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

## A kártyás borravaló sosem megy át rajtunk

Amikor egy rajongó rákoppint egy kártyás összegre, a böngészője az
`api.stripe.com`-mal beszél. Nem egy live.tips-szerverrel — ezen az útvonalon
nincs is ilyen. A fizetés a **te** Stripe-fiókodban jön létre, a **te**
Stripe-egyenlegedre kerül, és a **te** Stripe-ütemterved szerint fizetik ki. Az
egyetlen díj a Stripe saját, szokásos feldolgozási díja, amelyet a Stripe
közvetlenül tőled von le, pontosan úgy, ahogyan akkor tenné, ha magad integráltad
volna a Stripe-ot.

A mi oldalunkon nincs semmilyen főkönyv, mert nincs mit rögzíteni. Nem tudnánk
százalékot lecsípni anélkül, hogy előbb megépítenénk azt, ami a pénzt tartja.

## A kulcsaid a tiéd maradnak

A beállítás egy *korlátozott* Stripe API-kulcsot kér, nem éles titkos kulcsot —
azokat eleve elutasítjuk. A saját eszközöd kulcstárában tárolódik, és kizárólag
TLS-en keresztül jut el a Stripe-hoz.

A korlátozott azt jelenti, hogy a kulcs két dolgot tud: létrehozni a
fizess-amennyit-akarsz borravalós linket, és figyelni a beérkező borravalókat.
Nem tudja elolvasni az egyenlegedet, nem indíthat kifizetést, nem állíthat ki
visszatérítést, és nem férhet hozzá az ügyféladatokhoz. Ha holnap kiszivárogna, a
robbanás sugara egyetlen borravalós link.

## Az egyetlen hely, ahol létezik szerver

A Revolut és a MobilePay nem vezérelhető böngészőből úgy, ahogy a Stripe, ezért a
bekapcsolásuk elindít egy minimális továbbítót az `api.live.tips` címen. Érdemes
pontosnak lenni abban, mit csinál ez a továbbító, mert a „hozzáadtunk egy
backendet" általában az a pont, ahol az ilyen történetek félresiklanak.

A borravalós oldalad nyilvános profilját tárolja — a megjelenített nevet és az
általad közzétenni választott fizetési azonosítókat. Ennyi. Nem őriz borravaló-előzményeket, nem lát pénzt, nem tart kulcsot, és 90 nap inaktivitás után magától
törlődik. A pénz továbbra is közvetlenül a rajongód Revolut- vagy MobilePay-appja
és a tiéd között mozog.

Ha csak a Stripe-ot használod, a továbbítóval soha semmi nem lép kapcsolatba.

## Miért ne hidd el nekünk csak úgy

A fentiek mind ellenőrizhetők. A forráskód MIT-licenc alatt áll és nyilvános, az
oldal pedig egy statikus build, amelyet a GitHub Actions telepít a GitHub
Pagesre — semmi rejtett infrastruktúra, semmi ajtó mögött lefordítva. Nyisd meg a
hálózati fület egy demó borravaló közben, és olvasd el a kéréseket. Kevesebb van
belőlük, mint gondolnád.

Ez az igazi terméküzenet. Nem az, hogy megbízhatók vagyunk, hanem hogy nincs rá
szükséged, hogy azok legyünk.
