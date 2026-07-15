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

## Raha ei koskaan kulje meidän kauttamme

Kun fani napauttaa korttisummaa, maksu luodaan **sinun** Stripe-tiliäsi vasten, se
tilittyy **sinun** Stripe-saldoosi ja maksetaan ulos **sinun** Stripe-aikataulusi
mukaan. Ainoa kulu on Stripen oma vakiokäsittelymaksu, jonka Stripe veloittaa sinulta
suoraan, aivan kuten se tekisi, jos olisit integroinut Stripen itse.

Meidän puolellamme ei ole kirjanpitoa, koska ei ole mitään kirjattavaa. Emme voisi
napata prosenttiosuutta rakentamatta ensin sitä, mikä pitää rahaa hallussaan — eikä
sellaista ole.

Tämä pätee riippumatta siitä, kirjaudutko sisään vai et. Sisäänkirjautuminen muuttaa
*tietopolkua*, ei rahapolkua, ja seuraavat kaksi lukua ovat rehellisiä siitä, miten
tarkalleen.

## Avaimesi, ja missä ne sijaitsevat

Käyttöönotto pyytää *rajoitettua* Stripe-API-avainta, ei live-salaisuusavainta —
sellaiset me torjumme suoralta kädeltä. Rajoitettu tarkoittaa, että avain osaa kaksi
asiaa: luoda maksa-mitä-haluat-tippilinkin ja seurata tippien saapumista. Se ei voi
lukea saldoasi, käynnistää maksatuksia, tehdä hyvityksiä eikä koskea asiakastietoihin.
Jos se vuotaisi huomenna, vahinkosäde on yksi tippilinkki.

**Ilman tiliä tuo avain ei koskaan poistu laitteeltasi.** Se sijaitsee laitteen omassa
avainnipussa ja lähetetään aina vain osoitteeseen `api.stripe.com` TLS-yhteydellä.
Yksikään live.tips-palvelin ei ole lainkaan kuvassa.

**Kun kirjaudut sisään, avain siirtyy meille** — koska avain, joka on olemassa vain
yhdessä puhelimessa, ei voi palvella myös lavalla olevaa tablettia. Salaamme sen
(salaisuuskohtaisella AES-256-avaimella, joka on itsessään Google Cloud KMS:n kietoma)
ja tallennamme sen paikkaan, josta mikään ei voi lukea sitä takaisin: ei toinen tili,
emme me tietokantaa vilkaisemalla emmekä edes sinä. Se avataan sinetiltään vain
funktioidemme sisällä, sitä käytetään puhumaan Stripen kanssa puolestasi, eikä sitä
koskaan luovuteta enää laitteelle. Sanotaan se suoraan: sisäänkirjautuminen asettaa
live.tips-palvelimen Stripen ja tippihistoriasi väliin. Ei koskaan rahaan — tietoon.

## Palvelimet, ja mitä ne eivät voi tehdä

Niitä on kaksi, ja molemmat ovat minimaalisia.

**Välitin** on olemassa, koska Revolutia ja MobilePayta ei voi ohjata selaimesta samalla
tavalla kuin Stripeä. Niiden käyttöönotto kytkee päälle kourallisen Firebase-funktioita,
jotka tarjoilevat tippisivusi osoitteessa `tip.live.tips`. Se tallentaa julkisen
tippisivusi profiilin — näyttönimen ja ne maksutunnisteet, jotka valitsit julkaista — eikä
pidä tippihistoriaa sivun osalta, jonka takana ei ole tiliä: tippi odottaa vain siihen
asti, kunnes lavalaitteesi näyttää sen, ja se, mitä kukaan ei tullut hakemaan, pyyhitään
pois tunnin sisällä. Se ei näe rahaa ja poistaa itsensä 90 päivän käyttämättömyyden
jälkeen. Jos käytät vain Stripeä etkä koskaan kirjaudu sisään, välittimeen ei oteta
koskaan yhteyttä.

**Webhook** on olemassa vasta, kun kirjaudut sisään. Koska avaimesi sijaitsee nyt meillä,
Stripe raportoi jokaisen tipin pienelle funktiollemme, joka kirjoittaa sen omaan
historiaasi, jotta muut laitteesi voivat näyttää sen. Se on kopio tapahtumasta, ei kopio
rahasta. Se ei voi siirtää senttiäkään, ja se voi kirjoittaa vain siihen yhteen tiliin,
johon se kuuluu.

Kumpikaan palvelin ei voi ottaa osuutta, koska kumpikaan ei ole lähelläkään rahaa.
Eniten, mitä kumpikaan voi tehdä, on epäonnistua — eikä pelkkää Stripeä käyttävä,
tilitön kokoonpano ole riippuvainen kummastakaan.

## Tili, jota sinun ei ole pakko tehdä

Sovellus käynnistyy edelleen laitekohtaiseen profiiliin, aivan kuten ennenkin:
tippipurkkisi, avaimesi ja tippihistoriasi elävät laitteellasi eivätkä missään
muualla. Mihinkään ei tarvitse rekisteröityä.

Sisäänkirjautuminen — Applella, Googlella tai vieraana — on nyt mahdollista, ja se
on olemassa yhdestä syystä: toista laitetta varten. Jos lavalla olevan tabletin ja
taskussasi olevan puhelimen pitää näyttää sama ilta, jonkin täytyy istua niiden
välissä, ja se jokin on Firestore, sellaisen käyttäjätunnuksen alla, jota vain sinä
voit lukea. Bändisi, asetuksesi, tippihistoriasi — ja, yllä kuvatulla tavalla
salattuna, Stripe-avaimesi — elävät siellä. Se on todellinen muutos yksityisyystarinaan,
ja se ansaitsee tulla sanotuksi suoraan sen sijaan, että sen löytäisi itse: ilman tiliä
yksikään palvelin ei näe yhtäkään tippiä; tilin kanssa oma nurkkasi meidän
palvelimellamme näkee, ja meidän webhookimme on se, joka kirjoittaa sen sinne. Se on
toisen laitteen hinta, ja sinä päätät, maksatko sen vai et. Mihin se ei koskaan koske,
on raha — tili siirtää tietosi, ei saldoasi, eikä osuutta oteta edelleenkään.

## Miksi et saisi uskoa pelkkää sanaamme

Kaikki yllä oleva on tarkistettavissa. Koodikanta on MIT-lisensoitu ja julkinen, ja
sivusto on staattinen käännös, jonka GitHub Actions julkaisee GitHub Pagesiin — ei
piilotettua infrastruktuuria, ei mitään suljetun oven takana käännettyä. Avaa
verkkovälilehti demotipin aikana ja lue pyynnöt. Niitä on vähemmän kuin odotat.

Se on varsinainen tuotelupaus. Ei se, että olemme luotettavia, vaan että meidän ei
tarvitse olla.
