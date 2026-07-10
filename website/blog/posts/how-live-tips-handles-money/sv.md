---
title: Så hanterar live.tips pengar (det gör det inte)
description: Det finns inget live.tips-saldo, inget utbetalningsschema och ingen andel. Här är arkitekturen som gör de tre påståendena tråkiga i stället för modiga.
slug: sa-hanterar-live-tips-pengar
---

Vilken dricksburk som helst kan skriva "0 % avgift" på sin landningssida. Den
intressanta frågan är vad mjukvaran skulle behöva göra för att *börja* ta en andel,
och hur mycket av det du skulle kunna se.

För live.tips är svaret: den skulle behöva byggas om. Det är inte ett löfte om våra
avsikter, det är en beskrivning av vart pengarna tar vägen.

## Kortdricks passerar aldrig genom oss

När ett fan trycker på ett kortbelopp pratar deras webbläsare med `api.stripe.com`.
Inte med en live.tips-server – det finns ingen i den vägen. Betalningen skapas mot
**ditt** Stripe-konto, hamnar i **ditt** Stripe-saldo och betalas ut enligt
**ditt** Stripe-schema. Den enda avgiften är Stripes egen standardavgift för
hantering, som Stripe debiterar dig direkt, precis som om du hade integrerat Stripe
själv.

Det finns ingen liggare på vår sida, eftersom det inte finns något att bokföra. Vi
skulle inte kunna skumma av en procentsats utan att först bygga det som håller
pengarna.

## Dina nycklar förblir dina

Vid inställningen efterfrågas en *begränsad* Stripe-API-nyckel, inte en live secret
key – dem avvisar vi rakt av. Den lagras i din egen enhets nyckelring och skickas
bara någonsin till Stripe över TLS.

Begränsad betyder att nyckeln kan göra två saker: skapa
betala-vad-du-vill-drickslänken och se dricks komma in. Den kan inte läsa ditt
saldo, utlösa utbetalningar, göra återbetalningar eller röra kunddata. Om den
läckte i morgon når skadan inte längre än till en drickslänk.

## Den enda plats där en server finns

Revolut och MobilePay kan inte styras från en webbläsare på samma sätt som Stripe,
så att slå på dem aktiverar ett minimalt relä på `api.live.tips`. Det är värt att
vara exakt med vad det reläet gör, för "vi lade till en backend" är oftast där de
här berättelserna går fel.

Det lagrar din offentliga dricksside-profil – visningsnamnet och de
betalnings-handtag du valde att publicera. Mer är det inte. Det för ingen
donationshistorik, ser inga pengar, håller inga nycklar och raderar sig självt
efter 90 dagars inaktivitet. Pengarna rör sig fortfarande direkt mellan ditt fans
Revolut- eller MobilePay-app och din.

Om du bara använder Stripe kontaktas reläet aldrig alls.

## Varför du inte bör ta oss på orden

Allt ovanstående går att kontrollera. Kodbasen är MIT-licensierad och öppen, och
sajten är ett statiskt bygge som GitHub Actions distribuerar till GitHub Pages –
ingen dold infrastruktur, inget som kompileras bakom en dörr. Öppna nätverksfliken
under en demodricks och läs anropen. Det är färre än du tror.

Det är det egentliga produktlöftet. Inte att vi är att lita på, utan att du inte
behöver att vi är det.
