---
title: Personvernerklæring
description: live.tips har ingen informasjonskapsler, ingen analyse og ingen sporing, og virker helt uten konto. Velger du å logge inn, står det her nøyaktig hva som lagres, hvor, av hvem, og hvor lenge.
updated: 2026-07-15
updated_label: Sist oppdatert 15. juli 2026
---

live.tips er en tipskrukke med åpen kildekode for artister. Den drives av **Nikita Rabykin**,
en enkeltutvikler, ikke et selskap. Hvis noe av det som står nedenfor betyr noe for deg, skriv
til **[contact@live.tips](mailto:contact@live.tips)** — den adressen når fram til et menneske.

Denne erklæringen er ærlig om de kjedelige delene. Vi sier heller «vi beholder navnet ditt så
lenge du beholder bandet» enn å påstå at vi ikke beholder noe og ta feil.

## Kortversjonen

- **En konto er valgfri.** Appen virker helt uten konto, og det er fortsatt standarden. Vil du ha
  bandene og historikken din på en enhet nummer to, kan du logge inn — og da lagres noe av det på
  en tjener, og mer av det enn før. Hva som er hva, står nedenfor.
- **Ingen informasjonskapsler.** Ikke én, ingen steder.
- **Ingen analyse, ingen sporing, ingen annonser, ingen tredjepartsskript** på dette nettstedet.
- **Vi rører aldri pengene dine.** Tips går rett fra fansen til artistens egen
  Stripe-, Revolut-, MobilePay- eller Monzo-konto. Det finnes aldri noen live.tips-saldo.
- **Uten konto snakker appen bare med Stripe** — ikke med noen live.tips-server. Logger du inn,
  endrer det seg: Stripe-nøkkelen din flytter til serveren vår, og Stripe rapporterer tipsene dine
  til oss, slik at vi kan legge dem på de andre enhetene dine. Det er den ærlige prisen for å logge
  inn, og den står i sin helhet nedenfor.
- **Push-varsler er nye, valgfrie og bare for innloggede kontoer.** Ingenting pushes til en enhet
  som aldri slo dem på, og en enhet uten konto får aldri ett i det hele tatt.
- Serverne vi driver, ligger på Googles Firebase. De finnes hvis en artist slår på Revolut,
  MobilePay eller Monzo — eller hvis vedkommende logger inn.

## Dette nettstedet

Nettstedet er statisk og driftes på **GitHub Pages**. Som vert mottar GitHub IP-adressen og
nettleserens user-agent til alle som laster en side — dette er helt vanlig loggføring på
vevtjeneren, det skjer før noe av koden vår kjører, og vi kan ikke slå det av.
GitHub behandler det under sin egen
[personvernerklæring](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Vi leser ikke de loggene, og GitHub viser dem ikke til oss.

Utover det laster sidene du leser **ingenting fra noen andre**: skrifter, ikoner og bilder
serveres fra live.tips selv. Det finnes ingen Google Analytics, ingen tag manager, ingen
piksel, ingen innebygd widget.

Nettstedet lagrer **to verdier i nettleserens `localStorage`**, begge satt av deg, begge lesbare
bare av dette nettstedet, og ingen av dem sendes noe sted:

| Nøkkel | Hva den husker |
| --- | --- |
| `lt-landing-theme` | om du valgte lyse, mørke eller automatiske farger |
| `lt-langbar-dismissed` | at du lukket banneret «også tilgjengelig på ditt språk» |

Tømmer du nettleserlagringen, slettes de. De er ikke informasjonskapsler, de deles ikke, og de
identifiserer ingen.

## Appen har to modus, og forskjellen er hele historien

Alt nedenfor avhenger av ett spørsmål: **har du logget inn?**

### Modus én — ingen konto. Fortsatt standarden, fortsatt uendret.

Appen kjører **på artistens egen enhet**, og alt den vet, ligger der:

- Den **begrensede Stripe-nøkkelen** lagres i enhetens nøkkelring (iOS-/macOS-nøkkelring,
  Android Keystore) og sendes bare til `api.stripe.com`.
- **Tipshistorikk, økthistorikk, målet, listen over sangønsker og appinnstillinger** lagres i
  lokal enhetslagring. Dette omfatter navnene og hilsenene fansen legger ved tipsene sine.
- Avinstallerer du appen, slettes alt sammen. Det finnes ingen skysikkerhetskopi hos oss, fordi
  det i denne modusen ikke finnes noen sky hos oss.

**Vi mottar aldri noe av dette.** Appen leveres uten analyse-SDK, uten krasjrapportering og uten
annonsekode — ingen, ikke engang deaktiverte. (Push-varsler finnes, men de er en funksjon for
innloggede og er av til du slår dem på — se *Modus to*. En enhet uten konto får aldri ett.)

To presiseringer, slik at påstanden «snakker med ingen» forblir helt sann:

- Appen henter **valutakurser** én gang om dagen fra offentlige kurs-API-er
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Dette er helt vanlige
  forespørsler om en offentlig liste med kurser. De inneholder ingen informasjon om deg, om
  artisten eller om noe tips — men, som enhver vevforespørsel, avslører de IP-adressen din for
  disse tjenestene.
- Bruker du **nettleserversjonen** av appen, laster nettleseren den ned fra vår statiske vert
  (se *Dette nettstedet* ovenfor).

### Modus to — du har logget inn. Da forlater noen data enheten, med vilje.

Å logge inn er en bevisst handling. Ingenting logger deg inn for deg, og ingenting i appen slutter
å virke om du aldri gjør det. Du logger inn fordi du vil ha en enhet nummer to: telefonen i lomma
og nettbrettet på scenen som viser den samme kvelden, de samme bandene, den samme historikken.

Det virker bare hvis en tjener holder på dem. **Så det gjør den, og det er den ærlige prisen for
enhet nummer to.**

Tjeneren er **Firebase**, altså Google. Det finnes tre måter å ha en konto på:

- **Logg inn med Apple** eller **Logg inn med Google** — Firebase Auth mottar det leverandøren gir
  fra seg: en bruker-id (uid) og, som regel, en e-postadresse og et navn. (Med Apple kan du skjule
  e-postadressen din; Apple gir oss da en relé-adresse i stedet, og gir fra seg navnet ditt bare
  aller første gang du logger inn.)
- **En gjestekonto** — en anonym konto uten e-post og uten navn. Den synkroniserer og den kan
  tilbakekalles, men det finnes ingenting å gjenopprette den med om du mister enheten. Den er en
  uid og ikke noe mer. En gjestekonto kan ikke bruke den tjenersidige Stripe-forvaltningen eller
  push-varslene som beskrives nedenfor, fordi begge trenger en konto vi kan gi tilbake til deg.

Når du først har logget inn, får kontoen sin egen private krok av Googles **Cloud
Firestore**-database, på `users/<your uid>/`. Sikkerhetsreglene gir den kroken til den uid-en **og
til ingen andre** — ingen annen konto kan lese den, heller ikke ved å gjette URL-er. Inni den:

| Hva | Hvorfor det ligger der |
| --- | --- |
| **Bandene** dine — navn, innstillinger for tipskrukke og betalingsmåter, plakattekst, mål og **listen din over sangønsker** | slik at et band finnes på hver enhet du logger inn på |
| **Appinnstillinger**, inkludert varselpreferansene dine | slik at en enhet du legger til, allerede er satt opp |
| **Øktregistreringer og tipshistorikk** — inkludert **navnene og hilsenene fansen legger ved tipsene sine**, og **enhver sang en fan har ønsket seg** | fordi den historikken er nøyaktig det du ba om å få se på den andre enheten |
| Den **liveøkten** som kjører akkurat nå | slik at en skjerm nummer to kan bli med på kveldens sett |
| **Enhetene** dine — navnet hver av dem gir seg selv («Nikitas iPhone»), plattformen og modellen, grensesnittspråket, når den ble sett første og siste gang, og (hvis du slo på varsler) en **push-token** | slik at Innstillinger → Sikkerhet kan liste dem opp, slik at et varsel når riktig enhet på riktig språk, og slik at du kan tilbakekalle én |
| Et lite **profildokument** — kontonavnet du valgte, og hvilken leverandør du brukte | slik at kontovelgeren kan sette navn på den |
| En **klokkefeed** — en avgrenset liste over nylige tips og sangønsker som kom mens ingen sett kjørte | slik at du kan ta igjen det du gikk glipp av |

Og så det viktige, rett fram: **uten konto forlater en fans navn og hilsen aldri artistens enhet.
Med konto lagres de på Googles tjenere under artistens uid, som en del av artistens egen
synkroniserte historikk**, og — som de neste to seksjonene forklarer — **er det nå serveren vår
som skriver dem dit.** Ingen annen konto kan lese dem, vi ser ikke på dem, og ingenting utledes av
dem — men de er der, og de blir liggende der så lenge bandet gjør det, og det bør du vite før du
logger inn.

Logger du ut, går enheten tilbake til lokal modus. Det sletter ikke kontoens data — se *Å slette
ting*, nedenfor.

#### Stripe-nøkkelen din flytter til serveren vår når du logger inn

Dette er den største endringen, og den det er mest verdt å lese.

**Uten konto forlater den begrensede Stripe-nøkkelen din aldri enheten.** Det er Modus én, og den
er uendret.

**Når du logger inn, forlater den enheten — til oss.** Nøkkelen krypteres (en AES-256-nøkkel per
hemmelighet, som selv er pakket inn av Google Cloud KMS) og lagres på tjenersiden på et sted
**ingen kan lese den tilbake fra — ikke en annen konto, og ikke engang du.** Den låses opp bare
inne i våre Cloud Functions, brukes til å snakke med Stripe på dine vegne, og overleveres aldri
til en enhet igjen.

Fordi nøkkelen nå bor hos oss, **rapporterer Stripe tipsene dine direkte til serveren vår**: vi
registrerer en webhook på din egen Stripe-konto, og Stripe forteller den webhooken hver gang et
tips betales. Funksjonen vår skriver tipset inn i kontoens historikk (se nedenfor). Appen din spør
ikke lenger Stripe gjentatte ganger for en innlogget konto; den når Stripe bare gjennom en smal,
fast liste av operasjoner på serveren vår (å opprette tipslenken din, å lage en lenke for
sangønsker, og å lese dine egne tips tilbake for avstemming).

Så, sagt uten omskrivning: **for en innlogget konto finnes det nå en live.tips-server i veien
mellom Stripe og historikken din.** Vi rører fortsatt aldri pengene — et korttips opprettes mot
Stripe-kontoen din, havner i Stripe-saldoen din og utbetales etter Stripe-planen din, akkurat som
før. Det som endret seg, er *data*veien, ikke pengeveien. Logger du aldri inn, gjelder ingenting
av dette, og appen snakker fremdeles rett med `api.stripe.com` og med ingen andre.

#### Å legge til en enhet med QR-kode

For å legge til en enhet viser du en QR-kode fra en enhet som allerede er innlogget. Koden er
tilfeldig, **kan bare brukes én gang, og utløper etter to minutter**, og den nye enheten får
ingenting før du trykker *bekreft* på den gamle. Så lenge det håndtrykket står åpent, holder vi på
koden, navnet den nye enheten ga seg selv, og plattformen dens — og oppføringen slettes når den
utløper. En avfotografert QR-kode er verdiløs uten det bekreftende trykket ditt.

## Sangønsker

Et band kan slå på **sangønsker**: fansen velger da en sang fra artistens liste og betaler, om de
vil, for å skyve den oppover i køen. Et ønske er bare et tips som i tillegg bærer **hvilken sang**
det ble spurt om — så det samme navnet og den samme hilsenen en fan kan legge ved et tips, gjelder
også her, og det lagres og beholdes akkurat som ethvert annet tips (nedenfor). Den offentlige køen
en fan ser, viser bare **totaler per sang** — hvor mye en sang har trukket inn og hvor den ligger
— og bærer **ingen fansnavn**. Uten konto lever hele listen over sangønsker og historikken dens
bare på enheten.

## Push-varsler

Når du er innlogget, kan appen sende deg et **push-varsel** — men bare hvis du slår det på, per
enhet, og bare etter at operativsystemet på enheten din gir tillatelse. Det finnes til én ting: et
tips eller et sangønske som lander **mens du ikke kjører et sett**, slik at du hører om tipset du
ellers ville gått glipp av. Et tips som kommer mens scenen din er live, sender ingenting — du
følger allerede med på det.

- For å levere et push-varsel trenger Googles **Firebase Cloud Messaging (FCM)** en **push-token**
  for enheten. Vi lagrer den tokenen, og enhetens grensesnittspråk, på enhetens egen oppføring
  under kontoen din, og den slettes i det øyeblikket du slår av varsler, tilbakekaller enheten
  eller logger ut. Døde token-er ryddes vekk automatisk.
- Selve varselet sier hva som kom inn — et beløp, og en fans navn eller en sangtittel om de la
  igjen noe. Den samme korte listen holdes i kontoens **klokkefeed**, avgrenset til de siste hundre
  oppføringene, slik at du kan bla tilbake gjennom det som kom inn mens du var borte.
- På nett krever levering av et push-varsel en liten **service worker** i nettstedsroten og
  Firebase-meldings-SDK-en, som nettleseren din henter fra Google (`gstatic.com`) første gang.
  Web-push bæres deretter av nettleserens egen push-tjeneste (for Chrome er det Googles). Ingenting
  av dette lastes med mindre du slo på varsler.
- **En gjestekonto og en enhet uten konto får ingen push-varsler**, fordi et push-varsel trenger
  en konto vi kan levere til og en token du valgte å gi.

## Hvor alt dette fysisk ligger

Firebase Auth, Cloud Firestore, våre Cloud Functions og Cloud KMS-nøkkelen som pakker inn
Stripe-hemmeligheten din, kjører alle i **Den europeiske union** — databasen i Googles
`eur3`-multiregion, funksjonene og nøkkelringen i `europe-west1`. Google opptrer som vår
databehandler under
[Firebases personvern- og sikkerhetsvilkår](https://firebase.google.com/support/privacy) og sin
egen [personvernerklæring](https://policies.google.com/privacy). Som enhver stor leverandør kan
Google trekke inn infrastruktur utenfor EU til støtte og sikkerhet; det styres av de vilkårene,
ikke av oss. Push-varsler reiser, når de først er overlevert til Firebase Cloud Messaging og
nettleserens eller telefonens push-tjeneste, over disse selskapenes infrastruktur for å nå enheten
din.

## Stripe

Når en fan betaler med kort, er vedkommende på **Stripes** betalingsside, ikke vår. Stripe samler
inn og behandler betalingsopplysningene som selvstendig behandlingsansvarlig under
[Stripes personvernerklæring](https://stripe.com/privacy). Vi ser aldri kortnumre.

Hvordan tipsene når fram til deg avhenger av modusen:

- **Uten konto** leser artistens app sine egne tips fra Stripe med artistens egen begrensede nøkkel
  — rett fra enheten til `api.stripe.com`. **Det finnes ingen live.tips-server i den veien.**
- **Når du er innlogget** bor nøkkelen på serveren vår (kryptert, som ovenfor), og Stripe
  rapporterer hvert tips til webhooken vår, som skriver det inn i den artistens egen
  Firestore-historikk. **I denne modusen finnes det en live.tips-server i veien** — for
  tipsdataene, aldri for pengene. Navnet og hilsenen til en fan, hvis de la igjen noe, reiser med
  tipset inn i den artistens egen historikk og stopper der.

## Reléet — bare hvis Revolut, MobilePay eller Monzo er slått på

Oppsett med bare Stripe berører aldri dette.

Revolut, MobilePay og Monzo gir ingen mulighet for en app til å bekrefte at en betaling faktisk
skjedde, så de tipsene rutes gjennom et lite relé med åpen kildekode som vi driver på
**Firebase** — Cloud Functions og Firestore i `europe-west1`, med fansens tipsside servert fra
**`tip.live.tips/t/<id>`**. Det rører aldri penger. Her er alt det håndterer.

### Hva artisten lagrer

Å opprette en tipsside lagrer artistens **visningsnavn, den offentlige hilsenen, valutaen og de
betalingsidentitetene vedkommende valgte å publisere** (Stripe-betalingslenken, Revolut-brukernavnet,
MobilePay Box ID, Monzo-brukernavnet), og, hvis sangønsker er på, **den offentlige sanglisten og
prisene per sang**. Alt sammen er informasjon artisten uansett bevisst publiserer til fansen.

- **Lagringstid: en tipsside uten konto bak seg slettes automatisk etter 90 dager uten aktivitet.**
  En tipsside som hører til en innlogget konto, lever så lenge bandet den hører til.
- Artisten kan slette den **umiddelbart** fra appen, når som helst.
- Ingen e-postadresse, intet passord, intet juridisk navn og ingen bankopplysninger samles inn her.
- Sidens hemmelighet lagres **bare som en hash**. Vi kunne ikke fortalt deg hemmeligheten om du ba
  om den; vi kan bare sjekke én.

### Hva en fan sender

Tipsskjemaet spør om et **beløp**, og valgfritt et **navn** og en **hilsen** — og, for et sangønske,
hvilken sang. Det er hele skjemaet. Ingen e-post, intet telefonnummer, ingen konto.

Hvor den fanskrevne teksten går, og hvor lenge, avhenger av om artisten er innlogget:

- **Hvis tipssiden ikke har noen konto bak seg**, skrives tipset til en **leveringskø** — ett
  enkelt dokument som finnes for å bli overlevert til artistens skjerm. Når skjermen viser tipset,
  **sletter artistens enhet det dokumentet.** Slettingen *er* kvitteringen. Hvis artistens skjerm
  er frakoblet — telefonen låst, ingen dekning — **venter tipset i den køen i inntil én time**,
  slik at det ikke bare går tapt, og går over i det øyeblikket skjermen kobler seg til igjen. Hvis
  ingen kobler seg til, **slettes det usett**, ryddet vekk etter en fast plan. For en artist uten
  konto er **den køen det eneste stedet fanskrevet tekst noen gang lagres på tjeneren vår, og én
  time er den absolutte grensen.**
- **Hvis tipssiden hører til en innlogget konto**, finnes det ingen kø. Serveren vår skriver tipset
  **rett inn i den artistens egen historikk** under uid-en deres — inn i kveldens økt hvis et sett
  kjører, eller inn i bandets eget arkiv hvis ikke. Der blir det liggende **så lenge bandet gjør
  det**; det er artistens egen historikk, og det er det de logget inn for. Dette er den samme
  historikken Stripe-webhooken skriver til, ovenfor.
- Navnet og hilsenen din legges også inn i **betalingsmeldingen** som åpnes i Revolut, MobilePay
  eller Monzo — det er slik artisten vet hvem som ga tips. Disse selskapene behandler den så
  under sine egne personvernerklæringer.
- Reléet beholder **ingen tipshovedbok på tvers av artister**. Det kan ikke vise deg, oss eller
  noen andre en liste over hvem som ga tips til hvem på tvers av artister.

### IP-adresser og misbruksvern

Et åpent skjema som hvem som helst kan sende til, trenger et visst vern mot bot-er, derfor:

- IP-adressen din sendes til **Cloudflare Turnstile** — en bot-sjekk som kjører på tipssiden — for
  å bekrefte at du ikke er en bot. Turnstile er Cloudflares produkt og brukes i stedet for en
  CAPTCHA som profilerer deg. Turnstile og DNS-en vår er det eneste Cloudflare fortsatt gjør for
  oss; selve reléet kjører nå på Firebase. Se
  [Cloudflares personvernerklæring](https://www.cloudflare.com/privacypolicy/).
- IP-adressen din brukes også til å **frekvensbegrense** forespørsler — å sende et tips, å opprette
  en tipsside, å løse inn en kode for å legge til en enhet. Det vi lagrer for det, er en **saltet
  kryptografisk hash av IP-adressen**, aldri IP-adressen selv, i omtrent **to timer**, og så
  slettes den. Saltet er en tjenerhemmelighet: uten det nekter koden å lagre noe som helst,
  framfor å beholde en hash som kunne vært reversert.
- **Googles driftslogger** registrerer de tekniske detaljene om forespørsler til reléet — URL,
  tidspunkt, status — i noen få dager. Koden vår logger bevisst ingen navn, ingen hilsener, ingen
  hemmeligheter og ingen headere. Google opptrer som vår databehandler.

### Tellere

Reléet teller **hvor mange tips** en gitt tipsside har formidlet, slik at vi kan oppdage misbruk
og vite om greia i det hele tatt brukes. Det er et tall. Det inneholder ingen fansdata.

## Hvem behandler hva

| Hvem | Hva de får | Hvorfor |
| --- | --- | --- |
| **Google (Firebase)** | Kontoene, en innlogget artists synkroniserte data, den krypterte Stripe-nøkkelen, reléet, push-token-er og levering, tjenerlogger | Den valgfrie kontoen, det valgfrie reléet og push-varsler |
| **Google Cloud KMS** | Nøkkelen som pakker inn en innlogget artists Stripe-hemmelighet (aldri hemmeligheten i klartekst) | Å holde den lagrede Stripe-nøkkelen uleselig i ro |
| **Stripe** | Fansens betalingsopplysninger, som selvstendig behandlingsansvarlig; og, for en innlogget artist, tips-hendelser sendt til webhooken vår | Korttips |
| **Cloudflare** | Fansens IP-adresse, til Turnstile-sjekken på tipssiden. Og DNS-en vår. | Å holde bot-er unna tipsskjemaet |
| **GitHub** | IP-adressen og user-agenten til alle som laster dette nettstedet | Drift av nettstedet |
| **Nettleseren din / telefonens push-tjeneste** (f.eks. Googles for Chrome) | En push-token og varselinnholdet, hvis du slo på varsler | Å levere push-varsler |
| **Revolut / MobilePay / Monzo** | Det fansen gjør i deres egen app, betalingsmeldingen inkludert | Disse betalingsmåtene |

Vi selger ingenting til noen, og det står ingen andre på den lista.

## Behandlingsgrunnlag, hvis du trenger et (GDPR)

- Å drive en konto du har bedt om, å synkronisere dine egne data til dine egne enheter, å holde på
  Stripe-nøkkelen din slik at tipsene dine når historikken din, å drive reléet for en artist som
  har slått det på, å levere en fans tips til skjermen det var ment for, og å sende et push-varsel
  du slo på: **oppfyllelse av en tjeneste du har bedt om**.
- Frekvensbegrensning, Turnstile, kvoter basert på hashet IP og tilbakekalling av enheter:
  **berettiget interesse** i å hindre at en gratis, åpen tjeneste ødelegges av bot-er og svindel,
  og i å holde artistenes kontoer sikre.
- Tjenerlogger: **berettiget interesse** i å drifte og sikre tjenesten.

## Å slette ting

Dette betyr mer enn noe løfte vi kunne gitt om det, så her er nøyaktig hva som finnes i dag —
inkludert det som ikke finnes.

- **Ingen konto**: avinstaller appen. Da er alt sammen borte.
- **Et band**: å fjerne et band i appen sletter bandets skydata — innstillingene, nøklene, øktene
  og tipshistorikken — sammen med kopien på enheten.
- **En tipsside**: slett eller lag den på nytt i appen, og den viskes ut fra reléet med det samme,
  ventende tips inkludert.
- **Push-varsler**: slå dem av på en enhet, og enhetens push-token slettes. Klokkefeeden tømmes
  sammen med bandet eller kontoen.
- **En enhet**: Innstillinger → Sikkerhet lister opp enhetene dine. Du kan tilbakekalle én, eller
  logge ut alle andre steder — noe som avslutter økten på hver eneste av de andre enhetene
  umiddelbart, ikke etter hvert.
- **Hele kontoen din, med ett trykk: den knappen har appen ennå ikke.** Vi innrømmer det heller enn
  å late som noe annet. Inntil den finnes, skriv til
  **[contact@live.tips](mailto:contact@live.tips)**, så sletter vi kontoen og alt under den, for
  hånd. I mellomtiden kan du allerede slette hvert eneste band, noe som fjerner alt av substans —
  inkludert den lagrede Stripe-nøkkelen — og etterlater en tom konto.

## Rettighetene dine

Du kan be oss om å gi deg en kopi av, rette eller slette alt vi har om deg, og du kan klage til
datatilsynsmyndigheten i landet ditt. Skriv til
**[contact@live.tips](mailto:contact@live.tips)**.

I praksis er det meste av det allerede i dine egne hender: en artist kan slette en tipsside eller
et band fra appen på et blunk, uleverte tips fra fans fordamper innen timen, og logger du aldri
inn, har ingenting av det noen gang vært andre steder enn på din egen enhet.

## Barn

live.tips retter seg ikke mot barn, og vi behandler ikke bevisst deres data.

## Endringer

Vi oppdaterer denne siden når programvaren endres. Siden hele prosjektet er åpen kildekode,
ligger **hver eneste tidligere versjon av denne erklæringen i den offentlige git-historikken** —
du kan se nøyaktig hva som ble endret, og når.

## Språk

Denne erklæringen publiseres på alle språk nettstedet støtter, som en tjeneste. Hvis en
oversettelse og den engelske versjonen er uenige, er det **den engelske versjonen som gjelder**.
