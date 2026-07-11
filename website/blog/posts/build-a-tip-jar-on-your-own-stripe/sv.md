---
title: Bygg en dricksburk på ditt eget Stripe-konto
description: Tre API-anrop ger dig en hostad betala-vad-du-vill-sida med Apple Pay och Google Pay — helt utan server. Här är hela bygget: den begränsade nyckeln, behörigheterna, hur du läser in dricksen utan webhook, och avgiftsmatten som ingen trycker.
slug: bygg-en-dricksburk-pa-ditt-eget-stripe-konto
---

Du vill ha en dricksburk. Du vill inte ge en plattform 5 % av en gatumusikers kväll, och du
klarar utmärkt av att prata med ett API. Frågan är alltså inte *vilken dricksburk ska jag
registrera mig hos*, utan *hur mycket måste jag egentligen bygga*.

Mindre än du tror. På Stripe är det fungerande svaret tre API-anrop: ingen server, ingen
backend, ingen webhook-endpoint. Resten av det här inlägget är just det bygget — plus de två
saker som alla gör fel.

## Tricket är ett betala-vad-du-vill-Price

Stripe har ett prisläge där fanet själv skriver in beloppet. Det heter
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want), och det är
hela funktionen. Du skapar en Product, hänger på ett Price med
`custom_unit_amount[enabled]=true` och lägger en
[Payment Link](https://docs.stripe.com/payment-links/create) ovanpå.

```sh
# 1. saken du "säljer"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. priset fanet får välja
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. sidan
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=donate
```

Det tredje anropet returnerar en `url`. Den URL:en *är* din dricksburk. Det är en sida som
Stripe hostar, alltså PCI-kompatibel utan att du tänker på det, lokaliserad, och den visar
Apple Pay eller Google Pay för varje fan vars telefon har det inställt —
[dynamiska betalmetoder](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
avgör det åt dig utifrån enhet och land. Du skrev ingen frontend.

Koda URL:en som en QR-kod med vilket bibliotek du vill — det är bara en sträng — skriv ut den,
tejpa den på fodralet. Koden går aldrig ut, och den pekar inte på någon server av ditt slag,
eftersom du inte har någon.

Två flaggor värda att känna till:

- **`custom_unit_amount[preset]`** är beloppet sidan öppnar på. `500` betyder att fanet ser 5,00 €
  redan ifyllt och kan ändra det. Den siffran gör mer för din genomsnittliga dricks än något annat
  på sidan.
- **`custom_unit_amount[minimum]`** är ett golv. Sätt ett. Skälet står i avgiftsavsnittet nedan, och
  det är inte ett avrundningsfel.

Du kan också samla in namn och meddelande. Payment Links tar upp till tre `custom_fields` — så får du
"vem var det från?" på sidan utan att bygga ett formulär:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Ditt namn eller smeknamn" \
  -d "custom_fields[0][optional]"=true
```

Stripe har [krav för att ta emot dricks och donationer](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
läs dem en gång. Betala-vad-du-vill går inte heller att kombinera med andra line items, rabatter eller
återkommande betalningar. För en dricksburk biter inget av det.

## Nyckeln: anta att den läcker, och gör det tråkigt

Lägg inte en hemlig nyckel (`sk_live_…`) på en enhet som står på en scen. Använd en
[begränsad nyckel](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): du väljer en
behörighet per resurs, och allt du inte valde står på **None**.

För bygget ovan är hela listan fem rader:

| Resurs | Behörighet | Vad det ger dig |
| --- | --- | --- |
| Products | Write | skapa Product |
| Prices | Write | skapa betala-vad-du-vill-Price |
| Payment Links | Write | skapa länken |
| Checkout Sessions | Read | se dricksen som kommit in |
| Events | Read | liveflödet (nästa avsnitt) |

Allt annat — Balance, Payouts, Refunds, Customers, PaymentIntents, hela Connect — stannar på **None**.

Gör nu övningen som gör det här värt besväret. Din platta blir stulen från merch-bordet klockan ett på
natten. Vad kan tjuven göra med nyckeln i dess keychain? Läsa din dricks-historik och skapa fler
dricks-länkar i ditt konto. Det är hela sprängradien. Hen ser inte ditt saldo, kan inte utlösa en
utbetalning, kan inte göra en återbetalning till ett kort hen styr, kan inte läsa en kundlista. Du
återkallar nyckeln från en telefon i taxin hem och enheten slocknar. Ingenting av dina pengar har rört sig.

Den asymmetrin — skrivrättighet till dricksburken, noll åtkomst till pengarna — är det enda skälet till att
en serverlös, ta-med-din-egen-nyckel-design över huvud taget går att försvara. Den är också skälet till att
"Login with Stripe" inte är svaret här: OAuth kräver en server som apputvecklaren äger för att hålla din
token — och en server är precis det vi inte bygger.

(En egenhet du kommer att stöta på: behörigheten *Prices* heter internt `plan_write`, så Stripes felmeddelande
namnger en scope som inte finns under det namnet i dashboarden. Det är Prices.)

## Läsa in dricks utan webhook

Här slutar de flesta genomgångar, eller så griper de efter en webhook — och här skiljer sig en scen faktiskt
från en webbapp.

En webhook är en inkommande HTTP-förfrågan. En platta bakom ett mikrofonstativ kan inte ta emot en. Den sitter
på en lokals gäst-wifi bakom NAT, har ingen publik adress, inget TLS-certifikat — och har inget där att göra.
Tar du webhook-vägen måste du sätta upp en server som fångar händelserna och en socket som knuffar dem till
enheten: en backend, en driftsbörda, och en plats där dina fans namn nu bor. Du har just byggt om plattformen du
försökte undvika.

Dra alltså, i stället för att bli knuffad. Stripes endpoint
[List all events](https://docs.stripe.com/api/events/list) är publik, dokumenterad och returnerar händelser med
nyast först:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_DEN_SENASTE_JAG_SAG \
  -d limit=100
```

`ending_before` är hela designen. Behåll id:t för den senaste händelsen du behandlat; varje pollning ber om allt
som är strikt nyare, och du flyttar fram markören. Inga tidsstämplar, ingen klockdrift, ingen dedupliering på
belopp. Vid setets första pollning ber du om `limit=1` utan markör för att förankra dig i det som redan finns, så
att du inte spelar upp morgonens dricks under soundchecken.

Filtrera sedan det som kommer tillbaka. Båda händelsetyperna kan avfyras för en och samma betalning, så deduplicera
på Checkout Session-id. Kontrollera `payment_status == "paid"` — en avslutad session är inte nödvändigtvis betald.
Och kontrollera att `payment_link` matchar *din* länk, för `/v1/events` gäller hela kontot och räcker dig gärna
trafiken från allt annat det Stripe-kontot gör.

Var ärlig med avvägningarna, för de är verkliga:

- **Stripe rekommenderar webhooks.** Pollning är inte den välsignade vägen; det är en dokumenterad endpoint som
  används medvetet. Skriv det i din README och gå vidare.
- **Händelser går 30 dagar bakåt.** [Stripes egna ord](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Det här är ett liveflöde, inte din huvudbok. Din huvudbok är Checkout
  Sessions — och den riktiga är Stripe-dashboarden.
- **Håll koll på läskvoten.** Alla tittar på gränsen per sekund
  ([rate limits](https://docs.stripe.com/rate-limits): 100 req/s i live) och ingen på den andra: Stripe tilldelar
  ungefär **500 läsförfrågningar per transaktion** över rullande 30 dagar, med ett golv på 10 000 läsningar i
  månaden. Polla var 4:e sekund och ett tretimmarsset blir ~2 700 läsningar. Fyra långa spelningar på en månad och
  du ligger på golvet. Dricks köper dig utrymme allteftersom den kommer in — men den som pollar varje sekund för att
  det kändes piggare kommer att hitta taket. Fyra sekunder är ingen lat siffra; det *är* siffran.

Så ser det ärligt ut: pollning kostar dig några tusen GET:ar och köper dig att hela backenden kan strykas.

## Avgiftsmatten, ordentligt gjord

En plattform som gör reklam för 0 % är inte gratis, och det här är det inte heller. Stripes egen behandlingsavgift
gäller varje dricks, och Stripe debiterar dig den direkt. Enligt [Stripes europriser](https://stripe.com/ie/pricing)
kostar ett standardkort från EES i dag **1,5 % + 0,25 €**. Premiumkort från EES 1,9 % + 0,25 €, brittiska kort 2,5 % +
0,25 €, och allt annat 3,25 % + 0,25 € plus ytterligare 2 % om en valuta måste växlas. (I USA är det 2,9 % + 0,30 $,
vilket är sämre av exakt skälet nedan.)

Procenten är inte problemet. De tjugofem centen är problemet.

| Dricks | Stripe tar | Artisten behåller | Effektivt avdrag |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

En fast avgift är en procentsats i förklädnad, och på små pengar glider förklädnaden av. Samma 0,25 € som är osynliga
på en dricks om 50 € äter en åttondel av en om 2 €. Dricks är liten till sin natur — det är det som gör den till
dricks — så det här är inte ett kantfall, det är medianfallet.

Det är just därför du sätter `custom_unit_amount[minimum]`. Någonstans kring 2 € upphör transaktionen att vara värd att
behandla; en kortdricks på 0,50 € skulle komma fram som 0,24 € och kosta Stripe mer att flytta än den är värd. Välj ditt
golv medvetet i stället för att upptäcka det vid din första utbetalning.

Och lägg märke till vad detta gör med jämförelsen du började med. En plattform som tar 0 % ovanpå Stripe tar 0 % ovanpå
**det här**. Deras 0 % är verkliga — och det är 0 % av vad betalväxeln lämnade kvar. Ingens kortspår är gratis: den ärliga
utsagan är "inget avdrag utöver betalväxelns", och den som påstår mer ljuger eller använder inte kort.

## Vad du har nu, och vad du inte har

Tre API-anrop och en QR-kod — och en riktig dricksburk: hostad, PCI-kompatibel, Apple Pay, Google Pay, dricks som landar på
ditt eget Stripe-saldo enligt ditt eget utbetalningsschema, och ingen server i vägen. För många är det uppriktigt sagt
projektets slut, och du får gärna stanna här och släppa det.

Det du inte har är en scen. Du har en betalsida. Mellan dem står det tråkiga: pollningsloopen med sin markör och sin backoff;
en skärm som publiken kan se, med målet och det senaste meddelandet; en plats för nyckeln som inte heter `localStorage`; ett
lås så att en främling inte petar på plattan mellan seten; och lagret av tusen små beslut om vad som händer när lokalens wifi
faller mitt i setet.

Det är vad [live.tips](https://github.com/mekedron/live.tips) är — exakt den här arkitekturen, färdigbyggd, MIT-licensierad.
Den begränsade nyckeln med de fem behörigheterna, markörloopen mot `/v1/events`, skapandet av Product/Price/Payment Link —
allt körs på artistens enhet mot artistens eget konto. Det finns ingen live.tips-server i Stripe-vägen och inget
live.tips-saldo någonstans, vilket vi skrev om separat i
[hur live.tips hanterar pengar](post:how-live-tips-handles-money).

Läs källkoden, plocka de delar du vill ha, eller använd den bara. Poängen med det här inlägget är att arkitekturen varken är
en hemlighet eller svår: **Stripe hostar din dricksburk gratis, och en begränsad nyckel plus en pollningsloop är allt som står
mellan en artist och hens egna pengar.** Vi vill hellre att du vet det än att du registrerar dig någonstans.
