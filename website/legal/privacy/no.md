---
title: Personvernerklæring
description: live.tips har ingen kontoer, ingen informasjonskapsler, ingen analyse og ingen sporing. Her er den korte lista over hva som faktisk behandles, av hvem, og hvor lenge.
updated: 2026-07-13
updated_label: Sist oppdatert 13. juli 2026
---

live.tips er en tipskrukke med åpen kildekode for artister. Den drives av **Nikita Rabykin**,
en enkeltutvikler, ikke et selskap. Hvis noe av det som står nedenfor betyr noe for deg, skriv
til **[contact@live.tips](mailto:contact@live.tips)** — den adressen når fram til et menneske.

Denne erklæringen er ærlig om de kjedelige delene. Vi sier heller «vi beholder navnet ditt i
inntil én time» enn å påstå at vi ikke beholder noe og ta feil.

## Kortversjonen

- **Ingen kontoer.** Det finnes ingenting å registrere seg for.
- **Ingen informasjonskapsler.** Ikke én, ingen steder.
- **Ingen analyse, ingen sporing, ingen annonser, ingen tredjepartsskript** på dette nettstedet.
- **Vi rører aldri pengene dine.** Tips går rett fra fansen til artistens egen
  Stripe-, Revolut-, MobilePay- eller Monzo-konto. Vi er ikke i den veien.
- **I standardoppsettet snakker appen bare med Stripe** — ikke med noen live.tips-server.
- Den eneste serveren vi i det hele tatt driver, er et lite relé, og det finnes bare hvis en
  artist slår på Revolut, MobilePay eller Monzo.

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

## Appen

live.tips-appen kjører **på artistens egen enhet**. Alt den vet, ligger der:

- Den **begrensede Stripe-nøkkelen** lagres i enhetens nøkkelring (iOS-/macOS-nøkkelring,
  Android Keystore) og sendes bare til `api.stripe.com`.
- **Tipshistorikk, økthistorikk, målet og appinnstillinger** lagres i lokal enhetslagring.
  Dette omfatter navnene og hilsenene fansen legger ved tipsene sine.
- Avinstallerer du appen, slettes alt sammen. Det finnes ingen skysikkerhetskopi hos oss, fordi
  det ikke finnes noen sky hos oss.

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

## Stripe

Når en fan betaler med kort, er vedkommende på **Stripes** betalingsside, ikke vår. Stripe samler
inn og behandler betalingsopplysningene som selvstendig behandlingsansvarlig under
[Stripes personvernerklæring](https://stripe.com/privacy). Vi ser aldri kortnumre, og vi har
ingen tilgang til artistens Stripe-konto.

Artistens app leser sine egne tips fra Stripe med artistens egen begrensede nøkkel. Navnet og
hilsenen til en fan, hvis de la igjen noe, reiser fra Stripe til artistens enhet og stopper der.

## Reléet — bare hvis Revolut, MobilePay eller Monzo er slått på

Oppsett med bare Stripe berører aldri dette, og kan slutte å lese her.

Revolut, MobilePay og Monzo gir ingen mulighet for en app til å bekrefte at en betaling faktisk
skjedde, så de tipsene rutes gjennom et lite relé med åpen kildekode som vi driver på
**Cloudflare** på `api.live.tips`. Det rører aldri penger. Her er alt det håndterer.

### Hva artisten lagrer

Å opprette en tipsside lagrer artistens **visningsnavn, den offentlige hilsenen, valutaen og de
betalingsidentitetene vedkommende valgte å publisere** (Stripe-betalingslenken, Revolut-brukernavnet,
MobilePay Box ID, Monzo-brukernavnet). Alt sammen er informasjon artisten uansett bevisst
publiserer til fansen.

- **Lagringstid: slettes automatisk etter 90 dager uten aktivitet.**
- Artisten kan slette den **umiddelbart** fra appen, når som helst.
- Ingen e-postadresse, intet passord, intet juridisk navn og ingen bankopplysninger samles noen
  gang inn.

### Hva en fan sender

Tipsskjemaet spør om et **beløp**, og valgfritt et **navn** og en **hilsen**. Det er hele
skjemaet. Ingen e-post, intet telefonnummer, ingen konto.

- Hvis artistens skjerm er **på nett**, sendes tipset rett videre til den og **skrives aldri til
  disk**.
- Hvis artistens skjerm er **frakoblet** — telefonen låst, ingen dekning — **holdes tipset i
  lagring i inntil én time** slik at det ikke bare går tapt, og overleveres i det øyeblikket
  skjermen kobler seg til igjen. Hvis ingen kobler seg til, **slettes det usett**. Dette er den
  eneste fanskrevne teksten reléet noen gang lagrer, og én time er den absolutte grensen.
- Navnet og hilsenen din legges også inn i **betalingsmeldingen** som åpnes i Revolut, MobilePay
  eller Monzo — det er slik artisten vet hvem som ga tips. Disse selskapene behandler den så
  under sine egne personvernerklæringer.
- Reléet beholder **ingen tipshistorikk**. Det kan ikke vise deg, oss eller noen andre en liste
  over hvem som ga tips til hvem.

### IP-adresser og misbruksvern

Et åpent skjema som hvem som helst kan sende til, trenger et visst vern mot bot-er, derfor:

- IP-adressen din brukes til å **frekvensbegrense** forespørsler, og sendes til **Cloudflare
  Turnstile** (en bot-sjekk som kjører på tipssiden) for å bekrefte at du ikke er en bot.
  Turnstile er Cloudflares produkt og brukes i stedet for en CAPTCHA som profilerer deg.
- For å hindre at noen oppretter tusenvis av tipssider, beholdes en **kryptografisk hash av
  IP-adressen** til den som oppretter en, i omtrent **to timer**, og forkastes så.
- **Cloudflares driftslogger** registrerer de tekniske detaljene om forespørsler til reléet —
  URL, tidspunkt, status — i noen få dager. De inneholder ikke fansens navn eller hilsener.
  Cloudflare opptrer som vår databehandler; se
  [Cloudflares personvernerklæring](https://www.cloudflare.com/privacypolicy/).

### Tellere

Reléet teller **hvor mange tips** en gitt tipsside har formidlet, slik at vi kan oppdage misbruk
og vite om greia i det hele tatt brukes. Det er et tall. Det inneholder ingen fansdata.

## Behandlingsgrunnlag, hvis du trenger et (GDPR)

- Å drive reléet for en artist som har slått det på, og å levere en fans tips til skjermen det
  var ment for: **oppfyllelse av en tjeneste du har bedt om**.
- Frekvensbegrensning, Turnstile og kvoter basert på hashet IP: **berettiget interesse** i å
  hindre at en gratis, åpen tjeneste ødelegges av bot-er og svindel.
- Serverlogger: **berettiget interesse** i å drifte og sikre tjenesten.

## Rettighetene dine

Du kan be oss om å gi deg en kopi av, rette eller slette alt vi har om deg, og du kan klage til
datatilsynsmyndigheten i landet ditt. Skriv til
**[contact@live.tips](mailto:contact@live.tips)**.

I praksis er det meste av det allerede i dine egne hender: artister kan slette tipssiden sin fra
appen på et blunk, tips fra fans fordamper innen timen, og alt annet ligger på din egen enhet.

## Barn

live.tips retter seg ikke mot barn, og vi behandler ikke bevisst deres data.

## Endringer

Vi oppdaterer denne siden når programvaren endres. Siden hele prosjektet er åpen kildekode,
ligger **hver eneste tidligere versjon av denne erklæringen i den offentlige git-historikken** —
du kan se nøyaktig hva som ble endret, og når.

## Språk

Denne erklæringen publiseres på alle språk nettstedet støtter, som en tjeneste. Hvis en
oversettelse og den engelske versjonen er uenige, er det **den engelske versjonen som gjelder**.
