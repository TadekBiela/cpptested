---
title: "Fundamenty myślenia wielowątkowego"
date: 2026-02-24
author: "Tadeusz Biela"
categories:
  - multithreading
tags:
  - multithreading
  - developer practices
  - software
---

Podstawy są ważne, bez&nbsp;nich nie możemy ruszyć dalej z&nbsp;nauką, szczególnie, gdy&nbsp;chcemy opanować rzeczy o&nbsp;dużo większej złożoności, jak&nbsp;na przykład wielowątkowość i&nbsp;przetwarzanie współbieżne. Zacznijmy więc od fundamentów, pojęć bez, których opanowanie sztuki tworzenia wielowątkowego kodu się nie powiedzie. Żeby pisać kod uruchamiany w&nbsp;więcej niż jednym wątku, wpierw trzeba nauczyć się samego myślenia w&nbsp;sposób wielowątkowy i&nbsp;właśnie od&nbsp;tego zaczniemy.

### Współbieżność i&nbsp;wielowątkowość

Rozpoczniemy od rozróżnienia, czym jest współbieżność, a&nbsp;czym wielowątkowość. Zrozumienie obu zagadnień umożliwi Ci zbudowanie solidnych podstaw myślenia, jak&nbsp;wygląda przetwarzanie zadań przez komputer.

Współbieżność to wykonywanie zadań w&nbsp;tym samym czasie przez jedną jednostkę CPU. To znaczy, że&nbsp;nasz procesor otrzymuje kilka zadań i&nbsp;sekwencyjnie wykonuje po trochu każde z&nbsp;nich, przełączając konteksty między nimi. Zadania sumarycznie są wykonywane w&nbsp;tym samym czasie, ale&nbsp;tak naprawdę, to&nbsp;CPU jest w&nbsp;stanie pracować tylko nad jednym zadaniem na raz. Dlatego, by&nbsp; każde zadanie posuwało się do przodu, CPU przełącza się miedzy nimi, aż do ich zakończenia. Proces ten nazywamy przełączaniem kontekstów. To&nbsp;daje nam wrażenie, że&nbsp;wszystko co się dzieje na ekranie komputera, wykonuje się niejako jednocześnie. To&nbsp;sprytna sztuczka, oszukiwanie ludzkiego oka i&nbsp;percepcji.

Wielowątkowość to również przetwarzanie wielu zadań na raz, ale&nbsp;już bez przełączania kontekstu, ponieważ każdy wątek dostaje swoje zasoby może wykonywać przydzielone zadanie równocześnie z&nbsp;innymi wątkami. W&nbsp;tym przypadku możemy mówić o&nbsp;przynajmniej dwóch CPU (to uproszczenie), które nie przełączają się między zadaniami, tylko dostają po jednym i&nbsp;wykonują je bez przerwy, aż do zakończenia.

By jeszcze lepiej to zrozumieć, posłużmy się prostą analogią. Współbieżność jest jak gotowanie w&nbsp;kuchni, przez chwilę mieszasz gotujący się makaron, potem wrzucasz kotlet na patelnię, by&nbsp; za chwilę kroić warzywa na sałatkę. Nie&nbsp;kroisz jedną ręką warzyw, a&nbsp;drugą nie mieszasz makaronu, obracając stopą kotleta :) (no może niektórzy tak potrafią). Przeskakujesz między czynnościami, aby&nbsp; wszystkie zakończyć w&nbsp;podobnym czasie i&nbsp;móc podać gotowy obiad. Wielowątkowość to po prostu większa liczba kucharzy w&nbsp;kuchni, którzy nie wchodzą sobie w&nbsp;drogę. Obiad powstaje szybciej, ale&nbsp;wymaga więcej ludzi.

Oba podejścia można oczywiście łączyć, otrzymując wielozadaniowe wątki i&nbsp;jednostki przetwarzania. Obecnie architektury sprzętowe mogą być bardzo różne i&nbsp;rozbudowane, od&nbsp;procesora jednordzeniowego, poprzez wielordzeniowe CPU, a&nbsp;kończąc na wielu procesorach wielordzeniowych.

Z przetwarzaniem współbieżnym i&nbsp;wielowątkowym wiążą się również spore wyzwania i&nbsp;ograniczenia. Nie&nbsp;jest to remedium na wszystko, ale&nbsp;potrafią (gdy są odpowiednio użyte) mocno przyśpieszyć działanie naszego programu.

### Operacje w&nbsp;linijce kodu

Kiedy znamy już różnicę między współbieżnością, a&nbsp;wielowątkowością, przejdźmy do najbardziej podstawowego pojmowanie kodu właśnie w&nbsp;tym kontekście.

Gdy widzisz taką linijkę kodu, to&nbsp;co myślisz?

```cpp
x += 42;
```

Niby jedna operacja, nic&nbsp;bardziej mylnego! Tak naprawdę dzieją się tam trzy rzeczy:

1. Odczytanie zmiennej **x**.
2. Modyfikacja tej zmiennej
3. Zapis zmiennej **x** w&nbsp;pamięci.

Każda ta operacja przedstawia inny stan zmiennej **x**. Pomiędzy lub nawet w&nbsp;trakcie tych operacji, inny wątek może też chcieć skorzystać z&nbsp;naszej zmiennej. Pytanie w&nbsp;jakim stanie powinna się ona znajdować? By odpowiedzieć na to pytanie musimy najpierw zrozumieć czym są **niezmienniki**.

### Niezmienniki

**Niezmiennik** to stan zmiennej/obiektu/modułu/systemu, który musi być prawdą w&nbsp;każdym momencie jego obserwacji.

Kluczowymi słowami w&nbsp;tej definicji są **stan**, **prawda** i&nbsp;**obserwacja**. Rozłóżmy to na czynniki pierwsze. Jeśli chcesz nauczyć się dobrze programować wielowątkowo to wpierw naucz się myśleć, nie&nbsp;w&nbsp;kategoriach zmiennych czy obiektów, ale&nbsp;ich stanu w&nbsp;jakim się obecnie znajdują, w&nbsp;jakim będą się znajdować za chwilę itd.

Mamy metodę klasy **Account**, która ma taką implementację metody **transfer**.

```cpp
auto transfer(Account& account, Money value) -> void
{
    account.withdraw(value);
    balance_ += value;
}
```

Niezmiennikami mogą być, w&nbsp;takim przypadku, poniższe założenia:

1. Saldo każdego konta jest zawsze ≥ 0.
2. Suma środków **account.balance** i&nbsp;**balance_** jest taka sama w&nbsp;każdym obserwowanym momencie.
3. Metoda transfer jest niepodzielną zmianą systemu.
4. Jeśli zmniejszone zostało **account.balance** to zwiększone zostało **balance_**.

Powyższe 4 punkty to są założenia, które metoda **transfer** powinna spełniać. Czy&nbsp;tak jest? No niestety nie. W&nbsp;wyniku wykonywania tej metody, nie&nbsp;ma żadnych ograniczeń w&nbsp;tym, by&nbsp; inny wątek odwołał się do tych obiektów.

```cpp
auto transfer(Account& account, Money value) -> void
{
    account.withdraw(value);
    // W tym momencie obserwacji, część niezmienników nie jest prawdziwa
    balance_ += value;
}
```

Aby temu zaradzić należałoby dodać **mutex**. Czym są mutexy? O&nbsp;tym trochę później. Skupmy się na fundamentach. By&nbsp;dobrze określić niezmienniki należy zadać sobie odpowiednie pytania. Weźmy przykład prostej klasy **Counter**.

```cpp
class Counter
{
public:
    auto increment() -> void
    {
        value_++;
    }

    auto getValue() const -> int
    {
        return value_;
    }

private:
    int value_{ 0 };
};
```

1. Co jest stanem naszego obiektu klasy **Counter**?

Stanem jest zmienna **value_**, a&nbsp;raczej to jaką wartość posiada w&nbsp;każdym momencie obserwacji.

2. Kto może obserwować stan obiektu klasy **Colunter**?

Każdy inny wątek w&nbsp;dowolnym momencie. Nie&nbsp;tylko przed i&nbsp;po wywołaniu metod.

3. Jaki stan jest niedozwolony? Sprawia, że&nbsp;obiekt klasy **Counter** jest niespójny?

**value_** jest ujemne.

Naszym niezmiennikiem będzie więc: "Stan zmiennej **value_** jest nieujemny w&nbsp;każdym momencie obserwacji."

Zastanówmy się, czy&nbsp;jest w&nbsp;ogóle możliwość, aby&nbsp; ten niezmiennik był złamany? Dla przykładu metoda **increment**.

```cpp
auto increment() -> void
{
    value_++;
}
```

Czy istnieje moment, w&nbsp;którym **value_** może być ujemny? Weź pod uwagę dowolny przeplot wątków. Zakładamy brak synchronizacji i&nbsp;wiele wątków korzystających z&nbsp;tego samego obiektu klasy **Counter**. Wartość **value_** jest inicjalizowana jako 0.

Odpowiedź brzmi: tak.

Intuicyjnie jest to przecież niemożliwe, prawda? Przecież zaczynamy od 0 i&nbsp;tylko inkrementujemy. Tak,&nbsp;to&nbsp;prawda, jednak przy przetwarzaniu wielowątkowym, w&nbsp;przypadku naszej klasy **Counter**, mamy do czynienia z&nbsp;**data race**. Wątki konkurują ze sobą o&nbsp;dostęp do **value_**. Gdy jeden z&nbsp;wątków właśnie pracuje nad zwiększeniem **value_**, inny, w&nbsp;dowolnym momencie może zaobserwować **value_** i&nbsp;odczytać jej stan jako dowolny ciąg bitów. **value_** może być jeszcze w&nbsp;rejestrze CPU, może zawierać starą wartość, może zawierać tylko fragment nowej wartości (w reprezentacji bitowej). Standard C++ określa **data race** jako Undefined Behavior. Po dokładne szczegóły [odsyłam do oficjalnej dokumentacji](https://cppreference.net/cpp/language/multithread.html){:target="_blank" rel="noopener"}.

Wyznaczanie niezmienników nie jest rzeczą trywialną i&nbsp;wymaga ćwiczeń, niemniej znając ich definicje i&nbsp;założenia będzie to znacznie prostsze.

### Sekcja krytyczna

Wiedząc już czym są niezmienniki, czas przejść do ich spełniania w&nbsp;naszym kodzie. Wspominałem wcześniej o&nbsp;**mutexie**. To&nbsp;narzędzie do synchronizacji pomiędzy wątkami. Jest ich jeszcze kilka, ale&nbsp;ważniejsze jest teraz to, co&nbsp;ze sobą niosą. Sekcja krytyczna to taki fragment kodu/systemu, który nie może być obserwowalny przez inne wątki, aby&nbsp; zachować niezmienniki.

Wiedząc już jaki stan jest niedopuszczalny w&nbsp;naszym kodzie, musimy nauczyć się wydzielać te miejsca, które do takiego stanu doprowadzają i&nbsp;zablokować możliwość ich obserwacji przez inne wątki. Do&nbsp;tego, między innymi, służy **mutex**. Gdy&nbsp;jest zablokowany, nie&nbsp;dopuszcza innych wątków do momentu jego zwolnienia, a&nbsp;ich dostęp jest kolejkowany.

Wróćmy do przykładu z&nbsp;funkcją **transfer** i&nbsp;dodajmy do niej **mutex**.

```cpp
auto transfer(Account& account, Money value) -> void
{
    std::lock_guard<std::mutex> transferLock{ transferMutex_ };
    account->withdraw(value);
    balance_ += value;
}
```

**std::lock_guard** to narzędzie typu [RAII](https://pl.wikipedia.org/wiki/Resource_Acquisition_Is_Initialization){:target="_blank" rel="noopener"}, samo blokuje **mutex** w&nbsp;chwili tworzenia i&nbsp;odblokowuje w&nbsp;momencie destrukcji. Teraz funkcja **transfer** zachowuje niezmiennik:

4. Jeśli zmniejszone zostało **account.balance** to zwiększone zostało **balance_**.

Obserwowalny moment jest tylko przed zablokowaniem **mutexa** i&nbsp;po jego odblokowaniu, czyli całe ciało funkcji **transfer** nie jest dostępne dla innych wątków. Nie&nbsp;zawsze sekcja krytyczna to występujące po sobie linijki kodu. Najważniejsze są **niezmienniki**. Należy zawsze, przy analizie kodu wielowątkowego, zadawać sobie pytanie o&nbsp;poprawny stan naszej zmiennej czy obiektu.

Dla klasy **Counter** sekcją krytyczną będą wszystkie operacje na zmiennej **value_**.

```cpp
class Counter
{
public:
    auto increment() -> void
    {
        std::lock_guard<std::mutex> valueLock{ valueMutex_ };
        value_++;
    }

    auto getValue() const -> int
    {
        std::lock_guard<std::mutex> valueLock{ valueMutex_ };
        return value_;
    }

private:
    int value_{ 0 };
    mutable std::mutex valueMutex_;
};
```

To że blokujemy **mutex** osobno w&nbsp;metodzie **increment** i&nbsp;osobno w&nbsp;**getValue** to dalej jest to jedna i&nbsp;ta sama sekcja krytyczna, bo tyczy się stanu tej samej zmiennej czyli tych samych niezmienników.

### Podsumowanie

Znasz już najważniejsze koncepty myślenia wielowątkowego. Dzięki nim poznawanie świata programowania wielowątkowego będzie znacznie łatwiejsze. W&nbsp;następnym wpisie z&nbsp;tego cyklu poruszę najważniejsze zagrożenia płynące z&nbsp;wielowątkowości. Jeżeli chcesz poznać więcej szczegółów przetwarzania wielowątkowego, polecam zapoznać się z&nbsp;tytułem ["Język C++ i&nbsp;przetwarzanie współbieżne w&nbsp;akcji."](https://lubimyczytac.pl/ksiazka/4946367/jezyk-c-i-przetwarzanie-wspolbiezne-w-akcji-wydanie-ii){:target="_blank" rel="noopener"} - Anthony Williams. Jest to świetna pozycja, by&nbsp; dobrze zrozumieć wielowątkowość i&nbsp;zastosować ją w&nbsp;swoich projektach. Książka tak zawiera również bardzo zaawansowaną wiedzę na temat szeregowania dostępu do pamięci oraz tworzenia struktur bez blokad (mutexów), co&nbsp;może być po prostu zbyt trudne do przyswojenia, jeżeli dopiero zaczynasz naukę tej dziedziny. Warto wtedy ostanie kilka rozdziałów zostawić sobie na później :)

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}