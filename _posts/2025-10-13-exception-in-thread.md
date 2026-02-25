---
title: "Wątki i wyjątki. Jak radzić sobie z&nbsp;nieoczekiwanymi zachowaniami w&nbsp;wielowątkowym kodzie."
date: 2025-10-13
author: "Tadeusz Biela"
categories:
  - multithreading
tags:
  - cpp
  - exceptions
  - multithreading
  - software
---

Nieoczekiwane zachowanie czyli wyjątek to sytuacja, w&nbsp;której nasz kod zachował się w&nbsp;sposób, który&nbsp;normalnie nie występuje. Może&nbsp;być to wywołane problemami z&nbsp;zasobami jak brak pamięci podręcznej lub brak dostępu do pliku. Powodów może być wiele, najczęściej nie zależą od nas. Jednak możemy się na takie sytuacje przygotować i&nbsp;pomimo wystąpienia wyjątków, nasz&nbsp;program nie przerwie działania.

### Rodzaje wyjątków

Rodzajów wyjątków w&nbsp;STL mamy całkiem sporo i&nbsp;są one pogrupowane w&nbsp;podklasy dziedziczące po **std::exception**. I&nbsp;tak mamy na przykład **std::runtime_error**, który&nbsp;sam w&nbsp;sobie nie jest zgłaszany, jest&nbsp;jednak klasą bazową dla innych, między innymi **std::range_error**, **std::overflow_error**, **std::underflow_error**. Część wyjątków dodana została w&nbsp;późniejszych wersjach C++.

Wyjątki dotyczą różnych problemów, na które nasz program może natrafić, brak elementu w&nbsp;kontenerze - **std::out_of_range**, rzutowanie referencji typów niepołączonych hierarchią - **std::bad_cast** (przy wskaźnikach dostaniemy **nullptr**, a&nbsp;wyjątek nie jest rzucany) czy problemy z&nbsp;alokowaniem pamięci - **std::bad_alloc**. To&nbsp;tylko kilka przykładów, po&nbsp;dokładne szczegóły odsyłam do dokumentacji: [std::exception](https://en.cppreference.com/w/cpp/error/exception.html){:target="_blank" rel="noopener"}.

Prócz standardowych wyjątków, możemy również zdefiniować własne, po&nbsp;prostu dziedzicząc po **std::exception** lub jej klasie pochodnej.

```cpp
class ReadFileException : public std::exception
{
public:
	explicit ReadFileException(const std::string& fileName)
	 : fileName_(fileName)
	{}

	auto what() const noexcept override -> const char*
	{
		return fileName_.c_str();
	}

private:
	const std::string fileName_;
};
```

### Rzucanie i&nbsp;łapanie wyjątków

Rzucanie wyjątków w&nbsp;C++ jest banalnie proste, wystarczy użyć słowa kluczowego **throw** na obiekcie klasy wyjątka. Najczęściej będzie to obiekt tymczasowy. Jeszcze nie spotkałem się, z&nbsp;potrzebą składowania obiektów wyjątków, niemniej jest to jak najbardziej możliwe.

```cpp
throw ReadFileException{ "file.txt" };
```

Jak widać, rzucanie wyjątków jest proste, łatwe i&nbsp;czytelne. Inaczej jest z&nbsp;ich łapaniem. Obsługa wyjątków C++ jest już bardziej złożona. Do&nbsp;przechwytywania wyjątków służy blok **try/catch**.

```cpp
try
{
    if(fileHandler.openFile("file.txt"))
    {
        const auto fileContent{ fileHandler.read() };
        //...
    }
    fileHandler.closeFile();
}
catch(const ReadFileException& ex)
{
    std::cout << "Cannot read file: " << ex.what() << "\n";
    fileHandler.closeFile();
}
```

Block **try** jest prosty, to&nbsp;w&nbsp;nim umieszczamy kod, który&nbsp;może rzucić wyjątek. Block **catch** służy do przechwytywania wyjątków określonego typu oraz ich obsługi, na&nbsp;przykład zwolnienie zasobów takich jak pamięć czy mutex. Po&nbsp;opuszczeniu bloku **catch**, praca programu będzie kontynuowana. Bloków **catch** może być wiele, w&nbsp;zależności od tego jakie operacje muszą zostać wykonane w&nbsp;stosunku do typu rzuconego wyjątku.

```cpp
try
{
    if(fileHandler.openFile("file.txt"))
    {
        const auto fileContent{ fileHandler.read() };
        //...
    }
    fileHandler.closeFile();
}
catch(const ReadFileException& ex)
{
    std::cout << "Cannot read file: " << ex.what() << "\n";
    fileHandler.closeFile();
}
catch(const std::system_error& ex)
{
    std::cout << ex.what() << " with code: " << ex.code() << "\n";
    return 0;
}
```

Dodatkowo wyjątki łapane są według hierarchii dziedziczenia, to&nbsp;znaczy, że&nbsp;jeśli nie zdefiniujemy w&nbsp;bloku **catch** określonego typu wyjątku, ale&nbsp;jego rodzica już tak, to&nbsp;ten wyjątek również zostanie obsłużony.

```cpp
try
{
    if(fileHandler.openFile("file.txt"))
    {
        const auto fileContent{ fileHandler.read() };
        //...
    }
    fileHandler.closeFile();
}
catch(const std::system_error& ex)
{
    std::cout << ex.what() << " with code: " << ex.code() << "\n";
    return 0;
}
catch(const std::exception& ex) // ReadFileException zostanie tutaj przechwycony
{
    std::cout << "Cannot read file: " << ex.what() << "\n";
    fileHandler.closeFile();
}
```

Należy zwrócić uwagę na hierarchię dziedziczenia, jeśli pierwszy blok **catch** będzie ustawiony na klasę bazową, a&nbsp;następny na klasę pochodną, to&nbsp;wyjątek nigdy nie zostanie złapany przez drugi blok **catch**.

```cpp
try
{
    if(fileHandler.openFile("file.txt"))
    {
        const auto fileContent{ fileHandler.read() };
        //...
    }
    fileHandler.closeFile();
}
catch(const std::exception& ex) // Wyjątek typu std::system_error dziedziczy po std::exception i&nbsp;zostanie tutaj przechwycony
{
    std::cout << "Cannot read file: " << ex.what() << "\n";
    fileHandler.closeFile();
}
catch(const std::system_error& ex) // Ten kod nigdy się nie wykona
{
    std::cout << ex.what() << " with code: " << ex.code() << "\n";
    return 0;
}
```

Kompilator może nas poinformować ostrzeżeniem w&nbsp;stylu:

```bash
main.cpp:71:1: warning: exception of type ‘std::system_error’ will be caught by earlier handler [-Wexceptions]
   71 | catch(const std::system_error& ex)
      | ^~~~~
main.cpp:66:1: note: for type ‘std::exception’
   66 | catch(const std::exception& ex)
      | ^~~~~
```

Bywają jednak takie sytuacje, gdy&nbsp;chcemy, by&nbsp;każdy wyjątek obsłużyć tak samo i&nbsp;nie ma dla nas znaczenia jaki to typ. Jest&nbsp;na to sposób. C++&nbsp;nieczęsto stosuje składnię z&nbsp;użyciem wielokropka (**...**). To&nbsp;właśnie jeden z&nbsp;tych przypadków.

```cpp
try
{
    if(fileHandler.openFile("file.txt"))
    {
        const auto fileContent{ fileHandler.read() };
        //...
    }
    fileHandler.closeFile();
}
catch(...) // Łapiemy wszystkie wyjątki lecz kosztem braku informacji z&nbsp;metody what()
{
    fileHandler.closeFile();
}
```

Wielokropek powinien być używany jako ostatni blok **catch**. Nie&nbsp;zalecałbym takiej obsługi wyjątków jako domyślny sposób. Niemniej, warto wiedzieć o&nbsp;jego istnieniu ;).

Wszystkie te sposoby obsługi wyjątków się łączą. Możemy dowolnie definiować liczbę i&nbsp;rodzaje bloków **catch** (zgodnie z&nbsp;hierarchią dziedziczenia). Możemy także zagnieżdżać całe bloki **try/catch**.

```cpp
try
{
    if(fileHandler.openFile("file.txt"))
    {
        try
        {
            const auto fileContent{ fileHandler.read() };
            //...
        }
        catch(const ReadFileException& ex)
        {
            std::cout << "Cannot read file: " << ex.what() << "\n";
        }
    }
    fileHandler.closeFile();
}
catch(const std::system_error& ex)
{
    std::cout << ex.what() << " with code: " << ex.code() << "\n";
    return 0;
}
catch(...)
{
    std::cout << "Something unexpected happened!\n";
    return 0;
}
```

Trzeba jednak zachować umiar bo możemy skończyć z&nbsp;bardzo nieczytelnym kodem, w&nbsp;którym ciężko w&nbsp;szybki sposób zweryfikować, w&nbsp;który blok **catch** wyjątek zostanie złapany.

C++11 udostępnia nam też słowo kluczowe **noexcept**, którym możemy oznaczyć funkcje i&nbsp;metody nierzucające wyjątków. Czyli takie, które używają operacji bezpiecznych pod względem wyjątków i/lub same je obsługują. Słowo kluczowe **noexcept** możemy także zastosować do konstruktorów i&nbsp;destruktora klasy.

```cpp
auto add(int a, int b) noexcept -> int
{
    return a + b;
}

class FileHandler
{
public:
    FileHandler() noexcept;
    ~FileHandler() noexcept;

    auto openFile(const std::string& fileName) -> bool;
    auto read() const -> std::string;
    auto closeFile() noexcept -> void;

private:
    File file_;
};
```

Żeby móc oznaczyć funkcję lub metodę jako **noexcept**, wszystkie operacje i&nbsp;wywoływane funkcje/metody także powinny być oznaczone jako **noexcept**, by&nbsp;zachować bezpieczeństwo w&nbsp;kontekście wyjątków. Niestety kompilator nas nie poinformuje, jeżeli ten warunek nie jest spełniony.
Co jeśli oznaczymy naszą funkcję/metodę jako **noexcept**, a&nbsp;z jakiegoś powodu jednak rzuci wyjątek? Specyfikacja podpowiada, że&nbsp;zostanie wywołana funkcja **std::terminate()**, która&nbsp;zakończy działanie naszego programu niezależnie od tego czy dany kod był w&nbsp;bloku **try/catch** czy nie.

**noexcept** jest równoznaczne z&nbsp;**noexcept(true)**. Natomiast domyślnie wszystkie funkcje i&nbsp;metody oznaczone są jako **noexcept(false)**. Dlaczego dodano osobno **noexcept** oraz **noexcept(true/false)**? Głównie ze względu na szablony i&nbsp;metaprogramowanie, gdzie&nbsp;o&nbsp;tym czy funkcja lub metoda może lub nie może rzucać wyjątków kompilator dowiaduje się dopiero w&nbsp;trakcje kompilacji i&nbsp;konkretyzacji szablonów.

**noexcept** jest traktowane jako część typu funkcji. To&nbsp;znaczy, że&nbsp;jeśli mamy wskaźniki na funkcje, które różnią się tylko **noexcept**, to&nbsp;będą one traktowane jako osobne typy. Tak&nbsp;samo jeżeli chodzi o&nbsp;parametry szablonu.

```cpp
using funcPtr1 = auto(const int) -> bool;
using funcPtr2 = auto(const int) noexcept -> bool;
```

**noexcept** nie można za to stosować do przeciążania funkcji, gdyż&nbsp;nie wchodzi w&nbsp;skład jej sygnatury.

```cpp
auto add(int a, int b) noexcept -> int;
auto add(int a, int b) -> int; // Błąd kompilacji, redefinicja funkcji "add"
```

Zaletą **noexcept** jest przede wszystkim optymalizacja. Kompilator nie musi generować dodatkowego kodu do zwijania stosu po wystąpieniu wyjątku. Może także dobrać bardziej optymalne algorytmy STL. Łatwiej jest kompilatorowi inline’ować funkcję/metodę. Binarka wynikowa, również ma mniejszy rozmiar.

### Przechwytywanie wyjątku wewnątrz wątku

Przejdźmy teraz do wielowątkowego przechwytywania wyjątków. Nie&nbsp;jest to rzecz taka prosta. Spójrz na ten kod, czy&nbsp;jest on bezpieczny pod względem wyjątków?

```cpp
std::thread calculateSumThread;
try
{
    calculateSumThread = std::thread([]()
        {
            throw std::runtime_error("calculation error!");
        }
    );
}
catch(const std::runtime_error& ex)
{
    std::cerr << ex.what() << "\n";
}
catch(...)
{
    std::cerr << "Something unexpected happened!\n";
}

if (calculateSumThread.joinable())
{
    calculateSumThread.join();
}
```

Wydawać by się mogło, że&nbsp;tak. Przecież mamy blok **catch** zarówno na wyrzucany wyjątek **std::runtime_error** jak i&nbsp;**...**. Jednak tak nie jest. Po&nbsp;uruchomieniu tego kodu w&nbsp;prostej funkcji **main** zostanie wywołany **std::terminate()**.

```bash
terminate called after throwing an instance of 'std::runtime_error'
  what():  calculation error!
```

Dzieje się tak dlatego, że&nbsp;wątek traktowany jest jako osobny proces pomimo, iż&nbsp;należy do głównego wątku naszej aplikacji. Jednym z&nbsp;rozwiązań tego problemu jest obsługa wyjątków wewnątrz wątku i&nbsp;nie wyrzucanie ich na zewnątrz, tworząc wątek bezpieczny względem wyjątków.

```cpp
std::thread calculateSumThread;
try
{
    calculateSumThread = std::thread{ []()
        {
            try
            {
                throw std::runtime_error("calculation error!");
            }
            catch(const std::runtime_error& ex)
            {
                std::cerr << ex.what() << "\n";
            }
        }
    };
}
catch(...)
{
    std::cerr << "Something unexpected happened!\n";
}

if (calculateSumThread.joinable())
{
    calculateSumThread.join();
}
```

Wynikiem będzie tylko komunikat przechwyconego wyjątku, a&nbsp;nasz program będzie kontynuował pracę:

```bash
calculation error!
```

Tutaj jeszcze warto dodać, że&nbsp;od C++20 mamy dostępny nowy sposób tworzenia wątków w&nbsp;postaci **std::jthread**. Dzięki któremu nie musimy ręcznie wywoływać **join()**. Niemniej wiem, że&nbsp;nie każdy może sobie pozwolić na korzystanie z&nbsp;nowszych standardów C++ w swoiej pracy. Dla&nbsp;dociekliwych odsyłam do [oficialnej dokumentacji](https://en.cppreference.com/w/cpp/thread/jthread.html){:target="_blank" rel="noopener"}.

### Przekierowanie wyjątku do wątku głównego

Tworzenie osobnego bloku **try/catch** w&nbsp;wątku i&nbsp;poza nim może doprowadzić do niepotrzebnej złożoności. Możemy też potrzebować obsłużyć wyjątek w&nbsp;głównym wątku naszej aplikacji, gdy&nbsp;wyjątek wystąpi wewnątrz wątku, aby&nbsp;poprawnie zareagować na taką sytuację. C++&nbsp;od wersji 11 wraz z&nbsp;całą obsługą wyjątków daje nam kilka narzędzi, które rozwiązują ten problem: **std::async**, **std::packaged_task** i&nbsp;**promise**. Każde z&nbsp;nich umożliwia przekierowanie wyjątków z&nbsp;wątku pobocznego do wątku głównego.

Zacznijmy od **std::async**. To&nbsp;szablon funkcji o&nbsp;zmiennej liczbie parametrów umożliwiający uruchomienie przekazanej funkcji lub metody w&nbsp;osobnym wątku. Zwraca obiekt **std::future**, który po wywołaniu metody **get()** zwróci wynik lub wyjątek jeśli wystąpił.

```cpp
auto exceptionFutureObj{ std::async(std::launch::async, []()
    {
        throw std::runtime_error("calculation error!");
    })
};

try
{
    exceptionFutureObj.get();
}
catch(const std::runtime_error& ex)
{
    std::cerr << ex.what() << "\n";
}
```

Widać tutaj prostotę tego rozwiązania. Wątek poboczny nie zawiera już bloku **try/catch**. Cała&nbsp;obsługa wyjątku dzieje się pod spodem **std::async**. Kod&nbsp;jest czysty i&nbsp;zrozumiały. By&nbsp;mieć pewność, że funkcja przekazana jako parametr uruchomi się w&nbsp;osobnym wątku, trzeba ustawić tryb uruchamiania na **std::launch::async**. W&nbsp;trybie **std::launch::deferred** funkcja zostanie uruchomiona w&nbsp;tym samym wątku dopiero w&nbsp;momencie wywołania metody **get()** lub **wait()** na zwróconym przez **async** obiekcie **future**. Domyślnie, to&nbsp;implementacja decyduje jaki tryb uruchamiania zostanie wykorzystany.

Drugim narzędziem, którym możemy przekazać wyjątki z&nbsp;wątku pobocznego do głównego jest **std::packaged_task**.

```cpp
std::packaged_task<void()> task{ []()
    {
        throw std::runtime_error("calculation error!");
    }
};
auto exceptionFutureObj{ task.get_future() };
std::thread exceptionTaskThread{ std::move(task) };

try
{
    exceptionFutureObj.get();
}
catch(const std::runtime_error& ex)
{
    std::cerr << ex.what() << "\n";
}

exceptionTaskThread.join();
```

Pod względem przechwytywania wyjątków **async** i&nbsp;**std::packaged_task** działają tak samo. Oba&nbsp;zwracają obiekt typu **future** i&nbsp;w momencie pobierania wartości zwracanej (**get()**), wyjątek może zostać przechwycony. Zasadnicza różnica pomiędzy nimi jest moment, w&nbsp;którym wątek zostaje uruchomiony. Przy&nbsp;**async**  (z ustawionym **std::launch::async**), w&nbsp;momencie wywoływania. Przy&nbsp;**std::packaged_task**, dopiero, gdy&nbsp;task zostanie przekazany do nowego wątku.

Ostatni sposób na przekazanie wyjątków z&nbsp;wątku pobocznego do głównego, to&nbsp;**std::promise**.

```cpp
std::promise<void> exceptionPromise;
auto exceptionFutureObj{ exceptionPromise.get_future() };

std::thread exceptionTaskThread{ [&exceptionPromise]()
    {
        try
        {
            throw std::runtime_error("calculation error!");
        }
        catch (...)
        {
            exceptionPromise.set_exception(std::current_exception());
        }
    }
};

try
{
    exceptionFutureObj.get();
}
catch (const std::runtime_error& ex)
{
    std::cerr << ex.what() << "\n";
}

exceptionTaskThread.join();
```

Widać tutaj od razu, że&nbsp;blok **try/catch** powrócił do ciała naszego wątku pobocznego. Mimo&nbsp;to, jedynym dla nas potrzebnym blokiem **catch** jest ten z&nbsp;wielokropkiem, gdyż&nbsp;zależy nam na przekazywaniu wyjątków do wątku głównego. **promise** daje nam największą kontrolę nad tym, kiedy wątek zostanie uruchomiony, kiedy&nbsp;i&nbsp;jaki wyjątek zostanie przekazany wyżej. Możemy także przekazać jakąś wartość w&nbsp;**std::promise**, w&nbsp;polu **value**. Może&nbsp;w&nbsp;celu debuggowym albo jako wartość domyślną. Zależy od tego co będzie nam potrzebne.

### Wielokrotne przechwytywanie wyjątków

Na koniec jeszcze kwestia przechwytywania wyjątków z&nbsp;różnych wątków pobocznych w&nbsp;wątku głównym. Gdy&nbsp;przy użyciu **std::async**, uruchomimy dwa wątki i&nbsp;w obu zostaną wyrzucone wyjątki to musimy zadbać o&nbsp;to, by&nbsp;każdy został poprawnie obsłużony.

```cpp
auto exceptionFutureObj1{ std::async(std::launch::async, []()
    {
        std::cout << "First thread\n";
        throw std::runtime_error("calculation error!");
    })
};

auto exceptionFutureObj2{ std::async(std::launch::async, []()
    {
        std::cout << "Second thread\n";
        throw std::system_error(std::make_error_code(std::errc(EDEADLK)), "system error!");
    })
};

try
{
    exceptionFutureObj2.get(); // Rzucenie wyjątku std::system_error, przejście do bloku catch
    exceptionFutureObj1.get();
}
catch(const std::system_error& ex)
{
    std::cout << ex.what() << " with code: " << ex.code() << "\n";
}
catch(const std::runtime_error& ex)
{
    std::cerr << ex.what() << "\n";
}
```

A tutaj wynik działania powyższego fragmentu kodu:

```bash
First thread
Second thread
system error!: Resource deadlock avoided with code: generic:35
```

W tym przypadku, pomimo, iż&nbsp;oba wątki zostały uruchomione, i&nbsp;oba z&nbsp;pewnością rzuciły wyjątki to tylko jeden zostanie przechwycony. Nie&nbsp;liczy się moment rzucenia wyjątku, a&nbsp;moment odebrania wyniku z&nbsp;obiektu **future**. Dopiero wtedy wyjątek rzucany jest w&nbsp;wątku głównym. Dlatego w&nbsp;powyższym przykładzie, wyjątek **std::runtime_error** nie został przechwycony. Drugi **get()** po prostu się nie wykonał.

Aby uniknąć takich sytuacji należy każdą próbę odebrania wyniku z&nbsp;**future** opakować blokiem **try/catch** osobno. Możemy do tego utworzyć szablonowy handler.

```cpp
template <typename Future>
auto exceptionHandler(Future& future) -> void
{
    try
    {
        future.get();
    }
    catch(const std::runtime_error& ex)
    {
        std::cerr << ex.what() << "\n";
    }
}

auto main() -> int
{
    constexpr int numOfThreads{ 5 };
    std::vector<std::future<void>> futures;

    for(int idx = 0; idx < numOfThreads; idx++)
    {
        futures.push_back(std::async(std::launch::async, [idx]()
            {
                std::cout << "Thread nr: " << idx << "\n";
                throw std::runtime_error("error from thread: " + std::to_string(idx));
            })
        );
    }

    for(auto& future : futures)
    {
        exceptionHandler(future);
    }

    return 0;
}
```

A oto wynik:

```bash
Thread nr: 0Thread nr: 1
Thread nr: 2

Thread nr: 4
Thread nr: 3
error from thread: 0
error from thread: 1
error from thread: 2
error from thread: 3
error from thread: 4
```

Jak widać wszystkie wyjątki zostały przechwycone. Widać też asynchroniczność w&nbsp;logowaniu do **std::cout**. W&nbsp;takim przypadku lepiej użyć jakiegoś własnego loggera bezpiecznego dla wątków.

### Podsumowanie

W tym wpisie, starałem się zebrać wszystkie najważniejsze informacje dotyczące wyjątków w&nbsp;C++. Od&nbsp;tego jakie wyjątki są dostępne w&nbsp;tym języku programowania, poprzez ich rzucanie i&nbsp;obsługę, kończąc na przekazywaniu ich pomiędzy wątkami. C++&nbsp;wciąż się zmienia i&nbsp;ewoluuje. Może&nbsp;w&nbsp;przyszłości dojdą nowe mechanizmy związane z&nbsp;wyjątkami. Choć&nbsp;trzeba przyznać, że&nbsp;już teraz mamy spory wachlarz narzędzi do radzenia sobie z&nbsp;nimi :).

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}
