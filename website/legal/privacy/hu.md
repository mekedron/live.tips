---
title: Adatvédelmi tájékoztató
description: A live.tips nem használ fiókokat, sütiket, analitikát és nyomkövetést. Itt a rövid lista arról, mi kerül mégis feldolgozásra, ki által és mennyi ideig.
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

- **Nincsenek fiókok.** Nincs mire regisztrálni.
- **Nincsenek sütik.** Egy sem, sehol.
- **Nincs analitika, nincs nyomkövetés, nincsenek hirdetések, nincsenek harmadik féltől
  származó szkriptek** ezen a weboldalon.
- **A pénzedhez soha nem nyúlunk.** A borravaló egyenesen a rajongótól az előadó saját
  Stripe-, Revolut-, MobilePay- vagy Monzo-fiókjába megy. Mi nem vagyunk ebben az útvonalban.
- **Az alapbeállítás szerint az alkalmazás kizárólag a Stripe-pal kommunikál** — semmilyen
  live.tips-szerverrel.
- Az egyetlen szerver, amit egyáltalán üzemeltetünk, egy kis továbbító, és az is csak akkor
  létezik, ha egy előadó bekapcsolja a Revolutot, a MobilePayt vagy a Monzót.

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

## Az alkalmazás

A live.tips alkalmazás **az előadó saját készülékén fut**. Minden, amit tud, ott él:

- A **Stripe korlátozott kulcsa** a készülék kulcstárában tárolódik (iOS/macOS Keychain,
  Android Keystore), és kizárólag az `api.stripe.com` címre küldjük el.
- A **borravalók előzményei, a munkamenetek előzményei, a cél és az alkalmazás beállításai**
  a készülék helyi tárhelyén tárolódnak. Ide tartoznak azok a nevek és üzenetek is, amelyeket
  a rajongók a borravalójukhoz csatolnak.
- Az alkalmazás eltávolítása mindezt törli. A mi oldalunkon nincs felhőalapú biztonsági mentés,
  mert a mi oldalunkon nincs felhő.

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

## Stripe

Amikor egy rajongó kártyával fizet, a **Stripe** fizetési oldalán van, nem a miénken. A Stripe
önálló adatkezelőként gyűjti és kezeli a fizetési adatokat a
[Stripe adatvédelmi tájékoztatója](https://stripe.com/privacy) alapján. Mi soha nem látunk
kártyaszámot, és nincs hozzáférésünk az előadó Stripe-fiókjához.

Az előadó alkalmazása az előadó saját korlátozott kulcsával olvassa ki a saját borravalóit a
Stripe-ból. A rajongó neve és üzenete, ha hagyott ilyet, a Stripe-tól az előadó készülékére
utazik, és ott meg is áll.

## A továbbító — csak ha a Revolut, a MobilePay vagy a Monzo be van kapcsolva

A csak Stripe-ot használó beállítások ehhez soha nem érnek hozzá, és itt abba is hagyhatják az olvasást.

A Revolut, a MobilePay és a Monzo semmilyen módot nem kínál arra, hogy egy alkalmazás
megerősítse a fizetés megtörténtét, ezért ezek a borravalók egy kis, nyílt forráskódú
továbbítón haladnak át, amelyet a **Cloudflare**-en üzemeltetünk az `api.live.tips` címen.
Pénzhez soha nem nyúl. Íme minden, amit kezel.

### Mit tárol az előadó

Egy borravalóoldal létrehozása eltárolja az előadó **megjelenítendő nevét, nyilvános üzenetét,
pénznemét és azokat a fizetési azonosítókat, amelyeket közzé kíván tenni** (a Stripe fizetési
linkjét, a Revolut-felhasználónevét, a MobilePay Box ID-ját, a Monzo-felhasználónevét). Mindez
olyan információ, amelyet az előadó amúgy is szándékosan tesz közzé a rajongók felé.

- **Megőrzés: 90 nap inaktivitás után automatikusan törlődik.**
- Az előadó **azonnal** törölheti az alkalmazásból, bármikor.
- Soha nem gyűjtünk e-mail-címet, jelszót, hivatalos nevet vagy bankszámlaadatot.

### Mit küld egy rajongó

A borravalóűrlap **összeget** kér, valamint opcionálisan egy **nevet** és egy **üzenetet**.
Ennyi az egész űrlap. Nincs e-mail, nincs telefonszám, nincs fiók.

- Ha az előadó képernyője **online**, a borravaló egyenesen átmegy rajta, és **soha nem íródik lemezre**.
- Ha az előadó képernyője **offline** — lezárt telefon, nincs térerő —, a borravaló **legfeljebb
  egy órán át tárolásra kerül**, hogy ne vesszen el egyszerűen, majd abban a pillanatban átadjuk,
  amint a képernyő újra csatlakozik. Ha senki nem csatlakozik újra, **megtekintés nélkül törlődik**.
  Ez az egyetlen, rajongó által írt szöveg, amit a továbbító valaha is tárol, és egy óra a kemény
  határa.
- A neved és az üzeneted bekerül abba a **fizetési megjegyzésbe** is, amely a Revolutban, a
  MobilePayben vagy a Monzóban megnyílik — így tudja meg az előadó, ki adott borravalót. Ezek a
  cégek ezt követően a saját adatvédelmi tájékoztatóik szerint kezelik.
- A továbbító **semmilyen borravalóelőzményt nem őriz**. Nem tud sem neked, sem nekünk, sem
  senki másnak listát mutatni arról, ki kinek adott borravalót.

### IP-címek és visszaélés elleni védelem

Egy nyílt űrlapnak, amelyre bárki küldhet adatot, szüksége van némi védelemre a botok ellen, ezért:

- Az IP-címedet a kérések **korlátozására** használjuk, és elküldjük a **Cloudflare Turnstile**
  szolgáltatásnak (egy botellenes ellenőrzés, amely a borravalóoldalon fut), hogy igazolja: nem
  vagy bot. A Turnstile a Cloudflare terméke, és olyan CAPTCHA helyett használjuk, amely profilt
  építene rólad.
- Hogy senki ne hozhasson létre több ezer borravalóoldalt, a létrehozó **IP-címének kriptográfiai
  hash-ét** körülbelül **két órán át** megőrizzük, majd eldobjuk.
- A **Cloudflare üzemeltetési naplói** néhány napig rögzítik a továbbító felé irányuló kérések
  technikai részleteit — URL, időzítés, státusz. Ezek nem tartalmaznak rajongói neveket vagy
  üzeneteket. A Cloudflare adatfeldolgozóként jár el; lásd a
  [Cloudflare adatvédelmi tájékoztatóját](https://www.cloudflare.com/privacypolicy/).

### Számlálók

A továbbító megszámolja, **hány borravalót** továbbított egy adott borravalóoldal, hogy
észrevehessük a visszaéléseket, és megtudjuk, használja-e egyáltalán valaki a dolgot. Ez egy szám.
Semmilyen rajongói adatot nem tartalmaz.

## Jogalap, ha kell (GDPR)

- A továbbító üzemeltetése egy olyan előadó számára, aki bekapcsolta, és a rajongó borravalójának
  eljuttatása arra a képernyőre, amelynek szánták: **az általad kért szolgáltatás teljesítése**.
- Kérésszám-korlátozás, Turnstile és hashelt IP-alapú kvóták: **jogos érdek** abban, hogy egy
  ingyenes, nyílt szolgáltatást ne tegyenek tönkre botok és csalások.
- Szervernaplók: **jogos érdek** a szolgáltatás üzemeltetésében és biztonságában.

## A jogaid

Kérheted tőlünk, hogy adjunk másolatot mindarról, amit rólad tárolunk, hogy helyesbítsük vagy
töröljük azt, és panasszal élhetsz a nemzeti adatvédelmi hatóságodnál. Írj a
**[contact@live.tips](mailto:contact@live.tips)** címre.

A gyakorlatban ennek nagy része már most is a te kezedben van: az előadók azonnal törölhetik a
borravalóoldalukat az alkalmazásból, a rajongói borravalók egy órán belül elpárolognak, minden
más pedig a saját készülékeden él.

## Gyermekek

A live.tips nem gyermekeknek szól, és tudatosan nem kezelünk gyermekekre vonatkozó adatokat.

## Változások

Frissítjük ezt az oldalt, ahogy a szoftver változik. Mivel az egész projekt nyílt forráskódú,
**e tájékoztató minden korábbi változata megtalálható a nyilvános git-előzményekben** — pontosan
összevetheted, mi és mikor változott.

## Nyelv

Ezt a tájékoztatót az oldal által támogatott minden nyelven közzétesszük, a kényelmed érdekében.
Ha egy fordítás és az angol változat eltér egymástól, **az angol változat az irányadó**.
