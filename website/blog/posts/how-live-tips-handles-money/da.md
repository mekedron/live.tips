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

## Penge passerer aldrig gennem os

Når et fan trykker på et kortbeløb, oprettes betalingen på **din** Stripe-konto,
lander i **din** Stripe-saldo og udbetales efter **din** Stripe-plan. Det eneste
gebyr er Stripes eget standardgebyr for behandling, som Stripe opkræver dig direkte,
præcis som hvis du selv havde integreret Stripe.

Der er ingen kassebog hos os, fordi der ikke er noget at bogføre. Vi kunne ikke
skumme en procentdel af uden først at bygge det, der holder pengene – og det findes
ikke.

Det gælder, uanset om du logger ind eller ej. Det, som det at logge ind ændrer, er
*data*-vejen, ikke penge-vejen, og de næste to afsnit er ærlige om præcis hvordan.

## Dine nøgler, og hvor de bor

Opsætningen beder om en *begrænset* Stripe-API-nøgle, ikke en live secret key – dem
afviser vi blankt. Begrænset betyder, at nøglen kan to ting: oprette
betal-hvad-du-vil-drikkepengelinket og se drikkepenge komme ind. Den kan ikke læse
din saldo, udløse udbetalinger, foretage refusioner eller røre kundedata. Hvis den
lækkede i morgen, når skaden ikke længere end til et drikkepengelink.

**Uden en konto forlader den nøgle aldrig din enhed.** Den sidder i enhedens egen
nøglering og sendes kun nogensinde til `api.stripe.com` over TLS. Der er slet ingen
live.tips-server i billedet.

**Når du logger ind, flytter nøglen til os** – fordi en nøgle, der kun findes på én
telefon, ikke også kan betjene tabletten på scenen. Vi krypterer den (en
AES-256-nøgle pr. hemmelighed, som selv er pakket ind af Google Cloud KMS) og gemmer
den et sted, hvor intet kan læse den tilbage: ikke en anden konto, ikke os med et
blik i en database, ikke engang dig. Den åbnes kun inde i vores funktioner, bruges
til at tale med Stripe på dine vegne og gives aldrig til en enhed igen. Sig det
ligeud: at logge ind sætter en live.tips-server i vejen mellem Stripe og din
drikkepengehistorik. Aldrig pengene – dataene.

## Serverne, og hvad de ikke kan

Der er to, og begge er minimale.

**Relæet** findes, fordi Revolut og MobilePay ikke kan styres fra en browser på
samme måde som Stripe. At slå dem til aktiverer en håndfuld Firebase-funktioner, der
serverer din drikkepengeside på `tip.live.tips`. Det gemmer din offentlige
drikkepengesideprofil – visningsnavnet og de betalings-handles, du valgte at
offentliggøre – og fører, for en side uden en konto bag sig, ingen
drikkepengehistorik: drikkepenge venter kun, indtil din sceneenhed viser dem, og
alt, som ingen kom tilbage efter, fejes væk inden for en time. Det ser ingen penge
og sletter sig selv efter 90 dages inaktivitet. Bruger du kun Stripe og logger
aldrig ind, kontaktes relæet aldrig overhovedet.

**Webhooken** findes først, når du logger ind. Fordi din nøgle nu bor hos os,
rapporterer Stripe hver drikkepengebetaling til en lille funktion hos os, som
skriver den ind i din egen historik, så dine andre enheder kan vise den. Det er en
kopi af en hændelse, ikke en kopi af pengene. Den kan ikke flytte en øre, og den kan
kun nogensinde skrive ind i den ene konto, den hører til.

Ingen af de to servere kan tage en andel, fordi ingen af dem er i nærheden af
pengene. Det mest, nogen af dem kan gøre, er at fejle – og en opsætning med kun
Stripe og uden konto er afhængig af ingen af dem.

## Kontoen, du ikke behøver at oprette

Appen starter stadig op i en enhedslokal profil, hvilket er, hvad den altid har
været: din drikkepengekrukke, din nøgle og din drikkepengehistorik lever på enheden
og ingen andre steder. Der er ikke noget at melde sig til.

At logge ind – med Apple, med Google eller som gæst – er nu muligt, og det findes af
én grund: en enhed nummer to. Hvis tabletten på scenen og telefonen i din lomme skal
vise den samme aften, må noget sidde mellem dem, og det noget er Firestore, under et
bruger-id, som kun du kan læse. Dine bands, indstillinger, drikkepengehistorik – og,
krypteret som ovenfor, din Stripe-nøgle – bor der. Det er en reel ændring af
privatlivsfortællingen, og den fortjener at blive sagt lige ud frem for at blive
opdaget: uden en konto ser ingen server nogensinde et tip; med en konto gør dit eget
hjørne af vores, og det er vores webhook, der skriver det dertil. Det er prisen for
enhed nummer to, og det er dig, der vælger at betale den eller lade være. Det, den
aldrig rører, er pengene – en konto flytter dine data, ikke din saldo, og der er
stadig ingen andel.

## Hvorfor du ikke bare skal tage os på ordet

Alt ovenstående kan efterprøves. Kodebasen er MIT-licenseret og offentlig, og siden
er et statisk build, som GitHub Actions udruller til GitHub Pages – ingen skjult
infrastruktur, intet der kompileres bag en dør. Åbn netværksfanen under en
demodrikkepenge og læs forespørgslerne. Der er færre, end du tror.

Det er det egentlige produktløfte. Ikke at vi er til at stole på, men at du ikke
har brug for, at vi er det.
</content>
