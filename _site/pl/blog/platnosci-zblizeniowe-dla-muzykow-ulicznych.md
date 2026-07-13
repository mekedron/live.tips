# Napiwki zbliżeniowe dla ulicznych muzyków — szczerze policzone

> Tap to Pay na telefonie, terminal kartowy, naklejka NFC, kod QR — cztery różne rzeczy, które wszystkie nazywa się „zbliżeniowymi". Ile każda z nich naprawdę kosztuje w 2026, co tak naprawdę robi tag NFC (nie to, co myślisz) i kiedy przyłożenie wygrywa ze skanem.

Canonical: https://live.tips/pl/blog/platnosci-zblizeniowe-dla-muzykow-ulicznych/
Published: 2026-07-11
Language: pl
Tags: contactless, NFC, QR codes, Tap to Pay, fees

---

Poszukaj napiwków zbliżeniowych dla ulicznych muzyków, a internet poda ci rok 2018.
Studencki prototyp z Brunel University o nazwie Tiptap — stojak, w który wsuwa się
telefon — dostał wtedy rundkę w prasie, i ta prasa do dziś siedzi na pierwszej
stronie wyników. Ładny pomysł. Był też, słowami samych artykułów, *wciąż na etapie
rozwoju*, a w planach miał jednorazową opłatę plus **5% od każdego napiwku**. Nigdy
nie stał się czymś, co można kupić.

(„tiptap", na który trafisz dzisiaj, to niepowiązana firma z Ontario, sprzedająca
zbliżeniowe terminale do zbiórek organizacjom charytatywnym. To samo słowo, inny
produkt, nie dla ciebie.)

Czyli uczciwy stan rzeczy nie został spisany od ośmiu lat. Oto on.

To jest zejście w głąb *tapu*. Jeśli twoje prawdziwe pytanie jest szersze — jak w
ogóle dostać pieniądze, skoro nikt nie nosi gotówki, i ile kosztuje każdy ze
sposobów — zacznij od [jak grajkowie uliczni przyjmują płatności
kartą](https://live.tips/pl/blog/platnosci-karta-dla-muzykow-ulicznych/) i wróć tu potem.

## Cztery różne rzeczy nazywa się „zbliżeniowymi"

Tu mieszka większość zamieszania, więc rozdzielmy je, zanim cokolwiek policzymy.

1. **Tap to Pay na twoim własnym telefonie.** Twój telefon staje się terminalem. Fan
   przykłada swoją kartę albo zegarek do *twojego* aparatu. Zero dodatkowego sprzętu.
2. **Terminal kartowy** — SumUp, Zettle, Square. Mały plastikowy terminal, który
   wyciągasz w stronę fana. Fan go dotyka.
3. **Tag NFC** — naklejka albo tabliczka „przyłóż telefon, żeby dać napiwek". Ten
   punkt jest rozumiany opacznie niemal powszechnie, i następna sekcja tłumaczy
   dlaczego.
4. **Kod QR.** W sensie NFC nie jest zbliżeniowy — ale czytaj dalej, bo od strony
   fana bardzo często kończy się dokładnie tym samym przyłożeniem telefonu.

Tylko dwa pierwsze to *terminale płatnicze*. O tę różnicę chodzi w całym tym wpisie.

## Tag NFC nie przyjmuje płatności

Zabijmy to porządnie, bo sprzedawcy chętnie zostawią cię w błędzie.

Naklejka NFC — ta tania, z układem NTAG213, którego używa większość — ma **144 bajty
pamięci**. Nie 144 kilobajty. Nie umie wykonać kodu, nie ma baterii, nigdy nie
słyszała o organizacji kartowej i nie zmieściłaby protokołu płatniczego, nawet gdyby
chciała. To, co mieści, to krótki ciąg znaków w formacie NDEF, a ten ciąg jest w
przytłaczającej większości przypadków **adresem URL**.

Przykładasz telefon — i telefon otwiera stronę WWW. To cała funkcja.

Co oznacza, że tabliczka „przyłóż, żeby dać napiwek" jest kodem QR, który otwierasz
dotknięciem zamiast celowaniem. Ten sam cel, ta sama strona, ta sama płatność
odbywająca się w przeglądarce. Nawet specjaliści to mówią, jeśli czytać ich uważnie:
tiptap na własnej stronie opisuje swoje urządzenie z dowolną kwotą tak, że gdy
darczyńcy przyłożą do niego telefon, *„zostaną przekierowani na twoją stronę zbiórki
online"*. Przekierowani. Na stronę. Bo tyle właśnie potrafi tag.

To naprawdę użyteczne i naprawdę tanie — puste naklejki NTAG213 zaczynają się od
około **$0,24 za sztukę** w paczkach. Jeśli masz już stronę z napiwkami, przyklejenie
taga na futerale obok wydrukowanego kodu kosztuje cię grosze i daje części fanów
szybszą drogę do środka.

Ale miej jasność co do tego, co kupiłeś: **drugie drzwi frontowe do tej samej strony.**
Nie maszynę do kart.

### A na zewnątrz to grymaśne drzwi

Awarie są prawdziwe i żaden sprzedawca tagów ich nie wymienia:

- **Telefon fana musi być odblokowany i w użyciu.** Własna dokumentacja Apple mówi
  wprost: odczyt tagów w tle działa tylko wtedy, gdy iPhone jest w użyciu, a jeśli
  telefon jest zablokowany, system każe go najpierw odblokować.
- **Nie działa, gdy otwarty jest aparat.** Apple wymienia włączony aparat jako jeden
  ze stanów, w których odczyt tagów w tle jest niedostępny. Rozkoszuj się ironią: fan
  sięgający po aparat, żeby zeskanować twój kod QR, właśnie wyłączył ci taga NFC.
- **Potrzebny jest iPhone XS lub nowszy**, a na Androidzie musi być włączone NFC —
  które niektóre tryby oszczędzania energii wyłączają.
- **Zasięg to jakieś 4 cm.** Fan musi tego naprawdę dotknąć. W tłumie, schylając się
  do futerału po gitarze, to spore wymaganie.
- **Metal i magnesy to zabijają.** Tag przyklejony do wzmacniacza albo fan z
  magnetycznym etui — i nie dzieje się zupełnie nic.

Tag to niezła druga opcja. To zła jedyna opcja.

## Tap to Pay na telefonie: właściwa nowość roku 2026

Oto rzecz, która zmieniła się od czasu artykułów o Tiptapie i o której żadna z tych
zleżałych relacji nie wie.

**Tap to Pay na iPhonie** zmienia telefon, który i tak masz w kieszeni, w terminal
zbliżeniowy. Bez dongla, bez czytnika, bez stojaka. Apple podaje dostępność w
**ponad 70 krajach i regionach**, a lista dostawców, przez których można z tego
korzystać w Europie, wygląda jak cała branża — w samych Niemczech: Adyen, Mollie,
myPOS, Nexi, PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Wielka
Brytania, Francja, Holandia, Szwecja, Finlandia i Dania mają podobne listy.
Potrzebujesz iPhone'a XS albo nowszego.

**Tap to Pay na Androidzie** też istnieje, ale jest węższy. Przez Stripe'a jest
ogólnie dostępny w AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL,
SE, SG i US, a kolejnych osiemnaście krajów jest w publicznej zapowiedzi. Twój
telefon potrzebuje Androida 13 lub nowszego, czujnika NFC, nieodblokowanego
bootloadera, Google Mobile Services oraz wyłączonych opcji programisty — to ostatnie
łapie więcej ludzi, niż byś pomyślał.

Wersja praktyczna: **SumUp podaje Tap to Pay przy £0 sprzętu.** Jeśli masz świeżego
iPhone'a i jesteś we wspieranym kraju, koszt wejścia w wyciągnięcie do kogoś
terminala zbliżeniowego wynosi teraz zero. Sam ten fakt czyni każdy artykuł z 2018
w stylu „kup ten stojak" nieaktualnym.

## Terminale kartowe i ile naprawdę kosztują

Jeśli chcesz osobny kawałek plastiku — a są ku temu dobre powody, niżej — to rynek
składa się z trzech produktów.

| | Sprzęt | Opłata od jednego przyłożenia na miejscu |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay £0 · Solo Lite £25 · Solo £79 · Terminal £135 | **1,69%**, bez opłaty stałej |
| **SumUp** (Niemcy) | — | **1,39%**, bez opłaty stałej |
| **Zettle / PayPal POS** (UK) | Czytnik od £29 dla nowego użytkownika, potem £69 | **1,75%**, bez opłaty stałej |
| **Square** (UK) | Czytnik zbliżeniowy i chipowy £19 | **1,75%**, bez opłaty stałej |
| **Square** (US) | Czytnik zbliżeniowy i chipowy $59 | **2,6% + $0,15** |

Ceny bez VAT, wedle stanu opublikowanego w lipcu 2026. Sprawdź je sam; one się ruszają.

A teraz przeczytaj tę tabelę jeszcze raz, bo mówi coś, co przeczy temu, co ci
prawdopodobnie wmówiono.

## Rachunek opłat i to, co wszyscy mają odwrotnie

Utarta mądrość mówi, że opłaty kartowe niszczą małe napiwki z powodu stałej opłaty od
transakcji — tych dwudziestu pięciu centów, które zjadają jedną ósmą napiwku €2. To
prawda i sami [rozpisaliśmy ten rachunek](https://live.tips/pl/blog/zbuduj-sloik-na-napiwki-na-wlasnym-koncie-stripe/).

Ale to prawda o kartowych płatnościach *online*. **Europejskie czytniki zbliżeniowe
przeważnie w ogóle nie mają opłaty stałej.** SumUp, Zettle i Square w Wielkiej
Brytanii i w UE liczą wyłącznie procent. Co oznacza:

| Napiwek €2 | Opłata | Artyście zostaje | Efektywne cięcie |
| --- | --- | --- | --- |
| Czytnik SumUp (DE, 1,39%) | €0,03 | €1,97 | **1,4%** |
| Zettle / Square (UK, 1,75%) | €0,04 | €1,96 | 1,8% |
| Stripe, karta online (EOG, 1,5% + €0,25) | €0,28 | €1,72 | **14,0%** |
| Czytnik Square (US, 2,6% + $0,15) | $0,20 | $1,80 | **10,1%** |

Na samej opłacie europejski terminal zbliżeniowy bije płatność kartą online przy
małym napiwku, i to nie jest wyrównana walka. Jesteśmy produktem opartym na kodzie QR
i mówimy ci to: przy napiwku €2 czytnik SumUp zostawia ci €0,25, których strona
hostowana przez Stripe'a ci nie zostawia.

Dwie rzeczy przywracają temu proporcje.

**Sprzęt to ta sama opłata stała, tylko przesunięta.** Oszczędność €0,25 na napiwku
wobec Solo za £79 oznacza mniej więcej **trzysta przyłożeń, zanim czytnik się
zwróci**. Dla pracującego ulicznego muzyka to realna liczba, a dla kogoś, kto gra
dwa razy w lecie — śmieszna. (A Tap to Pay od SumUpa za £0 robi z tego zero
przyłożeń — i właśnie dlatego ta opcja liczy się bardziej niż same czytniki.)

**A Stany odwracają to z powrotem.** Amerykańska stawka Square'a za płatność na
miejscu niesie stałą opłatę $0,15, więc przyłożenie na $2 też traci na terminalu
jedną dziesiątą siebie. Prezent „bez opłaty stałej" jest europejski.

Jest też próg, na który natrafisz: SumUp nie przyjmie płatności poniżej **£1 / €1**.
Jakąkolwiek szynę wybierzesz, bardzo mały napiwek tak naprawdę nie jest transakcją
kartową.

## Kiedy więc przyłożenie bije skan?

Zdejmij technologię, a zostanie pytanie o ręce fana.

**Przyłożenie wymaga, żeby telefon fana był odblokowany i w jego dłoni, i żeby ty coś
wyciągał w jego stronę.** Gdy oba warunki są spełnione, to najszybsza rzecz w
płatnościach. Bez aplikacji, bez celowania, bez pisania, załatwione w sekundę.

**Skan wymaga, żeby fan otworzył aparat** — jeden świadomy ruch więcej — ale od
ciebie nie wymaga zupełnie niczego. Kod siedzi na futerale. Działa u fana stojącego z
tyłu. Działa u czterdziestu osób naraz. Działa, kiedy ty wciąż grasz.

Co daje uczciwy podział:

- **Przyłożenie wygrywa, gdy możesz podejść do ludzi.** Koniec setu, kapelusz w
  obieg, jeden fan naraz, ty wolny, żeby trzymać terminal. Przyłożenie to mniejsza
  prośba niż „wyjmij aparat", a w tej chwili jesteś fizycznie obecny, żeby to domknąć.
- **Skan wygrywa, gdy nie możesz.** W środku piosenki. Tłum w trzech rzędach. Miejsce,
  z którego nie możesz odejść od wzmacniacza. Każdy, kto chce dać, przechodząc obok.
  Terminal obsłuży dokładnie jedną osobę; wydrukowany kod obsługuje cały plac
  jednocześnie i nie wymaga, żebyś przestał grać, by go obsłużyć.

Ten ostatni punkt jest tym, którego sprzedawcy terminali nigdy nie podnoszą, i jest
największy. **Czytnik kart to wąskie gardło z kolejką.** Kod QR nie ma kolejki.

A tu jest część, która rozpuszcza połowę tego sporu: na dobrze zbudowanej stronie z
napiwkami **skan i tak kończy się przyłożeniem**. Fan skanuje, strona się otwiera, a
jego telefon proponuje Apple Pay albo Google Pay. Podwójne kliknięcie, telefon przy
twarzy, gotowe. Z perspektywy fana to płatność zbliżeniowa — ten sam portfel, ta sama
karta, te same dwie sekundy — a ty nie kupiłeś żadnego sprzętu, żeby się to stało.

## Gdzie w tym wszystkim jest live.tips i kiedy kupić zamiast tego SumUpa

[live.tips](https://github.com/mekedron/live.tips) to puszka na napiwki oparta na
kodzie QR. Jeden kod, który nigdy się nie zmienia, wskazujący prosto na własny link
płatniczy Stripe'a artysty. Nie ma salda live.tips, nie ma prowizji i nie ma platformy
na drodze — opłata jest własną opłatą Stripe'a i Stripe pobiera ją od artysty
bezpośrednio. Wszystko na licencji MIT, a tablet na scenie pokazuje każdy napiwek w
chwili, gdy dociera. Drogę pieniędzy rozpisaliśmy w
[jak live.tips obchodzi się z pieniędzmi](https://live.tips/pl/blog/jak-live-tips-obchodzi-sie-z-pieniedzmi/), a to,
dlaczego jest to [jeden kod, a nie po jednym na dostawcę](https://live.tips/pl/blog/jeden-kod-qr-kazda-metoda-platnosci/),
też.

Ta strona obsługuje Apple Pay i Google Pay. Więc live.tips *jest* zbliżeniowe z
perspektywy fana — przy tym przyłożeniu, które się liczy, tym na końcu, bez terminala
do kupienia, ładowania albo upuszczenia w deszczu. Po prostu nie jest terminalem.

**Jeśli chcesz fizycznie coś wyciągnąć i żeby ktoś obcy to dotknął, kup czytnik
kart.** Weź Tap to Pay od SumUpa, jeśli twój telefon i twój kraj to obsługują, bo nie
kosztuje nic; weź Solo, jeśli wolisz nie podsuwać własnego telefonu tłumowi. Tak czy
inaczej, przy przyłożeniu na €2 w Europie pobije to naszą opłatę, a my wolimy to
powiedzieć, niż udawać, że jest inaczej.

Możesz też robić jedno i drugie, i wielu ulicznych muzyków powinno: kod przyklejony
do futerału przez cały wieczór, łapiący przechodniów, gdy grasz — i terminal w dłoni
na te dziesięć sekund po ostatnim akordzie, gdy pierwszy rząd sięga do kieszeni. One
ze sobą nie konkurują. Łapią różnych ludzi.

Czym żadne z nich nie jest, to stojak z 2018 roku, który bierze 5%.

Opłaty, ceny sprzętu i dostępność w krajach zgodnie z tym, co Apple, Stripe, SumUp, Zettle/PayPal i Square opublikowali w lipcu 2026, bez VAT. Ceny naklejek NFC za GoToTags. Warunki Tiptapa z 2018 za Brunel University i Finextrą. Wszystko to się zmienia; sprawdź to u dostawcy, zanim wydasz pieniądze.
{: .footnote }
