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

## Ainoa palvelin maksun reitillä

Revolutia ja MobilePayta ei voi ohjata selaimesta samalla tavalla kuin Stripeä,
joten niiden käyttöönotto kytkee päälle minimaalisen välityspalvelimen — kourallisen
Firebase-funktioita, jotka tarjoilevat tippisivusi osoitteessa `tip.live.tips`. On
syytä olla täsmällinen siitä, mitä tuo välityspalvelin tekee, koska ”lisäsimme
taustapalvelun” on yleensä kohta, jossa nämä tarinat menevät pieleen.

Se tallentaa julkisen tippisivusi profiilin — näyttönimen ja ne maksutunnisteet,
jotka valitsit julkaistavaksi. Siinä kaikki. Se ei pidä tippihistoriaa, ei näe
rahaa, ei säilytä avaimia ja poistaa itsensä 90 päivän käyttämättömyyden jälkeen.
Revolut- tai MobilePay-tippi odottaa siellä vain siihen asti, kunnes lavalaitteesi
noutaa sen: näyttäminen poistaa sen, ja se, mitä kukaan ei tullut hakemaan,
pyyhitään pois tunnin sisällä. Raha liikkuu edelleen suoraan fanisi Revolut- tai
MobilePay-sovelluksen ja sinun sovelluksesi välillä.

Jos käytät vain Stripeä, välityspalvelimeen ei oteta koskaan yhteyttä.

## Tili, jota sinun ei ole pakko tehdä

Sovellus käynnistyy edelleen laitekohtaiseen profiiliin, aivan kuten ennenkin:
tippipurkkisi, avaimesi ja tippihistoriasi elävät laitteellasi eivätkä missään
muualla. Mihinkään ei tarvitse rekisteröityä.

Sisäänkirjautuminen — Applella, Googlella tai vieraana — on nyt mahdollista, ja se
on olemassa yhdestä syystä: toista laitetta varten. Jos lavalla olevan tabletin ja
taskussasi olevan puhelimen pitää näyttää sama ilta, jonkin täytyy istua niiden
välissä, ja se jokin on Firestore, sellaisen käyttäjätunnuksen alla, jota vain sinä
voit lukea. Bändisi, asetuksesi, rajoitettu avaimesi ja tippihistoriasi
synkronoituvat sinne. Se on todellinen muutos yksityisyystarinaan, ja se ansaitsee
tulla sanotuksi suoraan sen sijaan, että sen löytäisi itse: ilman tiliä yksikään
palvelin ei näe yhtäkään tippiä; tilin kanssa oma nurkkasi meidän palvelimellamme
näkee. Se on toisen laitteen hinta, ja sinä päätät, maksatko sen vai et. Mihin se
ei koskaan koske, on raha — tili siirtää tietosi, ei saldoasi, eikä osuutta oteta
edelleenkään.

## Miksi et saisi uskoa pelkkää sanaamme

Kaikki yllä oleva on tarkistettavissa. Koodikanta on MIT-lisensoitu ja julkinen, ja
sivusto on staattinen käännös, jonka GitHub Actions julkaisee GitHub Pagesiin — ei
piilotettua infrastruktuuria, ei mitään suljetun oven takana käännettyä. Avaa
verkkovälilehti demotipin aikana ja lue pyynnöt. Niitä on vähemmän kuin odotat.

Se on varsinainen tuotelupaus. Ei se, että olemme luotettavia, vaan että meidän ei
tarvitse olla.
