# Lähimaksutipit katusoittajille, rehellisesti

> Tap to Pay puhelimessa, kortinlukija, NFC-tarra, QR-koodi — neljä eri asiaa, joita kaikkia kutsutaan ”lähimaksuksi”. Mitä kukin niistä oikeasti maksaa vuonna 2026, mitä NFC-tarra todella tekee (ei sitä mitä luulet), ja milloin näppäys voittaa skannauksen.

Canonical: https://live.tips/fi/blog/lahimaksutipit-katusoittajille/
Published: 2026-07-11
Language: fi
Tags: contactless, NFC, QR codes, Tap to Pay, fees

---

Hae lähimaksutipeistä katusoittajille, ja internet ojentaa sinulle vuoden 2018.
Brunel Universityn opiskelijaprototyyppi nimeltä Tiptap — teline, johon puhelin
työnnetään — sai sinä vuonna kierroksen lehdistöä, ja se lehdistö istuu edelleen
ensimmäisellä hakusivulla. Se oli mukava idea. Se oli myös, uutisoinnin omin sanoin,
*yhä kehitysvaiheessa*, ja sen oli tarkoitus periä katusoittajilta kertamaksu sekä
**5 % jokaisesta tipistä**. Siitä ei koskaan tullut mitään, mitä voisi ostaa.

(Se ”tiptap”, jonka löydät jos nyt lähdet etsimään, on täysin eri ontariolainen
yritys, joka myy lähimaksullisia lahjoitusterminaaleja hyväntekeväisyysjärjestöille.
Sama sana, eri tuote, ei sinulle.)

Rehellinen tilannekuva on siis ollut kahdeksan vuotta kirjoittamatta. Tässä se on.

Tämä on syväsukellus vilautukseen. Jos oikea kysymyksesi on se laajempi — miten
katusoittaja ylipäätään saa rahansa nyt kun kukaan ei kanna käteistä, ja mitä kukin
tapa maksaa — aloita jutusta [miten katusoittajat ottavat vastaan
korttimaksuja](https://live.tips/fi/blog/korttimaksut-katusoittajalle/) ja palaa sitten tänne.

## Neljää eri asiaa kutsutaan ”lähimaksuksi”

Tässä asuu suurin osa sekaannuksesta, joten erotellaan ne ennen kuin hinnoittelemme
mitään.

1. **Tap to Pay omassa puhelimessasi.** Puhelimestasi tulee maksupääte. Fani vie
   korttinsa tai kellonsa *sinun* laitettasi vasten. Ei mitään lisälaitteita.
2. **Kortinlukija** — SumUp, Zettle, Square. Pieni muovipääte, jota ojennat. Fani vie
   korttinsa siihen.
3. **NFC-tarra** — se ”näppäytä tähän ja anna tippiä” -tarra tai -kyltti. Tämä
   ymmärretään väärin lähes kaikkialla, ja seuraava luku kertoo miksi.
4. **QR-koodi.** Ei lähimaksu NFC:n mielessä — mutta lue eteenpäin, sillä fanin
   puolelta se päättyy hyvin usein täsmälleen samaan näppäykseen.

Vain kaksi ensimmäistä ovat *maksupäätteitä*. Tuo ero on koko tämän tekstin ydin.

## NFC-tarra ei ota maksua vastaan

Tapetaan tämä kunnolla, koska myyjät antavat mielellään uskoa toisin.

NFC-tarrassa — siinä halvassa lajissa, NTAG213-sirussa, jota useimmat käyttävät — on
**144 tavua muistia**. Ei 144 kilotavua. Se ei osaa ajaa koodia, siinä ei ole
akkua, se ei ole ikinä kuullut korttijärjestelmästä, eikä siihen mahtuisi
maksuprotokolla vaikka se haluaisi. Siihen mahtuu lyhyt merkkijono NDEF-tietueeksi
muotoiltuna, ja ylivoimaisesti useimmiten se merkkijono on **URL**.

Näppäytä sitä, ja puhelin avaa verkkosivun. Siinä on koko ominaisuus.

Mikä tarkoittaa, että ”tap to tip” -kyltti on QR-koodi, jonka avaat koskettamalla
tähtäämisen sijaan. Sama määränpää, sama verkkosivu, sama selaimessa tapahtuva maksu.
Jopa erikoisliikkeet sanovat sen, kun heitä lukee tarkasti: tiptapin omilla sivuilla
kuvataan vapaan summan laitetta niin, että kun lahjoittajat vievät puhelimensa sen
lähelle, *”heidät ohjataan verkkokeräyssivullesi.”* Ohjataan sivulle. Koska juuri sen
tarra osaa.

Tämä on aidosti hyödyllistä, ja se on myös halpaa — tyhjät NTAG213-tarrat alkavat
noin **0,24 $ kappaleelta** pakkauksissa. Jos sinulla on jo tippisivu, tarra kotelon
kanteen painetun koodin viereen maksaa pikkurahaa ja antaa joillekin faneille
nopeamman reitin sisään.

Mutta ole selvillä siitä, mitä ostit: **toisen etuoven samalle sivulle.** Ei
korttikonetta.

### Ja ulkona se on nirso etuovi

Vikatilanteet ovat todellisia, eikä kukaan tarroja myyvä luettele niitä:

- **Fanin puhelimen pitää olla auki ja käytössä.** Applen oma dokumentaatio on
  yksiselitteinen: taustalla tapahtuva tarranluku toimii vain, kun iPhone on
  käytössä, ja jos puhelin on lukittu, järjestelmä pakottaa avaamaan sen ensin.
- **Se ei toimi, kun kamera on auki.** Apple listaa käytössä olevan kameran yhdeksi
  tilaksi, jossa taustalla tapahtuva tarranluku ei ole käytettävissä. Nauti ironiasta:
  fani, joka kaivaa kameran esiin skannatakseen QR-koodisi, on juuri kytkenyt
  NFC-tarrasi pois päältä.
- **Se vaatii iPhone XS:n tai uudemman**, ja Androidissa NFC:n pitää olla päällä —
  minkä jotkin virransäästötilat kytkevät pois.
- **Kantama on noin 4 cm.** Fanin pitää oikeasti koskettaa sitä. Väentungoksessa,
  kitaralaukun ylle kumartuneena, se on paljon pyydetty.
- **Metalli ja magneetit tappavat sen.** Vahvistimeen teipattu tarra, tai fani, jolla
  on magneettinen korttikuori — eikä tapahdu yhtään mitään.

Tarra on hyvä kakkosvaihtoehto. Ainoana vaihtoehtona se on huono.

## Tap to Pay puhelimessa: se todellinen vuoden 2026 uutinen

Tämä on se, mikä on muuttunut Tiptap-juttujen jälkeen ja mistä yksikään vanhentunut
uutinen ei tiedä.

**Tap to Pay iPhonella** muuttaa taskussasi jo olevan puhelimen lähimaksupäätteeksi.
Ei donglea, ei lukijaa, ei telinettä. Apple ilmoittaa sen olevan saatavilla **yli 70
maassa ja alueella**, ja palveluntarjoajat, joiden kautta sitä voi Euroopassa käyttää,
kuulostavat koko toimialalta — pelkästään Saksassa: Adyen, Mollie, myPOS, Nexi,
PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Britannialla, Ranskalla,
Alankomailla, Ruotsilla, Suomella ja Tanskalla on kaikilla samankaltaiset listat.
Tarvitset iPhone XS:n tai uudemman.

**Tap to Pay Androidilla** on myös olemassa, mutta kapeampana. Stripen kautta se on
yleisesti saatavilla maissa AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL,
NZ, PL, SE, SG ja US, ja kahdeksantoista maata lisää on julkisessa esikatselussa.
Puhelimesi tarvitsee Android 13:n tai uudemman, NFC-anturin, rootaamattoman
käynnistyslataimen, Google Mobile Servicesin ja kehittäjäasetukset pois päältä — tuo
viimeinen kaataa useamman kuin luulisi.

Käytännön versio: **SumUp listaa Tap to Payn 0 £:n laitteistolla.** Jos sinulla on
tuore iPhone ja olet tuetussa maassa, lähimaksupäätteen ojentamisen aloituskustannus
on nyt nolla. Jo pelkkä tuo tosiasia tekee jokaisesta vuoden 2018 ”osta tämä teline”
-artikkelista vanhentuneen.

## Kortinlukijat ja mitä ne oikeasti maksavat

Jos haluat erillisen muovipalan — ja siihen on hyviä syitä, alla — markkinat ovat
kolme tuotetta.

| | Laitteisto | Maksu läsnäolomaksusta |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, ei kiinteää maksua |
| **SumUp** (Saksa) | — | **1,39 %**, ei kiinteää maksua |
| **Zettle / PayPal POS** (UK) | Lukija 29 £:sta ensikertalaiselle, 69 £ sen jälkeen | **1,75 %**, ei kiinteää maksua |
| **Square** (UK) | Lähimaksu- ja sirulukija 19 £ | **1,75 %**, ei kiinteää maksua |
| **Square** (US) | Lähimaksu- ja sirulukija 59 $ | **2,6 % + 0,15 $** |

Hinnat ovat ilman arvonlisäveroa ja sellaisina kuin ne oli julkaistu heinäkuussa 2026.
Mene ja tarkista ne; ne liikkuvat.

Lue taulukko nyt uudelleen, koska se sanoo jotain, mikä on ristiriidassa sen kanssa,
mitä sinulle on todennäköisesti kerrottu.

## Maksulaskelma — ja se, minkä kaikki kääntävät väärin päin

Yleinen viisaus on, että korttimaksut tuhoavat pienet tipit tapahtumakohtaisen
kiinteän maksun takia — ne kaksikymmentäviisi senttiä, jotka syövät kahdeksasosan
kahden euron tipistä. Se on totta, ja olemme
[kirjoittaneet laskelman itse auki](https://live.tips/fi/blog/rakenna-tippipurkki-omalle-stripe-tilillesi/).

Mutta se pätee *verkon* korttimaksuihin. **Eurooppalaisissa lähimaksulukijoissa ei
useimmiten ole kiinteää maksua lainkaan.** SumUp, Zettle ja Square ovat Britanniassa
ja EU:ssa puhtaasti prosenttipohjaisia. Mikä tarkoittaa:

| Kahden euron tippi | Maksu | Artistille jää | Todellinen leikkaus |
| --- | --- | --- | --- |
| SumUp-lukija (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, kortti verkossa (ETA, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Square-lukija (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Pelkän maksun perusteella eurooppalainen lähimaksupääte voittaa verkon korttimaksun
pienessä tipissä, eikä kisa ole edes tiukka. Me olemme QR-koodituote, ja sanomme
sinulle silti: kahden euron tipissä SumUp-lukija jättää sinulle 0,25 €, jota
Stripe-isännöity sivu ei jätä.

Kaksi asiaa palauttaa mittasuhteet.

**Laitteisto on kiinteä maksu, vain siirrettynä.** 0,25 euron säästö tippiä kohti 79
punnan Soloa vastaan tarkoittaa suunnilleen **kolmeasataa maksua ennen kuin lukija on
maksanut itsensä takaisin**. Se on oikea luku työkseen soittavalle katusoittajalle ja
tyhmä luku sille, joka soittaa kahdesti kesässä. (Ja SumUpin 0 £:n Tap to Pay tekee
siitä nolla maksua — juuri siksi tuo vaihtoehto merkitsee enemmän kuin lukijat.)

**Ja Yhdysvallat kääntää sen takaisin.** Squaren amerikkalaisessa läsnäolotaksassa on
0,15 dollarin kiinteä maksu, joten kahden dollarin näppäys menettää kymmenyksensä
myös päätteellä. Lahja nimeltä ”ei kiinteää maksua” on eurooppalainen.

Vastaan tulee myös lattia: SumUp ei ota vastaan alle **1 £:n / 1 euron** maksua.
Valitsit minkä kiskon tahansa — hyvin pieni tippi ei oikeastaan ole korttitapahtuma.

## Milloin näppäys siis voittaa skannauksen?

Riisu tekniikka pois, ja jäljelle jää kysymys fanin käsistä.

**Näppäys vaatii, että fanin puhelin on auki ja hänen kädessään, ja että sinä ojennat
jotain.** Kun molemmat pitävät paikkansa, se on nopeinta mitä maksamisessa on. Ei
sovellusta, ei tähtäämistä, ei näpyttelyä, ohi sekunnissa.

**Skannaus vaatii, että fani avaa kameran** — yksi ylimääräinen tietoinen liike — mutta
se ei vaadi sinulta yhtään mitään. Koodi istuu kotelon kannessa. Se toimii takarivissä
seisovalle fanille. Se toimii neljällekymmenelle ihmiselle yhtä aikaa. Se toimii, kun
soitat vielä.

Siitä seuraa rehellinen työnjako:

- **Näppäys voittaa, kun voit kävellä ihmisten luo.** Setin lopussa, hattu kiertää, yksi
  fani kerrallaan, sinä vapaana pitelemään päätettä. Näppäys on pienempi pyyntö kuin
  ”kaivapa kamerasi esiin”, ja sillä hetkellä olet fyysisesti paikalla viemässä sen
  loppuun.
- **Skannaus voittaa, kun et voi.** Kesken kappaleen. Kolmen rivin syvyinen yleisö.
  Paikka, josta et voi jättää vahvistinta. Jokainen, joka haluaa antaa ohi kävellessään.
  Pääte palvelee tasan yhtä ihmistä; painettu koodi palvelee koko aukiota yhtä aikaa,
  eikä se vaadi sinua lopettamaan soittamista sitä palvellaksesi.

Tuo viimeinen kohta on se, jota päätekauppiaat eivät koskaan mainitse, ja se on suurin.
**Kortinlukija on pullonkaula, jossa on jono.** QR-koodissa ei ole jonoa.

Ja tässä on osa, joka liuottaa puolet koko väittelystä: hyvin rakennetulla tippisivulla
**skannaus päättyy joka tapauksessa näppäykseen**. Fani skannaa, sivu aukeaa, ja hänen
puhelimensa tarjoaa Apple Payta tai Google Payta. Hän tuplaklikkaa, nostaa puhelimen
kasvojensa eteen, ja se on tehty. Fanin puolelta se on lähimaksu — sama lompakko, sama
kortti, samat kaksi sekuntia — etkä ostanut mitään laitetta sen tapahtumiseksi.

## Missä live.tips seisoo — ja milloin kannattaa ostaa SumUp

[live.tips](https://github.com/mekedron/live.tips) on QR-pohjainen tippipurkki. Yksi
koodi, joka ei koskaan muutu, ja joka osoittaa suoraan artistin omaan Stripen
maksulinkkiin. live.tips-saldoa ei ole, osuutta ei oteta, eikä matkalla ole alustaa —
maksu on Stripen oma, ja Stripe veloittaa sen suoraan artistilta. Se on
MIT-lisensoitu, ja lavalla oleva tabletti näyttää jokaisen tipin sillä hetkellä, kun se
saapuu. Kirjoitimme rahan reitin auki tekstissä
[näin live.tips käsittelee rahaa](https://live.tips/fi/blog/nain-live-tips-kasittelee-rahaa/), ja sen, miksi se on
[yksi koodi eikä yksi per palveluntarjoaja](https://live.tips/fi/blog/yksi-qr-koodi-kaikki-maksutavat/).

Tuo sivu tukee Apple Payta ja Google Payta. Eli live.tips *on* lähimaksu fanin puolelta —
se näppäys, jolla on merkitystä, se lopussa, ilman päätettä, joka pitäisi ostaa, ladata
tai pudottaa sateeseen. Se ei vain ole pääte.

**Jos haluat ojentaa jotain fyysistä ja antaa tuntemattoman näppäyttää sitä, osta
kortinlukija.** Ota SumUpin Tap to Pay, jos puhelimesi ja maasi tukevat sitä, koska se ei
maksa mitään; ota Solo, jos et halua ojentaa omaa puhelintasi väkijoukkoon. Kummin
tahansa: kahden euron näppäyksellä Euroopassa se voittaa meidän maksumme, ja sanomme sen
mieluummin kuin teeskentelemme muuta.

Voit myös tehdä molemmat, ja monen katusoittajan pitäisi: koodi teipattuna koteloon koko
illan, nappaamassa ohikulkijat samalla kun soitat, ja pääte kädessä ne kymmenen sekuntia
viimeisen soinnun jälkeen, kun eturivi kaivaa taskujaan. Ne eivät kilpaile keskenään. Ne
nappaavat eri ihmiset.

Kumpikaan niistä ei ole vuoden 2018 teline, joka ottaa 5 %.

Maksut, laitehinnat ja maakohtainen saatavuus sellaisina kuin Apple, Stripe, SumUp, Zettle/PayPal ja Square julkaisivat ne heinäkuussa 2026, ilman arvonlisäveroa. NFC-tarrojen hinnat GoToTagsilta. Tiptapin vuoden 2018 ehdot Brunel Universityn ja Finextran kertomina. Kaikki tämä muuttuu; tarkista se palveluntarjoajalta ennen kuin käytät rahaa.
{: .footnote }
