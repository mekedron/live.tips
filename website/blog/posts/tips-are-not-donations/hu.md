---
title: A borravaló nem adomány — és a Stripe kétféle üzletként kezeli őket
description: Az utcazenész, aki „adománygombot" keres, egy olyan üzletet ír le, amelyet a Stripe Európa nagy részén tilt. A borravaló egy már elvégzett szolgáltatásért jár; az adomány jótékonysági célú adománygyűjtés. A különbség dönti el, melyik kategóriába kerül a fiókod — és egyetlen API-paraméter rosszul is választhat helyetted.
slug: a-borravalo-nem-adomany
---

Az interneten minden eszköz azt akarja, hogy adománynak nevezd. A gombokon az áll:
*Donate*. A blogbejegyzések *adománygombról zenészeknek* írnak. A bővítménytárak
*adományok fogadását* ígérik. Ha zenész vagy, és keresel egy módot arra, hogy
fizessenek neked azok, akiknél nincs készpénz, ez a szó mindenhová követ.

Aztán nyitsz egy Stripe-fiókot, és a Stripe megkérdezi, mivel foglalkozik az üzleted.
És abban a pillanatban a szó megszűnik marketingszöveg lenni, és **üzleti
kategóriává** válik — olyanná, amelyet a Stripe Európa nagy részén nem engedélyez.

Ez nem szőrszálhasogatás, és nem is ügyvédi finomkodás. Ez az az egyetlen kérdés,
amely a leginkább képes egy tökéletesen hétköznapi utcazenész fizetési fiókját
felülvizsgálat, késleltetés vagy elutasítás alá vonni. Előadóknak szinte senki nem
írta még le világosan, tehát tessék.

## Két szó, két üzlet

A határvonalat a Stripe maga húzza meg, egy-egy mondatban. A
[Borravaló vagy adomány fogadásának feltételei](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations)
oldalról:

> a borravalót egy már nyújtott áruért vagy szolgáltatásért kell adni (pl. tartalom)

> az adománynak egy konkrét jótékonysági célhoz kell kötődnie, amelynek teljesítését
> vállalod

A Stripe oldalai angolul vannak; az eredeti megfogalmazás a linkek mögött található.

Olvasd el kétszer, mert ebben a posztban minden más ebből a kettőből következik.

A **borravaló** visszafelé néz valamire, ami már megtörtént. A szolgáltatás
elkészült, a rajongónak tetszett, a rajongó fizetett még pluszban. A pénz feltétel
nélküli, és nem tartozol érte semmivel. Ez a borravalósor az étterem számláján, az
érme a kalapban, az ezres, amit az utolsó dal után nyomnak a kezedbe.

Az **adomány** előre néz valamire, aminek a megtételét megígérted. Van egy ügy. Van
egy cél, amit leírtál annak, aki ad. És — a Stripe ebben kifejezetten világos — a
pénznek ténylegesen arra a célra kell mennie. Bizalmi letétként tartod egy olyan
dologért, amelynek teljesítését megígérted.

Ez nem ugyanannak a tettnek két árnyalata. Ez két különböző viszony, két különböző
kötelezettségcsomaggal, és a Stripe két különböző üzletként jegyzi őket.

## Egy utcazenész egyértelműen, kétség nélkül a borravaló oldalán áll

Kiálltál két órára egy térre és játszottál. Negyven ember megállt. Egyikük
beszkenneli a kódodat, és küld neked öt eurót.

**Ez borravaló.** A szolgáltatás maga az előadás. Meg is történt — végignézték. Nincs
ügy, nincs kedvezményezett, nincs cél, amelynek teljesítését vállaltad, és senki nem
bízott rád pénzt egy projektre. Előadóművész vagy, akinek fizetnek egy előadásért,
ami a létező legrégebbi és legkevésbé vitatott kereskedelmi megállapodások egyike.

A zavart az okozza, hogy az utcazenész borravalója *önkéntes*, minket pedig
megtanítottak arra, hogy az önkéntes pénz jótékonysági pénz. Nem az. A borravaló is
önkéntes. Nem az önkéntesség tesz valamit adománnyá — hanem a **jótékonysági cél**.

Szóval amikor a táblád azt írja, hogy „adományokat szívesen fogadunk", nem szerény
vagy udvarias vagy. A fizetésfeldolgozó szótárában egy olyan üzletet írsz le,
amelyet nem folytatsz.

## Mennyibe kerül neked valójában ez a szó

Itt válik az elvontság pénzzé.

A Stripe közzétesz egy
[korlátozott üzletek listáját](https://stripe.com/legal/restricted-businesses) — azok
a dolgok, amelyeket Stripe-fiókkal nem szabad csinálnod, vagy csak bizonyos
országokban. A **Közösségi és adománygyűjtés** cím alatt szó szerint ez a sor áll:

> Jótékonysági célú adománygyűjtést végző szervezetek (Megjegyzés: Támogatott
> Ausztráliában, Kanadában, az Egyesült Királyságban és az Egyesült Államokban.
> Minden más országban tilos.)

Olvasd el lassan a zárójelet. A jótékonysági célú adománygyűjtés **négy országban
támogatott üzlet** — Ausztrália, Kanada, az Egyesült Királyság, az Egyesült Államok
—, és **mindenhol máshol tilos.**

A „mindenhol máshol" magába foglalja Németországot, Franciaországot, Spanyolországot,
Olaszországot, Hollandiát, Lengyelországot, Finnországot és minden más országot, ahol
egy utcazenész ésszerűen állhatna. Magába foglalja **Magyarországot** is: a
jótékonysági célú adománygyűjtés a Stripe-on nálunk a „minden más országba" esik, és
nem támogatott. A világ utcazenészeinek többsége a „minden más országban" él.

Ugyanez az oldal korlátozottként sorolja fel a *„nonprofit szervezetek, jótékonysági
szervezetek, politikai szervezetek és az adományért cserébe jutalmat kínáló
vállalkozások által végzett adománygyűjtést"* is, a Stripe borravalóról és
adományokról szóló oldala pedig országspecifikus szabályokat tesz mindezek tetejébe:
Japánban magánszemélyek egyáltalán nem fogadhatnak adományt; Szingapúrban csak az
állam által bejegyzett jótékonysági vagy vallási szervezetek; Indiában, Hongkongban
és Thaiföldön az adományok nem támogatottak.

Vagyis az a berlini zenész, aki a Stripe regisztrációs űrlapjába beírja, hogy
„adományok a zenémre", épp most írt le egy olyan üzletet, amelyet a Stripe
Németországban tilt. Nem azért, mert az utcazenélés tiltott — az utcazenélés
teljesen rendben van —, hanem mert az általa választott szavak egy olyan
kategóriához tartoznak, amely az.

## És most a kalibrálás, mert ez nem rémtörténet

**Az utcazenészek nem korlátozott üzlet.** A borravaló nem korlátozott üzlet. Az élő
előadás nincs a listán, nem is fog rákerülni miatta a neved, és nagyjából a
leghétköznapibb dolog, amit egy fizetési fiókkal csinálhatsz. Ha pontosan írod le
magad, mindebből semmi nem érint téged, a beállítás pedig unalmas lesz — pontosan
úgy, ahogy lennie kell.

A kockázat itt nem a Stripe. A kockázat az **önmagad rossz besorolása** — belépni a
szobába, és jótékonysági adománygyűjtőként bemutatkozni, miközben gitáros vagy. A
Stripe-nak nincs módja tudni, hogy te azt gondoltad: „adj borravalót, kérlek".
Csupán az űrlap van neki, amit kitöltöttél, az üzletleírás, amit írtál, és a szavak
azon az oldalon, amerre a QR-kódod mutat.

A Stripe-nál senki nem vadászik utcazenészekre. Egyszerűen csak elolvassák, amit te
mondtál nekik.

## A csapda egyetlen paraméternyi mély

Itt jön az a rész, amit szinte senki nem ír le, és ez a poszt leghasznosabb darabja.

A Stripe Payment Linkjeinek van egy `submit_type` nevű paramétere. Az
[API-referencia](https://docs.stripe.com/api/payment-link/object) szinte kozmetikai
apróságként írja le:

> Jelzi a végrehajtott tranzakció típusát, ami testreszabja a vonatkozó szöveget az
> oldalon, például az elküldés gombot.

*Testreszabja a vonatkozó szöveget.* Ésszerűen arra jutnál, hogy ez egy gombfeliratot
változtat meg, és hogy egy borravalós perselynek nyilván azt kellene írnia, hogy
*Donate* („adományozz"), nem azt, hogy *Buy* („vásárolj"), mert a *Buy* fura szó egy
utcazenész kalapja alá nyomtatva.

Aztán elolvasod, mit is csinálnak valójában az egyes értékek:

> `donate` — Adományok fogadásához ajánlott. Az elküldés gomb 'Donate' feliratot kap,
> az URL-ek pedig a `donate.stripe.com` hosztnevet használják

> `pay` — Az elküldés gomb 'Buy' feliratot kap, az URL-ek pedig a `buy.stripe.com`
> hosztnevet használják

**Ez nem felirat. Ez hosztnév.** Állítsd be a `submit_type=donate`-et, és a link,
amit a Stripe a kezedbe ad — az, amiből QR-kódot csinálsz, kinyomtatsz és a
gitártokodra ragasztasz — a `donate.stripe.com`-on lakik. Minden rajongó, aki
beszkenneli, egy adományoldalt lát. A vezérlőpultodon minden fizetés egy adományozási
folyamaton keresztül érkezett. A tokodon lévő QR-kód azt mondja a Stripe-nak, azt
mondja a közönségednek, és végül azt mondja neked is, hogy te adományokat gyűjtesz.

Sehová nem írtad le az „adomány" szót. Egyetlen API-paraméter leírta helyetted, és
kinyomtatta egy műanyag táblára egy köztéren.

Könnyű csapda ez, és nem az olvasó hibája, ha belesétál: a paraméter szövegváltásként
van dokumentálva, a *Donate* nyilvánvalóan szebb szó egy utcazenész kalapja alá, a
következmény pedig — egy üzleti besorolás — két mondattal lejjebb van az oldalon,
mint ameddig a legtöbben elolvassák.

A live.tips a `submit_type=pay`-t küldi. Minden művész linkje egy `buy.stripe.com`
link, és a kódban ott a megjegyzés, hogy miért, mert ez pontosan az a fajta dolog,
amit egy jövőbeli közreműködő különben „megjavítana".

## Mit tegyen valójában egy zenész

Ehhez nem kell ügyvéd. Öt perc kell hozzá, meg néhány egyszerű szó.

- **Írd le a valódi üzletet** a Stripe regisztrációjában. „Élőzenei előadás."
  „Utcazenész." „Zenész — borravaló a közönségtől élő fellépéseken." Mondd ki, hogy
  fellépsz, és hogy a fizetések borravalók ezekért a fellépésekért.
- **Válassz hozzá illő kategóriát.** Élő szórakoztatás, előadóművészet, zenész. Nem
  jótékonyság, nem nonprofit, nem adománygyűjtés.
- **Használd a `submit_type=pay`-t**, ha te magad építed a Payment Linket. Ha egy
  eszköz építette meg helyetted, nézd meg az URL-t, amit előállított: a
  `buy.stripe.com` egy borravalós persely, a `donate.stripe.com` egy adományoldal.
  Ez kétmásodperces ellenőrzés, és megmondja, minek gondol téged az eszközöd.
- **Ne nevezd adománynak** — se a táblán, se a weboldaladon, se a Stripe
  üzletleírásában. „Borravaló", „persely", „támogasd a zenekart", „fizess nekünk egy
  sört" — mind azt írják le, ami történik. Az „adományozz" valami mást ír le.
- **Az igazi adománygyűjtést tartsd külön.** Ha jótékonysági koncertet játszol, és a
  pénz egy ügyre megy, az valóban *jótékonysági célú adománygyűjtés*, és a fenti
  szabályok most rólad szólnak — az országlistával együtt. Csináld a megfelelő
  fiókkal, a megfelelő országban, miután elolvastad a Stripe feltételeit, és soha ne
  azon a perselyen keresztül, amit a hétköznapi estéiden használsz.

Ez az utolsó hangsúlyt érdemel, mert ez az érvelés őszinte fele. Nem azt mondjuk,
hogy az adományok rosszak, vagy hogy zenészek soha nem gyűjthetnek pénzt egy ügyre.
Azt mondjuk, hogy ez egy **másik tevékenység**, más szabályokkal, és hogy csendben
ugyanazon a QR-kódon átfuttatni a legjobb módja annak, hogy mindkettővel bajba kerülj.

A Stripe borravalóról és adományokról szóló oldalának még egy sorát érdemes ismerni,
mert kizár egy harmadik dolgot, amit sokan összekevernek a másik kettővel: a Stripe
nem végez *„fizetésfeldolgozást személyes vagy személyek közti pénzküldéshez (pl.
pénz küldése barátok között)"*. A borravaló ajándék sem barátok között. Ha ezt a sínt
akarod — egy rajongó egyszerűen pénzt küld neked, emberről emberre —, arra való a
Revolut vagy a MobilePay, és ezért él ez a kettő az alkalmazásunkban
[teljesen a Stripe-on kívül](post:one-qr-code-every-payment-method).

## Ami ez a poszt nem

Nem jogi tanács. Nem adótanács — hogy a borravalót hogyan adóztatják, országonként,
néha városonként is hatalmasan eltér, és teljesen kívül esik ezen a szövegen; kérdezz
meg egy hozzáértőt ott, ahol élsz.

És nem ígéret a fiókodról. **Hogy a Stripe jóváhagy-e, kizárólag a Stripe döntése.**
A live.tips-nek nincs kapcsolata a Stripe-pal, nincs módja befolyásolni egy
felülvizsgálatot, és nincs módja fellebbezni helyetted. Amit a szoftverünk meg tud
tenni, az az, hogy nem ad szavakat a szádba. Amit az űrlapra írsz, azt továbbra is te
írod.

A szabályzatok is változnak. Az itt idézett sorok 2026 júliusában szerepeltek a
Stripe oldalain, a linkek pedig ott vannak; menj, és olvasd el őket magad, ahelyett,
hogy egy blogbejegyzésnek hinnél — beleértve ezt is.

## A rövid változat

Lejátszottad a szettet. Végignézték. Kifizettek érte.

Ez borravaló. Mondd is ki — a táblán, az űrlapon, az URL-ben —, és megkapod azt az
unalmas kimenetelt, amit szeretnél. A perselyt pontosan e köré az állítás köré
építjük, egészen odáig, hogy
[melyik Stripe-hosztnévre mutat a QR-kódod](post:build-a-tip-jar-on-your-own-stripe),
és ha a tágabb képet szeretnéd látni arról, hová megy valójában a pénz, az
[itt van](post:how-live-tips-handles-money).
