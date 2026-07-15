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

## Penger går aldri gjennom oss

Når et fan trykker på et kortbeløp, opprettes betalingen mot **din** Stripe-konto,
havner i **din** Stripe-saldo og utbetales etter **din** Stripe-plan. Det eneste
gebyret er Stripes eget standard behandlingsgebyr, som Stripe belaster deg direkte,
akkurat som om du hadde integrert Stripe selv.

Det finnes ingen regnskapsbok hos oss, fordi det ikke er noe å føre. Vi kunne ikke
skumme av en prosentandel uten først å bygge det som holder pengene – og noe slikt
finnes ikke.

Det gjelder enten du logger inn eller ikke. Det å logge inn endrer *data*veien,
ikke pengeveien, og de neste to delene er ærlige om nøyaktig hvordan.

## Nøklene dine, og hvor de ligger

Oppsettet ber om en *begrenset* Stripe-API-nøkkel, ikke en live secret key – dem
avviser vi blankt. Begrenset betyr at nøkkelen kan gjøre to ting: opprette
betal-hva-du-vil-tipslenken og se tips komme inn. Den kan ikke lese saldoen din,
utløse utbetalinger, foreta refusjoner eller røre kundedata. Hvis den lekket i
morgen, når skaden ikke lenger enn til en tipslenke.

**Uten konto forlater den nøkkelen aldri enheten din.** Den ligger i enhetens egen
nøkkelring og sendes bare noensinne til `api.stripe.com` over TLS. Ingen
live.tips-server er inne i bildet i det hele tatt.

**Når du logger inn, flytter nøkkelen til oss** – fordi en nøkkel som bare finnes
på én telefon, ikke kan betjene nettbrettet på scenen også. Vi krypterer den (en
AES-256-nøkkel per hemmelighet, som selv er pakket inn av Google Cloud KMS) og
lagrer den et sted der ingenting kan lese den tilbake: ikke en annen konto, ikke vi
som kikker i en database, ikke engang du. Den låses opp bare inne i funksjonene
våre, brukes til å snakke med Stripe på dine vegne, og overleveres aldri til en
enhet igjen. Sagt rett ut: å logge inn setter en live.tips-server i veien mellom
Stripe og tipshistorikken din. Aldri pengene – dataene.

## Serverne, og hva de ikke kan gjøre

Det er to av dem, og begge er minimale.

**Reléet** finnes fordi Revolut og MobilePay ikke kan styres fra en nettleser slik
Stripe kan. Å slå dem på aktiverer en håndfull Firebase-funksjoner som serverer
tipssiden din på `tip.live.tips`. Det lagrer den offentlige tipsside-profilen din –
visningsnavnet og betalings-håndtakene du valgte å publisere – og, for en side uten
konto bak seg, fører det ingen tipshistorikk: et tips venter bare til scene-enheten
din viser det, og alt ingen kom tilbake etter, feies bort innen timen. Det ser
ingen penger og sletter seg selv etter 90 dager uten aktivitet. Bruker du bare
Stripe og aldri logger inn, kontaktes reléet aldri i det hele tatt.

**Webhooken** finnes bare når du først har logget inn. Fordi nøkkelen din nå bor
hos oss, rapporterer Stripe hvert tips til en liten funksjon hos oss, som skriver
det inn i din egen historikk slik at de andre enhetene dine kan vise det. Det er en
kopi av en hendelse, ikke en kopi av pengene. Den kan ikke flytte en eneste krone,
og den kan bare noensinne skrive inn i den ene kontoen den hører til.

Ingen av serverne kan ta en andel, fordi ingen av dem er i nærheten av pengene. Det
meste hver av dem kan gjøre, er å svikte – og et oppsett med bare Stripe og uten
konto er avhengig av ingen av dem.

## Kontoen du ikke trenger å opprette

Appen starter fortsatt opp i en profil som bare finnes på enheten, slik den alltid
har vært: tipskrukka di, nøkkelen din og tipshistorikken din ligger på enheten og
ingen andre steder. Det er ingenting å registrere seg for.

Å logge inn – med Apple, med Google eller som gjest – er nå mulig, og det finnes av
én grunn: en enhet nummer to. Skal nettbrettet på scenen og telefonen i lomma vise
den samme kvelden, må noe sitte mellom dem, og det noe er Firestore, under en
bruker-id bare du kan lese. Bandene dine, innstillingene, tipshistorikken – og,
kryptert som ovenfor, Stripe-nøkkelen din – ligger der. Det er en reell endring i
personvernhistorien, og den fortjener å bli sagt rett ut heller enn å bli oppdaget:
uten konto ser ingen server noen gang et tips; med konto gjør din egen krok av vår
det, og det er webhooken vår som skriver det dit. Det er prisen for enhet nummer to,
og det er din å betale eller avslå. Det den aldri rører, er pengene – en konto
flytter dataene dine, ikke saldoen din, og det tas fortsatt ingen andel.

## Hvorfor du ikke bør ta oss på ordet

Alt det ovenstående kan etterprøves. Kodebasen er MIT-lisensiert og offentlig, og
nettstedet er et statisk bygg som GitHub Actions ruller ut til GitHub Pages – ingen
skjult infrastruktur, ingenting som kompileres bak en dør. Åpne nettverksfanen
under et demotips og les forespørslene. Det er færre enn du venter.

Det er det egentlige produktløftet. Ikke at vi er til å stole på, men at du ikke
trenger at vi er det.
