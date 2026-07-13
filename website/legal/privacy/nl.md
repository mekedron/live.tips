---
title: Privacybeleid
description: live.tips heeft geen cookies, geen analytics en geen tracking, en werkt helemaal zonder account. Kies je er toch voor om in te loggen, dan staat hier precies wat er wordt bewaard, waar, door wie, en hoe lang.
updated: 2026-07-13
updated_label: Laatst bijgewerkt op 13 juli 2026
---

live.tips is een open-source fooienpot voor artiesten. Hij wordt beheerd door **Nikita Rabykin**, een
individuele ontwikkelaar, geen bedrijf. Als iets hieronder voor jou van belang is, schrijf dan naar
**[contact@live.tips](mailto:contact@live.tips)** — op dat adres zit een mens.

Dit beleid is eerlijk over de saaie delen. We zeggen liever "we bewaren je naam maximaal
één uur" dan te beweren dat we niets bewaren en er dan naast te zitten.

## De korte versie

- **Een account is optioneel.** De app werkt helemaal zonder account, en dat is nog steeds de
  standaard. Wil je je bands en je geschiedenis op een tweede apparaat, dan kun je inloggen — en
  dan wordt een deel ervan op een server bewaard. Wat wat is, staat hieronder.
- **Geen cookies.** Geen enkele, nergens.
- **Geen analytics, geen tracking, geen advertenties, geen scripts van derden** op deze website.
- **We raken je geld nooit aan.** Fooien gaan rechtstreeks van de fan naar het eigen
  Stripe-, Revolut-, MobilePay- of Monzo-account van de artiest. Wij zitten niet in dat pad.
- **In de standaardopzet praat de app alleen met Stripe** — niet met enige live.tips-server.
- De enige server die we überhaupt draaien is een klein relay op Firebase van Google. Dat bestaat
  alleen als een artiest Revolut, MobilePay of Monzo aanzet — of als hij inlogt.

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
- **Fooiengeschiedenis, sessiegeschiedenis, het doel en de app-instellingen** worden bewaard in de lokale
  opslag van het apparaat. Daaronder vallen de namen en berichten die fans aan hun fooien hangen.
- De app verwijderen wist dat allemaal. Er is geen cloudback-up aan onze kant, want
  in deze modus is er geen cloud aan onze kant.

**Wij ontvangen hier niets van.** De app wordt geleverd zonder analytics-SDK, zonder crash
reporter, zonder pushmeldingen en zonder advertentiecode — helemaal geen, ook geen uitgeschakelde.

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
  e-mailadres verbergen; Apple geeft ons dan in plaats daarvan een relay-adres.)
- **Een gastaccount** — een anoniem account zonder e-mailadres en zonder naam. Het synchroniseert
  en het kan worden ingetrokken, maar er is niets om het mee terug te halen als je je apparaat
  kwijtraakt. Het is een uid en niets meer.

Zodra je bent ingelogd, krijgt het account zijn eigen privéhoekje in Googles **Cloud
Firestore**-database, op `users/<your uid>/`. De beveiligingsregels geven dat hoekje aan die uid
**en aan niemand anders** — geen enkel ander account kan het lezen, ook niet door URL's te raden.
Daarin staat:

| Wat | Waarom het er staat |
| --- | --- |
| Je **bands** — namen, instellingen voor de fooienpot en de betaalmethoden, postertekst, doelen | zodat een band bestaat op elk apparaat waarop je inlogt |
| Je **beperkte Stripe-sleutel** en het geheim van de fooienpagina van het relay | in een geheimendocument dat alleen jouw uid kan lezen, en gecachet in de sleutelhanger van elk van je apparaten |
| **App-instellingen** | zodat een apparaat dat je toevoegt al is ingesteld |
| **Sessieregistraties en fooiengeschiedenis** — inclusief **de namen en de berichten die fans aan hun fooien hangen** | omdat die geschiedenis precies is wat je op dat andere apparaat wilde zien |
| De **live sessie** die op dit moment loopt | zodat een tweede scherm kan aanhaken bij de set van vanavond |
| Je **apparaten** — de naam die elk zichzelf geeft ("Nikita's iPhone"), het platform en het model, wanneer het voor het eerst en het laatst is gezien | zodat Instellingen → Beveiliging ze kan opsommen, en jij er een kunt intrekken |
| Een klein **profieldocument** — de accountnaam die je koos, en welke aanbieder je gebruikte | zodat de accountwisselaar het kan labelen |

En nu het belangrijke deel, ronduit: **zonder account verlaten de naam en het bericht van een fan
nooit het apparaat van de artiest. Met een account worden ze bewaard op Googles servers onder de
uid van de artiest, als onderdeel van de eigen gesynchroniseerde geschiedenis van die artiest.**
Geen enkel ander account kan ze lezen, wij kijken er niet naar, en er wordt niets uit afgeleid —
maar ze staan er, en dat mag je weten voordat je inlogt.

Uitloggen zet het apparaat terug in de lokale modus. Het verwijdert de gegevens van het account
niet — zie *Dingen verwijderen*, hieronder.

### Een apparaat toevoegen met een QR-code

Om een apparaat toe te voegen toon je een QR-code op een apparaat dat al is ingelogd. De code is
willekeurig, **eenmalig te gebruiken, en verloopt na twee minuten**, en het nieuwe apparaat krijgt
niets tot je op het oude op *bevestigen* tikt. Zolang die handdruk openstaat bewaren we de code,
de naam die het nieuwe apparaat zichzelf gaf, en het platform — en de registratie wordt verwijderd
zodra hij verloopt. Een gefotografeerde QR-code is waardeloos zonder jouw bevestigende tik.

## Waar dit alles fysiek staat

Firebase Auth, Cloud Firestore en onze Cloud Functions draaien in de **Europese Unie** — de
database in Googles `eur3`-multiregio, de functions in `europe-west1`. Google treedt op als onze
verwerker onder de
[privacy- en beveiligingsvoorwaarden van Firebase](https://firebase.google.com/support/privacy) en
zijn eigen [privacybeleid](https://policies.google.com/privacy). Zoals elke grote aanbieder kan
Google infrastructuur buiten de EU inschakelen voor ondersteuning en beveiliging; dat wordt door
die voorwaarden geregeld, niet door ons.

## Stripe

Als een fan met kaart betaalt, staat hij op de afrekenpagina van **Stripe**, niet op de onze. Stripe
verzamelt en verwerkt zijn betaalgegevens als zelfstandige verwerkingsverantwoordelijke onder het
[privacybeleid van Stripe](https://stripe.com/privacy). Wij zien nooit kaartnummers, en we
hebben geen toegang tot het Stripe-account van de artiest.

De app van de artiest leest zijn eigen fooien uit Stripe met de eigen beperkte sleutel van de
artiest — rechtstreeks van het apparaat naar `api.stripe.com`. **Er staat geen live.tips-server in
dat pad, en die heeft er ook nooit gestaan.** De naam en het bericht van een fan, als hij die heeft
achtergelaten, reizen van Stripe naar het apparaat van de artiest en stoppen daar — tenzij de
artiest is ingelogd, in welk geval het apparaat ze ook opslaat in de eigen Firestore-geschiedenis
van die artiest, zoals hierboven beschreven.

## Het relay — alleen als Revolut, MobilePay of Monzo aanstaan

Opzetten met alleen Stripe raken dit nooit aan.

Revolut, MobilePay en Monzo bieden een app geen enkele manier om te bevestigen dat een betaling heeft plaatsgevonden,
dus die fooien lopen via een klein open-source relay dat we draaien op **Firebase** — Cloud
Functions en Firestore in `europe-west1`, met de fooienpagina voor de fan geserveerd vanaf
**`tip.live.tips/t/<id>`**. Het raakt nooit geld aan. Hier staat alles wat het verwerkt.

### Wat de artiest opslaat

Het aanmaken van een fooienpagina slaat de **weergavenaam van de artiest, zijn openbare bericht, zijn
valuta en de betaalgegevens die hij heeft gekozen om te publiceren** op (zijn Stripe-betaallink,
Revolut-gebruikersnaam, MobilePay Box ID, Monzo-gebruikersnaam). Dat is allemaal informatie die de artiest
sowieso bewust aan fans publiceert.

- **Bewaartermijn: een fooienpagina zonder account erachter wordt automatisch verwijderd na 90
  dagen inactiviteit.** Een fooienpagina die bij een ingelogd account hoort, leeft zolang de band
  waar hij bij hoort.
- De artiest kan het **onmiddellijk** verwijderen vanuit de app, op elk moment.
- Er wordt hier nooit een e-mailadres, wachtwoord, wettelijke naam of bankgegeven verzameld.
- Het geheim van de pagina wordt **alleen als hash** bewaard. We zouden je het geheim niet kunnen
  vertellen als je erom vroeg; we kunnen er alleen een controleren.

### Wat een fan verstuurt

Het fooienformulier vraagt om een **bedrag**, en optioneel om een **naam** en een **bericht**. Dat is
het hele formulier. Geen e-mail, geen telefoonnummer, geen account.

- De fooi wordt weggeschreven naar een **afleverwachtrij** — één enkel document dat bestaat om aan
  het scherm van de artiest te worden overhandigd. Zodra het scherm de fooi toont, **verwijdert het
  apparaat van de artiest dat document.** Het verwijderen *is* de ontvangstbevestiging; er is geen
  "afgeleverd"-vlaggetje, want er blijft geen registratie over om te vlaggen.
- Als het scherm van de artiest offline is — telefoon vergrendeld, geen bereik — **wacht de fooi
  maximaal één uur in die wachtrij**, zodat hij niet zomaar verloren gaat, en gaat hij eroverheen
  op het moment dat het scherm weer verbinding maakt. Als niemand opnieuw verbinding maakt, wordt
  hij **ongezien verwijderd**, volgens een vast schema opgeruimd, of iemand er nu ooit nog voor
  terugkwam of niet.
- **Die wachtrij is de enige plek waar door fans geschreven tekst ooit op onze server wordt
  opgeslagen, en één uur is de harde grens.** Is de artiest ingelogd, dan bewaart zijn apparaat de
  fooi vervolgens in *zijn* Firestore-geschiedenis — want dat is zijn geschiedenis, en daarvoor is
  hij ingelogd.
- Je naam en bericht worden ook geplaatst in de **betaalomschrijving** die opent in Revolut,
  MobilePay of Monzo — zo weet de artiest wie er een fooi gaf. Die bedrijven
  verwerken het vervolgens onder hun eigen privacybeleid.
- Het relay houdt **geen fooiengeschiedenis** bij. Het kan jou, ons of wie dan ook geen lijst tonen van
  wie wie een fooi gaf.

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
| **Google (Firebase)** | Accounts, de gesynchroniseerde gegevens van een ingelogde artiest, het relay, serverlogs | Het optionele account en het optionele relay |
| **Stripe** | De betaalgegevens van de fan, als zelfstandige verwerkingsverantwoordelijke | Fooien met kaart |
| **Cloudflare** | Het IP-adres van de fan, voor de Turnstile-controle op de fooienpagina. En onze DNS. | Bots weghouden bij het fooienformulier |
| **GitHub** | Het IP-adres en de user-agent van iedereen die deze website laadt | Het hosten van de website |
| **Revolut / MobilePay / Monzo** | Wat de fan ook doet in hun eigen app, betaalomschrijving inbegrepen | Die betaalmethoden |

We verkopen niets aan niemand, en er staat verder niemand op die lijst.

## Rechtsgrondslag, als je die nodig hebt (AVG)

- Een account draaien waar je om hebt gevraagd, je eigen gegevens naar je eigen apparaten
  synchroniseren, het relay draaien voor een artiest die het heeft aangezet, en de fooi van een fan
  afleveren op het scherm waarvoor hij bedoeld was: **uitvoering van een dienst waar je om hebt
  gevraagd**.
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
- **Een apparaat**: Instellingen → Beveiliging somt je apparaten op. Je kunt er een intrekken, of
  overal elders uitloggen — wat de sessie van elk ander apparaat onmiddellijk beëindigt, niet ooit
  een keer.
- **Je hele account, met één tik: die knop heeft de app nog niet.** We geven dat liever toe dan te
  doen alsof. Tot hij er is, schrijf naar **[contact@live.tips](mailto:contact@live.tips)** en dan
  verwijderen we het account en alles eronder met de hand. Ondertussen kun je nu al elke band
  verwijderen, wat alles van betekenis weghaalt en een leeg account achterlaat.

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
