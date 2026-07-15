---
title: Bruksvilkår
description: live.tips er gratis programvare med åpen kildekode. Vi er ingen betalingsformidler, vi holder aldri pengene dine, og vi lover ingenting om tips vi ikke kan se. Detaljene, med rene ord.
updated: 2026-07-15
updated_label: Sist oppdatert 15. juli 2026
---

Disse vilkårene dekker live.tips-appen, dette nettstedet, den valgfrie live.tips-**kontoen** og det
valgfrie reléet bak tipssidene på `tip.live.tips`. live.tips drives av **Nikita Rabykin**, en
enkeltutvikler — ikke et selskap, ikke et team — og er utgitt som fri programvare med åpen
kildekode under
[MIT-lisensen](https://github.com/mekedron/live.tips/blob/main/LICENSE).

Ved å bruke live.tips godtar du det som følger. Det er kort, fordi live.tips gjør svært lite på
dine vegne — og det er hele poenget.

## Hva live.tips er

live.tips er **programvare du kjører selv**. Den gjør din egen Stripe-konto (eller Revolut,
MobilePay, Monzo) om til en levende tipskrukke med en QR-kode og en skjerm som fylles opp
etter hvert som fansen gir tips.

## Hva live.tips ikke er

**Vi er ingen betalingstjeneste, ingen bank, ingen depotordning og ingen part i transaksjonene
dine.** Vi holder, ruter eller rører aldri noens penger. Et tips reiser direkte fra fansen til
artistens egen betalingskonto. Det finnes ingen live.tips-saldo i midten, fordi det ikke finnes
noen live.tips-saldo i det hele tatt.

Konkret betyr dette:

- Vi tar **ingen provisjon** og krever **ingen gebyrer**. Det er ingenting å betale oss.
- Vi **kan ikke refundere et tips**, fordi vi aldri hadde det. Refusjoner hører til hos artisten
  og betalingsleverandøren deres.
- Vi **kan ikke se, fryse, reversere eller gjenopprette** noen betaling.
- Forholdet ditt om selve pengene er med **Stripe, Revolut, MobilePay eller Monzo**, under deres
  vilkår — ikke med oss.

## Tips er betaling for en opptreden

Tips som samles inn gjennom live.tips, er **frivillige betalinger til en artist for
liveopptredenen deres**. De er **ikke veldedige donasjoner**, og live.tips er ingen
innsamlingsplattform. Artister må beskrive virksomheten sin overfor betalingsleverandøren
tilsvarende — Stripe behandler særlig opptreden og pengeinnsamling som to forskjellige ting, og
bare den ene av dem er deg.

## Kontoer

En konto er **valgfri**, og det finnes fortsatt ingenting du må registrere deg for. Appen virker
helt uten konto — det er standarden, alt blir liggende på enheten din, og ingen live.tips-server er
involvert.

Vil du ha bandene, innstillingene og historikken din på mer enn én enhet, kan du logge inn med
**Apple**, med **Google**, eller som anonym **gjest**. En konto er et sted å oppbevare *dine egne*
data, på **Firebase** (Google), lesbare for kontoen din og for ingen andre. Hva den inneholder — og
hva det å logge inn endrer for personvernet ditt — står i personvernerklæringen, som er verdt å
lese før du logger inn.

Hvis du har en konto:

- **Det er ditt ansvar å passe på den.** Alle som kan logge inn som deg, kan se alt som ligger i
  den. Hold innloggingsmetoden din sikker, og bruk **Innstillinger → Sikkerhet** til å gå gjennom
  enhetene dine, tilbakekalle én, eller logge ut alle andre steder.
- **En gjestekonto kan ikke gjenopprettes.** Den har verken e-post eller passord. Mister du hver
  eneste enhet som er logget inn på den, er dataene borte — det er byttehandelen for å logge inn
  uten å gi oss noe. Bruk Apple eller Google hvis det betyr noe for deg.
- **Du er ansvarlig for det som ligger i den** — bandnavnene dine, de offentlige hilsenene dine, og
  alt annet du legger inn der.
- **Å legge til en enhet krever bekreftelsen din** på en enhet som allerede er innlogget. Ikke
  bekreft en enhet du ikke har bedt om, og ikke la noen fotografere QR-koden og så trykke bekreft
  likevel.
- **Push-varsler er valgfrie.** En innlogget konto kan slå på push-varsler, per enhet, for å høre
  om tips og sangønsker som kommer mens ingen sett kjører. De er av til du slår dem på, og kan slås
  av igjen når som helst; en gjestekonto og en enhet uten konto får ingen.
- **Vi kan suspendere eller slette en konto** — se *Å avslutte*, nedenfor.

## Hvis du er artist

Du er ansvarlig for:

- **Din egen betalingskonto** — å holde den i orden og følge reglene til Stripe, Revolut,
  MobilePay eller Monzo.
- **Skatten din.** Tips er inntekt. Vi rapporterer ingenting til noen, utsteder ingen
  skattedokumenter og vet ikke hva du tjente.
- **Refusjoner, tvister og tilbakeføringer**, som du håndterer i ditt eget betalingsdashbord.
- **Loven der du opptrer** — gatemusikanttillatelser, husregler på spillestedet og alt annet
  lokalt.
- **Det du publiserer.** Artistnavnet og hilsenen din vises på en offentlig tipsside; hold dem
  lovlige og dine egne.
- **Stripe-nøkkelen din.** Den er en begrenset nøkkel du selv har laget. **Uten konto bor den bare
  på enheten din.** Logger du inn, flytter den til serveren vår, kryptert slik at ingen — ikke en
  annen konto, ikke vi i klartekst, og ikke engang du — kan lese den tilbake; fra da av rapporterer
  Stripe tipsene dine til serveren vår, og de andre enhetene dine bruker nøkkelen bare gjennom oss.
  Uansett er den din: behandle en enhet som holder den som du ville behandlet kontanter, og
  tilbakekall nøkkelen i Stripe-dashbordet ditt hvis en enhet blir borte. Personvernerklæringen
  forklarer dette før du logger inn.
- **Bandene dine, og fanshilsenene du setter opp på skjermen.** Et navn og en hilsen vises for et
  rom fullt av folk. Det som dukker opp på den skjermen, er ditt å moderere.

## Hvis du er fan

- Å gi tips er **frivillig**, og når det først er sendt, er et tips som regel **endelig** — et
  livetips er ikke et kjøp med angrerett.
- Gikk noe galt med en betaling, ta det opp med **artisten** eller med betalingsleverandøren som
  behandlet den. Vi har ingen registrering av den og ingen makt over den.
- Hold navnet og hilsenen du legger ved, lovlig og sivilisert. De vises på en skjerm, på scenen,
  foran et rom fullt av folk.
- **Et sangønske er et tips, ikke en bestilling.** Har artisten slått på sangønsker, kan du gi tips
  til en sang — men pengene er et frivillig tips som ethvert annet, og det å betale, eller å betale
  mest, **garanterer ikke** at sangen spilles. Det er artistens avgjørelse.

## Uverifiserte tips — les denne

Revolut, MobilePay og Monzo gir en app **ingen mulighet til å bekrefte at en betaling faktisk
skjedde**. Et tips sendt med disse metodene dukker opp på artistens skjerm **i det øyeblikket
fansen sender inn skjemaet** — enten de så gjennomfører betalingen eller ikke.

live.tips merker disse tipsene som **uverifiserte**, og det betyr nøyaktig det: *noen sa at de
betalte.* De er en sceneeffekt, ikke en kvittering.

**Behandle aldri et uverifisert tips som bevis på betaling.** Artister må avstemme mot sin egen
Revolut-, MobilePay- eller Monzo-app. Stripe-tips er de eneste live.tips faktisk kan bekrefte, og
det er derfor Stripe er den anbefalte metoden.

## Reléet og tipssidene

Tipssidene ligger på `tip.live.tips` og serveres av et lite relé vi driver på Firebase. Det tilbys
**gratis, som en tjeneste, uten noen form for garanti**. Det er «beste forsøk»: det kan bli
frekvensbegrenset, det kan være utilgjengelig, og tips kan bli forsinket eller gå tapt. Hvor lenge
et tips beholdes avhenger av om artisten er innlogget: for en **tipsside uten konto bak seg**
beholder reléet bevisst ingenting som ville latt noen gjenopprette et tips i etterkant — et levert
tips slettes i det øyeblikket artistens skjerm viser det, og et ulevert feies bort innen timen. For
en **innlogget konto** skrives tipset inn i den artistens egen historikk og beholdes så lenge
bandet. Personvernerklæringen redegjør for begge tilfellene i sin helhet.

- En tipsside **uten konto bak seg slettes etter 90 dager uten aktivitet**.
- Vi kan **frekvensbegrense, blokkere eller slette enhver tipsside**, når som helst, uten varsel
  — særlig der vi ser svindel, identitetsmisbruk, misbruk, ulovlig innhold eller forsøk på å
  overbelaste tjenesten.
- Vi kan **endre reléet eller legge det ned helt**. Skulle vi noen gang gjøre det, vil oppsett med
  bare Stripe fortsette å virke, fordi de aldri var avhengige av oss.

Du må ikke bruke reléet, en tipsside eller en konto til å utgi deg for å være noen andre, til å
begå svindel, til å publisere ulovlig eller krenkende innhold, til å samle inn veldedige donasjoner
under falske forutsetninger, til å omgå frekvensgrensene eller bot-sjekken, eller til å angripe
tjenesten.

## Å avslutte

- **Du** kan slutte når som helst: logg ut, fjern et band, slett en tipsside, eller avinstaller
  appen. Personvernerklæringen sier nøyaktig hva hver av dem sletter — og sier ærlig at det å
  slette en hel konto foreløpig er en e-post til
  **[contact@live.tips](mailto:contact@live.tips)** og ikke en knapp i appen.
- **Vi** kan suspendere, tilbakekalle eller slette en konto, en tipsside eller tilgangen til
  tjenesten der den brukes til noe av det som er nevnt ovenfor, eller der det å la den kjøre ville
  sette tjenesten eller andre mennesker i fare. Her finnes det ingen klagenemnd. Det finnes en
  e-postadresse, og et menneske som leser den.
- Skulle den driftede tjenesten noen gang bli lagt ned, sier vi fra på dette nettstedet. Ingenting
  av verdi er låst inne i den: pengene ligger allerede på din egen betalingskonto, appen er åpen
  kildekode, og et oppsett med bare Stripe trengte oss aldri i det hele tatt.

## Ingen garanti

live.tips leveres **«som den er», uten garanti av noe slag**, verken uttrykkelig eller
underforstått, herunder enhver garanti om salgbarhet, egnethet for et bestemt formål eller
fravær av inngrep i tredjeparts rettigheter. Dette er standardposisjonen i MIT, og den er ment
bokstavelig.

Vi lover ikke at programvaren er fri for feil, at appen vil vise hvert eneste tips, at kontoen din
vil synkronisere, at reléet vil være tilgjengelig under settet ditt, eller at noen
tredjepartstjeneste vil oppføre seg.

## Ansvar

**I den grad loven tillater det, er vi ikke ansvarlige** for noe tap eller skade som oppstår som
følge av din bruk av live.tips. Det omfatter — uten begrensning — tips som er gått glipp av,
forsinket, duplisert eller ikke levert; tips som vises som uverifiserte og aldri ble betalt; data
som ikke lot seg synkronisere, eller som forsvant med en konto du ikke kunne gjenopprette; tapt
inntekt; en enhet som sviktet på scenen; handlingene, nedetiden eller beslutningene til Stripe,
Revolut, MobilePay, Monzo, Google, Apple, Cloudflare eller GitHub; og alt du tapte fordi du stolte
på et tall på en skjerm.

live.tips er fri programvare gitt bort av én person. Det finnes ingen inntekter her til å finansiere
et ansvar, og intet ansvar påtas.

To ærlige grenser for det avsnittet, fordi et vilkår som strekker seg for langt, er verdiløst:

- Vi utelukker **ikke** ansvar for **død eller personskade forårsaket av uaktsomhet, for svindel,
  eller for noe annet som ikke lovlig kan utelukkes**.
- Er du **forbruker**, beholder du alle **ufravikelige rettigheter lokal lovgivning gir deg**.
  Ingenting her tar dem fra deg.

## Programvaren er din

live.tips er MIT-lisensiert. Du kan **lese, forke, endre, drifte selv og kjøre den på egen hånd**
— inkludert reléet. Liker du ikke måten vi driver tjenesten på, er det ærlige svaret åpen kildekode
gir deg: kjør din egen. Kilden finnes på
[github.com/mekedron/live.tips](https://github.com/mekedron/live.tips).

Ingenting i disse vilkårene begrenser rettighetene MIT-lisensen gir deg over selve koden; disse
vilkårene styrer den **driftede tjenesten** — dette nettstedet, kontoene og reléet vi driver.

## Endringer

Vi kan oppdatere disse vilkårene etter hvert som programvaren endres. Hver tidligere versjon
ligger i den offentlige git-historikken, så du kan se nøyaktig hva som ble endret, og når.
Å fortsette å bruke tjenesten etter en endring betyr at du godtar den.

## Kontakt

**[contact@live.tips](mailto:contact@live.tips)** — et ekte menneske leser den.

## Språk

Disse vilkårene publiseres på alle språk nettstedet støtter, som en tjeneste. Hvis en oversettelse
og den engelske versjonen er uenige, er det **den engelske versjonen som gjelder**.
