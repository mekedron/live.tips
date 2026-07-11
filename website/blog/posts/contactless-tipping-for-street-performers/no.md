---
title: Kontaktløse tips til gatemusikanter — ærlig regnet ut
description: Tap to Pay på telefonen, en kortleser, et NFC-klistremerke, en QR-kode — fire forskjellige ting som alle kalles «kontaktløse». Hva hver av dem faktisk koster i 2026, hva en NFC-brikke egentlig gjør (ikke det du tror), og når et trykk slår et skann.
slug: kontaktlose-tips-til-gatemusikanter
---

Søk etter kontaktløse tips til gatemusikanter, og internett rekker deg 2018. En
studentprototype fra Brunel University ved navn Tiptap — et stativ du setter en
telefon ned i — fikk en runde presse det året, og den pressen ligger fortsatt på
side én. Det var en fin idé. Det var også, med dekningens egne ord, *fortsatt på
utviklingsstadiet*, og planen var å kreve gatemusikanter for et engangsgebyr pluss
**5 % av hvert eneste tips**. Det ble aldri noe man kan kjøpe.

(«Tiptap»-en du finner om du leter i dag, er et helt annet selskap fra Ontario som
selger kontaktløse donasjonsterminaler til veldedige organisasjoner. Samme ord,
annet produkt, ikke for deg.)

Så den ærlige statusen har gått åtte år uten å bli skrevet ned. Her er den.

Dette er dypdykket i tappen. Er det egentlige spørsmålet ditt det bredere — alle
måtene å få betalt på nå som ingen har kontanter, og hva hver av dem koster — så
begynn med [hvordan gatemusikere tar
kortbetaling](post:how-buskers-take-card-payments) og kom tilbake hit etterpå.

## Fire forskjellige ting kalles alle «kontaktløse»

Det er her mesteparten av forvirringen bor, så la oss skille dem før vi priser noe
som helst.

1. **Tap to Pay på din egen telefon.** Telefonen din blir terminalen. Fanen holder
   kortet eller klokka si mot *ditt* håndsett. Ingen ekstra maskinvare i det hele
   tatt.
2. **En kortleser** — en SumUp, en Zettle, en Square. En liten plastterminal du
   holder fram. Fanen holder kortet mot den.
3. **En NFC-brikke** — klistremerket eller skiltet med «trykk her for å gi tips».
   Dette blir misforstått nesten overalt, og neste avsnitt handler om hvorfor.
4. **En QR-kode.** Ikke kontaktløs i NFC-forstand — men les videre, for fra fanens
   side ender den svært ofte i nøyaktig det samme trykket.

Bare de to første er *betalingsterminaler*. Den forskjellen er hele dette innlegget.

## NFC-brikken tar ikke imot en betaling

La oss rydde dette skikkelig av veien, for leverandørene lar deg gjerne tro noe
annet.

Et NFC-klistremerke — den billige sorten, NTAG213-brikken som de fleste bruker — har
**144 byte minne**. Ikke 144 kilobyte. Den kan ikke kjøre kode, den har ikke
batteri, den har aldri hørt om et kortsystem, og den kunne ikke rommet en
betalingsprotokoll om den så ville. Det den rommer, er en kort tekststreng,
formatert som en NDEF-post, og den strengen er i all hovedsak en **URL**.

Trykk på den, og telefonen din åpner en nettside. Det er hele funksjonen.

Noe som betyr at et «tap to tip»-skilt er en QR-kode du åpner ved å berøre i stedet
for å sikte. Samme mål, samme nettside, samme betaling som skjer i nettleseren. Selv
spesialistene sier det når man leser dem nøye: tiptaps egen side beskriver enheten
sin for frie beløp slik at når givere holder telefonen opp mot den, *«blir de sendt
videre til innsamlingssiden din på nett.»* Sendt videre til en side. For det er det
en brikke kan.

Dette er oppriktig nyttig, og det er også billig — blanke NTAG213-klistremerker
starter rundt **0,24 $ stykket** i pakker. Har du allerede en tipsside, koster en
brikke på kassa ved siden av den trykte koden deg småpenger og gir noen fans en
raskere vei inn.

Men vær klar over hva du har kjøpt: **en inngangsdør nummer to til den samme siden.**
Ikke en kortmaskin.

### Og utendørs er det en kranglete inngangsdør

Feilmodusene er reelle, og ingen som selger brikker lister dem opp:

- **Fanens telefon må være låst opp og i bruk.** Apples egen dokumentasjon er
  utvetydig: bakgrunnslesing av brikker skjer bare mens iPhonen er i bruk, og er
  telefonen låst, tvinger systemet dem til å låse opp først.
- **Det virker ikke mens kameraet er åpent.** Apple lister et kamera i bruk som en
  av tilstandene der bakgrunnslesing av brikker ikke er tilgjengelig. Nyt ironien:
  en fan som griper etter kameraet for å skanne QR-koden din, har akkurat slått av
  NFC-brikken din.
- **Det krever en iPhone XS eller nyere**, og på Android må NFC være slått på — noe
  enkelte strømsparemoduser slår av.
- **Rekkevidden er rundt 4 cm.** Fanen må faktisk berøre greia. I en folkemengde,
  bøyd ned mot en gitarkasse, er det mye å be om.
- **Metall og magneter dreper den.** En brikke teipet på en forsterker, eller en fan
  med et magnetisk kortdeksel — og det skjer ingenting i det hele tatt.

En brikke er et fint alternativ nummer to. Den er et dårlig eneste alternativ.

## Tap to Pay på telefonen: den egentlige 2026-nyheten

Her er tingen som har endret seg siden Tiptap-artiklene, og som ingen av de utdaterte
oppslagene vet om.

**Tap to Pay på iPhone** gjør telefonen du allerede har i lomma, om til en
kontaktløs terminal. Ingen dongle, ingen leser, intet stativ. Apple oppgir at det er
tilgjengelig i **70+ land og regioner**, og formidlerne du kan bruke det gjennom i
Europa høres ut som hele bransjen — i Tyskland alene: Adyen, Mollie, myPOS, Nexi,
PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Storbritannia,
Frankrike, Nederland, Sverige, Finland og Danmark har alle lignende lister. Du
trenger en iPhone XS eller nyere.

**Tap to Pay på Android** finnes også, men er smalere. Gjennom Stripe er det generelt
tilgjengelig i AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG
og US, med ytterligere atten land i offentlig forhåndsvisning. Telefonen din trenger
Android 13 eller nyere, en NFC-sensor, en urotet bootloader, Google Mobile Services,
og utvikleralternativer slått av — det siste tar flere enn du skulle tro.

Den praktiske versjonen: **SumUp oppgir Tap to Pay til 0 £ i maskinvare.** Har du en
nyere iPhone og er i et støttet land, er inngangskostnaden for å holde fram en
kontaktløs terminal nå null. Det faktumet alene gjør enhver «kjøp dette
stativet»-artikkel fra 2018 utdatert.

## Kortlesere, og hva de faktisk koster

Vil du ha en egen bit plast — og det finnes gode grunner til det, se nedenfor — består
markedet av tre produkter.

| | Maskinvare | Gebyr per fysisk betaling |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, ingen fast avgift |
| **SumUp** (Tyskland) | — | **1,39 %**, ingen fast avgift |
| **Zettle / PayPal POS** (UK) | Leser fra 29 £ for en førstegangsbruker, 69 £ etterpå | **1,75 %**, ingen fast avgift |
| **Square** (UK) | Kontaktløs- og chipleser 19 £ | **1,75 %**, ingen fast avgift |
| **Square** (US) | Kontaktløs- og chipleser 59 $ | **2,6 % + 0,15 $** |

Prisene er uten mva. og slik de var publisert i juli 2026. Gå og sjekk dem selv; de
flytter på seg.

Les nå tabellen en gang til, for den sier noe som motsier det du sannsynligvis har
fått høre.

## Gebyrregnestykket — og det alle har baklengs

Den mottatte visdommen er at kortgebyrer ødelegger små tips på grunn av den faste
avgiften per transaksjon — de tjuefem centene som spiser en åttendedel av et tips på
2 €. Det er sant, og vi har
[skrevet regnestykket ut selv](post:build-a-tip-jar-on-your-own-stripe).

Men det er sant om *online* kortbetalinger. **Europeiske kontaktløse lesere har for
det meste ingen fast avgift i det hele tatt.** SumUp, Zettle og Square i
Storbritannia og EU er rent prosentbaserte. Noe som betyr:

| Et tips på 2 € | Gebyr | Artisten beholder | Reelt kutt |
| --- | --- | --- | --- |
| SumUp-leser (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, kort på nett (EØS, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Square-leser (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Målt på gebyret alene slår en europeisk tap-terminal en kortbetaling på nett når
tipset er lite, og det er ikke jevnt. Vi er et QR-kode-produkt, og vi sier det
likevel: på et tips på 2 € beholder du med en SumUp-leser 0,25 € som en Stripe-hostet
side ikke lar deg beholde.

To ting setter det tilbake i proporsjon.

**Maskinvaren er den faste avgiften, bare flyttet.** En besparelse på 0,25 € per tips
mot en Solo til 79 £ betyr rundt **tre hundre betalinger før leseren har betalt seg
selv**. Det er et reelt tall for en gatemusikant som jobber, og et tåpelig et for
noen som spiller to ganger om sommeren. (Og SumUps Tap to Pay til 0 £ gjør det til
null betalinger — som er nettopp derfor det alternativet betyr mer enn leserne gjør.)

**Og USA snur det tilbake.** Squares amerikanske sats for fysiske betalinger bærer en
fast avgift på 0,15 $, så et trykk på 2 $ mister også en tidel av seg selv ved
terminalen. Gaven «ingen fast avgift» er en europeisk gave.

Det finnes også et gulv du vil møte: SumUp tar ikke imot en betaling under **1 £ /
1 €**. Uansett hvilket spor du velger — det svært lille tipset er egentlig ikke en
korttransaksjon.

## Så når slår et trykk et skann?

Skrell vekk teknologien, og dette er et spørsmål om fanens hender.

**Et trykk krever at fanens telefon er låst opp og i hånda, og at du holder fram noe.**
Når begge deler stemmer, er det det raskeste betalingsverdenen har. Ingen app, ingen
sikting, ingen tasting, ferdig på et sekund.

**Et skann krever at fanen åpner et kamera** — én ekstra bevisst handling — men det
krever ingenting av deg. Koden sitter på kassa. Den virker på en fan som står bakerst.
Den virker på førti mennesker samtidig. Den virker mens du fortsatt spiller.

Det gir en ærlig arbeidsdeling:

- **Trykket vinner når du kan gå bort til folk.** Etter settet, hatten rundt, én fan
  om gangen, du fri til å holde en terminal. Et trykk er en mindre kostbar forespørsel
  enn «finn fram kameraet ditt», og i det øyeblikket står du der fysisk og kan lukke
  handelen.
- **Skannet vinner når du ikke kan.** Midt i en låt. En folkemengde i tre rader. En
  plass der du ikke kan forlate forsterkeren. Alle som vil gi mens de går forbi. En
  terminal kan betjene nøyaktig én person; en trykt kode betjener hele torget
  samtidig, og den krever ikke at du slutter å spille for å betjene den.

Det siste poenget er det terminalselgerne aldri fremmer, og det er det største.
**En kortleser er en flaskehals med kø.** En QR-kode har ingen kø.

Og her er delen som løser opp halve diskusjonen: på en godt bygget tipsside **ender
skannet uansett i et trykk**. Fanen skanner, siden åpner seg, og telefonen tilbyr Apple
Pay eller Google Pay. De dobbeltklikker, de holder telefonen opp mot ansiktet, det er
gjort. Fra fanens side er det en kontaktløs betaling — samme lommebok, samme kort,
samme to sekunder — og du kjøpte ingen maskinvare for å få det til.

## Hvor live.tips står — og når du heller bør kjøpe en SumUp

[live.tips](https://github.com/mekedron/live.tips) er en QR-basert tipskrukke. Én kode,
som aldri endrer seg, og som peker rett på artistens egen Stripe-betalingslenke. Det
finnes ingen live.tips-saldo, ingen kutt og ingen plattform i veien — gebyret er Stripes
eget, og Stripe fakturerer det direkte til artisten. Alt er MIT-lisensiert, og nettbrettet
på scenen viser hvert tips i det øyeblikket det lander. Vi skrev opp pengeveien i
[hvordan live.tips håndterer penger](post:how-live-tips-handles-money), og hvorfor det er
[én kode framfor én per formidler](post:one-qr-code-every-payment-method).

Den siden støtter Apple Pay og Google Pay. Så live.tips *er* kontaktløs fra fanens side —
trykket som teller, det på slutten, uten en terminal å kjøpe, lade eller miste i regnet.
Det er bare ikke en terminal.

**Er det du vil å holde fram noe fysisk og la en fremmed trykke på det, så kjøp en
kortleser.** Ta SumUps Tap to Pay hvis telefonen og landet ditt støtter det, for det
koster ingenting; ta en Solo hvis du helst ikke vil rekke din egen telefon ut i en
folkemengde. Uansett vil den slå gebyret vårt på et trykk på 2 € i Europa, og det sier
vi heller enn å late som noe annet.

Du kan også gjøre begge deler, og ganske mange gatemusikanter burde: koden teipet på kassa
hele kvelden, som fanger de forbipasserende mens du spiller, og terminalen i hånda de ti
sekundene etter siste akkord, når første rad griper ned i lomma. De konkurrerer ikke. De
fanger forskjellige mennesker.

Det ingen av dem er, er et stativ fra 2018 som tar 5 %.

Gebyrer, maskinvarepriser og landtilgjengelighet slik de er publisert av Apple, Stripe, SumUp, Zettle/PayPal og Square i juli 2026, uten mva. Priser på NFC-klistremerker fra GoToTags. Tiptaps vilkår fra 2018 slik de er gjengitt av Brunel University og Finextra. Alt her endrer seg; sjekk det mot leverandøren før du bruker penger.
{: .footnote }
