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

## Det ene stedet der en server finnes

Revolut og MobilePay kan ikke styres fra en nettleser slik Stripe kan, så det å slå
dem på aktiverer et minimalt relé på `api.live.tips`. Det er verdt å være presis på
hva det reléet gjør, for «vi la til en backend» er som regel der disse historiene
går galt.

Det lagrer den offentlige tipsside-profilen din – visningsnavnet og
betalings-håndtakene du valgte å publisere. Mer er det ikke. Det fører ingen
donasjonshistorikk, ser ingen penger, holder ingen nøkler og sletter seg selv etter
90 dager uten aktivitet. Pengene beveger seg fortsatt direkte mellom Revolut- eller
MobilePay-appen til fanet ditt og din egen.

Hvis du bare bruker Stripe, kontaktes reléet aldri i det hele tatt.

## Hvorfor du ikke bør ta oss på ordet

Alt det ovenstående kan etterprøves. Kodebasen er MIT-lisensiert og offentlig, og
nettstedet er et statisk bygg som GitHub Actions ruller ut til GitHub Pages – ingen
skjult infrastruktur, ingenting som kompileres bak en dør. Åpne nettverksfanen
under et demotips og les forespørslene. Det er færre enn du venter.

Det er det egentlige produktløftet. Ikke at vi er til å stole på, men at du ikke
trenger at vi er det.
