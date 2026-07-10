---
title: Sådan håndterer live.tips penge (det gør det ikke)
description: Der er ingen live.tips-saldo, ingen udbetalingsplan og ingen andel. Her er arkitekturen, der gør de tre påstande kedelige i stedet for modige.
slug: sadan-handterer-live-tips-penge
---

Enhver drikkepengekrukke kan skrive „0 % gebyr" på sin landingsside. Det
interessante spørgsmål er, hvad softwaren skulle gøre for at *begynde* at tage en
andel, og hvor meget af det du ville kunne se.

For live.tips er svaret: den skulle bygges om. Det er ikke et løfte om vores
hensigter, det er en beskrivelse af, hvor pengene går hen.

## Kortdrikkepenge passerer aldrig gennem os

Når et fan trykker på et kortbeløb, taler dens browser med `api.stripe.com`. Ikke
med en live.tips-server – der er ingen i den sti. Betalingen oprettes på **din**
Stripe-konto, lander i **din** Stripe-saldo og udbetales efter **din** Stripe-plan.
Det eneste gebyr er Stripes eget standardgebyr for behandling, som Stripe opkræver
dig direkte, præcis som hvis du selv havde integreret Stripe.

Der er ingen kassebog hos os, fordi der ikke er noget at bogføre. Vi kunne ikke
skumme en procentdel af uden først at bygge det, der holder pengene.

## Dine nøgler forbliver dine

Opsætningen beder om en *begrænset* Stripe-API-nøgle, ikke en live secret key – dem
afviser vi blankt. Den gemmes i din egen enheds nøglering og sendes kun nogensinde
til Stripe over TLS.

Begrænset betyder, at nøglen kan to ting: oprette
betal-hvad-du-vil-drikkepengelinket og se drikkepenge komme ind. Den kan ikke læse
din saldo, udløse udbetalinger, foretage refusioner eller røre kundedata. Hvis den
lækkede i morgen, når skaden ikke længere end til et drikkepengelink.

## Det ene sted, hvor der findes en server

Revolut og MobilePay kan ikke styres fra en browser på samme måde som Stripe, så
det at slå dem til aktiverer et minimalt relæ på `api.live.tips`. Det er værd at
være præcis om, hvad det relæ gør, for „vi tilføjede en backend" er som regel dér,
disse historier går galt.

Det gemmer din offentlige drikkepengesideprofil – visningsnavnet og de
betalings-handles, du valgte at offentliggøre. Mere er det ikke. Det fører ingen
donationshistorik, ser ingen penge, holder ingen nøgler og sletter sig selv efter
90 dages inaktivitet. Pengene bevæger sig stadig direkte mellem dit fans Revolut-
eller MobilePay-app og din.

Hvis du kun bruger Stripe, kontaktes relæet aldrig overhovedet.

## Hvorfor du ikke bare skal tage os på ordet

Alt ovenstående kan efterprøves. Kodebasen er MIT-licenseret og offentlig, og siden
er et statisk build, som GitHub Actions udruller til GitHub Pages – ingen skjult
infrastruktur, intet der kompileres bag en dør. Åbn netværksfanen under en
demodrikkepenge og læs forespørgslerne. Der er færre, end du tror.

Det er det egentlige produktløfte. Ikke at vi er til at stole på, men at du ikke
har brug for, at vi er det.
