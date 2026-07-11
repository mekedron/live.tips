---
title: Építs borravalós perselyt a saját Stripe-fiókodon
description: Három API-hívás, és kapsz egy hosztolt, „fizess, amennyit akarsz” oldalt Apple Pay-jel és Google Pay-jel — szerver nélkül. Itt a teljes építés: a korlátozott kulcs, a jogosultságok, hogyan olvasod vissza a borravalókat webhook nélkül, és a díjszámítás, amit senki sem nyomtat ki.
slug: epits-borravalos-perselyt-a-sajat-stripe-fiokodon
---

Borravalós perselyt akarsz. Nem akarsz egy platformnak odaadni 5 %-ot egy utcazenész
estéjéből, és tökéletesen elboldogulsz egy API-val. A kérdés tehát nem az, hogy *melyik
perselyre iratkozzam fel*, hanem az, hogy *mennyit kell tényleg megépítenem*.

Kevesebbet, mint hinnéd. Stripe-on a működő válasz három API-hívás: nincs szerver, nincs
backend, nincs webhook-végpont. A cikk többi része pontosan ez az építés — plusz az a két
dolog, amit mindenki elront.

## A trükk egy „fizess, amennyit akarsz” Price

A Stripe-nak van egy árazási módja, ahol a rajongó írja be az összeget. Úgy hívják:
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) — és ez az
egész funkció. Létrehozol egy Productot, akasztasz rá egy Price-t
`custom_unit_amount[enabled]=true` beállítással, arra pedig egy
[Payment Linket](https://docs.stripe.com/payment-links/create).

```sh
# 1. a dolog, amit "árulsz"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. az ár, amit a rajongó választ
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. az oldal
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

A harmadik hívás visszaad egy `url`-t. Ez az URL *maga* a borravalós perselyed. Stripe által
hosztolt oldal, tehát PCI-kompatibilis anélkül, hogy gondolkodnod kellene rajta, lokalizált,
és minden rajongónak megmutatja az Apple Payt vagy a Google Payt, akinek a telefonján be van
állítva — a
[dinamikus fizetési módok](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
ezt eldöntik helyetted eszköz és ország alapján. Egy sor frontendet sem írtál.

Kódold az URL-t QR-kódba bármelyik könyvtárral — csak egy sztring —, nyomtasd ki, ragaszd a
tokra. A kód sosem jár le, és nem mutat semmilyen szerveredre, mert nincs is olyanod.

Két paraméter, amit érdemes ismerni:

- **`custom_unit_amount[preset]`** az az összeg, amivel az oldal nyit. `500` azt jelenti, hogy a
  rajongó már beírva látja az 5,00 €-t, és átírhatja. Ez a szám többet tesz az átlagos
  borravalódért, mint bármi más az oldalon.
- **`custom_unit_amount[minimum]`** egy padló. Állítsd be. Hogy miért, az a díjakról szóló
  szakaszban áll, és nem kerekítési hiba.

Nevet és üzenetet is gyűjthetsz. A Payment Link legfeljebb három `custom_fields`-et fogad — így
jutsz hozzá a „na de kitől volt?”-hoz anélkül, hogy űrlapot építenél:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="A neved vagy beceneved" \
  -d "custom_fields[0][optional]"=true
```

A Stripe-nak vannak [követelményei a borravaló és az adomány elfogadására](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
olvasd el egyszer. A „fizess, amennyit akarsz” ráadásul nem kombinálható más line itemekkel,
kedvezményekkel vagy ismétlődő fizetésekkel. Egy borravalós perselynél ezek egyike sem fáj.

Ezt a különbséget érdemes eltalálni. A Stripe így fogalmaz: a borravalót egy már nyújtott
áruért vagy szolgáltatásért adják, míg az adománynak jótékony célhoz kell kötődnie.
Lejátszottad a szettet; a borravaló ezt fizeti meg. Ezért küld a fenti hívás is
`submit_type=pay`-t és nem `donate`-et — a `donate` a `donate.stripe.com`-ra tenné a
linkedet, és *Adományozás*-t nyomtatna a gombra. Ez másik szakma, és olyan, amelyet a
Stripe sokkal szigorúbban vizsgál.

## A kulcs: számíts rá, hogy kiszivárog — és tedd unalmassá

Ne tegyél titkos kulcsot (`sk_live_…`) olyan eszközre, ami egy színpadon áll. Használj
[korlátozott kulcsot](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`):
erőforrásonként választasz jogosultságot, és minden, amit nem választottál, **None** marad.

A fenti építéshez a teljes lista öt sor:

| Erőforrás | Jogosultság | Mire jó |
| --- | --- | --- |
| Products | Write | a Product létrehozása |
| Prices | Write | a „fizess, amennyit akarsz” Price létrehozása |
| Payment Links | Write | a link létrehozása |
| Checkout Sessions | Read | a beérkezett borravalók megtekintése |
| Events | Read | az élő feed (következő szakasz) |

Minden más — Balance, Payouts, Refunds, Customers, PaymentIntents, az egész Connect — **None**-on
marad.

Most pedig végezd el azt a gyakorlatot, amitől ez az egész értelmet nyer. Hajnali egykor lenyúlják
a tabletedet a merch-asztalról. Mit tud kezdeni a tolvaj a kulcstartóban lévő kulccsal? Elolvassa a
borravaló-előzményeidet, és létrehoz még pár borravalós linket a fiókodban. Ennyi az egész
robbanási sugár. Nem látja az egyenlegedet, nem indíthat kifizetést, nem küldhet visszatérítést egy
általa birtokolt kártyára, nem olvashat ügyféllistát. Visszavonod a kulcsot a hazafelé tartó taxiban
a telefonodról, és az eszköz elsötétül. A pénzedből semmi nem mozdult.

Ez az aszimmetria — írási jog a perselyhez, nulla hozzáférés a pénzhez — az egyetlen oka annak, hogy
egy szerver nélküli, hozd-a-saját-kulcsod felépítés egyáltalán védhető. És ezért nem a „Login with
Stripe” a válasz: az OAuth-hoz kell egy szerver az alkalmazás fejlesztőjétől, ami a tokenedet tartja
— a szerver pedig pontosan az, amit nem építünk.

(Egy furcsaság, amibe bele fogsz botlani: a *Prices* jogosultság belső neve `plan_write`, így a Stripe
hibaüzenete olyan scope-ot nevez meg, ami a dashboardon nem szerepel ezen a néven. A Prices az.)

## Borravalók visszaolvasása webhook nélkül

Itt a legtöbb leírás vagy megáll, vagy webhookért nyúl — és itt tér el egy színpad tényleg egy
webalkalmazástól.

A webhook egy bejövő HTTP-kérés. Egy mikrofonállvány mögötti tablet nem tud ilyet fogadni. Egy helyszín
vendég-wifijén ül NAT mögött, nincs publikus címe, nincs TLS-tanúsítványa — és semmi dolga sincs ezekkel.
Ha a webhook útját választod, fel kell húznod egy szervert, ami elkapja az eseményeket, és egy socketet,
ami áttolja őket az eszközre: ez backend, üzemeltetési teher, és egy hely, ahol mostantól a rajongóid nevei
laknak. Épp most építetted újra azt a platformot, amit el akartál kerülni.

Szóval húzz ahelyett, hogy tolatnál. A Stripe
[List all events](https://docs.stripe.com/api/events/list) végpontja nyilvános, dokumentált, és a
legfrissebbtől adja vissza az eseményeket:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_UTOLSO_LATOTT \
  -d limit=100
```

Az `ending_before` maga a teljes tervezés. Tartsd meg a legutóbb feldolgozott esemény id-jét; minden
lekérdezés mindent kér, ami szigorúan újabb, te pedig léptetsz a kurzoron. Nincsenek időbélyegek, nincs
óraeltolódás, nincs összeg szerinti duplikátumszűrés. Egy szett első lekérdezésénél kérj `limit=1`-et kurzor
nélkül, hogy lehorgonyozz ahhoz, ami már ott van — különben a hangpróbán újrajátszod a mai reggeli
borravalókat.

Aztán szűrd, ami visszajön. Mindkét eseménytípus elsülhet egyetlen fizetésre, tehát a Checkout Session id-je
alapján szűrd a duplikátumokat. Ellenőrizd, hogy `payment_status == "paid"` — egy befejezett munkamenet nem
feltétlenül fizetett. És ellenőrizd, hogy a `payment_link` a *te* linkedre illeszkedik, mert a `/v1/events`
fiókszintű, és készséggel átnyújtja neked mindazt a forgalmat, amit az a Stripe-fiók egyébként csinál.

Légy őszinte a kompromisszumokkal, mert valósak:

- **A Stripe a webhookokat ajánlja.** A pollozás nem az áldott út; egy dokumentált végpont szándékos
  használata. Írd le a README-be, és menj tovább.
- **Az események 30 napra nyúlnak vissza.** [A Stripe szavaival](https://docs.stripe.com/api/events/list):
  *„List events, going back up to 30 days.”* Ez élő feed, nem főkönyv. A főkönyved a Checkout Sessions — az
  igazi pedig a Stripe dashboard.
- **Figyelj az olvasási keretre.** Mindenki a másodpercenkénti korlátot nézi
  ([rate limits](https://docs.stripe.com/rate-limits): 100 kérés/mp élesben), és senki a másikat: a Stripe
  nagyjából **500 olvasási kérést oszt ki tranzakciónként** gördülő 30 napon, 10 000 olvasás/hó padlóval.
  Pollozz 4 másodpercenként, és egy háromórás szett ~2 700 olvasás. Négy hosszú koncert egy hónapban, és a
  padlón vagy. A borravalók vásárolnak neked mozgásteret, ahogy érkeznek — de aki másodpercenként pollozik,
  mert úgy fürgébbnek tűnt, meg fogja találni a plafont. A négy másodperc nem lustaság: *ez* a szám.

Így néz ki őszintén: a pollozás pár ezer GET-be kerül, és cserébe megspórol egy teljes backendet.

## A díjszámítás, rendesen elvégezve

Egy 0 %-ot hirdető platform nem ingyenes — és ez sem az. A Stripe saját feldolgozási díja minden borravalóra
vonatkozik, és a Stripe közvetlenül neked számlázza. Ma a [Stripe euróárai](https://stripe.com/ie/pricing)
szerint egy szabványos EGT-kártya **1,5 % + 0,25 €**. A prémium EGT-kártyák 1,9 % + 0,25 €, a britek 2,5 % +
0,25 €, minden más 3,25 % + 0,25 €, plusz további 2 %, ha valutaváltás kell. (Az USA-ban 2,9 % + 0,30 $, ami
pontosan az alábbi ok miatt rosszabb.)

Nem a százalék a baj. A huszonöt cent a baj.

| Borravaló | A Stripe elviszi | Az előadóé marad | Tényleges levonás |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

A fix díj álruhás százalék, és kis pénznél lecsúszik az álruha. Ugyanaz a 0,25 €, ami láthatatlan egy 50 eurós
borravalón, megeszi egy 2 eurósnak a nyolcadát. A borravaló természeténél fogva kicsi — ettől borravaló —, tehát
ez nem szélsőséges eset, hanem a tipikus.

Épp ezért állítod be a `custom_unit_amount[minimum]`-ot. Valahol 2 € körül a tranzakció megszűnik megérni; egy
0,50 eurós kártyás borravaló 0,24 €-ként érkezne, és a Stripe-nak többe kerülne mozgatni, mint amennyit ér. Válaszd
meg tudatosan a padlót, ahelyett hogy az első kifizetésnél fedeznéd fel.

És figyeld meg, mit tesz ez azzal az összehasonlítással, amivel indultál. Egy platform, amely 0 %-ot szed a Stripe
fölött, **erre** szed 0 %-ot. A 0 %-uk valódi — és a feldolgozó által meghagyott összegnek a 0 %-a. Senki kártyás
sínje nem ingyenes: az őszinte állítás az, hogy „a feldolgozóén túl semmilyen levonás”, és aki többet állít, az
vagy hazudik, vagy nem kártyát használ.

## Mid van most, és mid nincs

Három API-hívás és egy QR-kód — és egy igazi borravalós persely: hosztolt, PCI-kompatibilis, Apple Pay, Google Pay,
a borravalók a saját Stripe-egyenlegeden landolnak a saját kifizetési ütemterved szerint, és nincs szerver az
útvonalon. Sokaknak ez őszintén a projekt vége, és nyugodtan megállhatsz itt, és kiadhatod.

Ami nincs, az egy színpad. Egy fizetőoldalad van. A kettő közt ott állnak az unalmas dolgok: a pollozó ciklus a
kurzorával és a backoffjával; egy képernyő, amit a közönség lát, rajta a céllal és az utolsó üzenettel; egy hely a
kulcsnak, aminek nem `localStorage` a neve; egy zár, hogy idegen ne piszkálja a tabletet a szettek között; és az
ezer-apró-döntés réteg arról, mi történik, ha a helyszín wifije szett közben elszáll.

Pontosan ez a [live.tips](https://github.com/mekedron/live.tips) — ez az architektúra, befejezve, MIT-licenc alatt.
A korlátozott kulcs azzal az öt jogosultsággal, a `/v1/events` kurzoros ciklus, a Product/Price/Payment Link
létrehozása — mind az előadó eszközén fut, az ő saját fiókja ellen. A Stripe útvonalán nincs live.tips szerver, és
sehol nincs live.tips egyenleg — erről külön írtunk:
[hogyan bánik a live.tips a pénzzel](post:how-live-tips-handles-money).

Olvasd el a forrást, emeld ki, amire szükséged van, vagy egyszerűen használd. Ennek a cikknek az a lényege, hogy az
architektúra se nem titok, se nem nehéz: **a Stripe ingyen hosztolja a borravalós perselyedet, és egy korlátozott
kulcs plusz egy pollozó ciklus minden, ami az előadó és a saját pénze között áll.** Jobban örülünk, ha ezt tudod,
mint ha feliratkozol bárhová.
