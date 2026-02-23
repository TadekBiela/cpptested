---
title: "Największy wróg unit testów - logika."
date: 2026-02-23
author: "Tadeusz Biela"
categories:
  - unit-testing
tags:
  - clean code
  - software testing
  - code quality
  - developer practices
---

Logika, przepływ sterowania, instrukcje warunkowe - to&nbsp;dzięki nim nasze programy mogą spełniać szeregi wymagań i&nbsp;oczekiwań. Dzięki nim możemy rozbudowywać nasz program, rozwijać obecne funkcjonalności oraz dodawać nowe. Każdy programista wie, że&nbsp;bez nich tworzenie oprogramowania nie mogłoby mieć miejsca. Czy&nbsp;zatem nasze unit testy, również powinny zawierać logikę? Zdecydowanie nie, i&nbsp;w&nbsp;tym wpisie wyjaśnię dlaczego, tym&nbsp;razem odpowiedź jest taka klarowna, a&nbsp;nie, jak&nbsp;to nieraz w&nbsp;naszej branży bywa - "to&nbsp;zależy".

### Logika zwiększa ryzyko błędu

Każde rozgałęzienie procesu przetwarzania w&nbsp;naszym kodzie zwiększa jego podatność na błędy. Unit testy to narzędzie do weryfikowania założeń względem pisanego przez nas oprogramowania. Powinny one być jasno zdefiniowane. Jeśli w&nbsp;testach pojawia się logika to najczęściej jest to droga na skróty, by&nbsp;zaoszczędzić trochę czasu na dokładniejsze przeanalizowanie wymagań względem konkretnych scenariuszy użycia testowanego kodu.

Wyobraźmy sobie klasę do naliczania rabatów **DiscountCalculator**. Zamiast napisać trzy proste testy, w&nbsp;poniższym "sprytnym" przykładzie użyta została nie tylko pętla **for**, ale&nbsp;również instrukcje warunkowe **if/else**, aby&nbsp;przetestować różne progi rabatowe w&nbsp;jednym miejscu.

```cpp
TEST_F(DiscountCalculatorTest, calculate_CheckAllDiscounts_ShouldApplyCorrectRates)
{
    const std::vector<double> purchases { 50.0, 150.0, 300.0 };
    DiscountCalculator calculator {};

    for (const auto& amount : purchases)
    {
        const auto result { calculator.calculate(amount) };

        if (amount < 100.0)
        {
            EXPECT_NEAR(0.0, result, 0.001);
        }
        else if (100.0 <= amount && amount < 200.0)
        {
            EXPECT_NEAR(amount * 0.1, result, 0.001);
        }
        else
        {
            EXPECT_NEAR(amount * 0.2, result, 0.001); 
        }
    }
}
```

Dodanie logiki do testu powoduje szereg problemów. Jeśli test nie przejdzie, to&nbsp;nie tylko musimy debugować nasz kod, ale&nbsp;również kod testu.
A tutaj prawidłowo napisane testy dla metody **calculate**.

```cpp
TEST_F(DiscountCalculatorTest, calculate_TooLowAmount_ShouldReturnNoDiscount)
{
    const auto amount { 50.0 };
    DiscountCalculator calculator {};

    const auto result { calculator.calculate(amount) };

    EXPECT_NEAR(0.0, result, 0.001);
}

TEST_F(DiscountCalculatorTest, calculate_FirstThresholdAmount_ShouldReturn10PercentDiscount)
{
    const auto amount { 150.0 };
    DiscountCalculator calculator {};

    const auto result { calculator.calculate(amount) };

    EXPECT_NEAR(15.0, result, 0.001);
}

TEST_F(DiscountCalculatorTest, calculate_SecondThresholdAmount_ShouldReturn20PercentDiscount)
{
    const auto amount { 300.0 };
    DiscountCalculator calculator {};

    const auto result { calculator.calculate(amount) };

    EXPECT_NEAR(60.0, result, 0.001);
}
```

Jeśli unit testy nie mają prostej sekwencyjnej struktury tylko rozgałęziają się na różne scenariusze, to&nbsp;tracimy jedną z&nbsp;najważniejszych cech dobrych unit testów, powtarzalność. Tak&nbsp;w&nbsp;zasadzie to logika w&nbsp;testach łamie również inną zasadę z&nbsp;[akronimu F.I.R.S.T.](https://cpptested.com/unit-testing/first-reguly-ut/){:target="_blank" rel="noopener"} - **I**. Testy, przez wprowadzone instrukcje warunkowe, mogą utracić swoją niezależność względem innych testów. Zwłaszcza, gdy korzystają ze wspólnej metody narzędziowej klasy test siuty.

Dla przykładu testujemy klasę **OrderProcessor**. Mamy metodę narzędziową **setupMocks**, która w&nbsp;zależności od przekazanych flag, konfiguruje mocki dla różnych scenariuszy.

```cpp
class OrderProcessorTest : public testing::Test
{
protected:
    // Wspólna metoda narzędziowa z&nbsp;ukrytą logiką sterującą
    auto setupProcessor(bool isGoldCustomer, bool hasDiscount) -> void
    {
        if (isGoldCustomer)
        {
            EXPECT_CALL(customerServiceMock, getStatus(_)).WillRepeatedly(Return(Status::Gold));
        }

        if (hasDiscount)
        {
            EXPECT_CALL(discountServiceMock, apply(_)).WillOnce(Return(true));
        }
        else
        {
            // Brak zniżki może zmieniać stan mocka w&nbsp;sposób, 
            // którego inny test się nie spodziewa
            EXPECT_CALL(discountServiceMock, apply(_)).Times(0);
        }
    }

    MockCustomerService customerServiceMock;
    MockDiscountService discountServiceMock;
};

TEST_F(OrderProcessorTest, process_GoldCustomerWithoutDiscount_ShouldWork)
{
    setupProcessor(true, false);
    OrderProcessor processor { customerServiceMock, discountServiceMock };

    const auto result { processor.process(Order{}) };

    EXPECT_TRUE(result.success);
}
```

To jest dokładnie ta sytuacja, o&nbsp;której wspominałem we [wpisie o&nbsp;DRY i&nbsp;innych zasadach programowania](https://cpptested.com/clean-code/dry-and-other-principles/){:target="_blank" rel="noopener"}. Nie&nbsp;zawsze stosowanie DRY w&nbsp;testach to dobry pomysł. Poniżej poprawna wersja.

```cpp
class OrderProcessorTest : public testing::Test
{
protected:
    auto setupProcessorForCustomerWithoutDiscount(const Status customerStatus) -> void
    {
        EXPECT_CALL(customerServiceMock, getStatus(_)).WillRepeatedly(Return(customerStatus));
    }

    auto setupProcessorForCustomerWithDiscount(const Status customerStatus) -> void
    {
        EXPECT_CALL(customerServiceMock, getStatus(_)).WillRepeatedly(Return(customerStatus));
        EXPECT_CALL(discountServiceMock, apply(_)).WillOnce(Return(true));
    }
  
    MockCustomerService customerServiceMock;
    MockDiscountService discountServiceMock;
};

TEST_F(OrderProcessorTest, process_GoldCustomerWithoutDiscount_ShouldWork)
{
    setupProcessorForCustomerWithoutDiscount(Status::Gold);
    OrderProcessor processor { customerServiceMock, discountServiceMock };

    const auto result { processor.process(Order{}) };

    EXPECT_TRUE(result.success);
}
```

W tym przykładzie moglibyśmy w&nbsp;zasadzie, po&nbsp;prostu usunąć metody narzędziowe i&nbsp;bezpośrednio dodawać **EXPECT_CALL** do testów. Są&nbsp;jednak przypadki, gdzie takich instrukcji jest więcej i&nbsp;wtedy warto rozważyć stworzenie metody narzędziowej. To&nbsp;bardzo dobra technika, ciało testu się skraca, a&nbsp;dodatkowo dobrze dobrana nazwa metody dodaje więcej kontekstu. Pamiętaj tylko bez logiki! ;)

### Powielanie błędów z&nbsp;kodu produkcyjnego

Częstym powodem dodawania logiki do unit testów jest chęć odwzorowania przepływu sterowania w&nbsp;testowanym kodzie. Naraża nas to jednak na powielenie błędów z&nbsp;produkcyjnego kodu. Unit testy powinny wykrywać defekty, nie&nbsp;powielać logikę doprowadzając do sytuacji, w&nbsp;której testy w&nbsp;zasadzie są kopią testowanego kodu.

Tym razem mamy klasę **LoyaltyPointsCalculator**, liczymy punkty lojalnościowe. Kto&nbsp;nie lubi ekstra rabatów ;)
Logiką, w&nbsp;tym przypadku, jest&nbsp;kopia algorytmu z&nbsp;kodu produkcyjnego. Nie&nbsp;ma tam wprawdzie **if**a, niemniej zamiast podać konkretną liczbę, nasz test liczy sobie oczekiwaną wartość podczas swojego wykonywania.

```cpp
TEST_F(LoyaltyPointsTest, calculatePoints_LargeOrder_ShouldReturnPointsWithBonus)
{
    const double orderValue { 600.0 };
    const double baseRate { 10.0 };
    const double bonusMultiplier { 1.05 };
    LoyaltyPointsCalculator calculator {};

    EXPECT_NEAR((orderValue / baseRate) * bonusMultiplier, calculator.calculate(orderValue), 0.001);
}
```

To nic innego jak fragment implementacji przeklejony do testu. Nie&nbsp;mamy żadnej gwarancji, że&nbsp;nasz test nie odziedziczył przypadkiem logicznego błędu, który miał przecież wykrywać. W&nbsp;asercji powinna się znaleźć pożądana wartość, a&nbsp;nie sposób jej wyliczania. Poniżej poprawiony test.

```cpp
TEST_F(LoyaltyPointsTest, calculatePoints_LargeOrder_ShouldReturnPointsWithBonus)
{
    const auto orderValue { 600.0 };
    LoyaltyPointsCalculator calculator {};

    const auto result { calculator.calculate(orderValue) };

    EXPECT_NEAR(63.0, result, 0.1);
}
```

Możliwe, że&nbsp;zastanawiasz się jeszcze dlaczego podawać już obliczoną wartość. Przecież i&nbsp;tak trzeba było ją policzyć. Tak, zgadza się, jednak takich testów z&nbsp;pewnością napisalibyśmy więcej. Jeśli za każdym razem przekopiowalibyśmy logikę z&nbsp;kodu produkcyjnego do testów, to nic by one nie wykryły. Błąd natomiast zapewne wykryliby użytkownicy, co&nbsp;było by znacznie bardziej kosztowne i&nbsp;bolesne. Jeśli obliczamy wartości sami i&nbsp;wpisujemy je bezpośrednio do naszych testów to istnieje dużo mniejsza szansa, że&nbsp;za każdym razem obliczymy ją niepoprawnie.

### Zmniejszenie czytelności

Logika, na&nbsp;przykład w&nbsp;postaci bloku **switch/case** może utrudniać nam odczytanie intencji testów. Nazwy są niejasne, mało konkretne. Odzwierciedlają tylko to, że&nbsp;pojedynczy unit test testuje więcej niż jeden scenariusz. Dlatego tak ciężko dobrać prawidłową nazwę. Tracimy kontekst bo jest on rozmywany przez logikę, która steruje częścią asercji w&nbsp;zależności od tego co testowana metoda zwróci.

Dla przykładu mamy klasę **OrderNotifier**, która między innymi nadaje priorytety otrzymanym zamówieniom. W&nbsp;zależności od statusu, priorytet będzie inny. Poniżej przykład wszechstronnego, "mega" unit testu.

```cpp
TEST(OrderNotifierTest, determinePriority_MultipleStatuses_ShouldReturnCorrectPriority)
{
    std::vector<OrderStatus> statuses { OrderStatus::New, OrderStatus::Shipped, OrderStatus::Cancelled };
    OrderNotifier notifier {};

    for (const auto& status : statuses)
    {
        const auto priority { notifier.determinePriority(status) };

        switch (status)
        {
            case OrderStatus::New:
                EXPECT_EQ(Priority::Low, priority);
                break;
            case OrderStatus::Shipped:
                EXPECT_EQ(Priority::High, priority);
                break;
            case OrderStatus::Cancelled:
                EXPECT_EQ(Priority::Critical, priority);
                break;
        }
    }
}
```

Pomimo, iż&nbsp;sama nazwa trzyma się [standardu triple A](https://cpptested.com/unit-testing/AAA-golden-standard/){:target="_blank" rel="noopener"} to nie za wiele to daje. Nazwa jest po prostu zbyt ogólna. Jedyne czego możemy być pewni, to, że&nbsp;testuje metodę **determinePriority** klasy **OrderNotifier**. Z&nbsp;pewnością przyznasz, że&nbsp;to mało konkretne ;)
Ciało testu również nie trzyma standardu AAA. Bloki **Act** i&nbsp;**Assert** są wymieszane. Jeśli test zfailuje to w&nbsp;logach będziemy musieli szukać odpowiedzi. Gdyby to były osobne testy, po&nbsp;samej nazwie wiedzielibyśmy, co&nbsp;poszło nie tak.

Zobacz jak to powinno wyglądać poprawnie.

```cpp
TEST_F(OrderNotifierTest, determinePriority_NewOrder_ShouldReturnLowPriority)
{
    OrderNotifier notifier {};

    const auto priority { notifier.determinePriority(OrderStatus::New) };

    EXPECT_EQ(Priority::Low, priority);
}

TEST_F(OrderNotifierTest, determinePriority_OrderShipped_ShouldReturnHighPriority)
{
    OrderNotifier notifier {};

    const auto priority { notifier.determinePriority(OrderStatus::Shipped) };

    EXPECT_EQ(Priority::High, priority);
}

TEST_F(OrderNotifierTest, determinePriority_OrderCancelled_ShouldReturnCriticalPriority)
{
    OrderNotifier notifier {};

    const auto priority { notifier.determinePriority(OrderStatus::Cancelled) };

    EXPECT_EQ(Priority::Critical, priority);
}
```

I teraz to się nazywają czytelne testy! Prawda? Wszystko widoczne jak na tacy. Proste i&nbsp;skuteczne.

### Dopuszczalne rodzaje logiki

Istnieją pewne elementy logiki, które nie mają negatywnych skutków dla naszych unit testów i&nbsp;wręcz mogą poprawić ich czytelność - pętle. Ich&nbsp;stosowanie z&nbsp;pewnością będzie wskazane przy weryfikacji kontenerów. Niemniej, za&nbsp;każdym razem, gdy&nbsp;chcemy użyć pętli w&nbsp;unit testach powinniśmy sobie zadać pytanie: czy dodanie pętli jest niezbędne, by&nbsp;zachować czytelność i&nbsp;prostotę weryfikacji lub do realizacji konkretnego scenariusza testowego?
Jeśli odpowiedź brzmi tak, śmiało użyj pętli.

```cpp
TEST_F(ReportBatchProcessorTest, processReports_AllValidReports_EachReportIsMarkedAsProcessedAndNoErrors)
{
    const std::vector<Report> reports { { "ID_1" }, { "ID_2" }, { "ID_3" } };
    ReportBatchProcessor processor { reports };

    processor.processReports();

    const auto results { processor.getProcessedReports() };
    ASSERT_THAT(results, testing::SizeIs(reports.size()));
    for (const auto& report : results)
    {
        EXPECT_THAT(report.isProcessed(), testing::IsTrue());
        EXPECT_THAT(report.errorCode(), testing::Eq(0));
    }
}
```

W powyższym przykładnie zastosowanie pętli **for** jak najbardziej jest poprawne. Moglibyśmy wprawdzie po prostu napisać 6 asercji zamiast dwóch w&nbsp;pętli. Jednak jeśli elementów w&nbsp;kontenerze byłoby więcej, kod&nbsp;testu niepotrzebnie by się wydłużył. Zauważ przy okazji jakich asercji użyłem: **ASSERT_THAT** i&nbsp;**EXPECT_THAT**. Znasz je może? Ja wcześniej nie znałem. Po&nbsp;kilku testach stwierdziłem, że&nbsp;warto się im przyjrzeć bliżej. Z&nbsp;pewnością przygotuje osobny post o&nbsp;optymalizacji czytelności wyników testów, gdy&nbsp;się niepowiodą, tak, aby&nbsp;sam komunikat Google Testa jasno wskazywał nam co poszło nie tak.

### Podsumowanie

Mam nadzieję, że&nbsp;tym wpisem przekonałem Cię do niedodawania logiki to Twoich unit testów oraz uważniejszego code review swoich kolegów i&nbsp;koleżanek z&nbsp;zespołu. Ja&nbsp;sam wciąż zbyt często spotykam się z&nbsp;tym problemem i&nbsp;staram się dzielić wiedzą o&nbsp;tym jak pisać dobrej jakości unit testy. Co&nbsp;myślisz o&nbsp;tak rygorystycznym podejściu do braku logiki w&nbsp;unit testach? Uważasz to za przesadę, a&nbsp;może się ze mną zgadzasz? Koniecznie podziel się swoją opinią w&nbsp;komentarzu :)

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}