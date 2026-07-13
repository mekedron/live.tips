---
title: Privatlivspolitik
description: live.tips har ingen cookies, ingen analyseværktøjer og ingen sporing, og virker helt uden konto. Vælger du at logge ind, står her præcis, hvad der gemmes, hvor, af hvem og hvor længe.
updated: 2026-07-13
updated_label: Sidst opdateret 13. juli 2026
---

live.tips er en open source-drikkepengekrukke til optrædende kunstnere. Den drives af
**Nikita Rabykin**, en enkelt udvikler, ikke et selskab. Hvis noget herunder betyder noget
for dig, så skriv til **[contact@live.tips](mailto:contact@live.tips)** — den adresse når
frem til et menneske.

Denne politik er ærlig om de kedelige dele. Vi siger hellere “vi gemmer dit navn i op til
en time” end at påstå, at vi ikke gemmer noget, og tage fejl.

## Den korte version

- **En konto er valgfri.** Appen virker helt uden konto, og det er stadig standarden. Vil
  du have dine bands og din historik på en enhed nummer to, kan du logge ind — og så bliver
  noget af det gemt på en server. Hvad der er hvad, står herunder.
- **Ingen cookies.** Ikke én, ingen steder.
- **Ingen analyseværktøjer, ingen sporing, ingen reklamer, ingen tredjepartsscripts** på
  dette website.
- **Vi rører aldrig dine penge.** Drikkepenge går direkte fra fanen til kunstnerens egen
  Stripe-, Revolut-, MobilePay- eller Monzo-konto. Vi er ikke i den vej.
- **I standardopsætningen taler appen kun med Stripe** — ikke med nogen live.tips-server.
- Den eneste server, vi overhovedet driver, er et lille relæ på Googles Firebase. Det
  findes, hvis en kunstner slår Revolut, MobilePay eller Monzo til — eller hvis de logger
  ind.

## Dette website

Siden er statisk og hostet på **GitHub Pages**. Som host modtager GitHub IP-adressen og
browserens user-agent for alle, der indlæser en side — det er ganske almindelig
webserverlogning, det sker, før noget af vores kode kører, og vi kan ikke slå det fra.
GitHub behandler det under sin egen
[privatlivserklæring](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Vi læser ikke de logfiler, og GitHub viser os dem ikke.

Ud over det indlæser de sider, du læser, **intet fra nogen anden**: skrifttyper, ikoner og
billeder leveres fra live.tips selv. Der er ingen Google Analytics, ingen tag manager,
ingen pixel, ingen indlejret widget.

Siden gemmer **to værdier i din browsers `localStorage`**, begge sat af dig, begge kun
læsbare af denne side, og ingen af dem sendes nogensinde nogen steder hen:

| Nøgle | Hvad den husker |
| --- | --- |
| `lt-landing-theme` | om du valgte lyse, mørke eller automatiske farver |
| `lt-langbar-dismissed` | at du lukkede banneret “findes også på dit sprog” |

Rydder du din browserlagring, slettes de. De er ikke cookies, de deles ikke, og de
identificerer ingen.

## Appen har to tilstande, og forskellen er hele historien

Alt herunder afhænger af ét spørgsmål: **har du logget ind?**

### Tilstand ét — ingen konto. Stadig standarden, stadig uændret.

Appen kører **på kunstnerens egen enhed**, og alt, hvad den ved, bor der:

- Den **begrænsede Stripe-nøgle** gemmes i enhedens nøglering (iOS/macOS Keychain,
  Android Keystore) og sendes kun nogensinde til `api.stripe.com`.
- **Drikkepengehistorik, sessionshistorik, målet og appens indstillinger** gemmes i lokal
  lagring på enheden. Det inkluderer de navne og hilsner, som fans knytter til deres
  drikkepenge.
- Afinstallerer du appen, slettes det hele. Der er ingen cloud-backup hos os, fordi der i
  denne tilstand ikke er nogen cloud hos os.

**Vi modtager aldrig noget af dette.** Appen leveres uden analyse-SDK, uden
crash-rapportering, uden push-notifikationer og uden reklamekode — ingen, heller ikke
deaktiverede.

To præciseringer, så påstanden om, at appen “taler med ingen”, forbliver præcis sand:

- Appen henter **valutakurser** én gang om dagen fra offentlige kurs-API'er
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Det er helt almindelige
  forespørgsler efter en offentlig liste over kurser. De bærer ingen oplysninger om dig,
  kunstneren eller nogen drikkepenge — men ligesom enhver webforespørgsel afslører de din
  IP-adresse over for de tjenester.
- Bruger du **browserversionen** af appen, henter din browser den fra vores statiske host
  (se *Dette website* ovenfor).

### Tilstand to — du har logget ind. Så forlader nogle data enheden, med vilje.

At logge ind er en bevidst handling. Ingenting logger dig ind for dig, og intet i appen
holder op med at virke, hvis du aldrig gør det. Du logger ind, fordi du vil have en enhed
nummer to: telefonen i lommen og tabletten på scenen, der viser den samme aften, de samme
bands, den samme historik.

Det virker kun, hvis en server holder dem. **Det gør den så, og det er den ærlige pris for
enheden nummer to.**

Serveren er **Firebase**, som er Google. Der er tre måder at have en konto på:

- **Log ind med Apple** eller **log ind med Google** — Firebase Auth modtager, hvad end
  udbyderen udleverer: et bruger-id (uid) og som regel en e-mailadresse og et navn. (Hos
  Apple kan du skjule din e-mail; Apple giver os så en videresendelsesadresse i stedet.)
- **En gæstekonto** — en anonym konto uden e-mail og uden navn. Den synkroniserer, og den
  kan tilbagekaldes, men der er intet at gendanne den med, hvis du mister enheden. Den er
  et uid og ikke andet.

Når du først er logget ind, får kontoen sit eget private hjørne af Googles
**Cloud Firestore**-database, på `users/<your uid>/`. Sikkerhedsreglerne giver det hjørne
til det uid **og til ingen anden** — ingen anden konto kan læse det, heller ikke ved at
gætte URL'er. Indeni:

| Hvad | Hvorfor det er der |
| --- | --- |
| Dine **bands** — navne, indstillinger for drikkepengekrukke og betalingsmetoder, plakattekst, mål | så et band findes på hver enhed, du logger ind på |
| Din **begrænsede Stripe-nøgle** og hemmeligheden til drikkepengesiden i relæet | i et hemmelighedsdokument, som kun dit uid kan læse, og cachet i nøgleringen på hver af dine enheder |
| **Appens indstillinger** | så en enhed, du tilføjer, allerede er sat op |
| **Sessionsregistreringer og drikkepengehistorik** — herunder **de navne og hilsner, fans knytter til deres drikkepenge** | fordi netop den historik er det, du bad om at kunne se på den anden enhed |
| Den **live-session**, der kører lige nu | så en skærm nummer to kan slutte sig til aftenens sæt |
| Dine **enheder** — det navn, hver enkelt giver sig selv (“Nikitas iPhone”), dens platform og model, hvornår den blev set første og sidste gang | så Indstillinger → Sikkerhed kan liste dem, og du kan tilbagekalde en |
| Et lille **profildokument** — det kontonavn, du valgte, og hvilken udbyder du brugte | så kontovælgeren kan sætte navn på den |

Og så det vigtige, ligeud: **uden en konto forlader en fans navn og hilsen aldrig
kunstnerens enhed. Med en konto gemmes de på Googles servere under kunstnerens uid, som en
del af den kunstners egen synkroniserede historik.** Ingen anden konto kan læse dem, vi
kigger ikke på dem, og der udledes intet af dem — men de er der, og det bør du vide, før du
logger ind.

Logger du ud, går enheden tilbage til den lokale tilstand. Det sletter ikke kontoens data —
se *At slette ting* nedenfor.

### At tilføje en enhed med en QR-kode

For at tilføje en enhed viser du en QR-kode fra en enhed, der allerede er logget ind. Koden
er tilfældig, **kan kun bruges én gang og udløber om to minutter**, og den nye enhed får
intet, før du trykker *bekræft* på den gamle. Så længe det håndtryk står åbent, gemmer vi
koden, det navn den nye enhed gav sig selv, og dens platform — og posten slettes, når den
udløber. En fotograferet QR-kode er værdiløs uden dit bekræftende tryk.

## Hvor alt dette fysisk bor

Firebase Auth, Cloud Firestore og vores Cloud Functions kører i **Den Europæiske Union** —
databasen i Googles `eur3`-multiregion, funktionerne i `europe-west1`. Google fungerer som
vores databehandler under
[Firebases privatlivs- og sikkerhedsvilkår](https://firebase.google.com/support/privacy) og
sin egen [privatlivspolitik](https://policies.google.com/privacy). Som enhver stor udbyder
kan Google inddrage infrastruktur uden for EU til support og sikkerhed; det er reguleret af
de vilkår, ikke af os.

## Stripe

Når en fan betaler med kort, er vedkommende på **Stripes** betalingsside, ikke vores.
Stripe indsamler og behandler deres betalingsdata som selvstændig dataansvarlig under
[Stripes privatlivspolitik](https://stripe.com/privacy). Vi ser aldrig kortnumre, og vi har
ingen adgang til kunstnerens Stripe-konto.

Kunstnerens app læser kunstnerens egne drikkepenge fra Stripe med kunstnerens egen
begrænsede nøgle — direkte fra enheden til `api.stripe.com`. **Der er ingen
live.tips-server i den vej, og det har der aldrig været.** En fans navn og hilsen, hvis der
er efterladt nogen, rejser fra Stripe til kunstnerens enhed og stopper der — medmindre
kunstneren har logget ind, og så gemmer enheden dem også i den kunstners egen
Firestore-historik, som beskrevet ovenfor.

## Relæet — kun hvis Revolut, MobilePay eller Monzo er slået til

Opsætninger med kun Stripe rører aldrig dette.

Revolut, MobilePay og Monzo tilbyder ingen måde, hvorpå en app kan bekræfte, at en
betaling er sket, så de drikkepenge sendes gennem et lille open source-relæ, som vi driver
på **Firebase** — Cloud Functions og Firestore i `europe-west1`, med fanens drikkepengeside
serveret fra **`tip.live.tips/t/<id>`**. Det rører aldrig penge. Her er alt, hvad det
håndterer.

### Hvad kunstneren gemmer

At oprette en drikkepengeside gemmer kunstnerens **visningsnavn, deres offentlige hilsen,
deres valuta og de betalingsoplysninger, de har valgt at offentliggøre** (deres
Stripe-betalingslink, Revolut-brugernavn, MobilePay Box-ID, Monzo-brugernavn). Det hele er
oplysninger, som kunstneren alligevel bevidst offentliggør over for sine fans.

- **Opbevaring: en drikkepengeside uden en konto bag sig slettes automatisk efter 90 dages
  inaktivitet.** En drikkepengeside, der hører til en konto, man er logget ind på, lever
  lige så længe som det band, den hører til.
- Kunstneren kan slette den **med det samme** fra appen, når som helst.
- Der indsamles aldrig e-mailadresse, adgangskode, juridisk navn eller bankoplysninger her.
- Sidens hemmelighed gemmes **kun som et hash**. Vi kunne ikke fortælle dig hemmeligheden,
  hvis du spurgte; vi kan kun tjekke en.

### Hvad en fan sender

Drikkepengeformularen beder om et **beløb** og valgfrit et **navn** og en **hilsen**. Det er
hele formularen. Ingen e-mail, intet telefonnummer, ingen konto.

- Drikkepengene skrives til en **leveringskø** — et enkelt dokument, der findes for at blive
  overleveret til kunstnerens skærm. Når skærmen viser drikkepengene, **sletter kunstnerens
  enhed det dokument.** Sletningen *er* kvitteringen; der er intet “leveret”-flag, fordi der
  ikke er nogen post tilbage at sætte flag på.
- Er kunstnerens skærm offline — telefonen låst, intet signal — **venter drikkepengene i den
  kø i op til en time**, så de ikke bare går tabt, og går over i det øjeblik, skærmen
  forbinder igen. Forbinder ingen igen, **slettes de uset**, fejet væk efter en fast plan,
  uanset om nogen nogensinde kom tilbage efter dem.
- **Den kø er det eneste sted, fan-skrevet tekst nogensinde gemmes på vores server, og en
  time er dens absolutte grænse.** Er kunstneren logget ind, beholder deres enhed derefter
  drikkepengene i *deres* Firestore-historik — for det er deres historik, og det er det, de
  loggede ind for.
- Dit navn og din hilsen placeres også i den **betalingsnote**, der åbner i Revolut,
  MobilePay eller Monzo — det er sådan, kunstneren ved, hvem der gav drikkepenge. De
  selskaber behandler det derefter under deres egne privatlivspolitikker.
- Relæet gemmer **ingen drikkepengehistorik**. Det kan ikke vise dig, os eller nogen anden
  en liste over, hvem der har givet drikkepenge til hvem.

### IP-adresser og misbrugsbeskyttelse

En åben formular, som hvem som helst kan sende til, kræver en vis beskyttelse mod bots, så:

- Din IP-adresse sendes til **Cloudflare Turnstile** — et anti-bot-tjek, der kører på
  drikkepengesiden — for at verificere, at du ikke er en bot. Turnstile er Cloudflares
  produkt og bruges i stedet for en CAPTCHA, der profilerer dig. Turnstile og vores DNS er
  det eneste, Cloudflare stadig gør for os; selve relæet kører nu på Firebase. Se
  [Cloudflares privatlivspolitik](https://www.cloudflare.com/privacypolicy/).
- Din IP bruges også til at **rate-limite** forespørgsler — at sende drikkepenge, at oprette
  en drikkepengeside, at indløse en kode til at tilføje en enhed. Det, vi gemmer til det, er
  et **saltet kryptografisk hash af IP-adressen**, aldrig selve IP-adressen, i cirka **to
  timer**, og så slettes det. Saltet er en serverhemmelighed: uden det nægter koden at gemme
  noget som helst i stedet for at beholde et hash, der kunne vendes om.
- **Googles driftslogfiler** registrerer de tekniske detaljer om forespørgsler til relæet —
  URL, tidspunkt, status — i nogle få dage. Vores kode logger med vilje ingen navne, ingen
  hilsner, ingen hemmeligheder og ingen headere. Google fungerer som vores databehandler.

### Tællere

Relæet tæller, **hvor mange drikkepenge** en given drikkepengeside har videresendt, så vi
kan opdage misbrug og vide, om tingen overhovedet bliver brugt. Det er et tal. Det
indeholder ingen fan-data.

## Hvem behandler hvad

| Hvem | Hvad de får | Hvorfor |
| --- | --- | --- |
| **Google (Firebase)** | Konti, en indlogget kunstners synkroniserede data, relæet, serverlogfiler | Den valgfrie konto og det valgfrie relæ |
| **Stripe** | Fanens betalingsdata, som selvstændig dataansvarlig | Drikkepenge med kort |
| **Cloudflare** | Fanens IP-adresse, til Turnstile-tjekket på drikkepengesiden. Og vores DNS. | At holde bots væk fra drikkepengeformularen |
| **GitHub** | IP-adressen og user-agenten på alle, der indlæser dette website | Hosting af websitet |
| **Revolut / MobilePay / Monzo** | Hvad end fanen gør i deres egen app, betalingsnoten inklusive | Disse betalingsmetoder |

Vi sælger intet til nogen, og der er ingen andre på den liste.

## Retsgrundlag, hvis du har brug for et (GDPR)

- At drive en konto, du har bedt om, at synkronisere dine egne data til dine egne enheder,
  at drive relæet for en kunstner, der har slået det til, og at levere en fans drikkepenge
  til den skærm, de var rettet mod: **opfyldelse af en tjeneste, du har bedt om**.
- Rate limiting, Turnstile, kvoter baseret på hashede IP-adresser og tilbagekaldelse af
  enheder: **legitim interesse** i at forhindre, at en gratis, åben tjeneste ødelægges af
  bots og svindel, og i at holde kunstneres konti sikre.
- Serverlogfiler: **legitim interesse** i at drive og sikre tjenesten.

## At slette ting

Dette betyder mere end noget løfte, vi kunne give om det, så her er præcis, hvad der findes
i dag — inklusive hvad der ikke gør.

- **Ingen konto**: afinstaller appen. Så er det hele væk.
- **Et band**: fjerner du et band i appen, slettes det bands cloud-data — dets
  indstillinger, dets nøgler, dets sessioner, dets drikkepengehistorik — sammen med kopien
  på enheden.
- **En drikkepengeside**: slet eller gendan den i appen, og den bliver øjeblikkeligt visket
  ud af relæet, eventuelle ventende drikkepenge inklusive.
- **En enhed**: Indstillinger → Sikkerhed lister dine enheder. Du kan tilbagekalde en eller
  logge ud alle andre steder — hvilket afslutter alle andre enheders session med det samme,
  ikke på et tidspunkt.
- **Hele din konto, med ét tryk: den knap har appen ikke endnu.** Vi indrømmer det hellere
  end at lade som om noget andet. Indtil den findes, så skriv til
  **[contact@live.tips](mailto:contact@live.tips)**, så sletter vi kontoen og alt under den,
  i hånden. I mellemtiden kan du allerede slette hvert eneste band, hvilket fjerner alt af
  substans og efterlader en tom konto.

## Dine rettigheder

Du kan bede os om at give dig en kopi af, rette eller slette alt, hvad vi har om dig, og du
kan klage til din nationale databeskyttelsesmyndighed. Skriv til
**[contact@live.tips](mailto:contact@live.tips)**.

I praksis er det meste allerede i dine egne hænder: en kunstner kan slette en
drikkepengeside eller et band fra appen med det samme, ikke-leverede drikkepenge fra fans
fordamper inden for en time, og logger du aldrig ind, har intet af det nogensinde været
andre steder end på din egen enhed.

## Børn

live.tips er ikke rettet mod børn, og vi behandler ikke bevidst deres data.

## Ændringer

Vi opdaterer denne side, når softwaren ændrer sig. Fordi hele projektet er open source,
ligger **hver eneste tidligere version af denne politik i den offentlige git-historik** — du
kan se præcis, hvad der ændrede sig, og hvornår.

## Sprog

Denne politik udgives på alle de sprog, siden understøtter, som en service. Hvis en
oversættelse og den engelske version er uenige, er **det den engelske version, der
gælder**.
