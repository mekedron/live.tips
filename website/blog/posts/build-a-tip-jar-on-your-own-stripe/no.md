---
title: Bygg en tipskrukke på din egen Stripe-konto
description: Tre API-kall gir deg en hostet betal-hva-du-vil-side med Apple Pay og Google Pay — helt uten server. Her er hele byggingen: den begrensede nøkkelen, tillatelsene, hvordan du leser inn tips uten webhook, og gebyrregnestykket ingen trykker.
slug: bygg-en-tipskrukke-pa-din-egen-stripe-konto
---

Du vil ha en tipskrukke. Du vil ikke gi en plattform 5 % av kvelden til en gatemusiker, og du
klarer utmerket godt å snakke med et API. Spørsmålet er derfor ikke *hvilken tipskrukke skal
jeg melde meg på*, men *hvor mye må jeg egentlig bygge*.

Mindre enn du tror. På Stripe er det fungerende svaret tre API-kall: ingen server, ingen backend,
ingen webhook-endepunkt. Resten av dette innlegget er nettopp den byggingen — pluss de to tingene
alle gjør feil.

## Trikset er en betal-hva-du-vil-Price

Stripe har en prismodus der fanen selv taster inn beløpet. Den heter
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want), og det er hele
funksjonen. Du oppretter et Product, henger på en Price med
`custom_unit_amount[enabled]=true`, og over det en
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. tingen du "selger"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. prisen fanen får velge
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

Det tredje kallet returnerer en `url`. Den URL-en *er* tipskrukka di. Det er en side Stripe hoster,
altså PCI-kompatibel uten at du tenker på det, lokalisert, og den viser Apple Pay eller Google Pay til
enhver fan som har det satt opp på telefonen —
[dynamiske betalingsmetoder](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
avgjør det for deg ut fra enhet og land. Du har ikke skrevet noe frontend.

Kod URL-en som en QR-kode med hvilket bibliotek du vil — det er bare en streng — skriv den ut, tape den
på kassa. Koden går aldri ut, og den peker ikke på noen server av ditt slag, for du har ingen.

To parametre det er verdt å kjenne:

- **`custom_unit_amount[preset]`** er beløpet siden åpner med. `500` betyr at fanen ser 5,00 € allerede
  fylt inn og kan endre det. Det tallet gjør mer for gjennomsnittstipset ditt enn noe annet på siden.
- **`custom_unit_amount[minimum]`** er et gulv. Sett et. Grunnen står i gebyrdelen nedenfor, og det er ikke
  en avrundingsfeil.

Du kan også samle inn navn og melding. Payment Links tar opptil tre `custom_fields` — slik får du «hvem var
det fra?» på siden uten å bygge et skjema:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Navnet eller kallenavnet ditt" \
  -d "custom_fields[0][optional]"=true
```

Stripe har [krav for å ta imot tips og donasjoner](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
les dem én gang. Betal-hva-du-vil lar seg heller ikke kombinere med andre line items, rabatter eller
gjentakende betalinger. For en tipskrukke biter ingenting av det.

## Nøkkelen: gå ut fra at den lekker — og gjør det kjedelig

Ikke legg en hemmelig nøkkel (`sk_live_…`) på en enhet som står på en scene. Bruk en
[begrenset nøkkel](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): du velger én tillatelse
per ressurs, og alt du ikke velger, står på **None**.

For byggingen over er hele lista fem rader:

| Ressurs | Tillatelse | Hva den gir deg |
| --- | --- | --- |
| Products | Write | opprette Product |
| Prices | Write | opprette betal-hva-du-vil-Price |
| Payment Links | Write | opprette lenka |
| Checkout Sessions | Read | se tipsene som har kommet inn |
| Events | Read | livefeeden (neste del) |

Alt annet — Balance, Payouts, Refunds, Customers, PaymentIntents, hele Connect — blir stående på **None**.

Gjør nå øvelsen som gjør dette verdt bryet. Nettbrettet ditt blir stjålet fra merch-bordet klokka ett om natta.
Hva kan tyven med nøkkelen i keychainen? Lese tipshistorikken din og opprette flere tipslenker i kontoen din. Det
er hele sprengradiusen. Vedkommende ser ikke saldoen din, kan ikke utløse en utbetaling, kan ikke sende en refusjon
til et kort hun styrer, kan ikke lese en kundeliste. Du trekker tilbake nøkkelen fra telefonen i drosja hjem, og
enheten går i svart. Ingenting av pengene dine har rørt seg.

Den asymmetrien — skrivetilgang til tipskrukka, null tilgang til pengene — er den eneste grunnen til at en serverløs
ta-med-din-egen-nøkkel-design i det hele tatt lar seg forsvare. Den er også grunnen til at «Login with Stripe» ikke er
svaret her: OAuth krever en server som app-utvikleren eier for å holde tokenet ditt — og en server er nettopp det vi
ikke bygger.

(En finurlighet du kommer til å møte: tillatelsen *Prices* heter internt `plan_write`, så Stripes feilmelding navngir
et scope som ikke finnes under det navnet i dashbordet. Det er Prices.)

## Å lese inn tips uten webhook

Her stopper de fleste gjennomgangene, eller så griper de etter en webhook — og her skiller en scene seg virkelig fra
en webapp.

En webhook er en innkommende HTTP-forespørsel. Et nettbrett bak et mikrofonstativ kan ikke ta imot en. Det henger på
gjeste-wifien til et lokale bak NAT, har ingen offentlig adresse, intet TLS-sertifikat — og har ingen grunn til å ha
det. Velger du webhook-veien, må du sette opp en server som fanger hendelsene og en socket som dytter dem til enheten:
en backend, en driftsbyrde, og et sted der navnene på fansen dine nå bor. Du har nettopp bygget opp igjen plattformen
du prøvde å unngå.

Så trekk, i stedet for å bli dyttet. Stripes endepunkt
[List all events](https://docs.stripe.com/api/events/list) er offentlig, dokumentert og returnerer hendelser med de
nyeste først:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_DEN_SISTE_JEG_SAA \
  -d limit=100
```

`ending_before` er hele designet. Behold id-en til den nyeste hendelsen du har behandlet; hver polling ber om alt som er
strengt nyere, og du flytter markøren fram. Ingen tidsstempler, ingen klokkeavvik, ingen deduplisering på beløp. Ved
settets første polling ber du om `limit=1` uten markør for å forankre deg i det som allerede finnes — ellers spiller du
av morgenens tips under lydprøven.

Filtrer så det som kommer tilbake. Begge hendelsestypene kan utløses for én betaling, så dedupliser på Checkout
Session-id-en. Sjekk `payment_status == "paid"` — en fullført økt er ikke nødvendigvis betalt. Og sjekk at `payment_link`
stemmer med *din* lenke, for `/v1/events` gjelder hele kontoen og rekker deg gladelig trafikken fra alt annet den
Stripe-kontoen driver med.

Vær ærlig om avveiningene, for de er reelle:

- **Stripe anbefaler webhooks.** Polling er ikke den velsignede veien; det er et dokumentert endepunkt brukt bevisst.
  Skriv det i README-en din og gå videre.
- **Hendelser går 30 dager tilbake.** [Stripes egne ord](https://docs.stripe.com/api/events/list):
  *«List events, going back up to 30 days.»* Dette er en livefeed, ikke hovedboka di. Hovedboka di er Checkout Sessions
  — og den ekte er Stripe-dashbordet.
- **Følg med på lesekvoten.** Alle ser på grensen per sekund
  ([rate limits](https://docs.stripe.com/rate-limits): 100 forespørsler/s i live) og ingen på den andre: Stripe tildeler
  omtrent **500 leseforespørsler per transaksjon** over rullende 30 dager, med et gulv på 10 000 lesninger i måneden.
  Poll hvert 4. sekund, og et tre timers sett blir ~2 700 lesninger. Fire lange jobber i måneden, og du ligger på gulvet.
  Tips kjøper deg luft etter hvert som de kommer inn — men den som poller hvert sekund fordi det føltes kjappere, finner
  taket. Fire sekunder er ikke et lat tall; det *er* tallet.

Slik ser det ærlig ut: polling koster deg et par tusen GET-er og kjøper deg slettingen av en hel backend.

## Gebyrregnestykket, gjort ordentlig

En plattform som reklamerer med 0 %, er ikke gratis — og dette er det heller ikke. Stripes eget behandlingsgebyr gjelder
hvert eneste tips, og Stripe fakturerer det direkte til deg. I dag koster et standardkort fra EØS ifølge
[Stripes europriser](https://stripe.com/ie/pricing) **1,5 % + 0,25 €**. Premiumkort fra EØS 1,9 % + 0,25 €, britiske kort
2,5 % + 0,25 €, og alt annet 3,25 % + 0,25 € pluss ytterligere 2 % dersom en valuta må veksles. (I USA er det 2,9 % + 0,30 $,
noe som er verre av nøyaktig grunnen nedenfor.)

Prosenten er ikke problemet. De tjuefem centene er problemet.

| Tips | Stripe tar | Artisten beholder | Reelt kutt |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Et fast gebyr er en prosentsats i forkledning, og på små penger sklir forkledningen av. De samme 0,25 € som er usynlige på et
tips på 50 €, spiser en åttendedel av et på 2 €. Tips er små av natur — det er det som gjør dem til tips — så dette er ikke et
ytterkanttilfelle, det er medianen.

Nettopp derfor setter du `custom_unit_amount[minimum]`. Et sted rundt 2 € slutter transaksjonen å være verdt å behandle; et
korttips på 0,50 € ville landet som 0,24 € og kostet Stripe mer å flytte enn det er verdt. Velg gulvet ditt bevisst, i stedet for
å oppdage det ved den første utbetalingen din.

Og legg merke til hva dette gjør med sammenligningen du startet med. En plattform som tar 0 % oppå Stripe, tar 0 % oppå **dette**.
Deres 0 % er ekte — og det er 0 % av det betalingsbehandleren lot være igjen. Ingen sitt kortspor er gratis: den ærlige påstanden
er «ingen kutt utover behandlerens», og den som hevder mer, lyver eller bruker ikke kort.

## Hva du har nå, og hva du ikke har

Tre API-kall og en QR-kode — og en ekte tipskrukke: hostet, PCI-kompatibel, Apple Pay, Google Pay, tips som lander på din egen
Stripe-saldo etter din egen utbetalingsplan, og ingen server i veien. For mange er dette oppriktig talt slutten på prosjektet, og du
står helt fritt til å stoppe her og sende det ut.

Det du ikke har, er en scene. Du har en betalingsside. Mellom dem står de kjedelige tingene: polling-løkka med markøren og backoffen
sin; en skjerm publikum kan se, med målet og den siste meldinga; et sted til nøkkelen som ikke heter `localStorage`; en lås så en
fremmed ikke tukler med nettbrettet mellom settene; og laget av tusen små avgjørelser om hva som skjer når lokalets wifi ryker midt
i settet.

Det er hva [live.tips](https://github.com/mekedron/live.tips) er — nøyaktig denne arkitekturen, ferdigbygd, MIT-lisensiert. Den
begrensede nøkkelen med de fem tillatelsene, markør-løkka mot `/v1/events`, opprettelsen av Product/Price/Payment Link — alt kjører på
artistens enhet, mot artistens egen konto. Det finnes ingen live.tips-server i Stripe-veien og ingen live.tips-saldo noe sted, noe vi
skrev om separat i [hvordan live.tips håndterer penger](post:how-live-tips-handles-money).

Les kildekoden, plukk delene du vil ha, eller bare bruk den. Poenget med dette innlegget er at arkitekturen verken er en hemmelighet
eller vanskelig: **Stripe hoster tipskrukka di gratis, og en begrenset nøkkel pluss en polling-løkke er alt som står mellom en artist
og hennes egne penger.** Vi vil heller at du vet det enn at du melder deg på noe som helst.
