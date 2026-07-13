---
title: Slik håndterer live.tips penger (det gjør det ikke)
description: Det finnes ingen live.tips-saldo, ingen utbetalingsplan og ingen andel. Her er arkitekturen som gjør de tre påstandene kjedelige i stedet for modige.
slug: slik-handterer-live-tips-penger
---

Enhver tipskrukke kan skrive «0 % gebyr» på landingssiden sin. Det interessante
spørsmålet er hva programvaren måtte gjøre for å *begynne* å ta en andel, og hvor
mye av det du ville kunne se.

For live.tips er svaret: den måtte bygges om. Det er ikke et løfte om intensjonene
våre, det er en beskrivelse av hvor pengene går.

## Korttips går aldri gjennom oss

Når et fan trykker på et kortbeløp, snakker nettleseren deres med `api.stripe.com`.
Ikke med en live.tips-server – det finnes ingen i den ruten. Betalingen opprettes
mot **din** Stripe-konto, havner i **din** Stripe-saldo og utbetales etter **din**
Stripe-plan. Det eneste gebyret er Stripes eget standard behandlingsgebyr, som
Stripe belaster deg direkte, akkurat som om du hadde integrert Stripe selv.

Det finnes ingen regnskapsbok hos oss, fordi det ikke er noe å føre. Vi kunne ikke
skumme av en prosentandel uten først å bygge det som holder pengene.

## Nøklene dine forblir dine

Oppsettet ber om en *begrenset* Stripe-API-nøkkel, ikke en live secret key – dem
avviser vi blankt. Den lagres i nøkkelringen på din egen enhet og sendes bare
noensinne til Stripe over TLS.

Begrenset betyr at nøkkelen kan gjøre to ting: opprette
betal-hva-du-vil-tipslenken og se tips komme inn. Den kan ikke lese saldoen din,
utløse utbetalinger, foreta refusjoner eller røre kundedata. Hvis den lekket i
morgen, når skaden ikke lenger enn til en tipslenke.

## Den eneste serveren i betalingsflyten

Revolut og MobilePay kan ikke styres fra en nettleser slik Stripe kan, så det å slå
dem på aktiverer et minimalt relé – en håndfull Firebase-funksjoner som serverer
tipssiden din på `tip.live.tips`. Det er verdt å være presis på hva det reléet
gjør, for «vi la til en backend» er som regel der disse historiene går galt.

Det lagrer den offentlige tipsside-profilen din – visningsnavnet og
betalings-håndtakene du valgte å publisere. Mer er det ikke. Det fører ingen
tipshistorikk, ser ingen penger, holder ingen nøkler og sletter seg selv etter
90 dager uten aktivitet. Et tips via Revolut eller MobilePay venter der bare til
scene-enheten din henter det: å vise det sletter det, og alt ingen kom tilbake
etter, feies bort innen timen. Pengene beveger seg fortsatt direkte mellom Revolut-
eller MobilePay-appen til fanet ditt og din egen.

Hvis du bare bruker Stripe, kontaktes reléet aldri i det hele tatt.

## Kontoen du ikke trenger å opprette

Appen starter fortsatt opp i en profil som bare finnes på enheten, slik den alltid
har vært: tipskrukka di, nøkkelen din og tipshistorikken din ligger på enheten og
ingen andre steder. Det er ingenting å registrere seg for.

Å logge inn – med Apple, med Google eller som gjest – er nå mulig, og det finnes av
én grunn: en enhet nummer to. Skal nettbrettet på scenen og telefonen i lomma vise
den samme kvelden, må noe sitte mellom dem, og det noe er Firestore, under en
bruker-id bare du kan lese. Bandene dine, innstillingene, den begrensede nøkkelen
og tipshistorikken synkroniseres dit. Det er en reell endring i personvernhistorien,
og den fortjener å bli sagt rett ut heller enn å bli oppdaget: uten konto ser ingen
server noen gang et tips; med konto gjør din egen krok av vår det. Det er prisen for
enhet nummer to, og det er din å betale eller avslå. Det den aldri rører, er
pengene – en konto flytter dataene dine, ikke saldoen din, og det tas fortsatt
ingen andel.

## Hvorfor du ikke bør ta oss på ordet

Alt det ovenstående kan etterprøves. Kodebasen er MIT-lisensiert og offentlig, og
nettstedet er et statisk bygg som GitHub Actions ruller ut til GitHub Pages – ingen
skjult infrastruktur, ingenting som kompileres bak en dør. Åpne nettverksfanen
under et demotips og les forespørslene. Det er færre enn du venter.

Det er det egentlige produktløftet. Ikke at vi er til å stole på, men at du ikke
trenger at vi er det.
