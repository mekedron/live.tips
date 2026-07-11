---
title: Rakenna tippipurkki omalle Stripe-tilillesi
description: Kolme API-kutsua antaa sinulle isännöidyn maksa-mitä-haluat-sivun Apple Paylla ja Google Paylla — ilman yhtäkään palvelinta. Tässä on koko rakennus: rajoitettu avain, oikeudet, miten luet tipit sisään ilman webhookia, ja se maksurehellisyys, jota kukaan ei painata.
slug: rakenna-tippipurkki-omalle-stripe-tilillesi
---

Haluat tippipurkin. Et halua antaa alustalle 5 % katusoittajan illasta, ja pärjäät oikein
hyvin API:n kanssa. Kysymys ei siis ole *mihin tippipurkkiin rekisteröidyn*, vaan *kuinka
paljon minun oikeasti pitää rakentaa*.

Vähemmän kuin luulet. Stripessä toimiva vastaus on kolme API-kutsua: ei palvelinta, ei
backendiä, ei webhook-päätepistettä. Loppu tästä kirjoituksesta on juuri se rakennus — plus
ne kaksi asiaa, jotka kaikki tekevät väärin.

## Koko temppu on maksa-mitä-haluat-Price

Stripessä on hinnoittelutila, jossa fani näppäilee summan itse. Se on nimeltään
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want), ja se on koko
ominaisuus. Luot Productin, ripustat siihen Pricen asetuksella
`custom_unit_amount[enabled]=true`, ja päälle
[Payment Linkin](https://docs.stripe.com/payment-links/create).

```sh
# 1. se juttu, jota "myyt"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. hinta, jonka fani saa valita
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. sivu
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=donate
```

Kolmas kutsu palauttaa `url`-kentän. Se URL *on* tippipurkkisi. Se on Stripen isännöimä sivu:
PCI-yhteensopiva ilman että sinun tarvitsee ajatella sitä, lokalisoitu, ja se näyttää Apple Payn
tai Google Payn jokaiselle fanille, jonka puhelimessa ne on käytössä —
[dynaamiset maksutavat](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
päättävät sen puolestasi laitteen ja maan perusteella. Et kirjoittanut lainkaan frontendia.

Koodaa URL QR-koodiksi millä tahansa kirjastolla — se on vain merkkijono — tulosta se, teippaa
kotelon kylkeen. Koodi ei vanhene koskaan, eikä se osoita mihinkään omaan palvelimeesi, koska
sinulla ei ole sellaista.

Kaksi parametria, jotka kannattaa tuntea:

- **`custom_unit_amount[preset]`** on summa, jolla sivu avautuu. `500` tarkoittaa, että fani näkee
  5,00 € valmiiksi täytettynä ja voi muuttaa sen. Tämä luku tekee keskimääräiselle tipillesi enemmän
  kuin mikään muu sivulla.
- **`custom_unit_amount[minimum]`** on lattia. Aseta se. Syy on alempana maksuja käsittelevässä
  osiossa, eikä kyse ole pyöristysvirheestä.

Voit myös kerätä nimen ja viestin. Payment Link ottaa enintään kolme `custom_fields`-kenttää — näin saat
"keneltä tuo tuli" sivulle ilman lomakkeen rakentamista:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Nimesi tai lempinimesi" \
  -d "custom_fields[0][optional]"=true
```

Stripellä on [vaatimukset tippien ja lahjoitusten vastaanottamiselle](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
lue ne kerran. Maksa-mitä-haluat ei myöskään yhdisty muihin line itemeihin, alennuksiin tai toistuviin
maksuihin. Tippipurkille mikään noista ei haittaa.

## Avain: oleta että se vuotaa — ja tee siitä tylsää

Älä laita salaista avainta (`sk_live_…`) laitteeseen, joka seisoo lavalla. Käytä
[rajoitettua avainta](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): valitset
oikeuden resurssikohtaisesti, ja kaikki mitä et valitse jää **None**-tilaan.

Yllä olevaan rakennukseen koko lista on viisi riviä:

| Resurssi | Oikeus | Mihin se tarvitaan |
| --- | --- | --- |
| Products | Write | luoda Product |
| Prices | Write | luoda maksa-mitä-haluat-Price |
| Payment Links | Write | luoda linkki |
| Checkout Sessions | Read | nähdä saapuneet tipit |
| Events | Read | live-syöte (seuraava osio) |

Kaikki muu — Balance, Payouts, Refunds, Customers, PaymentIntents, koko Connect — jää **None**-tilaan.

Tee nyt se harjoitus, joka tekee tästä vaivan arvoista. Tablettisi viedään merch-pöydältä yhdeltä yöllä.
Mitä varas tekee avaimella, joka on sen keychainissa? Lukee tippihistoriasi ja luo tilillesi lisää
tippilinkkejä. Siinä on koko räjähdyssäde. Hän ei näe saldoasi, ei voi laukaista tilitystä, ei voi tehdä
hyvitystä hallitsemalleen kortille, ei voi lukea asiakaslistaa. Peruutat avaimen puhelimella taksissa
kotimatkalla, ja laite pimenee. Rahoistasi ei ole liikkunut mitään.

Tämä epäsymmetria — kirjoitusoikeus tippipurkkiin, nolla pääsyä rahoihin — on ainoa syy, miksi palvelimeton,
tuo-oma-avaimesi-suunnittelu on ylipäätään puolustettavissa. Se on myös syy siihen, miksei "Login with Stripe"
ole tässä vastaus: OAuth vaatii sovelluskehittäjän omistaman palvelimen pitämään tokeniasi — ja palvelin on
juuri se, mitä emme rakenna.

(Erikoisuus, johon törmäät: *Prices*-oikeuden sisäinen nimi on `plan_write`, joten Stripen virheilmoitus nimeää
scopen, jota ei sillä nimellä hallintapaneelissa ole. Kyse on Pricesista.)

## Tippien lukeminen ilman webhookia

Tässä useimmat oppaat joko lopettavat tai tarttuvat webhookiin — ja tässä lava todella eroaa
verkkosovelluksesta.

Webhook on saapuva HTTP-pyyntö. Mikrofonitelineen takana oleva tabletti ei voi vastaanottaa sellaista. Se roikkuu
paikan vierasverkossa NATin takana, sillä ei ole julkista osoitetta eikä TLS-varmennetta — eikä sillä ole mitään
asiaa niihin. Jos valitset webhook-tien, sinun on pystytettävä palvelin nappaamaan tapahtumat ja socket työntämään
ne laitteeseen: backend, ylläpitotaakka ja paikka, jossa faniesi nimet nyt asuvat. Rakensit juuri uudelleen sen
alustan, jota yritit välttää.

Vedä siis sen sijaan, että sinua työnnetään. Stripen päätepiste
[List all events](https://docs.stripe.com/api/events/list) on julkinen, dokumentoitu ja palauttaa tapahtumat uusin
ensin:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_VIIMEISIN_NAKEMANI \
  -d limit=100
```

`ending_before` on koko suunnittelu. Pidä tallessa käsittelemäsi uusimman tapahtuman id; jokainen kysely pyytää kaiken
tiukasti uudemman, ja sinä siirrät kursoria. Ei aikaleimoja, ei kellon ryömintää, ei summaan perustuvaa
kaksoiskappaleiden karsintaa. Setin ensimmäisessä kyselyssä pyydä `limit=1` ilman kursoria ankkuroituaksesi siihen,
mitä jo on — muuten soundcheckissä toistat aamun tipit uudelleen.

Suodata sitten se, mikä palaa. Molemmat tapahtumatyypit voivat laueta yhdestä maksusta, joten karsi kaksoiskappaleet
Checkout Sessionin id:n perusteella. Tarkista `payment_status == "paid"` — valmistunut sessio ei ole välttämättä
maksettu. Ja tarkista, että `payment_link` vastaa *sinun* linkkiäsi, sillä `/v1/events` koskee koko tiliä ja ojentaa
sinulle auliisti liikenteen kaikesta muusta, mitä se Stripe-tili tekee.

Ole rehellinen kompromisseista, sillä ne ovat todellisia:

- **Stripe suosittelee webhookeja.** Pollaus ei ole siunattu polku; se on dokumentoitu päätepiste, jota käytetään
  tietoisesti. Kirjoita se README:hesi ja jatka matkaa.
- **Tapahtumat ulottuvat 30 päivää taakse.** [Stripen omat sanat](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Tämä on live-syöte, ei kirjanpitosi. Kirjanpitosi ovat Checkout Sessionit
  — ja oikea kirjanpitosi on Stripen hallintapaneeli.
- **Vahdi lukukiintiötä.** Kaikki katsovat sekuntikohtaista rajaa
  ([rate limits](https://docs.stripe.com/rate-limits): 100 pyyntöä/s live-tilassa) eikä kukaan sitä toista: Stripe
  myöntää noin **500 lukupyyntöä per tapahtuma** liukuvalla 30 päivän jaksolla, ja lattia on 10 000 lukua kuussa.
  Pollaa 4 sekunnin välein, ja kolmen tunnin setti on ~2 700 lukua. Neljä pitkää keikkaa kuussa, ja olet lattiassa.
  Tipit ostavat sinulle liikkumavaraa saapuessaan — mutta se, joka pollaa sekunnin välein, koska se tuntui nopeammalta,
  löytää katon. Neljä sekuntia ei ole laiska luku; se *on* se luku.

Tältä se rehellisesti näyttää: pollaus maksaa sinulle pari tuhatta GET-pyyntöä ja ostaa sinulle kokonaisen backendin
poistamisen.

## Maksulaskelma, kunnolla tehtynä

Alusta, joka mainostaa 0 %:a, ei ole ilmainen — eikä tämäkään ole. Stripen oma käsittelymaksu koskee jokaista tippiä, ja
Stripe veloittaa sen suoraan sinulta. Tänään [Stripen eurohinnoittelun](https://stripe.com/ie/pricing) mukaan tavallinen
ETA-kortti maksaa **1,5 % + 0,25 €**. Premium-ETA-kortit 1,9 % + 0,25 €, brittikortit 2,5 % + 0,25 €, ja kaikki muu
3,25 % + 0,25 € sekä vielä 2 %, jos valuutta pitää muuntaa. (Yhdysvalloissa se on 2,9 % + 0,30 $, mikä on huonompi juuri
alla olevasta syystä.)

Prosentti ei ole ongelma. Ne kaksikymmentäviisi senttiä ovat.

| Tippi | Stripe ottaa | Artistille jää | Todellinen leikkaus |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Kiinteä maksu on prosentti valeasussa, ja pienissä rahoissa valeasu luiskahtaa. Samat 0,25 €, jotka ovat näkymättömiä
50 euron tipissä, syövät kahden euron tipistä kahdeksasosan. Tipit ovat luonnostaan pieniä — juuri se tekee niistä tippejä —
joten tämä ei ole reunatapaus, vaan mediaanitapaus.

Juuri siksi asetat `custom_unit_amount[minimum]`-arvon. Jossain 2 euron tienoilla tapahtuma lakkaa olemasta käsittelyn
arvoinen; 0,50 euron korttitippi saapuisi 0,24 eurona ja maksaisi Stripelle siirtona enemmän kuin on arvoinen. Valitse
lattiasi tietoisesti sen sijaan, että löytäisit sen ensimmäisessä tilityksessäsi.

Ja huomaa, mitä tämä tekee sille vertailulle, josta lähdit liikkeelle. Alusta, joka ottaa 0 % Stripen päälle, ottaa 0 %
**tämän** päälle. Heidän 0 %:nsa on aito — ja se on 0 % siitä, mitä maksunkäsittelijä jätti jäljelle. Kenenkään korttikisko ei
ole ilmainen: rehellinen väite on "ei leikkausta maksunkäsittelijän leikkauksen päälle", ja se joka väittää enemmän joko
valehtelee tai ei käytä kortteja.

## Mitä sinulla nyt on ja mitä ei

Kolme API-kutsua ja QR-koodi — ja aito tippipurkki: isännöity, PCI-yhteensopiva, Apple Pay, Google Pay, tipit laskeutuvat omalle
Stripe-saldollesi oman tilitysaikataulusi mukaan, eikä matkalla ole yhtään palvelinta. Monelle tämä on vilpittömästi projektin
loppu, ja voit aivan hyvin pysähtyä tähän ja julkaista sen.

Mitä sinulla ei ole, on lava. Sinulla on maksusivu. Niiden välissä seisovat tylsät asiat: pollauslooppi kursoreineen ja
backoffeineen; näyttö, jonka yleisö näkee, tavoitteineen ja viimeisimpine viesteineen; paikka avaimelle, jonka nimi ei ole
`localStorage`; lukitus, jottei vieras näpelöi tablettia settien välissä; ja se tuhannen pienen päätöksen kerros siitä, mitä
tapahtuu, kun paikan wifi tippuu kesken setin.

Sitä [live.tips](https://github.com/mekedron/live.tips) on — täsmälleen tämä arkkitehtuuri, valmiiksi rakennettuna, MIT-lisenssillä.
Rajoitettu avain noine viisine oikeuksineen, `/v1/events`-kursorilooppi, Product/Price/Payment Linkin luonti — kaikki pyörii artistin
laitteella hänen omaa tiliään vasten. Stripen polulla ei ole live.tips-palvelinta eikä missään ole live.tips-saldoa, mistä kirjoitimme
erikseen jutussa [miten live.tips käsittelee rahaa](post:how-live-tips-handles-money).

Lue lähdekoodi, poimi haluamasi palat, tai käytä sitä vain. Tämän kirjoituksen pointti on, että arkkitehtuuri ei ole salaisuus eikä
vaikea: **Stripe isännöi tippipurkkisi ilmaiseksi, ja rajoitettu avain plus pollauslooppi on kaikki, mikä seisoo artistin ja hänen
omien rahojensa välissä.** Mieluummin tiedät sen kuin rekisteröidyt minnekään.
