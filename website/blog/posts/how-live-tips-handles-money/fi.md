---
title: Näin live.tips käsittelee rahaa (ei käsittele)
description: live.tips-saldoa ei ole, maksuaikataulua ei ole eikä osuutta oteta. Tässä on arkkitehtuuri, joka tekee näistä kolmesta väitteestä tylsiä eikä uljaita.
slug: nain-live-tips-kasittelee-rahaa
---

Mikä tahansa tippipurkki voi laittaa aloitussivulleen ”0 % kuluja”. Mielenkiintoinen
kysymys on, mitä ohjelmiston pitäisi tehdä *alkaakseen* ottaa osuutta, ja kuinka
paljon siitä pystyisit näkemään.

live.tipsin kohdalla vastaus on: se pitäisi rakentaa uudelleen. Se ei ole lupaus
aikeistamme, vaan kuvaus siitä, minne raha menee.

## Korttitipit eivät koskaan kulje meidän kauttamme

Kun fani napauttaa korttisummaa, hänen selaimensa keskustelee osoitteen
`api.stripe.com` kanssa. Ei live.tips-palvelimen — sellaista ei ole tuolla reitillä.
Maksu luodaan **sinun** Stripe-tiliäsi vasten, se tilittyy **sinun** Stripe-saldoosi
ja maksetaan ulos **sinun** Stripe-aikataulusi mukaan. Ainoa kulu on Stripen oma
vakiokäsittelymaksu, jonka Stripe veloittaa sinulta suoraan, aivan kuten se tekisi,
jos olisit integroinut Stripen itse.

Meidän puolellamme ei ole kirjanpitoa, koska ei ole mitään kirjattavaa. Emme voisi
napata prosenttiosuutta rakentamatta ensin sitä, mikä pitää rahaa hallussaan.

## Avaimesi pysyvät sinun

Käyttöönotto pyytää *rajoitettua* Stripe-API-avainta, ei live-salaisuusavainta —
sellaiset me torjumme suoralta kädeltä. Se tallennetaan laitteesi omaan
avainnippuun ja lähetetään aina vain Stripelle TLS-yhteydellä.

Rajoitettu tarkoittaa, että avain osaa kaksi asiaa: luoda maksa-mitä-haluat-tippilinkin
ja seurata tippien saapumista. Se ei voi lukea saldoasi, käynnistää maksatuksia,
tehdä hyvityksiä eikä koskea asiakastietoihin. Jos se vuotaisi huomenna, vahinkosäde
on yksi tippilinkki.

## Ainoa paikka, jossa palvelin on olemassa

Revolutia ja MobilePayta ei voi ohjata selaimesta samalla tavalla kuin Stripeä,
joten niiden käyttöönotto kytkee päälle minimaalisen välityspalvelimen osoitteessa
`api.live.tips`. On syytä olla täsmällinen siitä, mitä tuo välityspalvelin tekee,
koska ”lisäsimme taustapalvelun” on yleensä kohta, jossa nämä tarinat menevät pieleen.

Se tallentaa julkisen tippisivusi profiilin — näyttönimen ja ne maksutunnisteet,
jotka valitsit julkaistavaksi. Siinä kaikki. Se ei pidä tippihistoriaa, ei näe
rahaa, ei säilytä avaimia ja poistaa itsensä 90 päivän käyttämättömyyden jälkeen.
Raha liikkuu edelleen suoraan fanisi Revolut- tai MobilePay-sovelluksen ja sinun
sovelluksesi välillä.

Jos käytät vain Stripeä, välityspalvelimeen ei oteta koskaan yhteyttä.

## Miksi et saisi uskoa pelkkää sanaamme

Kaikki yllä oleva on tarkistettavissa. Koodikanta on MIT-lisensoitu ja julkinen, ja
sivusto on staattinen käännös, jonka GitHub Actions julkaisee GitHub Pagesiin — ei
piilotettua infrastruktuuria, ei mitään suljetun oven takana käännettyä. Avaa
verkkovälilehti demotipin aikana ja lue pyynnöt. Niitä on vähemmän kuin odotat.

Se on varsinainen tuotelupaus. Ei se, että olemme luotettavia, vaan että meidän ei
tarvitse olla.
