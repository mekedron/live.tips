---
title: Kontaktlös dricks till gatumusiker, ärligt
description: Tap to Pay på mobilen, en kortläsare, ett NFC-klistermärke, en QR-kod — fyra olika saker som alla kallas ”kontaktlöst". Vad var och en faktiskt kostar 2026, vad ett NFC-tagg egentligen gör (det är inte vad du tror) och när en tryckning slår en skanning.
slug: kontaktlos-dricks-till-gatumusiker
---

Sök på kontaktlös dricks till gatumusiker och internet räcker dig 2018. En
studentprototyp från Brunel University som hette Tiptap — ett stativ man skjuter in en
mobil i — fick en runda press det året, och den pressen ligger fortfarande kvar på
sida ett. Det var en trevlig idé. Den var också, med bevakningens egna ord, *fortfarande
på utvecklingsstadiet*, och planen var att ta ut en engångsavgift av gatumusikern plus
**5% av varje dricks**. Det blev aldrig något man kan köpa.

(Det ”tiptap" du hittar om du letar i dag är ett orelaterat företag i Ontario som säljer
kontaktlösa donationsterminaler till välgörenhetsorganisationer. Samma ord, annan
produkt, inget för dig.)

Så den ärliga lägesbilden har fått gå åtta år utan att skrivas ner. Här är den.

Det här är djupdykningen i tappen. Om din verkliga fråga är den bredare — alla sätt
att få betalt nu när ingen bär kontanter, och vad vart och ett kostar — börja med
[hur gatumusiker tar kortbetalningar](post:how-buskers-take-card-payments) och kom
tillbaka hit sedan.

## Fyra olika saker kallas alla ”kontaktlöst"

Det är här förvirringen bor, så låt oss skilja dem åt innan vi prissätter någonting.

1. **Tap to Pay på din egen mobil.** Din telefon blir terminalen. Ditt fan trycker sitt
   kort eller sin klocka mot *din* lur. Ingen extra hårdvara alls.
2. **En kortläsare** — en SumUp, en Zettle, en Square. En liten plastterminal som du
   håller fram. Ditt fan trycker på den.
3. **Ett NFC-tagg** — klistermärket eller skylten med ”tryck här för att ge dricks". Det
   här missförstås nästan universellt, och nästa avsnitt handlar om varför.
4. **En QR-kod.** Inte kontaktlös i NFC-mening — men läs vidare, för från fanets sida
   slutar den mycket ofta i exakt samma tryckning.

Bara de två första är *betalterminaler*. Den skillnaden är hela den här texten.

## NFC-taggen tar inte emot någon betalning

Låt oss avliva det här ordentligt, för leverantörerna låter dig gärna tro något annat.

Ett NFC-klistermärke — den billiga sorten, NTAG213-chippet som de allra flesta använder —
har **144 bytes minne**. Inte 144 kilobytes. Det kan inte köra kod, det har inget batteri,
det har aldrig hört talas om ett kortnätverk och det skulle inte rymma ett betalprotokoll
även om det ville. Vad det rymmer är en kort teckensträng, formaterad som en NDEF-post, och
den strängen är i det överväldigande flertalet fall en **URL**.

Tryck på det, och din telefon öppnar en webbsida. Det är hela funktionen.

Vilket betyder att en ”tap to tip"-skylt är en QR-kod som man öppnar genom att röra vid den
i stället för att sikta. Samma destination, samma webbsida, samma betalning som sker i
webbläsaren. Till och med specialisterna säger det, om man läser dem noga: tiptaps egen sajt
beskriver sin enhet för fritt belopp som en där *”när givare håller upp sin telefon mot en
anpassad donationsenhet dirigeras de till din insamlingssida på nätet."* Dirigeras till en
sida. För det är vad ett tagg kan göra.

Det här är genuint användbart, och det är billigt — tomma NTAG213-klistermärken börjar runt
**0,24 $ styck** i flerpack. Har du redan en drickssida kostar det dig småpengar att sätta
ett tagg på fodralet bredvid den tryckta koden, och det ger vissa fans en snabbare väg in.

Men var klar över vad du har köpt: **en andra ytterdörr till samma sida.** Ingen kortmaskin.

### Och utomhus är det en kinkig ytterdörr

Felfallen är verkliga, och ingen som säljer taggar räknar upp dem:

- **Fanets telefon måste vara upplåst och i användning.** Apples egen dokumentation är tydlig:
  taggläsning i bakgrunden sker bara medan iPhonen är i användning, och är telefonen låst
  tvingar systemet användaren att låsa upp först.
- **Det fungerar inte medan kameran är öppen.** Apple listar en kamera som används som ett av
  de tillstånd där taggläsning i bakgrunden inte är tillgänglig. Njut av ironin: ett fan som
  sträcker sig efter kameran för att skanna din QR-kod har just stängt av ditt NFC-tagg.
- **Det kräver en iPhone XS eller nyare**, och på Android krävs att NFC är påslaget — vilket
  vissa energisparlägen slår av.
- **Räckvidden är runt 4 cm.** Fanet måste faktiskt röra vid saken. I en folkmassa, framåtböjd
  över ett gitarrfodral, är det verkligen mycket begärt.
- **Metall och magneter dödar det.** Ett tagg tejpat på en förstärkare, eller ett fan med ett
  magnetiskt plånboksskal, och ingenting alls händer.

Ett tagg är ett fint andrahandsval. Det är ett dåligt enda val.

## Tap to Pay på mobilen: den faktiska 2026-nyheten

Här är det som har förändrats sedan Tiptap-artiklarna, och som ingen av de unkna
bevakningarna känner till.

**Tap to Pay på iPhone** förvandlar telefonen du redan har i fickan till en kontaktlös
terminal. Ingen dongel, ingen läsare, inget stativ. Apple listar det som tillgängligt i **70+
länder och regioner**, och leverantörerna du kan använda det genom i Europa läser som hela
branschen — bara i Tyskland: Adyen, Mollie, myPOS, Nexi, PAYONE, Rapyd, Revolut, Sparkassen,
Stripe, SumUp, Viva.com. Storbritannien, Frankrike, Nederländerna, Sverige, Finland och Danmark
har alla liknande listor. Du behöver en iPhone XS eller nyare.

**Tap to Pay på Android** finns också men är smalare. Genom Stripe är det allmänt tillgängligt i
AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG och US, med ytterligare
arton länder i offentlig förhandsvisning. Din telefon behöver Android 13 eller nyare, en
NFC-sensor, en orörd bootloader, Google Mobile Services och avstängda utvecklaralternativ — det
sista fångar fler än man skulle tro.

Den praktiska versionen: **SumUp listar Tap to Pay till 0 £ i hårdvara.** Har du en färsk iPhone
och befinner dig i ett land som stöds är inträdeskostnaden för att hålla fram en kontaktlös
terminal numera noll. Bara det faktumet gör varje ”köp det här stativet"-artikel från 2018
obsolet.

## Kortläsare, och vad de egentligen kostar

Vill du ha en separat bit plast — och det finns goda skäl, se nedan — består marknaden av tre
produkter.

| | Hårdvara | Avgift per tryckning på plats |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, ingen fast avgift |
| **SumUp** (Tyskland) | — | **1,39 %**, ingen fast avgift |
| **Zettle / PayPal POS** (UK) | Läsare från 29 £ för förstagångsköpare, 69 £ därefter | **1,75 %**, ingen fast avgift |
| **Square** (UK) | Kontaktlös läsare med chip 19 £ | **1,75 %**, ingen fast avgift |
| **Square** (US) | Kontaktlös läsare med chip 59 $ | **2,6 % + 0,15 $** |

Priserna är exklusive moms och som de publicerats i juli 2026. Gå och kontrollera dem; de rör
sig.

Läs nu tabellen en gång till, för den säger något som motsäger vad du förmodligen har fått höra.

## Avgiftsmatematiken, och det alla får bakvänt

Den gängse visdomen är att kortavgifter förstör små dricks på grund av den fasta avgiften per
transaktion — de tjugofem cent som äter en åttondel av en dricks på 2 €. Det stämmer, och vi har
[skrivit ner matematiken själva](post:build-a-tip-jar-on-your-own-stripe).

Men det stämmer för kortbetalningar *online*. **Europeiska kontaktlösa läsare har mestadels ingen
fast avgift alls.** SumUp, Zettle och Square i Storbritannien och EU tar bara en procentsats.
Vilket betyder:

| En dricks på 2 € | Avgift | Artisten behåller | Faktisk andel |
| --- | --- | --- | --- |
| SumUp-läsare (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, kort online (EES, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Square-läsare (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Mätt enbart på avgiften slår en europeisk tryckterminal en kortbetalning online på en liten dricks,
och det är inte ens jämnt. Vi är en QR-kodsprodukt och vi säger det ändå: på en dricks på 2 €
behåller en SumUp-läsare 0,25 € åt dig som en Stripe-hostad sida inte gör.

Två saker sätter tillbaka det i proportion.

**Hårdvaran är den fasta avgiften, flyttad.** En besparing på 0,25 € per dricks mot en Solo för 79 £
betyder ungefär **trehundra tryckningar innan läsaren har betalat sig själv**. Det är en verklig
siffra för en yrkesverksam gatumusiker och en fånig för någon som spelar två gånger på en sommar.
(Och SumUps Tap to Pay för 0 £ gör det till noll tryckningar — vilket är precis därför det
alternativet spelar större roll än läsarna gör.)

**Och USA vänder tillbaka det.** Squares amerikanska sats på plats bär en fast avgift på 0,15 $, så
en tryckning på 2 $ förlorar en tiondel av sig själv vid terminalen också. Gåvan ”ingen fast avgift"
är europeisk.

Det finns också ett golv du kommer att stöta på: SumUp tar inte emot en betalning under **1 £ / 1 €**.
Vilket spår du än väljer är den riktigt lilla dricksen egentligen ingen korttransaktion.

## Så när slår en tryckning en skanning?

Skala bort tekniken och det här är en fråga om fanets händer.

**En tryckning kräver att fanets telefon är upplåst och i handen, och kräver att du håller fram
något.** När båda stämmer är det det snabbaste som finns inom betalningar. Ingen app, inget siktande,
inget skrivande, klart på en sekund.

**En skanning kräver att fanet öppnar en kamera** — en extra medveten handling — men den kräver
ingenting alls av dig. Koden sitter på fodralet. Den fungerar för ett fan som står längst bak. Den
fungerar för fyrtio personer samtidigt. Den fungerar medan du fortfarande spelar.

Vilket ger en ärlig uppdelning:

- **Tryckningen vinner när du kan gå fram till folk.** Slutet på setet, hatten runt, ett fan i taget,
  du fri att hålla en terminal. En tryckning är en mindre trögflytande fråga än ”ta fram kameran", och
  i det ögonblicket är du fysiskt närvarande för att avsluta den.
- **Skanningen vinner när du inte kan.** Mitt i en låt. En publik tre rader djup. En plats där du inte
  kan lämna förstärkaren. Alla som vill ge i förbifarten. En terminal betjänar exakt en person; en
  tryckt kod betjänar hela torget, samtidigt, och kräver inte att du slutar spela för att betjäna den.

Den sista punkten är den terminalleverantörerna aldrig gör, och den är den största. **En kortläsare är
en flaskhals med kö.** En QR-kod har ingen kö.

Och här är delen som löser upp halva argumentet: på en välbyggd drickssida **slutar skanningen ändå i
en tryckning**. Fanet skannar, sidan öppnas, och telefonen erbjuder Apple Pay eller Google Pay. De
dubbelklickar, håller upp telefonen mot ansiktet, klart. Från fanets sida är det en kontaktlös
betalning — samma plånbok, samma kort, samma två sekunder — och du köpte ingen hårdvara för att få det
att hända.

## Var live.tips står, och när du ska köpa en SumUp i stället

[live.tips](https://github.com/mekedron/live.tips) är en QR-baserad dricksburk. En kod, som aldrig
ändras, riktad rakt mot artistens egen Stripe-betallänk. Det finns inget live.tips-saldo, ingen andel
och ingen plattform i vägen — avgiften är Stripes egen och Stripe tar den direkt av artisten. Det är
MIT-licensierat, och plattan på scenen visar varje dricks i samma stund den landar. Vi skrev ner
pengavägen i [hur live.tips hanterar pengar](post:how-live-tips-handles-money), och varför det är
[en kod snarare än en per leverantör](post:one-qr-code-every-payment-method).

Den sidan stöder Apple Pay och Google Pay. Så live.tips *är* kontaktlöst från fanets sida — tryckningen
som betyder något, den i slutet, utan någon terminal att köpa, ladda eller tappa i regnet. Det är bara
ingen terminal.

**Är det du vill att fysiskt hålla fram något som en främling trycker på, köp en kortläsare.** Ta SumUps
Tap to Pay om din telefon och ditt land stöder det, för det kostar ingenting; ta en Solo om du hellre
slipper räcka din egen mobil till en folkmassa. Hur som helst kommer den att slå vår avgift på en
tryckning på 2 € i Europa, och det säger vi hellre än låtsas om motsatsen.

Du kan också göra båda, och en hel del gatumusiker borde: koden tejpad på fodralet hela kvällen, som
fångar förbipasserande medan du spelar, och terminalen i handen under de tio sekunderna efter sista
ackordet när första raden fiskar i fickorna. De konkurrerar inte. De fångar olika människor.

Vad ingen av dem är: ett stativ från 2018 som tar 5%.

Avgifter, hårdvarupriser och landstillgänglighet som de publicerats av Apple, Stripe, SumUp, Zettle/PayPal och Square i juli 2026, exklusive moms. Priser på NFC-klistermärken från GoToTags. Tiptaps villkor från 2018 som de rapporterats av Brunel University och Finextra. Allt här förändras; kontrollera det mot leverantören innan du lägger ut pengar.
{: .footnote }
