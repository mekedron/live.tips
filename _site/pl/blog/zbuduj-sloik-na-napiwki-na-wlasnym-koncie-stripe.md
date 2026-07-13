# Zbuduj słoik na napiwki na własnym koncie Stripe

> Trzy wywołania API dają ci hostowaną stronę „zapłać, ile chcesz” z Apple Pay i Google Pay — bez żadnego serwera. Oto cała budowa: klucz z ograniczeniami, uprawnienia, jak odczytywać napiwki bez webhooka i rachunek prowizji, którego nikt nie drukuje.

Canonical: https://live.tips/pl/blog/zbuduj-sloik-na-napiwki-na-wlasnym-koncie-stripe/
Published: 2026-07-11
Language: pl
Tags: Stripe, open source, how-to, API, fees

---

Chcesz słoik na napiwki. Nie chcesz oddawać platformie 5 % wieczoru ulicznego muzyka i
doskonale radzisz sobie z API. Pytanie nie brzmi więc *w jakim słoiku się zarejestrować*,
tylko *ile właściwie muszę zbudować*.

Mniej, niż myślisz. Na Stripe działająca odpowiedź to trzy wywołania API: żadnego serwera,
żadnego backendu, żadnego endpointu webhooka. Reszta tego wpisu to właśnie ta budowa —
plus dwie rzeczy, które wszyscy robią źle.

## Cała sztuczka to Price typu „zapłać, ile chcesz”

Stripe ma tryb cenowy, w którym to fan wpisuje kwotę. Nazywa się
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) i to jest
cała funkcja. Tworzysz Product, podpinasz do niego Price z
`custom_unit_amount[enabled]=true`, a na to zakładasz
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. rzecz, którą "sprzedajesz"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. cena, którą wybiera fan
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. strona
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

To trzecie wywołanie zwraca `url`. Ten URL *jest* twoim słoikiem na napiwki. To strona
hostowana przez Stripe — więc zgodna z PCI bez twojego udziału, zlokalizowana, i pokazuje
Apple Pay albo Google Pay każdemu fanowi, który ma je skonfigurowane na telefonie;
[dynamiczne metody płatności](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
decydują o tym za ciebie, na podstawie urządzenia i kraju. Nie napisałeś ani linijki
frontendu.

Zakoduj URL jako kod QR dowolną biblioteką — to zwykły string — wydrukuj, przyklej do
futerału. Kod nigdy nie wygasa i nie wskazuje na żaden twój serwer, bo go nie masz.

Dwa parametry warte poznania:

- **`custom_unit_amount[preset]`** to kwota, z którą otwiera się strona. `500` znaczy, że
  fan widzi już wpisane 5,00 € i może to zmienić. Ta liczba robi dla twojego średniego
  napiwku więcej niż cokolwiek innego na stronie.
- **`custom_unit_amount[minimum]`** to podłoga. Ustaw ją. Powód jest w sekcji o prowizjach
  poniżej i nie jest to błąd zaokrąglenia.

Możesz też zebrać imię i wiadomość. Payment Links przyjmują do trzech `custom_fields` — tak
zdobywasz „a od kogo to było” bez budowania formularza:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Twoje imię lub pseudonim" \
  -d "custom_fields[0][optional]"=true
```

Stripe ma [wymagania dotyczące przyjmowania napiwków i darowizn](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
przeczytaj je raz. „Zapłać, ile chcesz” nie łączy się też z innymi line itemami, rabatami ani
płatnościami cyklicznymi. Dla słoika na napiwki nic z tego nie przeszkadza.

Tę różnicę warto mieć po swojej stronie. Stripe ujmuje to tak: napiwek daje się za towar
lub usługę już wykonaną, a darowizna musi wiązać się z celem charytatywnym. Zagrałeś
koncert; napiwek za niego płaci. Dlatego wywołanie powyżej wysyła `submit_type=pay`, a nie
`donate` — `donate` umieściłoby twój link na `donate.stripe.com` i wydrukowało *Przekaż
darowiznę* na przycisku. To inna branża, i taka, którą Stripe sprawdza znacznie ostrzej.

## Klucz: załóż, że wycieknie, i zrób z tego nudę

Nie wkładaj klucza sekretnego (`sk_live_…`) do urządzenia, które stoi na scenie. Użyj
[klucza z ograniczeniami](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`):
wybierasz uprawnienie osobno dla każdego zasobu, a wszystko, czego nie wybrałeś, zostaje na
**None**.

Dla powyższej budowy pełna lista to pięć wierszy:

| Zasób | Uprawnienie | Po co |
| --- | --- | --- |
| Products | Write | utworzyć Product |
| Prices | Write | utworzyć Price „zapłać, ile chcesz” |
| Payment Links | Write | utworzyć link |
| Checkout Sessions | Read | zobaczyć napiwki, które weszły |
| Events | Read | feed na żywo (następna sekcja) |

Cała reszta — Balance, Payouts, Refunds, Customers, PaymentIntents, całe Connect — zostaje na
**None**.

A teraz zrób ćwiczenie, które nadaje temu wszystkiemu sens. O pierwszej w nocy ktoś podwędza ci
tablet ze stolika z merchem. Co złodziej zrobi z kluczem w keychainie? Odczyta historię napiwków
i stworzy kolejne linki na napiwki na twoim koncie. To cały promień rażenia. Nie zobaczy salda,
nie zleci wypłaty, nie zrobi zwrotu na swoją kartę, nie odczyta listy klientów. Unieważniasz
klucz z telefonu w taksówce do domu i urządzenie gaśnie. Z twoich pieniędzy nie ruszył się ani
cent.

Ta asymetria — zapis do słoika, zero dostępu do pieniędzy — jest jedynym powodem, dla którego
bezserwerowy projekt z własnym kluczem w ogóle da się obronić. Jest też powodem, dla którego
„Login with Stripe” nie jest tu odpowiedzią: OAuth wymaga serwera należącego do autora aplikacji,
który przechowa twój token — a serwer to dokładnie to, czego nie budujemy.

(Dziwactwo, na które trafisz: uprawnienie *Prices* nazywa się wewnętrznie `plan_write`, więc
komunikat błędu Stripe wymienia scope, którego pod tą nazwą w dashboardzie nie ma. Chodzi o
Prices.)

## Odczytywanie napiwków bez webhooka

Tu większość poradników się kończy albo sięga po webhooka — i tu scena naprawdę różni się od
aplikacji webowej.

Webhook to przychodzące żądanie HTTP. Tablet za statywem mikrofonowym nie może go odebrać. Siedzi
w gościnnym wi-fi klubu za NAT-em, nie ma publicznego adresu ani certyfikatu TLS — i nie ma po co
ich mieć. Jeśli pójdziesz drogą webhooka, musisz postawić serwer, który złapie zdarzenia, i socket,
który wypchnie je na urządzenie: backend, obciążenie operacyjne i miejsce, w którym teraz mieszkają
imiona twoich fanów. Właśnie odbudowałeś platformę, której chciałeś uniknąć.

Więc ciągnij, zamiast dać się popychać. Endpoint
[List all events](https://docs.stripe.com/api/events/list) Stripe jest publiczny, udokumentowany i
zwraca zdarzenia od najnowszych:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_OSTATNIE_WIDZIANE \
  -d limit=100
```

`ending_before` to cały projekt. Trzymaj id najnowszego przetworzonego zdarzenia; każde odpytanie
prosi o wszystko ściśle nowsze, a ty przesuwasz kursor. Żadnych znaczników czasu, żadnego dryfu
zegara, żadnego deduplikowania po kwocie. Przy pierwszym odpytaniu setu poproś o `limit=1` bez
kursora, żeby zakotwiczyć się na tym, co już jest — inaczej podczas próby dźwięku odtworzysz napiwki
z dzisiejszego ranka.

Potem filtruj to, co wraca. Oba typy zdarzeń mogą wystrzelić dla jednej płatności, więc deduplikuj
po id Checkout Session. Sprawdzaj `payment_status == "paid"` — sesja zakończona to niekoniecznie
sesja opłacona. I sprawdzaj, czy `payment_link` zgadza się z *twoim* linkiem, bo `/v1/events`
obejmuje całe konto i chętnie poda ci ruch ze wszystkiego innego, co to konto Stripe robi.

Bądź uczciwy co do kompromisów, bo są prawdziwe:

- **Stripe zaleca webhooki.** Odpytywanie nie jest błogosławioną ścieżką; to udokumentowany endpoint
  używany świadomie. Napisz to w README i jedź dalej.
- **Zdarzenia sięgają 30 dni wstecz.** [Słowa samego Stripe](https://docs.stripe.com/api/events/list):
  *„List events, going back up to 30 days.”* To feed na żywo, nie twoja księga. Twoją księgą są
  Checkout Sessions — a prawdziwą księgą jest dashboard Stripe.
- **Pilnuj limitu odczytów.** Wszyscy patrzą na limit na sekundę
  ([rate limits](https://docs.stripe.com/rate-limits): 100 zapytań/s w trybie live), a nikt na ten
  drugi: Stripe przydziela około **500 zapytań odczytu na transakcję** w oknie 30 dni, z podłogą
  10 000 odczytów miesięcznie. Odpytuj co 4 sekundy, a trzygodzinny set to ~2 700 odczytów. Cztery
  długie koncerty w miesiącu i jesteś na podłodze. Napiwki dokupują ci zapas, gdy przychodzą — ale
  jeśli odpytujesz co sekundę, bo wydawało się żwawiej, znajdziesz sufit. Cztery sekundy to nie
  lenistwo; to *ta* liczba.

Tak to wygląda uczciwie: odpytywanie kosztuje cię parę tysięcy GET-ów i kupuje ci skasowanie całego
backendu.

## Rachunek prowizji, zrobiony porządnie

Platforma reklamująca 0 % nie jest darmowa — i to też nie jest. Własna prowizja Stripe obejmuje każdy
napiwek i Stripe pobiera ją bezpośrednio od ciebie. Dziś, według
[cennika Stripe w euro](https://stripe.com/ie/pricing), standardowa karta z EOG kosztuje
**1,5 % + 0,25 €**. Karty premium z EOG: 1,9 % + 0,25 €; brytyjskie: 2,5 % + 0,25 €; cała reszta:
3,25 % + 0,25 €, plus 2 %, jeśli trzeba przewalutować. (W USA to 2,9 % + 0,30 $, co jest gorsze
dokładnie z poniższego powodu.)

Problemem nie jest procent. Problemem jest dwadzieścia pięć centów.

| Napiwek | Stripe bierze | Artysta zatrzymuje | Efektywna prowizja |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Opłata stała to procent w przebraniu, a przy małych kwotach przebranie się zsuwa. Te same 0,25 €,
niewidoczne przy napiwku 50 €, zjadają jedną ósmą napiwku 2 €. Napiwki są z natury małe — to właśnie
czyni je napiwkami — więc to nie przypadek brzegowy, tylko przypadek typowy.

Właśnie dlatego ustawiasz `custom_unit_amount[minimum]`. Gdzieś w okolicach 2 € transakcja przestaje
mieć sens; kartowy napiwek 0,50 € dotarłby jako 0,24 € i kosztowałby Stripe więcej przy przelewie, niż
jest wart. Wybierz podłogę świadomie, zamiast odkryć ją przy pierwszej wypłacie.

I zauważ, co to robi z porównaniem, od którego zacząłeś. Platforma pobierająca 0 % ponad Stripe pobiera
0 % ponad **to**. Ich 0 % jest prawdziwe — i jest to 0 % z tego, co zostawił procesor. Niczyja szyna
kartowa nie jest darmowa: uczciwe zdanie brzmi „żadnej prowizji ponad prowizję procesora”, a kto twierdzi
więcej, albo kłamie, albo nie używa kart.

## Co teraz masz, a czego nie

Trzy wywołania API i kod QR — i prawdziwy słoik na napiwki: hostowany, zgodny z PCI, Apple Pay, Google
Pay, napiwki lądujące na twoim własnym saldzie Stripe według twojego własnego harmonogramu wypłat, i
żadnego serwera po drodze. Dla wielu osób to naprawdę koniec projektu i możesz spokojnie się tu zatrzymać.

Czego nie masz, to sceny. Masz stronę płatności. Pomiędzy nimi stoją rzeczy nudne: pętla odpytywania z
kursorem i backoffem, ekran, który widzi publiczność, z celem i ostatnią wiadomością, miejsce na klucz,
które nie nazywa się `localStorage`, blokada, żeby obcy nie grzebał w tablecie między setami, oraz warstwa
tysiąca drobnych decyzji o tym, co się dzieje, gdy wi-fi klubu pada w środku setu.

Tym właśnie jest [live.tips](https://github.com/mekedron/live.tips) — dokładnie ta architektura, dokończona,
na licencji MIT. Klucz z ograniczeniami i tymi pięcioma uprawnieniami, pętla kursora na `/v1/events`,
tworzenie Product/Price/Payment Link — wszystko działa na urządzeniu artysty, na jego własnym koncie. W
ścieżce Stripe nie ma serwera live.tips ani nigdzie salda live.tips, o czym pisaliśmy osobno w
[jak live.tips obchodzi się z pieniędzmi](https://live.tips/pl/blog/jak-live-tips-obchodzi-sie-z-pieniedzmi/).

Przeczytaj źródła, weź, co ci potrzebne, albo po prostu tego użyj. Sens tego wpisu jest taki, że architektura
nie jest ani tajemnicą, ani czymś trudnym: **Stripe zahostuje twój słoik na napiwki za darmo, a klucz z
ograniczeniami plus pętla odpytywania to wszystko, co dzieli artystę od jego własnych pieniędzy.** Wolimy,
żebyś to wiedział, niż żebyś się gdziekolwiek rejestrował.
