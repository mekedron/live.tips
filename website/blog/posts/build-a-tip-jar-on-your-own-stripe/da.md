---
title: Byg en drikkepengekrukke på din egen Stripe-konto
description: Tre API-kald giver dig en hostet betal-hvad-du-vil-side med Apple Pay og Google Pay — helt uden server. Her er hele byggeriet: den begrænsede nøgle, tilladelserne, hvordan du læser drikkepenge ind uden webhook, og den gebyrregning, ingen trykker.
slug: byg-en-drikkepengekrukke-pa-din-egen-stripe-konto
---

Du vil have en drikkepengekrukke. Du vil ikke give en platform 5 % af en gademusikers aften,
og du kan sagtens finde ud af at tale med et API. Spørgsmålet er derfor ikke *hvilken
drikkepengekrukke skal jeg melde mig til*, men *hvor meget skal jeg egentlig bygge*.

Mindre, end du tror. På Stripe er det virkende svar tre API-kald: ingen server, ingen backend,
intet webhook-endpoint. Resten af dette indlæg er netop det byggeri — plus de to ting, alle
gør forkert.

## Tricket er et betal-hvad-du-vil-Price

Stripe har en pristilstand, hvor fanen selv taster beløbet. Den hedder
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want), og det er hele
funktionen. Du opretter et Product, hænger et Price på det med
`custom_unit_amount[enabled]=true`, og oven på det et
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. tingen du "sælger"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. prisen fanen selv vælger
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. siden
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=donate
```

Det tredje kald returnerer en `url`. Den URL *er* din drikkepengekrukke. Det er en side, Stripe
hoster, altså PCI-compliant uden at du tænker over det, lokaliseret, og den viser Apple Pay eller
Google Pay til enhver fan, hvis telefon har det sat op —
[dynamiske betalingsmetoder](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
afgør det for dig ud fra enhed og land. Du har ikke skrevet nogen frontend.

Kod URL'en som en QR-kode med det bibliotek, du har lyst til — det er bare en streng — print den,
tape den på kassen. Koden udløber aldrig, og den peger ikke på nogen server af din, for du har ingen.

To parametre, der er værd at kende:

- **`custom_unit_amount[preset]`** er det beløb, siden åbner på. `500` betyder, at fanen ser 5,00 €
  allerede udfyldt og kan ændre det. Det tal gør mere for din gennemsnitlige drikkeskilling end noget
  andet på siden.
- **`custom_unit_amount[minimum]`** er et gulv. Sæt et. Grunden står i gebyrafsnittet nedenfor, og det
  er ikke en afrundingsfejl.

Du kan også indsamle et navn og en besked. Payment Links tager op til tre `custom_fields` — sådan får du
"hvem var den nu fra?" på siden uden at bygge en formular:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Dit navn eller kaldenavn" \
  -d "custom_fields[0][optional]"=true
```

Stripe har [krav til at modtage drikkepenge og donationer](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
læs dem én gang. Betal-hvad-du-vil kan heller ikke kombineres med andre line items, rabatter eller
tilbagevendende betalinger. For en drikkepengekrukke bider intet af det.

## Nøglen: gå ud fra, at den lækker — og gør det kedeligt

Læg ikke en hemmelig nøgle (`sk_live_…`) på en enhed, der står på en scene. Brug en
[begrænset nøgle](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): du vælger en tilladelse
pr. ressource, og alt, du ikke vælger, står på **None**.

For byggeriet ovenfor er hele listen fem rækker:

| Ressource | Tilladelse | Hvad den giver dig |
| --- | --- | --- |
| Products | Write | oprette Product |
| Prices | Write | oprette betal-hvad-du-vil-Price |
| Payment Links | Write | oprette linket |
| Checkout Sessions | Read | se de drikkepenge, der er kommet ind |
| Events | Read | live-feedet (næste afsnit) |

Alt andet — Balance, Payouts, Refunds, Customers, PaymentIntents, hele Connect — bliver på **None**.

Lav nu øvelsen, der gør det hele umagen værd. Din tablet bliver hugget fra merch-bordet klokken et om
natten. Hvad kan tyven med nøglen i dens keychain? Læse din drikkepengehistorik og oprette flere
drikkepengelinks i din konto. Det er hele sprængradius. Vedkommende ser ikke din saldo, kan ikke udløse
en udbetaling, kan ikke sende en refusion til et kort, hun styrer, kan ikke læse en kundeliste. Du
tilbagekalder nøglen fra en telefon i taxaen hjem, og enheden går i sort. Intet af dine penge har rørt sig.

Den asymmetri — skriveadgang til drikkepengekrukken, nul adgang til pengene — er den eneste grund til, at
et serverløst design med din egen nøgle overhovedet kan forsvares. Det er også grunden til, at "Login with
Stripe" ikke er svaret her: OAuth kræver en server, som app-udvikleren ejer, til at holde dit token — og en
server er præcis det, vi ikke bygger.

(En finurlighed, du støder på: tilladelsen *Prices* hedder internt `plan_write`, så Stripes fejlbesked nævner
en scope, der ikke findes under det navn i dashboardet. Det er Prices.)

## At læse drikkepenge ind uden webhook

Her stopper de fleste gennemgange, eller også griber de fat i en webhook — og her adskiller en scene sig
virkelig fra en webapp.

En webhook er en indgående HTTP-forespørgsel. En tablet bag et mikrofonstativ kan ikke modtage en. Den hænger
på et spillesteds gæste-wifi bag NAT, har ingen offentlig adresse, intet TLS-certifikat — og har ingen grund
til at have det. Vælger du webhook-vejen, skal du sætte en server op, der fanger begivenhederne, og en socket,
der skubber dem til enheden: en backend, en driftsbyrde og et sted, hvor dine fans' navne nu bor. Du har lige
genopbygget den platform, du prøvede at undgå.

Så træk i stedet for at blive skubbet. Stripes endpoint
[List all events](https://docs.stripe.com/api/events/list) er offentligt, dokumenteret og returnerer
begivenheder med de nyeste først:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_DEN_SIDSTE_JEG_SAA \
  -d limit=100
```

`ending_before` er hele designet. Gem id'et på den nyeste begivenhed, du har behandlet; hvert poll beder om alt,
der er strengt nyere, og du rykker markøren frem. Ingen tidsstempler, ingen ur-afdrift, ingen deduplikering på
beløb. Ved sættets første poll beder du om `limit=1` uden markør for at forankre dig i det, der allerede er — så
du ikke afspiller morgenens drikkepenge under lydprøven.

Filtrér så det, der kommer tilbage. Begge begivenhedstyper kan udløses for én betaling, så deduplikér på Checkout
Session-id'et. Tjek `payment_status == "paid"` — en gennemført session er ikke nødvendigvis betalt. Og tjek, at
`payment_link` matcher *dit* link, for `/v1/events` gælder hele kontoen og rækker dig gladeligt trafikken fra alt
andet, den Stripe-konto laver.

Vær ærlig om afvejningerne, for de er reelle:

- **Stripe anbefaler webhooks.** Polling er ikke den velsignede vej; det er et dokumenteret endpoint, brugt bevidst.
  Skriv det i din README, og kør videre.
- **Begivenheder går 30 dage tilbage.** [Stripes egne ord](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Det her er et live-feed, ikke din hovedbog. Din hovedbog er Checkout
  Sessions — og den rigtige er Stripe-dashboardet.
- **Hold øje med læsekvoten.** Alle kigger på grænsen pr. sekund
  ([rate limits](https://docs.stripe.com/rate-limits): 100 req/s i live), og ingen på den anden: Stripe tildeler
  omkring **500 læseforespørgsler pr. transaktion** over rullende 30 dage, med et gulv på 10.000 læsninger om
  måneden. Poll hvert 4. sekund, og et tre timers sæt bliver ~2.700 læsninger. Fire lange jobs på en måned, og du
  ligger på gulvet. Drikkepenge køber dig luft, efterhånden som de lander — men den, der poller hvert sekund, fordi
  det føltes kvikkere, finder loftet. Fire sekunder er ikke et dovent tal; det *er* tallet.

Sådan ser det ærligt ud: polling koster dig et par tusind GET'er og køber dig sletningen af en hel backend.

## Gebyrregningen, gjort ordentligt

En platform, der reklamerer med 0 %, er ikke gratis — og det er det her heller ikke. Stripes eget behandlingsgebyr
gælder hver eneste drikkeskilling, og Stripe opkræver det direkte hos dig. I dag koster et standardkort fra EØS ifølge
[Stripes europriser](https://stripe.com/ie/pricing) **1,5 % + 0,25 €**. Premiumkort fra EØS 1,9 % + 0,25 €, britiske
kort 2,5 % + 0,25 €, og alt andet 3,25 % + 0,25 € plus yderligere 2 %, hvis der skal veksles valuta. (I USA er det
2,9 % + 0,30 $, hvilket er værre af præcis den grund, der følger.)

Procenten er ikke problemet. De femogtyve cent er problemet.

| Drikkepenge | Stripe tager | Kunstneren beholder | Reelt fradrag |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Et fast gebyr er en procentsats i forklædning, og på små beløb glider forklædningen af. De samme 0,25 €, der er usynlige
på en drikkeskilling på 50 €, æder en ottendedel af en på 2 €. Drikkepenge er små af natur — det er det, der gør dem til
drikkepenge — så det her er ikke et randtilfælde, det er medianen.

Derfor sætter du `custom_unit_amount[minimum]`. Et sted omkring 2 € holder transaktionen op med at være værd at behandle;
en kortdrikkeskilling på 0,50 € ville lande som 0,24 € og koste Stripe mere at flytte, end den er værd. Vælg dit gulv
bevidst i stedet for at opdage det ved din første udbetaling.

Og læg mærke til, hvad det gør ved den sammenligning, du startede med. En platform, der tager 0 % oven på Stripe, tager 0 %
oven på **det her**. Deres 0 % er ægte — og det er 0 % af det, betalingsbehandleren har levnet. Ingens kortskinne er gratis:
den ærlige påstand er "intet fradrag ud over behandlerens", og den, der påstår mere, lyver eller bruger ikke kort.

## Hvad du har nu, og hvad du ikke har

Tre API-kald og en QR-kode — og en rigtig drikkepengekrukke: hostet, PCI-compliant, Apple Pay, Google Pay, drikkepenge, der
lander på din egen Stripe-saldo efter din egen udbetalingsplan, og ingen server på vejen. For mange er det oprigtigt talt
projektets afslutning, og du må gerne stoppe her og sende det ud.

Det, du ikke har, er en scene. Du har en betalingsside. Mellem dem står de kedelige ting: poll-løkken med sin markør og sin
backoff; en skærm, publikum kan se, med målet og den seneste besked; et sted til nøglen, der ikke hedder `localStorage`; en
lås, så en fremmed ikke roder med tabletten mellem sættene; og laget af tusind små beslutninger om, hvad der sker, når
spillestedets wifi ryger midt i sættet.

Det er, hvad [live.tips](https://github.com/mekedron/live.tips) er — præcis denne arkitektur, færdigbygget, MIT-licenseret.
Den begrænsede nøgle med de fem tilladelser, markør-løkken mod `/v1/events`, oprettelsen af Product/Price/Payment Link — det
hele kører på kunstnerens enhed mod kunstnerens egen konto. Der er ingen live.tips-server i Stripe-vejen og ingen
live.tips-saldo noget sted, hvilket vi skrev om særskilt i
[hvordan live.tips håndterer penge](post:how-live-tips-handles-money).

Læs koden, tag de dele, du vil have, eller brug den bare. Pointen med dette indlæg er, at arkitekturen hverken er en hemmelighed
eller svær: **Stripe hoster din drikkepengekrukke gratis, og en begrænset nøgle plus en poll-løkke er alt, hvad der står mellem
en kunstner og hendes egne penge.** Vi vil hellere have, at du ved det, end at du melder dig til noget som helst.
