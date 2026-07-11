---
title: Dricks är inte donationer — och Stripe behandlar dem som två olika verksamheter
description: En gatumusikant som ber om en ”donationsknapp" beskriver en verksamhet som Stripe förbjuder i större delen av Europa. Dricks betalar för en tjänst du redan utfört; en donation är insamling för välgörande ändamål. Skillnaden avgör vilken kategori ditt konto hamnar i — och en enda API-parameter kan välja fel åt dig.
slug: dricks-ar-inte-donation
---

Varje verktyg på internet vill att du ska kalla det en donation. Knapparna säger
*Donate*. Blogginläggen säger *donationsknapp för musiker*. Pluginkatalogerna
säger *ta emot donationer*. Är du musiker och letar efter ett sätt att få betalt
av folk som inte har kontanter, följer ordet efter dig överallt.

Sedan öppnar du ett Stripe-konto, och Stripe frågar vad din verksamhet gör. Och i
det ögonblicket slutar ordet vara marknadsföringstext och blir en
**verksamhetskategori** — en som Stripe i större delen av Europa inte tillåter.

Det här är ingen pedanteri, och det är ingen juristfiness. Det är den enskilda
fråga som mest sannolikt får en fullkomligt vanlig gatumusikants betalkonto
granskat, fördröjt eller nekat. Nästan ingen har skrivit ner det rakt ut för dem
som spelar live, så här är det.

## Två ord, två verksamheter

Stripe drar gränsen själva, i en mening var. Ur
[Krav för att ta emot dricks eller donationer](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> dricks måste ges för en vara eller tjänst som har tillhandahållits (t.ex.
> innehåll)

> en donation måste vara knuten till ett specifikt välgörande ändamål som du
> åtar dig att uppfylla

Stripes sidor är på engelska; citaten här har vi översatt åt dig, och originalen
ligger bakom länkarna.

Läs de två meningarna två gånger, för allt annat i det här inlägget faller ut ur
dem.

**Dricks** tittar bakåt, på något som redan hänt. Tjänsten levererades, fanet
gillade den, fanet betalade extra. Pengarna är villkorslösa och du är ingen något
mer skyldig. Det är dricksraden på restaurangnotan, mynten i hatten, femtiolappen
som trycks i en hand efter sista låten.

En **donation** tittar framåt, på något du har lovat att göra. Det finns en sak
att verka för. Det finns ett ändamål du har beskrivit för den som ger. Och —
Stripe är uttrycklig på den punkten — pengarna måste faktiskt gå till det
ändamålet. Du förvaltar dem för något du sagt att du ska åstadkomma.

Det är inte två nyanser av samma handling. Det är två olika relationer, med två
olika uppsättningar skyldigheter, och Stripe tecknar dem som två olika
verksamheter.

## En gatumusikant befinner sig entydigt på dricksidan

Du stod två timmar på ett torg och spelade. Fyrtio personer stannade. En av dem
skannar din kod och skickar dig fem euro.

**Det är dricks.** Framförandet är tjänsten. Den tillhandahölls — de såg den ske.
Det finns ingen sak att verka för, ingen mottagare, inget ändamål du åtagit dig
att uppfylla, och ingen har anförtrott dig pengar för ett projekt. Du är en
utövande konstnär som får betalt för ett framförande, vilket är ett av de äldsta
och minst kontroversiella affärsupplägg som finns.

Förvirringen kommer av att en gatumusikants dricks är *frivillig*, och vi har
tränats att tro att frivilliga pengar är välgörenhetspengar. Det är de inte.
Dricks är också frivillig. Frivilligheten är inte det som gör något till en
donation — ett **välgörande ändamål** är det.

Så när din skylt säger ”donationer mottages tacksamt" är du inte blygsam eller
artig. Du beskriver, på betalförmedlarens språk, en verksamhet du inte bedriver.

## Vad ordet faktiskt kostar dig

Här blir abstraktionen till pengar.

Stripe publicerar en
[lista över begränsade verksamheter](https://stripe.com/legal/restricted-businesses)
— det du inte får göra med ett Stripe-konto, eller bara får göra i vissa länder.
Under rubriken **Crowdfunding och insamling** står den här raden, ordagrant:

> Organisationer som samlar in medel för ett välgörande ändamål (Obs: Stöds i
> Australien, Kanada, Storbritannien och USA. Förbjudet i alla andra länder.)

Läs parentesen långsamt. Insamling för välgörande ändamål är en **stödd
verksamhet i fyra länder** — Australien, Kanada, Storbritannien, USA — och
**förbjuden överallt annars.**

Överallt annars innefattar Sverige. Det innefattar Tyskland, Frankrike, Spanien,
Italien, Nederländerna, Polen, Finland och varje annat land där en gatumusikant
rimligen kan stå. De flesta av världens gatumusikanter bor i ”alla andra länder".

Samma sida listar också *”insamling som bedrivs av ideella organisationer,
välgörenhetsorganisationer, politiska organisationer och företag som erbjuder en
belöning i utbyte mot en donation"* som begränsad, och Stripes sida om dricks och
donationer lägger en uppsättning landsspecifika regler ovanpå: i Japan kan
privatpersoner inte ta emot donationer alls; i Singapore får bara statligt
registrerade välgörande eller religiösa organisationer göra det; i Indien,
Hongkong och Thailand stöds donationer inte.

Så en musiker i Stockholm som skriver ”donationer till min musik" i Stripes
registreringsformulär har just beskrivit en verksamhet som Stripe förbjuder i
Sverige. Inte för att gatumusik är förbjudet — gatumusik är helt i sin ordning —
utan för att orden hen valde tillhör en kategori som är det.

## Nu kalibreringen, för det här är ingen skräckhistoria

**Gatumusikanter är ingen begränsad verksamhet.** Att ta emot dricks är ingen
begränsad verksamhet. Livespelningar står inte på listan, kommer inte att sätta
dig på listan, och är ungefär så vardagligt som något kan bli med ett betalkonto.
Beskriver du dig själv korrekt rör inget av det här vid dig, och uppsättningen
blir tråkig, vilket är precis som det ska vara.

Risken här är inte Stripe. Risken är att **klassificera sig själv fel** — att
kliva in i rummet och presentera sig som en välgörenhetsinsamlare när man är
gitarrist. Stripe har inget sätt att veta att du menade ”ge mig gärna dricks". De
har bara formuläret du fyllde i, verksamhetsbeskrivningen du skrev och orden på
sidan din QR-kod pekar på.

Ingen på Stripe jagar gatumusikanter. De läser bara det du sa till dem.

## Fällan är en parameter djup

Här kommer den del nästan ingen skriver ner, och den är det mest användbara i hela
inlägget.

Stripes Payment Links har en parameter som heter `submit_type`.
[API-referensen](https://docs.stripe.com/api/payment-link/object) beskriver den
som något nästan kosmetiskt:

> Anger vilken typ av transaktion som utförs, vilket anpassar relevant text på
> sidan, till exempel skicka-knappen.

*Anpassar relevant text.* Du skulle rimligen dra slutsatsen att det ändrar en
knapptext, och att en dricksburk självklart borde säga *Donate* snarare än *Buy*,
eftersom *Buy* — köp — är ett underligt ord att trycka under en gatumusikants
hatt.

Sedan läser du vad de enskilda värdena faktiskt gör:

> `donate` — Rekommenderas när du tar emot donationer. Skicka-knappen får
> etiketten 'Donate' och URL:erna använder värdnamnet `donate.stripe.com`

> `pay` — Skicka-knappen får etiketten 'Buy' och URL:erna använder värdnamnet
> `buy.stripe.com`

**Det är ingen etikett. Det är ett värdnamn.** Sätt `submit_type=donate` och
länken Stripe räcker dig — den du gör till en QR-kod, skriver ut och tejpar på
gitarrfodralet — bor på `donate.stripe.com`. Varje fan som skannar den ser en
donationssida. Varje betalning i din instrumentpanel kom in genom ett
donationsflöde. QR-koden på ditt fodral talar om för Stripe, för din publik och
till slut för dig själv att du samlar in donationer.

Du skrev aldrig ordet ”donation" någonstans. En API-parameter skrev det åt dig,
och tryckte det på en plastskylt på ett offentligt torg.

Det är en lätt fälla att gå i, och det är inte läsarens fel när det händer:
parametern är dokumenterad som en textändring, *Donate* är uppenbart det trevligare
ordet att trycka under en gatumusikants hatt, och konsekvensen — en
verksamhetsklassificering — står två meningar längre ner än de flesta läser.

live.tips skickar `submit_type=pay`. Varje artists länk är en `buy.stripe.com`-länk,
och koden bär en kommentar som säger varför, eftersom det är precis sådant en
framtida bidragsgivare annars skulle ”förbättra".

## Vad en musiker faktiskt bör göra

Inget av det här kräver en jurist. Det kräver fem minuter och några raka ord.

- **Beskriv den verkliga verksamheten** i Stripes registrering. ”Livemusik."
  ”Gatumusikant." ”Musiker — dricks och gratifikationer från publik vid
  liveframträdanden." Säg att du uppträder, och att betalningarna är dricks för
  de framträdandena.
- **Välj en kategori som stämmer.** Liveunderhållning, scenkonst, musiker. Inte
  välgörenhet, inte ideell verksamhet, inte insamling.
- **Använd `submit_type=pay`** om du bygger din Payment Link själv. Har ett
  verktyg byggt den åt dig, titta på URL:en det producerade: `buy.stripe.com` är
  en dricksburk, `donate.stripe.com` är en donationssida. Det är en
  tvåsekunderskoll, och den talar om vad ditt verktyg tror att du är.
- **Kalla det inte en donation** — inte på skylten, inte på din webbplats, inte i
  verksamhetsbeskrivningen hos Stripe. ”Dricks", ”dricksburk", ”stötta bandet",
  ”bjud oss på en öl" beskriver alla det som faktiskt sker. ”Donera" beskriver
  något annat.
- **Håll en riktig insamling separat.** Spelar du en välgörenhetsspelning och
  pengarna går till en sak, då *är* det på riktigt insamling för välgörande
  ändamål, och reglerna ovan handlar nu om dig — landslistan inräknad. Gör det
  under rätt konto, i rätt land, efter att ha läst Stripes villkor, och aldrig
  genom dricksburken du använder på vanliga kvällar.

Den sista punkten förtjänar eftertryck, för den är den ärliga halvan av
argumentet. Vi säger inte att donationer är av ondo eller att musiker aldrig får
samla in pengar till en sak. Vi säger att det är en **annan verksamhet**, med
andra regler, och att tyst köra den genom samma QR-kod är precis så båda blir ett
problem för dig.

En rad till från Stripes sida om dricks och donationer är värd att känna till,
eftersom den utesluter en tredje sak som folk blandar ihop med båda: Stripe gör
inte *”betalningshantering för personliga överföringar eller överföringar mellan
privatpersoner (t.ex. att skicka pengar mellan vänner)"*. Dricks är inte heller en
gåva mellan vänner. Vill du ha det spåret — ett fan som helt enkelt skickar dig
pengar, person till person — så är det vad Revolut och MobilePay är, och det är
därför de lever
[helt utanför Stripe](post:one-qr-code-every-payment-method) i vår app.

## Vad det här inlägget inte är

Det är ingen juridisk rådgivning. Det är ingen skatterådgivning — hur dricks
beskattas varierar enormt mellan länder, ibland mellan städer, och det ligger helt
utanför ramen här; fråga någon kvalificerad där du bor.

Och det är inget löfte om ditt konto. **Huruvida Stripe godkänner dig är enbart
Stripes beslut.** live.tips har ingen relation till Stripe, ingen möjlighet att
påverka en granskning och inget sätt att överklaga en åt dig. Vad vår mjukvara kan
göra är att låta bli att lägga ord i din mun. Vad du skriver i formuläret är
fortfarande ditt att skriva.

Policyer ändras också. Raderna som citeras här låg på Stripes sidor i juli 2026,
och länkarna finns där; gå och läs dem själv i stället för att lita på ett
blogginlägg, det här inräknat.

## Kortversionen

Du spelade setet. De såg det. De betalade dig för det.

Det är dricks. Säg det — på skylten, i formuläret, i URL:en — och det tråkiga
utfall du vill ha är det du får. Vi bygger dricksburken kring precis det påståendet,
hela vägen ner till
[vilket Stripe-värdnamn din QR-kod pekar på](post:build-a-tip-jar-on-your-own-stripe),
och vill du ha den vidare bilden av vart pengarna faktiskt går, finns den
[här](post:how-live-tips-handles-money).
