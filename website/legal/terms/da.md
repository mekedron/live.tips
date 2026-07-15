---
title: Brugsvilkår
description: live.tips er gratis open source-software. Vi er ikke en betalingsudbyder, vi holder aldrig dine penge, og vi lover intet om drikkepenge, vi ikke kan se. Detaljerne, i almindelige ord.
updated: 2026-07-15
updated_label: Sidst opdateret 15. juli 2026
---

Disse vilkår dækker live.tips-appen, dette website, den valgfrie live.tips-**konto** og det
valgfrie relæ bag drikkepengesiderne på `tip.live.tips`. live.tips drives af **Nikita
Rabykin**, en enkelt udvikler — ikke et selskab, ikke et team — og udgives som fri og open
source-software under
[MIT-licensen](https://github.com/mekedron/live.tips/blob/main/LICENSE).

Ved at bruge live.tips accepterer du det følgende. Det er kort, fordi live.tips gør meget
lidt på dine vegne — og det er hele pointen.

## Hvad live.tips er

live.tips er **software, du selv kører**. Den forvandler din egen Stripe- (eller Revolut-,
MobilePay-, Monzo-) konto til en live-drikkepengekrukke med en QR-kode og en skærm, der
fyldes op, efterhånden som fans giver drikkepenge.

## Hvad live.tips ikke er

**Vi er ikke en betalingstjeneste, en bank, en deponeringsordning eller en part i dine
transaktioner.** Vi holder, dirigerer eller rører aldrig nogens penge. Drikkepenge rejser
direkte fra fanen til kunstnerens egen betalingskonto. Der er ingen live.tips-saldo i
midten, fordi der slet ikke findes nogen live.tips-saldo.

Konkret betyder det:

- Vi tager **ingen kommission** og opkræver **intet gebyr**. Der er ikke noget at betale os.
- Vi **kan ikke refundere drikkepenge**, fordi vi aldrig har haft dem. Refusioner tilhører
  kunstneren og deres betalingsudbyder.
- Vi **kan ikke se, fryse, tilbageføre eller genskabe** nogen betaling.
- Dit forhold vedrørende selve pengene er med **Stripe, Revolut, MobilePay eller Monzo**
  under deres vilkår — ikke med os.

## Drikkepenge er betaling for en optræden

Drikkepenge, der indsamles gennem live.tips, er **frivillige betalinger til en kunstner for
deres liveoptræden**. De er **ikke velgørende donationer**, og live.tips er ikke en
indsamlingsplatform. Kunstnere skal beskrive deres virksomhed over for deres
betalingsudbyder i overensstemmelse hermed — Stripe behandler i særdeleshed optræden og
indsamling som to forskellige ting, og kun den ene af dem er dig.

## Konti

En konto er **valgfri**, og der er stadig ikke noget, du skal melde dig til. Appen virker
helt uden konto — det er standarden, alt bliver på din enhed, og ingen live.tips-server er
involveret.

Vil du have dine bands, indstillinger og din historik på mere end én enhed, kan du logge ind
med **Apple**, med **Google** eller som anonym **gæst**. En konto er et sted at opbevare
*dine egne* data, på **Firebase** (Google), læsbare af din konto og af ingen anden. Hvad den
indeholder — og hvad det at logge ind ændrer ved dit privatliv — står i Privatlivspolitikken,
som er værd at læse, før du logger ind.

Har du en konto:

- **Den er din at passe på.** Enhver, der kan logge ind som dig, kan se alt i den. Hold din
  login-metode sikker, og brug **Indstillinger → Sikkerhed** til at gennemgå dine enheder,
  tilbagekalde en eller logge ud alle andre steder.
- **En gæstekonto kan ikke gendannes.** Den har ingen e-mail og ingen adgangskode. Mister du
  alle enheder, der er logget ind på den, er dens data væk — det er prisen for at logge ind
  uden at give os noget. Brug Apple eller Google, hvis det betyder noget for dig.
- **Du er ansvarlig for, hvad der er i den** — dine bandnavne, dine offentlige hilsner og alt
  andet, du lægger derind.
- **At tilføje en enhed kræver din bekræftelse** på en enhed, der allerede er logget ind.
  Bekræft ikke en enhed, du ikke selv har bedt om, og lad ikke nogen fotografere QR-koden for
  så alligevel at trykke bekræft.
- **Push-notifikationer er valgfrie.** En konto, man er logget ind på, kan slå
  push-notifikationer til, pr. enhed, for at høre om drikkepenge og sangønsker, der ankommer,
  mens intet sæt kører. De er slået fra, indtil du slår dem til, og kan slås fra igen når som
  helst; en gæstekonto og en enhed uden konto får ingen.
- **Vi kan suspendere eller slette en konto** — se *At sætte punktum* nedenfor.

## Hvis du er kunstner

Du er ansvarlig for:

- **Din egen betalingskonto** — at holde den i god stand og følge Stripes eller Revoluts,
  MobilePays eller Monzos regler.
- **Din skat.** Drikkepenge er indkomst. Vi indberetter ikke noget til nogen, udsteder intet
  skattedokument og ved ikke, hvad du har tjent.
- **Refusioner, tvister og tilbageførsler**, som du håndterer i dit eget
  betalingsdashboard.
- **Loven der, hvor du optræder** — tilladelser til gadeoptræden, spillestedets regler og
  alt andet lokalt.
- **Det, du offentliggør.** Dit kunstnernavn og din hilsen vises på en offentlig
  drikkepengeside; hold dem lovlige og dine egne.
- **Din Stripe-nøgle.** Det er en begrænset nøgle, du selv har oprettet. **Uden en konto bor
  den kun på din enhed.** Logger du ind, flytter den til vores server, krypteret, så ingen —
  ikke en anden konto, ikke os for åbent skue, og ikke engang dig — kan læse den tilbage; fra
  da af rapporterer Stripe dine drikkepenge til vores server, og dine andre enheder bruger
  nøglen kun gennem os. Uanset hvad er den din: behandl en enhed, der holder den, som du ville
  behandle kontanter, og tilbagekald nøglen i dit Stripe-dashboard, hvis en forsvinder.
  Privatlivspolitikken redegør for dette, før du logger ind.
- **Dine bands og de fan-hilsner, du sætter på skærmen.** Et navn og en hilsen vises for et
  lokale fuldt af mennesker. Hvad der kommer op på den skærm, er dit at moderere.

## Hvis du er fan

- At give drikkepenge er **frivilligt**, og når de først er sendt, er drikkepenge som
  udgangspunkt **endelige** — en live-skilling er ikke et køb med returret.
- Er noget gået galt med en betaling, så tag det op med **kunstneren** eller med den
  betalingsudbyder, der behandlede den. Vi har ingen registrering af den og ingen magt over
  den.
- Hold venligst det navn og den hilsen, du vedhæfter, lovlig og anstændig. De vises på en
  skærm, på en scene, foran et lokale fuldt af mennesker.
- **Et sangønske er drikkepenge, ikke en ordre.** Har kunstneren slået sangønsker til, kan
  du give drikkepenge til en sang — men pengene er frivillige drikkepenge som alle andre, og
  at betale, eller at betale mest, **garanterer ikke**, at sangen bliver spillet. Det er
  kunstnerens afgørelse.

## Uverificerede drikkepenge — læs lige den her

Revolut, MobilePay og Monzo giver en app **ingen måde at bekræfte, at en betaling rent
faktisk er sket**. Drikkepenge sendt via de metoder dukker op på kunstnerens skærm **i det
øjeblik, fanen sender formularen** — uanset om vedkommende derefter gennemfører betalingen
eller ej.

live.tips markerer disse drikkepenge som **uverificerede**, og det betyder præcis det:
*nogen sagde, at de betalte.* De er en sceneeffekt, ikke en kvittering.

**Behandl aldrig uverificerede drikkepenge som bevis for betaling.** Kunstnere skal afstemme
mod deres egen Revolut-, MobilePay- eller Monzo-app. Drikkepenge via Stripe er de eneste,
live.tips rent faktisk kan bekræfte, og det er derfor, Stripe er den anbefalede metode.

## Relæet og drikkepengesiderne

Drikkepengesider bor på `tip.live.tips` og serveres af et lille relæ, vi driver på Firebase.
Det tilbydes **gratis, som en venlig gestus, uden nogen form for garanti**. Det er
best effort: det kan blive rate-limitet, det kan være utilgængeligt, og drikkepenge kan blive
forsinket eller gå tabt. Hvor længe drikkepenge gemmes, afhænger af, om kunstneren er logget
ind: for en **drikkepengeside uden en konto bag sig** gemmer relæet med vilje intet, der ville
lade nogen genskabe drikkepenge bagefter — leverede drikkepenge slettes i det øjeblik,
kunstnerens skærm viser dem, og ikke-leverede fejes væk inden for en time. For en **konto, man
er logget ind på**, skrives drikkepengene ind i den kunstners egen historik og gemmes, så
længe bandet består. Privatlivspolitikken redegør for begge tilfælde i sin helhed.

- En drikkepengeside **uden en konto bag sig slettes efter 90 dages inaktivitet**.
- Vi kan **rate-limite, blokere eller slette enhver drikkepengeside**, når som helst, uden
  varsel — i særdeleshed hvor vi ser svindel, identitetsmisbrug, misbrug, ulovligt indhold
  eller et forsøg på at overbelaste tjenesten.
- Vi kan **ændre relæet eller lukke det helt ned**. Skulle vi nogensinde gøre det, vil
  opsætninger med kun Stripe blive ved med at virke, fordi de aldrig var afhængige af os.

Du må ikke bruge relæet, en drikkepengeside eller en konto til at udgive dig for at være en
anden, til at begå svindel, til at offentliggøre ulovligt eller krænkende indhold, til at
indsamle velgørende donationer under falske forudsætninger, til at omgå rate-limits eller
anti-bot-tjekket eller til at angribe tjenesten.

## At sætte punktum

- **Du** kan stoppe når som helst: log ud, fjern et band, slet en drikkepengeside, eller
  afinstaller appen. Privatlivspolitikken siger præcis, hvad hver af de handlinger sletter —
  og siger ærligt, at det at slette en hel konto indtil videre er en e-mail til
  **[contact@live.tips](mailto:contact@live.tips)** frem for en knap i appen.
- **Vi** kan suspendere, tilbagekalde eller slette en konto, en drikkepengeside eller adgang
  til tjenesten, hvor den bruges til noget af det ovennævnte, eller hvor det at lade den køre
  ville udsætte tjenesten eller andre mennesker for risiko. Der er ingen ankenævn her. Der er
  en e-mailadresse og et menneske, der læser den.
- Bliver den hostede tjeneste nogensinde lukket ned, siger vi det på dette website. Der er
  intet af værdi låst inde i den: pengene er allerede på din egen betalingskonto, appen er
  open source, og en opsætning med kun Stripe havde aldrig brug for os.

## Ingen garanti

live.tips leveres **“som den er”, uden nogen form for garanti**, udtrykkelig eller
underforstået, herunder enhver garanti for salgbarhed, egnethed til et bestemt formål eller
ikke-krænkelse. Det er standardpositionen i MIT, og den er ment bogstaveligt.

Vi lover ikke, at softwaren er fri for fejl, at appen viser hver eneste skilling, at din
konto synkroniserer, at relæet er tilgængeligt under dit sæt, eller at nogen
tredjepartstjeneste opfører sig ordentligt.

## Ansvar

**I det videst mulige omfang, loven tillader, er vi ikke ansvarlige** for tab eller skade,
der opstår som følge af din brug af live.tips. Det omfatter — uden begrænsning — mistede,
forsinkede, duplikerede eller ikke-leverede drikkepenge; drikkepenge vist som uverificerede,
som aldrig blev betalt; data, der ikke blev synkroniseret, eller som fulgte med en konto, du
ikke kunne gendanne; tabt indtægt; en enhed, der svigtede på scenen; handlinger, nedbrud
eller beslutninger fra Stripe, Revolut, MobilePay, Monzo, Google, Apple, Cloudflare eller
GitHub; og alt, du har mistet, fordi du stolede på et tal på en skærm.

live.tips er fri software, som én person giver væk. Der er ingen indtægt her til at
finansiere et ansvar, og intet accepteres.

To ærlige begrænsninger af det afsnit, for et vilkår, der rækker for langt, er intet værd:

- Vi udelukker **ikke** ansvar for **dødsfald eller personskade forårsaget af uagtsomhed,
  for svig eller for noget andet, der ikke lovligt kan udelukkes**.
- Er du **forbruger**, beholder du alle **ufravigelige rettigheder, din lokale lovgivning
  giver dig**. Intet heri tager dem fra dig.

## Softwaren er din

live.tips er MIT-licenseret. Du må **læse, forke, ændre, selv hoste og selv køre den** —
inklusive relæet. Kan du ikke lide, hvordan vi driver tjenesten, er det ærlige svar, som
open source giver dig: kør din egen. Kildekoden ligger på
[github.com/mekedron/live.tips](https://github.com/mekedron/live.tips).

Intet i disse vilkår begrænser de rettigheder, MIT-licensen giver dig over selve koden;
disse vilkår regulerer den **hostede tjeneste** — dette website, kontiene og det relæ, vi
driver.

## Ændringer

Vi kan opdatere disse vilkår, efterhånden som softwaren ændrer sig. Hver eneste tidligere
version ligger i den offentlige git-historik, så du kan se præcis, hvad der ændrede sig, og
hvornår. Fortsætter du med at bruge tjenesten efter en ændring, betyder det, at du
accepterer den.

## Kontakt

**[contact@live.tips](mailto:contact@live.tips)** — et rigtigt menneske læser den.

## Sprog

Disse vilkår udgives på alle de sprog, siden understøtter, som en service. Hvis en
oversættelse og den engelske version er uenige, er **det den engelske version, der
gælder**.
</content>
