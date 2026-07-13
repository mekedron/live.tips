# Bouw een fooienpot op je eigen Stripe-account

> Drie API-calls geven je een gehoste pay-what-you-want-pagina met Apple Pay en Google Pay, zonder enige server. Hier is de volledige bouw: de restricted key, de scopes, hoe je fooien binnenleest zonder webhook, en de kostenberekening die niemand afdrukt.

Canonical: https://live.tips/nl/blog/bouw-een-fooienpot-op-je-eigen-stripe-account/
Published: 2026-07-11
Language: nl
Tags: Stripe, open source, how-to, API, fees

---

Je wilt een fooienpot. Je wilt geen 5 % van de avond van een straatmuzikant aan een
platform geven, en je kunt prima met een API overweg. De vraag is dus niet *bij welke
fooienpot moet ik me aanmelden*, maar *hoeveel moet ik eigenlijk bouwen*.

Minder dan je denkt. Op Stripe is het werkende antwoord: drie API-calls, geen server,
geen backend, geen webhook-endpoint. De rest van dit stuk is die bouw, plus de twee
dingen die iedereen fout doet.

## De truc is een pay-what-you-want Price

Stripe kent een prijsmodus waarin de fan het bedrag zelf intikt. Dat heet
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want), en dat
is de hele feature. Je maakt een Product, hangt er een Price aan met
`custom_unit_amount[enabled]=true`, en daaroverheen een
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. het ding dat je "verkoopt"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. de prijs die de fan mag kiezen
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. de pagina
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

Die derde call geeft een `url` terug. Die URL *is* je fooienpot. Het is een door Stripe
gehoste pagina, dus PCI-compliant zonder dat je erover nadenkt, gelokaliseerd, en hij
toont Apple Pay of Google Pay aan elke fan wiens telefoon dat heeft ingesteld —
[dynamic payment methods](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
bepalen dat voor je op basis van apparaat en land. Je hebt geen frontend geschreven.

Codeer de URL als QR-code met welke library je maar wilt — het is gewoon een string —
print hem, plak hem op de koffer. De code verloopt nooit, en hij wijst niet naar een
server van jou, want die heb je niet.

Twee parameters om te kennen:

- **`custom_unit_amount[preset]`** is het bedrag waarmee de pagina opent. `500` betekent
  dat de fan € 5,00 al ingevuld ziet en het kan wijzigen. Dit getal doet meer voor je
  gemiddelde fooi dan wat dan ook op die pagina.
- **`custom_unit_amount[minimum]`** is een ondergrens. Zet er een. Waarom staat in de
  kostensectie hieronder, en het is geen afrondingsfout.

Je kunt ook een naam en een bericht ophalen. Payment Links nemen tot drie `custom_fields`
— zo krijg je "van wie was dat dan" op de pagina zonder een formulier te bouwen:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Je naam of bijnaam" \
  -d "custom_fields[0][optional]"=true
```

Stripe heeft [eisen voor het accepteren van fooien en donaties](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
lees ze één keer. Pay-what-you-want laat zich ook niet combineren met andere line items,
kortingen of terugkerende betalingen. Voor een fooienpot bijt daarvan niets.

Dat onderscheid is het waard om goed te hebben. Stripe zegt het zo: een fooi wordt gegeven
voor een reeds geleverd goed of dienst, terwijl een donatie gekoppeld moet zijn aan een
goed doel. Jij speelde de set; de fooi betaalt ervoor. Daarom stuurt de call hierboven ook
`submit_type=pay` en niet `donate` — `donate` zou je link op `donate.stripe.com` zetten en
*Doneren* op de knop drukken. Dat is een ander vak, en eentje dat Stripe veel strenger
beoordeelt.

## De key: ga ervan uit dat hij lekt, en maak dat saai

Zet geen secret key (`sk_live_…`) op een apparaat dat op een podium staat. Gebruik een
[restricted key](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): je kiest
per resource een permissie, en alles wat je niet kiest staat op **None**.

Voor de bouw hierboven is de volledige lijst vijf regels:

| Resource | Permissie | Wat het je oplevert |
| --- | --- | --- |
| Products | Write | het Product aanmaken |
| Prices | Write | de pay-what-you-want Price aanmaken |
| Payment Links | Write | de link aanmaken |
| Checkout Sessions | Read | de binnengekomen fooien zien |
| Events | Read | de live feed (volgende sectie) |

Al het andere — Balance, Payouts, Refunds, Customers, PaymentIntents, heel Connect —
blijft op **None**.

Doe nu de oefening die dit de moeite waard maakt. Om één uur 's nachts wordt je tablet van
de merch-tafel gejat. Wat kan de dief met de key in de keychain? Je fooienhistorie lezen en
meer fooienlinks in je account aanmaken. Dat is de hele blast radius. Hij ziet je saldo niet,
kan geen uitbetaling starten, geen refund naar een kaart van zichzelf sturen, geen
klantenlijst lezen. Je trekt de key in vanaf een telefoon in de taxi naar huis en het
apparaat gaat op zwart. Aan je geld is niets bewogen.

Die asymmetrie — schrijftoegang tot de fooienpot, nul toegang tot het geld — is de enige
reden waarom een serverloos, breng-je-eigen-key-ontwerp überhaupt te verdedigen is. Het is
ook waarom "Login with Stripe" hier niet het antwoord is: OAuth heeft een server van de
app-ontwikkelaar nodig om je token vast te houden, en een server is precies wat we niet
bouwen.

(Een eigenaardigheid die je gaat tegenkomen: de *Prices*-permissie heet intern `plan_write`,
dus Stripe's foutmelding noemt een scope die in het dashboard niet onder die naam bestaat.
Het is Prices.)

## Fooien binnenlezen zonder webhook

Hier stoppen de meeste uitleggen, of ze grijpen naar een webhook — en hier is een podium
echt anders dan een webapp.

Een webhook is een inkomend HTTP-verzoek. Een tablet achter een microfoonstandaard kan er
geen ontvangen. Hij hangt op het gasten-wifi van een zaal achter NAT, heeft geen publiek
adres, geen TLS-certificaat, en hoort dat allemaal ook niet te hebben. Neem je de
webhook-route, dan moet je een server neerzetten om de events te vangen en een socket om ze
naar het apparaat te duwen — een backend, een beheerlast, en een plek waar de namen van je
fans nu wonen. Je hebt zojuist het platform herbouwd dat je wilde vermijden.

Trek dus, in plaats van je te laten duwen. Stripe's endpoint
[List all events](https://docs.stripe.com/api/events/list) is publiek, gedocumenteerd, en
geeft events nieuwste-eerst terug:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_LAATSTE_DIE_IK_ZAG \
  -d limit=100
```

`ending_before` is het hele ontwerp. Bewaar het id van het nieuwste event dat je hebt
verwerkt; elke poll vraagt om alles wat strikt nieuwer is, en je schuift de cursor op. Geen
timestamps, geen clock skew, geen dedupliceren op bedrag. Bij de eerste poll van een set
vraag je `limit=1` zonder cursor om je te verankeren op wat er al staat, zodat je niet bij
de soundcheck de fooien van vanochtend opnieuw afspeelt.

Filter dan wat terugkomt. Beide event-types kunnen voor één betaling afgaan, dus dedupliceer
op het Checkout Session-id. Controleer `payment_status == "paid"` — een voltooide sessie is
niet per se een betaalde. En controleer dat `payment_link` overeenkomt met *jouw* link, want
`/v1/events` geldt accountbreed en overhandigt je vrolijk het verkeer van al het andere dat
dat Stripe-account doet.

Wees eerlijk over de afwegingen, want ze zijn echt:

- **Stripe raadt webhooks aan.** Pollen is niet het gezegende pad; het is een gedocumenteerd
  endpoint dat je bewust inzet. Zeg dat in je README en ga door.
- **Events gaan 30 dagen terug.** [Stripe's eigen woorden](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Dit is een live feed, geen grootboek. Je grootboek
  zijn de Checkout Sessions — en je échte grootboek is het Stripe-dashboard.
- **Let op de read allocation.** Iedereen kijkt naar de limiet per seconde
  ([rate limits](https://docs.stripe.com/rate-limits): 100 req/s live) en niemand naar de andere:
  Stripe kent ongeveer **500 leesverzoeken per transactie** toe over een voortschrijdende 30
  dagen, met een bodem van 10.000 reads per maand. Poll elke 4 seconden en een set van drie uur
  is ~2.700 reads. Vier lange optredens in een maand en je zit op de bodem. Fooien kopen je
  ruimte zodra ze binnenkomen, maar wie elke seconde pollt omdat dat vlotter aanvoelde, vindt
  het plafond. Vier seconden is geen luie keuze; het *is* het getal.

Dat is de eerlijke vorm ervan: pollen kost je een paar duizend GET's en levert je het schrappen
van een compleet backend op.

## De kostenberekening, netjes gedaan

Een platform dat 0 % adverteert is niet gratis, en dit ook niet. Stripe's eigen verwerkingskosten
gelden voor elke fooi, en Stripe brengt ze rechtstreeks bij jou in rekening. Vandaag kost een
standaard EER-kaart volgens [Stripe's euro-tarieven](https://stripe.com/ie/pricing) **1,5 % +
€ 0,25**. Premium EER-kaarten 1,9 % + € 0,25, Britse kaarten 2,5 % + € 0,25, en al het overige
3,25 % + € 0,25 met nog eens 2 % als er een valuta omgerekend moet worden. (In de VS is het
2,9 % + $ 0,30, wat slechter is om precies de reden hieronder.)

Het percentage is het probleem niet. De vijfentwintig cent is het probleem.

| Fooi | Stripe pakt | Artiest houdt | Effectieve afroming |
| --- | --- | --- | --- |
| € 2 | € 0,28 | € 1,72 | **14,0 %** |
| € 5 | € 0,33 | € 4,67 | 6,5 % |
| € 10 | € 0,40 | € 9,60 | 4,0 % |
| € 20 | € 0,55 | € 19,45 | 2,8 % |
| € 50 | € 1,00 | € 49,00 | 2,0 % |

Een vast bedrag is een vermomd percentage, en bij klein geld zakt de vermomming af. Diezelfde
€ 0,25 die onzichtbaar is op een fooi van € 50 vreet een achtste van een fooi van € 2. Fooien
zijn van nature klein — dat maakt ze juist fooien — dus dit is geen randgeval, het is het
mediane geval.

Daarom zet je `custom_unit_amount[minimum]`. Ergens rond de € 2 houdt de transactie op zinvol te
zijn; een kaartfooi van € 0,50 zou binnenkomen als € 0,24 en kost Stripe meer om te verplaatsen
dan hij waard is. Kies je ondergrens bewust in plaats van hem bij je eerste uitbetaling te
ontdekken.

En zie wat dit doet met de vergelijking waarmee je begon. Een platform dat 0 % bovenop Stripe
rekent, rekent 0 % bovenop **dit**. Hun 0 % is echt — en het is 0 % van wat de verwerker heeft
overgelaten. Niemands kaartrail is gratis: de eerlijke claim is "geen afroming bovenop die van de
verwerker", en wie meer beweert liegt, of gebruikt geen kaarten.

## Wat je nu hebt, en wat niet

Drie API-calls en een QR-code, en een echte fooienpot: gehost, PCI-compliant, Apple Pay, Google
Pay, fooien die op je eigen Stripe-saldo landen volgens je eigen uitbetalingsschema, en geen
server in het pad. Voor veel mensen is dat oprecht het einde van het project, en je mag hier
gerust stoppen en het uitbrengen.

Wat je niet hebt is een podium. Je hebt een betaalpagina. Daartussen staan de saaie dingen: de
poll-loop met zijn cursor en zijn backoff, een scherm dat het publiek kan zien met het doel en het
laatste bericht erop, een plek voor de key die geen `localStorage` heet, een slot zodat een
vreemde niet tussen de sets door aan de tablet zit te prutsen, en de duizend-kleine-beslissingen
laag van wat er gebeurt als de wifi van de zaal midden in de set wegvalt.

Dat is [live.tips](https://github.com/mekedron/live.tips) — precies deze architectuur, afgebouwd,
MIT-gelicenseerd. De restricted key met die vijf scopes, de `/v1/events`-cursorloop, het aanmaken
van Product/Price/Payment Link, alles draaiend op het apparaat van de artiest tegen diens eigen
account. Er staat geen live.tips-server in het Stripe-pad en er is nergens een live.tips-saldo — dat
schreven we apart op in [hoe live.tips met geld omgaat](https://live.tips/nl/blog/hoe-live-tips-met-geld-omgaat/).

Lees de broncode, pak eruit wat je wilt, of gebruik het gewoon. De kern van dit stuk is dat de
architectuur geen geheim en niet moeilijk is: **Stripe host je fooienpot gratis, en een restricted
key plus een poll-loop is alles wat tussen een artiest en zijn eigen geld staat.** Wij hebben liever
dat je dat weet dan dat je je ergens aanmeldt.
