---
title: En QR-kod, varje betalningsmetod
description: De flesta dricksverktyg ger dig en kod per betalningsleverantör. Tejpa tre på ett mikrofonstativ och se folk ge upp. Här är varför live.tips håller sig till en.
slug: en-qr-kod-varje-betalningsmetod
---

Gå förbi tillräckligt många gatuspelningar och du börjar lägga märke till tejpen.
En Revolut-kod på gitarrfodralet. En MobilePay-kod på förstärkaren. Kanske en från
PayPal, med hörnen krullande, från en turné för två somrar sedan.

Var och en av de koderna är en liten vadslagning om att någon i publiken använder
just den appen. Tillsammans är de en vägg av läxor, framlagd för en person som
redan har stannat, redan har tagit fram telefonen och kanske har åtta sekunder av
välvilja kvar innan kompisen säger *kom igen*.

## Problemet är vägvalet, inte appen

Betalningsleverantörer är regionala. Revolut reser väl genom Europa. Med MobilePay
betalar finnar och danskar varandra. Swish äger Sverige. En gatumusiker i
Helsingfors som spelar för ett torg fullt av turister behöver verkligen mer än en –
den delen är inget misstag.

Misstaget är att låta publiken lösa det. Ett fan som skannar en MobilePay-kod utan
MobilePay installerat går inte och letar efter dina andra koder. De lägger undan
telefonen. Du förlorade inte dricksen för att de inte ville ge; du förlorade den
för att du räckte över ett vägval i exakt det ögonblick då de kände sig generösa.

## Vad vi gör i stället

live.tips ger dig en QR-kod, och den ändras aldrig. Slå på Stripe, Revolut och
MobilePay tillsammans, och samma kod öppnar en enda dricksida som listar varje
metod du tar emot. Fanet väljer den de redan har. Ingen skannar något två gånger.

Om du bara någonsin vill ha kortbetalningar får du aldrig se listan – den
kombinerade sidan dyker upp först när du aktiverar en andra metod. En kod, en sida,
och sidan anpassar sig efter dig i stället för efter leverantören.

Det finns en tystare fördel också. Koden på ditt fodral är nu ett permanent
föremål. Du kan skriva ut den en gång, laminera den, klistra den på locket, och den
fortsätter att fungera när du lägger till Revolut nästa vår eller släpper MobilePay
efter att du flyttat. Din scenutrustning slutar vara en funktion av din
betalningsstack.

## Vart pengarna faktiskt tar vägen

Värt att säga rakt ut, för "en sida för varje metod" är precis den mening en
plattform använder strax innan den förklarar sin avgift: kortdricks går rakt från
ditt fan till ditt eget Stripe-konto. Vi står inte mitt i det. Det finns inget
live.tips-saldo, inget utbetalningsschema, ingen andel.

Revolut- och MobilePay-flödena fungerar lite annorlunda, och det skrev vi om
separat i [så hanterar live.tips pengar](post:how-live-tips-handles-money) – värt
fem minuter om du är den sortens person som läser villkoren innan du tejpar något
på ditt gitarrfodral. Det bör du vara.

## Testa det

Öppna [appen](/app/?lang=sv), lämna Stripe i demoläge och rikta din egen telefon
mot koden den genererar. Lägg till en andra metod och skanna samma kod igen. Det är
samma kod. Det är hela funktionen.
