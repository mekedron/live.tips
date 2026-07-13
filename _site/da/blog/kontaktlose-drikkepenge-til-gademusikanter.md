# Kontaktløse drikkepenge til gademusikanter — ærligt regnet ud

> Tap to Pay på telefonen, en kortlæser, et NFC-klistermærke, en QR-kode — fire forskellige ting, der alle kaldes »kontaktløse«. Hvad hver af dem faktisk koster i 2026, hvad et NFC-tag i virkeligheden gør (ikke det, du tror), og hvornår et tryk slår et scan.

Canonical: https://live.tips/da/blog/kontaktlose-drikkepenge-til-gademusikanter/
Published: 2026-07-11
Language: da
Tags: contactless, NFC, QR codes, Tap to Pay, fees

---

Søg efter kontaktløse drikkepenge til gademusikanter, og internettet rækker dig
2018. En studenterprototype fra Brunel University ved navn Tiptap — et stativ, du
sætter en telefon ned i — fik en omgang presse det år, og den presse ligger stadig
på side ét. Det var en pæn idé. Det var også, med dækningens egne ord, *stadig på
udviklingsstadiet*, og planen var at opkræve gademusikanter et engangsgebyr plus
**5 % af hver eneste drikkeskilling**. Det blev aldrig til noget, man kan købe.

(Det »tiptap«, du finder, hvis du går på jagt i dag, er et helt andet firma fra
Ontario, der sælger kontaktløse donationsterminaler til velgørende organisationer.
Samme ord, andet produkt, ikke til dig.)

Den ærlige status er altså gået otte år uden at blive skrevet ned. Her er den.

Det her er dybdedykket i tappet. Hvis dit egentlige spørgsmål er det bredere — alle
måderne at få penge på nu, hvor ingen har kontanter, og hvad hver af dem koster — så
start med [hvordan gademusikere tager imod
kortbetalinger](https://live.tips/da/blog/kortbetaling-for-gademusikanter/) og kom tilbage hertil bagefter.

## Fire forskellige ting kaldes alle »kontaktløse«

Det er her, det meste af forvirringen bor, så lad os skille dem ad, før vi sætter
pris på noget som helst.

1. **Tap to Pay på din egen telefon.** Din telefon bliver terminalen. Fanen holder
   sit kort eller sit ur mod *dit* håndsæt. Slet ingen ekstra hardware.
2. **En kortlæser** — en SumUp, en Zettle, en Square. En lille plastikterminal, du
   holder frem. Fanen holder kortet mod den.
3. **Et NFC-tag** — klistermærket eller skiltet med »tryk her for at give
   drikkepenge«. Det her bliver misforstået næsten overalt, og det næste afsnit
   handler om hvorfor.
4. **En QR-kode.** Ikke kontaktløs i NFC-forstand — men læs videre, for fra fanens
   side ender den meget ofte i præcis det samme tryk.

Kun de to første er *betalingsterminaler*. Den forskel er hele det her indlæg.

## NFC-tagget tager ikke imod en betaling

Lad os rydde det her ordentligt af vejen, for sælgerne lader dig gerne tro noget
andet.

Et NFC-klistermærke — den billige slags, NTAG213-chippen, som de fleste bruger — har
**144 byte hukommelse**. Ikke 144 kilobyte. Det kan ikke køre kode, det har intet
batteri, det har aldrig hørt om et kortsystem, og det kunne ikke rumme en
betalingsprotokol, om det så ville. Det, det rummer, er en kort tekststreng,
formateret som en NDEF-post, og den streng er ganske overvejende en **URL**.

Tryk på det, og din telefon åbner en webside. Det er hele funktionen.

Hvilket betyder, at et »tap to tip«-skilt er en QR-kode, du åbner ved at røre i
stedet for at sigte. Samme destination, samme webside, samme betaling, der sker i
browseren. Selv specialisterne siger det, når man læser dem nøje: tiptaps egen side
beskriver sin enhed til frie beløb sådan, at når donorer holder deres telefon op
mod den, *»bliver de ledt hen til din online indsamlingsside.«* Ledt hen til en
side. For det er det, et tag kan.

Det er oprigtigt nyttigt, og det er også billigt — blanke NTAG213-klistermærker
starter omkring **0,24 $ stykket** i pakker. Har du allerede en drikkepengeside,
koster et tag på kassen ved siden af den trykte kode dig småpenge og giver nogle
fans en hurtigere vej ind.

Men vær klar over, hvad du har købt: **en hoveddør nummer to til den samme side.**
Ikke en kortmaskine.

### Og udendørs er det en pirrelig hoveddør

Fejltilstandene er virkelige, og ingen tag-sælger lister dem:

- **Fanens telefon skal være låst op og i brug.** Apples egen dokumentation er
  utvetydig: baggrundslæsning af tags sker kun, mens iPhonen er i brug, og er
  telefonen låst, får systemet dem til at låse op først.
- **Det virker ikke, mens kameraet er åbent.** Apple nævner et kamera i brug som en
  af de tilstande, hvor baggrundslæsning af tags ikke er tilgængelig. Nyd ironien:
  en fan, der griber efter kameraet for at scanne din QR-kode, har lige slået dit
  NFC-tag fra.
- **Det kræver en iPhone XS eller nyere**, og på Android skal NFC være slået til —
  hvilket nogle strømsparetilstande slår fra.
- **Rækkevidden er cirka 4 cm.** Fanen skal faktisk røre ved tingesten. I en menneskemængde,
  bøjet ned over en guitarkasse, er det meget at bede om.
- **Metal og magneter dræber det.** Et tag tapet på en forstærker, eller en fan med
  et magnetisk kortetui — og der sker overhovedet ingenting.

Et tag er en god mulighed nummer to. Det er en dårlig eneste mulighed.

## Tap to Pay på telefonen: den egentlige nyhed i 2026

Her er det, der har ændret sig siden Tiptap-artiklerne, og som ingen af de forældede
dækninger kender til.

**Tap to Pay på iPhone** gør telefonen, du allerede har i lommen, til en kontaktløs
terminal. Ingen dongle, ingen læser, intet stativ. Apple angiver, at det er
tilgængeligt i **70+ lande og regioner**, og de udbydere, du kan bruge det igennem i
Europa, lyder som hele branchen — alene i Tyskland: Adyen, Mollie, myPOS, Nexi,
PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Storbritannien,
Frankrig, Holland, Sverige, Finland og Danmark har alle lignende lister. Du skal
bruge en iPhone XS eller nyere.

**Tap to Pay på Android** findes også, men er smallere. Gennem Stripe er det
almindeligt tilgængeligt i AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL,
NZ, PL, SE, SG og US, med yderligere atten lande i offentlig prøveversion. Din
telefon skal have Android 13 eller nyere, en NFC-sensor, en urodet bootloader, Google
Mobile Services og udviklerindstillinger slået fra — den sidste fanger flere folk,
end man skulle tro.

Den praktiske version: **SumUp angiver Tap to Pay til 0 £ i hardware.** Har du en
nyere iPhone, og er du i et understøttet land, er startomkostningen ved at holde en
kontaktløs terminal frem nu nul. Alene den kendsgerning gør enhver »køb dette
stativ«-artikel fra 2018 forældet.

## Kortlæsere, og hvad de i virkeligheden koster

Vil du have et separat stykke plastik — og der er gode grunde til det, se nedenfor —
består markedet af tre produkter.

| | Hardware | Gebyr pr. fysisk betaling |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, intet fast gebyr |
| **SumUp** (Tyskland) | — | **1,39 %**, intet fast gebyr |
| **Zettle / PayPal POS** (UK) | Læser fra 29 £ for en førstegangsbruger, 69 £ derefter | **1,75 %**, intet fast gebyr |
| **Square** (UK) | Kontaktløs- og chiplæser 19 £ | **1,75 %**, intet fast gebyr |
| **Square** (US) | Kontaktløs- og chiplæser 59 $ | **2,6 % + 0,15 $** |

Priser er uden moms og som offentliggjort i juli 2026. Gå selv og tjek dem; de
flytter sig.

Læs så tabellen igen, for den siger noget, der modsiger det, du sandsynligvis har
fået fortalt.

## Gebyrregningen — og det, alle vender på hovedet

Den gængse visdom er, at kortgebyrer ødelægger små drikkepenge på grund af det faste
gebyr pr. transaktion — de femogtyve cent, der æder en ottendedel af en drikkeskilling
på 2 €. Det er sandt, og vi har
[selv skrevet regnestykket op](https://live.tips/da/blog/byg-en-drikkepengekrukke-pa-din-egen-stripe-konto/).

Men det er sandt om *online*-kortbetalinger. **Europæiske kontaktløse læsere har for
det meste slet ikke noget fast gebyr.** SumUp, Zettle og Square i Storbritannien og
EU er rent procentbaserede. Hvilket betyder:

| En drikkeskilling på 2 € | Gebyr | Kunstneren beholder | Reelt fradrag |
| --- | --- | --- | --- |
| SumUp-læser (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, kort online (EØS, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Square-læser (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Målt på gebyret alene slår en europæisk tap-terminal en online kortbetaling på en lille
drikkeskilling, og det er ikke tæt løb. Vi er et QR-kode-produkt, og vi siger det
alligevel: på 2 € beholder du med en SumUp-læser 0,25 €, som en Stripe-hostet side
ikke levner dig.

To ting sætter det tilbage i proportion.

**Hardwaren er det faste gebyr, bare flyttet.** En besparelse på 0,25 € pr.
drikkeskilling mod en Solo til 79 £ betyder omtrent **tre hundrede betalinger, før
læseren har tjent sig ind**. Det er et virkeligt tal for en arbejdende gademusikant
og et fjollet et for en, der spiller to gange om sommeren. (Og SumUps Tap to Pay til
0 £ gør det til nul betalinger — hvilket er præcis derfor, den mulighed betyder mere
end læserne gør.)

**Og USA vender det tilbage igen.** Squares amerikanske sats for fysiske betalinger
bærer et fast gebyr på 0,15 $, så en betaling på 2 $ mister også en tiendedel af sig
selv ved terminalen. Gaven »intet fast gebyr« er en europæisk gave.

Der er også et gulv, du vil møde: SumUp tager ikke imod en betaling under **1 £ /
1 €**. Uanset hvilken skinne du vælger — den meget lille drikkeskilling er egentlig
ikke en korttransaktion.

## Hvornår slår et tryk så et scan?

Skræl teknologien væk, og det her er et spørgsmål om fanens hænder.

**Et tryk kræver, at fanens telefon er låst op og i hånden, og at du holder noget
frem.** Når begge dele er sandt, er det det hurtigste, betalingsverdenen har. Ingen
app, ingen sigten, ingen indtastning, klaret på et sekund.

**Et scan kræver, at fanen åbner et kamera** — én ekstra bevidst handling — men det
kræver overhovedet intet af dig. Koden ligger på kassen. Den virker på en fan, der
står bagerst. Den virker på fyrre mennesker på én gang. Den virker, mens du stadig
spiller.

Det giver en ærlig arbejdsdeling:

- **Trykket vinder, når du kan gå hen til folk.** Efter sættet, hatten rundt, én fan
  ad gangen, dig fri til at holde en terminal. Et tryk er en mindre besværlig
  anmodning end »find lige dit kamera frem«, og i det øjeblik står du der fysisk og
  kan lukke handlen.
- **Scannet vinder, når du ikke kan.** Midt i en sang. En menneskemængde i tre rækker.
  En plads, hvor du ikke kan forlade forstærkeren. Alle, der vil give, mens de går
  forbi. En terminal kan betjene præcis én person; en trykt kode betjener hele
  pladsen på samme tid, og den kræver ikke, at du holder op med at spille for at
  betjene den.

Det sidste punkt er det, terminalsælgerne aldrig fremfører, og det er det største.
**En kortlæser er en flaskehals med en kø.** En QR-kode har ingen kø.

Og her er den del, der opløser det halve af diskussionen: på en velbygget
drikkepengeside **ender scannet alligevel i et tryk**. Fanen scanner, siden åbner sig,
og telefonen tilbyder Apple Pay eller Google Pay. De dobbeltklikker, de holder
telefonen op foran ansigtet, det er klaret. Fra fanens side er det en kontaktløs
betaling — samme wallet, samme kort, samme to sekunder — og du købte ingen hardware
for at få det til at ske.

## Hvor live.tips står — og hvornår du hellere skal købe en SumUp

[live.tips](https://github.com/mekedron/live.tips) er en QR-baseret drikkepengekrukke.
Én kode, som aldrig ændrer sig, og som peger direkte på kunstnerens eget
Stripe-betalingslink. Der er ingen live.tips-saldo, intet fradrag og ingen platform
undervejs — gebyret er Stripes eget, og Stripe opkræver det direkte hos kunstneren.
Det er MIT-licenseret, og tabletten på scenen viser hver drikkeskilling, i det øjeblik
den lander. Vi har skrevet pengevejen op i
[hvordan live.tips håndterer penge](https://live.tips/da/blog/sadan-handterer-live-tips-penge/), og hvorfor det
er [én kode frem for én pr. udbyder](https://live.tips/da/blog/en-qr-kode-hver-betalingsmetode/).

Den side understøtter Apple Pay og Google Pay. Så live.tips *er* kontaktløs fra fanens
side — det tryk, der tæller, det til sidst, uden en terminal at købe, oplade eller tabe
i regnen. Det er bare ikke en terminal.

**Er det, du vil, at holde noget fysisk frem og lade en fremmed trykke på det, så køb
en kortlæser.** Tag SumUps Tap to Pay, hvis din telefon og dit land understøtter det,
for det koster ingenting; tag en Solo, hvis du helst ikke vil række din egen telefon
ud i en menneskemængde. Uanset hvad slår den vores gebyr på en betaling på 2 € i
Europa, og det siger vi hellere end at lade som om noget andet.

Du kan også gøre begge dele, og det burde en hel del gademusikanter: koden tapet på
kassen hele aftenen, som fanger de forbipasserende, mens du spiller, og terminalen i
hånden i de ti sekunder efter den sidste akkord, hvor forreste række griber ned i
lommen. De konkurrerer ikke. De fanger forskellige mennesker.

Det, ingen af dem er, er et stativ fra 2018, der tager 5 %.

Gebyrer, hardwarepriser og landetilgængelighed som offentliggjort af Apple, Stripe, SumUp, Zettle/PayPal og Square i juli 2026, uden moms. Priser på NFC-klistermærker fra GoToTags. Tiptaps vilkår fra 2018 som rapporteret af Brunel University og Finextra. Alt her ændrer sig; tjek det hos udbyderen, før du bruger penge.
{: .footnote }
