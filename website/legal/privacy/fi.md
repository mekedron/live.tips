---
title: Tietosuojaseloste
description: live.tips ei käytä tilejä, evästeitä, analytiikkaa eikä seurantaa. Tässä on lyhyt lista siitä, mitä oikeasti käsitellään, kenen toimesta ja kuinka kauan.
updated: 2026-07-13
updated_label: Päivitetty viimeksi 13. heinäkuuta 2026
---

live.tips on avoimen lähdekoodin tippipurkki esiintyjille. Sitä ylläpitää **Nikita Rabykin**,
yksityinen kehittäjä, ei yritys. Jos jokin alla olevista asioista askarruttaa sinua, kirjoita
osoitteeseen **[contact@live.tips](mailto:contact@live.tips)** — se tavoittaa oikean ihmisen.

Tämä seloste on rehellinen myös tylsien osien kohdalla. Sanomme mieluummin ”säilytämme
nimesi enintään yhden tunnin” kuin väitämme, ettemme säilytä mitään, ja olemme väärässä.

## Lyhyt versio

- **Ei tilejä.** Mihinkään ei tarvitse rekisteröityä.
- **Ei evästeitä.** Ei yhtäkään, ei missään.
- **Ei analytiikkaa, ei seurantaa, ei mainoksia, ei kolmannen osapuolen skriptejä** tällä
  sivustolla.
- **Emme koskaan koske rahoihisi.** Tipit kulkevat suoraan fanilta artistin omalle
  Stripe-, Revolut-, MobilePay- tai Monzo-tilille. Me emme ole siinä polussa.
- **Oletusasetuksilla sovellus puhuu vain Stripen kanssa** — ei minkään live.tips-palvelimen.
- Ainoa palvelin, jota ylipäätään ylläpidämme, on pieni välitin, ja se on olemassa vain,
  jos artisti kytkee päälle Revolutin, MobilePayn tai Monzon.

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

## Sovellus

live.tips-sovellus toimii **artistin omalla laitteella**. Kaikki, minkä se tietää, sijaitsee
siellä:

- **Stripen rajoitettu avain** tallennetaan laitteen avainnippuun (iOS-/macOS-Keychain,
  Android Keystore) ja se lähetetään ainoastaan osoitteeseen `api.stripe.com`.
- **Tippihistoria, sessiohistoria, tavoite ja sovelluksen asetukset** tallennetaan laitteen
  paikalliseen tallennustilaan. Tähän sisältyvät nimet ja viestit, jotka fanit liittävät
  tippeihinsä.
- Sovelluksen poistaminen poistaa kaiken tämän. Meidän puolellamme ei ole pilvivarmuuskopiota,
  koska meidän puolellamme ei ole pilveä.

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

## Stripe

Kun fani maksaa kortilla, hän on **Stripen** kassasivulla, ei meidän. Stripe kerää ja
käsittelee hänen maksutietonsa itsenäisenä rekisterinpitäjänä
[Stripen tietosuojaselosteen](https://stripe.com/privacy) mukaisesti. Me emme koskaan näe
korttinumeroita, eikä meillä ole pääsyä artistin Stripe-tilille.

Artistin sovellus lukee hänen omat tippinsä Stripestä artistin omalla rajoitetulla avaimella.
Fanin nimi ja viesti, jos hän jätti sellaisen, kulkevat Stripestä artistin laitteelle ja
pysähtyvät siihen.

## Välitin — vain jos Revolut, MobilePay tai Monzo on kytketty päälle

Pelkkää Stripeä käyttävät kokoonpanot eivät koskaan koske tähän, ja voivat lopettaa lukemisen
tähän.

Revolut, MobilePay ja Monzo eivät tarjoa sovellukselle mitään tapaa vahvistaa, että maksu
tapahtui, joten nuo tipit reititetään pienen avoimen lähdekoodin välittimen kautta, jota
ylläpidämme **Cloudflaressa** osoitteessa `api.live.tips`. Se ei koskaan koske rahaan. Tässä
on kaikki, mitä se käsittelee.

### Mitä artisti tallentaa

Tippisivun luominen tallentaa artistin **näyttönimen, hänen julkisen viestinsä, hänen
valuuttansa ja ne maksutunnisteet, jotka hän valitsi julkaista** (hänen Stripe-maksulinkkinsä,
Revolut-käyttäjänimensä, MobilePay Box ID:nsä, Monzo-käyttäjänimensä). Kaikki tämä on tietoa,
jonka artisti joka tapauksessa tarkoituksella julkaisee faneille.

- **Säilytysaika: poistetaan automaattisesti 90 päivän käyttämättömyyden jälkeen.**
- Artisti voi poistaa sen **välittömästi** sovelluksesta, milloin tahansa.
- Sähköpostiosoitetta, salasanaa, virallista nimeä tai pankkitietoja ei koskaan kerätä.

### Mitä fani lähettää

Tippilomake kysyy **summan** ja valinnaisesti **nimen** ja **viestin**. Siinä on koko lomake.
Ei sähköpostia, ei puhelinnumeroa, ei tiliä.

- Jos artistin näyttö on **verkossa**, tippi välitetään suoraan sille eikä sitä **koskaan
  kirjoiteta levylle**.
- Jos artistin näyttö on **poissa verkosta** — puhelin lukossa, ei kenttää — tippiä
  **säilytetään tallennustilassa enintään yhden tunnin**, jottei se yksinkertaisesti katoa,
  ja se luovutetaan heti kun näyttö palaa yhteyteen. Jos kukaan ei palaa yhteyteen, se
  **poistetaan kenenkään näkemättä**. Tämä on ainoa fanin kirjoittama teksti, jota välitin
  koskaan tallentaa, ja yksi tunti on sen ehdoton yläraja.
- Nimesi ja viestisi sijoitetaan myös **maksuviestiin**, joka avautuu Revolutissa,
  MobilePayssa tai Monzossa — juuri siten artisti tietää, kuka tippasi. Nuo yhtiöt käsittelevät
  sen sitten omien tietosuojaselosteidensa mukaisesti.
- Välitin ei säilytä **mitään tippihistoriaa**. Se ei voi näyttää sinulle, meille eikä
  kenellekään muulle listaa siitä, kuka tippasi kenelle.

### IP-osoitteet ja väärinkäytösten torjunta

Avoin lomake, johon kuka tahansa voi lähettää, tarvitsee jonkinlaisen suojan botteja vastaan,
joten:

- IP-osoitettasi käytetään pyyntöjen **rajoittamiseen** (rate limit), ja se lähetetään
  **Cloudflare Turnstilelle** (tippisivulla ajettava bottitarkistus) sen varmistamiseksi,
  ettet ole botti. Turnstile on Cloudflaren tuote, ja sitä käytetään sellaisen CAPTCHAn
  sijaan, joka profiloisi sinut.
- Jotta kukaan ei loisi tuhansia tippisivuja, tippisivun luojan **IP-osoitteen kryptografinen
  tiiviste** säilytetään noin **kaksi tuntia**, ja hylätään sen jälkeen.
- **Cloudflaren operatiiviset lokit** tallentavat välittimeen tulevien pyyntöjen tekniset
  tiedot — URL-osoitteen, ajoituksen, statuksen — muutaman päivän ajaksi. Ne eivät sisällä
  fanien nimiä tai viestejä. Cloudflare toimii henkilötietojen käsittelijänämme; katso
  [Cloudflaren tietosuojaseloste](https://www.cloudflare.com/privacypolicy/).

### Laskurit

Välitin laskee, **kuinka monta tippiä** tietty tippisivu on välittänyt, jotta voimme
havaita väärinkäytökset ja tietää, käytetäänkö tätä ylipäätään. Se on luku. Se ei sisällä
mitään fanien tietoja.

## Käsittelyn oikeusperuste, jos sellaista tarvitset (GDPR)

- Välittimen ylläpitäminen artistille, joka kytki sen päälle, ja fanin tipin toimittaminen
  sille näytölle, jolle se oli suunnattu: **pyytämäsi palvelun suorittaminen**.
- Pyyntörajoitukset, Turnstile ja tiivistettyihin IP-osoitteisiin perustuvat kiintiöt:
  **oikeutettu etu** pitää ilmainen, avoin palvelu hengissä siltä, että botit ja petokset
  tuhoavat sen.
- Palvelinlokit: **oikeutettu etu** palvelun ylläpitämisessä ja suojaamisessa.

## Oikeutesi

Voit pyytää meiltä kopion sinusta säilyttämistämme tiedoista, niiden oikaisua tai poistamista,
ja voit tehdä valituksen kansalliselle tietosuojaviranomaiselle. Kirjoita osoitteeseen
**[contact@live.tips](mailto:contact@live.tips)**.

Käytännössä suurin osa siitä on jo omissa käsissäsi: artistit voivat poistaa tippisivunsa
sovelluksesta välittömästi, fanien tipit haihtuvat tunnin sisällä, ja kaikki muu sijaitsee
omalla laitteellasi.

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
