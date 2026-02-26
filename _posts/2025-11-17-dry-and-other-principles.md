---
title: "DRY, YAGNI, KISS i inne. Uniwersalne zasady dla każdego programisty."
date: 2025-11-17
author: "Tadeusz Biela"
categories:
  - clean-code
tags:
  - clean code
  - code quality
  - developer practices
  - software
---

Te tajemnicze akronimy skrywają w&nbsp;sobie dekady doświadczeń naszych programistycznych poprzedników. Choć brzmi to nieco patetycznie, tak&nbsp;właśnie jest. Zasady, opisane w&nbsp;tym wpisie, to&nbsp;dziedzictwo wielu błędów, obserwacji i&nbsp;celnych spostrzeżeń, zbieranych latami przez bardzo doświadczonych ludzi dla ich następców. Te&nbsp;zasady działają jak sita. Przesiany przez nie kod staje się znacznie lepszy, bardziej czytelny, odporny na błędy i&nbsp;łatwiejszy w&nbsp;utrzymaniu.

### Po co nam zasady?

Zasady w&nbsp;programowaniu wytyczają nam szlak - kierunek, w&nbsp;jakim powinniśmy podążać, aby&nbsp;uzyskać kod wysokiej jakości. Każda z&nbsp;poniższych reguł, o&nbsp;których wspominam w&nbsp;tym wpisie, dotyka nieco innych aspektów wytwarzanego przez nas oprogramowania. Tworzą one niejako pewien standard. Można oczywiście pisać kod i&nbsp;bez nich, tylko po co? DRY&nbsp;i&nbsp;inne zasady to ogrom doświadczenia naszych poprzedników, z&nbsp;którego powinniśmy korzystać, ucząc się na ich błędach i&nbsp;kto wie, może formułować nowe? Czemu by nie!

Co daje nam trzymanie się dobrych zasad programowania?
1. Ułatwiają utrzymanie kodu.
2. Zmniejszają ryzyko wystąpienia błędów.
3. Umożliwiają dobrą współpracę między twórcami i&nbsp;odbiorcami kodu.
4. Tworzą bardziej uporządkowany projekt.
5. Pomagają podejmować odpowiedzialne decyzje.

A&nbsp;teraz przejdźmy już do konkretów.

### DRY - jedno źródło informacji

DRY - Don't Repeat Yourself - unikaj powielania wiedzy. Zasada ta jest prosta, jeśli widzisz w&nbsp;swoim kodzie ciągle powtarzające się linijki, to&nbsp;należy je odpowiednio nazwać i&nbsp;przenieść do funkcji lub metody, w&nbsp;zależności od kontekstu. Dzięki temu, gdy&nbsp;przyjdzie czas na zmianę (a&nbsp;z&nbsp;pewnością przyjdzie), będziemy musieli edytować tylko jedno miejsce, a&nbsp;nie wiele. Unikniemy sytuacji, gdy&nbsp;trzeba zmienić kod w&nbsp;kilku miejscach i&nbsp;o&nbsp;którymś zapomnimy. Daje nam to również możliwość zwiększenia czytelności naszego kodu. Nowa funkcja czy metoda musi mieć nazwę, warto, by&nbsp;była ona wyjaśniająca, tłumaczyła w&nbsp;krótki sposób, co&nbsp;robi wewnątrz.

```cpp
auto calculateSalary(const Employee& employee) -> Money
{
    if(18 <= employee.getAge())
    {
        //...
    }
    else
    {
        //...
    }
}

auto freeDays(const Employee& employee) -> int
{
    if(18 <= employee.getAge())
    {
        //...
    }
    else
    {
        //...
    }
}
```

Widać tutaj powtórzenie, **"18&nbsp;<=&nbsp;employee.getAge()"**. Jest to pewien element wiedzy biznesowej. Jeśli pracownik jest niepełnoletni, to&nbsp;jego wynagrodzenie i&nbsp;liczba dni wolnych jest inna. Spróbujmy to lepiej wyrazić i&nbsp;zastosować DRY.

```cpp
auto isAdult(const Employee& employee) -> bool
{
    const unsigned adultAge{ 18 };
    return adultAge <= employee.getAge();
}

auto calculateSalary(const Employee& employee) -> Money
{
    if(isAdult(employee))
    {
        //...
    }
    else
    {
        //...
    }
}

auto freeDays(const Employee& employee) -> int
{
    if(isAdult(employee))
    {
        //...
    }
    else
    {
        //...
    }
}
```

To tylko prosty przykład, jak&nbsp;możemy stosować DRY. Należy jednak pamiętać, że&nbsp;ta&nbsp;zasada, jak&nbsp;i&nbsp;wszystkie następne, mają nam pomagać tworzyć kod wysokiej jakości. Jak&nbsp;ze wszystkim, tak&nbsp;z&nbsp;DRY, też&nbsp;da&nbsp;się przesadzić. Zauważyłem, że&nbsp;często w&nbsp;unit testach DRY nie do końca się sprawdza.

Mamy klasę **UserService**, która odpowiada za logowanie (pomińmy na razie aspekty security ;) ).

```cpp
class UserService
{
public:
    auto login(const std::string& username, const std::string& password) -> bool
    {
        return username == "admin" && password == "1234";
    }
};

auto checkLogin(UserService& service,
                const std::string& user,
                const std::string& pass,
                bool expected) -> void
{
    EXPECT_EQ(expected, service.login(user, pass));
}

TEST(UserServiceTest, AllLogins)
{
    UserService service{};

    checkLogin(service, "admin", "1234", true);
    checkLogin(service, "admin", "wrong", false);
    checkLogin(service, "user", "1234", false);
}
```

W&nbsp;tym przykładzie testujemy różne sposoby logowania. Wygląda prosto. Nie&nbsp;ma powtórzeń, ale&nbsp;jest tutaj jeden zasadniczy problem - czytelność, a&nbsp;raczej jej brak. Mamy tylko jeden test sprawdzający tę samą jednostkę, ale&nbsp;już w&nbsp;różnych scenariuszach. Nie&nbsp;spełnia on standardu [AAA](https://cpptested.com/unit%20testing/AAA-golden-standard/){:target="_blank" rel="noopener"}. Gdy coś pójdzie nie tak, dużo trudniej będzie dowiedzieć się, który scenariusz nie działa poprawnie.

Teraz porównaj to z&nbsp;poniższymi testami.

```cpp
TEST(UserServiceTest, login_ValidCredentials_ReturnTrue)
{
    UserService service{};

    const bool result{ service.login("admin", "1234") };

    EXPECT_TRUE(result);
}

TEST(UserServiceTest, login_WrongPassword_ReturnFalse)
{
    UserService service{};

    const bool result{ service.login("admin", "wrong") };

    EXPECT_FALSE(result);
}

TEST(UserServiceTest, login_UnknownUser_ReturnFalse)
{
    UserService service{};

    const bool result{ service.login("user", "1234") };

    EXPECT_FALSE(result);
}
```

To klasyczny przykład, gdzie czytelność jest wyżej niż DRY. Don't Repeat Yourself to świetna reguła. Pomaga uporządkować kod, ułatwia wprowadzanie zmian i&nbsp;zrozumienie logiki kodu. W&nbsp;testach również ma swoje zastosowanie, lecz&nbsp;nie powinna być regułą wiodącą w&nbsp;nich prym.

DRY to jednak coś znacznie więcej, niż tylko ograniczanie powielania kodu, jak dla mnie najlepiej opisuję tę zasadę Robert C. Martin w swojej bardzo znanej książce - [Czysty Kod. Podręcznik dobrego programisty](https://lubimyczytac.pl/ksiazka/83492/czysty-kod-podrecznik-dobrego-programisty){:target="_blank" rel="noopener"}, którą z czystym sumieniem polecam ;)

### YAGNI - potrzebne ponad możliwe

YAGNI - You Aren't Gonna Need It, ta&nbsp;zasada mówi o tym, że jeśli w&nbsp;danym momencie rozwoju oprogramowania nie potrzebujesz jakiejś funkcjonalności, to&nbsp;jej nie dodawaj. Czasem chcemy wychodzić naprzeciw oczekiwaniom użytkowników naszego kodu, lub&nbsp;staramy się przewidzieć, co&nbsp;jeszcze będzie potrzebne. Zapominamy jednak o&nbsp;czymś bardzo istotnym. Założenia się zmieniają. To,&nbsp;co&nbsp;wydawało nam się być potrzebne, choć nie planowane, po&nbsp;chwili może wylądować w&nbsp;gitowej historii.

W&nbsp;tej regule nie chodzi o&nbsp;to, by&nbsp;nie myśleć o&nbsp;przyszłości, o&nbsp;architekturze. Projekt jest ważny, umożliwia rozwój oprogramowania w&nbsp;jasno określonym kierunku i&nbsp;określony sposób. Bierze pod uwagę różne aspekty, takie jak elastyczność, łatwość utrzymania, koszty wytworzenia i&nbsp;wiele innych.

YAGNI nie mówi o&nbsp;tym, byś&nbsp;nie planował, nie&nbsp;przewidywał. Mówi o&nbsp;tym, byś&nbsp;nie implementował czegoś, co&nbsp;może okazać się niepotrzebne.

Wróćmy do **UserService**. Założenie jest proste, klasa odpowiada za logowanie. Można by przewidzieć, co&nbsp;będzie jeszcze potrzebne do logowania i&nbsp;nasza klasa rozrośnie się.

```cpp
class UserService
{
public:
    auto login(const std::string& username, const std::string& password) ->bool
    {
        return username == "admin" && password == "1234";
    }

    auto logout() -> void {}
    auto resetPassword() -> void {}
    auto twoFactorAuth() -> void {}
};
```

Tylko na tym etapie nie wiemy jeszcze, co&nbsp;tak naprawdę się przyda. Jak mamy zastosować TDD, gdy&nbsp;brak jest założeń? Co&nbsp;zrobić z&nbsp;kodem, którego nikt nie używa?

Nie traćmy czasu i&nbsp;zasobów na tworzenie kodu, którego nikt w&nbsp;danym momencie nie potrzebuje. Ogranicza to również koszty, które taki nadmiarowy kod generuje. Trzeba do niego napisać testy (choć w&nbsp;przykładzie dodaliśmy tylko puste metody, więc testów nie napiszemy), utrzymywać, aktualizować, gdy&nbsp;interfejs się zmienia. To&nbsp;są koszty, koszty, które ponosisz Ty, Twój zespół i&nbsp;Twoja firma. Ogranicz zakres zmian do minimum. YAGNI to istota minimalizmu w&nbsp;programistycznym świecie.

### KISS - prosto ale skutecznie

KISS - Keep It Simple, Stupid, dość wymowna nazwa. Kultura w&nbsp;branży IT wydaje mi się na całkiem wysokim poziomie i&nbsp;nikt raczej nie wyzywa nikogo od idiotów :). Zasada ta mówi o&nbsp;tym, aby&nbsp;nie dodawać nadmiernej złożoności do naszego kodu. Kod prosty, to&nbsp;taki kod, który nie tylko łatwo napisać, ale&nbsp;przede wszystkim zrozumieć i&nbsp;zmienić, gdy&nbsp;będzie to potrzebne. Prosty kod też łatwiej się testuje.

Tutaj chcę zaznaczyć, że&nbsp;sama złożoność kodu nie jest zła, jeśli wynika ze złożoności problemu, który rozwiązuje. KISS trochę łączy się z&nbsp;YAGNI, bo&nbsp;możemy dodać więcej kodu, tworząc bardziej elastyczne rozwiązanie, potencjalnie łatwiejsze w&nbsp;rozszerzaniu. Może stosując jakiś wzorzec projektowy.

Tylko decyzja o&nbsp;użyciu wzorca powinna być podejmowana na poziomie architektury. Nie mówię tu o&nbsp;tym, żeby najpierw mieć cały projekt, a&nbsp;potem kod. W&nbsp;Agile tak się nie dzieje. Całe oprogramowanie tworzymy przyrostowo. Mówię o&nbsp;tym, by&nbsp;nie komplikować kodu bez potrzeby i&nbsp;bez planu.

Spójrz na poniższy przykład. Widać w&nbsp;nim pewien zamysł, może plany na przyszłość. Jednak kod jest zbyt zawiły w&nbsp;stosunku do tego, za&nbsp;co jest odpowiedzialny.

```cpp
class IValidator
{
public:
    virtual ~IValidator() = default;
    virtual auto validate(const std::string& value) const -> bool = 0;
};

class EmailValidator : public IValidator
{
public:
    auto validate(const std::string& value) const override -> bool
    {
        return value.contains('@');
    }
};

class PasswordValidator : public IValidator
{
public:
    auto validate(const std::string& value) const override -> bool
    {
        return 8 <= value.size();
    }
};

class UserService
{
public:
    UserService(std::unique_ptr<IValidator> emailValidator,
                std::unique_ptr<IValidator> passwordValidator)
        : emailValidator_(std::move(emailValidator)),
          passwordValidator_(std::move(passwordValidator))
    {}

    auto registerUser(const std::string& email, const std::string& password) -> bool
    {
        return emailValidator_->validate(email) && passwordValidator_->validate(password);
    }

private:
    std::unique_ptr<IValidator> emailValidator_;
    std::unique_ptr<IValidator> passwordValidator_;
};
```

Widać tutaj zdecydowany overengineering. Tyle konstrukcji tylko po to, by&nbsp;sprawdzić dwa proste warunki. Z&nbsp;KISS kod wyglądałby mniej więcej tak.

```cpp
class UserService
{
public:
    auto registerUser(const std::string& email, const std::string& password) -> bool
    {
        if (email.find('@') == std::string::npos)
            return false;

        if (password.size() < 8)
            return false;

        return true;
    }
};
```

Zdecydowanie, w&nbsp;takim przypadku prostota wygrywa. KISS pomaga nam trzymać w&nbsp;ryzach złożoność naszego kodu.

KISS to świetna zasada w&nbsp;połączeniu z&nbsp;TDD. Każda zmiana w&nbsp;kodzie ma sprawić by nowy test przeszedł, nic&nbsp;więcej. TDD zakłada właśnie to, żeby tworzyć kod, który tylko sprawi, że&nbsp;nasz nowy test przejdzie i&nbsp;nie wprowadzi regresji do poprzednich.

Zasada KISS łamana jest najczęściej w&nbsp;trzech przypadkach:

1. Przedwczesna optymalizacja - stosujemy sztuczki w&nbsp;kodzie, które potencjalnie mogą zwiększyć wydajność kodu. Sprawić, że&nbsp;będzie on działał szybciej. Jednak praktycznie nigdy się tego nie mierzy, a&nbsp;sama optymalizacja jest tak naprawdę znikoma lub pozorna. Kompilator nieraz jest w&nbsp;stanie czysty kod lepiej sam zoptymalizować niż z&nbsp;naszymi "sprytnymi" sztuczkami.

2. Nadużywanie wzorców projektowych - sam się na tym złapałem kilka lat temu, gdy&nbsp;poznałem wzorce. Chęć ich wykorzystania była tak duża, że&nbsp;przy jednym z&nbsp;zadań rekrutacyjnych od razu chciałem zastosować fabrykę, a&nbsp;wystarczyłby jeden prosty **if**.

3. Magia w&nbsp;kodzie - metaprogramowanie, refleksje, wiele poziomów abstrakcji. Te&nbsp;wszystkie rzeczy mają swoje zastosowanie, ale&nbsp;są to narzędzia do konkretnych celów. Nie należy ich stosować wszędzie, gdzie popadnie, bo&nbsp;akurat nam pasuje.

Jak stosować KISS w&nbsp;codziennej pracy? Najpierw zrób tak, aby działało, potem uprość kod, a&nbsp;na samym końcu optymalizuj, jeśli jest to potrzebne.

### POLA - to oczywiste!

POLA&nbsp;- Principle Of Least Astonishment, to&nbsp;nic innego jak zasada najmniejszego zaskoczenia. Gdy widzimy nazwę funkcji lub metody klasy, która mówi **A**, to&nbsp;powinna robić **A**, a&nbsp;nie **ABC** plus jeszcze **Z**. Albo w&nbsp;ogóle nie robi **A**, tylko **F**. W&nbsp;tej zasadzie musimy pamiętać, że tworząc kod, należy dobrze opisywać, co&nbsp;on robi, poprzez nadawanie odpowiednich nazw zmiennym, stałym, metodom, funkcjom itp. Kluczem do zachowania POLA&nbsp;jest dobre nazewnictwo. Zwiększa ono czytelność i&nbsp;łatwość zrozumienia naszego kodu, a&nbsp;to bezpośrednio przekłada się na niższy koszt jego utrzymania. Pamiętajmy, że kod zazwyczaj piszemy raz, czytamy natomiast wielokrotnie.

POLA&nbsp;mówi o&nbsp;tym, by&nbsp;nasz kod, był&nbsp;intuicyjny i&nbsp;spójny w&nbsp;zachowaniu. Jeśli metody naszej klasy robią coś innego niż to, na&nbsp;co wskazuje ich nazwa, łatwo popełnić błąd, trudniej korzystać z&nbsp;takiej klasy, jest&nbsp;to bardziej czasochłonne, bo&nbsp;musimy zapoznać się z&nbsp;jej implementacją. Naruszenie tej zasady bywa nieraz bardzo subtelne, dlatego tym bardziej powinniśmy o&nbsp;niej pamiętać.

Mamy tutaj klasę **FileWriter** z&nbsp;jedną metodą **write**. Pozornie wszystko wygląda ok.

```cpp
class FileWriter
{
public:
    auto write(const std::string& path, const std::string& data) -> void
    {
        std::ofstream file(path);
        if (!file.is_open())
        {
            std::filesystem::create_directories(std::filesystem::path(path).parent_path());
            std::ofstream retry(path);
            retry << data;
            return;
        }
        file << data;
    }
};
```

Metoda **write** próbuje otworzyć podany w&nbsp;**path** plik. Jeśli się nie uda, utworzy go wraz z&nbsp;wszystkimi katalogami prowadzącymi do pliku. Tylko czy ta metoda powinna to robić? Co&nbsp;jeżeli, ktoś w&nbsp;**path** popełni tylko literówkę? Nazwa **write** nie mówi o&nbsp;tym, że&nbsp;metoda coś tworzy. Jak&nbsp;w&nbsp;takim razie powinna wyglądać?

```cpp
class FileWriter
{
public:
    auto write(const std::string& path, const std::string& data) -> void
    {
        std::ofstream file(path);
        if (!file.is_open())
        {
            throw std::runtime_error("Cannot open file: " + path);
        }
        file << data;
    }
};
```

Myślę, że&nbsp;rzucenie wyjątku jak najbardziej jest dobrym rozwiązaniem, jeżeli tylko nasz projekt zakłada ich użycie. Jeśli chcesz poznać więcej szczegółów dotyczących sytuacji wyjątkowych, to&nbsp;odsyłam do mojego wpisu o&nbsp;[wyjątkach](https://cpptested.com/multithreading/exception-in-thread/){:target="_blank" rel="noopener"}.

W&nbsp;takiej formie, użytkownik klasy **FileWriter** nie powinien być zaskoczony wyrzuceniem wyjątku, gdy&nbsp;poda złą ścieżkę do pliku, zwłaszcza, iż&nbsp;metoda **write** nie jest oznaczona jako **noexcept**.

### LoD - im mniej wiesz, tym lepiej

LoD - Law of Demeter, czyli inaczej Principle of Least Knowledge. Zasada najmniejszej wiedzy mówi o&nbsp;tym, by&nbsp;metoda wykorzystywała tylko to, co&nbsp;sama&nbsp;"wie".

Metoda w&nbsp;klasie powinna komunikować się tylko z&nbsp;obiektami, które zna bezpośrednio. Sprowadza się to do używania tylko własnych pól klasy, przekazanych argumentów, stworzonych przez tę metodę obiektów i&nbsp;ewentualnie elementów globalnych (tak,&nbsp;tak, te&nbsp;ostatnie to zazwyczaj oznaka problemów projektowych, choć&nbsp;nie zawsze. Może napiszę osobny post, jak radzić sobie z&nbsp;globalami w&nbsp;testach).

Przyjrzyjmy się metodzie **sendReport** klasy **ReportService**. Metoda ta korzysta z&nbsp;wszystkich rodzajów dostępnej wiedzy, zachowując jednocześnie LoD.

```cpp
class Report
{
public:
    auto generate() const -> std::string
    {
        return "Daily report data";
    }
};

class EmailClient
{
public:
    auto send(const std::string& recipient, const std::string& content) -> void
    {
        std::cout << "Sending email to " << recipient << " with content:\n"
                  << content << "\n";
    }
};

class Config
{
public:
    static auto getDefaultRecipient() -> std::string
    {
        return "admin@example.com";
    }
};

class ReportService
{
public:
    auto sendReport(const std::string& customRecipient = "") -> void
    {
        // użycie argumentu metody
        std::string recipient{ customRecipient.empty()
            ? Config::getDefaultRecipient()  // globalne źródło wiedzy
            : customRecipient };

        // stworzenie i użycie obiektu lokalnego
        Report report;
        const std::string content{ report.generate() };

        // wysłanie raportu przez własne pole emailClient_
        emailClient_.send(recipient, reportTitle_ + "\n" + content);
    }

private:
    EmailClient emailClient_;
    std::string reportTitle_{ "Daily Report" };
};
```

W&nbsp;Law od Demeter chodzi o&nbsp;ograniczanie łańcuchów wywołań.

```cpp
order.getCustomer().getAddress().getCity().getName();
```

Zamiast takiego łańcuszka powinniśmy dążyć do tego, aby&nbsp;klasa order udostępniła nazwę miasta klienta bezpośrednio.

```cpp
order.getCustomerCityName();
```

Wewnątrz tej metody nie powinno być kolejnego, nieco krótszego łańcucha tylko coś w&nbsp;tym rodzaju.

```cpp
auto Order::getCustomerCityName() const -> std::string
{
    return customer_.getCityName();
}
```

Zaletą stosowania LoD jest zmniejszenie sprzężenia między klasami. Poprawia się również czytelność kodu.

### COI - niczym klocki Lego

COI - Composition Over Inheritance, dziedziczenie to potężny mechanizm niosący za sobą bardzo cenną mechanikę - polimorfizm. Jednak ma ono też drugie oblicze, łatwo można przesadzić. Hierarchia dziedziczenia powinna odzwierciedlać zależności typu "jest", a&nbsp;nie "ma". Jeśli klasa dziedziczy po innej tylko dlatego, że&nbsp;część jej funkcjonalności by się przydała, to&nbsp;należy dodać potrzebny obiekt jako nowe pole klasy zamiast po niej dziedziczyć.

Ta zasada nie mówi o&nbsp;tym, by&nbsp;z&nbsp;dziedziczenia nie korzystać, lecz o&nbsp;tym, by&nbsp;korzystać z&nbsp;niego mądrze. Kompozycja daje nam większą elastyczność kodu. Elementy, jako że&nbsp;są to pola klasy, można łatwo dodawać, usuwać czy wymieniać. Wewnętrzna implementacja klasy rodzica, może się zmienić i&nbsp;dużo łatwiej ta zmiana może negatywnie odbić się na naszej klasie, gdy&nbsp;po niej dziedziczy, niż&nbsp;gdy jest tylko polem.

Kompozycja ułatwia też testowanie naszej klasy. Tworząc testy, możemy łatwo zastąpić pola klasy mockami poprzez wstrzykiwanie zależności (Dependency Injection). W&nbsp;ten sposób będziemy mogli skupić się na przetestowaniu logiki tylko naszej klasy. W&nbsp;przypadku dziedziczenia, nie&nbsp;możemy już w&nbsp;tak łatwy sposób oddzielić logiki naszej klasy od logiki rodzica. Musimy nie jako przetestować całość, mimo&nbsp;iż&nbsp;klasa rodzica ma swoje testy.

Dziedziczenie dużo mocniej wiąże ze sobą klasy, co&nbsp;utrudnia ich ponowne użycie. Jeśli nie tworzą spójnej całości, może się okazać, że&nbsp;zamiast ponownie skorzystać z&nbsp;już napisanego kodu, musimy nie jako napisać go od nowa. Boleśnie się o&nbsp;tym przekonałem, gdy&nbsp;zacząłem pisanie swojej drugiej gry. W&nbsp;pierwszej, mocno korzystałem z&nbsp;dziedziczenia, co&nbsp;sprawiło, że&nbsp;nie mogłem w&nbsp;prosty sposób przenieść fragmentu kodu. Musiałbym przenieść kilka klas na raz. To doprowadziło do tego, że&nbsp;zamiast użyć kod ponownie, stał się on tylko przykładem, do&nbsp;którego zaglądam, implementując nową grę.

```cpp
class Shape
{
public:
    virtual ~Shape() = default;
    virtual auto draw() -> void = 0;
};

class Rectangle : public Shape
{
public:
    virtual ~Rectangle() = default;
    virtual auto draw() override -> void
    {
        std::cout << "Drawing rectangle\n";
    }
};

class ColoredRectangle : public Rectangle
{
public:
    ColoredRectangle(const std::string& color)
        : color_(color)
    {}

    auto draw() override -> void
    {
        std::cout << "Drawing " << color_ << " rectangle\n";
    }

private:
    std::string color_;
};
```

Mamy tutaj interfejs **Shape**. Klasa **Rectangle** dziedziczy po interfejsie i&nbsp;to jest jak najbardziej ok. Problem zaczyna się w&nbsp;klasie **ColoredRectangle**, która dziedziczy po **Rectangle**. Co się stanie, jeżeli zaczniemy potrzebować klasy kwadratu z&nbsp;obramowaniem albo animacją? Idąc za dziedziczeniem, utworzymy **BorderedRectangle** i&nbsp;**AnimatedRectangle**. A&nbsp;jeśli będziemy potrzebować kolorowego kwadratu z&nbsp;obramowaniem? Kolejna klasa. A&nbsp;teraz dołóżmy trójkąt. Co wtedy? **Triangle**, **ColoredTriangle**, **BorderedTriangle**, **AnimatedTriangle**? Klasy mnożą się w&nbsp;zastraszającym tempie! Spróbujmy zastosować COI w&nbsp;tym przypadku.

```cpp
class ColoredShape : public Shape
{
public:
    ColoredShape(Shape& shape, const std::string& color)
        : shape_(shape)
        , color_(color)
    {}

    auto draw() override -> void
    {
        std::cout << "Drawing " << color_ << " ";
        shape_.draw();
    }

private:
    Shape& shape_;
    std::string color_;
};
```

Teraz mamy ogólną klasę **ColoredShape**, niezwiązaną bezpośrednio z&nbsp;**Rectangle**. Obie klasy mogą być przetestowane osobno. Dodanie nowego kształtu sprowadza się do utworzenia tylko jednej klasy. Dodanie nowego atrybutu również. Oczywiście i&nbsp;z&nbsp;tym można by powalczyć, tworząc jeszcze bardziej uniwersalne rozwiązanie, ale&nbsp;to tylko przykład.

### Podsumowanie

I to już wszystkie najważniejsze zasady programowania, które każdy programista powinien znać i&nbsp;stosować, aby&nbsp;jego kod był wysokiej jakości. Celowo nie poruszyłem tutaj zestawu zasad SOLID, gdyż&nbsp;one bardziej tyczą się projektowania. Przyjdzie i&nbsp;na to czas :). Tymczasem dziękuję Ci za dotrwanie do końca wpisu. Mam nadzieję, że&nbsp;przekazana tutaj wiedza pomoże Ci w&nbsp;codziennych bataliach z&nbsp;kodem. Jeśli masz pomysły na inne tematy, które mógłbym poruszyć na blogu - napisz w&nbsp;komentarzu.

Mój blog oparty jest na GitHub'ie, stąd trzeba się zalogować do niego, ale&nbsp;spokojnie, to&nbsp;jest odizolowany fragment strony, do&nbsp;którego nie mam bezpośredniego dostępu ;). Podobał Ci się ten wpis? Zapraszam do podzielenia się swoją opinią w komentarzu!

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}
