---
title: Polityka prywatności
description: live.tips nie ma plików cookie, analityki ani śledzenia i działa całkowicie bez konta. Jeśli zdecydujesz się zalogować, oto dokładnie co jest przechowywane, gdzie, przez kogo i jak długo.
updated: 2026-07-15
updated_label: Ostatnia aktualizacja 15 lipca 2026
---

live.tips to otwartoźródłowy słoik na napiwki dla artystów. Prowadzi go **Nikita Rabykin**,
niezależny programista, a nie firma. Jeśli cokolwiek poniżej ma dla Ciebie znaczenie, napisz
na **[contact@live.tips](mailto:contact@live.tips)** — pod tym adresem odbiera człowiek.

Ta polityka jest szczera także w nudnych miejscach. Wolimy powiedzieć „przechowujemy Twoje
imię tak długo, jak długo trzymasz zespół" niż twierdzić, że nie przechowujemy nic, i się
mylić.

## W skrócie

- **Konto jest opcjonalne.** Aplikacja działa całkowicie bez konta i tak jest nadal
  domyślnie. Jeśli chcesz mieć swoje zespoły i swoją historię na drugim urządzeniu, możesz
  się zalogować — i wtedy część tego jest przechowywana na serwerze, i więcej niż wcześniej.
  Co jest czym, opisujemy niżej.
- **Bez plików cookie.** Ani jednego, nigdzie.
- **Bez analityki, bez śledzenia, bez reklam, bez skryptów innych firm** na tej stronie.
- **Nigdy nie dotykamy Twoich pieniędzy.** Napiwki trafiają prosto od fana na własne konto
  artysty w Stripe, Revolut, MobilePay lub Monzo. Nigdy nie ma żadnego salda live.tips.
- **Bez konta aplikacja rozmawia wyłącznie ze Stripe** — z żadnym serwerem live.tips. Jeśli
  się zalogujesz, to się zmienia: Twój klucz Stripe przenosi się na nasz serwer, a Stripe
  zgłasza nam Twoje napiwki, żebyśmy mogli umieścić je na Twoich pozostałych urządzeniach.
  To uczciwa cena zalogowania się i jest w całości opisana niżej.
- **Powiadomienia push są nowe, opcjonalne i tylko dla zalogowanych kont.** Nic nie jest
  wysyłane do urządzenia, które nigdy ich nie włączyło, a do urządzenia bez konta nie jest
  wysyłane w ogóle żadne.
- Serwery, które prowadzimy, działają na Firebase od Google. Istnieją, gdy artysta włączy
  Revolut, MobilePay lub Monzo — albo gdy się zaloguje.

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

## Aplikacja ma dwa tryby i to właśnie ta różnica jest całą historią

Wszystko poniżej zależy od jednego pytania: **czy się zalogowałeś?**

### Tryb pierwszy — bez konta. Nadal domyślny, nadal niezmieniony.

Aplikacja działa **na własnym urządzeniu artysty** i wszystko, co wie, mieszka właśnie tam:

- **Ograniczony klucz Stripe** jest przechowywany w pęku kluczy urządzenia (Keychain w
  iOS/macOS, Keystore w Androidzie) i jest wysyłany wyłącznie do `api.stripe.com`.
- **Historia napiwków, historia sesji, cel, lista próśb o piosenki i ustawienia aplikacji**
  są przechowywane w lokalnej pamięci urządzenia. Obejmuje to imiona i wiadomości, które
  fani dołączają do swoich napiwków.
- Odinstalowanie aplikacji usuwa to wszystko. Po naszej stronie nie ma kopii zapasowej w
  chmurze, bo w tym trybie po naszej stronie nie ma żadnej chmury.

**Nigdy nic z tego nie otrzymujemy.** Aplikacja nie zawiera żadnego SDK analitycznego,
raportowania awarii ani kodu reklamowego — żadnych, nawet wyłączonych. (Powiadomienia push
istnieją, ale to funkcja dla zalogowanych i są wyłączone, dopóki ich nie włączysz — patrz
*Tryb drugi*. Do urządzenia bez konta nie jest wysyłane żadne.)

Dwa doprecyzowania, żeby twierdzenie „z nikim nie rozmawia” pozostało dokładnie prawdziwe:

- Aplikacja pobiera **kursy walut** raz dziennie z publicznych API kursowych
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). To zwykłe zapytania o
  publiczną listę kursów. Nie niosą żadnych informacji o Tobie, o artyście ani o żadnym
  napiwku — ale, jak każde zapytanie sieciowe, ujawniają tym usługom Twój adres IP.
- Jeśli korzystasz z **przeglądarkowej wersji** aplikacji, Twoja przeglądarka pobiera ją z
  naszego statycznego hosta (patrz *Ta strona* powyżej).

### Tryb drugi — zalogowałeś się. Wtedy część danych świadomie opuszcza urządzenie.

Zalogowanie się to świadoma decyzja. Nic nie loguje Cię za Ciebie i nic w aplikacji nie
przestaje działać, jeśli nigdy tego nie zrobisz. Logujesz się, bo chcesz mieć drugie
urządzenie: telefon w kieszeni i tablet na scenie pokazujące ten sam wieczór, te same
zespoły, tę samą historię.

To działa tylko wtedy, gdy trzyma je serwer. **Więc je trzyma, i to jest uczciwa cena
drugiego urządzenia.**

Serwerem jest **Firebase**, czyli Google. Konto można mieć na trzy sposoby:

- **Zaloguj się przez Apple** lub **Zaloguj się przez Google** — Firebase Auth otrzymuje to,
  co przekaże dostawca: identyfikator użytkownika (uid) oraz, zwykle, adres e-mail i imię.
  (W przypadku Apple możesz ukryć swój e-mail; Apple daje nam wtedy adres pośredniczący, a
  Twoje imię przekazuje tylko przy pierwszym logowaniu.)
- **Konto gościa** — anonimowe konto bez e-maila i bez imienia. Synchronizuje dane i można
  je unieważnić, ale nie ma niczego, czym dałoby się je odzyskać, jeśli stracisz urządzenie.
  To uid i nic więcej. Konto gościa nie może korzystać z serwerowego przechowywania klucza
  Stripe ani z powiadomień push opisanych niżej, bo jedno i drugie wymaga konta, które
  możemy Ci oddać.

Po zalogowaniu konto dostaje swój własny prywatny kąt w bazie **Cloud Firestore** od Google,
pod adresem `users/<your uid>/`. Reguły bezpieczeństwa przyznają ten kąt temu uid **i nikomu
innemu** — żadne inne konto nie może go odczytać, także przez zgadywanie adresów URL. W
środku znajdują się:

| Co | Dlaczego tam jest |
| --- | --- |
| Twoje **zespoły** — nazwy, ustawienia słoika na napiwki i metod płatności, treść plakatu, cele oraz Twoja **lista próśb o piosenki** | żeby zespół istniał na każdym urządzeniu, na którym się zalogujesz |
| **Ustawienia aplikacji**, w tym Twoje preferencje powiadomień | żeby urządzenie, które dodasz, było już skonfigurowane |
| **Zapisy sesji i historia napiwków** — w tym **imiona i wiadomości, które fani dołączają do swoich napiwków**, oraz każda **piosenka, o którą poprosił fan** | bo właśnie tę historię chciałeś zobaczyć na drugim urządzeniu |
| **Sesja na żywo**, która trwa właśnie teraz | żeby drugi ekran mógł dołączyć do dzisiejszego koncertu |
| Twoje **urządzenia** — nazwa, którą każde sobie nadaje („iPhone Nikity”), jego platforma i model, jego język interfejsu, kiedy zostało zobaczone pierwszy i ostatni raz oraz (jeśli włączyłeś powiadomienia) **token push** | żeby Ustawienia → Bezpieczeństwo mogły je wypisać, żeby powiadomienie trafiło do właściwego urządzenia we właściwym języku i żebyś mógł któreś unieważnić |
| Niewielki **dokument profilu** — wybrana nazwa konta i użyty dostawca logowania | żeby przełącznik kont mógł je podpisać |
| **Kanał dzwonka** — ograniczona lista ostatnich napiwków i próśb o piosenki, które przyszły, gdy nie trwał żaden koncert | żebyś mógł nadrobić to, co Cię ominęło |

A teraz rzecz najważniejsza, wprost: **bez konta imię i wiadomość fana nigdy nie opuszczają
urządzenia artysty. Z kontem są przechowywane na serwerach Google pod uid artysty, jako
część jego własnej zsynchronizowanej historii**, i — jak wyjaśniają dwa kolejne rozdziały —
**to teraz nasz serwer je tam zapisuje.** Żadne inne konto nie może ich odczytać, my do nich
nie zaglądamy i nic z nich nie wyprowadzamy — ale one tam są i zostają tam tak długo, jak
istnieje zespół, i powinieneś o tym wiedzieć, zanim się zalogujesz.

Wylogowanie przywraca urządzenie do trybu lokalnego. Nie usuwa danych konta — patrz
*Usuwanie rzeczy* poniżej.

#### Twój klucz Stripe, gdy się logujesz, przenosi się na nasz serwer

To największa zmiana i ta, którą najbardziej warto przeczytać.

**Bez konta Twój ograniczony klucz Stripe nigdy nie opuszcza urządzenia.** To Tryb pierwszy
i pozostaje niezmieniony.

**Kiedy się logujesz, klucz jednak je opuszcza — do nas.** Klucz jest szyfrowany (klucz
AES-256 osobny dla każdego sekretu, sam opakowany przez Google Cloud KMS) i przechowywany po
stronie serwera w miejscu, którego **nikt nie może odczytać z powrotem — ani inne konto, ani
nawet Ty.** Jest odpieczętowywany wyłącznie wewnątrz naszych Cloud Functions, używany do
rozmowy ze Stripe w Twoim imieniu i nigdy więcej nie jest przekazywany urządzeniu.

Ponieważ klucz mieszka teraz u nas, **Stripe zgłasza Twoje napiwki bezpośrednio na nasz
serwer**: rejestrujemy webhook na Twoim własnym koncie Stripe, a Stripe informuje ten
webhook za każdym razem, gdy zostaje opłacony napiwek. Nasza funkcja zapisuje napiwek w
historii Twojego konta (patrz niżej). Aplikacja nie odpytuje już Stripe dla zalogowanego
konta; sięga do Stripe wyłącznie przez wąską, ustaloną listę operacji na naszym serwerze
(utworzenie Twojego linku do napiwków, wygenerowanie linku prośby o piosenkę i odczytanie
Twoich własnych napiwków w celu uzgodnienia).

Więc, powiedziawszy to bez eufemizmów: **dla zalogowanego konta na drodze między Stripe a
Twoją historią stoi teraz serwer live.tips.** Nadal nigdy nie dotykamy pieniędzy — napiwek
kartą jest tworzony na Twoim koncie Stripe, trafia na Twoje saldo Stripe i jest wypłacany
według Twojego harmonogramu Stripe, dokładnie tak jak wcześniej. Zmieniła się droga *danych*,
a nie droga *pieniędzy*. Jeśli nigdy się nie zalogujesz, nic z tego Cię nie dotyczy, a
aplikacja nadal rozmawia prosto z `api.stripe.com` i z nikim więcej.

#### Dodawanie urządzenia kodem QR

Żeby dodać urządzenie, pokazujesz kod QR z urządzenia, które jest już zalogowane. Kod jest
losowy, **jednorazowy i wygasa po dwóch minutach**, a nowe urządzenie nie dostaje niczego,
dopóki nie naciśniesz *potwierdź* na starym. Dopóki ta wymiana jest otwarta, przechowujemy
kod, nazwę, jaką nadało sobie nowe urządzenie, i jego platformę — a zapis jest usuwany, gdy
kod wygasa. Sfotografowany kod QR jest bezużyteczny bez Twojego potwierdzenia.

## Prośby o piosenki

Zespół może włączyć **prośby o piosenki**: fani wybierają wtedy piosenkę z listy artysty i,
opcjonalnie, płacą, żeby przesunąć ją wyżej w kolejce. Prośba to po prostu napiwek, który
dodatkowo niesie informację, **o którą piosenkę** poproszono — więc to samo imię i wiadomość,
jakie fan może dołączyć do napiwku, obowiązują i tutaj, a jest przechowywana i zachowywana
dokładnie tak jak każdy inny napiwek (poniżej). Publiczna kolejka, którą widzi fan, pokazuje
wyłącznie **sumy dla poszczególnych piosenek** — ile dana piosenka uzbierała i gdzie się
plasuje — i nie niesie **żadnych imion fanów**. Bez konta cała lista próśb o piosenki i jej
historia mieszkają wyłącznie na urządzeniu.

## Powiadomienia push

Kiedy jesteś zalogowany, aplikacja może wysłać Ci **powiadomienie push** — ale tylko jeśli je
włączysz, osobno na każdym urządzeniu, i dopiero po tym, jak system operacyjny Twojego
urządzenia udzieli na to zgody. Istnieje w jednym celu: napiwek albo prośba o piosenkę, które
przychodzą, **gdy nie prowadzisz koncertu**, żebyś usłyszał o napiwku, który inaczej by Cię
ominął. Napiwek, który przychodzi, gdy Twoja scena jest na żywo, nie wysyła niczego — już go
oglądasz.

- Żeby dostarczyć push, **Firebase Cloud Messaging (FCM)** od Google potrzebuje **tokenu
  push** dla urządzenia. Przechowujemy ten token oraz język interfejsu urządzenia we własnym
  zapisie tego urządzenia pod Twoim kontem, i jest on usuwany w chwili, gdy wyłączysz
  powiadomienia, unieważnisz urządzenie albo się wylogujesz. Martwe tokeny są usuwane
  automatycznie.
- Samo powiadomienie mówi, co przyszło — kwotę oraz imię fana lub tytuł piosenki, jeśli je
  zostawił. Ta sama krótka lista jest przechowywana w **kanale dzwonka** Twojego konta,
  ograniczonym do stu najnowszych wpisów, żebyś mógł przewinąć wstecz to, co przyszło, gdy Cię
  nie było.
- W sieci dostarczenie push wymaga niewielkiego **service workera** w katalogu głównym strony
  oraz SDK wiadomości Firebase, które Twoja przeglądarka pobiera z Google (`gstatic.com`) za
  pierwszym razem. Push w sieci jest następnie przenoszony przez własną usługę push Twojej
  przeglądarki (dla Chrome jest to usługa Google). Nic z tego się nie wczytuje, dopóki nie
  włączysz powiadomień.
- **Konto gościa i urządzenie bez konta nie dostają żadnych pushy**, bo push wymaga konta, do
  którego możemy dostarczyć, i tokenu, który zdecydowałeś się dać.

## Gdzie to wszystko fizycznie mieszka

Firebase Auth, Cloud Firestore, nasze Cloud Functions oraz klucz Cloud KMS, który opakowuje
Twój sekret Stripe, działają w **Unii Europejskiej** — baza danych w multiregionie `eur3` od
Google, funkcje i pęk kluczy w `europe-west1`. Google działa jako nasz podmiot przetwarzający
na podstawie
[warunków prywatności i bezpieczeństwa Firebase](https://firebase.google.com/support/privacy)
oraz własnej [polityki prywatności](https://policies.google.com/privacy). Jak każdy duży
dostawca, Google może angażować infrastrukturę poza UE na potrzeby wsparcia i
bezpieczeństwa; regulują to tamte warunki, nie my. Powiadomienia push, gdy trafią już do
Firebase Cloud Messaging oraz usługi push Twojej przeglądarki lub telefonu, wędrują przez
infrastrukturę tych firm, żeby dotrzeć do Twojego urządzenia.

## Stripe

Kiedy fan płaci kartą, znajduje się na stronie płatności **Stripe**, nie naszej. Stripe
zbiera i przetwarza jego dane płatnicze jako niezależny administrator danych na podstawie
[Polityki prywatności Stripe](https://stripe.com/privacy). Nigdy nie widzimy numerów kart.

To, jak docierają do Ciebie napiwki, zależy od trybu:

- **Bez konta** aplikacja artysty odczytuje jego własne napiwki ze Stripe za pomocą jego
  własnego ograniczonego klucza — prosto z urządzenia do `api.stripe.com`. **Na tej drodze
  nie ma żadnego serwera live.tips.**
- **Po zalogowaniu** klucz mieszka na naszym serwerze (zaszyfrowany, jak wyżej), a Stripe
  zgłasza każdy napiwek naszemu webhookowi, który zapisuje go we własnej historii tego
  artysty w Firestore. **W tym trybie na tej drodze stoi serwer live.tips** — dla danych
  napiwku, nigdy dla pieniędzy. Imię i wiadomość fana, jeśli je zostawił, wędrują z napiwkiem
  do własnej historii tego artysty i tam się zatrzymują.

## Przekaźnik — tylko jeśli włączone są Revolut, MobilePay lub Monzo

Konfiguracje oparte wyłącznie na Stripe nigdy go nie dotykają.

Revolut, MobilePay i Monzo nie dają aplikacji żadnej możliwości potwierdzenia, że płatność
się odbyła, więc te napiwki są przekazywane przez niewielki otwartoźródłowy przekaźnik,
który prowadzimy na **Firebase** — Cloud Functions i Firestore w `europe-west1`, ze stroną
napiwków dla fana serwowaną z **`tip.live.tips/t/<id>`**. Nigdy nie dotyka pieniędzy. Oto
wszystko, czym się zajmuje.

### Co przechowuje artysta

Utworzenie strony napiwków zapisuje **nazwę wyświetlaną artysty, jego publiczną wiadomość,
jego walutę oraz identyfikatory płatnicze, które postanowił opublikować** (jego link
płatności Stripe, nazwę użytkownika Revolut, identyfikator MobilePay Box ID, nazwę
użytkownika Monzo) oraz, jeśli włączone są prośby o piosenki, **jego publiczną listę piosenek
i ceny za poszczególne piosenki**. To wszystko są informacje, które artysta i tak celowo
publikuje dla fanów.

- **Okres przechowywania: strona napiwków, za którą nie stoi żadne konto, jest usuwana
  automatycznie po 90 dniach braku aktywności.** Strona napiwków należąca do zalogowanego
  konta żyje tak długo, jak zespół, do którego należy.
- Artysta może ją usunąć **natychmiast** z poziomu aplikacji, w dowolnym momencie.
- Nie zbieramy tu żadnego adresu e-mail, hasła, imienia i nazwiska ani danych bankowych.
- Sekret strony jest przechowywany **wyłącznie jako skrót**. Nie moglibyśmy Ci go zdradzić,
  nawet gdybyś o to poprosił; możemy tylko sprawdzić podany.

### Co wysyła fan

Formularz napiwku prosi o **kwotę**, a opcjonalnie o **imię** i **wiadomość** — a w przypadku
prośby o piosenkę także o to, którą piosenkę. To cały formularz. Bez e-maila, bez numeru
telefonu, bez konta.

Dokąd trafia ten napisany przez fana tekst i na jak długo, zależy od tego, czy artysta jest
zalogowany:

- **Jeśli za stroną napiwków nie stoi żadne konto**, napiwek jest zapisywany do **kolejki
  dostarczania** — pojedynczego dokumentu, który istnieje po to, by trafić na ekran artysty.
  Gdy ekran pokaże napiwek, **urządzenie artysty usuwa ten dokument.** Usunięcie *jest*
  potwierdzeniem odbioru. Jeśli ekran artysty jest offline — telefon zablokowany, brak
  zasięgu — napiwek **czeka w tej kolejce maksymalnie przez godzinę**, żeby po prostu nie
  przepadł, i trafia na ekran w chwili, gdy ten ponownie się połączy. Jeśli nikt się nie
  połączy, napiwek jest **usuwany, nieprzeczytany**, zamiatany zgodnie z harmonogramem. Dla
  artysty bez konta **ta kolejka jest jedynym miejscem, w którym tekst napisany przez fana
  jest w ogóle przechowywany na naszym serwerze, a godzina jest jej twardym limitem.**
- **Jeśli strona napiwków należy do zalogowanego konta**, nie ma żadnej kolejki. Nasz serwer
  zapisuje napiwek **prosto we własnej historii tego artysty** pod jego uid — do dzisiejszej
  sesji, jeśli trwa koncert, albo do archiwum samego zespołu, jeśli nie. Zostaje tam **tak
  długo, jak istnieje zespół**; to własna historia artysty i to właśnie po nią się zalogował.
  To ta sama historia, do której zapisuje webhook Stripe, powyżej.
- Twoje imię i wiadomość trafiają również do **tytułu płatności**, który otwiera się w
  Revolut, MobilePay lub Monzo — właśnie w ten sposób artysta wie, kto dał napiwek. Te firmy
  przetwarzają je następnie na podstawie własnych polityk prywatności.
- Przekaźnik nie prowadzi **żadnej międzyartystowskiej księgi napiwków**. Nie może pokazać
  Tobie, nam ani nikomu innemu listy tego, kto komu dał napiwek u różnych artystów.

### Adresy IP i ochrona przed nadużyciami

Otwarty formularz, do którego każdy może wysyłać dane, potrzebuje pewnej ochrony przed
botami, dlatego:

- Twój adres IP jest wysyłany do **Cloudflare Turnstile** — testu antybotowego działającego
  na stronie napiwków — aby potwierdzić, że nie jesteś botem. Turnstile to produkt
  Cloudflare, używany zamiast CAPTCHA, która by Cię profilowała. Turnstile i nasz DNS to
  jedyne rzeczy, które Cloudflare wciąż dla nas robi; sam przekaźnik działa teraz na
  Firebase. Zobacz [Politykę prywatności Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Twój adres IP służy też do **ograniczania liczby żądań** — wysłania napiwku, utworzenia
  strony napiwków, zrealizowania kodu dodania urządzenia. To, co w tym celu przechowujemy,
  to **solony kryptograficzny skrót adresu IP**, nigdy sam adres IP, przez około **dwie
  godziny**, a potem jest usuwany. Sól jest sekretem serwera: bez niej kod w ogóle odmawia
  zapisania czegokolwiek, zamiast trzymać skrót, który dałoby się odwrócić.
- **Operacyjne logi Google** rejestrują techniczne szczegóły żądań do przekaźnika — adres
  URL, czas, status — przez kilka dni. Nasz kod celowo nie zapisuje żadnych imion, żadnych
  wiadomości, żadnych sekretów ani żadnych nagłówków. Google działa jako nasz podmiot
  przetwarzający.

### Liczniki

Przekaźnik zlicza, **ile napiwków** przekazała dana strona napiwków, żebyśmy mogli wykrywać
nadużycia i wiedzieć, czy to w ogóle jest używane. To liczba. Nie zawiera żadnych danych
fanów.

## Kto co przetwarza

| Kto | Co otrzymuje | Po co |
| --- | --- | --- |
| **Google (Firebase)** | Konta, zsynchronizowane dane zalogowanego artysty, zaszyfrowany klucz Stripe, przekaźnik, tokeny push i ich dostarczanie, logi serwera | Opcjonalne konto, opcjonalny przekaźnik i powiadomienia push |
| **Google Cloud KMS** | Klucz, który opakowuje sekret Stripe zalogowanego artysty (nigdy sam sekret w postaci jawnej) | Utrzymanie przechowywanego klucza Stripe nieczytelnym w spoczynku |
| **Stripe** | Dane płatnicze fana, jako niezależny administrator danych; oraz, dla zalogowanego artysty, zdarzenia napiwków wysyłane do naszego webhooka | Napiwki kartą |
| **Cloudflare** | Adres IP fana, na potrzeby testu Turnstile na stronie napiwków. I nasz DNS. | Trzymanie botów z dala od formularza napiwku |
| **GitHub** | Adres IP i user-agent każdego, kto wczytuje tę stronę | Hosting strony |
| **Usługa push Twojej przeglądarki / telefonu** (np. Google dla Chrome) | Token push i treść powiadomienia, jeśli włączyłeś powiadomienia | Dostarczanie powiadomień push |
| **Revolut / MobilePay / Monzo** | Wszystko, co fan robi w ich własnej aplikacji, wraz z tytułem płatności | Te metody płatności |

Nikomu niczego nie sprzedajemy i nie ma nikogo więcej na tej liście.

## Podstawa prawna, jeśli jej potrzebujesz (RODO)

- Prowadzenie konta, o które poprosiłeś, synchronizowanie Twoich własnych danych na Twoje
  własne urządzenia, przechowywanie Twojego klucza Stripe, żeby Twoje napiwki docierały do
  Twojej historii, prowadzenie przekaźnika dla artysty, który go włączył, dostarczenie
  napiwku fana na ekran, do którego był skierowany, oraz wysłanie powiadomienia push, które
  włączyłeś: **wykonanie usługi, o którą poprosiłeś**.
- Ograniczanie liczby żądań, Turnstile, limity oparte na skrócie adresu IP i unieważnianie
  urządzeń: **prawnie uzasadniony interes** polegający na ochronie darmowej, otwartej usługi
  przed zniszczeniem przez boty i oszustwa oraz na utrzymaniu bezpieczeństwa kont artystów.
- Logi serwera: **prawnie uzasadniony interes** polegający na prowadzeniu i zabezpieczaniu
  usługi.

## Usuwanie rzeczy

To liczy się bardziej niż jakakolwiek obietnica, którą moglibyśmy złożyć, więc oto dokładnie
to, co istnieje dzisiaj — łącznie z tym, czego nie ma.

- **Bez konta**: odinstaluj aplikację. To wszystko, znikło.
- **Zespół**: usunięcie zespołu w aplikacji kasuje dane tego zespołu w chmurze — jego
  ustawienia, jego klucze, jego sesje, jego historię napiwków — wraz z kopią na urządzeniu.
- **Strona napiwków**: usuń ją lub wygeneruj na nowo w aplikacji, a zostanie natychmiast
  wymazana z przekaźnika, razem z wszystkimi oczekującymi napiwkami.
- **Powiadomienia push**: wyłącz je na urządzeniu, a jego token push zostaje usunięty. Kanał
  dzwonka czyści się wraz z zespołem lub kontem.
- **Urządzenie**: Ustawienia → Bezpieczeństwo wypisują Twoje urządzenia. Możesz któreś
  unieważnić albo wylogować się wszędzie indziej — co natychmiast, a nie kiedyś tam, kończy
  sesję każdego innego urządzenia.
- **Całe Twoje konto, jednym dotknięciem: aplikacja nie ma jeszcze takiego przycisku.**
  Wolimy się do tego przyznać, niż udawać, że jest inaczej. Dopóki go nie ma, napisz na
  **[contact@live.tips](mailto:contact@live.tips)**, a my ręcznie usuniemy konto i wszystko,
  co się pod nim znajduje. W międzyczasie możesz już teraz usunąć każdy zespół, co usuwa
  wszystko, co ma jakąkolwiek treść — łącznie z przechowywanym kluczem Stripe — i zostawia po
  sobie puste konto.

## Twoje prawa

Możesz zażądać od nas kopii, sprostowania lub usunięcia wszystkiego, co o Tobie
przechowujemy, a także złożyć skargę do krajowego organu ochrony danych osobowych. Napisz na
**[contact@live.tips](mailto:contact@live.tips)**.

W praktyce większość tego i tak jest w Twoich rękach: artysta może natychmiast usunąć stronę
napiwków lub zespół z poziomu aplikacji, niedostarczone napiwki fanów na stronie bez konta
wyparowują w ciągu godziny, a jeśli nigdy się nie zalogujesz, nic z tego nigdy nie było
nigdzie poza Twoim własnym urządzeniem.

## Dzieci

live.tips nie jest skierowane do dzieci i nie przetwarzamy świadomie ich danych.

## Zmiany

Będziemy aktualizować tę stronę, gdy zmieni się oprogramowanie. Ponieważ cały projekt jest
otwartoźródłowy, **każda dawna wersja tej polityki znajduje się w publicznej historii git** —
możesz dokładnie porównać, co i kiedy się zmieniło.

## Język

Ta polityka jest publikowana we wszystkich językach obsługiwanych przez stronę, dla wygody.
Jeśli tłumaczenie i wersja angielska są ze sobą sprzeczne, **wiążąca jest wersja angielska**.
