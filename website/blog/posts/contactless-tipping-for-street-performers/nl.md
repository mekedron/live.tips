---
title: Contactloos fooien geven aan straatmuzikanten, eerlijk gerekend
description: Tap to Pay op een telefoon, een kaartlezer, een NFC-sticker, een QR-code — vier verschillende dingen die allemaal 'contactloos' heten. Wat elk daarvan in 2026 echt kost, wat een NFC-tag werkelijk doet (niet wat je denkt), en wanneer een tap een scan verslaat.
slug: contactloos-fooien-geven-aan-straatmuzikanten
---

Zoek op contactloos fooien geven aan straatmuzikanten en het internet overhandigt je
2018. Een studentenprototype van Brunel University genaamd Tiptap — een standaard
waar je een telefoon in schuift — kreeg dat jaar een ronde pers, en die pers staat
nog altijd op pagina één. Het was een aardig idee. Het was ook, in de woorden van
diezelfde berichtgeving, *nog in de ontwikkelingsfase*, en het was van plan
straatmuzikanten een eenmalige vergoeding te rekenen plus **5% van elke fooi**. Het
is nooit iets geworden dat je kunt kopen.

(De 'tiptap' die je vindt als je nu gaat zoeken, is een niet-gerelateerd bedrijf uit
Ontario dat contactloze donatieterminals aan goede doelen verkoopt. Zelfde woord,
ander product, niet voor jou.)

De eerlijke stand van zaken is dus acht jaar lang niet opgeschreven. Hier is hij.

Dit is de diepteduik in de tap. Is je echte vraag de bredere — alle manieren om
betaald te worden nu niemand nog contant geld op zak heeft, en wat elke manier kost
—, begin dan bij [hoe straatmuzikanten kaartbetalingen
aannemen](post:how-buskers-take-card-payments) en kom daarna hier terug.

## Vier verschillende dingen heten allemaal 'contactloos'

Hier zit de meeste verwarring, dus laten we ze uit elkaar halen voordat we iets
beprijzen.

1. **Tap to Pay op je eigen telefoon.** Je telefoon wordt de terminal. De fan houdt
   zijn kaart of zijn horloge tegen *jouw* toestel. Helemaal geen extra hardware.
2. **Een kaartlezer** — een SumUp, een Zettle, een Square. Een plastic terminaltje dat
   je voorhoudt. De fan tapt erop.
3. **Een NFC-tag** — de 'tap hier voor een fooi'-sticker of het plaatje. Deze wordt
   bijna universeel verkeerd begrepen, en de volgende paragraaf gaat over waarom.
4. **Een QR-code.** Niet contactloos in de NFC-zin — maar lees door, want vanaf de
   kant van de fan eindigt het heel vaak in precies dezelfde tap.

Alleen de eerste twee zijn *betaalterminals*. Dat onderscheid is het hele stuk.

## De NFC-tag neemt geen betaling aan

Laten we dit netjes afmaken, want verkopers laten je maar wat graag het tegendeel
geloven.

Een NFC-sticker — de goedkope soort, de NTAG213-chip die de meeste gebruiken — heeft
**144 bytes geheugen**. Geen 144 kilobytes. Hij kan geen code draaien, hij heeft geen
batterij, hij heeft nog nooit van een kaartschema gehoord, en hij zou een
betaalprotocol niet kunnen bevatten al zou hij willen. Wat hij wél bevat is een korte
tekenreeks, opgemaakt als een NDEF-record, en die tekenreeks is overweldigend vaak een
**URL**.

Tap erop, en je telefoon opent een webpagina. Dat is de hele functie.

Wat betekent dat een 'tap to tip'-plaatje een QR-code is die je opent door hem aan te
raken in plaats van erop te richten. Dezelfde bestemming, dezelfde webpagina, dezelfde
betaling die in de browser gebeurt. Zelfs de specialisten zeggen het, als je ze
zorgvuldig leest: tiptap beschrijft op zijn eigen site het apparaat met vrij bedrag
als een waarbij *"donateurs die hun telefoon tegen een aangepast donatieapparaat
houden, naar je online inzamelingspagina worden geleid."* Geleid naar een pagina. Want
dat is wat een tag kan.

Dat is oprecht nuttig, en het is ook goedkoop — blanco NTAG213-stickers beginnen rond
de **$0,24 per stuk** in pakjes. Als je al een fooienpagina hebt, kost een tag op je
koffer naast de gedrukte code je kleingeld en geeft hij sommige fans een snellere weg
naar binnen.

Maar wees duidelijk over wat je gekocht hebt: **een tweede voordeur naar dezelfde
pagina.** Geen pinapparaat.

### En buiten is het een kieskeurige voordeur

De faalgevallen zijn echt, en niemand die tags verkoopt somt ze op:

- **De telefoon van de fan moet ontgrendeld zijn en in gebruik.** Apples eigen
  documentatie is expliciet: het lezen van tags op de achtergrond gebeurt alleen
  terwijl de iPhone in gebruik is, en als de telefoon vergrendeld is, laat het systeem
  hem eerst ontgrendelen.
- **Het werkt niet terwijl de camera open staat.** Apple noemt de camera in gebruik
  als een van de toestanden waarin het lezen van tags op de achtergrond niet
  beschikbaar is. Geniet van de ironie: een fan die naar zijn camera grijpt om je
  QR-code te scannen, heeft zojuist je NFC-tag uitgeschakeld.
- **Het vereist een iPhone XS of nieuwer**, en op Android moet NFC aan staan — wat
  sommige energiebesparingsstanden uitzetten.
- **Het bereik is ongeveer 4 cm.** De fan moet het ding echt aanraken. In een menigte,
  bukkend naar een gitaarkoffer, is dat nogal wat gevraagd.
- **Metaal en magneten maken het dood.** Een tag op een versterker geplakt, of een fan
  met een magnetisch hoesje, en er gebeurt helemaal niets.

Een tag is een prima tweede optie. Als enige optie is hij slecht.

## Tap to Pay op je telefoon: het echte nieuws van 2026

Dit is wat er veranderd is sinds de Tiptap-artikelen, en waar geen van die muffe
berichtgeving iets van weet.

**Tap to Pay op de iPhone** maakt van de telefoon die al in je zak zit een contactloze
terminal. Geen dongle, geen lezer, geen standaard. Apple noemt het beschikbaar in
**70+ landen en regio's**, en de aanbieders waarmee je het in Europa kunt gebruiken
lezen als de hele branche — alleen al in Duitsland: Adyen, Mollie, myPOS, Nexi,
PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Het Verenigd Koninkrijk,
Frankrijk, Nederland, Zweden, Finland en Denemarken hebben vergelijkbare lijsten. Je
hebt een iPhone XS of nieuwer nodig.

**Tap to Pay op Android** bestaat ook, maar is smaller. Via Stripe is het algemeen
beschikbaar in AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG
en US, met nog eens achttien landen in publieke preview. Je telefoon heeft Android 13
of nieuwer nodig, een NFC-sensor, een niet-geroote bootloader, Google Mobile Services,
en ontwikkelaarsopties uitgeschakeld — dat laatste betrapt meer mensen dan je zou
denken.

De praktische versie: **SumUp zet Tap to Pay op £0 aan hardware.** Heb je een recente
iPhone en zit je in een ondersteund land, dan is de instapkosten om een contactloze
terminal voor te houden nu nul. Alleen dat feit maakt elk 'koop deze
standaard'-artikel uit 2018 achterhaald.

## Kaartlezers, en wat ze echt kosten

Wil je een apart stuk plastic — en daar zijn goede redenen voor, zie hieronder — dan
bestaat de markt uit drie producten.

| | Hardware | Kosten per tap ter plekke |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay £0 · Solo Lite £25 · Solo £79 · Terminal £135 | **1,69%**, geen vast bedrag |
| **SumUp** (Duitsland) | — | **1,39%**, geen vast bedrag |
| **Zettle / PayPal POS** (UK) | Lezer vanaf £29 voor een eerste aankoop, daarna £69 | **1,75%**, geen vast bedrag |
| **Square** (UK) | Contactloze en chiplezer £19 | **1,75%**, geen vast bedrag |
| **Square** (US) | Contactloze en chiplezer $59 | **2,6% + $0,15** |

Prijzen exclusief btw en zoals gepubliceerd in juli 2026. Ga ze zelf nakijken; ze
bewegen.

Lees die tabel nu nog eens, want hij zegt iets dat ingaat tegen wat je waarschijnlijk
verteld is.

## De feerekensom, en het ding dat iedereen omgekeerd heeft

De gangbare wijsheid is dat kaartkosten kleine fooien vernietigen vanwege het vaste
bedrag per transactie — de vijfentwintig cent die een achtste van een fooi van €2
opeet. Dat klopt, en we hebben
[de rekensom zelf uitgeschreven](post:build-a-tip-jar-on-your-own-stripe).

Maar het klopt van *online* kaartbetalingen. **Europese contactloze lezers hebben
meestal helemaal geen vast bedrag.** SumUp, Zettle en Square in het VK en de EU
rekenen alleen een percentage. Wat betekent:

| Een fooi van €2 | Kosten | Artiest houdt over | Effectieve afdracht |
| --- | --- | --- | --- |
| SumUp-lezer (DE, 1,39%) | €0,03 | €1,97 | **1,4%** |
| Zettle / Square (UK, 1,75%) | €0,04 | €1,96 | 1,8% |
| Stripe, online kaart (EER, 1,5% + €0,25) | €0,28 | €1,72 | **14,0%** |
| Square-lezer (US, 2,6% + $0,15) | $0,20 | $1,80 | **10,1%** |

Puur op de kosten verslaat een Europese tap-terminal een online kaartbetaling bij een
kleine fooi, en het is niet eens spannend. We zijn een QR-codeproduct en we vertellen
je dit: bij een fooi van €2 houdt een SumUp-lezer €0,25 voor je vast die een door
Stripe gehoste pagina niet vasthoudt.

Twee dingen zetten dat weer in verhouding.

**De hardware is het vaste bedrag, verplaatst.** Een besparing van €0,25 per fooi
tegenover een Solo van £79 betekent ruwweg **driehonderd taps voordat de lezer
zichzelf heeft terugverdiend**. Dat is een reëel getal voor een werkende
straatmuzikant en een lachwekkend getal voor iemand die twee keer per zomer speelt.
(En SumUps Tap to Pay van £0 maakt er nul taps van — precies daarom doet die optie er
meer toe dan de lezers.)

**En de VS draait het weer om.** Squares Amerikaanse tarief ter plekke draagt een vast
bedrag van $0,15, dus een tap van $2 verliest ook aan de terminal een tiende van
zichzelf. Het cadeau 'geen vast bedrag' is een Europees cadeau.

Er is ook een ondergrens die je tegenkomt: SumUp neemt geen betaling aan onder **£1 /
€1**. Welk spoor je ook kiest, de heel kleine fooi is eigenlijk geen kaarttransactie.

## Wanneer verslaat een tap dan een scan?

Haal de techniek weg en dit is een vraag over de handen van de fan.

**Een tap heeft de telefoon van de fan ontgrendeld en in zijn hand nodig, en heeft
nodig dat jij iets voorhoudt.** Als beide waar zijn, is het het snelste wat er in
betalingen bestaat. Geen app, geen richten, geen typen, in een seconde klaar.

**Een scan heeft nodig dat de fan een camera opent** — één extra bewuste handeling —
maar hij heeft helemaal niets van jou nodig. De code zit op de koffer. Hij werkt bij
een fan die achteraan staat. Hij werkt bij veertig mensen tegelijk. Hij werkt terwijl
je nog aan het spelen bent.

Wat een eerlijke verdeling geeft:

- **Tap wint wanneer je naar mensen toe kunt lopen.** Einde van het set, de hoed rond,
  één fan tegelijk, jij vrij om een terminal vast te houden. Een tap is een vraag met
  minder wrijving dan 'pak je camera erbij', en op dat moment sta je er fysiek bij om
  het af te maken.
- **Scan wint wanneer je dat niet kunt.** Midden in een nummer. Een publiek van drie
  rijen diep. Een plek waar je niet bij de versterker weg kunt. Iedereen die in het
  voorbijgaan wil geven. Een terminal bedient precies één persoon; een gedrukte code
  bedient het hele plein, tegelijk, en heeft niet nodig dat je stopt met spelen om hem
  te bedienen.

Dat laatste punt is het punt dat terminalverkopers nooit maken, en het is het grootste.
**Een kaartlezer is een flessenhals met een rij.** Een QR-code heeft geen rij.

En hier is het deel dat de helft van de discussie oplost: op een goed gebouwde
fooienpagina **eindigt de scan toch al in een tap**. De fan scant, de pagina opent, en
zijn telefoon biedt Apple Pay of Google Pay aan. Hij dubbelklikt, hij houdt de telefoon
voor zijn gezicht, klaar. Vanaf de kant van de fan is dat een contactloze betaling —
dezelfde wallet, dezelfde kaart, dezelfde twee seconden — en jij hebt er geen hardware
voor gekocht.

## Waar live.tips staat, en wanneer je beter een SumUp koopt

[live.tips](https://github.com/mekedron/live.tips) is een fooienpot op basis van een
QR-code. Eén code, die nooit verandert, die rechtstreeks naar de eigen Stripe-betaallink
van de artiest wijst. Er is geen live.tips-saldo, geen afdracht, en geen platform in het
pad — de kosten zijn die van Stripe, en Stripe rekent ze rechtstreeks aan de artiest. Het
is MIT-gelicentieerd, en de tablet op het podium toont elke fooi op het moment dat hij
binnenkomt. We schreven het geldpad uit in
[hoe live.tips met geld omgaat](post:how-live-tips-handles-money), en waarom het
[één code is in plaats van één per aanbieder](post:one-qr-code-every-payment-method).

Die pagina ondersteunt Apple Pay en Google Pay. Dus live.tips *is* contactloos vanaf de
kant van de fan — de tap die ertoe doet, die aan het eind, zonder terminal om te kopen,
op te laden of in de regen te laten vallen. Het is alleen geen terminal.

**Als wat je wilt is fysiek iets voorhouden waar een vreemde op tapt, koop dan een
kaartlezer.** Neem SumUps Tap to Pay als je telefoon en je land het ondersteunen, want
het kost niets; neem een Solo als je liever niet je eigen telefoon aan een menigte
voorhoudt. Hoe dan ook: bij een tap van €2 in Europa verslaat het onze kosten, en we
zeggen dat liever dan dat we doen alsof het anders is.

Je kunt ook allebei doen, en heel wat straatmuzikanten zouden dat moeten: de code de
hele avond op de koffer geplakt, die de voorbijgangers opvangt terwijl je speelt, en de
terminal in je hand voor de tien seconden na het laatste akkoord, wanneer de eerste rij
naar zijn zakken grijpt. Ze concurreren niet. Ze vangen verschillende mensen.

Wat ze geen van beide zijn: een standaard uit 2018 die 5% neemt.

Kosten, hardwareprijzen en beschikbaarheid per land zoals gepubliceerd door Apple, Stripe, SumUp, Zettle/PayPal en Square in juli 2026, exclusief btw. Prijzen van NFC-stickers van GoToTags. Tiptaps voorwaarden uit 2018 zoals gerapporteerd door Brunel University en Finextra. Alles hierin verandert; controleer het bij de leverancier voordat je geld uitgeeft.
{: .footnote }
