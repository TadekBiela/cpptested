---
title: "F.I.R.S.T. - jak pisać unit testy lepiej."
date: 2025-07-28
author: "Tadeusz Biela"
categories:
  - unit testing
tags:
  - clean code
  - software testing
  - code quality
  - refactoring
  - developer practices
---

F.I.R.S.T. to&nbsp;pewien standard, jaki unit testy powinny spełniać. To&nbsp;zbiór założeń, które wyznaczają kierunek, jaki powinniśmy obierać, pisząc testy.


### F jak Fast

Czas oczekiwania na wynik naszych unit testów powinien być jak najkrótszy.

Znani i&nbsp;cenieni specjaliści, jak Robert C. Martin czy Kent Beck, w&nbsp;swoich książkach przytaczają związek między czasem wykonywania testów, a&nbsp;ich regularnym uruchamianiem.
Jeśli testy "kręcą się" kilka lub kilkanaście minut, często zniechęca to&nbsp;programistów do&nbsp;regularnego ich uruchamiania. Dodatkowo, &nbsp;gdy weźmiemy pod uwagę Test Driven Development, to&nbsp;praktycznie paraliżuje to&nbsp;rozwój kodu i&nbsp;rodzi sporo frustracji.

Kiedy testy "kręcą się" za długo? Tutaj sprawa już nie jest taka prosta. Czy 5 s jest OK? Myślę, że&nbsp;tak. 30&nbsp;s – jeszcze akceptowalne. 1–2 min? Tutaj już może pojawić się myśl: "Czy zdążę zrobić sobie kawę/herbatę?"
Gdy zaczynamy myśleć o&nbsp;zrobieniu czegoś innego, oczekując na wyniki unit testów, to&nbsp;już jest znak, że&nbsp;trwa to za długo. Gdy pracujemy w&nbsp;TDD, to&nbsp;zmiany często są&nbsp;minimalne, trwające kilka sekund. Nie możemy pozwolić, by&nbsp;ich weryfikacja trwała kilkukrotnie dłużej, bo&nbsp;wybije nas to&nbsp;z&nbsp;rytmu.

Przyczyn długiego oczekiwania na zakończenie unit testów może być kilka:

**1)** Sleepy w&nbsp;testach.
   Jeśli w&nbsp;naszych unit testach korzystamy z&nbsp;czasowych opóźnień, to&nbsp;często jest to&nbsp;związane z&nbsp;timerami użytymi w&nbsp;logice naszego kodu.

**2)** Dostęp do&nbsp;plików.
   Pojedynczy przypadek raczej nie wpłynie znacząco na czas wykonywania unit testów. Gdy takich odczytów jest więcej, zaczynają one mieć znaczenie.

**3)** Zewnętrzny framework do&nbsp;przesyłania message’y/eventów.
   Jeśli nasz kod produkcyjny korzysta z&nbsp;takich rozwiązań, może to&nbsp;w&nbsp;testach doprowadzić do&nbsp;opóźnień. Na&nbsp;przykład, gdy&nbsp; message nie przyjdzie na czas z&nbsp;powodu obciążenia sprzętu, na&nbsp;którym uruchamiamy testy (współdzielony serwer).

Z pewnością każdy z&nbsp;Was może znaleźć też inne przyczyny opóźnień. Najczęstszym rozwiązaniem jest wprowadzenie warstwy pośredniej, rodzaj interfejsu, aby&nbsp;móc zastąpić implementację problematycznych zależności mockami.

Warto pamiętać i&nbsp;dążyć do&nbsp;tego, aby&nbsp;czas oczekiwania na wyniki unit testów był jak najkrótszy. Podnosi to&nbsp;nie tylko jakość kodu, ale&nbsp;też satysfakcję z&nbsp;samej pracy z&nbsp;nim.


### I jak Independent

Unit testy powinny być niezależne od siebie nawzajem, tak&nbsp;aby można było uruchomić je w&nbsp;dowolnej kolejności.

Sytuacja, w&nbsp;której jeden test nie przechodzi tylko dlatego, że&nbsp;inny również nie przeszedł, nie&nbsp;należy do&nbsp;zbyt komfortowych. Tracimy wtedy wiarę w&nbsp;wiarygodność testów. Dodatkowo zmiana w&nbsp;jednym teście wymusza zmianę również w&nbsp;innym.
Framework testowy Google Test domyślnie uruchamia testy w&nbsp;sposób losowy, dzięki czemu złamanie tej reguły powinno wyjść bardzo szybko.

Częstym powodem zależności między testami są&nbsp;zmienne globalne. Istnieją techniki odcinania zależności od&nbsp;zmiennych globalnych czy wolnych funkcji (niezwiązanych z&nbsp;żadnym obiektem).
W&nbsp;mojej ocenie jedną z&nbsp;najlepszych jest opakowanie użycia zmiennej globalnej (czy też funkcji) w&nbsp;metodę klasy w&nbsp;sekcji protected. Tak, aby&nbsp;można było przysłonić jej zachowanie w&nbsp;testach, tworząc klasę Testable.

Technik radzenia sobie ze zmiennymi globalnymi jest więcej i&nbsp;można je znaleźć w&nbsp;tak świetnych książkach jak "Praca z&nbsp;zastanym kodem" czy "Refaktoryzacja. Ulepszanie struktury istniejącego kodu".


### R jak Repeatable

Testy powinny być powtarzalne, niezależnie od środowiska, w&nbsp;którym je uruchomimy. Czy to&nbsp;będzie mój laptop, czy&nbsp;serwer firmowy – wyniki testów powinny być takie same.
Esencją braku tej zasady jest znane przez chyba wszystkich programistów zdanie: "U mnie działa."
Świetnie, ale testy powinny działać wszędzie tam, gdzie się je uruchomi, i&nbsp;zwracać to&nbsp;samo.
Gdy unit test zwraca jeden wynik w&nbsp;środowisku&nbsp;A, a&nbsp;inny wynik w&nbsp;środowisku&nbsp;B – to&nbsp;znak, że&nbsp;ma&nbsp;on jakąś zależność, która powinna zostać odcięta.

Tutaj znów przyczyną może być dostęp do&nbsp;systemu plików. Gdy w&nbsp;jednym środowisku pliki istnieją, a&nbsp;w&nbsp;innym nie – testy zachowują się inaczej.

Inną przyczyną może być korzystanie ze zmiennych środowiskowych.
Tak czy inaczej – takie praktyki przeczą idei unit testów, jaką jest izolacja: odcięcie zewnętrznych zależności i&nbsp;testowanie małego fragmentu w&nbsp;przygotowanym do&nbsp;tego środowisku i&nbsp;scenariuszu.

W&nbsp;mojej ocenie korzystanie z&nbsp;zewnętrznych zależności w&nbsp;testach to&nbsp;droga na skróty, która w&nbsp;dłuższej perspektywie rodzi więcej problemów, niż&nbsp;daje korzyści.


### S jak Self-Validating

Unit test powinien zwracać jednoznaczny wynik – test się powiódł lub nie.
Testy jednostkowe to&nbsp;jedno z&nbsp;wielu zautomatyzowanych narzędzi wspierających naszą pracę z&nbsp;kodem i&nbsp;podnoszących jego jakość.

Gdy musimy ręcznie weryfikować wyniki testów, marnujemy sporo czasu lub co gorasze, możemy błędnie odczytać ich wynik – dostarczając wadliwy kod lub niepotrzebnie debuggując go, gdy&nbsp;jednak jest poprawny, szukając błędu, który nie istnieje.
Jeśli test wymaga ręcznego sprawdzenia logów, by&nbsp;potwierdzić, czy&nbsp;testowany kod działa, to&nbsp;znaczy, że&nbsp;coś jest nie tak.

Czy możemy wtedy mówić o&nbsp;zautomatyzowanym teście? Zdecydowanie nie.
Informacja zwrotna powinna być jasna – Twój kod działa/nie działa.
Myślę, że ten punkt jest jasny i&nbsp;bez niego nie możemy mówić o&nbsp;cyklu TDD: Red → Green → Refactor. Bez jasnego sygnału, jak zakończyły się testy, nie możemy płynnie pracować w&nbsp;tym rytmie.


### T jak Timely

Unit testy powinny być uruchamiane w&nbsp;odpowiednim czasie. W&nbsp;tym punkcie nie mówię o&nbsp;czasie wykonywania, ale&nbsp;o&nbsp;momencie, w&nbsp;którym uruchamiamy testy.

W Test Driven Development (TDD) mamy cykl Red&nbsp;→&nbsp;Green&nbsp;→&nbsp;Refactor, o&nbsp;którym już wspomniałem. Każdy cykl rozpoczyna się od napisania testu i&nbsp;od razu próby jego uruchomienia. Najczęściej kończy się on błędem kompilacji, gdyż nowa metoda, którą chcemy przetestować, jeszcze nie powstała. To&nbsp;też jest wynik "Red".

Testy uruchamiamy tak często, jak to&nbsp;możliwe, i&nbsp;wprowadzamy zmiany iteracyjnie, małymi krokami. Dzięki takim krótkim cyklom szybko możemy wykryć regresję, a&nbsp;zakres zmian jest minimalny i&nbsp;łatwo możemy dojść do&nbsp;tego, gdzie popełniliśmy błąd.
Timely nie odnosi się już do&nbsp;tego, jak&nbsp;pisać unit testy, tylko jak ich używać - często :)


### Podsumowanie

W&nbsp;tym wpisie starałem się przybliżyć pięć cech dobrych unit testów. Są&nbsp;to&nbsp;drogowskazy pomagające nam nie tylko pisać testy lepiej, ale przede wszystkim pracować z&nbsp;nimi na co dzień.
Trzymając się tych reguł, z&nbsp;pewnością odczujemy różnicę w&nbsp;codziennej pracy – zyskując kontrolę nad zmianami, większe zaufanie do&nbsp;kodu i&nbsp;pewność, że&nbsp;nie wprowadzimy regresji.

**Autor:** Tadeusz Biela  
Programista C++ | Entuzjasta TDD | Fan unit testów

[LinkedIn](https://www.linkedin.com/in/tadeuszbiela/){:target="_blank" rel="noopener"}
