---
title: "AAA - złoty standard unit testów."
date: 2025-09-15
author: "Tadeusz Biela"
categories:
  - unit-testing
tags:
  - clean code
  - code quality
  - developer practices
  - refactoring
  - software testing
---

Arrange Act Assert – to game changer dla jakości unit testów. Dzięki tym prostym zasadom testy stają się nie tylko bardziej czytelne, lecz&nbsp;mogą stanowić doskonałą dokumentację przypadków użycia naszego kodu. Dzielimy nazwę, jak&nbsp;i&nbsp;kod naszego unit testu, na&nbsp;trzy jasno określone bloki.

A czym jest to całe AAA? Zacznijmy od początku.

### AAA - złoty standard

O zasadzie AAA (triple A) piszę w&nbsp;swojej świetnej książce: [Testy jednostkowe. Świat niezawodnych aplikacji](https://lubimyczytac.pl/ksiazka/243300/testy-jednostkowe-swiat-niezawodnych-aplikacji){:target="_blank" rel="noopener"} (The Art of Unit Testing) - Roy Osherove. Nie&nbsp;jest on wprawdzie jej bezpośrednim autorem, lecz&nbsp;wielkim fanem, zresztą nie tylko on ;). AAA wywodzi się ze środowiska .NET, niemniej, nie&nbsp;jest&nbsp;zależna od użytej technologii. Świetnie sprawdza się również w&nbsp;świecie&nbsp;C++.

No dobrze, ale&nbsp;czym ta zasada jest i&nbsp;o&nbsp;czym mówi?

AAA - mówi o&nbsp;tym, by&nbsp;podzielić test na trzy logiczne bloki: Arrange, Act i&nbsp;Assert.

### Arrange

W&nbsp;pierwszym bloku kodu naszego testu przygotowujemy wszystko, co&nbsp;niezbędne, aby&nbsp;naszą testowaną metodę lub funkcję sprawdzić. Przygotowujemy dane wejściowe oraz oczekiwane dane wyjściowe. Tworzymy stuby i&nbsp;mocki oraz ustawiamy ich niezbędne zachowanie względem naszej testowanej jednostki. W&nbsp;tym bloku możemy także wywołać inne metody testowanej klasy, jeśli są nam potrzebne do uzyskania odpowiedniego stanu obiektu. Oczywiście te metody również powinny być zweryfikowane w&nbsp;osobnych testach.

### Act

Drugim blokiem jest uruchomienie naszej testowanej metody/funkcji. Najczęściej będzie to pojedyncza linijka kodu, ale&nbsp;nie&nbsp;zawsze. Czasem bywa tak, że&nbsp;działanie naszej testowanej metody jest inne, gdy wywołamy ją kilkukrotnie. Jeśli to jest przedmiotem naszego unit testu, to&nbsp;wtedy jak najbardziej również umieszczamy wszystkie wywołania w&nbsp;bloku **Act**.

### Assert

Trzecim i&nbsp;ostatnim blokiem jest weryfikacja. Tutaj sprawdzamy, czy&nbsp;wartości zwracane przez naszą jednostkę są zgodne z&nbsp;oczekiwanymi. Również tutaj weryfikujemy stan obiektu, jeśli jest to oczekiwane zachowanie testowanej metody. Można spotkać się z&nbsp;zasadą "jedna asercja na test". Jeśli potraktujemy ją dosłownie, to&nbsp;powielimy testy tylko po to, by&nbsp;zachować tę zasadę i&nbsp;wywoływać pojedynczy ASSERT w&nbsp;teście. Lecz nie o&nbsp;to w&nbsp;niej chodzi, tylko&nbsp;o&nbsp;spójny kontekst asercji. Samych wywołań może być więcej, jeśli tylko są one ściśle powiązane.

### Przykład użycia triple&nbsp;A

Spójrz na poniższy przykład testu niekorzystającego z&nbsp;AAA, czy&nbsp;potrafisz odgadnąć co jest w&nbsp;zasadzie testowane?

```cpp
TEST_F(TemperatureSensorManagerTest, testCollectingTemperatures)
{
    TemperatureSensorManager manager;

    TemperatureSensorFactoryStub factory;

    const auto expectedSensorName1{ "temp_core_1" };
    manager.addSensor(factory.createSensor(expectedSensorName1, 47.3));
    const auto expectedSensorName2{ "temp_core_2" };
    manager.addSensor(factory.createSensor(expectedSensorName2, -10.0));
    const auto expectedSensorName3{ "temp_board_0" };
    manager.addSensor(factory.createSensor(expectedSensorName3, 65.1));

    auto temps = manager.getTemps();
    ASSERT_EQ(3, temps.size());

    EXPECT_EQ(expectedSensorName1, temps.at(0).getName());
    EXPECT_EQ(expectedSensorName2, temps.at(1).getName());
    EXPECT_EQ(expectedSensorName3, temps.at(2).getName());

    EXPECT_FLOAT_EQ(34.13, manager.getAvgTemp());
}
```

A teraz ten sam test, tylko&nbsp;sformatowany zgodnie z&nbsp;triple A(na co dzień nie dodaję takich komentarzy ;) ):

```cpp
TEST_F(TemperatureSensorManagerTest, testCollectingTemperatures)
{
    //Arrange
    const auto expectedSensorName1{ "temp_core_1" };
    const auto expectedSensorName2{ "temp_core_2" };
    const auto expectedSensorName3{ "temp_board_0" };
    TemperatureSensorFactoryStub factory;
    TemperatureSensorManager manager;

    //Act
    manager.addSensor(factory.createSensor(expectedSensorName1, 47.3));
    manager.addSensor(factory.createSensor(expectedSensorName2, -10.0));
    manager.addSensor(factory.createSensor(expectedSensorName3, 65.1));

    //Assert
    auto temps = manager.getTemps();
    ASSERT_EQ(3, temps.size());
    EXPECT_EQ(expectedSensorName1, temps.at(0).getName());
    EXPECT_EQ(expectedSensorName2, temps.at(1).getName());
    EXPECT_EQ(expectedSensorName3, temps.at(2).getName());
    EXPECT_FLOAT_EQ(34.13, manager.getAvgTemp());
}
```

Od razu widać, co&nbsp;jest przedmiotem testu, co&nbsp;jest wymagane na początku oraz jaki wynik będzie oczekiwany. Mimo&nbsp;iż sama nazwa testu nie mówi nam wiele, szybkie spojrzenie na kod daje jednak jasny obraz tego, co&nbsp;unit test sprawdza. No&nbsp;właśnie, nazwa testu... czy można coś z&nbsp;tym zrobić?

### Nazwa testu

Standard AAA możemy również wykorzystać przy nadawaniu nazw unit testów. Główną zaletą AAA jest poprawa czytelności testów. Dobra nazwa to nie taka prosta sprawa, jeśli&nbsp;nie zna się przydatnych wytycznych.
Dla przykładu zwykła lub "zła" nazwa testu:

```cpp
TEST_F(TemperatureSensorTests, test_no_avg_temp)
```

Czy domyślasz się, co&nbsp;jest testowane? W&nbsp;jakich warunkach? Co&nbsp;jest wynikiem testu?
Jeśli się domyślasz, ale&nbsp;tego nie wiesz, już&nbsp;po samej nazwie, to&nbsp;nie jest ona do końca trafiona, prawda?

Ok, spróbujmy teraz z&nbsp;taką nazwą:

```cpp
TEST_F(TemperatureSensorTests, calculateAverageTemp_emptyTemperatureInput_ReturnZero)
```

Lepiej? Nie wiem jak dla Ciebie, ale&nbsp;dla&nbsp;mnie, tak! Zdecydowanie widać co jest testowane, jak&nbsp;i&nbsp;co będzie wynikiem.
Tym właśnie jest AAA - trzy części nazwy unit testu, w&nbsp;skrócie, schemat budowy nazwy testów wygląda tak:

```cpp
TEST_F(TestowanaKlasaTest, nazwaTestowanejMetody_ScenariuszTestowyZawierającyDaneWejściowe_WynikCzyliToCoMaSięStaćPoWykonaniuTestowanejMetody)
```

Powróćmy do naszego przykładowego unit testu i&nbsp;zastosujmy AAA do jego nazwy. Znając wytyczne, zamiast takiej nazwy:

```cpp
TEST_F(TemperatureSensorManagerTest, testCollectingTemperatures)
```

Powinniśmy otrzymać coś w&nbsp;tym rodzaju:

```cpp
TEST_F(TemperatureSensorManagerTest, addSensor_AddThreeValidSensors_StoreAllSensorsAndReturnCorrectAverageTemperature)
```

Teraz, nie&nbsp;znając ciała testu, łatwo możemy określić co on robi. A&nbsp;dlaczego taki format, a&nbsp;nie inny? Dla przykładu zróbmy listę kilku takich nazw:

```cpp
TEST_F(TemperatureSensorManagerTest, addSensor_AddOneValidSensor_StoreSensorAndReturnAverageTemperatureSameAsSensorTemperature)
TEST_F(TemperatureSensorManagerTest, addSensor_AddTwoSensorsOneValid_StoreOneSensorAndReturnAverageTemperatureSameAsSensorTemperature)
TEST_F(TemperatureSensorManagerTest, addSensor_AddThreeSensorsAllNoValid_NotStoreAnySensorAndReturnZeroAsAverageTemperature)
TEST_F(TemperatureSensorManagerTest, getTemps_NoAddedSensors_ReturnsEmptyContainer)
TEST_F(TemperatureSensorManagerTest, getTemps_ThreeSensorsAdded_ReturnsThreeSensors)
TEST_F(TemperatureSensorManagerTest, getAvgTemp_NoAddedSensors_ReturnsZero)
TEST_F(TemperatureSensorManagerTest, getAvgTemp_AddedOneSensor_ReturnsSameTemperatureAsSensor)
```

Przeglądając taki zestaw nazw, szybko zweryfikujemy, czy&nbsp;i&nbsp;jakie metody naszej klasy są przetestowane oraz w&nbsp;jakich warunkach. To miałem na myśli, pisząc o&nbsp;przypadkach użycia. Wystarczy nam lista nazw unit testów i&nbsp;mamy nie tylko zakres testowania, ale&nbsp;także funkcjonalne i&nbsp;zawsze aktualne sposoby użycia naszej klasy. Nawet osoba nietechniczna będzie w&nbsp;stanie ogarnąć, co&nbsp;jest testowane i&nbsp;w jakim zakresie. Nie&nbsp;musi analizować kodu testów.

### Wyjątki od AAA

Od podziału na 3&nbsp;bloki są pewne wyjątki. Możemy mieć sytuację, gdy&nbsp;chcemy, na&nbsp;przykład przetestować domyślne zachowanie konstruktora i&nbsp;w&nbsp;tym&nbsp;przypadku akurat nie mamy nic do zainicjalizowania. Wtedy po prostu bloku **Arrange** nie ma w teście i&nbsp;to&nbsp;jest&nbsp;ok.

```cpp
TEST_F(DoorsLockTests, constructor_DefaultBehavior_ShouldReturnEmptyTemps)
{
    TemperatureSensorManager manager;

    auto temps = manager.getTemps();
    ASSERT_EQ(3, temps.size());
}
```

Inny przykład, gdy&nbsp;jedynym oczekiwanym wynikiem naszej testowanej metody jest wartość przez nią zwrócona. Wtedy **Act**&nbsp;i&nbsp;**Assert** występują razem.

```cpp
TEST_F(TemperatureSensorManagerTest, getAvgTemp_NoAddedSensors_ReturnsZero)
{
    TemperatureSensorManager manager;

    EXPECT_FLOAT_EQ(0.0, manager.getAvgTemp());
}
```

Możemy również dodać zmienną wynikową, by&nbsp;zachować podział na&nbsp;3&nbsp;bloki. Takie rozwiązanie też jest dobre.

```cpp
TEST_F(TemperatureSensorManagerTest, getAvgTemp_NoAddedSensors_ReturnsZero)
{
    TemperatureSensorManager manager;

    auto result{ manager.getAvgTemp() };

    EXPECT_FLOAT_EQ(0.0, result);
}
```

Ostatnim przykładem może być&nbsp;test zawierający tylko jedną linijkę kodu.

```cpp
TEST_F(TemperatureSensorManagerTest, constructor_DefaultBehavior_ShouldNoThrowAnyException)
{
    EXPECT_NO_THROW(TemperatureSensorManager{});
}
```

Zauważ, że&nbsp;we&nbsp;wszystkich przykładach nazwa wciąż zawiera podział zgodny&nbsp;z&nbsp;AAA. Mimo, że&nbsp;samych bloków może brakować, to&nbsp;wciąż test jest czytelny i&nbsp;łatwy do&nbsp;zrozumienia.

### GWT

W Internecie możesz spotkać się z&nbsp;nazwą GWT. To&nbsp;w&nbsp;zasadzie to samo.
GWT czyli Give(Arrnage) When(Act) Then(Assert). Ja&nbsp;osobiście wolę triple A&nbsp;;)

### Podsumowanie

I to już cały opis triple&nbsp;A. Mam&nbsp;nadzieję, że&nbsp;znajomość złotego standardu podniesie jakość także w&nbsp;Twoich testach. Jak&nbsp;dla mnie AAA naprawdę sporo wnosi i&nbsp;nie widzę żadnych przeciwwskazań do jego stosowania. Po&nbsp;prostu spróbuj!

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}

