---
title: Hogyan bánik a live.tips a pénzzel (sehogy)
description: Nincs live.tips-egyenleg, nincs kifizetési ütemterv, nincs jutalék. Íme az architektúra, amely ezt a három állítást unalmassá teszi bátor helyett.
slug: hogyan-banik-a-live-tips-a-penzzel
---

Bármelyik borravalós persely kiírhatja a nyitóoldalára, hogy „0% jutalék". Az
érdekesebb kérdés az, hogy mit kellene tennie a szoftvernek ahhoz, hogy
*elkezdjen* részt lecsípni, és mennyit látnál ebből.

A live.tips esetében a válasz: újra kellene építeni. Ez nem ígéret a
szándékainkról, hanem annak leírása, hogy hová megy a pénz.

## A pénz sosem megy át rajtunk

Amikor egy rajongó rákoppint egy kártyás összegre, a fizetés a **te**
Stripe-fiókodban jön létre, a **te** Stripe-egyenlegedre kerül, és a **te**
Stripe-ütemterved szerint fizetik ki. Az egyetlen díj a Stripe saját, szokásos
feldolgozási díja, amelyet a Stripe közvetlenül tőled von le, pontosan úgy,
ahogyan akkor tenné, ha magad integráltad volna a Stripe-ot.

A mi oldalunkon nincs semmilyen főkönyv, mert nincs mit rögzíteni. Nem tudnánk
százalékot lecsípni anélkül, hogy előbb megépítenénk azt, ami a pénzt tartja — és
ilyen nincs.

Ez akkor is igaz, ha bejelentkezel, akkor is, ha nem. Amit a bejelentkezés
megváltoztat, az az *adat* útvonala, nem a pénzé, és a következő két szakasz
őszinte azzal kapcsolatban, hogy pontosan hogyan.

## A kulcsaid, és hol élnek

A beállítás egy *korlátozott* Stripe API-kulcsot kér, nem éles titkos kulcsot —
azokat eleve elutasítjuk. A korlátozott azt jelenti, hogy a kulcs két dolgot tud:
létrehozni a fizess-amennyit-akarsz borravalós linket, és figyelni a beérkező
borravalókat. Nem tudja elolvasni az egyenlegedet, nem indíthat kifizetést, nem
állíthat ki visszatérítést, és nem férhet hozzá az ügyféladatokhoz. Ha holnap
kiszivárogna, a robbanás sugara egyetlen borravalós link.

**Fiók nélkül ez a kulcs soha nem hagyja el az eszközödet.** Az eszköz saját
kulcstárában ül, és kizárólag az `api.stripe.com` címre küldjük el, TLS-en
keresztül. Egyáltalán nincs live.tips-szerver a képben.

**Amikor bejelentkezel, a kulcs hozzánk kerül** — mert egy kulcs, amely csak
egyetlen telefonon létezik, nem tudja kiszolgálni a színpadon lévő tabletet is.
Titkosítjuk (egy titkonkénti AES-256 kulccsal, amelyet magát a Google Cloud KMS
zár le), és oda tesszük, ahol semmi nem tudja visszaolvasni: sem egy másik fiók,
sem mi egy adatbázisba pillantva, még te magad sem. Csak a függvényeinken belül
nyílik ki, arra használjuk, hogy a nevedben a Stripe-pal beszéljünk, és soha többé
nem adjuk át egyetlen eszköznek sem. Mondjuk ki kereken: a bejelentkezés egy
live.tips-szervert állít a Stripe és a borravaló-előzményeid útvonalába. Soha nem a
pénzébe — az adatéba.

## A szerverek, és amit nem tehetnek

Kettő van, és mindkettő minimális.

**A továbbító** azért létezik, mert a Revolut és a MobilePay nem vezérelhető
böngészőből úgy, ahogy a Stripe. A bekapcsolásuk elindít egy maroknyi
Firebase-függvényt, amelyek a `tip.live.tips` címen szolgálják ki a borravalós
oldaladat. Tárolja a borravalós oldalad nyilvános profilját — a megjelenített
nevet és az általad közzétenni választott fizetési azonosítókat —, és egy olyan
oldal esetében, amely mögött nincs fiók, semmilyen borravaló-előzményt nem őriz:
egy borravaló csak addig vár, amíg a színpadi eszközöd meg nem jeleníti, és amiért
senki nem jött vissza, azt egy órán belül elsöpörjük. Nem lát pénzt, és 90 nap
inaktivitás után magától törlődik. Ha csak a Stripe-ot használod, és soha nem
jelentkezel be, a továbbítóval egyáltalán semmi nem lép kapcsolatba.

**A webhook** csak akkor létezik, ha bejelentkezel. Mivel a kulcsod immár nálunk
él, a Stripe minden borravalót jelent egy kis függvényünknek, amely beírja azt a
saját előzményeidbe, hogy a többi eszközöd meg tudja jeleníteni. Ez egy esemény
másolata, nem a pénzé. Egyetlen centet sem tud mozgatni, és mindig csak abba az
egyetlen fiókba tud írni, amelyhez tartozik.

Egyik szerver sem tud részt lecsípni, mert egyik sincs a pénz közelében sem. A
legtöbb, amit bármelyik tehet, az az, hogy meghibásodik — és egy csak Stripe-ot
használó, fiók nélküli beállítás egyikre sem támaszkodik.

## A fiók, amelyet nem kötelező létrehoznod

Az app továbbra is egy eszközhelyi profillal indul, ugyanúgy, ahogy mindig is: a
borravalós perselyed, a kulcsod és a borravaló-előzményeid az eszközön élnek, és
sehol máshol. Nincs mire regisztrálni.

A bejelentkezés — Apple-lel, Google-lel vagy vendégként — most már lehetséges, és
egyetlen okból létezik: a második eszköz miatt. Ha a színpadon lévő tabletnek és a
zsebedben lévő telefonnak ugyanazt az estét kell mutatnia, valaminek ülnie kell
kettejük között, és ez a valami a Firestore, egy olyan felhasználói azonosító alatt,
amelyet csak te olvashatsz. A zenekaraid, a beállításaid, a borravaló-előzményeid —
és, a fentiek szerint titkosítva, a Stripe-kulcsod — ott élnek. Ez valódi változás
az adatvédelmi történetben, és megérdemli, hogy kimondjuk, ahelyett hogy magadtól
fedeznéd fel: fiók nélkül egyetlen szerver sem lát soha egyetlen borravalót sem;
fiókkal a miénk egy sarka — a te sarkod — igen, és a webhookunk az, ami odaírja. Ez
a második eszköz ára, és rajtad áll, hogy megfizeted-e vagy visszautasítod. Amihez
sosem nyúl, az a pénz: a fiók az adataidat mozgatja, nem az egyenlegedet, és
jutalék továbbra sincs.

## Miért ne hidd el nekünk csak úgy

A fentiek mind ellenőrizhetők. A forráskód MIT-licenc alatt áll és nyilvános, az
oldal pedig egy statikus build, amelyet a GitHub Actions telepít a GitHub
Pagesre — semmi rejtett infrastruktúra, semmi ajtó mögött lefordítva. Nyisd meg a
hálózati fület egy demó borravaló közben, és olvasd el a kéréseket. Kevesebb van
belőlük, mint gondolnád.

Ez az igazi terméküzenet. Nem az, hogy megbízhatók vagyunk, hanem hogy nincs rá
szükséged, hogy azok legyünk.
</content>
</invoke>
