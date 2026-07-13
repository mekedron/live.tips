---
title: Polityka prywatności
description: live.tips nie ma kont, plików cookie, analityki ani śledzenia. Oto krótka lista tego, co jednak jest przetwarzane, przez kogo i jak długo.
updated: 2026-07-13
updated_label: Ostatnia aktualizacja 13 lipca 2026
---

live.tips to otwartoźródłowy słoik na napiwki dla artystów. Prowadzi go **Nikita Rabykin**,
niezależny programista, a nie firma. Jeśli cokolwiek poniżej ma dla Ciebie znaczenie, napisz
na **[contact@live.tips](mailto:contact@live.tips)** — pod tym adresem odbiera człowiek.

Ta polityka jest szczera także w nudnych miejscach. Wolimy powiedzieć „przechowujemy Twoje
imię przez maksymalnie godzinę” niż twierdzić, że nie przechowujemy nic, i się mylić.

## W skrócie

- **Bez kont.** Nie ma się gdzie rejestrować.
- **Bez plików cookie.** Ani jednego, nigdzie.
- **Bez analityki, bez śledzenia, bez reklam, bez skryptów innych firm** na tej stronie.
- **Nigdy nie dotykamy Twoich pieniędzy.** Napiwki trafiają prosto od fana na własne konto
  artysty w Stripe, Revolut, MobilePay lub Monzo. Nas nie ma na tej drodze.
- **W domyślnej konfiguracji aplikacja rozmawia wyłącznie ze Stripe** — z żadnym serwerem
  live.tips.
- Jedyny serwer, jaki w ogóle prowadzimy, to niewielki przekaźnik, a istnieje on tylko wtedy,
  gdy artysta włączy Revolut, MobilePay lub Monzo.

## Ta strona

Strona jest statyczna i hostowana na **GitHub Pages**. Jako host GitHub otrzymuje adres IP
i user-agent przeglądarki każdego, kto wczytuje stronę — to zwykłe logowanie serwera WWW,
dzieje się zanim uruchomi się jakikolwiek nasz kod i nie możemy tego wyłączyć. GitHub
przetwarza te dane na podstawie własnego
[oświadczenia o prywatności](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Nie czytamy tych logów, a GitHub nam ich nie pokazuje.

Poza tym strony, które czytasz, **nie wczytują niczego od nikogo innego**: czcionki, ikony
i obrazy są serwowane z samego live.tips. Nie ma tu Google Analytics, menedżera tagów,
piksela ani osadzonego widżetu.

Strona przechowuje **dwie wartości w `localStorage` Twojej przeglądarki** — obie ustawione
przez Ciebie, obie czytelne wyłącznie dla tej strony i żadna z nich nigdy nigdzie nie jest
wysyłana:

| Klucz | Co zapamiętuje |
| --- | --- |
| `lt-landing-theme` | czy wybrałeś kolory jasne, ciemne czy automatyczne |
| `lt-langbar-dismissed` | że zamknąłeś baner „dostępne również w Twoim języku” |

Wyczyszczenie pamięci przeglądarki je usuwa. Nie są plikami cookie, nie są nikomu
udostępniane i nikogo nie identyfikują.

## Aplikacja

Aplikacja live.tips działa **na własnym urządzeniu artysty**. Wszystko, co wie, jest właśnie tam:

- **Ograniczony klucz Stripe** jest przechowywany w pęku kluczy urządzenia (Keychain w
  iOS/macOS, Keystore w Androidzie) i jest wysyłany wyłącznie do `api.stripe.com`.
- **Historia napiwków, historia sesji, cel i ustawienia aplikacji** są przechowywane w
  lokalnej pamięci urządzenia. Obejmuje to imiona i wiadomości, które fani dołączają do
  swoich napiwków.
- Odinstalowanie aplikacji usuwa to wszystko. Po naszej stronie nie ma kopii zapasowej w
  chmurze, bo po naszej stronie nie ma chmury.

**Nigdy nic z tego nie otrzymujemy.** Aplikacja nie zawiera żadnego SDK analitycznego,
raportowania awarii, powiadomień push ani kodu reklamowego — żadnych, nawet wyłączonych.

Dwa doprecyzowania, żeby twierdzenie „z nikim nie rozmawia” pozostało dokładnie prawdziwe:

- Aplikacja pobiera **kursy walut** raz dziennie z publicznych API kursowych
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). To zwykłe zapytania o
  publiczną listę kursów. Nie niosą żadnych informacji o Tobie, o artyście ani o żadnym
  napiwku — ale, jak każde zapytanie sieciowe, ujawniają tym usługom Twój adres IP.
- Jeśli korzystasz z **przeglądarkowej wersji** aplikacji, Twoja przeglądarka pobiera ją z
  naszego statycznego hosta (patrz *Ta strona* powyżej).

## Stripe

Kiedy fan płaci kartą, znajduje się na stronie płatności **Stripe**, nie naszej. Stripe zbiera
i przetwarza jego dane płatnicze jako niezależny administrator danych na podstawie
[Polityki prywatności Stripe](https://stripe.com/privacy). Nigdy nie widzimy numerów kart i
nie mamy dostępu do konta Stripe artysty.

Aplikacja artysty odczytuje jego własne napiwki ze Stripe za pomocą jego własnego
ograniczonego klucza. Imię i wiadomość fana, jeśli je zostawił, wędrują ze Stripe na
urządzenie artysty i tam się zatrzymują.

## Przekaźnik — tylko jeśli włączone są Revolut, MobilePay lub Monzo

Konfiguracje oparte wyłącznie na Stripe nigdy go nie dotykają i mogą przestać czytać w tym miejscu.

Revolut, MobilePay i Monzo nie dają aplikacji żadnej możliwości potwierdzenia, że płatność
się odbyła, więc te napiwki są przekazywane przez niewielki otwartoźródłowy przekaźnik, który
prowadzimy na **Cloudflare** pod adresem `api.live.tips`. Nigdy nie dotyka pieniędzy. Oto
wszystko, czym się zajmuje.

### Co przechowuje artysta

Utworzenie strony napiwków zapisuje **nazwę wyświetlaną artysty, jego publiczną wiadomość,
jego walutę oraz identyfikatory płatnicze, które postanowił opublikować** (jego link płatności
Stripe, nazwę użytkownika Revolut, identyfikator MobilePay Box ID, nazwę użytkownika Monzo).
To wszystko są informacje, które artysta i tak celowo publikuje dla fanów.

- **Okres przechowywania: usuwane automatycznie po 90 dniach braku aktywności.**
- Artysta może je usunąć **natychmiast** z poziomu aplikacji, w dowolnym momencie.
- Nigdy nie zbieramy adresu e-mail, hasła, imienia i nazwiska ani danych bankowych.

### Co wysyła fan

Formularz napiwku prosi o **kwotę**, a opcjonalnie o **imię** i **wiadomość**. To cały
formularz. Bez e-maila, bez numeru telefonu, bez konta.

- Jeśli ekran artysty jest **online**, napiwek jest przekazywany prosto do niego i **nigdy nie
  jest zapisywany na dysku**.
- Jeśli ekran artysty jest **offline** — telefon zablokowany, brak zasięgu — napiwek jest
  **przechowywany maksymalnie przez godzinę**, żeby po prostu nie przepadł, a następnie
  przekazywany w chwili, gdy ekran ponownie się połączy. Jeśli nikt się nie połączy, napiwek
  jest **usuwany, nieprzeczytany**. To jedyny tekst napisany przez fana, jaki przekaźnik
  w ogóle przechowuje, a godzina jest twardym limitem.
- Twoje imię i wiadomość trafiają również do **tytułu płatności**, który otwiera się w Revolut,
  MobilePay lub Monzo — właśnie w ten sposób artysta wie, kto dał napiwek. Te firmy
  przetwarzają je następnie na podstawie własnych polityk prywatności.
- Przekaźnik nie prowadzi **żadnej historii napiwków**. Nie może pokazać Tobie, nam ani
  nikomu innemu listy tego, kto komu dał napiwek.

### Adresy IP i ochrona przed nadużyciami

Otwarty formularz, do którego każdy może wysyłać dane, potrzebuje pewnej ochrony przed botami,
dlatego:

- Twój adres IP służy do **ograniczania liczby żądań** i jest wysyłany do **Cloudflare
  Turnstile** (test antybotowy działający na stronie napiwków), aby potwierdzić, że nie jesteś
  botem. Turnstile to produkt Cloudflare, używany zamiast CAPTCHA, która by Cię profilowała.
- Aby uniemożliwić komuś tworzenie tysięcy stron napiwków, **kryptograficzny skrót adresu IP**
  osoby, która taką stronę tworzy, jest przechowywany przez około **dwie godziny**, a potem
  odrzucany.
- **Operacyjne logi Cloudflare** rejestrują techniczne szczegóły żądań do przekaźnika — adres
  URL, czas, status — przez kilka dni. Nie zawierają imion ani wiadomości fanów. Cloudflare
  działa jako nasz podmiot przetwarzający; zobacz
  [Politykę prywatności Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Liczniki

Przekaźnik zlicza, **ile napiwków** przekazała dana strona napiwków, żebyśmy mogli wykrywać
nadużycia i wiedzieć, czy to w ogóle jest używane. To liczba. Nie zawiera żadnych danych fanów.

## Podstawa prawna, jeśli jej potrzebujesz (RODO)

- Prowadzenie przekaźnika dla artysty, który go włączył, oraz dostarczenie napiwku fana na
  ekran, do którego był skierowany: **wykonanie usługi, o którą poprosiłeś**.
- Ograniczanie liczby żądań, Turnstile i limity oparte na skrócie adresu IP: **prawnie
  uzasadniony interes** polegający na ochronie darmowej, otwartej usługi przed zniszczeniem
  przez boty i oszustwa.
- Logi serwera: **prawnie uzasadniony interes** polegający na prowadzeniu i zabezpieczaniu
  usługi.

## Twoje prawa

Możesz zażądać od nas kopii, sprostowania lub usunięcia wszystkiego, co o Tobie
przechowujemy, a także złożyć skargę do krajowego organu ochrony danych osobowych. Napisz na
**[contact@live.tips](mailto:contact@live.tips)**.

W praktyce większość tego i tak jest w Twoich rękach: artyści mogą natychmiast usunąć swoją
stronę napiwków z aplikacji, napiwki fanów wyparowują w ciągu godziny, a wszystko pozostałe
mieszka na Twoim własnym urządzeniu.

## Dzieci

live.tips nie jest skierowane do dzieci i nie przetwarzamy świadomie ich danych.

## Zmiany

Będziemy aktualizować tę stronę, gdy zmieni się oprogramowanie. Ponieważ cały projekt jest
otwartoźródłowy, **każda dawna wersja tej polityki znajduje się w publicznej historii git** —
możesz dokładnie porównać, co i kiedy się zmieniło.

## Język

Ta polityka jest publikowana we wszystkich językach obsługiwanych przez stronę, dla wygody.
Jeśli tłumaczenie i wersja angielska są ze sobą sprzeczne, **wiążąca jest wersja angielska**.
