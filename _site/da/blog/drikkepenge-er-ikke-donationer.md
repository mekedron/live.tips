# Drikkepenge er ikke donationer — og Stripe behandler dem som to forskellige forretninger

> En gademusiker, der beder om en »donationsknap«, beskriver en forretning, som Stripe forbyder i det meste af Europa. Drikkepenge betaler for en ydelse, du allerede har leveret; en donation er indsamling til velgørende formål. Forskellen afgør, hvilken kategori din konto lander i — og en enkelt API-parameter kan vælge den forkerte for dig.

Canonical: https://live.tips/da/blog/drikkepenge-er-ikke-donationer/
Published: 2026-07-11
Language: da
Tags: Stripe, donations, busking, compliance, how-to

---

Hvert eneste værktøj på internettet vil have dig til at kalde det en donation.
Knapperne siger *Donate*. Blogindlæggene siger *donationsknap til musikere*.
Plugin-katalogerne siger *modtag donationer*. Er du musiker og leder efter en måde
at få penge fra folk, der ikke har kontanter, følger ordet efter dig overalt.

Så åbner du en Stripe-konto, og Stripe spørger, hvad din forretning laver. Og i
det øjeblik holder ordet op med at være marketingtekst og bliver til en
**forretningskategori** — en, som Stripe i det meste af Europa ikke tillader.

Det her er ikke pedanteri, og det er ikke en juridisk spidsfindighed. Det er det
enkeltspørgsmål, der med størst sandsynlighed får en fuldstændig almindelig
gademusikers betalingskonto sat til gennemgang, forsinket eller afvist. Næsten
ingen har skrevet det ligeud til dem, der spiller live, så her er det.

## To ord, to forretninger

Stripe trækker selv linjen, med én sætning hver. Fra
[Krav for at modtage drikkepenge eller donationer](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> drikkepenge skal gives for en vare eller ydelse, der er blevet leveret (f.eks.
> indhold)

> en donation skal være knyttet til et bestemt velgørende formål, som du
> forpligter dig til at opfylde

Stripes sider er på engelsk; citaterne her har vi oversat for dig, og originalerne
ligger bag linkene.

Læs de to sætninger to gange, for alt andet i dette indlæg falder ud af dem.

**Drikkepenge** ser bagud på noget, der allerede er sket. Ydelsen blev leveret,
fanen kunne lide den, fanen betalte ekstra. Pengene er ubetingede, og du skylder
intet yderligere. Det er drikkepengelinjen på restaurantregningen, mønterne i
hatten, den halvtredser der bliver trykket i en hånd efter sidste nummer.

En **donation** ser fremad på noget, du har lovet at gøre. Der er en sag. Der er
et formål, du har beskrevet for den, der giver. Og — Stripe er eksplicit på det
punkt — pengene skal rent faktisk gå til det formål. Du forvalter dem for noget,
du har sagt, du vil udrette.

Det er ikke to nuancer af den samme handling. Det er to forskellige forhold, med
to forskellige sæt forpligtelser, og Stripe tegner dem som to forskellige
forretninger.

## En gademusiker er utvetydigt på drikkepengesiden

Du stod to timer på en plads og spillede. Fyrre mennesker stoppede op. En af dem
scanner din kode og sender dig fem euro.

**Det er drikkepenge.** Optrædenen er ydelsen. Den blev leveret — de så den ske.
Der er ingen sag, ingen modtager, intet formål, du har forpligtet dig til at
opfylde, og ingen har betroet dig penge til et projekt. Du er en udøvende kunstner,
der får betaling for en optræden, hvilket er en af de ældste og mindst
kontroversielle handler, der findes.

Forvirringen kommer af, at en gademusikers drikkepenge er *frivillige*, og vi er
blevet oplært til at tro, at frivillige penge er velgørenhedspenge. Det er de
ikke. Drikkepenge er også frivillige. Frivilligheden er ikke det, der gør noget
til en donation — et **velgørende formål** er.

Så når dit skilt siger »donationer modtages gerne«, er du ikke beskeden eller
høflig. Du beskriver, på betalingsudbyderens sprog, en forretning, du ikke er i.

## Hvad ordet faktisk koster dig

Her bliver abstraktionen til penge.

Stripe udgiver en
[liste over begrænsede forretninger](https://stripe.com/legal/restricted-businesses)
— det, du ikke må lave med en Stripe-konto, eller kun må lave i visse lande. Under
overskriften **Crowdfunding og indsamling** står denne linje, ordret:

> Organisationer, der indsamler midler til et velgørende formål (Bemærk:
> Understøttet i Australien, Canada, Storbritannien og USA. Forbudt i alle andre
> lande.)

Læs parentesen langsomt. Indsamling til velgørende formål er en **understøttet
forretning i fire lande** — Australien, Canada, Storbritannien, USA — og
**forbudt alle andre steder.**

Alle andre steder inkluderer Danmark. Det inkluderer Tyskland, Frankrig, Spanien,
Italien, Holland, Polen, Finland og ethvert andet land, hvor en gademusiker med
rimelighed kunne stå. De fleste af verdens gademusikere bor i »alle andre lande«.

Den samme side opregner også *»indsamling foretaget af nonprofitorganisationer,
velgørende organisationer, politiske organisationer og virksomheder, der tilbyder
en belønning til gengæld for en donation«* som begrænset, og Stripes side om
drikkepenge og donationer lægger et sæt landespecifikke regler oveni: i Japan kan
privatpersoner slet ikke modtage donationer; i Singapore må kun statsregistrerede
velgørende eller religiøse organisationer; i Indien, Hongkong og Thailand er
donationer ikke understøttet.

Så en musiker i København, der skriver »donationer til min musik« i Stripes
oprettelsesformular, har lige beskrevet en forretning, som Stripe forbyder i
Danmark. Ikke fordi gademusik er forbudt — gademusik er helt i orden — men fordi
de ord, hun valgte, hører til en kategori, der er det.

## Og så kalibreringen, for det her er ikke en gyserhistorie

**Gademusikere er ikke en begrænset forretning.** Drikkepenge er ikke en begrænset
forretning. Liveoptræden står ikke på listen, kommer ikke til at sætte dig på
listen, og er omtrent så almindelig en ting, som man kan lave med en
betalingskonto. Beskriver du dig selv præcist, rører intet af det her ved dig, og
opsætningen bliver kedelig, hvilket er præcis, som det skal være.

Risikoen her er ikke Stripe. Risikoen er **at klassificere sig selv forkert** — at
træde ind i rummet og præsentere sig som velgørenhedsindsamler, når man er
guitarist. Stripe har ingen mulighed for at vide, at du mente »giv mig gerne
drikkepenge«. De har kun formularen, du udfyldte, forretningsbeskrivelsen, du
skrev, og ordene på den side, din QR-kode peger på.

Ingen hos Stripe går på jagt efter gademusikere. De læser blot det, du fortalte
dem.

## Fælden er én parameter dyb

Her er den del, næsten ingen skriver ned, og den er det mest nyttige i hele
indlægget.

Stripes Payment Links har en parameter, der hedder `submit_type`.
[API-referencen](https://docs.stripe.com/api/payment-link/object) beskriver den
som noget nærmest kosmetisk:

> Angiver den type transaktion, der udføres, hvilket tilpasser relevant tekst på
> siden, såsom knappen til at indsende.

*Tilpasser relevant tekst.* Man ville med rimelighed konkludere, at det ændrer en
knaptekst, og at en tipkrukke selvfølgelig burde sige *Donate* frem for *Buy*,
fordi *Buy* — køb — er et underligt ord at trykke under en gademusikers hat.

Så læser man, hvad de enkelte værdier rent faktisk gør:

> `donate` — Anbefales, når du modtager donationer. Indsend-knappen får etiketten
> 'Donate', og URL'erne bruger værtsnavnet `donate.stripe.com`

> `pay` — Indsend-knappen får etiketten 'Buy', og URL'erne bruger værtsnavnet
> `buy.stripe.com`

**Det er ikke en etiket. Det er et værtsnavn.** Sæt `submit_type=donate`, og det
link, Stripe rækker dig — det, du laver om til en QR-kode, printer og taper på din
guitarkasse — bor på `donate.stripe.com`. Hver eneste fan, der scanner den, ser en
donationsside. Hver eneste betaling i dit dashboard kom ind gennem et
donationsflow. QR-koden på din kasse fortæller Stripe, fortæller dit publikum og
til sidst også dig selv, at du samler donationer ind.

Du skrev aldrig ordet »donation« nogen steder. Én API-parameter skrev det for dig
og trykte det på et plastskilt på en offentlig plads.

Det er en let fælde at gå i, og det er ikke læserens skyld, når det sker:
parameteren er dokumenteret som en tekstændring, *Donate* er åbenlyst det pænere
ord at trykke under en gademusikers hat, og konsekvensen — en
forretningsklassificering — står to sætninger længere nede, end de fleste læser.

live.tips sender `submit_type=pay`. Hver kunstners link er et
`buy.stripe.com`-link, og koden bærer en kommentar, der siger hvorfor, for det er
den slags, en fremtidig bidragyder ellers ville »forbedre«.

## Hvad en musiker faktisk bør gøre

Intet af det her kræver en advokat. Det kræver fem minutter og nogle ligefremme
ord.

- **Beskriv den rigtige forretning** i Stripes oprettelse. »Livemusik.«
  »Gademusiker.« »Musiker — drikkepenge fra publikum ved liveoptrædener.« Sig, at
  du optræder, og at betalingerne er drikkepenge for de optrædener.
- **Vælg en kategori, der passer.** Liveunderholdning, scenekunst, musiker. Ikke
  velgørenhed, ikke nonprofit, ikke indsamling.
- **Brug `submit_type=pay`**, hvis du selv bygger dit Payment Link. Har et værktøj
  bygget det for dig, så kig på den URL, det producerede: `buy.stripe.com` er en
  tipkrukke, `donate.stripe.com` er en donationsside. Det er et to-sekunders
  tjek, og det fortæller dig, hvad dit værktøj tror, du er.
- **Kald det ikke en donation** — ikke på skiltet, ikke på din hjemmeside, ikke i
  forretningsbeskrivelsen hos Stripe. »Drikkepenge«, »tipkrukke«, »støt bandet«,
  »giv os en øl« beskriver alle det, der rent faktisk sker. »Doner« beskriver
  noget andet.
- **Hold en rigtig indsamling adskilt.** Spiller du en velgørenhedskoncert, og går
  pengene til en sag, så *er* det ægte indsamling til velgørende formål, og
  reglerne ovenfor handler nu om dig — landelisten inklusive. Gør det under den
  rigtige konto, i det rigtige land, efter at have læst Stripes vilkår, og aldrig
  gennem den tipkrukke, du bruger på almindelige aftener.

Det sidste punkt fortjener eftertryk, for det er den ærlige halvdel af argumentet.
Vi siger ikke, at donationer er af det onde, eller at musikere aldrig må samle
penge ind til en sag. Vi siger, at det er en **anden aktivitet**, med andre
regler, og at det er sådan, begge dele bringer dig i vanskeligheder, hvis du
stiltiende kører dem gennem den samme QR-kode.

Endnu en linje fra Stripes side om drikkepenge og donationer er værd at kende,
eftersom den udelukker en tredje ting, folk forveksler med begge: Stripe laver
ikke *»betalingsbehandling for personlige overførsler eller overførsler mellem
privatpersoner (f.eks. at sende penge mellem venner)«*. Drikkepenge er heller ikke
en gave mellem venner. Vil du have den skinne — en fan, der bare sender dig penge,
person til person — så er det, hvad Revolut og MobilePay er, og det er derfor, de
lever [helt uden for Stripe](https://live.tips/da/blog/en-qr-kode-hver-betalingsmetode/) i vores app.

## Hvad dette indlæg ikke er

Det er ikke juridisk rådgivning. Det er ikke skatterådgivning — hvordan
drikkepenge beskattes, varierer enormt fra land til land, undertiden fra by til
by, og det ligger fuldstændig uden for rammen her; spørg en kvalificeret person,
der hvor du bor.

Og det er ikke et løfte om din konto. **Om Stripe godkender dig, er alene Stripes
beslutning.** live.tips har intet forhold til Stripe, ingen mulighed for at
påvirke en gennemgang og ingen måde at anke en på dine vegne. Hvad vores software
kan gøre, er at lade være med at lægge dig ord i munden. Hvad du skriver i
formularen, er stadig dit at skrive.

Politikker ændrer sig også. De linjer, der er citeret her, stod på Stripes sider i
juli 2026, og linkene er der; gå og læs dem selv i stedet for at stole på et
blogindlæg, dette inklusive.

## Den korte version

Du spillede sættet. De så det. De betalte dig for det.

Det er drikkepenge. Sig det — på skiltet, i formularen, i URL'en — og det kedelige
udfald, du ønsker dig, er det, du får. Vi bygger tipkrukken op om præcis den
påstand, hele vejen ned til
[hvilket Stripe-værtsnavn din QR-kode peger på](https://live.tips/da/blog/byg-en-drikkepengekrukke-pa-din-egen-stripe-konto/),
og vil du have det bredere billede af, hvor pengene faktisk går hen, er det
[her](https://live.tips/da/blog/sadan-handterer-live-tips-penge/).
