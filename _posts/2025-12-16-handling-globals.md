---
title: "Zależności globalne - jak poradzić sobie z&nbsp;nimi w unit testach"
date: 2025-12-16
author: "Tadeusz Biela"
categories:
  - unit-testing
tags:
  - unit testing
  - code quality
  - developer practices
  - refactoring
  - software testing
---

Każdy dobry unit test powinien nie tylko weryfikować nasz kod ale również odcinać zewnętrzne zależności, tak, aby&nbsp;przeprowadzenie testu odbywało się w&nbsp;izolacji. Typów zależności jest kilka, jednak najbardziej problematycznym są te globalne. Zaszyte w&nbsp;naszym kodzie potrafią skutecznie uniemożliwić nam odizolowanie naszej testowanej jednostki. Czy&nbsp;można coś z&nbsp;tym zrobić? Oczywiście! Jest na to kilka naprawdę dobrych technik. A&nbsp;więc zacznijmy od podstaw.

### Czym są zależności globalne

Celowo nie użyłem słowa "zmienne" bo to nie jedyny problem. Możemy natrafić na stałe lub makra, które są zależne od platformy, na której nasz kod jest uruchamiany. Innym rodzajem zależności globalnej będzie [Singleton](https://pl.wikipedia.org/wiki/Singleton_(wzorzec_projektowy)){:target="_blank" rel="noopener"}, z&nbsp;którego nasza testowana klasa korzysta. Kolejnym rodzajem zależności globalnej mogą być zmienne statyczne.

Ostatnią kategorią zależności globalnej jest wolna funkcja! Pewnie pomyślisz coś w&nbsp;stylu: "Ale jak to? To&nbsp;coś złego? Po&nbsp;prostu przetestuję logikę mojej klasy wraz z&nbsp;logiką funkcji!" Oczywiście, jak&nbsp;najbardziej możesz to zrobić i&nbsp;nawet nie będzie to takie złe. Tylko&nbsp;wolna funkcja powinna mieć swój zestaw testów. Po&nbsp;co więc powielać je jako część naszych nowych unit testów? Dobrze by było zasymulować co wolna funkcja ma zwrócić, tak, aby&nbsp;uzyskać pożądany przepływ sterowania w&nbsp;naszym kodzie, bez&nbsp;"wstrzeliwania się" w&nbsp;jej logikę.
Do wolnych funkcji zaliczamy również funkcje i&nbsp;obiekty z&nbsp;biblioteki standardowej lub frameworków oraz statyczne metody klas.

Jak widzisz zależności globalne mają różne formy. W&nbsp;świetnej książce [Praca z&nbsp;zastanym kodem. Najlepsze techniki](https://lubimyczytac.pl/ksiazka/238260/praca-z-zastanym-kodem-najlepsze-techniki){:target="_blank" rel="noopener"} autora Michael'a Feathers'a, polskie tłumaczenie wykonane przez Ireneusza Jakóbika, określa tego rodzaju rozwiązania jako **"spoiny"**. Jak&nbsp;dla mnie bardzo trafne i&nbsp;ciekawe tłumaczenie, które również w&nbsp;moim wpisie się pojawi. Przejdźmy zatem do metod radzenia sobie z&nbsp;nimi.  

### Linkowanie

Jednym z&nbsp;rozwiązań, którym możemy się posłużyć, by&nbsp;odciąć zależności globalne jest proces linkowania. Jeżeli implementacja wolnej funkcji czy Singleton'u jest w&nbsp;pliku **.cpp**. Możemy stworzyć ich odpowiedniki tylko dla testów, które będą zwracać cały czas te same wartości lub mieć implementację z&nbsp;możliwością sterowania co i&nbsp;jak ma być zwracane w&nbsp;testach, tak&nbsp;aby każdy test był niezależny.

Mamy klasę **TemperatureSensor**, która do komunikacji z&nbsp;czujnikiem temperatury wykorzystuje protokół [I²C](https://pl.wikipedia.org/wiki/I%C2%B2C){:target="_blank" rel="noopener"}, który jest zaimplementowany jako wolne funkcje w&nbsp;pliku **I2cBus.hpp** i&nbsp;**I2cBus.cpp**.

Tutaj fragment z&nbsp;implementacji klasy **TemperatureSensor** z&nbsp;użyciem zależności globalnej.

```cpp
auto TemperatureSensor::getAvgTemperature() -> float
{
    if(sensorDrivers_.empty())
      return 0.0f;

    float tempSum{ 0.0f };
    for(const auto& sensorDriver : sensorDrivers_)
    {
        tempSum += i2c::getSensorTemp(sensorDriver.address);
    }

    return tempSum / sensorDrivers_.size();
}
```

Spoinę linkowania możemy zastosować, gdy&nbsp;w&nbsp;pliku nagłówkowym mamy tylko deklarację.

```cpp
namespace i2c
{

auto getSensorTemp(const int sensorAddress) -> float;

}
```

Natomiast definicja znajduje się w&nbsp;pliku źródłowym (.cpp).

```cpp
namespace i2c
{

auto getSensorTemp(const int sensorAddress) -> float
{
    //Tutaj produkcyjna implementacja
}

}
```

W takiej sytuacji możemy stworzyć osobną definicję dla testów w&nbsp;pliku **I2cBusStub.cpp**.

```cpp
namespace i2c
{

auto getSensorTemp(const int sensorAddress) -> float
{
    return 32.1f;
}

}
```

Struktura projektu mogłaby wyglądać tak:

```bash
-project \
  - src\
    - temperatureSensor \
      - I2cBus.hpp
      - I2cBus.cpp
      - TemperatureSensor.hpp
      - TemperatureSensor.cpp
    - tests \
      - stubs
        - I2cBusStub.cpp
      - ut
        - TemperatureSensorTests.cpp
```

W systemie budowany dla testów jako plik źródłowy do nagłówka **I2cBus.hpp** podajemy implementację z&nbsp;folderu **stubs** i&nbsp;spoina gotowa.

W ten sposób w&nbsp;naszych unit testach, nie&nbsp;będziemy korzystać z&nbsp;produkcyjnej implementacji tylko z&nbsp;stubowej/mockowej wersji. O&nbsp;różnicach między stubem, a&nbsp;mockiem pewnie jeszcze napiszę ;). 

Podsumowując zastosowanie spoiny linkowania odbywa się tak:
1. Jeśli trzeba przenosisz implementację zależności globalnej do pliku źródłowego.
2. Tworzysz stuba lub mocka zależności globalnej i&nbsp;dostosowujesz system budowania.

Spoina linkowania jest w&nbsp;mojej ocenie jednak rozwiązaniem ostatecznym. Rozwiązuje wprawdzie problem zależności globalnych lecz ma spore wady. Po&nbsp;pierwsze wymaga dużo czasu. Nie&nbsp;tylko musimy zaimplementować stuba/mocka, ale&nbsp;dodatkowo zmienić także pliki budowania. Drugą wadą jest bardzo słaba czytelność. Nawet dobrze skonfigurowane IDE nieraz ma problem, by&nbsp;otworzyć odpowiedni plik źródłowy zależności globalnej i&nbsp;pracując przy testach otwiera produkcyjną implementację, co&nbsp;może być bardzo mylące, zwłaszcza dla mniej doświadczonych programistów. Po&nbsp;trzecie, nie&nbsp;jest rozwiązaniem dla wszystkich typów zależności globalnych. Spoiną linkowania nie odetniemy zależności do zmiennych statycznych, funkcji **inline** i&nbsp;innych zależności definiowanych w&nbsp;nagłówkach, których z&nbsp;jakiś powodów nie możemy przenieść do plików źródłowych.

Przejdźmy zatem do spoin obiektowych.

### Dependency Injection

Wstrzykiwanie zależności to ogólnie dobra metoda separowania zależnych od siebie klas. W&nbsp;przypadku globalnych zależności ta technika również może pomóc. Możemy ją wykorzystać, gdy&nbsp;nasz kod zależny jest od zmiennych globalnych, Singleton'u, a&nbsp;nawet wolnych funkcji.

Technika ta polega na zmianie bezpośredniego wywołania zależności globalnej, w&nbsp;pole klasy i&nbsp;inicjalizowanie go poprzez dodanie parametru konstruktora. Weźmy na warsztat zmienną globalną.

```cpp

int g_gameObjectsCounter{ 0 };

```

Tutaj przykład jej użycia

```cpp
auto Weapon::fire(const Position& position, const Rotation& position) -> void
{
    auto bullet{ std::make_unique<Bullet>(g_gameObjectsCounter++, bulletTexture, position, position) };

    display_->add(std::move(bullet));
}
```

W takiej wersji zmienna globalna będzie trzymała stan między testami co prowadzi do zależności i&nbsp;złamania zasady **I** z&nbsp;[F.I.R.S.T.](https://cpptested.com/unit%20testing/first-reguly-ut/){:target="_blank" rel="noopener"}.

Teraz spróbujmy przekazywać wartość zmiennej globalnej jako parametr konstruktora testowanej klasy. Plik nagłówkowy będzie wyglądał następująco.

```cpp
class Weapon
{
public:
    Weapon(int& bulletId = g_gameObjectsCounter);
    //...
private:
    int& bulletId_;
    //...
};
```

Jak widać, możemy nadać bardziej konkretną nazwę, przekazanej zmiennej globalnej, co&nbsp;poprawia czytelność dodając więcej kontekstu do miejsca jej użycia.

```cpp
Weapon::Weapon(int& bulletId)
  : bulletId_(bulletId)
{}

auto Weapon::fire(const Position& position, const Rotation& position) -> void
{
    auto bullet{ std::make_unique<Bullet>(bulletId_++, bulletTexture, position, position) };

    display_->add(std::move(bullet));
}
```

W każdym teście możemy przekazywać dowolną zmienną, a&nbsp;testy stają się niezależne. W&nbsp;kodzie produkcyjnym niewiele się zmieni. Dodatkowo możemy zdefiniować domyślną wartość nowego parametru i&nbsp;ustawić ją właśnie na zmienną globalną. Zaletą takiego podejścia jest wyrzucenie użycia zmiennej globalnej poza implementację klasy. Możemy też nadać jej lepszą nazwę, bardziej związaną z&nbsp;kontekstem samej klasy. Zmienne globalne zazwyczaj mają bardziej ogólne nazwy. Możemy nawet dojść do miejsca, w&nbsp;którym ta zmienna globalna stanie się tak naprawdę lokalną zmienną tworzoną na stosie funkcji **main**.

Spróbujmy teraz nieco trudniejszy przypadek - Singleton. Wystarczy nam jego plik nagłówkowy. Sama implementacja do zastosowania **Dependency Injection** nie jest nam potrzebna.

```cpp
class TextureStorage
{
public:
    TextureStorage(const TextureStorage&) = delete;
    TextureStorage& operator=(const TextureStorage&) = delete;
    TextureStorage(TextureStorage&&) = delete;
    TextureStorage& operator=(TextureStorage&&) = delete;

    static const auto instance() -> TextureStorage&;
    auto getTexture(const TextureId& id) -> const Texture&;

private:
    std::map<TextureId, Texture> textures_;

    TextureStorage();
    ~TextureStorage();
};
```

A tutaj jego użycie w&nbsp;naszej testowanej klasie **Player**.

```cpp
Player::Player(const Position& position, const Rotation& rotation)
  : position_(position)
  , rotation_(rotation)
{
    const auto& graphicsStorage{ TextureStorage::instance() };
    texture = getTexture(TextureId::PLAYER);

    //Reszta implementacji konstruktora...
}

auto Player::changeLook(const TextureId& newTexture) -> void
{
    const auto& graphicsStorage{ TextureStorage::instance() };
    texture = getTexture(newTexture);
}
```

Najpierw będziemy potrzebowali wydzielić potrzebny interfejs dla Singleton'u.

```cpp
class ITextureStorage
{
public:
    virtual ~ITextureStorage() = default;
    virtual auto getTexture(const TextureId& id) const -> const Texture& = 0;
};
```

Czasem spotykam się z&nbsp;opinią, że&nbsp;dodawanie litery **I** do nazwy interfejsu to zły pomysł. Jak&nbsp;dla mnie uwidacznia on zastosowanie interfejsu co jest zaletą.

Teraz sam Singleton będzie dziedziczył po nowym interfejsie.

```cpp
class TextureStorage : public ITextureStorage
{
public:
//...
};
```

W naszej klasie **Player** należy dodać referencję do **ITextureStorage** i&nbsp;przekazać ją w&nbsp;konstruktorze.

```cpp
class Player
{
public:
    Player(const Position& position, const Rotation& rotation rotation, const ITextureStorage& textureStorage);

    //...
private:
    const ITextureStorage& textureStorage_;
    //...
};
```

Dzięki takiemu zabiegowi, będziemy mogli w&nbsp;testach przekazać mocka, który również dziedziczy po tym samym interfejsie co Singleton. Umożliwi nam to pełne i&nbsp;dowolne sterowanie jego zachowaniem w&nbsp;naszej testowanej klasie. W&nbsp;podobny sposób możemy poradzić sobie ze statycznymi obiektami.

Ogólna zasada jest taka:
1. Dodajesz parametr do konstruktora
2. Tworzysz pole i&nbsp;przekazujesz zależność globalną poprzez konstruktor.

Jedyną wadę jaką mogę tutaj dostrzec jest czasochłonność takiego rozwiązania. Trzeba dodać nieraz sporo kodu, aby&nbsp;móc skorzystać w&nbsp;pełni z&nbsp;tej techniki. Choć&nbsp;i&nbsp;tak wydaje mi się, że&nbsp;nakładu pracy jest mniej niż w&nbsp;spoinie linkowania.

### Wrapper

Ostatnim i&nbsp;w&nbsp;mojej ocenie najlepszym rozwiązaniem do szybkiego, poprawnego i&nbsp;efektywnego odcięcia zależności globalnej jest **wrapper**. To&nbsp;nic innego jak opakowanie użycia globala w&nbsp;metodę. Metodę tą definiujemy jako **virtual** w&nbsp;sekcji **protected**. Tylko co nam to daje? Chyba najłatwiej będzie to zrozumieć na przykładzie.

Mamy klasę **LoanScheduleGenerator**, która wykorzystuje zmienną globalną **g_interestRate** w&nbsp;metodzie **generate**.

```cpp
double g_interestRate{ 0.035 };

auto LoanScheduleGenerator::generate(const Loan& loan) -> PaymentSchedule
{
    const unsigned numOfMonths{ 12 };
    double monthlyRate{ g_interestRate / numOfMonths };
    // dalsza część implementacji generowania harmonogramu spłaty kredytu
}
```

Dodajemy wirtualną metodę **getInterestRate** w&nbsp;sekcji **protected**.

```cpp
class LoanScheduleGenerator
{
public:
    //...
protected:
    virtual auto getInterestRate() const -> double;
    //...
};
```

Następnie umieszczamy w&nbsp;niej globalną zależność. I&nbsp;zastępujemy bezpośrednie użycie globala **wrapperem**.

```cpp
auto LoanScheduleGenerator::getInterestRate() const -> double
{
    return g_interestRate;
}

auto LoanScheduleGenerator::generate(const Loan& loan) -> PaymentSchedule
{
    const unsigned numOfMonths{ 12 };
    double monthlyRate{ getInterestRate() / numOfMonths };
    // dalsza część implementacji generowania harmonogramu spłaty kredytu
}
```

Przejdźmy do testów. Dzięki **wrapperowi** możemy stworzyć klasę **Testable**, dziedziczącą po klasie **LoanScheduleGenerator**, którą chcemy przetestować i&nbsp;właśnie w&nbsp;niej przysłaniamy **wrappera** nadając mu potrzebne zachowanie.

```cpp
class LoanScheduleGeneratorTestable : public LoanScheduleGenerator
{
public:
    //...

private:
    auto getInterestRate() const override -> double
    {
        return 1.0;
    }
};
```

W ten sposób odcinamy zależność, minimalizując przy tym ingerencję w&nbsp;kod produkcyjny. Zastosowanie **wrappera** sprowadza się do kilku kroków:
1. Tworzysz wirtualną metodę w&nbsp;sekcji **protected** testowanej klasy (**wrapper**).
2. Przenosisz wywołanie zależności globalnej do tej metody.
3. Zastępujesz użycie globala **wrapperem**.
4. Tworzysz klasę pochodną od klasy testowanej z&nbsp;postfixem **Testable** i&nbsp;przysłaniasz w&nbsp;niej **wrapper**.

### Podsumowanie

I to już wszystko co chciałem przekazać Ci w&nbsp;temacie odcinania zależności globalnych w&nbsp;testach. Mam&nbsp;nadzieję, że&nbsp;dzięki tym technikom, dużo&nbsp;prościej będzie Ci pracować z&nbsp;Twoimi testami. Celowo nie wspomniałem o&nbsp;spoinach kompilacyjnych (z użyciem preprocesora), gdyż&nbsp;uważam je za bardzo mało intuicyjne i&nbsp;z&nbsp;powodzeniem można użyć spoin obiektowych. Niemniej dla ciekawych odsyłam do książki, o&nbsp;której wspomniałem na początku wpisu.

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}
