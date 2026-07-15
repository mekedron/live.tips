---
title: Tietosuojaseloste
description: live.tips ei käytä evästeitä, analytiikkaa eikä seurantaa, ja se toimii täysin ilman tiliä. Jos päätät kirjautua sisään, tässä on tarkalleen se, mitä tallennetaan, minne, kenen toimesta ja kuinka kauan.
updated: 2026-07-15
updated_label: Päivitetty viimeksi 15. heinäkuuta 2026
---

live.tips on avoimen lähdekoodin tippipurkki esiintyjille. Sitä ylläpitää **Nikita Rabykin**,
yksityinen kehittäjä, ei yritys. Jos jokin alla olevista asioista askarruttaa sinua, kirjoita
osoitteeseen **[contact@live.tips](mailto:contact@live.tips)** — se tavoittaa oikean ihmisen.

Tämä seloste on rehellinen myös tylsien osien kohdalla. Sanomme mieluummin ”säilytämme
nimesi niin kauan kuin pidät bändisi” kuin väitämme, ettemme säilytä mitään, ja olemme väärässä.

## Lyhyt versio

- **Tili on valinnainen.** Sovellus toimii täysin ilman tiliä, ja se on edelleen oletus. Jos
  haluat bändisi ja historiasi toiselle laitteelle, voit kirjautua sisään — ja silloin osa
  siitä tallentuu palvelimelle, ja enemmän kuin ennen. Mikä on mitäkin, kerrotaan alla.
- **Ei evästeitä.** Ei yhtäkään, ei missään.
- **Ei analytiikkaa, ei seurantaa, ei mainoksia, ei kolmannen osapuolen skriptejä** tällä
  sivustolla.
- **Emme koskaan koske rahoihisi.** Tipit kulkevat suoraan fanilta artistin omalle
  Stripe-, Revolut-, MobilePay- tai Monzo-tilille. Mitään live.tips-saldoa ei ole, ei koskaan.
- **Ilman tiliä sovellus puhuu vain Stripen kanssa** — ei minkään live.tips-palvelimen. Jos
  kirjaudut sisään, se muuttuu: Stripe-avaimesi siirtyy palvelimellemme ja Stripe raportoi
  tippisi meille, jotta voimme tuoda ne muille laitteillesi. Se on sisäänkirjautumisen
  rehellinen hinta, ja se kuvataan kokonaisuudessaan alla.
- **Push-ilmoitukset ovat uusia, valinnaisia ja vain kirjautuneille tileille.** Mitään ei
  työnnetä laitteelle, joka ei ole niitä koskaan kytkenyt päälle, eikä tilittömälle laitteelle
  lähetetä sellaista lainkaan.
- Palvelimet, joita ylläpidämme, ovat Googlen Firebasessa. Ne ovat olemassa, jos artisti
  kytkee päälle Revolutin, MobilePayn tai Monzon — tai jos hän kirjautuu sisään.

## Tämä sivusto

Sivusto on staattinen ja sitä isännöi **GitHub Pages**. Isäntänä GitHub vastaanottaa
jokaisen sivunlataajan IP-osoitteen ja selaimen user-agentin — tämä on tavanomaista
verkkopalvelimen lokitusta, se tapahtuu ennen kuin yksikään meidän koodirivimme suoritetaan,
emmekä voi kytkeä sitä pois. GitHub käsittelee näitä tietoja oman
[tietosuojalausuntonsa](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement)
mukaisesti. Me emme lue noita lokeja, eikä GitHub näytä niitä meille.

Sen lisäksi lukemasi sivut eivät lataa **mitään keneltäkään muulta**: fontit, ikonit ja
kuvat tarjoillaan live.tips-sivustolta itseltään. Täällä ei ole Google Analyticsia, ei
tag manageria, ei pikseliä, ei upotettua widgetiä.

Sivusto tallentaa **kaksi arvoa selaimesi `localStorage`-muistiin**. Molemmat asetat sinä,
molemmat ovat luettavissa vain tältä sivustolta, eikä kumpaakaan lähetetä minnekään:

| Avain | Mitä se muistaa |
| --- | --- |
| `lt-landing-theme` | valitsitko vaaleat, tummat vai automaattiset värit |
| `lt-langbar-dismissed` | että suljit ”saatavilla myös omalla kielelläsi” -bannerin |

Selaimen tallennustilan tyhjentäminen poistaa ne. Ne eivät ole evästeitä, niitä ei jaeta,
eivätkä ne yksilöi ketään.

## Sovelluksella on kaksi tilaa, ja koko juttu on niiden erossa

Kaikki alla oleva riippuu yhdestä kysymyksestä: **oletko kirjautunut sisään?**

### Tila yksi — ei tiliä. Edelleen oletus, edelleen ennallaan.

Sovellus toimii **artistin omalla laitteella**, ja kaikki, minkä se tietää, sijaitsee siellä:

- **Stripen rajoitettu avain** tallennetaan laitteen avainnippuun (iOS-/macOS-Keychain,
  Android Keystore) ja se lähetetään ainoastaan osoitteeseen `api.stripe.com`.
- **Tippihistoria, sessiohistoria, tavoite, biisitoivelista ja sovelluksen asetukset**
  tallennetaan laitteen paikalliseen tallennustilaan. Tähän sisältyvät nimet ja viestit,
  jotka fanit liittävät tippeihinsä.
- Sovelluksen poistaminen poistaa kaiken tämän. Meidän puolellamme ei ole pilvivarmuuskopiota,
  koska tässä tilassa meidän puolellamme ei ole pilveä.

**Me emme koskaan vastaanota mitään tästä.** Sovelluksessa ei ole analytiikan SDK:ta, ei
kaatumisraportointia eikä mainoskoodia — ei lainkaan, ei edes pois kytkettyinä.
(Push-ilmoitukset ovat olemassa, mutta ne ovat kirjautuneiden ominaisuus ja pois päältä,
kunnes kytket ne — katso *Tila kaksi*. Tilittömälle laitteelle ei lähetetä sellaista koskaan.)

Kaksi täsmennystä, jotta väite ”ei puhu kenellekään” pysyy täsmälleen totena:

- Sovellus hakee **valuuttakurssit** kerran päivässä julkisista kurssirajapinnoista
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Nämä ovat tavallisia
  pyyntöjä julkisesta kurssilistasta. Ne eivät sisällä tietoa sinusta, artistista tai
  yhdestäkään tipistä — mutta kuten mikä tahansa verkkopyyntö, ne paljastavat IP-osoitteesi
  näille palveluille.
- Jos käytät sovelluksen **selainversiota**, selaimesi lataa sen staattiselta isännältämme
  (katso *Tämä sivusto* yllä).

### Tila kaksi — kirjauduit sisään. Silloin osa tiedoista lähtee laitteelta, tarkoituksella.

Sisäänkirjautuminen on tietoinen teko. Mikään ei kirjaa sinua sisään puolestasi, eikä mikään
sovelluksessa lakkaa toimimasta, vaikket koskaan kirjautuisi. Kirjaudut sisään, koska haluat
toisen laitteen: taskussa oleva puhelin ja lavalla oleva tabletti näyttävät saman illan, samat
bändit, saman historian.

Se onnistuu vain, jos palvelin säilyttää ne. **Niinpä se säilyttää, ja se on toisen laitteen
rehellinen hinta.**

Palvelin on **Firebase**, eli Google. Tilin voi hankkia kolmella tavalla:

- **Kirjaudu Applella** tai **kirjaudu Googlella** — Firebase Auth vastaanottaa sen, minkä
  palveluntarjoaja luovuttaa: käyttäjätunnisteen (uid) ja yleensä sähköpostiosoitteen sekä
  nimen. (Applella voit piilottaa sähköpostisi; silloin Apple antaa meille sen sijaan
  välitysosoitteen, ja se luovuttaa nimesi vain aivan ensimmäisellä sisäänkirjautumiskerralla.)
- **Vierastili** — anonyymi tili ilman sähköpostia ja ilman nimeä. Se synkronoi ja sen voi
  perua, mutta sitä ei voi palauttaa millään, jos laite katoaa. Se on uid eikä mitään muuta.
  Vierastili ei voi käyttää alla kuvattua palvelinpuolen Stripe-avaimen säilytystä eikä
  push-ilmoituksia, koska molemmat tarvitsevat tilin, jonka voimme luovuttaa sinulle takaisin.

Kun olet kirjautunut sisään, tili saa oman yksityisen nurkkansa Googlen **Cloud
Firestore** -tietokannasta, polusta `users/<your uid>/`. Tietoturvasäännöt myöntävät sen nurkan
tälle uid:lle **eikä kenellekään muulle** — mikään toinen tili ei voi lukea sitä, ei myöskään
URL-osoitteita arvaamalla. Sen sisällä on:

| Mitä | Miksi se on siellä |
| --- | --- |
| **Bändisi** — nimet, tippipurkin ja maksutapojen asetukset, julisteen tekstit, tavoitteet ja **biisitoivelistasi** | jotta bändi on olemassa jokaisella laitteella, jolle kirjaudut |
| **Sovelluksen asetukset**, ilmoitusasetuksesi mukaan lukien | jotta lisäämäsi laite on jo valmiiksi konfiguroitu |
| **Sessiotietueet ja tippihistoria** — mukaan lukien **nimet ja viestit, jotka fanit liittävät tippeihinsä**, ja mahdollinen **fanin toivoma biisi** | koska juuri tuota historiaa pyysit näkyviin toiselle laitteelle |
| Parhaillaan käynnissä oleva **live-sessio** | jotta toinen ruutu voi liittyä tämän illan settiin |
| **Laitteesi** — nimi, jonka kukin niistä itselleen antaa (”Nikitan iPhone”), sen alusta ja malli, sen käyttöliittymän kieli, milloin se nähtiin ensimmäisen ja viimeisen kerran, ja (jos kytkit ilmoitukset päälle) **push-token** | jotta Asetukset → Turvallisuus voi listata ne, jotta ilmoitus tavoittaa oikean laitteen oikealla kielellä ja jotta voit perua jonkin niistä |
| Pieni **profiilidokumentti** — valitsemasi tilinimi ja käyttämäsi palveluntarjoaja | jotta tilinvaihdin osaa nimetä sen |
| **Ilmoitussyöte** — rajattu lista viimeaikaisista tipeistä ja biisitoiveista, jotka saapuivat, kun mikään setti ei ollut käynnissä | jotta voit katsoa jälkikäteen, mitä jäi näkemättä |

Ja nyt se tärkeä osa, suoraan sanottuna: **ilman tiliä fanin nimi ja viesti eivät koskaan
poistu artistin laitteelta. Tilin kanssa ne tallennetaan Googlen palvelimille artistin uid:n
alle, osana kyseisen artistin omaa synkronoitua historiaa, ja — kuten seuraavat kaksi lukua
selittävät — ne sinne nyt kirjoittaa meidän palvelimemme.** Mikään toinen tili ei voi lukea
niitä, me emme katso niitä, eikä niistä johdeta mitään — mutta ne ovat siellä, ja ne pysyvät
siellä niin kauan kuin bändikin, ja se on hyvä tietää ennen kuin kirjaudut sisään.

Uloskirjautuminen palauttaa laitteen paikalliseen tilaan. Se ei poista tilin tietoja — katso
*Asioiden poistaminen* alta.

#### Stripe-avaimesi siirtyy palvelimellemme, kun kirjaudut sisään

Tämä on suurin muutos, ja se, joka kannattaa lukea kaikkein tarkimmin.

**Ilman tiliä Stripen rajoitettu avaimesi ei koskaan poistu laitteeltasi.** Se on Tila yksi,
ja se on ennallaan.

**Kun kirjaudut sisään, se poistuu — meille.** Avain salataan (salaisuuskohtaisella
AES-256-avaimella, joka on itsessään Google Cloud KMS:n kietoma) ja tallennetaan palvelinpuolelle
paikkaan, jota **kukaan ei voi lukea takaisin — ei toinen tili eikä edes sinä.** Se avataan
sinetiltään vain Cloud Functions -funktioidemme sisällä, sitä käytetään puhumaan Stripen kanssa
puolestasi, eikä sitä koskaan luovuteta enää laitteelle.

Koska avain sijaitsee nyt meillä, **Stripe raportoi tippisi suoraan palvelimellemme**:
rekisteröimme webhookin omalle Stripe-tilillesi, ja Stripe kertoo tuolle webhookille aina, kun
tippi maksetaan. Funktiomme kirjoittaa tipin tilisi historiaan (katso alla). Sovelluksesi ei
enää kysele Stripeltä kirjautuneen tilin osalta; se tavoittaa Stripen vain kapean, kiinteän
toimintolistan kautta palvelimellamme (tippilinkkisi luominen, biisitoivelinkin luonti ja omien
tippiesi lukeminen takaisin täsmäytystä varten).

Eli ilman kaunistelua: **kirjautuneella tilillä Stripen ja historiasi välissä on nyt
live.tips-palvelin.** Emme silti koskaan koske rahaan — korttitippi luodaan Stripe-tiliäsi
vasten, se tilittyy Stripe-saldoosi ja maksetaan ulos Stripe-aikataulusi mukaan, aivan kuten
ennenkin. Mikä muuttui, on *tietopolku*, ei *rahapolku*. Jos et koskaan kirjaudu sisään, mikään
tästä ei koske sinua, ja sovellus puhuu edelleen suoraan osoitteeseen `api.stripe.com` eikä
kenellekään muulle.

#### Laitteen lisääminen QR-koodilla

Laitteen lisäämiseksi näytät QR-koodin laitteelta, joka on jo kirjautuneena. Koodi on
satunnainen, **kertakäyttöinen ja vanhenee kahdessa minuutissa**, eikä uusi laite saa mitään
ennen kuin napautat *vahvista* vanhalla. Niin kauan kuin tämä kättely on auki, säilytämme
koodin, uuden laitteen itselleen antaman nimen ja sen alustan — ja tietue poistetaan, kun
koodi vanhenee. Valokuvattu QR-koodi on hyödytön ilman sinun vahvistusnapautustasi.

## Biisitoiveet

Bändi voi kytkeä päälle **biisitoiveet**: fanit valitsevat tällöin biisin artistin listalta ja
voivat halutessaan maksaa nostaakseen sen jonossa ylöspäin. Toive on vain tippi, joka kantaa
mukanaan myös **sen, mitä biisiä** toivottiin — joten sama nimi ja viesti, jotka fani voi liittää
tippiin, koskevat tässäkin, ja se tallennetaan ja säilytetään täsmälleen kuten mikä tahansa muu
tippi (alla). Julkinen jono, jonka fani näkee, näyttää vain **biisikohtaiset summat** — kuinka
paljon biisi on kerännyt ja missä se on — eikä siinä ole **fanien nimiä**. Ilman tiliä koko
biisitoivelista ja sen historia elävät vain laitteella.

## Push-ilmoitukset

Kun olet kirjautunut sisään, sovellus voi lähettää sinulle **push-ilmoituksen** — mutta vain jos
kytket sen päälle laitekohtaisesti ja vasta sen jälkeen, kun laitteesi käyttöjärjestelmä on
myöntänyt luvan. Se on olemassa yhtä asiaa varten: tippi tai biisitoive, joka saapuu **silloin,
kun et pidä settiä**, jotta kuulet tipistä, joka muuten jäisi sinulta huomaamatta. Tippi, joka
saapuu lavasi ollessa live, ei lähetä mitään — katsot sitä jo muutenkin.

- Push-ilmoituksen toimittaakseen Googlen **Firebase Cloud Messaging (FCM)** tarvitsee laitteelle
  **push-tokenin**. Säilytämme tuon tokenin ja laitteen käyttöliittymän kielen laitteen omassa
  tietueessa tilisi alla, ja se poistetaan sillä hetkellä, kun kytket ilmoitukset pois, peruutat
  laitteen tai kirjaudut ulos. Kuolleet tokenit karsitaan automaattisesti.
- Itse ilmoitus kertoo, mitä saapui — summan sekä fanin nimen tai biisin nimen, jos hän jätti
  sellaisen. Sama lyhyt lista säilytetään tilisi **ilmoitussyötteessä**, joka on rajattu sataan
  viimeisimpään merkintään, jotta voit selata jälkikäteen, mitä saapui poissa ollessasi.
- Verkossa push-ilmoituksen toimittaminen vaatii pienen **service workerin** sivuston juuressa
  sekä Firebase-viestintä-SDK:n, jonka selaimesi hakee ensimmäisellä kerralla Googlelta
  (`gstatic.com`). Web-push kulkee tämän jälkeen selaimesi oman push-palvelun kautta (Chromella
  se on Googlen). Mikään tästä ei lataudu, ellet ole kytkenyt ilmoituksia päälle.
- **Vierastili ja tilitön laite eivät saa push-ilmoituksia**, koska push tarvitsee tilin, jolle
  toimittaa, ja tokenin, jonka valitsit antaa.

## Missä kaikki tämä fyysisesti sijaitsee

Firebase Auth, Cloud Firestore, Cloud Functions -funktiomme ja Cloud KMS -avain, joka kietoo
Stripe-salaisuutesi, toimivat kaikki **Euroopan unionissa** — tietokanta Googlen
`eur3`-monialueella, funktiot ja avainnippu (key ring) alueella `europe-west1`. Google toimii
henkilötietojen käsittelijänämme
[Firebasen tietosuoja- ja tietoturvaehtojen](https://firebase.google.com/support/privacy) ja
oman [tietosuojaselosteensa](https://policies.google.com/privacy) mukaisesti. Kuten mikä tahansa
suuri palveluntarjoaja, Google voi käyttää EU:n ulkopuolista infrastruktuuria tukeen ja
tietoturvaan; sitä säätelevät nuo ehdot, emme me. Push-ilmoitukset kulkevat, kun ne on luovutettu
Firebase Cloud Messagingille ja selaimesi tai puhelimesi push-palvelulle, näiden yhtiöiden
infrastruktuurin kautta laitteellesi.

## Stripe

Kun fani maksaa kortilla, hän on **Stripen** kassasivulla, ei meidän. Stripe kerää ja
käsittelee hänen maksutietonsa itsenäisenä rekisterinpitäjänä
[Stripen tietosuojaselosteen](https://stripe.com/privacy) mukaisesti. Me emme koskaan näe
korttinumeroita.

Se, miten tippisi tavoittavat sinut, riippuu tilasta:

- **Ilman tiliä** artistin sovellus lukee hänen omat tippinsä Stripestä artistin omalla
  rajoitetulla avaimella — suoraan laitteelta osoitteeseen `api.stripe.com`. **Siinä polussa ei
  ole live.tips-palvelinta.**
- **Kirjautuneena** avain sijaitsee palvelimellamme (salattuna, kuten yllä), ja Stripe raportoi
  jokaisen tipin webhookillemme, joka kirjoittaa sen kyseisen artistin omaan Firestore-historiaan.
  **Tässä tilassa polussa on live.tips-palvelin** — tippitiedon osalta, ei koskaan rahan. Fanin
  nimi ja viesti, jos hän jätti sellaisen, kulkevat tipin mukana kyseisen artistin omaan
  historiaan ja pysähtyvät siihen.

## Välitin — vain jos Revolut, MobilePay tai Monzo on kytketty päälle

Pelkkää Stripeä käyttävät kokoonpanot eivät koskaan koske tähän.

Revolut, MobilePay ja Monzo eivät tarjoa sovellukselle mitään tapaa vahvistaa, että maksu
tapahtui, joten nuo tipit reititetään pienen avoimen lähdekoodin välittimen kautta, jota
ylläpidämme **Firebasessa** — Cloud Functions ja Firestore alueella `europe-west1`, ja fanin
tippisivu tarjoillaan osoitteesta **`tip.live.tips/t/<id>`**. Se ei koskaan koske rahaan. Tässä
on kaikki, mitä se käsittelee.

### Mitä artisti tallentaa

Tippisivun luominen tallentaa artistin **näyttönimen, hänen julkisen viestinsä, hänen
valuuttansa ja ne maksutunnisteet, jotka hän valitsi julkaista** (hänen Stripe-maksulinkkinsä,
Revolut-käyttäjänimensä, MobilePay Box ID:nsä, Monzo-käyttäjänimensä) ja, jos biisitoiveet ovat
päällä, **hänen julkisen biisilistansa ja sen biisikohtaiset hinnat**. Kaikki tämä on tietoa,
jonka artisti joka tapauksessa tarkoituksella julkaisee faneille.

- **Säilytysaika: tippisivu, jonka takana ei ole tiliä, poistetaan automaattisesti 90 päivän
  käyttämättömyyden jälkeen.** Kirjautuneelle tilille kuuluva tippisivu elää yhtä kauan kuin
  bändi, jolle se kuuluu.
- Artisti voi poistaa sen **välittömästi** sovelluksesta, milloin tahansa.
- Täällä ei kerätä sähköpostiosoitetta, salasanaa, virallista nimeä eikä pankkitietoja.
- Sivun salaisuus säilytetään **vain tiivisteenä**. Emme voisi kertoa sinulle salaisuutta,
  vaikka kysyisit; voimme ainoastaan tarkistaa yhden.

### Mitä fani lähettää

Tippilomake kysyy **summan** ja valinnaisesti **nimen** ja **viestin** — ja biisitoiveen
kohdalla, mikä biisi. Siinä on koko lomake. Ei sähköpostia, ei puhelinnumeroa, ei tiliä.

Se, minne tuo fanin kirjoittama teksti menee ja kuinka pitkäksi aikaa, riippuu siitä, onko
artisti kirjautunut sisään:

- **Jos tippisivun takana ei ole tiliä**, tippi kirjoitetaan **toimitusjonoon** — yhteen
  dokumenttiin, joka on olemassa vain luovutettavaksi artistin näytölle. Kun näyttö näyttää
  tipin, **artistin laite poistaa tuon dokumentin.** Poisto *on* kuittaus. Jos artistin näyttö
  on poissa verkosta — puhelin lukossa, ei kenttää — tippi **odottaa siinä jonossa enintään
  yhden tunnin**, jottei se yksinkertaisesti katoa, ja menee perille sillä hetkellä, kun näyttö
  palaa yhteyteen. Jos kukaan ei palaa yhteyteen, se **poistetaan kenenkään näkemättä**,
  ajastetusti pyyhkäistynä. Tilittömän artistin kohdalla **tuo jono on ainoa paikka, jossa fanin
  kirjoittamaa tekstiä koskaan säilytetään palvelimellamme, ja yksi tunti on sen ehdoton
  yläraja.**
- **Jos tippisivu kuuluu kirjautuneelle tilille**, jonoa ei ole. Palvelimemme kirjoittaa tipin
  **suoraan kyseisen artistin omaan historiaan** hänen uid:nsä alle — tämän illan sessioon, jos
  setti on käynnissä, tai bändin omaan arkistoon, jos ei. Siellä se pysyy **niin kauan kuin
  bändikin**; se on artistin oma historia, ja juuri sitä varten hän kirjautui. Tämä on sama
  historia, johon yllä kuvattu Stripe-webhook kirjoittaa.
- Nimesi ja viestisi sijoitetaan myös **maksuviestiin**, joka avautuu Revolutissa,
  MobilePayssa tai Monzossa — juuri siten artisti tietää, kuka tippasi. Nuo yhtiöt käsittelevät
  sen sitten omien tietosuojaselosteidensa mukaisesti.
- Välitin ei pidä **mitään artistien välistä tippikirjanpitoa**. Se ei voi näyttää sinulle,
  meille eikä kenellekään muulle listaa siitä, kuka tippasi kenelle eri artistien kesken.

### IP-osoitteet ja väärinkäytösten torjunta

Avoin lomake, johon kuka tahansa voi lähettää, tarvitsee jonkinlaisen suojan botteja vastaan,
joten:

- IP-osoitteesi lähetetään **Cloudflare Turnstilelle** — tippisivulla ajettavaan
  bottitarkistukseen — sen varmistamiseksi, ettet ole botti. Turnstile on Cloudflaren tuote, ja
  sitä käytetään sellaisen CAPTCHAn sijaan, joka profiloisi sinut. Turnstile ja DNS:mme ovat
  ainoat asiat, joita Cloudflare enää meille tekee; välitin itse toimii nykyään Firebasessa.
  Katso [Cloudflaren tietosuojaseloste](https://www.cloudflare.com/privacypolicy/).
- IP-osoitettasi käytetään myös pyyntöjen **rajoittamiseen** (rate limit) — tipin lähettämiseen,
  tippisivun luomiseen, laitteenlisäyskoodin lunastamiseen. Sitä varten säilytämme
  **suolatun kryptografisen tiivisteen IP-osoitteesta**, emme koskaan itse IP-osoitetta, noin
  **kahden tunnin** ajan, ja sen jälkeen se poistetaan. Suola on palvelimen salaisuus: ilman
  sitä koodi kieltäytyy tallentamasta yhtään mitään sen sijaan, että säilyttäisi tiivisteen,
  joka voitaisiin purkaa.
- **Googlen operatiiviset lokit** tallentavat välittimeen tulevien pyyntöjen tekniset
  tiedot — URL-osoitteen, ajoituksen, statuksen — muutaman päivän ajaksi. Koodimme ei
  tarkoituksella lokita nimiä, viestejä, salaisuuksia eikä otsakkeita. Google toimii
  henkilötietojen käsittelijänämme.

### Laskurit

Välitin laskee, **kuinka monta tippiä** tietty tippisivu on välittänyt, jotta voimme
havaita väärinkäytökset ja tietää, käytetäänkö tätä ylipäätään. Se on luku. Se ei sisällä
mitään fanien tietoja.

## Kuka käsittelee mitäkin

| Kuka | Mitä hän saa | Miksi |
| --- | --- | --- |
| **Google (Firebase)** | Tilit, kirjautuneen artistin synkronoidut tiedot, salatun Stripe-avaimen, välittimen, push-tokenit ja niiden toimituksen, palvelinlokit | Valinnainen tili, valinnainen välitin ja push-ilmoitukset |
| **Google Cloud KMS** | Avaimen, joka kietoo kirjautuneen artistin Stripe-salaisuuden (ei koskaan salaisuutta selkokielisenä) | Tallennetun Stripe-avaimen pitäminen lukukelvottomana levossa |
| **Stripe** | Fanin maksutiedot itsenäisenä rekisterinpitäjänä; ja kirjautuneen artistin osalta tippitapahtumat, jotka lähetetään webhookillemme | Korttitipit |
| **Cloudflare** | Fanin IP-osoitteen tippisivun Turnstile-tarkistusta varten. Ja DNS:mme. | Bottien pitäminen poissa tippilomakkeelta |
| **GitHub** | Tämän sivuston lataajan IP-osoitteen ja user-agentin | Sivuston isännöinti |
| **Selaimesi / puhelimesi push-palvelu** (esim. Googlen Chromella) | Push-tokenin ja ilmoituksen sisällön, jos kytkit ilmoitukset päälle | Push-ilmoitusten toimittaminen |
| **Revolut / MobilePay / Monzo** | Kaiken sen, mitä fani tekee heidän omassa sovelluksessaan, maksuviesti mukaan lukien | Nuo maksutavat |

Emme myy mitään kenellekään, eikä tuolla listalla ole ketään muuta.

## Käsittelyn oikeusperuste, jos sellaista tarvitset (GDPR)

- Pyytämäsi tilin ylläpitäminen, omien tietojesi synkronointi omille laitteillesi, Stripe-avaimesi
  säilyttäminen, jotta tippisi tavoittavat historiasi, välittimen ylläpitäminen artistille, joka
  kytki sen päälle, fanin tipin toimittaminen sille näytölle, jolle se oli suunnattu, ja
  kytkemäsi push-ilmoituksen lähettäminen: **pyytämäsi palvelun suorittaminen**.
- Pyyntörajoitukset, Turnstile, tiivistettyihin IP-osoitteisiin perustuvat kiintiöt ja
  laitteiden peruuttaminen: **oikeutettu etu** pitää ilmainen, avoin palvelu hengissä siltä,
  että botit ja petokset tuhoavat sen, ja pitää artistien tilit turvassa.
- Palvelinlokit: **oikeutettu etu** palvelun ylläpitämisessä ja suojaamisessa.

## Asioiden poistaminen

Tämä merkitsee enemmän kuin mikään lupaus, jonka voisimme siitä antaa, joten tässä on
tarkalleen se, mitä tänään on olemassa — mukaan lukien se, mitä ei ole.

- **Ei tiliä**: poista sovellus. Siinä kaikki, ja kaikki on poissa.
- **Bändi**: bändin poistaminen sovelluksessa poistaa sen bändin pilvitiedot — sen asetukset,
  sen avaimet, sen sessiot, sen tippihistorian — samoin kuin laitteella olevan kopion.
- **Tippisivu**: poista se tai luo se uudelleen sovelluksessa, ja se pyyhitään välittimestä
  heti, kaikki odottavat tipit mukaan lukien.
- **Push-ilmoitukset**: kytke ne pois laitteella, ja sen push-token poistetaan. Ilmoitussyöte
  tyhjenee bändin tai tilin mukana.
- **Laite**: Asetukset → Turvallisuus listaa laitteesi. Voit perua yhden tai kirjautua ulos
  kaikkialta muualta — mikä päättää jokaisen muun laitteen istunnon välittömästi, ei joskus.
- **Koko tilisi yhdellä napautuksella: sovelluksessa ei ole vielä tuota nappia.** Myönnämme sen
  mieluummin kuin teeskentelemme muuta. Kunnes se on olemassa, kirjoita osoitteeseen
  **[contact@live.tips](mailto:contact@live.tips)**, niin poistamme tilin ja kaiken sen alta
  käsin. Sillä välin voit jo poistaa jokaisen bändin, mikä poistaa kaiken olennaisen — mukaan
  lukien tallennetun Stripe-avaimen — ja jättää jäljelle tyhjän tilin.

## Oikeutesi

Voit pyytää meiltä kopion sinusta säilyttämistämme tiedoista, niiden oikaisua tai poistamista,
ja voit tehdä valituksen kansalliselle tietosuojaviranomaiselle. Kirjoita osoitteeseen
**[contact@live.tips](mailto:contact@live.tips)**.

Käytännössä suurin osa siitä on jo omissa käsissäsi: artisti voi poistaa tippisivun tai bändin
sovelluksesta välittömästi, toimittamatta jääneet fanien tipit tilittömällä sivulla haihtuvat
tunnin sisällä, ja jos et koskaan kirjaudu sisään, mikään siitä ei ole koskaan ollut missään
muualla kuin omalla laitteellasi.

## Lapset

live.tips ei ole suunnattu lapsille, emmekä tietoisesti käsittele heidän tietojaan.

## Muutokset

Päivitämme tämän sivun, kun ohjelmisto muuttuu. Koska koko projekti on avointa lähdekoodia,
**tämän selosteen jokainen aiempi versio on julkisessa git-historiassa** — voit katsoa
tarkalleen, mikä muuttui ja milloin.

## Kieli

Tämä seloste julkaistaan kaikilla sivuston tukemilla kielillä helpottaaksemme lukemista. Jos
käännös ja englanninkielinen versio ovat ristiriidassa, **englanninkielinen versio on se, joka
ratkaisee**.
