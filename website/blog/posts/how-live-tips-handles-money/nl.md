---
title: Hoe live.tips met geld omgaat (dat doet het niet)
description: Er is geen live.tips-saldo, geen uitbetalingsschema en geen commissie. Dit is de architectuur die die drie beweringen saai maakt in plaats van dapper.
slug: hoe-live-tips-met-geld-omgaat
---

Elke fooienpot kan „0% commissie" op zijn landingspagina zetten. De interessante
vraag is wat de software zou moeten doen om te *beginnen* met een deel af te romen,
en hoeveel je daarvan zou kunnen zien.

Bij live.tips is het antwoord: het zou opnieuw gebouwd moeten worden. Dat is geen
belofte over onze bedoelingen, het is een beschrijving van waar het geld heen gaat.

## Kaartfooien komen nooit langs ons

Wanneer een fan op een kaartbedrag tikt, praat zijn browser met `api.stripe.com`.
Niet met een live.tips-server – die zit niet in dat pad. De betaling wordt
aangemaakt op **jouw** Stripe-account, komt terecht in **jouw** Stripe-saldo en
wordt uitbetaald volgens **jouw** Stripe-schema. De enige kosten zijn Stripes
eigen standaard verwerkingskosten, die Stripe je rechtstreeks in rekening brengt,
precies zoals het zou gebeuren als je Stripe zelf had geïntegreerd.

Aan onze kant is er geen grootboek, omdat er niets te noteren valt. We zouden geen
percentage kunnen afromen zonder eerst datgene te bouwen wat het geld vasthoudt.

## Je sleutels blijven van jou

Bij het instellen wordt om een *beperkte* Stripe-API-sleutel gevraagd, niet om een
live secret key – die weigeren we ronduit. Hij wordt bewaard in de sleutelbos van
je eigen apparaat en alleen ooit via TLS naar Stripe gestuurd.

Beperkt betekent dat de sleutel twee dingen kan: de
betaal-wat-je-wilt-fooienlink aanmaken en toekijken hoe fooien binnenkomen. Hij
kan je saldo niet lezen, geen uitbetalingen starten, geen terugbetalingen doen en
geen klantgegevens aanraken. Als hij morgen zou uitlekken, reikt de schade niet
verder dan een fooienlink.

## De enige server in het betaalpad

Revolut en MobilePay laten zich niet vanuit een browser aansturen zoals Stripe dat
kan, dus het inschakelen ervan zet een minimale relay aan – een handvol
Firebase-functies die je fooienpagina op `tip.live.tips` serveren. Het is de
moeite waard om precies te zijn over wat die relay doet, want „we hebben een
backend toegevoegd" is meestal het punt waarop deze verhalen misgaan.

Het bewaart je openbare fooienpaginaprofiel – de weergavenaam en de betaal-handles
die je hebt gekozen om te publiceren. Meer niet. Het houdt geen fooiengeschiedenis
bij, ziet geen geld, bewaart geen sleutels en verwijdert zichzelf na 90 dagen
inactiviteit. Een fooi via Revolut of MobilePay wacht daar alleen tot je
podiumapparaat hem oppikt: zodra hij getoond wordt, wordt hij verwijderd, en alles
waar niemand voor terugkomt, wordt binnen het uur opgeruimd. Het geld beweegt nog
steeds rechtstreeks tussen de Revolut- of MobilePay-app van je fan en die van jou.

Als je alleen Stripe gebruikt, wordt de relay helemaal nooit benaderd.

## Het account dat je niet hoeft aan te maken

De app start nog steeds op in een profiel dat alleen op je apparaat leeft, precies
zoals het altijd was: je fooienpot, je sleutel en je fooiengeschiedenis staan op
het apparaat en nergens anders. Er is nergens iets om je voor aan te melden.

Inloggen – met Apple, met Google of als gast – kan nu wel, en dat bestaat om één
reden: een tweede apparaat. Als de tablet op het podium en de telefoon in je zak
dezelfde avond moeten tonen, moet er iets tussen zitten, en dat iets is Firestore,
onder een gebruikers-id die alleen jij kunt lezen. Je bands, instellingen,
beperkte sleutel en fooiengeschiedenis synchroniseren daarheen. Dat is een echte
verandering in het privacyverhaal, en die verdient het om ronduit gezegd te worden
in plaats van ontdekt: zonder account ziet geen enkele server ooit een fooi; met
een account ziet jouw eigen hoekje van de onze er wel een. Dat is de prijs van het
tweede apparaat, en het is aan jou om die te betalen of te weigeren. Wat het nooit
raakt, is het geld – een account verplaatst je gegevens, niet je saldo, en er wordt
nog altijd geen deel afgeroomd.

## Waarom je ons niet zomaar op ons woord moet geloven

Dit alles is te controleren. De codebase is MIT-gelicentieerd en openbaar, en de
site is een statische build die GitHub Actions naar GitHub Pages uitrolt – geen
verborgen infrastructuur, niets dat achter een deur gecompileerd wordt. Open het
netwerktabblad tijdens een demofooi en lees de requests. Het zijn er minder dan je
verwacht.

Dat is de eigenlijke productbelofte. Niet dat wij te vertrouwen zijn, maar dat het
niet nodig is dat we dat zijn.
