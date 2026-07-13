---
title: Tietosuojaseloste
description: live.tips ei käytä evästeitä, analytiikkaa eikä seurantaa, ja se toimii täysin ilman tiliä. Jos päätät kirjautua sisään, tässä on tarkalleen se, mitä tallennetaan, minne, kenen toimesta ja kuinka kauan.
updated: 2026-07-13
updated_label: Päivitetty viimeksi 13. heinäkuuta 2026
---

live.tips on avoimen lähdekoodin tippipurkki esiintyjille. Sitä ylläpitää **Nikita Rabykin**,
yksityinen kehittäjä, ei yritys. Jos jokin alla olevista asioista askarruttaa sinua, kirjoita
osoitteeseen **[contact@live.tips](mailto:contact@live.tips)** — se tavoittaa oikean ihmisen.

Tämä seloste on rehellinen myös tylsien osien kohdalla. Sanomme mieluummin ”säilytämme
nimesi enintään yhden tunnin” kuin väitämme, ettemme säilytä mitään, ja olemme väärässä.

## Lyhyt versio

- **Tili on valinnainen.** Sovellus toimii täysin ilman tiliä, ja se on edelleen oletus. Jos
  haluat bändisi ja historiasi toiselle laitteelle, voit kirjautua sisään — ja silloin osa
  siitä tallentuu palvelimelle. Mikä on mitäkin, kerrotaan alla.
- **Ei evästeitä.** Ei yhtäkään, ei missään.
- **Ei analytiikkaa, ei seurantaa, ei mainoksia, ei kolmannen osapuolen skriptejä** tällä
  sivustolla.
- **Emme koskaan koske rahoihisi.** Tipit kulkevat suoraan fanilta artistin omalle
  Stripe-, Revolut-, MobilePay- tai Monzo-tilille. Me emme ole siinä polussa.
- **Oletusasetuksilla sovellus puhuu vain Stripen kanssa** — ei minkään live.tips-palvelimen.
- Ainoa palvelin, jota ylipäätään ylläpidämme, on pieni välitin Googlen Firebasessa. Se on
  olemassa, jos artisti kytkee päälle Revolutin, MobilePayn tai Monzon — tai jos hän kirjautuu
  sisään.

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
- **Tippihistoria, sessiohistoria, tavoite ja sovelluksen asetukset** tallennetaan laitteen
  paikalliseen tallennustilaan. Tähän sisältyvät nimet ja viestit, jotka fanit liittävät
  tippeihinsä.
- Sovelluksen poistaminen poistaa kaiken tämän. Meidän puolellamme ei ole pilvivarmuuskopiota,
  koska tässä tilassa meidän puolellamme ei ole pilveä.

**Me emme koskaan vastaanota mitään tästä.** Sovelluksessa ei ole analytiikan SDK:ta, ei
kaatumisraportointia, ei push-ilmoituksia eikä mainoskoodia — ei lainkaan, ei edes pois
kytkettyinä.

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
  välitysosoitteen.)
- **Vierastili** — anonyymi tili ilman sähköpostia ja ilman nimeä. Se synkronoi ja sen voi
  perua, mutta sitä ei voi palauttaa millään, jos laite katoaa. Se on uid eikä mitään muuta.

Kun olet kirjautunut sisään, tili saa oman yksityisen nurkkansa Googlen **Cloud
Firestore** -tietokannasta, polusta `users/<your uid>/`. Tietoturvasäännöt myöntävät sen nurkan
tälle uid:lle **eikä kenellekään muulle** — mikään toinen tili ei voi lukea sitä, ei myöskään
URL-osoitteita arvaamalla. Sen sisällä on:

| Mitä | Miksi se on siellä |
| --- | --- |
| **Bändisi** — nimet, tippipurkin ja maksutapojen asetukset, julisteen tekstit, tavoitteet | jotta bändi on olemassa jokaisella laitteella, jolle kirjaudut |
| **Stripen rajoitettu avaimesi** ja välittimen tippisivun salaisuus | salaisuusdokumentissa, jonka vain sinun uid:si voi lukea, ja välimuistissa kunkin laitteesi avainnipussa |
| **Sovelluksen asetukset** | jotta lisäämäsi laite on jo valmiiksi konfiguroitu |
| **Sessiotietueet ja tippihistoria** — mukaan lukien **nimet ja viestit, jotka fanit liittävät tippeihinsä** | koska juuri tuota historiaa pyysit näkyviin toiselle laitteelle |
| Parhaillaan käynnissä oleva **live-sessio** | jotta toinen ruutu voi liittyä tämän illan settiin |
| **Laitteesi** — nimi, jonka kukin niistä itselleen antaa (”Nikitan iPhone”), sen alusta ja malli, milloin se nähtiin ensimmäisen ja viimeisen kerran | jotta Asetukset → Turvallisuus voi listata ne ja voit perua jonkin niistä |
| Pieni **profiilidokumentti** — valitsemasi tilinimi ja käyttämäsi palveluntarjoaja | jotta tilinvaihdin osaa nimetä sen |

Ja nyt se tärkeä osa, suoraan sanottuna: **ilman tiliä fanin nimi ja viesti eivät koskaan
poistu artistin laitteelta. Tilin kanssa ne tallennetaan Googlen palvelimille artistin uid:n
alle, osana kyseisen artistin omaa synkronoitua historiaa.** Mikään toinen tili ei voi lukea
niitä, me emme katso niitä, eikä niistä johdeta mitään — mutta ne ovat siellä, ja se on hyvä
tietää ennen kuin kirjaudut sisään.

Uloskirjautuminen palauttaa laitteen paikalliseen tilaan. Se ei poista tilin tietoja — katso
*Asioiden poistaminen* alta.

### Laitteen lisääminen QR-koodilla

Laitteen lisäämiseksi näytät QR-koodin laitteelta, joka on jo kirjautuneena. Koodi on
satunnainen, **kertakäyttöinen ja vanhenee kahdessa minuutissa**, eikä uusi laite saa mitään
ennen kuin napautat *vahvista* vanhalla. Niin kauan kuin tämä kättely on auki, säilytämme
koodin, uuden laitteen itselleen antaman nimen ja sen alustan — ja tietue poistetaan, kun
koodi vanhenee. Valokuvattu QR-koodi on hyödytön ilman sinun vahvistusnapautustasi.

## Missä kaikki tämä fyysisesti sijaitsee

Firebase Auth, Cloud Firestore ja Cloud Functions -funktiomme toimivat **Euroopan unionissa** —
tietokanta Googlen `eur3`-monialueella, funktiot alueella `europe-west1`. Google toimii
henkilötietojen käsittelijänämme
[Firebasen tietosuoja- ja tietoturvaehtojen](https://firebase.google.com/support/privacy) ja
oman [tietosuojaselosteensa](https://policies.google.com/privacy) mukaisesti. Kuten mikä tahansa
suuri palveluntarjoaja, Google voi käyttää EU:n ulkopuolista infrastruktuuria tukeen ja
tietoturvaan; sitä säätelevät nuo ehdot, emme me.

## Stripe

Kun fani maksaa kortilla, hän on **Stripen** kassasivulla, ei meidän. Stripe kerää ja
käsittelee hänen maksutietonsa itsenäisenä rekisterinpitäjänä
[Stripen tietosuojaselosteen](https://stripe.com/privacy) mukaisesti. Me emme koskaan näe
korttinumeroita, eikä meillä ole pääsyä artistin Stripe-tilille.

Artistin sovellus lukee hänen omat tippinsä Stripestä artistin omalla rajoitetulla avaimella —
suoraan laitteelta osoitteeseen `api.stripe.com`. **Siinä polussa ei ole live.tips-palvelinta,
eikä koskaan ollutkaan.** Fanin nimi ja viesti, jos hän jätti sellaisen, kulkevat Stripestä
artistin laitteelle ja pysähtyvät siihen — ellei artisti ole kirjautunut sisään, jolloin laite
tallentaa ne myös kyseisen artistin omaan Firestore-historiaan, kuten yllä.

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
Revolut-käyttäjänimensä, MobilePay Box ID:nsä, Monzo-käyttäjänimensä). Kaikki tämä on tietoa,
jonka artisti joka tapauksessa tarkoituksella julkaisee faneille.

- **Säilytysaika: tippisivu, jonka takana ei ole tiliä, poistetaan automaattisesti 90 päivän
  käyttämättömyyden jälkeen.** Kirjautuneelle tilille kuuluva tippisivu elää yhtä kauan kuin
  bändi, jolle se kuuluu.
- Artisti voi poistaa sen **välittömästi** sovelluksesta, milloin tahansa.
- Täällä ei kerätä sähköpostiosoitetta, salasanaa, virallista nimeä eikä pankkitietoja.
- Sivun salaisuus säilytetään **vain tiivisteenä**. Emme voisi kertoa sinulle salaisuutta,
  vaikka kysyisit; voimme ainoastaan tarkistaa yhden.

### Mitä fani lähettää

Tippilomake kysyy **summan** ja valinnaisesti **nimen** ja **viestin**. Siinä on koko lomake.
Ei sähköpostia, ei puhelinnumeroa, ei tiliä.

- Tippi kirjoitetaan **toimitusjonoon** — yhteen dokumenttiin, joka on olemassa vain
  luovutettavaksi artistin näytölle. Kun näyttö näyttää tipin, **artistin laite poistaa tuon
  dokumentin.** Poisto *on* kuittaus; ”toimitettu”-merkintää ei ole, koska ei ole jäljellä
  tietuetta, jota merkitä.
- Jos artistin näyttö on poissa verkosta — puhelin lukossa, ei kenttää — tippi **odottaa siinä
  jonossa enintään yhden tunnin**, jottei se yksinkertaisesti katoa, ja menee perille sillä
  hetkellä, kun näyttö palaa yhteyteen. Jos kukaan ei palaa yhteyteen, se **poistetaan
  kenenkään näkemättä**, ajastetusti pyyhkäistynä riippumatta siitä, tuliko kukaan koskaan
  hakemaan sitä.
- **Tuo jono on ainoa paikka, jossa fanin kirjoittamaa tekstiä koskaan säilytetään
  palvelimellamme, ja yksi tunti on sen ehdoton yläraja.** Jos artisti on kirjautunut sisään,
  hänen laitteensa säilyttää tipin sen jälkeen *hänen* Firestore-historiassaan — koska se on
  hänen historiansa, ja juuri sitä varten hän kirjautui.
- Nimesi ja viestisi sijoitetaan myös **maksuviestiin**, joka avautuu Revolutissa,
  MobilePayssa tai Monzossa — juuri siten artisti tietää, kuka tippasi. Nuo yhtiöt käsittelevät
  sen sitten omien tietosuojaselosteidensa mukaisesti.
- Välitin ei säilytä **mitään tippihistoriaa**. Se ei voi näyttää sinulle, meille eikä
  kenellekään muulle listaa siitä, kuka tippasi kenelle.

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
| **Google (Firebase)** | Tilit, kirjautuneen artistin synkronoidut tiedot, välittimen, palvelinlokit | Valinnainen tili ja valinnainen välitin |
| **Stripe** | Fanin maksutiedot, itsenäisenä rekisterinpitäjänä | Korttitipit |
| **Cloudflare** | Fanin IP-osoitteen tippisivun Turnstile-tarkistusta varten. Ja DNS:mme. | Bottien pitäminen poissa tippilomakkeelta |
| **GitHub** | Tämän sivuston lataajan IP-osoitteen ja user-agentin | Sivuston isännöinti |
| **Revolut / MobilePay / Monzo** | Kaiken sen, mitä fani tekee heidän omassa sovelluksessaan, maksuviesti mukaan lukien | Nuo maksutavat |

Emme myy mitään kenellekään, eikä tuolla listalla ole ketään muuta.

## Käsittelyn oikeusperuste, jos sellaista tarvitset (GDPR)

- Pyytämäsi tilin ylläpitäminen, omien tietojesi synkronointi omille laitteillesi, välittimen
  ylläpitäminen artistille, joka kytki sen päälle, ja fanin tipin toimittaminen sille näytölle,
  jolle se oli suunnattu: **pyytämäsi palvelun suorittaminen**.
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
- **Laite**: Asetukset → Turvallisuus listaa laitteesi. Voit perua yhden tai kirjautua ulos
  kaikkialta muualta — mikä päättää jokaisen muun laitteen istunnon välittömästi, ei joskus.
- **Koko tilisi yhdellä napautuksella: sovelluksessa ei ole vielä tuota nappia.** Myönnämme sen
  mieluummin kuin teeskentelemme muuta. Kunnes se on olemassa, kirjoita osoitteeseen
  **[contact@live.tips](mailto:contact@live.tips)**, niin poistamme tilin ja kaiken sen alta
  käsin. Sillä välin voit jo poistaa jokaisen bändin, mikä poistaa kaiken olennaisen ja jättää
  jäljelle tyhjän tilin.

## Oikeutesi

Voit pyytää meiltä kopion sinusta säilyttämistämme tiedoista, niiden oikaisua tai poistamista,
ja voit tehdä valituksen kansalliselle tietosuojaviranomaiselle. Kirjoita osoitteeseen
**[contact@live.tips](mailto:contact@live.tips)**.

Käytännössä suurin osa siitä on jo omissa käsissäsi: artisti voi poistaa tippisivun tai bändin
sovelluksesta välittömästi, toimittamatta jääneet fanien tipit haihtuvat tunnin sisällä, ja jos
et koskaan kirjaudu sisään, mikään siitä ei ole koskaan ollut missään muualla kuin omalla
laitteellasi.

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
