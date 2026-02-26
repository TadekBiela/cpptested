---
title: "6 najczęstszych błędów z&nbsp;Google Test."
date: 2026-01-26
author: "Tadeusz Biela"
categories:
  - clean code
tags:
  - clean code
  - code quality
  - developer practices
  - software
---

Google Test to chyba najbardziej znany i&nbsp;używany framework testowy w&nbsp;projektach C++. Zawiera w&nbsp;sobie masę przydatnych narzędzi do tworzenia różnych rodzajów testów. Ja osobiście stosuję go w&nbsp;swoich projektach pisząc unit testy, ale nic nie stoi na przeszkodzie by tworzyć testy modułowe czy komponentowe (typu black box). Ceniony za swą uniwersalność oraz rozbudowany system asercji jest narzędziem bardzo potężnym. Mimo to nie jest również bez wad. Im&nbsp;bardziej złożone jest narzędzie tym trudniej się go nauczyć i&nbsp;korzystać z&nbsp;niego poprawnie.

Popełniamy błędy. To&nbsp;normalne, ważne jest co z&nbsp;tym zrobimy. Warto wyciągnąć z&nbsp;nich lekcje na przyszłość. Poniższa lista to nic innego jak moje własne obserwacje, jak programiści C++(w tym ja) wykorzystują **GTest** i&nbsp;gdzie najczęściej popełniają błędy.

### Kolejność parametrów asercji

Czy kolejność w&nbsp;asercji typu EXPECT_EQ jest ważna? Owszem! Choć nie wynika ona z&nbsp;samej definicji makra w&nbsp;nagłówku **gtest.h**. Wspomniana definicja wygląda następująco.

```cpp
#define EXPECT_EQ(val1, val2) \
  EXPECT_PRED_FORMAT2(::testing::internal::EqHelper::Compare, val1, val2)
```

Sam Google Test nie informuje gdzie ma być umieszczona wartość oczekiwania, a&nbsp;gdzie wynikowa. Skąd więc założenie, że&nbsp;wartość **expected** powinna być pierwsza? Głównie z&nbsp;przykładów z&nbsp;repozytorium Google Test.

Przykład z&nbsp;folderu **samples** repozytorium Google Test, a&nbsp;dokładnie ten ["sample4_unittest"](https://github.com/google/googletest/blob/main/googletest/samples/sample4_unittest.cc){:target="_blank" rel="noopener"}.

```cpp
TEST(Counter, Increment) {
  Counter c;

  // Test that counter 0 returns 0
  EXPECT_EQ(0, c.Decrement());

  // EXPECT_EQ() evaluates its arguments exactly once, so they
  // can have side effects.

  EXPECT_EQ(0, c.Increment());
  EXPECT_EQ(1, c.Increment());
  EXPECT_EQ(2, c.Increment());

  EXPECT_EQ(3, c.Decrement());
}
```

Oczywiście jest ich znacznie więcej.

Są dwa powody dlaczego warto najpierw podawać wartość oczekiwaną, a&nbsp;potem wynikową.

1. Czytelność - przeglądając test, czytamy linijkę od lewej do prawej. Gdy&nbsp;wartością oczekiwaną jest po prostu stałą liczbową lub tekstową, szybciej dowiemy się co jest oczekiwane względem testowanej metody.
2. Spójność z&nbsp;warunkami w&nbsp;kodzie - znasz ten ból, gdy&nbsp;w&nbsp;**if** zamiast użyć operatora porównania **==**, użyłeś operator przypisania **=**? Ja tak, dlatego warto najpierw wartość oczekiwaną podawać jako pierwszą. Jeśli jest to stała, kompilator szybko poinformuje nas o&nbsp;pomyłce.

```cpp

if(i = 5) // Kompilator nie zgłosi błędu

if(5 = i) // a tutaj już tak

```

Logika jest zachowana ale zwiększa się odporność na błędy.

To która wersja będzie poprawna?

```cpp
EXPECT_EQ(resultValue, expectedValue); // Ta?
EXPECT_EQ(expectedValue, resultValue); // czy ta?
```

Tak naprawdę - to zależy. Choć sama kolejność jest sugerowana przykładami, nie jest ona napisana wprost. Którą więc wybrać? Jeśli wchodzisz do projektu, gdzie pierwsza wartość to ta wynikowa. Dostosuj się do konwencji już panującej w&nbsp;projekcie. Jeśli to nowy projekt, lub&nbsp;brak jest spójnej konwencji, wybierz wersję, gdzie wartość oczekiwana podawana jest jako pierwsza.

### Używanie EXPECT zamiast ASSERT

Ten błąd może kosztować życie (naszego wątku uruchamiającego testy). Dlaczego? Najpierw omówmy różnicę w&nbsp;zachowaniu **EXPECT_EQ** i&nbsp;**ASSERT_EQ** (lub dowolnej innej pary tych typów asercji). Obie asercje mają za zadanie sprawdzać czy dana wartość zgadza się z&nbsp;oczekiwaną. Różnica polega na&nbsp;tym co wydarzy się w&nbsp;przypadku niepowodzenia asercji. **EXPECT** spowoduje, że&nbsp;test nie zostanie zaliczony, wypisze komunikat i&nbsp;przejdzie do następnej linii testu.

```cpp
TEST_F(WidgetFactoryTests, create_ButtonWidgetType_ReturnButtonWidget)
{
    const Rect expectedRect{ 300, 400, 120, 30 };
    const std::string expectedText{ "Test Button" };
    WidgetFactory factory{};

    const auto resultWidget{ factory.create(WidgetType::BUTTON, expectedRect, expectedText)};

    EXPECT_EQ(WidgetType::LABEL, resultWidget.getType()); // Ta asercja się nie powiedzie
    EXPECT_EQ(expectedRect, resultWidget.getRect()); // Ta i następna zostaną wywołane
    EXPECT_EQ(expectedText, resultWidget.getText());
}
```

**ASSERT** również spowoduje fail testu, wypisze komunikat, ale&nbsp;już nie przejdzie dalej do kolejnej części testu. Test zostaje przerwany w&nbsp;tym miejscu i&nbsp;dalej nie będzie kontynuowany.

```cpp
TEST_F(WidgetsFactorySfmlTests, create_LabelType_CreateLabelWidget)
{
    const auto sfmlWindow{ std::make_shared<MockSfmlWindow>() };
    EXPECT_CALL(*sfmlWindow, getRenderTarget()).WillOnce(ReturnRef(getWindow()));
    EXPECT_CALL(*sfmlWindow, add(_));
    WidgetsFactorySfml factory{ nullptr, sfmlWindow, nullptr };

    const auto resultWidget {
        factory.create(
            WidgetType::LABEL,
            WidgetGeometry{},
            WidgetText{},
            WidgetStyle{}
        )
    }; // Jeśli ta metoda zwróci nullptr

    ASSERT_TRUE(resultWidget != nullptr); // to ta asercja się nie powiedzie i test przerywa wykonywanie.
    EXPECT_EQ(WidgetType::LABEL, resultWidget->getType()); // Ta i następna asercja nie zostaną wywołane
    EXPECT_TRUE(dynamic_cast<LabelWidget*>(resultWidget.get()) != nullptr);
}
```

Co nam to daje? Bardzo wiele, zwłaszcza gdy kolejne asercje opierają się na naszym **ASSERT**. Jeśli zastosujemy zwykły **EXPECT** to test zakończy swoje działanie poprzez brutalne przerwanie w&nbsp;stylu segfaulta.

```cpp
TEST_F(WidgetsFactorySfmlTests, create_LabelType_CreateLabelWidget)
{
    const auto sfmlWindow{ std::make_shared<MockSfmlWindow>() };
    EXPECT_CALL(*sfmlWindow, getRenderTarget()).WillOnce(ReturnRef(getWindow()));
    EXPECT_CALL(*sfmlWindow, add(_));
    WidgetsFactorySfml factory{ nullptr, sfmlWindow, nullptr };

    const auto resultWidget {
        factory.create(
            WidgetType::LABEL,
            WidgetGeometry{},
            WidgetText{},
            WidgetStyle{}
        )
    }; 

    EXPECT_TRUE(resultWidget != nullptr); // zamiast ASSERT jest EXPECT
    EXPECT_EQ(WidgetType::LABEL, resultWidget->getType());
    EXPECT_TRUE(dynamic_cast<LabelWidget*>(resultWidget.get()) != nullptr);
}
```

Test nie przejdzie, na dodatek, jeśli w&nbsp;naszej suicie będzie więcej testów i&nbsp;miały być one uruchomione po tym, to do tego nie dojdzie. Cały wątek z&nbsp;naszą suitą zostanie przerwany. Czyli inne testy nawet się nie wykonają.

```bash
[ RUN      ] WidgetsFactorySfmlTests.create_LabelType_CreateLabelWidget
Setting vertical sync not supported
/usr/src/heisttown/src/Sfml/SfmlWidgets/Tests/WidgetsFactorySfmlTests.cpp:42: Failure
Value of: resultWidget != nullptr
  Actual: false
Expected: true
```

W tym przypadku mamy chociaż informacje co poszło nie tak. Jeśli nie dodalibyśmy, w&nbsp;ogóle asercji na sprawdzanie czy **resultWidget** nie jest **nullptr**, nie wiedzielibyśmy nic. Dlatego ważne jest, aby&nbsp;stosować **ASSERT** czy **EXPECT** zgodnie z&nbsp;ich przeznaczeniem.

Dlaczego więc nie stosować **ASSERT** zawsze? Jak już pisałem, **ASSERT** zatrzymuje test, dalsza jego część nie jest weryfikowana. Jeśli następne asercje nie są zależne od poprzednich to, w&nbsp;takim przypadku zostaną pominięte i&nbsp;nie będziemy wiedzieli, czy tylko ta jedna asercja nie została spełniona, czy cały ich szereg. Obraz sytuacji będzie niekompletny.

Jeśli oczekiwanym wynikiem może być kontener to sprawdź jego rozmiar **ASSERT**em zanim zaczniesz weryfikować jego konkretne elementy. Albo, gdy&nbsp;wynikiem będzie wskaźnik, sprawdź czy nie jest on **nullptr** zanim zaczniesz odwoływać się do obiektu pod nim. To tylko najczęściej powtarzające się sytuacje, gdzie należy stosować **ASSERT**. Z&nbsp;pewnością jest ich więcej.

### Porównywanie floatów bez precyzji

Reprezentacja liczb zmiennoprzecinkowych przez komputer nie jest doskonała i&nbsp;wie to każdy doświadczony programista. Porównywanie wartości typu **float** czy **double** ze sobą nie jest takie proste jak liczb całkowitych. Weryfikacja testu odbywa się właśnie przez porównanie, a&nbsp;wyniki zapisane w&nbsp;liczbach zmiennoprzecinkowych mogą się nieznacznie różnić od tych oczekiwanych.

Dlaczego tak się dzieje?

Spora część liczb zmiennoprzecinkowych nie ma idealnej reprezentacji w&nbsp;systemie binarnym. Dlatego komputer musi zaokrąglać wyliczoną wartość do najbliższej zero-jedynkowej wartości. Jest nawet na to określony standard ["IEEE 754"](https://pl.wikipedia.org/wiki/IEEE_754){:target="_blank" rel="noopener"}. Właśnie ze względu na te zaokrąglenia, porównywanie wartości zmiennoprzecinkowych, może dać fałszywe wyniki. Dlatego stosuje się porównywanie z&nbsp;tolerancją, tak zwany **epsilon**.

To mi przypomina moje początki nauki pisania unit testów i&nbsp;pracy z&nbsp;Google Test. Tak,&nbsp;mniej więcej, wyglądał jeden z&nbsp;moich pierwszych unit testów w&nbsp;zakresie weryfikacji wyniku zapisanego właśnie w&nbsp;**double**.

```cpp
TEST(DemodulationTests, llr16QamIMsb_PositiveRealSampleValueAndPositiveNoise_ReturnCorrectLlr)
{
    const std::complex<double> sample{ 1.0, 0.0 };
    const double noise{ 0.394 };
  
    const auto resultLlr{ llr16QamIMsb(sample, noise) };

    EXPECT_EQ(5.0761421319796952, resultLlr);
}
```

Teraz, gdy&nbsp;o&nbsp;tym myślę, chce mi się śmiać, ale&nbsp;kto nie popełnia błędów? Ten kto nic nie robi ;) Dziś sobie z&nbsp;przed lat powiedziałbym co trzeba zrobić w&nbsp;takim przypadku, poprawilibyśmy ten test i&nbsp;wyglądałby następująco.

```cpp
TEST(DemodulationTests, llr16QamIMsb_PositiveRealSampleValueAndPositiveNoise_ReturnCorrectLlr)
{
    const std::complex<double> sample{ 1.0, 0.0 };
    const double noise{ 0.394 };
  
    const auto resultLlr{ llr16QamIMsb(sample, noise) };

    EXPECT_NEAR(5.07614, resultLlr, 0.00001);
}
```

Zmieniła się tylko sama asercja i&nbsp;z pewnością test stał się niewrażliwy na zmianę platformy, która ma inną precyzję operacji na liczbach zmiennoprzecinkowych. Dodatkowo dzięki właśnie **EXPECT_NEAR** możemy jasno określić tolerancję, czyli już wcześniej wspomniany **epsilon**.

### Logika w&nbsp;Mocku

Wraz z&nbsp;Google Test dostajemy również Google Mock, jest on dodawany jako osobny nagłówek **gmock.h**. Mock to w&nbsp;tłumaczeniu na polski - makieta. Czyli, w&nbsp;kontekście programowania obiektowego, coś&nbsp;co tylko udaje implementację klasy. Nieraz jednak widziałem, mocki, które przysłaniały tylko część metod, pozostawiając lub nadpisując implementację klasy, z&nbsp;której dziedziczyły.

Możemy podejść do mockowania na przynajmniej dwa sposoby. Pierowysz to bazowanie na interfejsie. Wprowadzamy klasę czysto abstrakcyjną, do której nasza testowana klasa się odwołuje, nie znając prawdziwej wersji implementacji.

Poniżej przykład interfejsu **RenderSceneBuilder**. Klasa ta ma za zadanie budowanie sceny gry złożonej z&nbsp;obiektów klasy **RenderItem** (również interfejs) w&nbsp;oparciu o&nbsp;strukturę **SceneUdate**.

```cpp
class RenderSceneBuilder
{
public:
    virtual ~RenderSceneBuilder() = default;

    virtual auto build(const SceneUpdate& sceneUpdate) -> void = 0;
    virtual auto popRenderItems() -> RenderItems = 0;
};
```

A tutaj przykład jego wykorzystania (uproszczony by nie zaciemniać obrazu).

```cpp
class SfmlWindow
{
public:
    SfmlWindow(
        //...
        std::unique_ptr<RenderSceneBuilder> inputSceneBuilder = nullptr
        //...
    );

    //...
    auto update(const SceneUpdate& sceneUpdate) -> void;

private:
    //...
    std::unique_ptr<RenderSceneBuilder> sceneBuilder;
    //...
};
```

Teraz utworzymy mocka z&nbsp;interfejsu, **MockRenderSceneBuilder**.

```cpp
class MockRenderSceneBuilder : public RenderSceneBuilder
{
public:
    MOCK_METHOD(void, build, (const SceneUpdate&), (override));
    MOCK_METHOD(RenderItems, popRenderItems, (), (override));
};
```

W tym przypadku klasa mocka przysłania tylko interfejs i&nbsp;wszystko mamy czyste. Wstrzykujemy mocka do naszej testowanej klasy poprzez konstruktor i&nbsp;voilà!

Drugi sposób - do destruktora oraz wszystkich publicznych metod klasy, którą chcemy zamockować dodajemy **virtual**. Dla&nbsp;przykładu mamy klasę **GameSession**.

```cpp
class GameSession
{
public:
    explicit GameSession(std::unique_ptr<SceneItemFactory> inputFactory = nullptr);
    virtual ~GameSession() = default;

    virtual auto addPlayer() -> PlayerID;
    virtual auto removePlayer(const PlayerID& playerId) -> void;
    virtual auto queuePlayerStatus(const PlayerID& playerId, const PlayerStatus& playerStatus) -> void;
    virtual auto updateGameWorld() -> void;
    virtual auto getUpdateForPlayer(const PlayerID& playerId) const -> GameplayUpdate;

private:
    //...
};
```

I mockujemy.

```cpp
class MockGameSession : public GameSession
{
public:
    MockGameSession() = default;

    MOCK_METHOD(PlayerID, addPlayer, (), (override));
    MOCK_METHOD(void, removePlayer, (const PlayerID&), (override));
    MOCK_METHOD(void, queuePlayerStatus, (const PlayerID&, const PlayerStatus&), (override));
    MOCK_METHOD(void, updateGameWorld, (), (override));
    MOCK_METHOD(GameplayUpdate, getUpdateForPlayer, (const PlayerID&), (const, override));
};

```

Jeśli pozostawimy część publicznych metod jako niewirtualne i&nbsp;nie przysłonimy ich w&nbsp;mocku to nie odcinamy w&nbsp;pełni zależności między naszą testowaną klasą, a&nbsp;klasą zmockowaną. Taki test de facto nie jest już unit testem lecz czymś w&nbsp;rodzaju karykatury module testu. Poniżej przykład

```cpp
class MockGameSession : public GameSession
{
public:
    MockGameSession() = default;

    MOCK_METHOD(PlayerID, addPlayer, (), (override));
    MOCK_METHOD(void, removePlayer, (const PlayerID&), (override));
    MOCK_METHOD(void, queuePlayerStatus, (const PlayerID&, const PlayerStatus&), (override));
    MOCK_METHOD(void, updateGameWorld, (), (override));
    GameplayUpdate getUpdateForPlayer(const PlayerID&) const override
    {
        // Generuje losowe wartości i wypełnia nimi GameplayUpdate
    } 
};
```

W przypadku, gdy&nbsp;dopisujemy jakąś część logiki w&nbsp;kodzie mocka ograniczamy widoczność tych operacji w&nbsp;naszych testach. Mock sam z&nbsp;siebie nie powinien nic robić. Służy on do weryfikacji zachowania naszej testowanej klasy, tj. jego interakcji z&nbsp;mockowaną klasą. Jeśli potrzebujemy, by nasz mock reagował na te interakcje Google Mock udostępnia szereg narzędzi jak **ON_CALL** i&nbsp;**EXPECT_CALL** z&nbsp;odpowiednią kombinacją na przykład **WillOnce** i&nbsp;**Invoke** (są też inne metody na sterowanie zachowaniem mocka). Wtedy wszystko jest zapisane w&nbsp;naszym unit teście, w&nbsp;bloku ["Arrange"](https://cpptested.com/unit%20testing/AAA-golden-standard/){:target="_blank" rel="noopener"}.

### Testowanie Mocka

Jak już wspomniałem mocki służą do weryfikacji interakcji z&nbsp;naszą testowaną klasą. Spotkałem się jednak z&nbsp;innym sposobem wykorzystywania mocków w&nbsp;unit testach. Kiedy nie znamy dobrych podstaw pisania unit testów (o których jeszcze napiszę ;) ), mogą powstać naprawdę dziwne rzeczy.

W unit testach widziałem wiele nietypowych konstrukcji, i&nbsp;w rzeczy samej testowanie mocka jest jedną z&nbsp;nich. Chcąc odciąć jakąś zależność możemy zastosować mocka, aby&nbsp;przysłonić część implementacji lub wręcz zastąpić ją inną. Co&nbsp;de&nbsp;facto mija się z&nbsp;celem testowania.

Dla przykładu, mamy mocka klasy **MockGameSession** z&nbsp;poprzedniego punktu. Tym&nbsp;razem jak najbardziej poprawnego.

```cpp
class MockGameSession : public GameSession
{
public:
    MockGameSession() = default;

    MOCK_METHOD(PlayerID, addPlayer, ());
    MOCK_METHOD(void, removePlayer, (const PlayerID&));
    MOCK_METHOD(void, queuePlayerStatus, (const PlayerID&, const PlayerStatus&));
    MOCK_METHOD(void, updateGameWorld, ());
    MOCK_METHOD(GameplayUpdate, getUpdateForPlayer, (const PlayerID&), (const));
    MOCK_METHOD(Texture, getTexture, (const std::string), (const)); // metoda protected w GameSession
};
```

Natomiast w&nbsp;unit testach chcemy przetestować metodę **addPlayer** klasy **GameSession**, jednak korzysta ona z&nbsp;metody **getTexture** odczytującej teksturę gracza z&nbsp;pliku. W&nbsp;takim przypadku moglibyśmy zastosować ["Wrapper"](https://cpptested.com/unit%20testing/handling-globals/){:target="_blank" rel="noopener"} lub wprowadzić osobny obiekt klasy **Factory** i&nbsp;zacmokocwać ją stosująć Dependency Injection. Jednak nie znając jeszcze tych technik możemy pokusić się o&nbsp;użycie mocka w&nbsp;taki sposób, by podczas testowania metody **addPlayer** przysłonić tylko metodę **getTexture**, która to odpowiedzialna jest za odczyt pliku.

```cpp
TEST_F(GameSessionTests, addPlayer_OneNewPlayer_ReturnNewPlayerId)
{
    auto factory{ std::make_unique<MockSceneItemFactory>() };
    EXPECT_CALL(*factory, create(_, _, _));
    MockGameSession gameSession{ std::move(factory) };
    EXPECT_CALL(gameSession, getTexture(_)).WillOnce(Return(Texture())); // Mockowanie zależności odczytu z pliku
    EXPECT_CALL(gameSession, addPlayer()).WillOnce(Invoke([&](){ // Mockowana metoda wykonuje tą prawdziwą
        return gameSession.GameSession::addPlayer();
    }));

    const auto resultPlayerId{ gameSession.addPlayer() }; // Wywołanie mockowanej metody

    EXPECT_EQ(0, resultPlayerId);
}
```

Dlaczego uważam to za fatalny pomysł? W końcu działa...

No cóż to tak jakby używać spawarki do wbijania gwoździ, no niby da się tylko po co? Mocki zostały wymyślone po to by odcinać zależności między klasami, a&nbsp;nie do grzebania w&nbsp;implementacji naszej testowanej klasy. Gdy widzę test, w&nbsp;którym nie ma normalnej klasy, tylko same mocki to coś tu jest nie tak.

Taki test jest bardzo nieczytelny. Gdy&nbsp;dodamy do tego enigmatyczną nazwę to praktycznie na pierwszy czy nawet drugi rzut oka, nie jesteśmy w&nbsp;stanie stwierdzić, która klasa jest testowana. W GoogleTest są oczywiście nazwa test suity, która może w&nbsp;tym przypadku podpowiedzieć to i&nbsp;owo, niemniej, czytelność i&nbsp;tak spada diametralnie.

Używajmy narzędzi zgodnie z&nbsp;ich pierwotnym przeznaczeniem, zwłaszcza podczas testowania. Dbamy tym samym o&nbsp;wysoką czytelność i&nbsp;przejrzystość w&nbsp;naszych unit testach.

### Brak override w mockach

Słowo kluczowe (a&nbsp;dokładnie specyfikator) **override** możemy stosować również w&nbsp;mockowanych metodach i&nbsp;działa ono dokładnie tak samo jak w&nbsp;zwykłych klasach. W&nbsp;**MOCK_METHOD** na końcu, w&nbsp;sekcji gdzie dodajemy kwalifikatory i&nbsp;specyfikatory. Dla przykładu, wróćmy do **MockGameSession**.

```cpp
class MockGameSession : public GameSession
{
public:
    MockGameSession() = default;

    MOCK_METHOD(PlayerID, addPlayer, ());
    MOCK_METHOD(void, removePlayer, (const PlayerID&));
    MOCK_METHOD(void, queuePlayerStatus, (const PlayerID&, const PlayerStatus&));
    MOCK_METHOD(void, updateGameWorld, ());
    MOCK_METHOD(GameplayUpdate, getUpdateForPlayer, (const PlayerID&), (const));
};
```

Jeśli w&nbsp;takim przypadku metoda **removePlayer** w&nbsp;klasie **GameSession** nie będzie wirtualna, kompilator i&nbsp;tak nie zwróci błędu. Kod&nbsp;skompiluje się, a&nbsp;my będziemy zachodzić w&nbsp;głowę czemu nasz mock nie jest wywoływany.

Użycie **override** eliminuje problem. W&nbsp;przypadku, gdy&nbsp;dodamy ten specyfikator, a&nbsp;metoda w&nbsp;klasie bazowej nie będzie wirtualna, kompilator zwróci błąd. Tak&nbsp;jak na poniższym przykładzie.

Tutaj już poprawiony mock.

```cpp
class MockGameSession : public GameSession
{
public:
    MockGameSession() = default;

    MOCK_METHOD(PlayerID, addPlayer, (), (override));
    MOCK_METHOD(void, removePlayer, (const PlayerID&), (override));
    MOCK_METHOD(void, queuePlayerStatus, (const PlayerID&, const PlayerStatus&), (override));
    MOCK_METHOD(void, updateGameWorld, (), (override));
    MOCK_METHOD(GameplayUpdate, getUpdateForPlayer, (const PlayerID&), (const, override));
};
```

Oraz błąd zwracany przez kompilator.

```bash
/.../MockGameSession.hpp:16:23: error: 'testing::internal::Function<void(const int&)>::Result MockGameSession::removePlayer(testing::internal::ElemFromList<0, const int&>::type)' marked 'override', but does not override
   16 |     MOCK_METHOD(void, removePlayer, (const PlayerID&), (override));
      | 
```

### Podsumowanie

To już wszystko w&nbsp;tym wpisie. Mam&nbsp;nadzieję, że&nbsp;będzie dla Ciebie choć trochę pomocny w&nbsp;zmaganiach z&nbsp;Google Test'em. Czy któryś z&nbsp;wymienionych w&nbsp;tym wpisie błędów Cię zaskoczył? Może inny jest dość znajomy? Daj znać w&nbsp;komentarzu! Popełnianie błędów jest czymś normalnym. Ważne by się rozwijać i&nbsp;uczyć od siebie nawzajem. Jeśli znasz inne przypadki, chętnie się z&nbsp;nimi zapoznam. Możesz również napisać do mnie email lub wysłać wiadomość na LinkedIn. Będzie mi bardzo miło :)

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}
