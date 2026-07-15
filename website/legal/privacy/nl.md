---
title: Privacybeleid
description: live.tips heeft geen cookies, geen analytics en geen tracking, en werkt helemaal zonder account. Kies je er toch voor om in te loggen, dan staat hier precies wat er wordt bewaard, waar, door wie, en hoe lang.
updated: 2026-07-15
updated_label: Laatst bijgewerkt op 15 juli 2026
---

live.tips is een open-source fooienpot voor artiesten. Hij wordt beheerd door **Nikita Rabykin**, een
individuele ontwikkelaar, geen bedrijf. Als iets hieronder voor jou van belang is, schrijf dan naar
**[contact@live.tips](mailto:contact@live.tips)** — op dat adres zit een mens.

Dit beleid is eerlijk over de saaie delen. We zeggen liever "we bewaren je naam zolang je de band
houdt" dan te beweren dat we niets bewaren en er dan naast te zitten.

## De korte versie

- **Een account is optioneel.** De app werkt helemaal zonder account, en dat is nog steeds de
  standaard. Wil je je bands en je geschiedenis op een tweede apparaat, dan kun je inloggen — en
  dan wordt een deel ervan op een server bewaard, en meer ervan dan voorheen. Wat wat is, staat
  hieronder.
- **Geen cookies.** Geen enkele, nergens.
- **Geen analytics, geen tracking, geen advertenties, geen scripts van derden** op deze website.
- **We raken je geld nooit aan.** Fooien gaan rechtstreeks van de fan naar het eigen
  Stripe-, Revolut-, MobilePay- of Monzo-account van de artiest. Er is nooit een live.tips-saldo.
- **Zonder account praat de app alleen met Stripe** — niet met enige live.tips-server. Log je in,
  dan verandert dat: je Stripe-sleutel verhuist naar onze server en Stripe meldt je fooien aan ons,
  zodat we ze op je andere apparaten kunnen zetten. Dat is de eerlijke prijs van inloggen, en het
  staat hieronder volledig uiteengezet.
- **Pushmeldingen zijn nieuw, optioneel, en alleen voor ingelogde accounts.** Er wordt niets gepusht
  naar een apparaat dat ze nooit heeft aangezet, en een apparaat zonder account krijgt er nooit een.
- De servers die we draaien staan op Firebase van Google. Ze bestaan als een artiest Revolut,
  MobilePay of Monzo aanzet — of als hij inlogt.

## Deze website

De site is statisch en wordt gehost op **GitHub Pages**. Als host ontvangt GitHub het IP-adres
en de browser-user-agent van iedereen die een pagina laadt — dat is gewone
webserverlogging, het gebeurt voordat onze code draait, en we kunnen het niet uitzetten.
GitHub verwerkt dat onder zijn eigen
[privacyverklaring](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Wij lezen die logs niet en GitHub laat ze ons niet zien.

Verder laden de pagina's die je nu leest **niets van iemand anders**: lettertypen, iconen
en afbeeldingen worden door live.tips zelf geserveerd. Er is geen Google Analytics, geen tag
manager, geen pixel, geen ingesloten widget.

De site bewaart **twee waarden in de `localStorage` van je browser**, allebei door jou ingesteld, allebei
alleen leesbaar voor deze site, en geen van beide wordt ooit ergens naartoe gestuurd:

| Sleutel | Wat die onthoudt |
| --- | --- |
| `lt-landing-theme` | of je licht, donker of automatische kleuren hebt gekozen |
| `lt-langbar-dismissed` | dat je de banner "ook beschikbaar in jouw taal" hebt gesloten |

Je browseropslag wissen verwijdert ze. Het zijn geen cookies, ze worden niet gedeeld,
en ze identificeren niemand.

## De app heeft twee modi, en het verschil is het hele verhaal

Alles hieronder draait om één vraag: **ben je ingelogd?**

### Modus één — geen account. Nog steeds de standaard, nog steeds onveranderd.

De app draait **op het eigen apparaat van de artiest**, en alles wat hij weet, staat daar:

- De **beperkte Stripe-sleutel** wordt bewaard in de sleutelhanger van het apparaat (iOS/macOS Keychain,
  Android Keystore) en wordt uitsluitend naar `api.stripe.com` gestuurd.
- **Fooiengeschiedenis, sessiegeschiedenis, het doel, de lijst met verzoeknummers en de
  app-instellingen** worden bewaard in de lokale opslag van het apparaat. Daaronder vallen de namen
  en berichten die fans aan hun fooien hangen.
- De app verwijderen wist dat allemaal. Er is geen cloudback-up aan onze kant, want
  in deze modus is er geen cloud aan onze kant.

**Wij ontvangen hier niets van.** De app wordt geleverd zonder analytics-SDK, zonder crash
reporter en zonder advertentiecode — helemaal geen, ook geen uitgeschakelde. (Pushmeldingen bestaan
wel, maar zijn een functie voor ingelogde accounts en staan uit tot je ze aanzet — zie *Modus twee*.
Een apparaat zonder account krijgt er nooit een.)

Twee verduidelijkingen, zodat de bewering "praat met niemand" precies waar blijft:

- De app haalt eens per dag **wisselkoersen** op bij openbare koers-API's
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Dat zijn gewone
  verzoeken om een openbare lijst met koersen. Ze bevatten geen informatie over jou, de artiest
  of enige fooi — maar, zoals elk webverzoek, onthullen ze wel je IP-adres aan die
  diensten.
- Als je de **browserversie** van de app gebruikt, downloadt je browser die van onze
  statische host (zie *Deze website* hierboven).

### Modus twee — je bent ingelogd. Dan verlaten sommige gegevens het apparaat, met opzet.

Inloggen is een bewuste handeling. Niets logt jou in voor jou, en niets aan de app houdt op met
werken als je het nooit doet. Je logt in omdat je een tweede apparaat wilt: de telefoon in je zak
en de tablet op het podium die dezelfde avond, dezelfde bands en dezelfde geschiedenis tonen.

Dat kan alleen als een server ze bewaart. **Dus dat doet hij, en dat is de eerlijke prijs van het
tweede apparaat.**

De server is **Firebase**, en dat is Google. Er zijn drie manieren om een account te hebben:

- **Inloggen met Apple** of **Inloggen met Google** — Firebase Auth ontvangt wat de aanbieder
  doorgeeft: een gebruikers-id (uid) en meestal een e-mailadres en een naam. (Bij Apple mag je je
  e-mailadres verbergen; Apple geeft ons dan in plaats daarvan een relay-adres, en het geeft je naam
  alleen de allereerste keer dat je inlogt door.)
- **Een gastaccount** — een anoniem account zonder e-mailadres en zonder naam. Het synchroniseert
  en het kan worden ingetrokken, maar er is niets om het mee terug te halen als je je apparaat
  kwijtraakt. Het is een uid en niets meer. Een gastaccount kan het server-side Stripe-beheer of de
  hieronder beschreven pushmeldingen niet gebruiken, want beide hebben een account nodig dat we aan
  je kunnen teruggeven.

Zodra je bent ingelogd, krijgt het account zijn eigen privéhoekje in Googles **Cloud
Firestore**-database, op `users/<your uid>/`. De beveiligingsregels geven dat hoekje aan die uid
**en aan niemand anders** — geen enkel ander account kan het lezen, ook niet door URL's te raden.
Daarin staat:

| Wat | Waarom het er staat |
| --- | --- |
| Je **bands** — namen, instellingen voor de fooienpot en de betaalmethoden, postertekst, doelen, en je **lijst met verzoeknummers** | zodat een band bestaat op elk apparaat waarop je inlogt |
| **App-instellingen**, inclusief je meldingsvoorkeuren | zodat een apparaat dat je toevoegt al is ingesteld |
| **Sessieregistraties en fooiengeschiedenis** — inclusief **de namen en de berichten die fans aan hun fooien hangen**, en elk **nummer dat een fan aanvroeg** | omdat die geschiedenis precies is wat je op dat andere apparaat wilde zien |
| De **live sessie** die op dit moment loopt | zodat een tweede scherm kan aanhaken bij de set van vanavond |
| Je **apparaten** — de naam die elk zichzelf geeft ("Nikita's iPhone"), het platform en het model, de interfacetaal, wanneer het voor het eerst en het laatst is gezien, en (als je meldingen hebt aangezet) een **pushtoken** | zodat Instellingen → Beveiliging ze kan opsommen, zodat een melding het juiste apparaat in de juiste taal bereikt, en jij er een kunt intrekken |
| Een klein **profieldocument** — de accountnaam die je koos, en welke aanbieder je gebruikte | zodat de accountwisselaar het kan labelen |
| Een **belfeed** — een begrensde lijst van recente fooien en verzoeknummers die binnenkwamen terwijl er geen set liep | zodat je kunt bijlezen wat je hebt gemist |

En nu het belangrijke deel, ronduit: **zonder account verlaten de naam en het bericht van een fan
nooit het apparaat van de artiest. Met een account worden ze bewaard op Googles servers onder de
uid van de artiest, als onderdeel van de eigen gesynchroniseerde geschiedenis van die artiest**, en
— zoals de volgende twee secties uitleggen — **is het nu onze server die ze daar wegschrijft.**
Geen enkel ander account kan ze lezen, wij kijken er niet naar, en er wordt niets uit afgeleid —
maar ze staan er, en ze blijven er zolang de band bestaat, en dat mag je weten voordat je inlogt.

Uitloggen zet het apparaat terug in de lokale modus. Het verwijdert de gegevens van het account
niet — zie *Dingen verwijderen*, hieronder.

#### Je Stripe-sleutel verhuist naar onze server als je inlogt

Dit is de grootste verandering, en de meest lezenswaardige.

**Zonder account verlaat je beperkte Stripe-sleutel nooit je apparaat.** Dat is Modus één, en die
is onveranderd.

**Als je inlogt, verlaat hij het apparaat wél — naar ons.** De sleutel wordt versleuteld (een
AES-256-sleutel per geheim, die zelf door Google Cloud KMS wordt ingepakt) en server-side bewaard op
een plek waar **niemand hem kan teruglezen — geen ander account, en zelfs jij niet.** Hij wordt
alleen binnen onze Cloud Functions ontzegeld, gebruikt om namens jou met Stripe te praten, en nooit
meer aan een apparaat gegeven.

Omdat de sleutel nu bij ons woont, **meldt Stripe je fooien rechtstreeks aan onze server**: we
registreren een webhook op je eigen Stripe-account, en Stripe vertelt die webhook telkens wanneer er
een fooi wordt betaald. Onze functie schrijft de fooi weg in de geschiedenis van je account (zie
hieronder). Je app pollt Stripe niet meer voor een ingelogd account; hij bereikt Stripe alleen via
een smalle, vaste lijst met bewerkingen op onze server (het aanmaken van je fooienlink, het aanmaken
van een verzoeknummerlink, en het teruglezen van je eigen fooien voor afstemming).

Dus, zonder eufemisme gezegd: **voor een ingelogd account staat er nu een live.tips-server in het
pad tussen Stripe en je geschiedenis.** We raken het geld nog steeds nooit aan — een kaartfooi wordt
aangemaakt op je Stripe-account, komt terecht in je Stripe-saldo en wordt uitbetaald volgens je
Stripe-schema, precies zoals voorheen. Wat veranderde is het *gegevens*pad, niet het *geld*pad. Log
je nooit in, dan geldt niets hiervan en praat de app nog steeds rechtstreeks met `api.stripe.com` en
met niemand anders.

#### Een apparaat toevoegen met een QR-code

Om een apparaat toe te voegen toon je een QR-code op een apparaat dat al is ingelogd. De code is
willekeurig, **eenmalig te gebruiken, en verloopt na twee minuten**, en het nieuwe apparaat krijgt
niets tot je op het oude op *bevestigen* tikt. Zolang die handdruk openstaat bewaren we de code,
de naam die het nieuwe apparaat zichzelf gaf, en het platform — en de registratie wordt verwijderd
zodra hij verloopt. Een gefotografeerde QR-code is waardeloos zonder jouw bevestigende tik.

## Verzoeknummers

Een band kan **verzoeknummers** aanzetten: fans kiezen dan een nummer uit de lijst van de artiest en
betalen, optioneel, om het hoger in de wachtrij te zetten. Een verzoek is gewoon een fooi die ook
meedraagt **welk nummer** werd aangevraagd — dus dezelfde naam en hetzelfde bericht die een fan aan
een fooi kan hangen, gelden hier ook, en het wordt opgeslagen en bewaard precies zoals elke andere
fooi (hieronder). De openbare wachtrij die een fan ziet, toont alleen **totalen per nummer** —
hoeveel een nummer heeft opgehaald en waar het staat — en draagt **geen fannamen**. Zonder account
leven de hele lijst met verzoeknummers en de geschiedenis ervan alleen op het apparaat.

## Pushmeldingen

Als je bent ingelogd, kan de app je een **pushmelding** sturen — maar alleen als je het aanzet, per
apparaat, en alleen nadat het besturingssysteem van je apparaat toestemming geeft. Het bestaat voor
één ding: een fooi of een verzoeknummer dat binnenkomt **terwijl je geen set draait**, zodat je
hoort van de fooi die je anders zou zijn misgelopen. Een fooi die binnenkomt terwijl je podium live
is, stuurt niets — je kijkt er al naar.

- Om een push af te leveren heeft Googles **Firebase Cloud Messaging (FCM)** een **pushtoken** voor
  het apparaat nodig. We bewaren dat token, en de interfacetaal van het apparaat, op de eigen
  registratie van het apparaat onder je account, en het wordt verwijderd op het moment dat je
  meldingen uitzet, het apparaat intrekt, of uitlogt. Dode tokens worden automatisch opgeruimd.
- De melding zelf zegt wat er binnenkwam — een bedrag, en de naam van een fan of een nummertitel als
  die is achtergelaten. Dezelfde korte lijst wordt bewaard in de **belfeed** van je account,
  begrensd op de honderd meest recente items, zodat je kunt terugscrollen door wat er binnenkwam
  terwijl je weg was.
- Op het web vereist het afleveren van een push een kleine **service worker** in de root van de site
  en de Firebase-messaging-SDK, die je browser de eerste keer bij Google ophaalt (`gstatic.com`).
  Web-push wordt daarna gedragen door de eigen pushdienst van je browser (voor Chrome is dat die van
  Google). Niets hiervan wordt geladen tenzij je meldingen hebt aangezet.
- **Een gastaccount en een apparaat zonder account krijgen geen pushes**, want een push heeft een
  account nodig waaraan we kunnen afleveren en een token dat je ervoor koos te geven.

## Waar dit alles fysiek staat

Firebase Auth, Cloud Firestore, onze Cloud Functions en de Cloud KMS-sleutel die je Stripe-geheim
inpakt, draaien allemaal in de **Europese Unie** — de database in Googles `eur3`-multiregio, de
functions en de sleutelring in `europe-west1`. Google treedt op als onze verwerker onder de
[privacy- en beveiligingsvoorwaarden van Firebase](https://firebase.google.com/support/privacy) en
zijn eigen [privacybeleid](https://policies.google.com/privacy). Zoals elke grote aanbieder kan
Google infrastructuur buiten de EU inschakelen voor ondersteuning en beveiliging; dat wordt door
die voorwaarden geregeld, niet door ons. Pushmeldingen reizen, zodra ze zijn overhandigd aan
Firebase Cloud Messaging en de pushdienst van je browser of telefoon, over de infrastructuur van die
bedrijven om je apparaat te bereiken.

## Stripe

Als een fan met kaart betaalt, staat hij op de afrekenpagina van **Stripe**, niet op de onze. Stripe
verzamelt en verwerkt zijn betaalgegevens als zelfstandige verwerkingsverantwoordelijke onder het
[privacybeleid van Stripe](https://stripe.com/privacy). Wij zien nooit kaartnummers.

Hoe je fooien je bereiken, hangt af van de modus:

- **Zonder account** leest de app van de artiest zijn eigen fooien uit Stripe met de eigen beperkte
  sleutel van de artiest — rechtstreeks van het apparaat naar `api.stripe.com`. **Er staat geen
  live.tips-server in dat pad.**
- **Als je bent ingelogd**, woont de sleutel op onze server (versleuteld, zoals hierboven), en meldt
  Stripe elke fooi aan onze webhook, die hem wegschrijft in de eigen Firestore-geschiedenis van die
  artiest. **In deze modus staat er wél een live.tips-server in het pad** — voor de fooigegevens,
  nooit voor het geld. De naam en het bericht van een fan, als hij die achterliet, reizen met de
  fooi mee naar de eigen geschiedenis van die artiest en stoppen daar.

## Het relay — alleen als Revolut, MobilePay of Monzo aanstaan

Opzetten met alleen Stripe raken dit nooit aan.

Revolut, MobilePay en Monzo bieden een app geen enkele manier om te bevestigen dat een betaling heeft plaatsgevonden,
dus die fooien lopen via een klein open-source relay dat we draaien op **Firebase** — Cloud
Functions en Firestore in `europe-west1`, met de fooienpagina voor de fan geserveerd vanaf
**`tip.live.tips/t/<id>`**. Het raakt nooit geld aan. Hier staat alles wat het verwerkt.

### Wat de artiest opslaat

Het aanmaken van een fooienpagina slaat de **weergavenaam van de artiest, zijn openbare bericht, zijn
valuta en de betaalgegevens die hij heeft gekozen om te publiceren** op (zijn Stripe-betaallink,
Revolut-gebruikersnaam, MobilePay Box ID, Monzo-gebruikersnaam), en, als verzoeknummers aanstaan,
**zijn openbare nummerlijst en de prijzen per nummer**. Dat is allemaal informatie die de artiest
sowieso bewust aan fans publiceert.

- **Bewaartermijn: een fooienpagina zonder account erachter wordt automatisch verwijderd na 90
  dagen inactiviteit.** Een fooienpagina die bij een ingelogd account hoort, leeft zolang de band
  waar hij bij hoort.
- De artiest kan het **onmiddellijk** verwijderen vanuit de app, op elk moment.
- Er wordt hier nooit een e-mailadres, wachtwoord, wettelijke naam of bankgegeven verzameld.
- Het geheim van de pagina wordt **alleen als hash** bewaard. We zouden je het geheim niet kunnen
  vertellen als je erom vroeg; we kunnen er alleen een controleren.

### Wat een fan verstuurt

Het fooienformulier vraagt om een **bedrag**, en optioneel om een **naam** en een **bericht** — en,
voor een verzoeknummer, welk nummer. Dat is het hele formulier. Geen e-mail, geen telefoonnummer,
geen account.

Waar die door de fan geschreven tekst heen gaat, en hoe lang, hangt ervan af of de artiest is
ingelogd:

- **Als er geen account achter de fooienpagina zit**, wordt de fooi weggeschreven naar een
  **afleverwachtrij** — één enkel document dat bestaat om aan het scherm van de artiest te worden
  overhandigd. Zodra het scherm de fooi toont, **verwijdert het apparaat van de artiest dat
  document.** Het verwijderen *is* de ontvangstbevestiging. Is het scherm van de artiest offline —
  telefoon vergrendeld, geen bereik — dan **wacht de fooi maximaal één uur in die wachtrij**, zodat
  hij niet zomaar verloren gaat, en gaat hij eroverheen op het moment dat het scherm weer verbinding
  maakt. Als niemand opnieuw verbinding maakt, wordt hij **ongezien verwijderd**, volgens een vast
  schema opgeruimd. Voor een artiest zonder account is **die wachtrij de enige plek waar door fans
  geschreven tekst ooit op onze server wordt opgeslagen, en één uur is de harde grens.**
- **Hoort de fooienpagina bij een ingelogd account**, dan is er geen wachtrij. Onze server schrijft
  de fooi **rechtstreeks weg in de eigen geschiedenis van die artiest** onder zijn uid — in de
  sessie van vanavond als er een set loopt, of anders in het eigen archief van de band. Daar blijft
  hij **zolang de band bestaat**; het is de eigen geschiedenis van de artiest, en het is waarvoor hij
  is ingelogd. Dit is dezelfde geschiedenis waar de Stripe-webhook hierboven naartoe schrijft.
- Je naam en bericht worden ook geplaatst in de **betaalomschrijving** die opent in Revolut,
  MobilePay of Monzo — zo weet de artiest wie er een fooi gaf. Die bedrijven
  verwerken het vervolgens onder hun eigen privacybeleid.
- Het relay houdt **geen fooienboek over artiesten heen** bij. Het kan jou, ons of wie dan ook geen
  lijst tonen van wie aan wie een fooi gaf, over verschillende artiesten heen.

### IP-adressen en misbruikbestrijding

Een open formulier waar iedereen naartoe kan posten heeft enige bescherming tegen bots nodig, dus:

- Je IP-adres wordt naar **Cloudflare Turnstile** gestuurd — een antibotcontrole die op de
  fooienpagina draait — om te verifiëren dat je geen bot bent. Turnstile is een product van
  Cloudflare en wordt gebruikt in plaats van een CAPTCHA die je profileert. Turnstile en onze DNS
  zijn de enige dingen die Cloudflare nog voor ons doet; het relay zelf draait nu op Firebase. Zie
  het [privacybeleid van Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Je IP wordt ook gebruikt om verzoeken te **beperken in aantal** (rate limiting) — een fooi
  plaatsen, een fooienpagina aanmaken, een code voor het toevoegen van een apparaat inwisselen.
  Wat we daarvoor bewaren is een **gezouten cryptografische hash van het IP-adres**, nooit het
  IP-adres zelf, ongeveer **twee uur** lang, en daarna wordt die verwijderd. Het zout is een
  servergeheim: zonder dat weigert de code überhaupt iets op te slaan, in plaats van een hash te
  bewaren die omkeerbaar zou zijn.
- **De operationele logs van Google** leggen de technische details van verzoeken aan het relay vast
  — URL, timing, status — voor een paar dagen. Onze code logt bewust geen namen, geen berichten,
  geen geheimen en geen headers. Google treedt op als onze verwerker.

### Tellers

Het relay telt **hoeveel fooien** een bepaalde fooienpagina heeft doorgegeven, zodat we misbruik kunnen opmerken en
weten of het ding überhaupt wordt gebruikt. Het is een getal. Het bevat geen fangegevens.

## Wie verwerkt wat

| Wie | Wat ze krijgen | Waarom |
| --- | --- | --- |
| **Google (Firebase)** | Accounts, de gesynchroniseerde gegevens van een ingelogde artiest, de versleutelde Stripe-sleutel, het relay, pushtokens en aflevering, serverlogs | Het optionele account, het optionele relay, en pushmeldingen |
| **Google Cloud KMS** | De sleutel die het Stripe-geheim van een ingelogde artiest inpakt (nooit het geheim in leesbare vorm) | Het opgeslagen Stripe-geheim onleesbaar houden in rust |
| **Stripe** | De betaalgegevens van de fan, als zelfstandige verwerkingsverantwoordelijke; en, voor een ingelogde artiest, fooigebeurtenissen die naar onze webhook worden gestuurd | Fooien met kaart |
| **Cloudflare** | Het IP-adres van de fan, voor de Turnstile-controle op de fooienpagina. En onze DNS. | Bots weghouden bij het fooienformulier |
| **GitHub** | Het IP-adres en de user-agent van iedereen die deze website laadt | Het hosten van de website |
| **De pushdienst van je browser / telefoon** (bijv. die van Google voor Chrome) | Een pushtoken en de inhoud van de melding, als je meldingen hebt aangezet | Pushmeldingen afleveren |
| **Revolut / MobilePay / Monzo** | Wat de fan ook doet in hun eigen app, betaalomschrijving inbegrepen | Die betaalmethoden |

We verkopen niets aan niemand, en er staat verder niemand op die lijst.

## Rechtsgrondslag, als je die nodig hebt (AVG)

- Een account draaien waar je om hebt gevraagd, je eigen gegevens naar je eigen apparaten
  synchroniseren, je Stripe-sleutel bewaren zodat je fooien je geschiedenis bereiken, het relay
  draaien voor een artiest die het heeft aangezet, de fooi van een fan afleveren op het scherm
  waarvoor hij bedoeld was, en een push sturen die je hebt aangezet: **uitvoering van een dienst
  waar je om hebt gevraagd**.
- Rate limiting, Turnstile, quota op gehashte IP-adressen en het intrekken van apparaten:
  **gerechtvaardigd belang** om te voorkomen dat een gratis, open dienst wordt gesloopt door bots
  en fraude, en om de accounts van artiesten veilig te houden.
- Serverlogs: **gerechtvaardigd belang** bij het uitvoeren en beveiligen van de dienst.

## Dingen verwijderen

Dit telt zwaarder dan welke belofte we er ook over zouden kunnen doen, dus hier staat precies wat
er vandaag bestaat — inclusief wat er niet bestaat.

- **Geen account**: verwijder de app. Dat is alles, weg.
- **Een band**: een band verwijderen in de app wist de cloudgegevens van die band — zijn
  instellingen, zijn sleutels, zijn sessies, zijn fooiengeschiedenis — samen met de kopie op het
  apparaat.
- **Een fooienpagina**: verwijder of vernieuw hem in de app en hij wordt meteen van het relay
  geveegd, inclusief eventuele wachtende fooien.
- **Pushmeldingen**: zet ze uit op een apparaat en het pushtoken ervan wordt verwijderd. De belfeed
  wordt gewist met de band of het account.
- **Een apparaat**: Instellingen → Beveiliging somt je apparaten op. Je kunt er een intrekken, of
  overal elders uitloggen — wat de sessie van elk ander apparaat onmiddellijk beëindigt, niet ooit
  een keer.
- **Je hele account, met één tik: die knop heeft de app nog niet.** We geven dat liever toe dan te
  doen alsof. Tot hij er is, schrijf naar **[contact@live.tips](mailto:contact@live.tips)** en dan
  verwijderen we het account en alles eronder met de hand. Ondertussen kun je nu al elke band
  verwijderen, wat alles van betekenis weghaalt — inclusief de opgeslagen Stripe-sleutel — en een
  leeg account achterlaat.

## Jouw rechten

Je kunt ons vragen om een kopie te geven van, te corrigeren of te verwijderen wat we over jou bewaren, en
je kunt een klacht indienen bij je nationale gegevensbeschermingsautoriteit. Schrijf naar
**[contact@live.tips](mailto:contact@live.tips)**.

In de praktijk heb je het meeste al zelf in handen: een artiest kan een fooienpagina of een band
onmiddellijk uit de app verwijderen, niet-afgeleverde fooien van fans verdampen binnen het uur, en
log je nooit in, dan is niets ervan ooit ergens anders geweest dan op je eigen apparaat.

## Kinderen

live.tips is niet gericht op kinderen en we verwerken hun gegevens niet bewust.

## Wijzigingen

We werken deze pagina bij wanneer de software verandert. Omdat het hele project open
source is, staat **elke eerdere versie van dit beleid in de openbare git-geschiedenis** — je kunt
precies nagaan wat er wanneer is veranderd.

## Taal

Dit beleid wordt voor het gemak gepubliceerd in elke taal die de site ondersteunt. Als een
vertaling en de Engelse versie van elkaar afwijken, is **de Engelse versie doorslaggevend**.
