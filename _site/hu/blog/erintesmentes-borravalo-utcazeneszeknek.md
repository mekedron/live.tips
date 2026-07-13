# Érintésmentes borravaló utcazenészeknek — őszintén kiszámolva

> Tap to Pay a telefonon, egy kártyaolvasó, egy NFC-matrica, egy QR-kód — négy különböző dolog, amit mind „érintésmentesnek" hívnak. Mennyibe kerül mindegyik valójában 2026-ban, mit csinál egy NFC-tag a valóságban (nem azt, amit gondolsz), és mikor veri az érintés a szkennelést.

Canonical: https://live.tips/hu/blog/erintesmentes-borravalo-utcazeneszeknek/
Published: 2026-07-11
Language: hu
Tags: contactless, NFC, QR codes, Tap to Pay, fees

---

Keress rá az utcazenészeknek szóló érintésmentes borravalóra, és az internet 2018-at
nyújtja át neked. A Brunel University egyik hallgatói prototípusa, a Tiptap — egy
állvány, amibe telefont csúsztatsz — kapott abban az évben egy kör sajtót, és az a
sajtó máig ott ül az első találati oldalon. Szép ötlet volt. És a tudósítások saját
szavaival élve *még mindig fejlesztési fázisban* volt, és úgy tervezte, hogy egyszeri
díjat szed az utcazenészektől, plusz **minden borravaló 5%-át**. Sosem lett belőle
olyasmi, amit meg lehet venni.

(A „tiptap", amit ma találsz, ha nekiállsz keresni, egy nem kapcsolódó ontariói cég,
amely érintésmentes adományterminálokat árul jótékonysági szervezeteknek. Ugyanaz a
szó, más termék, nem neked való.)

Vagyis a dolgok őszinte állását nyolc éve nem írta le senki. Íme.

Ez az érintés mélyfúrása. Ha a valódi kérdésed a tágabb — hogyan jut egyáltalán
pénzhez az utcazenész most, hogy senki nem hord készpénzt, és melyik mód mennyibe
kerül —, akkor kezdd itt: [hogyan fogadnak el kártyát az
utcazenészek](https://live.tips/hu/blog/kartyas-fizetes-utcazeneszeknek/), aztán gyere vissza.

## Négy különböző dolgot hívnak „érintésmentesnek"

Itt lakik a zűrzavar java, úgyhogy válasszuk szét őket, mielőtt bármit is kiszámolnánk.

1. **Tap to Pay a saját telefonodon.** A telefonodból lesz a terminál. A rajongó a
   saját kártyáját vagy óráját érinti a *te* készülékedhez. Semmilyen külön hardver.
2. **Egy kártyaolvasó** — egy SumUp, egy Zettle, egy Square. Egy kis műanyag terminál,
   amit odatartasz. A rajongó hozzáérinti a kártyáját.
3. **Egy NFC-tag** — az „érintsd ide a borravalóhoz" matrica vagy tábla. Ezt szinte
   mindenki félreérti, és a következő szakasz arról szól, miért.
4. **Egy QR-kód.** NFC-értelemben nem érintésmentes — de olvass tovább, mert a rajongó
   felől nézve nagyon gyakran pontosan ugyanabban az érintésben végződik.

Csak az első kettő *fizetési terminál*. Erről a különbségről szól ez az egész írás.

## Az NFC-tag nem fogad be fizetést

Intézzük el ezt rendesen, mert az eladók szívesen hagynak téged tévhitben.

Egy NFC-matricának — az olcsó fajtának, az NTAG213 chipnek, amit a legtöbbjük használ
— **144 bájt memóriája** van. Nem 144 kilobájt. Nem tud kódot futtatni, nincs
akkumulátora, sosem hallott még kártyatársaságról, és egy fizetési protokollt akkor
sem tudna befogadni, ha akarna. Amit befogad, az egy rövid karakterlánc, NDEF-rekord
formájában, és ez a karakterlánc túlnyomó részt egy **URL**.

Hozzáérintesz — és a telefonod megnyit egy weboldalt. Ennyi az egész funkció.

Ami azt jelenti, hogy egy „érintsd meg a borravalóhoz" tábla nem más, mint egy QR-kód,
amit érintéssel nyitsz meg célzás helyett. Ugyanaz a célpont, ugyanaz a weboldal,
ugyanaz a fizetés, ami a böngészőben zajlik. Még a szakosodottak is ezt mondják, ha
figyelmesen olvasod őket: a tiptap a saját oldalán úgy írja le a szabadon választható
összegű eszközét, hogy amikor az adományozók hozzátartják a telefonjukat,
*„átirányítjuk őket az online adománygyűjtő oldaladra."* Átirányítjuk. Egy oldalra.
Mert ennyit tud egy tag.

Ez valóban hasznos, és olcsó is — az üres NTAG213-matricák csomagban körülbelül
**$0,24-tól** indulnak darabonként. Ha már van borravalós oldalad, egy tag a tokodra
ragasztva, a nyomtatott kód mellé, aprópénzbe kerül, és néhány rajongónak gyorsabb
utat ad befelé.

De legyél tisztában azzal, mit vettél: **egy második bejárati ajtót ugyanahhoz az
oldalhoz.** Nem kártyagépet.

### És a szabadban ez egy szeszélyes bejárati ajtó

A hibalehetőségek valósak, és egyetlen tag-árus sem sorolja fel őket:

- **A rajongó telefonjának feloldva és használatban kell lennie.** Az Apple saját
  dokumentációja egyértelmű: a háttérben történő tag-olvasás csak akkor működik, amíg
  az iPhone használatban van, és ha a telefon zárolva van, a rendszer előbb feloldatja.
- **Nem működik, amíg a kamera nyitva van.** Az Apple a használatban lévő kamerát
  kifejezetten azon állapotok közé sorolja, amelyekben a háttérben történő tag-olvasás
  nem elérhető. Ízleld meg az iróniát: a rajongó, aki a kamera után nyúl, hogy
  beszkennelje a QR-kódodat, épp most kapcsolta ki az NFC-tagedet.
- **iPhone XS vagy újabb kell hozzá**, Androidon pedig bekapcsolt NFC — amit néhány
  energiatakarékos mód kikapcsol.
- **A hatótáv nagyjából 4 cm.** A rajongónak tényleg hozzá kell érnie a dologhoz. Egy
  tömegben, egy gitártok fölé hajolva ez komoly kérés.
- **A fém és a mágnes megöli.** Egy erősítőre ragasztott tag, vagy egy rajongó mágneses
  tokkal — és egyszerűen nem történik semmi.

Egy tag remek második lehetőség. Egyetlen lehetőségnek rossz.

## Tap to Pay a telefonon: 2026 igazi híre

Íme, ami a Tiptap-cikkek óta megváltozott, és amiről az elavult tudósítások egyike sem
tud.

**A Tap to Pay iPhone-on** a zsebedben amúgy is ott lévő telefonból érintésmentes
terminált csinál. Nincs dongle, nincs olvasó, nincs állvány. Az Apple **több mint 70
országban és régióban** listázza elérhetőként, és a szolgáltatók, akiken keresztül
Európában használhatod, úgy olvasódnak, mint az egész iparág — egyedül Németországban:
Adyen, Mollie, myPOS, Nexi, PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp,
Viva.com. Nagy-Britanniában, Franciaországban, Hollandiában, Svédországban,
Finnországban és Dániában is hasonló a lista. iPhone XS vagy újabb kell hozzá.

**A Tap to Pay Androidon** szintén létezik, de szűkebb. A Stripe-on keresztül általánosan
elérhető AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG és US
területén, további tizennyolc ország nyilvános előzetesben van. A telefonodnak Android
13 vagy újabb kell, egy NFC-érzékelő, egy nem rootolt bootloader, Google Mobile
Services, és kikapcsolt fejlesztői beállítások — ez utóbbi több embert csíp nyakon,
mint gondolnád.

A gyakorlati változat: **a SumUp £0 hardverrel listázza a Tap to Payt.** Ha van egy
friss iPhone-od, és támogatott országban vagy, akkor annak a belépési költsége, hogy
érintésmentes terminált tarts oda valakinek, most nulla. Már önmagában ez a tény
elavulttá tesz minden 2018-as „vedd meg ezt az állványt" cikket.

## Kártyaolvasók, és hogy valójában mennyibe kerülnek

Ha külön műanyagdarabot akarsz — és van rá jó ok, lásd lent —, a piac három termékből áll.

| | Hardver | Díj személyes érintésenként |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay £0 · Solo Lite £25 · Solo £79 · Terminal £135 | **1,69%**, fix díj nélkül |
| **SumUp** (Németország) | — | **1,39%**, fix díj nélkül |
| **Zettle / PayPal POS** (UK) | Olvasó £29-tól első felhasználónak, utána £69 | **1,75%**, fix díj nélkül |
| **Square** (UK) | Érintéses és chipes olvasó £19 | **1,75%**, fix díj nélkül |
| **Square** (US) | Érintéses és chipes olvasó $59 | **2,6% + $0,15** |

Az árak áfa nélkül értendők, 2026 júliusában közzétett állapot szerint. Menj, és
ellenőrizd őket; mozognak.

Most pedig olvasd el újra azt a táblázatot, mert olyat mond, ami ellentmond annak,
amit valószínűleg mondtak neked.

## A díjszámtan, és amit mindenki fordítva tud

A bevett bölcsesség szerint a kártyadíjak azért nyírják ki a kis borravalókat, mert
van egy fix, tranzakciónkénti díj — az a huszonöt cent, ami egy €2-es borravaló
nyolcadát megeszi. Ez igaz, és
[magunk is kiírtuk a számokat](https://live.tips/hu/blog/epits-borravalos-perselyt-a-sajat-stripe-fiokodon/).

De ez az *online* kártyás fizetésekre igaz. **Az európai érintésmentes olvasóknak
többnyire egyáltalán nincs fix díjuk.** A SumUp, a Zettle és a Square az Egyesült
Királyságban és az EU-ban csak százalékot számol. Ami azt jelenti:

| Egy €2-es borravaló | Díj | A művésznek marad | Tényleges levonás |
| --- | --- | --- | --- |
| SumUp-olvasó (DE, 1,39%) | €0,03 | €1,97 | **1,4%** |
| Zettle / Square (UK, 1,75%) | €0,04 | €1,96 | 1,8% |
| Stripe, online kártya (EGT, 1,5% + €0,25) | €0,28 | €1,72 | **14,0%** |
| Square-olvasó (US, 2,6% + $0,15) | $0,20 | $1,80 | **10,1%** |

Pusztán a díjat nézve egy európai érintéses terminál kis borravalónál veri az online
kártyás fizetést, és nem is szorosan. QR-kódos termék vagyunk, és mégis ezt mondjuk
neked: egy €2-es borravalónál a SumUp-olvasó €0,25-öt hagy nálad, amit egy Stripe által
hosztolt oldal nem.

Két dolog teszi ezt arányba vissza.

**A hardver maga a fix díj, csak arrébb tolva.** Egy €0,25-ös megtakarítás borravalónként
egy £79-es Solóval szemben nagyjából **háromszáz érintést** jelent, mire az olvasó
kitermeli magát. Ez egy dolgozó utcazenésznek valós szám, valakinek pedig, aki nyaranta
kétszer játszik, nevetséges. (És a SumUp £0-s Tap to Payje nullára viszi le az
érintéseket — pontosan ezért számít ez a lehetőség többet, mint maguk az olvasók.)

**Az Egyesült Államok pedig visszabillenti.** A Square amerikai személyes tarifája
$0,15 fix díjat visz magával, tehát egy $2-es érintés a terminálon is elveszíti a
tizedét. A „nincs fix díj" ajándék európai.

Van egy alsó küszöb is, amivel találkozni fogsz: a SumUp nem fogad el **£1 / €1** alatti
fizetést. Bármelyik sínt is választod, a nagyon kicsi borravaló igazából nem kártyás
tranzakció.

## Tehát mikor veri az érintés a szkennelést?

Vedd le róla a technológiát, és ez egy kérdés a rajongó kezeiről.

**Az érintéshez az kell, hogy a rajongó telefonja feloldva a kezében legyen, és hogy te
odatarts valamit.** Amikor mindkettő igaz, ez a leggyorsabb dolog a fizetésben. Nincs
app, nincs célzás, nincs gépelés, egy másodperc alatt kész.

**A szkenneléshez az kell, hogy a rajongó kinyissa a kamerát** — egy plusz szándékos
mozdulat —, de tőled semmit sem kér. A kód ott ül a tokon. Működik a hátul álló
rajongónál. Működik negyven embernél egyszerre. Működik, miközben te még játszol.

Amiből egy őszinte felosztás következik:

- **Az érintés nyer, amikor oda tudsz menni az emberekhez.** A szett vége, körbemegy a
  kalap, egyszerre egy rajongó, te szabadon tarthatsz egy terminált. Az érintés kisebb
  kérés, mint az, hogy „vedd elő a kamerádat", és abban a pillanatban fizikailag ott
  vagy, hogy lezárd.
- **A szkennelés nyer, amikor nem tudsz.** Dal közben. Háromsoros tömegnél. Egy helyen,
  ahonnan nem tudsz elmozdulni az erősítőtől. Bárkinél, aki elhaladtában akar adni. Egy
  terminál pontosan egy embert szolgál ki; egy kinyomtatott kód az egész teret
  egyszerre, és nem kell hozzá abbahagynod a játékot.

Ez az utolsó pont az, amit a terminálárusok soha nem hoznak fel, és ez a legnagyobb. **Egy
kártyaolvasó egy szűk keresztmetszet, sorral.** Egy QR-kódnak nincs sora.

És itt jön az a rész, ami feloldja a vita felét: egy jól megépített borravalós oldalon
**a szkennelés úgyis érintéssel végződik**. A rajongó szkennel, az oldal megnyílik, és
a telefonja felkínálja az Apple Payt vagy a Google Payt. Dupla kattintás, arcához
tartja a telefont, kész. A rajongó felől nézve ez érintésmentes fizetés — ugyanaz a
tárca, ugyanaz a kártya, ugyanaz a két másodperc —, és te nem vettél hozzá semmilyen
hardvert.

## Hol áll a live.tips, és mikor vegyél inkább SumUpot

A [live.tips](https://github.com/mekedron/live.tips) egy QR-alapú borravalós persely.
Egy kód, ami sosem változik, és ami egyenesen a művész saját Stripe-fizetési linkjére
mutat. Nincs live.tips-egyenleg, nincs részesedés, és nincs platform az útban — a díj
a Stripe sajátja, és a Stripe közvetlenül a művésznek számítja fel. MIT-licenc alatt
van, a színpadi tablet pedig minden borravalót megmutat abban a pillanatban, ahogy
megérkezik. A pénz útját megírtuk itt:
[hogyan bánik a pénzzel a live.tips](https://live.tips/hu/blog/hogyan-banik-a-live-tips-a-penzzel/), és azt is, miért
[egy kód, nem pedig szolgáltatónként egy](https://live.tips/hu/blog/egy-qr-kod-minden-fizetesi-mod/).

Ez az oldal támogatja az Apple Payt és a Google Payt. Tehát a live.tips a rajongó felől
nézve *igenis* érintésmentes — abban az érintésben, ami számít, a legutolsóban, anélkül
hogy terminált kellene venni, tölteni vagy elejteni az esőben. Csak épp nem terminál.

**Ha az kell neked, hogy fizikailag odatarts valamit, és egy idegen hozzáérintse, vegyél
kártyaolvasót.** Válaszd a SumUp Tap to Payjét, ha a telefonod és az országod bírja,
mert nem kerül semmibe; válassz egy Solót, ha inkább nem adnád a saját telefonodat egy
tömeg kezébe. Így is, úgy is: egy €2-es érintésnél Európában megveri a mi díjunkat, és
ezt inkább kimondjuk, mint hogy úgy tegyünk, mintha nem így lenne.

Csinálhatod mindkettőt is, és sok utcazenésznek meg is kéne: a kód a tokra ragasztva
egész este, elkapva a járókelőket, miközben játszol — és a terminál a kezedben arra a
tíz másodpercre az utolsó akkord után, amikor az első sor a zsebébe nyúl. Nem
versenyeznek egymással. Más embereket kapnak el.

Amik viszont egyikük sem: egy 2018-as állvány, ami 5%-ot vesz el.

A díjak, a hardverárak és az országos elérhetőség az Apple, a Stripe, a SumUp, a Zettle/PayPal és a Square által 2026 júliusában közzétett formában, áfa nélkül. Az NFC-matricák ára a GoToTags alapján. A Tiptap 2018-as feltételei a Brunel University és a Finextra beszámolói szerint. Itt minden változik; ellenőrizd a szolgáltatónál, mielőtt pénzt költenél.
{: .footnote }
