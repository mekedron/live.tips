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

## Pengar passerar aldrig genom oss

När ett fan trycker på ett kortbelopp skapas betalningen mot **ditt** Stripe-konto,
hamnar i **ditt** Stripe-saldo och betalas ut enligt **ditt** Stripe-schema. Den
enda avgiften är Stripes egen standardavgift för hantering, som Stripe debiterar dig
direkt, precis som om du hade integrerat Stripe själv.

Det finns ingen liggare på vår sida, eftersom det inte finns något att bokföra. Vi
skulle inte kunna skumma av en procentsats utan att först bygga det som håller
pengarna – och något sådant finns inte.

Det gäller vare sig du loggar in eller inte. Vad inloggningen ändrar är *data*vägen,
inte pengavägen, och de två nästa avsnitten är ärliga om exakt hur.

## Dina nycklar, och var de bor

Vid inställningen efterfrågas en *begränsad* Stripe-API-nyckel, inte en live secret
key – dem avvisar vi rakt av. Begränsad betyder att nyckeln kan göra två saker: skapa
betala-vad-du-vill-drickslänken och se dricks komma in. Den kan inte läsa ditt
saldo, utlösa utbetalningar, göra återbetalningar eller röra kunddata. Om den
läckte i morgon når skadan inte längre än till en drickslänk.

**Utan konto lämnar den nyckeln aldrig din enhet.** Den ligger i enhetens egen
nyckelring och skickas bara någonsin till `api.stripe.com` över TLS. Ingen
live.tips-server är med i bilden alls.

**Loggar du in flyttas nyckeln till oss** – eftersom en nyckel som bara finns på en
telefon inte kan betjäna plattan på scenen också. Vi krypterar den (en AES-256-nyckel
per hemlighet, som i sin tur omsluts av Google Cloud KMS) och lagrar den där ingenting
kan läsa tillbaka den: inte ett annat konto, inte vi med en blick i en databas, inte
ens du. Den låses upp bara inuti våra funktioner, används för att prata med Stripe å
dina vägnar, och lämnas aldrig till en enhet igen. Sagt rakt ut: att logga in sätter
en live.tips-server i vägen mellan Stripe och din dricks-historik. Aldrig pengarna –
datan.

## Servrarna, och vad de inte kan göra

Det finns två, och båda är minimala.

**Reläet** finns eftersom Revolut och MobilePay inte kan styras från en webbläsare på
samma sätt som Stripe. Att slå på dem aktiverar en handfull Firebase-funktioner som
serverar din dricks-sida på `tip.live.tips`. Det lagrar din offentliga
dricksside-profil – visningsnamnet och de betalnings-handtag du valde att publicera –
och, för en sida utan konto bakom sig, för det ingen dricks-historik: en dricks väntar
bara tills din scenenhet visar den, och det ingen kom tillbaka efter sopas bort inom en
timme. Det ser inga pengar och raderar sig självt efter 90 dagars inaktivitet. Om du
bara använder Stripe och aldrig loggar in kontaktas reläet aldrig alls.

**Webhooken** finns bara när du väl loggat in. Eftersom din nyckel nu bor hos oss
rapporterar Stripe varje dricks till en liten funktion hos oss, som skriver in den i
din egen historik så att dina andra enheter kan visa den. Det är en kopia av en
händelse, inte en kopia av pengarna. Den kan inte flytta ett öre, och den kan aldrig
skriva till annat än det enda konto den tillhör.

Ingen av servrarna kan ta en andel, för ingen av dem är i närheten av pengarna. Det
mesta någon av dem kan göra är att fallera – och en uppsättning med enbart Stripe och
utan konto är inte beroende av någon av dem.

## Kontot du inte behöver skapa

Appen startar fortfarande upp i en enhetslokal profil, vilket är precis vad den
alltid har varit: din dricksburk, din nyckel och din dricks-historik bor på enheten
och ingen annanstans. Det finns inget att registrera sig för.

Att logga in – med Apple, med Google eller som gäst – går nu, och det finns av ett
enda skäl: en andra enhet. Ska plattan på scenen och telefonen i fickan visa samma
kväll måste något sitta emellan dem, och det något är Firestore, under ett
användar-id som bara du kan läsa. Dina band, inställningar, dricks-historik – och,
krypterad enligt ovan, din Stripe-nyckel – bor där. Det är en verklig förändring i
integritetsberättelsen, och den förtjänar att sägas rakt ut i stället för att
upptäckas i efterhand: utan konto ser ingen server någonsin en dricks; med konto
gör din egen vrå av vår det, och det är vår webhook som skriver in den där. Det är
priset för den andra enheten, och det är ditt att betala eller tacka nej till. Vad
det aldrig rör är pengarna – ett konto flyttar dina data, inte ditt saldo, och vi
tar fortfarande ingen andel.

## Varför du inte bör ta oss på orden

Allt ovanstående går att kontrollera. Kodbasen är MIT-licensierad och öppen, och
sajten är ett statiskt bygge som GitHub Actions distribuerar till GitHub Pages –
ingen dold infrastruktur, inget som kompileras bakom en dörr. Öppna nätverksfliken
under en demodricks och läs anropen. Det är färre än du tror.

Det är det egentliga produktlöftet. Inte att vi är att lita på, utan att du inte
behöver att vi är det.
