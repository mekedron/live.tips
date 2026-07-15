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

## Geld komt nooit langs ons

Wanneer een fan op een kaartbedrag tikt, wordt de betaling aangemaakt op **jouw**
Stripe-account, komt terecht in **jouw** Stripe-saldo en wordt uitbetaald volgens
**jouw** Stripe-schema. De enige kosten zijn Stripes eigen standaard
verwerkingskosten, die Stripe je rechtstreeks in rekening brengt, precies zoals het
zou gebeuren als je Stripe zelf had geïntegreerd.

Aan onze kant is er geen grootboek, omdat er niets te noteren valt. We zouden geen
percentage kunnen afromen zonder eerst datgene te bouwen wat het geld vasthoudt — en
dat bestaat niet.

Dat geldt of je nu inlogt of niet. Wat inloggen verandert is het *gegevens*pad, niet
het geldpad, en de volgende twee secties zijn eerlijk over precies hoe.

## Je sleutels, en waar ze wonen

Bij het instellen wordt om een *beperkte* Stripe-API-sleutel gevraagd, niet om een
live secret key – die weigeren we ronduit. Beperkt betekent dat de sleutel twee
dingen kan: de betaal-wat-je-wilt-fooienlink aanmaken en toekijken hoe fooien
binnenkomen. Hij kan je saldo niet lezen, geen uitbetalingen starten, geen
terugbetalingen doen en geen klantgegevens aanraken. Als hij morgen zou uitlekken,
reikt de schade niet verder dan een fooienlink.

**Zonder account verlaat die sleutel nooit je apparaat.** Hij zit in de sleutelbos
van je eigen apparaat en wordt uitsluitend via TLS naar `api.stripe.com` gestuurd.
Er komt helemaal geen live.tips-server aan te pas.

**Als je inlogt, verhuist de sleutel naar ons** – want een sleutel die alleen op één
telefoon bestaat, kan de tablet op het podium niet ook bedienen. We versleutelen hem
(een AES-256-sleutel per geheim, die zelf door Google Cloud KMS wordt ingepakt) en
bewaren hem op een plek waar niets hem kan teruglezen: geen ander account, wij niet
met een blik op een database, en zelfs jij niet. Hij wordt alleen binnen onze
functions ontzegeld, gebruikt om namens jou met Stripe te praten, en nooit meer aan
een apparaat gegeven. Zeg het ronduit: inloggen zet een live.tips-server in het pad
tussen Stripe en je fooiengeschiedenis. Nooit het geld — de gegevens.

## De servers, en wat ze niet kunnen

Er zijn er twee, en beide zijn minimaal.

**De relay** bestaat omdat Revolut en MobilePay zich niet vanuit een browser laten
aansturen zoals Stripe dat kan. Ze inschakelen zet een handvol Firebase-functies aan
die je fooienpagina op `tip.live.tips` serveren. Hij bewaart je openbare
fooienpaginaprofiel – de weergavenaam en de betaal-handles die je hebt gekozen om te
publiceren – en houdt, voor een pagina zonder account erachter, geen
fooiengeschiedenis bij: een fooi wacht alleen tot je podiumapparaat hem toont, en
alles waar niemand voor terugkwam, wordt binnen het uur opgeruimd. Hij ziet geen geld
en verwijdert zichzelf na 90 dagen inactiviteit. Als je alleen Stripe gebruikt en
nooit inlogt, wordt de relay helemaal nooit benaderd.

**De webhook** bestaat pas zodra je inlogt. Omdat je sleutel nu bij ons woont, meldt
Stripe elke fooi aan een kleine functie van ons, die hem in je eigen geschiedenis
wegschrijft zodat je andere apparaten hem kunnen tonen. Het is een kopie van een
gebeurtenis, niet een kopie van het geld. Hij kan geen cent verplaatsen, en kan
alleen ooit wegschrijven naar het ene account waar hij bij hoort.

Geen van beide servers kan een deel afromen, want geen van beide komt ook maar in de
buurt van het geld. Het meeste wat een van beide kan doen is falen — en een opzet met
alleen Stripe en zonder account is van geen van beide afhankelijk.

## Het account dat je niet hoeft aan te maken

De app start nog steeds op in een profiel dat alleen op je apparaat leeft, precies
zoals het altijd was: je fooienpot, je sleutel en je fooiengeschiedenis staan op
het apparaat en nergens anders. Er is nergens iets om je voor aan te melden.

Inloggen – met Apple, met Google of als gast – kan nu wel, en dat bestaat om één
reden: een tweede apparaat. Als de tablet op het podium en de telefoon in je zak
dezelfde avond moeten tonen, moet er iets tussen zitten, en dat iets is Firestore,
onder een gebruikers-id die alleen jij kunt lezen. Je bands, instellingen,
fooiengeschiedenis – en, versleuteld zoals hierboven, je Stripe-sleutel – wonen daar.
Dat is een echte verandering in het privacyverhaal, en die verdient het om ronduit
gezegd te worden in plaats van ontdekt: zonder account ziet geen enkele server ooit
een fooi; met een account ziet jouw eigen hoekje van de onze er wel een, en het is
onze webhook die hem daar wegschrijft. Dat is de prijs van het tweede apparaat, en
het is aan jou om die te betalen of te weigeren. Wat het nooit raakt, is het geld – een
account verplaatst je gegevens, niet je saldo, en er wordt nog altijd geen deel
afgeroomd.

## Waarom je ons niet zomaar op ons woord moet geloven

Dit alles is te controleren. De codebase is MIT-gelicentieerd en openbaar, en de
site is een statische build die GitHub Actions naar GitHub Pages uitrolt – geen
verborgen infrastructuur, niets dat achter een deur gecompileerd wordt. Open het
netwerktabblad tijdens een demofooi en lees de requests. Het zijn er minder dan je
verwacht.

Dat is de eigenlijke productbelofte. Niet dat wij te vertrouwen zijn, maar dat het
niet nodig is dat we dat zijn.
