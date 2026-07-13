---
title: Privacybeleid
description: live.tips heeft geen accounts, geen cookies, geen analytics en geen tracking. Hier is het korte lijstje van wat er wél wordt verwerkt, door wie, en hoe lang.
updated: 2026-07-13
updated_label: Laatst bijgewerkt op 13 juli 2026
---

live.tips is een open-source fooienpot voor artiesten. Hij wordt beheerd door **Nikita Rabykin**, een
individuele ontwikkelaar, geen bedrijf. Als iets hieronder voor jou van belang is, schrijf dan naar
**[contact@live.tips](mailto:contact@live.tips)** — op dat adres zit een mens.

Dit beleid is eerlijk over de saaie delen. We zeggen liever "we bewaren je naam maximaal
één uur" dan te beweren dat we niets bewaren en er dan naast te zitten.

## De korte versie

- **Geen accounts.** Er valt nergens voor te registreren.
- **Geen cookies.** Geen enkele, nergens.
- **Geen analytics, geen tracking, geen advertenties, geen scripts van derden** op deze website.
- **We raken je geld nooit aan.** Fooien gaan rechtstreeks van de fan naar het eigen
  Stripe-, Revolut-, MobilePay- of Monzo-account van de artiest. Wij zitten niet in dat pad.
- **In de standaardopzet praat de app alleen met Stripe** — niet met enige live.tips-server.
- De enige server die we überhaupt draaien is een klein relay, en dat bestaat alleen als een artiest
  Revolut, MobilePay of Monzo aanzet.

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

## De app

De live.tips-app draait **op het eigen apparaat van de artiest**. Alles wat hij weet, staat daar:

- De **beperkte Stripe-sleutel** wordt bewaard in de sleutelhanger van het apparaat (iOS/macOS Keychain,
  Android Keystore) en wordt uitsluitend naar `api.stripe.com` gestuurd.
- **Fooiengeschiedenis, sessiegeschiedenis, het doel en de app-instellingen** worden bewaard in de lokale
  opslag van het apparaat. Daaronder vallen de namen en berichten die fans aan hun fooien hangen.
- De app verwijderen wist dat allemaal. Er is geen cloudback-up aan onze kant, want
  er is geen cloud aan onze kant.

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

## Stripe

Als een fan met kaart betaalt, staat hij op de afrekenpagina van **Stripe**, niet op de onze. Stripe
verzamelt en verwerkt zijn betaalgegevens als zelfstandige verwerkingsverantwoordelijke onder het
[privacybeleid van Stripe](https://stripe.com/privacy). Wij zien nooit kaartnummers, en we
hebben geen toegang tot het Stripe-account van de artiest.

De app van de artiest leest zijn eigen fooien uit Stripe met de eigen beperkte sleutel van de artiest.
De naam en het bericht van een fan, als hij die heeft achtergelaten, reizen van Stripe naar het apparaat van de artiest
en stoppen daar.

## Het relay — alleen als Revolut, MobilePay of Monzo aanstaan

Opzetten met alleen Stripe raken dit nooit aan, en kunnen hier stoppen met lezen.

Revolut, MobilePay en Monzo bieden een app geen enkele manier om te bevestigen dat een betaling heeft plaatsgevonden,
dus die fooien lopen via een klein open-source relay dat we draaien op **Cloudflare** op
`api.live.tips`. Het raakt nooit geld aan. Hier staat alles wat het verwerkt.

### Wat de artiest opslaat

Het aanmaken van een fooienpagina slaat de **weergavenaam van de artiest, zijn openbare bericht, zijn
valuta en de betaalgegevens die hij heeft gekozen om te publiceren** op (zijn Stripe-betaallink,
Revolut-gebruikersnaam, MobilePay Box ID, Monzo-gebruikersnaam). Dat is allemaal informatie die de artiest
sowieso bewust aan fans publiceert.

- **Bewaartermijn: automatisch verwijderd na 90 dagen inactiviteit.**
- De artiest kan het **onmiddellijk** verwijderen vanuit de app, op elk moment.
- Er wordt nooit een e-mailadres, wachtwoord, wettelijke naam of bankgegeven verzameld.

### Wat een fan verstuurt

Het fooienformulier vraagt om een **bedrag**, en optioneel om een **naam** en een **bericht**. Dat is
het hele formulier. Geen e-mail, geen telefoonnummer, geen account.

- Als het scherm van de artiest **online** is, wordt de fooi er rechtstreeks naartoe doorgegeven en
  **nooit naar schijf geschreven**.
- Als het scherm van de artiest **offline** is — telefoon vergrendeld, geen bereik — wordt de fooi **maximaal
  één uur in opslag bewaard**, zodat hij niet zomaar verloren gaat, en daarna doorgegeven op het moment dat het
  scherm weer verbinding maakt. Als niemand opnieuw verbinding maakt, wordt hij **ongezien verwijderd**. Dit is de enige
  door fans geschreven tekst die het relay ooit opslaat, en één uur is de harde grens.
- Je naam en bericht worden ook geplaatst in de **betaalomschrijving** die opent in Revolut,
  MobilePay of Monzo — zo weet de artiest wie er een fooi gaf. Die bedrijven
  verwerken het vervolgens onder hun eigen privacybeleid.
- Het relay houdt **geen fooiengeschiedenis** bij. Het kan jou, ons of wie dan ook geen lijst tonen van
  wie wie een fooi gaf.

### IP-adressen en misbruikbestrijding

Een open formulier waar iedereen naartoe kan posten heeft enige bescherming tegen bots nodig, dus:

- Je IP-adres wordt gebruikt om verzoeken te **beperken in aantal** (rate limiting), en wordt naar **Cloudflare
  Turnstile** gestuurd (een antibotcontrole die op de fooienpagina draait) om te verifiëren dat je geen bot bent.
  Turnstile is een product van Cloudflare en wordt gebruikt in plaats van een CAPTCHA die je profileert.
- Om te voorkomen dat iemand duizenden fooienpagina's aanmaakt, wordt een **cryptografische hash van het IP-adres**
  van degene die er een aanmaakt ongeveer **twee uur** bewaard en daarna weggegooid.
- **De operationele logs van Cloudflare** leggen de technische details van verzoeken aan het relay vast
  — URL, timing, status — voor een paar dagen. Ze bevatten geen namen of berichten van fans.
  Cloudflare treedt op als onze verwerker; zie het
  [privacybeleid van Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Tellers

Het relay telt **hoeveel fooien** een bepaalde fooienpagina heeft doorgegeven, zodat we misbruik kunnen opmerken en
weten of het ding überhaupt wordt gebruikt. Het is een getal. Het bevat geen fangegevens.

## Rechtsgrondslag, als je die nodig hebt (AVG)

- Het relay draaien voor een artiest die het heeft aangezet, en de fooi van een fan afleveren op het
  scherm waarvoor hij bedoeld was: **uitvoering van een dienst waar je om hebt gevraagd**.
- Rate limiting, Turnstile en quota op gehashte IP-adressen: **gerechtvaardigd belang** om te voorkomen dat een
  gratis, open dienst wordt gesloopt door bots en fraude.
- Serverlogs: **gerechtvaardigd belang** bij het uitvoeren en beveiligen van de dienst.

## Jouw rechten

Je kunt ons vragen om een kopie te geven van, te corrigeren of te verwijderen wat we over jou bewaren, en
je kunt een klacht indienen bij je nationale gegevensbeschermingsautoriteit. Schrijf naar
**[contact@live.tips](mailto:contact@live.tips)**.

In de praktijk heb je het meeste al zelf in handen: artiesten kunnen hun fooienpagina onmiddellijk
uit de app verwijderen, fooien van fans verdampen binnen het uur, en al het andere staat op je
eigen apparaat.

## Kinderen

live.tips is niet gericht op kinderen en we verwerken hun gegevens niet bewust.

## Wijzigingen

We werken deze pagina bij wanneer de software verandert. Omdat het hele project open
source is, staat **elke eerdere versie van dit beleid in de openbare git-geschiedenis** — je kunt
precies nagaan wat er wanneer is veranderd.

## Taal

Dit beleid wordt voor het gemak gepubliceerd in elke taal die de site ondersteunt. Als een
vertaling en de Engelse versie van elkaar afwijken, is **de Engelse versie doorslaggevend**.
