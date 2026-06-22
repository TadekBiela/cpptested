---
title: "Twoje unit testy przemówią! Czyli jak poprawić komunikaty testów."
date: 2026-04-19
author: "Tadeusz Biela"
categories:
  - unit-testing
tags:
  - clean code
  - software testing
  - code quality
  - developer practices
---

Czytelność komunikatów logowanych podczas niepowodzenia unit testów często jest bardzo niskiej jakości. Sam&nbsp;wcześniej nie zwracałem na to zbytniej uwagi. Dziś uważam, że&nbsp;to błąd! Gdy testy świecą się na zielono, to w&nbsp;zasadzie problem nie istnieje. Gdy&nbsp;zaś na czerwono, wtedy zaczynają się schody. Najczęściej po prostu sięgamy od razu do kodu i&nbsp;szukamy przyczyny próbując jednocześnie odczytać "zaszyfrowane" wartości z&nbsp;logów failującego testu. A&nbsp;gdyby tak te logi mogłyby być czytelne nawet dla laika? Z&nbsp;pewnością ułatwiłoby to wszystkim pracę :)

### Enum jak enigma

W unit testach porównujemy różnego rodzaju zmienne wynikowe z&nbsp;oczekiwanymi. Jeśli są to zmienne typu liczbowego to zazwyczaj ich odczytanie nie stanowi problemu. Inaczej dzieje się w&nbsp;przypadku typów wyliczeniowych. Nie&nbsp;zawsze pamiętamy co ich reprezentacja liczbowa oznacza. Dla&nbsp;przykładu mamy poniższy test.

```cpp
TEST_F(SceneItemFactoryTests, create_OneObject_ReturnCorrectSceneItem)
{
    SceneItemFactoryTestable factory{};

    auto resultObject{ factory.create(SceneItemType::PLAYER, { 40.5F, 7.9F }, 45.0F) };

    EXPECT_EQ(0, resultObject.id);
    EXPECT_EQ(SceneItemType::WEAPON, resultObject.type); // Celowo podana zła wartość enum
}
```

A oto wynik naszego unit testu:

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Expected equality of these values:
  expectedType
    Which is: 4-byte object <01-00 00-00>
  resultObject.type
    Which is: 4-byte object <00-00 00-00>

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

No cóż możemy sobie sprawdzić co oznacza 1 i&nbsp;0, niemniej przyznać trzeba, że&nbsp;średnio ten komunikat jest czytelny. Musimy sięgnąć do kodu i&nbsp;to sprawdzić. Spróbujmy zmienić rodzaj asercji na **EXPECT_THAT**. Oto&nbsp;wynik:

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Value of: resultObject.type
Expected: is equal to 4-byte object <01-00 00-00>
  Actual: 4-byte object <00-00 00-00> (of type SceneItemType)

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

Jest trochę lepiej, już&nbsp;teraz wiemy przynajmniej jakiego typu są wartości: **(of type SceneItemType)**. Niemniej wciąż ten log niewiele pomaga. Co&nbsp;możemy zrobić? Dodać **operator<<** ! Operator ten należy zdefiniować w&nbsp;tym samym pliku, w&nbsp;którym znajduje się nasz **enum**.

```cpp
inline auto operator<<(std::ostream& os, const SceneItemType& type) -> std::ostream&
{
    std::string typeStr{};
    switch(type)
    {
        case SceneItemType::PLAYER:
            typeStr = "PLAYER";
            break;
        case SceneItemType::WEAPON:
            typeStr = "WEAPON";
            break;
    }

    os << typeStr;
    return os;
}
```

Taki zabieg pozwala Google Test użyć go w&nbsp;swoich asercjach. Gdy&nbsp;asercja nie przechodzi, GTest przeszukuje naszą bazę kodu w&nbsp;poszukiwaniu narzędzi umożliwiających wypisanie wartości parametrów asercji w&nbsp;formie tekstowej. Jeśli zdefiniujemy dla porównywanego typu, asercje Google Test użyje jej do budowy swoich logów.

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Value of: resultObject.type
Expected: is equal to WEAPON
  Actual: PLAYER (of type SceneItemType)

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

Teraz zdecydowanie, dokładnie wiadomo co się wydarzyło w&nbsp;teście. Nasza testowana fabryka utworzyła obiekt typu **PLAYER**, a&nbsp;miała stworzyć **WEAPON** ;) W&nbsp;tym miejscu muszę wspomnieć o&nbsp;jeszcze jednym sposobie uzyskania podobnego efektu. Można zdefiniować funkcję **PrintTo**. Jest to specjalna metoda Google Test, która działa w&nbsp;zasadzie tak samo. Plusem może okazać się brak ingerencji w&nbsp;kod produkcyjny. Jeśli to dla kogoś problem warto zainteresować się tematem. Poniżej odpowiednik naszego operatora w&nbsp;wersji **PrintTo**.

```cpp
inline auto PrintTo(const SceneItemType& type, std::ostream* os) -> void
{
    std::string typeStr{};
    switch(type)
    {
        case SceneItemType::PLAYER:
            typeStr = "PLAYER";
            break;
        case SceneItemType::WEAPON:
            typeStr = "WEAPON";
            break;
    }

    os << typeStr;
}
```

Oba rozwiązania muszą znajdować się w&nbsp;tej samej przestrzeni nazw, gdyż Google Test szuka **operator<<** oraz **PrintTo** za pomocą [ADL](https://en.cppreference.com/w/cpp/language/adl.html){:target="_blank" rel="noopener"}. Zauważ, że&nbsp;w&nbsp;instrukcji **switch** celowo pominąłem sekcję **default**. Dzięki temu, gdy&nbsp;w&nbsp;przyszłości dodasz nową wartość do **enum**a, kompilator przypomni Ci o&nbsp;konieczności aktualizacji również tego fragmentu kodu.

### struct, czyli puchnące testy

W przypadku porównywania struktur możemy w&nbsp;każdej asercji sprawdzać pojedyncze jej pola.

```cpp
TEST_F(SceneItemFactoryTests, create_OneObject_ReturnCorrectSceneItem)
{
    SceneItemFactoryTestable factory{};

    auto resultObject{ factory.create(SceneItemType::PLAYER, { 40.1F, 7.9F }, 45.0F) };

    EXPECT_THAT(resultObject.id, Eq(0));
    EXPECT_THAT(resultObject.type, Eq(SceneItemType::PLAYER));
    EXPECT_THAT(resultObject.position.x, FloatEq(40.5F)); // Sprawdzamy każde pole
    EXPECT_THAT(resultObject.position.y, FloatEq(7.9F)); // struktury Position osobno
    EXPECT_THAT(resultObject.rotation, FloatEq(45.0F));
}
```

Gdy struktura jest mała, może to być rozwiązanie całkiem ok. Jednak są na to lepsze metody. Jeżeli chcemy, aby&nbsp;jedna asercja porównywała całą strukturę musimy zdefiniować **operator==**. Dzięki temu Google Test użyje go automatyczne.

```cpp
struct Position
{
    float x{ 0.0F };
    float y{ 0.0F };

    auto operator==(const Position& other) const -> bool
    {
        // Używamy std::abs i małej tolerancji (epsilon)
        constexpr auto eps{ 1e-5F };
        return std::abs(x - other.x) < eps and 
               std::abs(y - other.y) < eps;
    }
};
```

Po dodaniu operatora porównania, nasz test wygląda następująco.

```cpp
TEST_F(SceneItemFactoryTests, create_OneObject_ReturnCorrectSceneItem)
{
    SceneItemFactoryTestable factory{};

    auto resultObject{ factory.create(SceneItemType::PLAYER, { 40.1F, 7.9F }, 45.0F) };

    EXPECT_EQ(0, resultObject.id);
    EXPECT_THAT(resultObject.type, Eq(SceneItemType::PLAYER));
    EXPECT_THAT(resultObject.position, Eq(Position{ 40.5F, 7.9F })); // Jedna asercja na całą strukturę
    EXPECT_THAT(resultObject.rotation, FloatEq(45.0F));
}
```

Choć zdecydowanie, dodanie operatora pomaga w&nbsp;ograniczaniu rozmiaru naszego unit testu, to&nbsp;nie chroni on od pojawiających się oktetów, gdy&nbsp;asercja się nie powiedzie.

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Value of: resultObject.position
Expected: is equal to 8-byte object <00-00 22-42 CD-CC FC-40>
  Actual: 8-byte object <66-66 20-42 CD-CC FC-40> (of type Position)

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

Innym rozwiązaniem może być utworzenie własnego matchera. Jedną z&nbsp;zasad pisania unit testów jest założenie, że&nbsp;nie powinniśmy zmieniać kodu produkcyjnego tylko ze względu na testy. Są&nbsp;oczywiście techniki jak **Dependency Injection**, które wpływają nieco na kod produkcyjny, ale&nbsp;w&nbsp;tej zasadzie bardziej chodzi o&nbsp;to, by&nbsp;nie oddawać API do naszej testowanej klasy, czy&nbsp;w&nbsp;tym przypadku struktury.

```cpp
MATCHER_P2(PositionNear, expected, tolerance, "")
{
    const auto xDiff{ std::abs(arg.x - expected.x) };
    const auto yDiff{ std::abs(arg.y - expected.y) };

    *result_listener << "where x diff is " << xDiff << " and y diff is " << yDiff;

    return xDiff <= tolerance and yDiff <= tolerance;
}
```

Prawda, że&nbsp;elegancki? A&nbsp;teraz jak to wygląda w&nbsp;praktyce, czyli odświeżony test.

```cpp
TEST_F(SceneItemFactoryTests, create_OneObject_ReturnCorrectSceneItem)
{
    SceneItemFactoryTestable factory{};

    auto resultObject{ factory.create(SceneItemType::PLAYER, { 40.1F, 7.9F }, 45.0F) };

    EXPECT_EQ(0, resultObject.id);
    EXPECT_THAT(resultObject.type, Eq(SceneItemType::PLAYER));
    EXPECT_THAT(resultObject.position, PositionNear(Position{ 40.5F, 7.9F }, 1e-5F)); // Użycie naszego matchera do porównywania struktury Position
    EXPECT_THAT(resultObject.rotation, FloatEq(45.0F));
}
```

No to czas na werdykt, czy&nbsp;nasze logi rzeczywiście poprawiły się dzięki temu zabiegowi?

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Value of: resultObject.position
Expected: position near (expected: 8-byte object <00-00 22-42 CD-CC FC-40>, tolerance: 1e-05)
  Actual: 8-byte object <66-66 20-42 CD-CC FC-40> (of type Position), where x diff is 0.400002 and y diff is 0

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

No magiczne oktety wciąż się pojawiają. To&nbsp;dlatego, że&nbsp;tak naprawdę Google Test dalej nie wie w&nbsp;jaki sposób wyświetlić naszą strukturę **Position**. I&nbsp;tutaj wracamy się z&nbsp;powrotem do operatora wstawiania do strumienia: **operator<<**. 

```cpp
inline auto operator<<(std::ostream& os, const Position& position) -> std::ostream&
{
    return os << "Position{ x: " << position.x << ", y: " << position.y << " }";
}
```

Po dodaniu takiego operatora nasze logi z&nbsp;testu wyglądają następująco.

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Value of: resultObject.position
Expected: position near (expected: Position{ x: 40.5, y: 7.9 }, tolerance: 1e-05)
  Actual: Position{ x: 40.1, y: 7.9 } (of type Position), where x diff is 0.400002 and y diff is 0

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

Teraz można śmiało stwierdzić, że&nbsp;każdy będzie w&nbsp;stanie zrozumieć co dokładnie się wydarzyło i&nbsp;dlaczego test nie przechodzi. I&nbsp;dla porównania logi z&nbsp;testu z&nbsp;użyciem **operator==** zamiast matchera.

```bash
[ RUN      ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem

Value of: resultObject.position
Expected: is equal to Position{ x: 40.5, y: 7.9 }
  Actual: Position{ x: 40.1, y: 7.9 } (of type Position)

[  FAILED  ] SceneItemFactoryTests.create_OneObject_ReturnCorrectSceneItem (0 ms)
```

To czy należy korzystać z&nbsp;**operator==** czy jednak z&nbsp;matchera to w&nbsp;zasadzie może zależeć od wielu czynników. Oba&nbsp;rozwiązania mają swoje wady i&nbsp;zalety. Tak&nbsp;jak to często w&nbsp;naszym zawodzie bywa, trzeba wybrać to rozwiązanie, które najbardziej pasuje do założeń naszego projektu, dobrych praktyk w&nbsp;naszym zespole, standardów kodzenia w&nbsp;naszej organizacji lub po prostu naszych preferencji :)

### Kontenery

Podczas porównywania elementów dowolnego kontenera w&nbsp;C++ przy użyciu Google Test, najczęstszym problemem jest brak informacji, które elementy nie zgadzają się z&nbsp;ich oczekiwaną wartością. Mamy poniższy test.

```cpp
TEST_F(OrderProcessorTest, getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad)
{
    OrderProcessor processor{};
    const std::vector<int> expected{ 1, 2, 3 };

    const auto result{ processor.getProcessedIds({ 3, 1, 2 }) };

    EXPECT_EQ(expected, result);
}
```

A oto wynik z&nbsp;konsoli.

```bash
[ RUN      ] OrderProcessorTest.getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad

Expected equality of these values:
  expected
    Which is: { 1, 2, 3 }
  result
    Which is: { 3, 1, 2 }

[  FAILED  ] OrderProcessorTest.getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad (0 ms)
```

Jak widać w&nbsp;takim przypadku, gdy&nbsp;kontener zawiera niewielką ilość elementów, znalezienie różnicy nie bywa wymagające. Co&nbsp;innego, gdy&nbsp;taki **std::vector** zawiera ich znacznie więcej.

```cpp
TEST_F(OrderProcessorTest, getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad)
{
    OrderProcessor processor{};
    const std::vector<int> expected{  1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
                                     11, 12, 13, 14, 15, 16, 17, 18, 19, 20 };

    const auto result{ processor.getProcessedIds({  3,  1,  2,  4, 15, 20,  5,  7,  6,  8,
                                                   10, 11, 14, 13, 18, 19,  9, 12, 16, 17 }) };

    EXPECT_EQ(expected, result);
}
```

Znalezienie różnicy może być znacznie utrudnione.

```bash
[ RUN      ] OrderProcessorTest.getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad

Expected equality of these values:
  expected
    Which is: { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 }
  result
    Which is: { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 15, 17, 18, 19, 20 }

[  FAILED  ] OrderProcessorTest.getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad (0 ms)
```

Aby poradzić sobie z&nbsp;tym problemem możemy zastosować matchera **Pointwise** w&nbsp;połączeniu z&nbsp;Eq(), oczywiście przy użyciu asercji **EXPECT_THAT** zamiast **EXPECT_EQ**. Tym&nbsp;razem widać znaczącą różnice w&nbsp;możliwościach tych dwóch typów asercji.

```cpp
TEST_F(OrderProcessorTest, getProcessedIds_UnsortedIds_ReturnsSortedVector_Bad)
{
    OrderProcessor processor{};
    const std::vector<int> expected{  1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
                                     11, 12, 13, 14, 15, 16, 17, 18, 19, 20 };

    const auto result{ processor.getProcessedIds({  3,  1,  2,  4, 15, 20,  5,  7,  6,  8,
                                                   10, 11, 14, 13, 18, 19,  9, 12, 16, 17 }) };

    EXPECT_THAT(result, Pointwise(Eq(), expected));
}
```

I wynik z&nbsp;konsoli.

```bash
Value of: result
Expected: contains 20 values, where each value and its corresponding value in { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 } are an equal pair
  Actual: { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 15, 17, 18, 19, 20 }, where the value pair (16, 15) at index #14 don't match
```

Nie tylko dostajemy numer indeksu niepasujących wartości ale również jakie one są. Jedynym minusem jest fakt, że&nbsp;zostajemy poinformowani tylko o&nbsp;pierwszej niepasującej parze wartości. Innym przypadkiem może być sytuacja, w&nbsp;której porównujemy kontener z&nbsp;elementami typu struktury lub klasy z&nbsp;operatorem porównania za pomocą pętli **for**. Wtedy możemy zastosować ciekawą właściwość makr asercji Google Test i&nbsp;potraktować je jak strumień wyjścia.

```cpp
struct Product
{
    int id;
    std::string name;

    auto operator==(const Product& other) const -> bool
    {
        return id == other.id and name == other.name;
    }

    friend auto operator<<(std::ostream& os, const Product& product) -> std::ostream&
    {
        return os << "Product{ id: " << product.id << ", name: " << product.name << " }";
    }
};

class Warehouse
{
public:
    auto getProducts() const -> std::vector<Product>
    {
        return { Product{ 1, "Keyboard" }, Product{ 2, "Gamepad" } };
    }
};

TEST_F(WarehouseTest, getProducts_WhenInventoryNotEmpty_ReturnsAllItemsWithStreamInfo)
{
    const std::vector<Product> expectedItems{ Product{ 1, "Keyboard" }, Product{ 2, "Mouse" } };
    Warehouse warehouse{};

    const auto resultItems{ warehouse.getProducts() };

    ASSERT_THAT(resultItems.size(), Eq(expectedItems.size()));
    for (std::size_t idx{ 0 }; idx < resultItems.size(); ++idx)
    {
        EXPECT_THAT(resultItems.at(idx), Eq(expectedItems.at(idx)))
            << " mismatch at index: " << idx;
    }
}
```

A tak się prezentuje komunikat w&nbsp;konsoli.

```bash
[ RUN      ] WarehouseTest.getProducts_WhenInventoryNotEmpty_ReturnsAllItemsWithStreamInfo

Value of: resultItems.at(idx)
Expected: is equal to Product{ id: 2, name: Mouse }
  Actual: Product{ id: 2, name: Gamepad } (of type Product)
 mismatch at index: 1

[  FAILED  ] WarehouseTest.getProducts_WhenInventoryNotEmpty_ReturnsAllItemsWithStreamInfo (0 ms)
```

Dzięki zastosowaniu **operator<<**, widzimy co znajduje się w&nbsp;strukturach. Natomiast dzięki dodaniu komunikatu na końcu asercji mamy informację o&nbsp;tym, który element nie pasuje do wartości oczekiwanej.

### Komunikaty wyjątków

Okazuje się, że&nbsp;matchery nie zawsze są idealnym rozwiązaniem i choć kod testu wygląda elegancko to jest to okupione bardzo słabym komunikatem w przypadku niepowodzenia naszego unit testu. Na&nbsp;taką sytuację możemy natrafić, gdy&nbsp;zależy nam na zweryfikowaniu, nie&nbsp;tylko czy i jaki wyjątek powinna rzucać testowana metoda, ale&nbsp;również chcemy mieć pewność, że&nbsp;niesiony przez wyjątek komunikat zawiera konkretną treść. Ważne w przypadkach, gdy&nbsp;testowana metoda może rzucić wiele wyjątków tego samego typu, ale&nbsp;z&nbsp;różnych powodów. By&nbsp;to zweryfikować musimy sprawdzić jaki komunikat o błędzie dany wyjątek ma w sobie.

Przyjrzyjmy się najpierw temu jakże pięknemu testowi! Jego kod jest przejrzysty, matcher jasno określa co jest sprawdzane i jaki komunikat jest oczekiwany.

```cpp
TEST_F(LevelLoaderTests, load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage)
{
    const std::string expectedMessage{ "Level data cannot be empty" };
    const std::string emptyLevelData{ "" };
    const LevelLoader loader{};

    EXPECT_THAT(
        [&]()
        {
            loader.load(emptyLevelData);
        },
        testing::ThrowsMessage<std::runtime_error>(testing::StrEq(expectedMessage))
    );
}
```

Widać tutaj, że&nbsp;bloki **Act** i **Assert** są połączone, nie&nbsp;jest możliwe oddzielić asercji od wykonania metody jeśli oczekiwanym wynikiem ma być rzucenie wyjątku. A&nbsp;teraz druga wersja tego testu. Tym&nbsp;razem matcher też ma tutaj swoje zastosowanie ale już w mniejszym zakresie.

```cpp
TEST_F(LevelLoaderTests, load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage)
{
    const std::string expectedMessage{ "Level data cannot be empty" };
    const std::string emptyLevelData{ "" };
    const LevelLoader loader{};

    try
    {
        loader.load(emptyLevelData);
        FAIL() << " LevelLoader::load() should throw std::runtime_error when level data is empty.";
    }
    catch (const std::runtime_error& ex)
    {
        EXPECT_THAT(std::string{ ex.what() }, StrEq(expectedMessage));
    }
}
```

Na pierwszy rzut oka, gdy&nbsp;je porównamy to pierwsza wersja wydaje się lepsza i sam bym ją pewnie wybrał oraz zatwierdził w code review, ale&nbsp;najpierw sprawdźmy jakie komunikaty generują oba testy, gdy&nbsp;nasza testowana metoda rzuci, wprawdzie wyjątek ale z innym komunikatem.

Oto wyjście z pierwszej wersji testu:

```bash
[ RUN      ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage

Value of: [&]() { loader.load(emptyLevelData); }
Expected: throws an exception which is a std::runtime_error which contains .what() that is equal to "Level data cannot be empty"
  Actual: 8-byte object <AB-F9 BC-03 AC-F9 BC-03>, throws an exception which is a std::runtime_error which contains .what() (of value = Corrupted level header) that

[  FAILED  ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage (34 ms)
```

A to z drugiej wersji:

```bash
[ RUN      ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage

Value of: std::string{ ex.what() }
Expected: is equal to "Level data cannot be empty"
  Actual: "Corrupted level header"

[  FAILED  ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage (33 ms)
```

I co tu zrobić? No&nbsp;nie wiem jak dla Ciebie, ale&nbsp;dla mnie ten drugi jest bardziej czytelny. Pozostałe wnioski pozostawiam Tobie :)

A na koniec jeszcze logi, gdy&nbsp; wyjątek w ogóle nie zostanie rzucony:

```bash
[ RUN      ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage

Value of: [&]() { loader.load(emptyLevelData); }
Expected: throws an exception which is a std::runtime_error which contains .what() that is equal to "Level data cannot be empty"
  Actual: 8-byte object <AB-F9 BE-03 AC-F9 BE-03>, does not throw any exception

[  FAILED  ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage (29 ms)
```

I z drugiej wersji:

```bash
[ RUN      ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage

Failed
 LevelLoader::load() should throw std::runtime_error when level data is empty.

[  FAILED  ] LevelLoaderTests.load_EmptyLevelData_ThrowsRuntimeErrorWithEmptyLevelDataMessage (11 ms)
```

### Podsumowanie

Na ten moment to już wszystko ode mnie w&nbsp;temacie poprawy czytelności wyników testów. Jeśli natrafię na inne przypadki, gdzie testy nie są zbyt rozmowne to z&nbsp;pewnością postaram się zaprezentować nowe przykłady i&nbsp;dodam je do tego wpisu. Mam&nbsp;nadzieję, że&nbsp;przedstawiona tutaj treść pomoże Ci pisać nie tylko lepsze i&nbsp;bardziej skuteczne unit testy, ale&nbsp;również bardziej konkretne komunikaty, gdy&nbsp;testy failują. Jeśli masz inne przypadki, gdzie logi wyników testów bywają słabo pomocne opisz problem w&nbsp;komentarzu lub napisz do mnie bezpośrednio! Podziel się również swoją opinią na temat tego wpisu i&nbsp;ogólnie co myślisz o&nbsp;moim blogu. Chętnie dowiem się Twojej opinii! :)

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}
