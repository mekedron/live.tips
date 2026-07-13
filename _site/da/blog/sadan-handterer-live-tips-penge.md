# Sådan håndterer live.tips penge (det gør det ikke)

> Der er ingen live.tips-saldo, ingen udbetalingsplan og ingen andel. Her er arkitekturen, der gør de tre påstande kedelige i stedet for modige.

Canonical: https://live.tips/da/blog/sadan-handterer-live-tips-penge/
Published: 2026-07-02
Updated: 2026-07-13
Language: da
Tags: Stripe, privacy, open source

---

Enhver drikkepengekrukke kan skrive „0 % gebyr" på sin landingsside. Det
interessante spørgsmål er, hvad softwaren skulle gøre for at *begynde* at tage en
andel, og hvor meget af det du ville kunne se.

For live.tips er svaret: den skulle bygges om. Det er ikke et løfte om vores
hensigter, det er en beskrivelse af, hvor pengene går hen.

## Kortdrikkepenge passerer aldrig gennem os

Når et fan trykker på et kortbeløb, taler dens browser med `api.stripe.com`. Ikke
med en live.tips-server – der er ingen i den sti. Betalingen oprettes på **din**
Stripe-konto, lander i **din** Stripe-saldo og udbetales efter **din** Stripe-plan.
Det eneste gebyr er Stripes eget standardgebyr for behandling, som Stripe opkræver
dig direkte, præcis som hvis du selv havde integreret Stripe.

Der er ingen kassebog hos os, fordi der ikke er noget at bogføre. Vi kunne ikke
skumme en procentdel af uden først at bygge det, der holder pengene.

## Dine nøgler forbliver dine

Opsætningen beder om en *begrænset* Stripe-API-nøgle, ikke en live secret key – dem
afviser vi blankt. Den gemmes i din egen enheds nøglering og sendes kun nogensinde
til Stripe over TLS.

Begrænset betyder, at nøglen kan to ting: oprette
betal-hvad-du-vil-drikkepengelinket og se drikkepenge komme ind. Den kan ikke læse
din saldo, udløse udbetalinger, foretage refusioner eller røre kundedata. Hvis den
lækkede i morgen, når skaden ikke længere end til et drikkepengelink.

## Den ene server i betalingsvejen

Revolut og MobilePay kan ikke styres fra en browser på samme måde som Stripe, så
det at slå dem til aktiverer et minimalt relæ – en håndfuld Firebase-funktioner,
der serverer din drikkepengeside på `tip.live.tips`. Det er værd at være præcis om,
hvad det relæ gør, for „vi tilføjede en backend" er som regel dér, disse historier
går galt.

Det gemmer din offentlige drikkepengesideprofil – visningsnavnet og de
betalings-handles, du valgte at offentliggøre. Mere er det ikke. Det fører ingen
drikkepengehistorik, ser ingen penge, holder ingen nøgler og sletter sig selv efter
90 dages inaktivitet. Et Revolut- eller MobilePay-tip venter der kun, indtil din
sceneenhed henter det: at vise det sletter det, og alt, som ingen kom tilbage efter,
fejes væk inden for en time. Pengene bevæger sig stadig direkte mellem dit fans
Revolut- eller MobilePay-app og din.

Hvis du kun bruger Stripe, kontaktes relæet aldrig overhovedet.

## Kontoen, du ikke behøver at oprette

Appen starter stadig op i en enhedslokal profil, hvilket er, hvad den altid har
været: din drikkepengekrukke, din nøgle og din drikkepengehistorik lever på enheden
og ingen andre steder. Der er ikke noget at melde sig til.

At logge ind – med Apple, med Google eller som gæst – er nu muligt, og det findes af
én grund: en enhed nummer to. Hvis tabletten på scenen og telefonen i din lomme skal
vise den samme aften, må noget sidde mellem dem, og det noget er Firestore, under et
bruger-id, som kun du kan læse. Dine bands, indstillinger, begrænsede nøgle og
drikkepengehistorik synkroniseres dertil. Det er en reel ændring af
privatlivsfortællingen, og den fortjener at blive sagt lige ud frem for at blive
opdaget: uden en konto ser ingen server nogensinde et tip; med en konto gør dit eget
hjørne af vores. Det er prisen for enhed nummer to, og det er dig, der vælger at
betale den eller lade være. Det, den aldrig rører, er pengene – en konto flytter
dine data, ikke din saldo, og der er stadig ingen andel.

## Hvorfor du ikke bare skal tage os på ordet

Alt ovenstående kan efterprøves. Kodebasen er MIT-licenseret og offentlig, og siden
er et statisk build, som GitHub Actions udruller til GitHub Pages – ingen skjult
infrastruktur, intet der kompileres bag en dør. Åbn netværksfanen under en
demodrikkepenge og læs forespørgslerne. Der er færre, end du tror.

Det er det egentlige produktløfte. Ikke at vi er til at stole på, men at du ikke
har brug for, at vi er det.
