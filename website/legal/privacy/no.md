---
title: Personvernerklæring
description: live.tips har ingen informasjonskapsler, ingen analyse og ingen sporing, og virker helt uten konto. Velger du å logge inn, står det her nøyaktig hva som lagres, hvor, av hvem, og hvor lenge.
updated: 2026-07-13
updated_label: Sist oppdatert 13. juli 2026
---

live.tips er en tipskrukke med åpen kildekode for artister. Den drives av **Nikita Rabykin**,
en enkeltutvikler, ikke et selskap. Hvis noe av det som står nedenfor betyr noe for deg, skriv
til **[contact@live.tips](mailto:contact@live.tips)** — den adressen når fram til et menneske.

Denne erklæringen er ærlig om de kjedelige delene. Vi sier heller «vi beholder navnet ditt i
inntil én time» enn å påstå at vi ikke beholder noe og ta feil.

## Kortversjonen

- **En konto er valgfri.** Appen virker helt uten konto, og det er fortsatt standarden. Vil du ha
  bandene og historikken din på en enhet nummer to, kan du logge inn — og da lagres noe av det på
  en tjener. Hva som er hva, står nedenfor.
- **Ingen informasjonskapsler.** Ikke én, ingen steder.
- **Ingen analyse, ingen sporing, ingen annonser, ingen tredjepartsskript** på dette nettstedet.
- **Vi rører aldri pengene dine.** Tips går rett fra fansen til artistens egen
  Stripe-, Revolut-, MobilePay- eller Monzo-konto. Vi er ikke i den veien.
- **I standardoppsettet snakker appen bare med Stripe** — ikke med noen live.tips-server.
- Den eneste serveren vi i det hele tatt driver, er et lite relé på Googles Firebase. Det finnes
  bare hvis en artist slår på Revolut, MobilePay eller Monzo — eller hvis vedkommende logger inn.

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
- **Tipshistorikk, økthistorikk, målet og appinnstillinger** lagres i lokal enhetslagring.
  Dette omfatter navnene og hilsenene fansen legger ved tipsene sine.
- Avinstallerer du appen, slettes alt sammen. Det finnes ingen skysikkerhetskopi hos oss, fordi
  det i denne modusen ikke finnes noen sky hos oss.

**Vi mottar aldri noe av dette.** Appen leveres uten analyse-SDK, uten krasjrapportering, uten
push-varsler og uten annonsekode — ingen, ikke engang deaktiverte.

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
  e-postadressen din; Apple gir oss da en relé-adresse i stedet.)
- **En gjestekonto** — en anonym konto uten e-post og uten navn. Den synkroniserer og den kan
  tilbakekalles, men det finnes ingenting å gjenopprette den med om du mister enheten. Den er en
  uid og ikke noe mer.

Når du først har logget inn, får kontoen sin egen private krok av Googles **Cloud
Firestore**-database, på `users/<your uid>/`. Sikkerhetsreglene gir den kroken til den uid-en **og
til ingen andre** — ingen annen konto kan lese den, heller ikke ved å gjette URL-er. Inni den:

| Hva | Hvorfor det ligger der |
| --- | --- |
| **Bandene** dine — navn, innstillinger for tipskrukke og betalingsmåter, plakattekst, mål | slik at et band finnes på hver enhet du logger inn på |
| Den **begrensede Stripe-nøkkelen** din og hemmeligheten til reléets tipsside | i et hemmelighetsdokument bare uid-en din kan lese, og bufret i nøkkelringen på hver av enhetene dine |
| **Appinnstillinger** | slik at en enhet du legger til, allerede er satt opp |
| **Øktregistreringer og tipshistorikk** — inkludert **navnene og hilsenene fansen legger ved tipsene sine** | fordi den historikken er nøyaktig det du ba om å få se på den andre enheten |
| Den **liveøkten** som kjører akkurat nå | slik at en skjerm nummer to kan bli med på kveldens sett |
| **Enhetene** dine — navnet hver av dem gir seg selv («Nikitas iPhone»), plattformen og modellen, når den ble sett første og siste gang | slik at Innstillinger → Sikkerhet kan liste dem opp, og du kan tilbakekalle én |
| Et lite **profildokument** — kontonavnet du valgte, og hvilken leverandør du brukte | slik at kontovelgeren kan sette navn på den |

Og så det viktige, rett fram: **uten konto forlater en fans navn og hilsen aldri artistens enhet.
Med konto lagres de på Googles tjenere under artistens uid, som en del av artistens egen
synkroniserte historikk.** Ingen annen konto kan lese dem, vi ser ikke på dem, og ingenting utledes
av dem — men de er der, og det bør du vite før du logger inn.

Logger du ut, går enheten tilbake til lokal modus. Det sletter ikke kontoens data — se *Å slette
ting*, nedenfor.

### Å legge til en enhet med QR-kode

For å legge til en enhet viser du en QR-kode fra en enhet som allerede er innlogget. Koden er
tilfeldig, **kan bare brukes én gang, og utløper etter to minutter**, og den nye enheten får
ingenting før du trykker *bekreft* på den gamle. Så lenge det håndtrykket står åpent, holder vi på
koden, navnet den nye enheten ga seg selv, og plattformen dens — og oppføringen slettes når den
utløper. En avfotografert QR-kode er verdiløs uten det bekreftende trykket ditt.

## Hvor alt dette fysisk ligger

Firebase Auth, Cloud Firestore og våre Cloud Functions kjører i **Den europeiske union** —
databasen i Googles `eur3`-multiregion, funksjonene i `europe-west1`. Google opptrer som vår
databehandler under
[Firebases personvern- og sikkerhetsvilkår](https://firebase.google.com/support/privacy) og sin
egen [personvernerklæring](https://policies.google.com/privacy). Som enhver stor leverandør kan
Google trekke inn infrastruktur utenfor EU til støtte og sikkerhet; det styres av de vilkårene,
ikke av oss.

## Stripe

Når en fan betaler med kort, er vedkommende på **Stripes** betalingsside, ikke vår. Stripe samler
inn og behandler betalingsopplysningene som selvstendig behandlingsansvarlig under
[Stripes personvernerklæring](https://stripe.com/privacy). Vi ser aldri kortnumre, og vi har
ingen tilgang til artistens Stripe-konto.

Artistens app leser sine egne tips fra Stripe med artistens egen begrensede nøkkel — rett fra
enheten til `api.stripe.com`. **Det finnes ingen live.tips-server i den veien, og det har det
aldri gjort.** Navnet og hilsenen til en fan, hvis de la igjen noe, reiser fra Stripe til artistens
enhet og stopper der — med mindre artisten har logget inn, og da lagrer enheten dem også i den
artistens egen Firestore-historikk, som beskrevet ovenfor.

## Reléet — bare hvis Revolut, MobilePay eller Monzo er slått på

Oppsett med bare Stripe berører aldri dette.

Revolut, MobilePay og Monzo gir ingen mulighet for en app til å bekrefte at en betaling faktisk
skjedde, så de tipsene rutes gjennom et lite relé med åpen kildekode som vi driver på
**Firebase** — Cloud Functions og Firestore i `europe-west1`, med fansens tipsside servert fra
**`tip.live.tips/t/<id>`**. Det rører aldri penger. Her er alt det håndterer.

### Hva artisten lagrer

Å opprette en tipsside lagrer artistens **visningsnavn, den offentlige hilsenen, valutaen og de
betalingsidentitetene vedkommende valgte å publisere** (Stripe-betalingslenken, Revolut-brukernavnet,
MobilePay Box ID, Monzo-brukernavnet). Alt sammen er informasjon artisten uansett bevisst
publiserer til fansen.

- **Lagringstid: en tipsside uten konto bak seg slettes automatisk etter 90 dager uten aktivitet.**
  En tipsside som hører til en innlogget konto, lever så lenge bandet den hører til.
- Artisten kan slette den **umiddelbart** fra appen, når som helst.
- Ingen e-postadresse, intet passord, intet juridisk navn og ingen bankopplysninger samles inn her.
- Sidens hemmelighet lagres **bare som en hash**. Vi kunne ikke fortalt deg hemmeligheten om du ba
  om den; vi kan bare sjekke én.

### Hva en fan sender

Tipsskjemaet spør om et **beløp**, og valgfritt et **navn** og en **hilsen**. Det er hele
skjemaet. Ingen e-post, intet telefonnummer, ingen konto.

- Tipset skrives til en **leveringskø** — ett enkelt dokument som finnes for å bli overlevert til
  artistens skjerm. Når skjermen viser tipset, **sletter artistens enhet det dokumentet.**
  Slettingen *er* kvitteringen; det finnes ikke noe «levert»-flagg, fordi det ikke er noen
  oppføring igjen å flagge.
- Hvis artistens skjerm er frakoblet — telefonen låst, ingen dekning — **venter tipset i den køen i
  inntil én time**, slik at det ikke bare går tapt, og går over i det øyeblikket skjermen kobler
  seg til igjen. Hvis ingen kobler seg til, **slettes det usett**, ryddet vekk etter en fast plan,
  uansett om noen noen gang kom tilbake for det eller ikke.
- **Den køen er det eneste stedet fanskrevet tekst noen gang lagres på tjeneren vår, og én time er
  den absolutte grensen.** Er artisten innlogget, beholder enheten deretter tipset i *deres* egen
  Firestore-historikk — fordi det er deres historikk, og det er det de logget inn for.
- Navnet og hilsenen din legges også inn i **betalingsmeldingen** som åpnes i Revolut, MobilePay
  eller Monzo — det er slik artisten vet hvem som ga tips. Disse selskapene behandler den så
  under sine egne personvernerklæringer.
- Reléet beholder **ingen tipshistorikk**. Det kan ikke vise deg, oss eller noen andre en liste
  over hvem som ga tips til hvem.

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
| **Google (Firebase)** | Kontoene, en innlogget artists synkroniserte data, reléet, tjenerlogger | Den valgfrie kontoen og det valgfrie reléet |
| **Stripe** | Fansens betalingsopplysninger, som selvstendig behandlingsansvarlig | Korttips |
| **Cloudflare** | Fansens IP-adresse, til Turnstile-sjekken på tipssiden. Og DNS-en vår. | Å holde bot-er unna tipsskjemaet |
| **GitHub** | IP-adressen og user-agenten til alle som laster dette nettstedet | Drift av nettstedet |
| **Revolut / MobilePay / Monzo** | Det fansen gjør i deres egen app, betalingsmeldingen inkludert | Disse betalingsmåtene |

Vi selger ingenting til noen, og det står ingen andre på den lista.

## Behandlingsgrunnlag, hvis du trenger et (GDPR)

- Å drive en konto du har bedt om, å synkronisere dine egne data til dine egne enheter, å drive
  reléet for en artist som har slått det på, og å levere en fans tips til skjermen det var ment
  for: **oppfyllelse av en tjeneste du har bedt om**.
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
- **En enhet**: Innstillinger → Sikkerhet lister opp enhetene dine. Du kan tilbakekalle én, eller
  logge ut alle andre steder — noe som avslutter økten på hver eneste av de andre enhetene
  umiddelbart, ikke etter hvert.
- **Hele kontoen din, med ett trykk: den knappen har appen ennå ikke.** Vi innrømmer det heller enn
  å late som noe annet. Inntil den finnes, skriv til
  **[contact@live.tips](mailto:contact@live.tips)**, så sletter vi kontoen og alt under den, for
  hånd. I mellomtiden kan du allerede slette hvert eneste band, noe som fjerner alt av substans og
  etterlater en tom konto.

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
