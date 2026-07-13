# Fooien zijn geen donaties — en Stripe behandelt ze als twee verschillende bedrijven

> Een straatmuzikant die om een 'donatieknop' vraagt, beschrijft een bedrijf dat Stripe in vrijwel heel Europa verbiedt. Een fooi betaalt voor een dienst die je al geleverd hebt; een donatie is fondsenwerving voor een goed doel. Het verschil bepaalt in welke categorie je account belandt — en één API-parameter kan de verkeerde voor je kiezen.

Canonical: https://live.tips/nl/blog/fooien-zijn-geen-donaties/
Published: 2026-07-11
Language: nl
Tags: Stripe, donations, busking, compliance, how-to

---

Elk hulpmiddel op internet wil dat je het een donatie noemt. De knoppen zeggen
*Doneer*. De blogposts zeggen *donatieknop voor muzikanten*. De pluginmappen zeggen
*accepteer donaties*. Ben je muzikant en zoek je een manier om betaald te worden
door mensen zonder contant geld, dan volgt dat woord je overal.

Dan open je een Stripe-account, en Stripe vraagt wat je bedrijf doet. En op dat
moment houdt het woord op marketingtekst te zijn en wordt het een
**bedrijfscategorie** — een die Stripe in vrijwel heel Europa niet toestaat.

Dit is geen muggenzifterij en geen advocatenonderscheid. Het is de vraag die de
betaalrekening van een volstrekt gewone straatmuzikant het vaakst in beoordeling,
vertraging of weigering doet belanden. Bijna niemand heeft het onomwonden voor
muzikanten opgeschreven, dus bij dezen.

## Twee woorden, twee bedrijven

Stripe trekt de grens zelf, in één zin per kant. Uit
[Vereisten voor het accepteren van fooien of donaties](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> een fooi moet gegeven worden voor een goed of dienst die is geleverd (bijv.
> content)

> een donatie moet verbonden zijn aan een specifiek liefdadig doel dat je je
> verplicht te verwezenlijken

Stripes pagina's staan in het Engels; we vertalen ze hier voor je, en de originelen
staan achter de links.

Lees die twee zinnen twee keer, want al het andere in deze post volgt eruit.

Een **fooi** kijkt terug op iets wat al gebeurd is. De dienst is geleverd, de fan
vond het mooi, de fan betaalde extra. Het geld is onvoorwaardelijk en je bent verder
niets verschuldigd. Dit is de fooienregel op de restaurantrekening, de munten in de
hoed, het briefje van vijf dat na het laatste nummer in een hand wordt gedrukt.

Een **donatie** kijkt vooruit naar iets wat je beloofd hebt te doen. Er is een doel.
Er is een bestemming die je aan de gever beschreven hebt. En — Stripe is daar
expliciet over — het geld moet daadwerkelijk naar die bestemming gaan. Je houdt het
in bewaring voor iets wat je gezegd hebt te zullen verwezenlijken.

Dat zijn geen twee schakeringen van dezelfde handeling. Het zijn twee verschillende
relaties, met twee verschillende sets verplichtingen, en Stripe verzekert ze als
twee verschillende bedrijven.

## Een straatmuzikant zit vierkant, ondubbelzinnig aan de fooienkant

Je stond twee uur op een plein te spelen. Veertig mensen bleven staan. Eén van hen
scant je code en stuurt je vijf euro.

**Dat is een fooi.** Het optreden is de dienst. Die is geleverd — ze zagen het
gebeuren. Er is geen doel, geen begunstigde, geen bestemming die je je verplicht hebt
te verwezenlijken, en niemand heeft je geld toevertrouwd voor een project. Je bent
een uitvoerend artiest die betaald wordt voor een optreden, en dat is een van de
oudste en minst omstreden commerciële afspraken die er bestaan.

De verwarring komt doordat de fooi van een straatmuzikant *vrijwillig* is, en we zijn
getraind om te denken dat vrijwillig geld liefdadig geld is. Dat is het niet. Een
fooi is ook vrijwillig. Vrijwilligheid maakt iets niet tot een donatie — een
**liefdadig doel** wel.

Dus wanneer je bordje zegt "donaties welkom", ben je niet bescheiden of beleefd. Je
beschrijft, in het vocabulaire van de betaalverwerker, een bedrijf waar je niet in
zit.

## Wat dat woord je werkelijk kost

Hier wordt de abstractie geld.

Stripe publiceert een
[lijst met beperkte bedrijven](https://stripe.com/legal/restricted-businesses) — de
dingen die je niet met een Stripe-account mag doen, of alleen in bepaalde landen.
Onder het kopje **Crowdfunding en fondsenwerving** staat deze regel, letterlijk:

> Organisaties die fondsen werven voor een liefdadig doel (Let op: ondersteund in
> Australië, Canada, het Verenigd Koninkrijk en de Verenigde Staten. Verboden in alle
> andere landen.)

Lees de haakjes langzaam. Fondsenwerving voor een goed doel is een **ondersteund
bedrijf in vier landen** — Australië, Canada, het VK, de VS — en **overal elders
verboden.**

Overal elders is inclusief Nederland en België, en inclusief Duitsland, Frankrijk,
Spanje, Italië, Polen, Finland en elk ander land waar een straatmuzikant redelijkerwijs
zou kunnen staan. De meeste straatmuzikanten ter wereld wonen in "alle andere landen".

Diezelfde pagina noemt ook *"fondsenwerving door non-profits, goede doelen,
politieke organisaties en bedrijven die een beloning in ruil voor een donatie
aanbieden"* als beperkt, en Stripes pagina over fooien en donaties stapelt daar nog
landspecifieke regels bovenop: in Japan mogen particulieren helemaal geen donaties
ontvangen; in Singapore alleen door de overheid geregistreerde liefdadige of
religieuze organisaties; in India, Hongkong en Thailand worden donaties niet
ondersteund.

Dus een muzikant in Amsterdam die "donaties voor mijn muziek" in het Stripe-formulier
typt, heeft zojuist een bedrijf beschreven dat Stripe in Nederland verbiedt. Niet
omdat straatoptredens verboden zijn — die zijn volstrekt in orde — maar omdat de
woorden die hij koos bij een categorie horen die dat wel is.

## En nu de kalibratie, want dit is geen horrorverhaal

**Straatmuzikanten zijn geen beperkt bedrijf.** Fooien zijn geen beperkt bedrijf.
Live optreden staat niet op de lijst, zet je niet op de lijst, en is ongeveer het
gewoonste wat je met een betaalrekening kunt doen. Als je jezelf accuraat beschrijft,
raakt niets hiervan je en is de opzet saai, precies zoals het hoort.

Het risico is hier niet Stripe. Het risico is **zelfmisclassificatie** — de kamer
binnenlopen en jezelf aankondigen als fondsenwerver voor een goed doel terwijl je
gitarist bent. Stripe kan onmogelijk weten dat je "geef me alsjeblieft een fooi"
bedoelde. Het heeft alleen het formulier dat je invulde, de bedrijfsomschrijving die
je schreef, en de woorden op de pagina waar je QR-code naartoe wijst.

Niemand bij Stripe jaagt op straatmuzikanten. Ze lezen simpelweg wat je ze verteld
hebt.

## De valkuil is één parameter diep

Hier komt het deel dat bijna niemand opschrijft, en het is het nuttigste in deze post.

Stripes Payment Links hebben een parameter die `submit_type` heet. De
[API-referentie](https://docs.stripe.com/api/payment-link/object) beschrijft hem als
iets bijna cosmetisch:

> Geeft het type transactie aan dat wordt uitgevoerd, wat de relevante tekst op de
> pagina aanpast, zoals de verzendknop.

*Past de relevante tekst aan.* Je zou daaruit redelijkerwijs concluderen dat dit een
knoplabel verandert, en dat een fooienpot natuurlijk *Donate* ('doneer') zou moeten
zeggen in plaats van *Buy* ('koop'), want *Buy* is een raar woord om onder de hoed
van een straatmuzikant te drukken.

Dan lees je wat de afzonderlijke waarden werkelijk doen:

> `donate` — Aanbevolen bij het accepteren van donaties. De verzendknop krijgt het
> label 'Donate' en URL's gebruiken de hostnaam `donate.stripe.com`

> `pay` — De verzendknop krijgt het label 'Buy' en URL's gebruiken de hostnaam
> `buy.stripe.com`

**Het is geen label. Het is een hostnaam.** Zet `submit_type=donate` en de link die
Stripe je aanreikt — die je tot QR-code maakt, afdrukt en op je gitaarkoffer plakt —
staat op `donate.stripe.com`. Elke fan die hem scant ziet een donatiepagina. Elke
betaling in je dashboard kwam via een donatiestroom binnen. De QR-code op je koffer
vertelt Stripe, vertelt je publiek en vertelt uiteindelijk jou dat je donaties
inzamelt.

Je hebt het woord "donatie" nergens geschreven. Eén API-parameter schreef het voor
je, en drukte het af op een plastic bordje op een openbaar plein.

Dit is een makkelijke valkuil om in te lopen, en het is niet de schuld van de lezer
die erin trapt: de parameter is gedocumenteerd als een tekstwijziging, *Donate* is
duidelijk het aardigere woord om onder de hoed van een straatmuzikant te drukken, en
het gevolg — een bedrijfsclassificatie — staat twee zinnen verder dan de meeste
mensen lezen.

live.tips stuurt `submit_type=pay`. De link van elke artiest is een
`buy.stripe.com`-link, en de code draagt een commentaar dat uitlegt waarom, want het
is het soort ding dat een toekomstige bijdrager anders zou "verbeteren".

## Wat een muzikant eigenlijk zou moeten doen

Hier is geen advocaat voor nodig. Er zijn vijf minuten en wat gewone woorden voor
nodig.

- **Beschrijf het echte bedrijf** in Stripes aanmeldformulier. "Live muziekoptredens."
  "Straatmuzikant." "Muzikant — fooien van publiek bij live optredens." Zeg dat je
  optreedt, en dat de betalingen fooien voor die optredens zijn.
- **Kies een passende categorie.** Live entertainment, podiumkunsten, muzikant. Geen
  goed doel, geen non-profit, geen fondsenwerving.
- **Gebruik `submit_type=pay`** als je de Payment Link zelf bouwt. Bouwde een tool
  hem voor je, kijk dan naar de URL die eruit kwam: `buy.stripe.com` is een
  fooienpot, `donate.stripe.com` is een donatiepagina. Dat is een controle van twee
  seconden, en het vertelt je wat je tool denkt dat je bent.
- **Noem het geen donatie** — niet op het bordje, niet op je website, niet in de
  bedrijfsomschrijving bij Stripe. "Fooien", "fooienpot", "steun de band", "trakteer
  ons op een biertje" beschrijven allemaal wat er gebeurt. "Doneer" beschrijft iets
  anders.
- **Houd een echte inzamelingsactie apart.** Speel je een benefietoptreden en gaat het
  geld naar een goed doel, dan *is* dat werkelijk fondsenwerving voor een goed doel,
  en dan gaan de regels hierboven wél over jou — inclusief de landenlijst. Doe het
  onder het juiste account, in het juiste land, met Stripes voorwaarden gelezen, en
  nooit via de fooienpot die je op gewone avonden gebruikt.

Die laatste verdient nadruk, want het is de eerlijke helft van het argument. We zeggen
niet dat donaties slecht zijn of dat muzikanten nooit geld voor een goed doel mogen
inzamelen. We zeggen dat het een **andere activiteit** is, met andere regels, en dat
het stilletjes door dezelfde QR-code laten lopen de manier is om met allebei in de
problemen te komen.

Nog één regel van Stripes fooien-en-donatiespagina is het weten waard, omdat hij een
derde ding uitsluit dat mensen met beide verwarren: Stripe doet niet aan
*"betaalverwerking voor persoonlijke of peer-to-peer geldoverdracht (bijv. geld sturen
tussen vrienden)"*. Een fooi is ook geen cadeau tussen vrienden. Wil je dat spoor —
een fan die je gewoon geld stuurt, van persoon tot persoon — dan is dat wat Revolut en
MobilePay zijn, en daarom leven die
[helemaal buiten Stripe](https://live.tips/nl/blog/een-qr-code-elke-betaalmethode/) in onze app.

## Wat deze post niet is

Het is geen juridisch advies. Het is geen belastingadvies — hoe fooien belast worden
verschilt enorm per land, soms per stad, en valt hier volledig buiten het bestek; vraag
het iemand die daarvoor gekwalificeerd is waar je woont.

En het is geen belofte over jouw account. **Of Stripe je goedkeurt is uitsluitend
Stripes beslissing.** live.tips heeft geen relatie met Stripe, geen mogelijkheid om een
beoordeling te beïnvloeden, en geen manier om er namens jou beroep tegen aan te tekenen.
Wat onze software wél kan, is je geen woorden in de mond leggen. Wat je op het formulier
schrijft, schrijf je nog altijd zelf.

Beleid verandert ook. De hier geciteerde regels stonden in juli 2026 op Stripes
pagina's, en de links staan er gewoon; ga ze zelf lezen in plaats van een blogpost te
geloven, deze inbegrepen.

## De korte versie

Je speelde de set. Ze keken ernaar. Ze betaalden je ervoor.

Dat is een fooi. Zeg dat ook — op het bordje, in het formulier, in de URL — en de saaie
uitkomst die je wilt is de uitkomst die je krijgt. We bouwen de fooienpot precies rond
die bewering, tot en met
[naar welke Stripe-hostnaam je QR-code wijst](https://live.tips/nl/blog/bouw-een-fooienpot-op-je-eigen-stripe-account/),
en wil je het bredere plaatje van waar het geld werkelijk heen gaat, dan staat dat
[hier](https://live.tips/nl/blog/hoe-live-tips-met-geld-omgaat/).
