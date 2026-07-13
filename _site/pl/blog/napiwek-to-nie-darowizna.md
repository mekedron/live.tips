# Napiwek to nie darowizna — a Stripe traktuje je jak dwa różne biznesy

> Uliczny muzyk, który prosi o „przycisk darowizny", opisuje działalność, której Stripe w większości Europy zakazuje. Napiwek płaci za usługę już wykonaną; darowizna to zbiórka na cele charytatywne. Ta różnica decyduje, do jakiej kategorii trafi twoje konto — a jeden parametr API potrafi wybrać za ciebie tę złą.

Canonical: https://live.tips/pl/blog/napiwek-to-nie-darowizna/
Published: 2026-07-11
Language: pl
Tags: Stripe, donations, busking, compliance, how-to

---

Każde narzędzie w internecie chce, żebyś nazwał to darowizną. Przyciski mówią
*Wesprzyj*. Wpisy na blogach mówią *przycisk darowizn dla muzyków*. Katalogi
wtyczek mówią *przyjmuj darowizny*. Jeśli jesteś muzykiem i szukasz sposobu, żeby
dostawać pieniądze od ludzi, którzy nie mają gotówki, to słowo chodzi za tobą
wszędzie.

Potem zakładasz konto Stripe, a Stripe pyta, czym zajmuje się twoja działalność. I
w tym momencie słowo przestaje być hasłem marketingowym, a staje się **kategorią
biznesową** — taką, której Stripe w większości Europy nie dopuszcza.

To nie jest czepianie się słówek ani rozróżnienie dla prawników. To jedno pytanie,
które najczęściej powoduje, że najzwyklejsze konto płatnicze ulicznego muzyka trafia
do weryfikacji, utyka albo zostaje odrzucone. Prawie nikt nie napisał tego wprost dla
grających, więc proszę bardzo.

## Dwa słowa, dwa biznesy

Stripe sam wyznacza granicę, jednym zdaniem na stronę. Ze strony
[Wymagania dotyczące przyjmowania napiwków i darowizn](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> napiwek musi zostać dany za towar lub usługę, które zostały już dostarczone (np.
> treści)

> darowizna musi być powiązana z konkretnym celem charytatywnym, do którego
> realizacji się zobowiązujesz

Strony Stripe'a są po angielsku; tłumaczymy je tu dla ciebie, a oryginały są pod
linkami.

Przeczytaj te dwa zdania dwa razy, bo wszystko inne w tym wpisie z nich wynika.

**Napiwek** patrzy wstecz, na coś, co już się wydarzyło. Usługa została wykonana,
fanowi się spodobało, fan dopłacił. Pieniądze są bezwarunkowe i nie jesteś już nic
nikomu winien. To jest ta linijka na rachunku w restauracji, monety w kapeluszu,
piątka wciśnięta w dłoń po ostatniej piosence.

**Darowizna** patrzy w przód, na coś, co obiecałeś zrobić. Jest cel. Jest
przeznaczenie, które opisałeś osobie dającej. I — Stripe mówi to wprost — pieniądze
muszą naprawdę pójść na to przeznaczenie. Trzymasz je w zaufaniu na rzecz czegoś, co
zobowiązałeś się zrobić.

To nie są dwa odcienie tego samego gestu. To dwie różne relacje, z dwoma różnymi
zestawami zobowiązań, i Stripe ubezpiecza je jako dwa różne biznesy.

## Uliczny muzyk stoi jednoznacznie po stronie napiwku

Stałeś dwie godziny na rynku i grałeś. Zatrzymało się czterdzieści osób. Jedna z nich
skanuje twój kod i wysyła ci pięć euro.

**To jest napiwek.** Występ jest usługą. Została wykonana — widzieli, jak się dzieje.
Nie ma celu, nie ma beneficjenta, nie ma przeznaczenia, do którego się zobowiązałeś, i
nikt nie powierzył ci pieniędzy na projekt. Jesteś artystą, któremu płacą za występ, a
to jeden z najstarszych i najmniej kontrowersyjnych układów handlowych, jakie istnieją.

Zamieszanie bierze się stąd, że napiwek dla ulicznego muzyka jest *dobrowolny*, a nas
wytresowano do myślenia, że dobrowolne pieniądze to pieniądze charytatywne. Nie są.
Napiwek też jest dobrowolny. To nie dobrowolność czyni coś darowizną — czyni to **cel
charytatywny**.

Więc kiedy twoja tabliczka mówi „darowizny mile widziane", nie jesteś skromny ani
uprzejmy. Opisujesz — w języku operatora płatności — działalność, której nie
prowadzisz.

## Ile to słowo naprawdę cię kosztuje

Tu abstrakcja zamienia się w pieniądze.

Stripe publikuje
[listę działalności zakazanych](https://stripe.com/legal/restricted-businesses) —
rzeczy, których nie wolno robić na koncie Stripe albo które wolno tylko w niektórych
krajach. Pod nagłówkiem **Crowdfunding i zbiórki** stoi ta linijka, dosłownie:

> Organizacje zbierające fundusze na cel charytatywny (Uwaga: obsługiwane w
> Australii, Kanadzie, Wielkiej Brytanii i Stanach Zjednoczonych. Zakazane we
> wszystkich pozostałych krajach.)

Przeczytaj ten nawias powoli. Zbiórka na cele charytatywne to **działalność
obsługiwana w czterech krajach** — Australia, Kanada, Wielka Brytania, USA — i
**zakazana wszędzie indziej.**

Wszędzie indziej obejmuje Polskę. Obejmuje też Niemcy, Francję, Hiszpanię, Włochy,
Holandię, Finlandię i każdy inny kraj, w którym uliczny muzyk mógłby rozsądnie stać.
Większość ulicznych grajków tego świata mieszka we „wszystkich pozostałych krajach".

Ta sama strona wymienia jako ograniczone również *„zbiórki prowadzone przez organizacje
non-profit, organizacje charytatywne, organizacje polityczne i firmy oferujące nagrodę
w zamian za darowiznę"*, a strona Stripe'a o napiwkach i darowiznach dokłada do tego
zestaw reguł krajowych: w Japonii osoby prywatne w ogóle nie mogą przyjmować darowizn;
w Singapurze mogą tylko zarejestrowane przez państwo organizacje charytatywne lub
religijne; w Indiach, Hongkongu i Tajlandii darowizny nie są obsługiwane.

Czyli muzyk w Krakowie, który wpisuje „darowizny na moją muzykę" w formularzu
rejestracyjnym Stripe'a, właśnie opisał działalność, której Stripe w Polsce zakazuje.
Nie dlatego, że granie na ulicy jest zakazane — granie na ulicy jest całkowicie w
porządku — tylko dlatego, że słowa, które wybrał, należą do kategorii, która jest.

## A teraz kalibracja, bo to nie jest horror

**Uliczni muzycy nie są działalnością zakazaną.** Napiwki nie są działalnością
zakazaną. Występ na żywo nie jest na liście, nie wciągnie cię na listę i jest mniej
więcej najzwyklejszą rzeczą, jaką można zrobić z kontem płatniczym. Jeśli opiszesz
siebie zgodnie z prawdą, nic z tego cię nie dotknie, a konfiguracja będzie nudna —
czyli dokładnie taka, jaka być powinna.

Ryzykiem nie jest tu Stripe. Ryzykiem jest **błędne zaklasyfikowanie samego siebie** —
wejście do pokoju i ogłoszenie się zbierającym na cele charytatywne, kiedy jesteś
gitarzystą. Stripe nie ma jak wiedzieć, że miałeś na myśli „daj mi napiwek". Ma tylko
formularz, który wypełniłeś, opis działalności, który napisałeś, i słowa na stronie, na
którą wskazuje twój kod QR.

Nikt w Stripe nie poluje na ulicznych muzyków. Oni po prostu czytają to, co im
powiedziałeś.

## Pułapka ma głębokość jednego parametru

Oto część, której prawie nikt nie zapisuje, i jest to najużyteczniejsza rzecz w tym
wpisie.

Payment Links w Stripe mają parametr o nazwie `submit_type`.
[Dokumentacja API](https://docs.stripe.com/api/payment-link/object) opisuje go jako coś
niemal kosmetycznego:

> Wskazuje typ wykonywanej transakcji, co dostosowuje odpowiednie teksty na stronie,
> takie jak przycisk zatwierdzenia.

*Dostosowuje odpowiednie teksty.* Rozsądnie byś stąd wywnioskował, że zmienia to etykietę
przycisku i że puszka na napiwki powinna oczywiście mówić *Donate* („wesprzyj") zamiast
*Buy* („kup"), bo *Buy* to dziwne słowo do wydrukowania pod kapeluszem ulicznego grajka.

Potem czytasz, co poszczególne wartości robią naprawdę:

> `donate` — Zalecane przy przyjmowaniu darowizn. Przycisk zatwierdzenia dostaje
> etykietę 'Donate', a adresy URL używają nazwy hosta `donate.stripe.com`

> `pay` — Przycisk zatwierdzenia dostaje etykietę 'Buy', a adresy URL używają nazwy
> hosta `buy.stripe.com`

**To nie etykieta. To nazwa hosta.** Ustawiasz `submit_type=donate` i link, który
podaje ci Stripe — ten, który zamieniasz w kod QR, drukujesz i przyklejasz do futerału
od gitary — mieszka pod `donate.stripe.com`. Każdy fan, który go zeskanuje, widzi stronę
darowizn. Każda płatność w twoim panelu przyszła przez ścieżkę darowizny. Kod QR na
twoim futerale mówi Stripe'owi, mówi twojej publiczności, a w końcu mówi i tobie, że
zbierasz darowizny.

Nigdzie nie napisałeś słowa „darowizna". Napisał je za ciebie jeden parametr API — i
wydrukował na plastikowej tabliczce na rynku.

To łatwa pułapka i nie jest winą czytelnika, że w nią wchodzi: parametr jest
udokumentowany jako zmiana tekstu, *Donate* jest wyraźnie milszym słowem do wydrukowania
pod kapeluszem ulicznego grajka, a konsekwencja — klasyfikacja działalności — leży dwa
zdania niżej, niż większość ludzi czyta.

live.tips wysyła `submit_type=pay`. Link każdego artysty jest linkiem
`buy.stripe.com`, a w kodzie stoi komentarz mówiący dlaczego, bo to dokładnie ten rodzaj
rzeczy, którą ktoś dopisujący się później do projektu inaczej by „poprawił".

## Co muzyk powinien naprawdę zrobić

Nic z tego nie wymaga prawnika. Wymaga pięciu minut i kilku zwykłych słów.

- **Opisz prawdziwą działalność** w rejestracji Stripe. „Występy muzyczne na żywo."
  „Muzyk uliczny." „Muzyk — napiwki od publiczności na występach na żywo." Napisz, że
  występujesz i że płatności są napiwkami za te występy.
- **Wybierz pasującą kategorię.** Rozrywka na żywo, sztuki performatywne, muzyk. Nie
  organizacja charytatywna, nie non-profit, nie zbiórka.
- **Używaj `submit_type=pay`**, jeśli sam budujesz Payment Link. Jeśli zbudowało go
  narzędzie, spójrz na adres, który wyprodukowało: `buy.stripe.com` to puszka na
  napiwki, `donate.stripe.com` to strona darowizn. To sprawdzenie na dwie sekundy i
  mówi ci, za kogo uważa cię twoje narzędzie.
- **Nie nazywaj tego darowizną** — ani na tabliczce, ani na stronie, ani w opisie
  działalności w Stripe. „Napiwki", „puszka na napiwki", „wesprzyj zespół", „postaw nam
  piwo" opisują to, co się faktycznie dzieje. „Darowizna" opisuje coś innego.
- **Prawdziwą zbiórkę trzymaj osobno.** Jeśli grasz koncert charytatywny i pieniądze idą
  na cel, to *naprawdę* jest zbiórka na cele charytatywne i powyższe reguły dotyczą już
  ciebie — razem z listą krajów. Zrób to na właściwym koncie, we właściwym kraju, po
  przeczytaniu warunków Stripe'a, i nigdy przez puszkę na napiwki, której używasz w
  zwykłe wieczory.

Ten ostatni punkt zasługuje na podkreślenie, bo to uczciwa połowa argumentu. Nie mówimy,
że darowizny są złe ani że muzyk nigdy nie może zbierać pieniędzy na cel. Mówimy, że to
**inna działalność**, z innymi regułami, i że przepuszczanie jej po cichu przez ten sam
kod QR to sposób na kłopoty z obiema.

Warto znać jeszcze jedno zdanie ze strony Stripe'a o napiwkach i darowiznach, bo wyklucza
trzecią rzecz, którą ludzie mylą z obiema: Stripe nie zajmuje się *„obsługą płatności dla
prywatnych lub peer-to-peer przekazów pieniężnych (np. wysyłania pieniędzy między
znajomymi)"*. Napiwek to też nie prezent między znajomymi. Jeśli chcesz tej szyny — fan
po prostu przesyła ci pieniądze, od osoby do osoby — to właśnie tym są Revolut i
MobilePay, i dlatego w naszej aplikacji żyją one
[całkowicie poza Stripe](https://live.tips/pl/blog/jeden-kod-qr-kazda-metoda-platnosci/).

## Czym ten wpis nie jest

Nie jest poradą prawną. Nie jest poradą podatkową — to, jak opodatkowane są napiwki,
różni się ogromnie w zależności od kraju, czasem od miasta, i jest tu całkowicie poza
zakresem; zapytaj kogoś kompetentnego tam, gdzie mieszkasz.

I nie jest obietnicą dotyczącą twojego konta. **To, czy Stripe cię zaakceptuje, jest
wyłącznie decyzją Stripe'a.** live.tips nie ma ze Stripe'em żadnej relacji, nie może
wpłynąć na weryfikację ani odwołać się od niej w twoim imieniu. To, co potrafi nasze
oprogramowanie, to nie wkładać ci słów w usta. To, co napiszesz w formularzu, wciąż
piszesz sam.

Zasady też się zmieniają. Cytowane tu linijki stały na stronach Stripe'a w lipcu 2026, a
linki są tuż obok; idź i przeczytaj je sam, zamiast wierzyć wpisowi na blogu — łącznie z
tym.

## Wersja krótka

Zagrałeś set. Oglądali go. Zapłacili ci za niego.

To jest napiwek. Powiedz to — na tabliczce, w formularzu, w adresie URL — a nudny wynik,
którego chcesz, będzie tym, który dostaniesz. Puszkę na napiwki budujemy dokładnie wokół
tego twierdzenia, aż do tego,
[na jaki host Stripe'a wskazuje twój kod QR](https://live.tips/pl/blog/zbuduj-sloik-na-napiwki-na-wlasnym-koncie-stripe/), a
jeśli chcesz szerszy obraz tego, dokąd naprawdę idą pieniądze, jest
[tutaj](https://live.tips/pl/blog/jak-live-tips-obchodzi-sie-z-pieniedzmi/).
