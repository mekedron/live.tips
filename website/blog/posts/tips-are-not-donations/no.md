---
title: Drikkepenger er ikke donasjoner — og Stripe behandler dem som to forskjellige virksomheter
description: En gatemusikant som ber om en «donasjonsknapp», beskriver en virksomhet Stripe forbyr i store deler av Europa. Drikkepenger betaler for en tjeneste du allerede har utført; en donasjon er innsamling til veldedig formål. Forskjellen avgjør hvilken kategori kontoen din havner i — og én enkelt API-parameter kan velge feil for deg.
slug: drikkepenger-er-ikke-donasjoner
---

Hvert eneste verktøy på internett vil at du skal kalle det en donasjon. Knappene
sier *Donate*. Bloggpostene sier *donasjonsknapp for musikere*. Plugin-katalogene
sier *ta imot donasjoner*. Er du musiker og leter etter en måte å få betalt av
folk som ikke har kontanter, følger ordet etter deg overalt.

Så åpner du en Stripe-konto, og Stripe spør hva virksomheten din driver med. Og i
det øyeblikket slutter ordet å være markedsføringstekst og blir en
**virksomhetskategori** — en som Stripe i store deler av Europa ikke tillater.

Dette er ikke pedanteri, og det er ingen juridisk finesse. Det er det ene
spørsmålet som med størst sannsynlighet får en helt alminnelig gatemusikants
betalingskonto satt til gjennomgang, forsinket eller avslått. Nesten ingen har
skrevet det rett ut for dem som spiller live, så her er det.

## To ord, to virksomheter

Stripe trekker grensen selv, med én setning hver. Fra
[Krav for å ta imot drikkepenger eller donasjoner](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> drikkepenger må gis for en vare eller tjeneste som er levert (f.eks. innhold)

> en donasjon må være knyttet til et bestemt veldedig formål som du forplikter deg
> til å oppfylle

Stripes sider er på engelsk; sitatene her har vi oversatt for deg, og originalene
ligger bak lenkene.

Les de to setningene to ganger, for alt annet i dette innlegget faller ut av dem.

**Drikkepenger** ser bakover, på noe som allerede har skjedd. Tjenesten ble
levert, fanen likte den, fanen betalte litt ekstra. Pengene er ubetingede, og du
skylder ingenting mer. Det er drikkepengelinjen på restaurantregningen, myntene i
hatten, femtilappen som blir trykket i en hånd etter siste låt.

En **donasjon** ser framover, på noe du har lovet å gjøre. Det finnes en sak. Det
finnes et formål du har beskrevet for den som gir. Og — Stripe er tydelig på dette
— pengene må faktisk gå til det formålet. Du forvalter dem for noe du har sagt at
du skal få til.

Dette er ikke to nyanser av samme handling. Det er to forskjellige forhold, med to
forskjellige sett av forpliktelser, og Stripe tegner dem som to forskjellige
virksomheter.

## En gatemusikant er utvetydig på drikkepengesiden

Du sto to timer på et torg og spilte. Førti mennesker stanset. En av dem skanner
koden din og sender deg fem euro.

**Det er drikkepenger.** Framføringen er tjenesten. Den ble levert — de så den
skje. Det finnes ingen sak, ingen mottaker, ingen hensikt du har forpliktet deg
til å oppfylle, og ingen har betrodd deg penger til et prosjekt. Du er en utøvende
kunstner som får betalt for en framføring, som er en av de eldste og minst
kontroversielle handelsavtalene som finnes.

Forvirringen kommer av at en gatemusikants drikkepenger er *frivillige*, og vi er
lært opp til å tro at frivillige penger er veldedighetspenger. Det er de ikke.
Drikkepenger — tips, som vi like gjerne sier — er også frivillige.
Frivilligheten er ikke det som gjør noe til en donasjon. Et **veldedig formål**
er det.

Så når skiltet ditt sier «donasjoner mottas med takk», er du ikke beskjeden eller
høflig. Du beskriver, på betalingsformidlerens språk, en virksomhet du ikke driver
med.

## Hva ordet faktisk koster deg

Her blir abstraksjonen til penger.

Stripe publiserer en
[liste over begrensede virksomheter](https://stripe.com/legal/restricted-businesses)
— det du ikke får gjøre med en Stripe-konto, eller bare får gjøre i enkelte land.
Under overskriften **Crowdfunding og innsamling** står denne linjen, ordrett:

> Organisasjoner som samler inn midler til et veldedig formål (Merk: Støttet i
> Australia, Canada, Storbritannia og USA. Forbudt i alle andre land.)

Les parentesen sakte. Innsamling til veldedig formål er en **støttet virksomhet i
fire land** — Australia, Canada, Storbritannia, USA — og **forbudt overalt
ellers.**

Overalt ellers omfatter Norge. Det omfatter Tyskland, Frankrike, Spania, Italia,
Nederland, Polen, Finland og hvert eneste andre land der en gatemusikant med
rimelighet kunne stå. De fleste av verdens gatemusikanter bor i «alle andre land».

Den samme siden fører også opp *«innsamling utført av ideelle organisasjoner,
veldedige organisasjoner, politiske organisasjoner og virksomheter som tilbyr en
belønning i bytte mot en donasjon»* som begrenset, og Stripes side om drikkepenger
og donasjoner legger et sett landsspesifikke regler oppå: i Japan kan
privatpersoner ikke motta donasjoner i det hele tatt; i Singapore kan bare
statsregistrerte veldedige eller religiøse organisasjoner gjøre det; i India,
Hongkong og Thailand er donasjoner ikke støttet.

Så en musiker i Oslo som skriver «donasjoner til musikken min» i Stripes
registreringsskjema, har akkurat beskrevet en virksomhet Stripe forbyr i Norge.
Ikke fordi gatemusikk er forbudt — gatemusikk er helt greit — men fordi ordene hun
valgte, hører til en kategori som er det.

## Og så kalibreringen, for dette er ingen skrekkhistorie

**Gatemusikanter er ikke en begrenset virksomhet.** Drikkepenger er ikke en
begrenset virksomhet. Liveopptreden står ikke på listen, kommer ikke til å sette
deg på listen, og er omtrent så alminnelig som noe kan bli med en betalingskonto.
Beskriver du deg selv riktig, rører ingenting av dette deg, og oppsettet blir
kjedelig, som er nøyaktig slik det skal være.

Risikoen her er ikke Stripe. Risikoen er **å klassifisere seg selv feil** — å tre
inn i rommet og presentere seg som en veldedig innsamler når man er gitarist.
Stripe har ingen måte å vite at du mente «gi meg gjerne drikkepenger». De har bare
skjemaet du fylte ut, virksomhetsbeskrivelsen du skrev, og ordene på siden
QR-koden din peker på.

Ingen hos Stripe jakter på gatemusikanter. De leser bare det du fortalte dem.

## Fella er én parameter dyp

Her er den delen nesten ingen skriver ned, og den er det mest nyttige i hele
innlegget.

Stripes Payment Links har en parameter som heter `submit_type`.
[API-referansen](https://docs.stripe.com/api/payment-link/object) beskriver den
som noe nesten kosmetisk:

> Angir hvilken type transaksjon som utføres, noe som tilpasser relevant tekst på
> siden, for eksempel send-knappen.

*Tilpasser relevant tekst.* Du ville med rimelighet konkludere med at dette endrer
en knappetekst, og at en tipskrukke selvsagt burde si *Donate* framfor *Buy*, siden
*Buy* — kjøp — er et rart ord å trykke under hatten til en gatemusikant.

Så leser du hva de enkelte verdiene faktisk gjør:

> `donate` — Anbefales når du tar imot donasjoner. Send-knappen får etiketten
> 'Donate', og URL-ene bruker vertsnavnet `donate.stripe.com`

> `pay` — Send-knappen får etiketten 'Buy', og URL-ene bruker vertsnavnet
> `buy.stripe.com`

**Det er ikke en etikett. Det er et vertsnavn.** Sett `submit_type=donate`, og
lenken Stripe rekker deg — den du gjør om til en QR-kode, skriver ut og teiper på
gitarkassa — bor på `donate.stripe.com`. Hver eneste fan som skanner den, ser en
donasjonsside. Hver eneste betaling i dashbordet ditt kom inn gjennom en
donasjonsflyt. QR-koden på kassa di forteller Stripe, forteller publikummet ditt
og til slutt deg selv at du samler inn donasjoner.

Du skrev aldri ordet «donasjon» noe sted. Én API-parameter skrev det for deg, og
trykte det på et plastskilt på et offentlig torg.

Dette er en lett felle å gå i, og det er ikke leserens skyld når det skjer:
parameteren er dokumentert som en tekstendring, *Donate* er åpenbart det penere
ordet å trykke under hatten til en gatemusikant, og konsekvensen — en
virksomhetsklassifisering — står to setninger lenger ned enn de fleste leser.

live.tips sender `submit_type=pay`. Hver artists lenke er en
`buy.stripe.com`-lenke, og koden bærer en kommentar som sier hvorfor, for det er
den typen ting en framtidig bidragsyter ellers ville «forbedret».

## Hva en musiker faktisk bør gjøre

Ingenting av dette krever en advokat. Det krever fem minutter og noen enkle ord.

- **Beskriv den virkelige virksomheten** i Stripes registrering. «Livemusikk.»
  «Gatemusikant.» «Musiker — drikkepenger fra publikum på liveopptredener.» Si at
  du opptrer, og at betalingene er drikkepenger for de opptredenene.
- **Velg en kategori som stemmer.** Liveunderholdning, scenekunst, musiker. Ikke
  veldedighet, ikke ideell organisasjon, ikke innsamling.
- **Bruk `submit_type=pay`** hvis du bygger Payment Link-en selv. Har et verktøy
  bygget den for deg, se på URL-en den produserte: `buy.stripe.com` er en
  tipskrukke, `donate.stripe.com` er en donasjonsside. Det er en tosekunders
  sjekk, og den forteller deg hva verktøyet ditt tror du er.
- **Ikke kall det en donasjon** — ikke på skiltet, ikke på nettsiden din, ikke i
  virksomhetsbeskrivelsen hos Stripe. «Drikkepenger», «tipskrukke», «støtt
  bandet», «spander en øl på oss» beskriver alle det som faktisk skjer. «Doner»
  beskriver noe annet.
- **Hold en ekte innsamling adskilt.** Spiller du en veldedighetskonsert, og
  pengene går til en sak, da *er* det ekte innsamling til veldedig formål, og
  reglene over handler nå om deg — landlisten inkludert. Gjør det under riktig
  konto, i riktig land, etter å ha lest Stripes vilkår, og aldri gjennom
  tipskrukka du bruker på vanlige kvelder.

Det siste punktet fortjener ettertrykk, for det er den ærlige halvdelen av
argumentet. Vi sier ikke at donasjoner er av det onde, eller at musikere aldri kan
samle inn penger til en sak. Vi sier at det er en **annen aktivitet**, med andre
regler, og at det er nettopp ved å kjøre den stilltiende gjennom den samme
QR-koden at begge deler skaffer deg trøbbel.

Enda en linje fra Stripes side om drikkepenger og donasjoner er verdt å kjenne,
siden den utelukker en tredje ting folk blander sammen med begge: Stripe driver
ikke med *«betalingsbehandling for personlige overføringer eller overføringer
mellom privatpersoner (f.eks. å sende penger mellom venner)»*. Drikkepenger er
heller ikke en gave mellom venner. Vil du ha den skinnen — en fan som rett og
slett sender deg penger, person til person — så er det Revolut og MobilePay er, og
det er derfor de lever [helt utenfor Stripe](post:one-qr-code-every-payment-method)
i appen vår.

## Hva dette innlegget ikke er

Det er ikke juridisk rådgivning. Det er ikke skatterådgivning — hvordan
drikkepenger beskattes, varierer enormt fra land til land, iblant fra by til by,
og det ligger fullstendig utenfor rammen her; spør noen kvalifiserte der du bor.

Og det er ikke et løfte om kontoen din. **Om Stripe godkjenner deg, er alene
Stripes avgjørelse.** live.tips har ingen relasjon til Stripe, ingen mulighet til
å påvirke en gjennomgang, og ingen måte å anke en på dine vegne. Det programvaren
vår kan gjøre, er å la være å legge ord i munnen din. Hva du skriver i skjemaet,
er fortsatt ditt å skrive.

Retningslinjer endrer seg også. Linjene som er sitert her, sto på Stripes sider i
juli 2026, og lenkene ligger rett der; gå og les dem selv i stedet for å stole på
en bloggpost, denne inkludert.

## Kortversjonen

Du spilte settet. De så det. De betalte deg for det.

Det er drikkepenger. Si det — på skiltet, i skjemaet, i URL-en — og det kjedelige
utfallet du vil ha, er det du får. Vi bygger tipskrukka rundt nøyaktig den
påstanden, hele veien ned til
[hvilket Stripe-vertsnavn QR-koden din peker på](post:build-a-tip-jar-on-your-own-stripe),
og vil du ha det større bildet av hvor pengene faktisk går, er det
[her](post:how-live-tips-handles-money).
