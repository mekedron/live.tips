---
title: Adatvédelmi tájékoztató
description: A live.tips nem használ sütiket, analitikát és nyomkövetést, és fiók nélkül is működik. Ha úgy döntesz, hogy bejelentkezel, itt pontosan leírjuk, mi tárolódik, hol, ki által és mennyi ideig.
updated: 2026-07-15
updated_label: Utoljára frissítve 2026. július 15-én
---

A live.tips egy nyílt forráskódú borravalós persely előadóknak. **Nikita Rabykin**
üzemelteti, egy magánszemély fejlesztő, nem cég. Ha az alábbiakból bármi fontos neked,
írj a **[contact@live.tips](mailto:contact@live.tips)** címre — ott egy ember olvassa.

Ez a tájékoztató őszinte az unalmas részekkel kapcsolatban is. Inkább mondjuk azt, hogy
„a nevedet addig őrizzük meg, ameddig megtartod a zenekart", mint hogy azt állítsuk, semmit
sem tárolunk, és tévedjünk.

## A rövid változat

- **A fiók opcionális.** Az alkalmazás fiók nélkül is működik, és továbbra is ez az
  alapbeállítás. Ha a zenekaraidat és az előzményeidet egy második készüléken is látni
  akarod, bejelentkezhetsz — és akkor ezek egy része egy szerveren tárolódik, méghozzá több,
  mint korábban. Hogy melyik melyik, azt alább leírjuk.
- **Nincsenek sütik.** Egy sem, sehol.
- **Nincs analitika, nincs nyomkövetés, nincsenek hirdetések, nincsenek harmadik féltől
  származó szkriptek** ezen a weboldalon.
- **A pénzedhez soha nem nyúlunk.** A borravaló egyenesen a rajongótól az előadó saját
  Stripe-, Revolut-, MobilePay- vagy Monzo-fiókjába megy. Nincs live.tips-egyenleg, soha.
- **Fiók nélkül az alkalmazás kizárólag a Stripe-pal kommunikál** — semmilyen
  live.tips-szerverrel. Ha bejelentkezel, ez megváltozik: a Stripe-kulcsod a szerverünkre
  kerül, a Stripe pedig nekünk jelenti a borravalóidat, hogy rátehessük őket a többi
  készülékedre. Ez a bejelentkezés őszinte ára, és alább teljes egészében leírjuk.
- **A push-értesítések újak, opcionálisak, és csak bejelentkezett fiókoknak szólnak.** Semmit
  nem küldünk push formájában olyan készülékre, amely soha nem kapcsolta be őket, egy fiók
  nélküli készülék pedig egyáltalán soha nem kap ilyet.
- Az általunk üzemeltetett szerverek a Google Firebase platformján futnak. Akkor van rájuk
  szükség, ha egy előadó bekapcsolja a Revolutot, a MobilePayt vagy a Monzót — vagy ha
  bejelentkezik.

## Ez a weboldal

Az oldal statikus, és a **GitHub Pages** szolgáltatáson fut. Tárhelyszolgáltatóként a GitHub
megkapja mindenki IP-címét és böngészőjének user-agent adatát, aki betölt egy oldalt — ez a
szokásos webszerver-naplózás, még azelőtt történik, hogy bármelyik kódunk lefutna, és nem
tudjuk kikapcsolni. A GitHub a saját
[adatvédelmi nyilatkozata](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement)
alapján kezeli ezeket. Mi nem olvassuk ezeket a naplókat, és a GitHub nem is mutatja meg őket nekünk.

Ezen túl az oldalak, amiket most olvasol, **senki mástól nem töltenek be semmit**: a betűtípusok,
az ikonok és a képek magáról a live.tips-ről érkeznek. Nincs Google Analytics, nincs tag manager,
nincs pixel, nincs beágyazott widget.

Az oldal **két értéket tárol a böngésződ `localStorage` tárhelyén**, mindkettőt te állítod be,
mindkettőt csak ez az oldal tudja olvasni, és egyiket sem küldjük sehova:

| Kulcs | Mire emlékszik |
| --- | --- |
| `lt-landing-theme` | hogy világos, sötét vagy automatikus színeket választottál |
| `lt-langbar-dismissed` | hogy bezártad az „elérhető a te nyelveden is" sávot |

A böngésző tárhelyének törlésével ezek is eltűnnek. Nem sütik, nem osztjuk meg őket, és senkit
sem azonosítanak.

## Az alkalmazásnak két üzemmódja van, és a különbség maga a lényeg

Minden, ami következik, egyetlen kérdésen múlik: **bejelentkeztél-e?**

### Első mód — nincs fiók. Továbbra is ez az alapértelmezett, továbbra is változatlan.

Az alkalmazás **az előadó saját készülékén fut**, és minden, amit tud, ott él:

- A **Stripe korlátozott kulcsa** a készülék kulcstárában tárolódik (iOS/macOS Keychain,
  Android Keystore), és kizárólag az `api.stripe.com` címre küldjük el.
- A **borravalók előzményei, a munkamenetek előzményei, a cél, a dalkéréslista és az alkalmazás
  beállításai** a készülék helyi tárhelyén tárolódnak. Ide tartoznak azok a nevek és üzenetek is,
  amelyeket a rajongók a borravalójukhoz csatolnak.
- Az alkalmazás eltávolítása mindezt törli. A mi oldalunkon nincs felhőalapú biztonsági mentés,
  mert ebben az üzemmódban a mi oldalunkon nincs felhő.

**Ebből mi soha semmit nem kapunk meg.** Az alkalmazás analitikai SDK, összeomlásjelentő és
hirdetési kód nélkül készül — egyáltalán nincs benne ilyen, még kikapcsolva sem. (A
push-értesítések léteznek, de bejelentkezéshez kötött funkció, és ki vannak kapcsolva, amíg be
nem kapcsolod őket — lásd *Második mód*. Egy fiók nélküli készülék soha nem kap ilyet.)

Két pontosítás, hogy a „senkivel nem kommunikál" állítás pontosan igaz maradjon:

- Az alkalmazás naponta egyszer lekéri a **devizaárfolyamokat** nyilvános árfolyam-API-król
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Ezek egyszerű kérések egy
  nyilvános árfolyamlistáért. Nem hordoznak semmilyen információt rólad, az előadóról vagy
  bármelyik borravalóról — de mint minden webes kérés, felfedik az IP-címedet ezeknek a
  szolgáltatásoknak.
- Ha az alkalmazás **böngészős változatát** használod, a böngésződ a mi statikus tárhelyünkről
  tölti le (lásd fentebb: *Ez a weboldal*).

### Második mód — bejelentkeztél. Ekkor egyes adatok szándékosan elhagyják a készüléket.

A bejelentkezés tudatos döntés. Semmi nem jelentkeztet be helyetted, és az alkalmazásból semmi
nem szűnik meg működni, ha soha nem teszed meg. Azért jelentkezel be, mert egy második
készüléket szeretnél: a zsebedben lévő telefont és a színpadon lévő táblagépet, amelyek ugyanazt
az estét, ugyanazokat a zenekarokat, ugyanazokat az előzményeket mutatják.

Ez csak akkor működik, ha egy szerver őrzi őket. **Így hát őrzi is, és ez a második készülék
őszinte ára.**

A szerver a **Firebase**, vagyis a Google. Háromféleképpen lehet fiókod:

- **Bejelentkezés Apple-lel** vagy **bejelentkezés Google-lel** — a Firebase Auth megkapja
  azt, amit a szolgáltató átad: egy felhasználói azonosítót (uid), és általában egy e-mail-címet
  és egy nevet. (Az Apple-nél elrejtheted az e-mail-címedet; ilyenkor az Apple egy továbbító
  címet ad nekünk helyette, a nevedet pedig csak a legelső bejelentkezéskor adja át.)
- **Vendégfiók** — névtelen fiók e-mail-cím és név nélkül. Szinkronizál, és vissza lehet vonni,
  de semmi sincs, amivel visszaszerezhető lenne, ha elveszíted a készüléket. Ez egy uid, és
  semmi több. Egy vendégfiók nem használhatja a szerveroldali Stripe-kulcsőrzést és az alább
  leírt push-értesítéseket sem, mert mindkettőhöz olyan fiók kell, amelyet vissza tudunk adni
  neked.

Amint bejelentkeztél, a fiók saját, privát sarkot kap a Google **Cloud Firestore**
adatbázisában, a `users/<your uid>/` útvonalon. A biztonsági szabályok ezt a sarkot ehhez az
uid-hez rendelik, **és senki máshoz** — semmilyen másik fiók nem tudja elolvasni, URL-kitalálást
is beleértve. Ami benne van:

| Mi | Miért van ott |
| --- | --- |
| A **zenekaraid** — nevek, a borravalós persely és a fizetési módok beállításai, a plakát szövege, célok és a **dalkéréslistád** | hogy egy zenekar minden készüléken létezzen, amelyen bejelentkezel |
| **Az alkalmazás beállításai**, beleértve az értesítési beállításaidat | hogy egy újonnan hozzáadott készülék már be legyen állítva |
| **Munkamenet-bejegyzések és borravalóelőzmények** — beleértve **azokat a neveket és üzeneteket, amelyeket a rajongók a borravalójukhoz csatolnak**, és bármely **dalt, amelyet egy rajongó kért** | mert pontosan ezt az előzményt akartad látni a másik készüléken |
| Az éppen futó **élő munkamenet** | hogy egy második képernyő is csatlakozhasson a ma esti fellépéshez |
| A **készülékeid** — a név, amit mindegyik ad magának („Nikita iPhone-ja"), a platformja és a modellje, a felület nyelve, mikor láttuk először és utoljára, és (ha bekapcsoltad az értesítéseket) egy **push token** | hogy a Beállítások → Biztonság fel tudja sorolni őket, hogy egy értesítés a megfelelő nyelven a megfelelő készülékre érkezzen, és vissza tudj vonni egyet |
| Egy kis **profildokumentum** — a választott fióknév és az, hogy melyik szolgáltatót használtad | hogy a fiókváltó fel tudja címkézni |
| Egy **értesítési lista** — a közelmúltbeli borravalók és dalkérések felső korláttal ellátott listája, amelyek akkor érkeztek, amikor nem futott fellépés | hogy utólag át tudd nézni, mi maradt le |

És most a lényeg, kertelés nélkül: **fiók nélkül a rajongó neve és üzenete soha nem hagyja el az
előadó készülékét. Fiókkal viszont a Google szerverein tárolódnak, az előadó uid-je alatt, az
adott előadó saját szinkronizált előzményeinek részeként**, és — ahogy a következő két szakasz
elmagyarázza — **immár a mi szerverünk az, ami odaírja őket.** Semmilyen másik fiók nem tudja
elolvasni őket, mi nem nézünk bele, és semmit nem vezetünk le belőlük — de ott vannak, és addig
maradnak ott, ameddig a zenekar, és ezt tudnod kell, mielőtt bejelentkezel.

A kijelentkezés visszateszi a készüléket a helyi üzemmódba. A fiók adatait nem törli — lásd
*Dolgok törlése* alább.

#### A Stripe-kulcsod, amikor bejelentkezel, a szerverünkre kerül

Ez a legnagyobb változás, és a leginkább elolvasásra érdemes.

**Fiók nélkül a Stripe korlátozott kulcsod soha nem hagyja el a készülékedet.** Ez az első mód,
és ez változatlan.

**Amikor bejelentkezel, viszont elhagyja — hozzánk kerül.** A kulcsot titkosítjuk (egy
titkonkénti AES-256 kulccsal, amelyet magát a Google Cloud KMS zár le), és a szerveren olyan
helyen tároljuk, ahol **senki nem tudja visszaolvasni — sem egy másik fiók, sem te magad.**
Csak a Cloud Functions függvényeinken belül nyílik ki, arra használjuk, hogy a nevedben a
Stripe-pal beszéljünk, és soha többé nem adjuk át egyetlen készüléknek sem.

Mivel a kulcs immár nálunk él, **a Stripe közvetlenül a szerverünknek jelenti a borravalóidat**:
regisztrálunk egy webhookot a saját Stripe-fiókodon, és a Stripe minden alkalommal szól ennek a
webhooknak, amikor egy borravalót kifizetnek. A függvényünk beírja a borravalót a fiókod
előzményeibe (lásd lentebb). Az alkalmazásod egy bejelentkezett fiók esetében már nem kérdezi le
folyamatosan a Stripe-ot; a Stripe-ot kizárólag a szerverünkön futó, szűk, rögzített
műveletlistán keresztül éri el (a borravalós linked létrehozása, egy dalkérési link kibocsátása,
és a saját borravalóid visszaolvasása egyeztetés céljából).

Tehát, eufemizmus nélkül kimondva: **egy bejelentkezett fiók esetében immár van egy
live.tips-szerver a Stripe és az előzményeid közötti útvonalban.** A pénzhez továbbra sem nyúlunk
— egy kártyás borravaló a te Stripe-fiókodban jön létre, a te Stripe-egyenlegedre kerül, és a te
Stripe-ütemterved szerint fizetik ki, pontosan úgy, mint korábban. Ami megváltozott, az az *adat*
útvonala, nem a *pénzé*. Ha soha nem jelentkezel be, ebből semmi nem vonatkozik rád, és az
alkalmazás továbbra is egyenesen az `api.stripe.com` címmel és senki mással nem kommunikál.

#### Készülék hozzáadása QR-kóddal

Készülék hozzáadásához egy már bejelentkezett készüléken jeleníted meg a QR-kódot. A kód
véletlenszerű, **egyszer használható, és két perc alatt lejár**, az új készülék pedig semmit
nem kap, amíg a régin rá nem koppintasz a *megerősítés* gombra. Amíg ez a kézfogás nyitva van,
tároljuk a kódot, az új készülék által magának adott nevet és a platformját — és a bejegyzés
törlődik, amikor lejár. Egy lefényképezett QR-kód semmit sem ér a megerősítő koppintásod nélkül.

## Dalkérések

Egy zenekar bekapcsolhatja a **dalkéréseket**: a rajongók ekkor kiválasztanak egy dalt az előadó
listájáról, és opcionálisan fizethetnek azért, hogy feljebb tolják a sorban. A kérés csupán egy
borravaló, amely azt is hordozza, hogy **melyik dalt** kérték — így ugyanaz a név és üzenet,
amelyet egy rajongó a borravalóhoz csatolhat, itt is érvényes, és pontosan úgy tárolódik és
őrződik meg, mint bármely más borravaló (lásd lentebb). A nyilvános sor, amelyet egy rajongó lát,
csak a **dalonkénti összegeket** mutatja — mennyit hozott egy dal, és hol áll —, és **nem
tartalmaz rajongói neveket**. Fiók nélkül az egész dalkéréslista és annak előzményei kizárólag a
készüléken élnek.

## Push-értesítések

Amikor be vagy jelentkezve, az alkalmazás küldhet neked **push-értesítést** — de csak akkor, ha
készülékenként bekapcsolod, és csak azután, hogy a készüléked operációs rendszere engedélyt ad
rá. Egyetlen dologért létezik: egy borravaló vagy egy dalkérés, amely akkor érkezik, **amikor nem
futtatsz fellépést**, hogy értesülj arról a borravalóról, amely különben lemaradt volna. Egy
borravaló, amely akkor érkezik, amikor a színpadod élőben van, semmit nem küld — hiszen már úgyis
nézed.

- A push kézbesítéséhez a Google **Firebase Cloud Messaging (FCM)** szolgáltatásának egy **push
  tokenre** van szüksége a készülékhez. Ezt a tokent és a készülék felületének nyelvét a készülék
  saját bejegyzésén tároljuk a fiókod alatt, és abban a pillanatban töröljük, amint kikapcsolod az
  értesítéseket, visszavonod a készüléket, vagy kijelentkezel. Az elhalt tokeneket automatikusan
  kigyomláljuk.
- Maga az értesítés megmondja, mi érkezett — egy összeget, és egy rajongó nevét vagy egy dal
  címét, ha hagyott ilyet. Ugyanez a rövid lista megmarad a fiókod **értesítési listájában**,
  legfeljebb a legutóbbi száz bejegyzésre korlátozva, hogy visszagörgethesd, mi érkezett, amíg
  távol voltál.
- A weben egy push kézbesítéséhez egy kis **service worker** kell az oldal gyökerében, valamint a
  Firebase üzenetküldő SDK-ja, amelyet a böngésződ első alkalommal a Google-től (`gstatic.com`)
  tölt le. A webes pusht ezután a böngésződ saját push-szolgáltatása szállítja (a Chrome esetében
  ez a Google-é). Ezekből semmi nem töltődik be, hacsak be nem kapcsoltad az értesítéseket.
- **Egy vendégfiók és egy fiók nélküli készülék nem kap pusht**, mert egy pushhoz olyan fiók
  kell, amelynek kézbesíthetünk, és egy token, amelyet te döntöttél úgy, hogy megadsz.

## Hol él mindez fizikailag

A Firebase Auth, a Cloud Firestore, a Cloud Functions függvényeink és az a Cloud KMS-kulcs, amely
a Stripe-titkodat zárja le, mind az **Európai Unióban** futnak — az adatbázis a Google `eur3`
több régióra kiterjedő zónájában, a függvények és a kulcstartó az `europe-west1` régióban. A
Google adatfeldolgozóként jár el a
[Firebase adatvédelmi és biztonsági feltételei](https://firebase.google.com/support/privacy)
és a saját [adatvédelmi tájékoztatója](https://policies.google.com/privacy) alapján. Mint minden
nagy szolgáltató, a Google is bevonhat az EU-n kívüli infrastruktúrát támogatási és biztonsági
célból; ezt azok a feltételek szabályozzák, nem mi. A push-értesítések, amint átadtuk őket a
Firebase Cloud Messagingnek és a böngésződ vagy telefonod push-szolgáltatásának, ezeknek a
cégeknek az infrastruktúráján utaznak, hogy elérjék a készülékedet.

## Stripe

Amikor egy rajongó kártyával fizet, a **Stripe** fizetési oldalán van, nem a miénken. A Stripe
önálló adatkezelőként gyűjti és kezeli a fizetési adatokat a
[Stripe adatvédelmi tájékoztatója](https://stripe.com/privacy) alapján. Mi soha nem látunk
kártyaszámot.

Hogy a borravalóid hogyan jutnak el hozzád, az az üzemmódtól függ:

- **Fiók nélkül** az előadó alkalmazása az előadó saját korlátozott kulcsával olvassa ki a saját
  borravalóit a Stripe-ból — egyenesen a készülékről az `api.stripe.com` címre. **Ebben az
  útvonalban nincs live.tips-szerver.**
- **Bejelentkezve** a kulcs a szerverünkön él (titkosítva, a fentiek szerint), a Stripe pedig
  minden borravalót jelent a webhookunknak, amely beírja azt az adott előadó saját
  Firestore-előzményeibe. **Ebben az üzemmódban van egy live.tips-szerver az útvonalban** — a
  borravaló adataiért, soha nem a pénzért. A rajongó neve és üzenete, ha hagyott ilyet, a
  borravalóval együtt utazik az adott előadó saját előzményeibe, és ott meg is áll.

## A továbbító — csak ha a Revolut, a MobilePay vagy a Monzo be van kapcsolva

A csak Stripe-ot használó beállítások ehhez soha nem érnek hozzá.

A Revolut, a MobilePay és a Monzo semmilyen módot nem kínál arra, hogy egy alkalmazás
megerősítse a fizetés megtörténtét, ezért ezek a borravalók egy kis, nyílt forráskódú
továbbítón haladnak át, amelyet a **Firebase**-en üzemeltetünk — Cloud Functions és Firestore
az `europe-west1` régióban, a rajongó borravalóoldalát pedig a **`tip.live.tips/t/<id>`** címről
szolgáljuk ki. Pénzhez soha nem nyúl. Íme minden, amit kezel.

### Mit tárol az előadó

Egy borravalóoldal létrehozása eltárolja az előadó **megjelenítendő nevét, nyilvános üzenetét,
pénznemét és azokat a fizetési azonosítókat, amelyeket közzé kíván tenni** (a Stripe fizetési
linkjét, a Revolut-felhasználónevét, a MobilePay Box ID-ját, a Monzo-felhasználónevét), és ha a
dalkérések be vannak kapcsolva, **a nyilvános dallistáját és annak dalonkénti árait**. Mindez
olyan információ, amelyet az előadó amúgy is szándékosan tesz közzé a rajongók felé.

- **Megőrzés: az a borravalóoldal, amely mögött nincs fiók, 90 nap inaktivitás után
  automatikusan törlődik.** Az a borravalóoldal, amely egy bejelentkezett fiókhoz tartozik,
  addig él, amíg az a zenekar, amelyhez tartozik.
- Az előadó **azonnal** törölheti az alkalmazásból, bármikor.
- Itt nem gyűjtünk e-mail-címet, jelszót, hivatalos nevet vagy bankszámlaadatot.
- Az oldal titkát **kizárólag hash formájában** tároljuk. Nem tudnánk megmondani neked a titkot,
  ha kérnéd; csak ellenőrizni tudunk egyet.

### Mit küld egy rajongó

A borravalóűrlap **összeget** kér, valamint opcionálisan egy **nevet** és egy **üzenetet** — egy
dalkérés esetében pedig azt, hogy melyik dalt. Ennyi az egész űrlap. Nincs e-mail, nincs
telefonszám, nincs fiók.

Hogy a rajongó által írt szöveg hová kerül, és mennyi ideig, az attól függ, be van-e jelentkezve
az előadó:

- **Ha a borravalóoldal mögött nincs fiók**, a borravaló egy **kézbesítési sorba** kerül —
  egyetlen dokumentum, amely csak azért létezik, hogy átadjuk az előadó képernyőjének. Amikor a
  képernyő megjeleníti a borravalót, **az előadó készüléke törli ezt a dokumentumot.** A törlés
  *maga* a visszaigazolás. Ha az előadó képernyője offline — lezárt telefon, nincs térerő —, a
  borravaló **legfeljebb egy órán át vár ebben a sorban**, hogy ne vesszen el egyszerűen, és abban
  a pillanatban átmegy, amint a képernyő újra csatlakozik. Ha senki nem csatlakozik újra,
  **megtekintés nélkül törlődik**, ütemezetten kisöpörve. Egy fiók nélküli előadónál **ez a sor
  az egyetlen hely, ahol rajongó által írt szöveg valaha is tárolásra kerül a szerverünkön, és
  egy óra ennek a kemény határa.**
- **Ha a borravalóoldal egy bejelentkezett fiókhoz tartozik**, nincs sor. A szerverünk a
  borravalót **egyenesen az adott előadó saját előzményeibe** írja az uid-je alatt — a ma esti
  munkamenetbe, ha éppen fut fellépés, vagy a zenekar saját archívumába, ha nem. Ott **addig
  marad, ameddig a zenekar**; ez az előadó saját előzménye, és éppen ezért jelentkezett be. Ez
  ugyanaz az előzmény, amelybe a fenti Stripe-webhook is ír.
- A neved és az üzeneted bekerül abba a **fizetési megjegyzésbe** is, amely a Revolutban, a
  MobilePayben vagy a Monzóban megnyílik — így tudja meg az előadó, ki adott borravalót. Ezek a
  cégek ezt követően a saját adatvédelmi tájékoztatóik szerint kezelik.
- A továbbító **semmilyen előadókon átívelő borravalóelőzményt nem őriz**. Nem tud sem neked, sem
  nekünk, sem senki másnak listát mutatni arról, ki kinek adott borravalót az előadók között.

### IP-címek és visszaélés elleni védelem

Egy nyílt űrlapnak, amelyre bárki küldhet adatot, szüksége van némi védelemre a botok ellen, ezért:

- Az IP-címedet elküldjük a **Cloudflare Turnstile** szolgáltatásnak — ez egy botellenes
  ellenőrzés, amely a borravalóoldalon fut —, hogy igazolja: nem vagy bot. A Turnstile a
  Cloudflare terméke, és olyan CAPTCHA helyett használjuk, amely profilt építene rólad. A
  Turnstile és a DNS-ünk az egyetlen dolog, amit a Cloudflare még csinál nekünk; maga a továbbító
  már a Firebase-en fut. Lásd a
  [Cloudflare adatvédelmi tájékoztatóját](https://www.cloudflare.com/privacypolicy/).
- Az IP-címedet a kérések **korlátozására** is használjuk — borravaló küldése, borravalóoldal
  létrehozása, készülék-hozzáadási kód beváltása. Amit ehhez tárolunk, az az **IP sózott
  kriptográfiai hash-e**, soha nem maga az IP, körülbelül **két órán át**, majd töröljük. A só egy
  szerveroldali titok: nélküle a kód inkább semmit nem tárol, mint hogy olyan hash-t őrizzen meg,
  amely visszafejthető lenne.
- A **Google üzemeltetési naplói** néhány napig rögzítik a továbbító felé irányuló kérések
  technikai részleteit — URL, időzítés, státusz. A kódunk szándékosan nem naplóz neveket,
  üzeneteket, titkokat és fejléceket. A Google adatfeldolgozóként jár el.

### Számlálók

A továbbító megszámolja, **hány borravalót** továbbított egy adott borravalóoldal, hogy
észrevehessük a visszaéléseket, és megtudjuk, használja-e egyáltalán valaki a dolgot. Ez egy szám.
Semmilyen rajongói adatot nem tartalmaz.

## Ki mit dolgoz fel

| Ki | Mit kap meg | Miért |
| --- | --- | --- |
| **Google (Firebase)** | A fiókok, egy bejelentkezett előadó szinkronizált adatai, a titkosított Stripe-kulcs, a továbbító, a push tokenek és a kézbesítés, a szervernaplók | Az opcionális fiók, az opcionális továbbító és a push-értesítések |
| **Google Cloud KMS** | Az a kulcs, amely egy bejelentkezett előadó Stripe-titkát zárja le (soha nem magát a titkot nyílt formában) | Hogy a tárolt Stripe-kulcs nyugalmi állapotban olvashatatlan maradjon |
| **Stripe** | A rajongó fizetési adatai, önálló adatkezelőként; és egy bejelentkezett előadó esetében a webhookunknak küldött borravaló-események | Kártyás borravalók |
| **Cloudflare** | A rajongó IP-címe, a borravalóoldalon futó Turnstile-ellenőrzéshez. És a DNS-ünk. | Hogy a botok távol maradjanak a borravalóűrlaptól |
| **GitHub** | Bárki IP-címe és user-agentje, aki betölti ezt a weboldalt | A weboldal tárhelye |
| **A böngésződ / telefonod push-szolgáltatása** (pl. a Chrome esetében a Google-é) | Egy push token és az értesítés tartalma, ha bekapcsoltad az értesítéseket | A push-értesítések kézbesítése |
| **Revolut / MobilePay / Monzo** | Bármit, amit a rajongó a saját alkalmazásukban tesz, a fizetési megjegyzéssel együtt | Ezek a fizetési módok |

Senkinek nem adunk el semmit, és nincs más ezen a listán.

## Jogalap, ha kell (GDPR)

- Az általad kért fiók működtetése, a saját adataid szinkronizálása a saját készülékeidre, a
  Stripe-kulcsod őrzése, hogy a borravalóid eljussanak az előzményeidbe, a továbbító üzemeltetése
  egy olyan előadó számára, aki bekapcsolta, a rajongó borravalójának eljuttatása arra a
  képernyőre, amelynek szánták, és egy általad bekapcsolt push elküldése: **az általad kért
  szolgáltatás teljesítése**.
- Kérésszám-korlátozás, Turnstile, hashelt IP-alapú kvóták és készülékek visszavonása: **jogos
  érdek** abban, hogy egy ingyenes, nyílt szolgáltatást ne tegyenek tönkre botok és csalások, és
  hogy az előadók fiókjai biztonságban maradjanak.
- Szervernaplók: **jogos érdek** a szolgáltatás üzemeltetésében és biztonságában.

## Dolgok törlése

Ez többet számít bármilyen ígéretnél, amit tehetnénk róla, ezért itt pontosan az áll, ami ma
létezik — beleértve azt is, ami nem.

- **Nincs fiók**: távolítsd el az alkalmazást. Ennyi volt, minden eltűnt.
- **Egy zenekar**: ha eltávolítasz egy zenekart az alkalmazásban, azzal törlődnek az adott zenekar
  felhőbeli adatai — a beállításai, a kulcsai, a munkamenetei, a borravalóelőzményei — a
  készüléken lévő másolattal együtt.
- **Egy borravalóoldal**: töröld vagy generáld újra az alkalmazásban, és azonnal letörlődik a
  továbbítóról, a függőben lévő borravalókkal együtt.
- **Push-értesítések**: kapcsold ki őket egy készüléken, és a push tokenje törlődik. Az értesítési
  lista a zenekarral vagy a fiókkal együtt ürül ki.
- **Egy készülék**: a Beállítások → Biztonság felsorolja a készülékeidet. Visszavonhatsz egyet,
  vagy kijelentkezhetsz mindenhol máshol — ez azonnal, nem pedig előbb-utóbb megszünteti az
  összes többi készülék munkamenetét.
- **A teljes fiókod, egyetlen koppintással: ez a gomb még nincs meg az alkalmazásban.** Inkább
  bevalljuk, mint hogy az ellenkezőjét állítsuk. Amíg nem létezik, írj a
  **[contact@live.tips](mailto:contact@live.tips)** címre, és kézzel töröljük a fiókot és mindent,
  ami alatta van. Addig is már most törölheted az összes zenekart, amivel minden érdemi tartalom
  eltűnik — beleértve a tárolt Stripe-kulcsot is —, és egy üres fiók marad hátra.

## A jogaid

Kérheted tőlünk, hogy adjunk másolatot mindarról, amit rólad tárolunk, hogy helyesbítsük vagy
töröljük azt, és panasszal élhetsz a nemzeti adatvédelmi hatóságodnál. Írj a
**[contact@live.tips](mailto:contact@live.tips)** címre.

A gyakorlatban ennek nagy része már most is a te kezedben van: az előadó azonnal törölhet egy
borravalóoldalt vagy egy zenekart az alkalmazásból, a kézbesítetlen rajongói borravalók egy órán
belül elpárolognak, és ha soha nem jelentkezel be, ebből semmi nem volt sehol máshol, csak a
saját készülékeden.

## Gyermekek

A live.tips nem gyermekeknek szól, és tudatosan nem kezelünk gyermekekre vonatkozó adatokat.

## Változások

Frissítjük ezt az oldalt, ahogy a szoftver változik. Mivel az egész projekt nyílt forráskódú,
**e tájékoztató minden korábbi változata megtalálható a nyilvános git-előzményekben** — pontosan
összevetheted, mi és mikor változott.

## Nyelv

Ezt a tájékoztatót az oldal által támogatott minden nyelven közzétesszük, a kényelmed érdekében.
Ha egy fordítás és az angol változat eltér egymástól, **az angol változat az irányadó**.
</content>
