---
title: Adatvédelmi tájékoztató
description: A live.tips nem használ sütiket, analitikát és nyomkövetést, és fiók nélkül is működik. Ha úgy döntesz, hogy bejelentkezel, itt pontosan leírjuk, mi tárolódik, hol, ki által és mennyi ideig.
updated: 2026-07-13
updated_label: Utoljára frissítve 2026. július 13-án
---

A live.tips egy nyílt forráskódú borravalós persely előadóknak. **Nikita Rabykin**
üzemelteti, egy magánszemély fejlesztő, nem cég. Ha az alábbiakból bármi fontos neked,
írj a **[contact@live.tips](mailto:contact@live.tips)** címre — ott egy ember olvassa.

Ez a tájékoztató őszinte az unalmas részekkel kapcsolatban is. Inkább mondjuk azt, hogy
„a nevedet legfeljebb egy órán át megőrizzük”, mint hogy azt állítsuk, semmit sem tárolunk,
és tévedjünk.

## A rövid változat

- **A fiók opcionális.** Az alkalmazás fiók nélkül is működik, és továbbra is ez az
  alapbeállítás. Ha a zenekaraidat és az előzményeidet egy második készüléken is látni
  akarod, bejelentkezhetsz — és akkor ezek egy része egy szerveren tárolódik. Hogy melyik
  melyik, azt alább leírjuk.
- **Nincsenek sütik.** Egy sem, sehol.
- **Nincs analitika, nincs nyomkövetés, nincsenek hirdetések, nincsenek harmadik féltől
  származó szkriptek** ezen a weboldalon.
- **A pénzedhez soha nem nyúlunk.** A borravaló egyenesen a rajongótól az előadó saját
  Stripe-, Revolut-, MobilePay- vagy Monzo-fiókjába megy. Mi nem vagyunk ebben az útvonalban.
- **Az alapbeállítás szerint az alkalmazás kizárólag a Stripe-pal kommunikál** — semmilyen
  live.tips-szerverrel.
- Az egyetlen szerver, amit egyáltalán üzemeltetünk, egy kis továbbító a Google Firebase
  platformján. Csak akkor van rá szükség, ha egy előadó bekapcsolja a Revolutot, a
  MobilePayt vagy a Monzót — vagy ha bejelentkezik.

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
| `lt-langbar-dismissed` | hogy bezártad az „elérhető a te nyelveden is” sávot |

A böngésző tárhelyének törlésével ezek is eltűnnek. Nem sütik, nem osztjuk meg őket, és senkit
sem azonosítanak.

## Az alkalmazásnak két üzemmódja van, és a különbség maga a lényeg

Minden, ami következik, egyetlen kérdésen múlik: **bejelentkeztél-e?**

### Első mód — nincs fiók. Továbbra is ez az alapértelmezett, továbbra is változatlan.

Az alkalmazás **az előadó saját készülékén fut**, és minden, amit tud, ott él:

- A **Stripe korlátozott kulcsa** a készülék kulcstárában tárolódik (iOS/macOS Keychain,
  Android Keystore), és kizárólag az `api.stripe.com` címre küldjük el.
- A **borravalók előzményei, a munkamenetek előzményei, a cél és az alkalmazás beállításai**
  a készülék helyi tárhelyén tárolódnak. Ide tartoznak azok a nevek és üzenetek is, amelyeket
  a rajongók a borravalójukhoz csatolnak.
- Az alkalmazás eltávolítása mindezt törli. A mi oldalunkon nincs felhőalapú biztonsági mentés,
  mert ebben az üzemmódban a mi oldalunkon nincs felhő.

**Ebből mi soha semmit nem kapunk meg.** Az alkalmazás analitikai SDK, összeomlásjelentő,
push-értesítés és hirdetési kód nélkül készül — egyáltalán nincs benne ilyen, még kikapcsolva sem.

Két pontosítás, hogy a „senkivel nem kommunikál” állítás pontosan igaz maradjon:

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
  címet ad nekünk helyette.)
- **Vendégfiók** — névtelen fiók e-mail-cím és név nélkül. Szinkronizál, és vissza lehet vonni,
  de semmi sincs, amivel visszaszerezhető lenne, ha elveszíted a készüléket. Ez egy uid, és
  semmi több.

Amint bejelentkeztél, a fiók saját, privát sarkot kap a Google **Cloud Firestore**
adatbázisában, a `users/<your uid>/` útvonalon. A biztonsági szabályok ezt a sarkot ehhez az
uid-hez rendelik, **és senki máshoz** — semmilyen másik fiók nem tudja elolvasni, URL-kitalálást
is beleértve. Ami benne van:

| Mi | Miért van ott |
| --- | --- |
| A **zenekaraid** — nevek, a borravalós persely és a fizetési módok beállításai, a plakát szövege, célok | hogy egy zenekar minden készüléken létezzen, amelyen bejelentkezel |
| A **Stripe korlátozott kulcsod** és a továbbító borravalóoldalának titka | egy titkokat tartalmazó dokumentumban, amelyet csak a te uid-ed olvashat, és gyorsítótárazva minden készüléked kulcstárában |
| **Az alkalmazás beállításai** | hogy egy újonnan hozzáadott készülék már be legyen állítva |
| **Munkamenet-bejegyzések és borravalóelőzmények** — beleértve **azokat a neveket és üzeneteket, amelyeket a rajongók a borravalójukhoz csatolnak** | mert pontosan ezt az előzményt akartad látni a másik készüléken |
| Az éppen futó **élő munkamenet** | hogy egy második képernyő is csatlakozhasson a ma esti fellépéshez |
| A **készülékeid** — a név, amit mindegyik ad magának („Nikita iPhone-ja”), a platformja és a modellje, mikor láttuk először és utoljára | hogy a Beállítások → Biztonság fel tudja sorolni őket, és vissza tudj vonni egyet |
| Egy kis **profildokumentum** — a választott fióknév és az, hogy melyik szolgáltatót használtad | hogy a fiókváltó fel tudja címkézni |

És most a lényeg, kertelés nélkül: **fiók nélkül a rajongó neve és üzenete soha nem hagyja el az
előadó készülékét. Fiókkal viszont a Google szerverein tárolódnak, az előadó uid-je alatt, az
adott előadó saját szinkronizált előzményeinek részeként.** Semmilyen másik fiók nem tudja
elolvasni őket, mi nem nézünk bele, és semmit nem vezetünk le belőlük — de ott vannak, és ezt
tudnod kell, mielőtt bejelentkezel.

A kijelentkezés visszateszi a készüléket a helyi üzemmódba. A fiók adatait nem törli — lásd
*Dolgok törlése* alább.

### Készülék hozzáadása QR-kóddal

Készülék hozzáadásához egy már bejelentkezett készüléken jeleníted meg a QR-kódot. A kód
véletlenszerű, **egyszer használható, és két perc alatt lejár**, az új készülék pedig semmit
nem kap, amíg a régin rá nem koppintasz a *megerősítés* gombra. Amíg ez a kézfogás nyitva van,
tároljuk a kódot, az új készülék által magának adott nevet és a platformját — és a bejegyzés
törlődik, amikor lejár. Egy lefényképezett QR-kód semmit sem ér a megerősítő koppintásod nélkül.

## Hol él mindez fizikailag

A Firebase Auth, a Cloud Firestore és a Cloud Functions függvényeink az **Európai Unióban**
futnak — az adatbázis a Google `eur3` több régióra kiterjedő zónájában, a függvények az
`europe-west1` régióban. A Google adatfeldolgozóként jár el a
[Firebase adatvédelmi és biztonsági feltételei](https://firebase.google.com/support/privacy)
és a saját [adatvédelmi tájékoztatója](https://policies.google.com/privacy) alapján. Mint minden
nagy szolgáltató, a Google is bevonhat az EU-n kívüli infrastruktúrát támogatási és biztonsági
célból; ezt azok a feltételek szabályozzák, nem mi.

## Stripe

Amikor egy rajongó kártyával fizet, a **Stripe** fizetési oldalán van, nem a miénken. A Stripe
önálló adatkezelőként gyűjti és kezeli a fizetési adatokat a
[Stripe adatvédelmi tájékoztatója](https://stripe.com/privacy) alapján. Mi soha nem látunk
kártyaszámot, és nincs hozzáférésünk az előadó Stripe-fiókjához.

Az előadó alkalmazása az előadó saját korlátozott kulcsával olvassa ki a saját borravalóit a
Stripe-ból — egyenesen a készülékről az `api.stripe.com` címre. **Ebben az útvonalban nincs
live.tips-szerver, és soha nem is volt.** A rajongó neve és üzenete, ha hagyott ilyet, a
Stripe-tól az előadó készülékére utazik, és ott meg is áll — hacsak az előadó nem jelentkezett
be, mert akkor a készülék el is menti őket az adott előadó saját Firestore-előzményei közé, a
fentiek szerint.

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
linkjét, a Revolut-felhasználónevét, a MobilePay Box ID-ját, a Monzo-felhasználónevét). Mindez
olyan információ, amelyet az előadó amúgy is szándékosan tesz közzé a rajongók felé.

- **Megőrzés: az a borravalóoldal, amely mögött nincs fiók, 90 nap inaktivitás után
  automatikusan törlődik.** Az a borravalóoldal, amely egy bejelentkezett fiókhoz tartozik,
  addig él, amíg az a zenekar, amelyhez tartozik.
- Az előadó **azonnal** törölheti az alkalmazásból, bármikor.
- Itt nem gyűjtünk e-mail-címet, jelszót, hivatalos nevet vagy bankszámlaadatot.
- Az oldal titkát **kizárólag hash formájában** tároljuk. Nem tudnánk megmondani neked a titkot,
  ha kérnéd; csak ellenőrizni tudunk egyet.

### Mit küld egy rajongó

A borravalóűrlap **összeget** kér, valamint opcionálisan egy **nevet** és egy **üzenetet**.
Ennyi az egész űrlap. Nincs e-mail, nincs telefonszám, nincs fiók.

- A borravaló egy **kézbesítési sorba** kerül — egyetlen dokumentum, amely csak azért létezik,
  hogy átadjuk az előadó képernyőjének. Amikor a képernyő megjeleníti a borravalót, **az előadó
  készüléke törli ezt a dokumentumot.** A törlés *maga* a visszaigazolás; nincs „kézbesítve”
  jelölő, mert nem marad rekord, amit meg lehetne jelölni.
- Ha az előadó képernyője offline — lezárt telefon, nincs térerő —, a borravaló **legfeljebb egy
  órán át vár ebben a sorban**, hogy ne vesszen el egyszerűen, és abban a pillanatban átmegy,
  amint a képernyő újra csatlakozik. Ha senki nem csatlakozik újra, **megtekintés nélkül
  törlődik**, ütemezetten kisöpörve, függetlenül attól, hogy visszatért-e érte bárki.
- **Ez a sor az egyetlen hely, ahol rajongó által írt szöveg valaha is tárolásra kerül a
  szerverünkön, és egy óra ennek a kemény határa.** Ha az előadó be van jelentkezve, a készüléke
  ezután megtartja a borravalót a *saját* Firestore-előzményeiben — mert az az ő előzménye, és
  éppen ezért jelentkezett be.
- A neved és az üzeneted bekerül abba a **fizetési megjegyzésbe** is, amely a Revolutban, a
  MobilePayben vagy a Monzóban megnyílik — így tudja meg az előadó, ki adott borravalót. Ezek a
  cégek ezt követően a saját adatvédelmi tájékoztatóik szerint kezelik.
- A továbbító **semmilyen borravalóelőzményt nem őriz**. Nem tud sem neked, sem nekünk, sem
  senki másnak listát mutatni arról, ki kinek adott borravalót.

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
| **Google (Firebase)** | A fiókok, egy bejelentkezett előadó szinkronizált adatai, a továbbító, a szervernaplók | Az opcionális fiók és az opcionális továbbító |
| **Stripe** | A rajongó fizetési adatai, önálló adatkezelőként | Kártyás borravalók |
| **Cloudflare** | A rajongó IP-címe, a borravalóoldalon futó Turnstile-ellenőrzéshez. És a DNS-ünk. | Hogy a botok távol maradjanak a borravalóűrlaptól |
| **GitHub** | Bárki IP-címe és user-agentje, aki betölti ezt a weboldalt | A weboldal tárhelye |
| **Revolut / MobilePay / Monzo** | Bármit, amit a rajongó a saját alkalmazásukban tesz, a fizetési megjegyzéssel együtt | Ezek a fizetési módok |

Senkinek nem adunk el semmit, és nincs más ezen a listán.

## Jogalap, ha kell (GDPR)

- Az általad kért fiók működtetése, a saját adataid szinkronizálása a saját készülékeidre, a
  továbbító üzemeltetése egy olyan előadó számára, aki bekapcsolta, és a rajongó borravalójának
  eljuttatása arra a képernyőre, amelynek szánták: **az általad kért szolgáltatás teljesítése**.
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
- **Egy készülék**: a Beállítások → Biztonság felsorolja a készülékeidet. Visszavonhatsz egyet,
  vagy kijelentkezhetsz mindenhol máshol — ez azonnal, nem pedig előbb-utóbb megszünteti az
  összes többi készülék munkamenetét.
- **A teljes fiókod, egyetlen koppintással: ez a gomb még nincs meg az alkalmazásban.** Inkább
  bevalljuk, mint hogy az ellenkezőjét állítsuk. Amíg nem létezik, írj a
  **[contact@live.tips](mailto:contact@live.tips)** címre, és kézzel töröljük a fiókot és mindent,
  ami alatta van. Addig is már most törölheted az összes zenekart, amivel minden érdemi tartalom
  eltűnik, és egy üres fiók marad hátra.

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
