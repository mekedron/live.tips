---
title: Privatlivspolitik
description: live.tips har ingen konti, ingen cookies, ingen analyseværktøjer og ingen sporing. Her er den korte liste over, hvad der rent faktisk behandles, af hvem og hvor længe.
updated: 2026-07-13
updated_label: Sidst opdateret 13. juli 2026
---

live.tips er en open source-drikkepengekrukke til optrædende kunstnere. Den drives af
**Nikita Rabykin**, en enkelt udvikler, ikke et selskab. Hvis noget herunder betyder noget
for dig, så skriv til **[contact@live.tips](mailto:contact@live.tips)** — den adresse når
frem til et menneske.

Denne politik er ærlig om de kedelige dele. Vi siger hellere “vi gemmer dit navn i op til
en time” end at påstå, at vi ikke gemmer noget, og tage fejl.

## Den korte version

- **Ingen konti.** Der er ikke noget at melde sig til.
- **Ingen cookies.** Ikke én, ingen steder.
- **Ingen analyseværktøjer, ingen sporing, ingen reklamer, ingen tredjepartsscripts** på
  dette website.
- **Vi rører aldrig dine penge.** Drikkepenge går direkte fra fanen til kunstnerens egen
  Stripe-, Revolut-, MobilePay- eller Monzo-konto. Vi er ikke i den vej.
- **I standardopsætningen taler appen kun med Stripe** — ikke med nogen live.tips-server.
- Den eneste server, vi overhovedet driver, er et lille relæ, og det findes kun, hvis en
  kunstner slår Revolut, MobilePay eller Monzo til.

## Dette website

Siden er statisk og hostet på **GitHub Pages**. Som host modtager GitHub IP-adressen og
browserens user-agent for alle, der indlæser en side — det er ganske almindelig
webserverlogning, det sker, før noget af vores kode kører, og vi kan ikke slå det fra.
GitHub behandler det under sin egen
[privatlivserklæring](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Vi læser ikke de logfiler, og GitHub viser os dem ikke.

Ud over det indlæser de sider, du læser, **intet fra nogen anden**: skrifttyper, ikoner og
billeder leveres fra live.tips selv. Der er ingen Google Analytics, ingen tag manager,
ingen pixel, ingen indlejret widget.

Siden gemmer **to værdier i din browsers `localStorage`**, begge sat af dig, begge kun
læsbare af denne side, og ingen af dem sendes nogensinde nogen steder hen:

| Nøgle | Hvad den husker |
| --- | --- |
| `lt-landing-theme` | om du valgte lyse, mørke eller automatiske farver |
| `lt-langbar-dismissed` | at du lukkede banneret “findes også på dit sprog” |

Rydder du din browserlagring, slettes de. De er ikke cookies, de deles ikke, og de
identificerer ingen.

## Appen

live.tips-appen kører **på kunstnerens egen enhed**. Alt, hvad den ved, bor der:

- Den **begrænsede Stripe-nøgle** gemmes i enhedens nøglering (iOS/macOS Keychain,
  Android Keystore) og sendes kun nogensinde til `api.stripe.com`.
- **Drikkepengehistorik, sessionshistorik, målet og appens indstillinger** gemmes i lokal
  lagring på enheden. Det inkluderer de navne og hilsner, som fans knytter til deres
  drikkepenge.
- Afinstallerer du appen, slettes det hele. Der er ingen cloud-backup hos os, fordi der
  ikke er nogen cloud hos os.

**Vi modtager aldrig noget af dette.** Appen leveres uden analyse-SDK, uden
crash-rapportering, uden push-notifikationer og uden reklamekode — ingen, heller ikke
deaktiverede.

To præciseringer, så påstanden om, at appen “taler med ingen”, forbliver præcis sand:

- Appen henter **valutakurser** én gang om dagen fra offentlige kurs-API'er
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Det er helt almindelige
  forespørgsler efter en offentlig liste over kurser. De bærer ingen oplysninger om dig,
  kunstneren eller nogen drikkepenge — men ligesom enhver webforespørgsel afslører de din
  IP-adresse over for de tjenester.
- Bruger du **browserversionen** af appen, henter din browser den fra vores statiske host
  (se *Dette website* ovenfor).

## Stripe

Når en fan betaler med kort, er vedkommende på **Stripes** betalingsside, ikke vores.
Stripe indsamler og behandler deres betalingsdata som selvstændig dataansvarlig under
[Stripes privatlivspolitik](https://stripe.com/privacy). Vi ser aldrig kortnumre, og vi har
ingen adgang til kunstnerens Stripe-konto.

Kunstnerens app læser kunstnerens egne drikkepenge fra Stripe med kunstnerens egen
begrænsede nøgle. En fans navn og hilsen, hvis der er efterladt nogen, rejser fra Stripe
til kunstnerens enhed og stopper der.

## Relæet — kun hvis Revolut, MobilePay eller Monzo er slået til

Opsætninger med kun Stripe rører aldrig dette og kan stoppe med at læse her.

Revolut, MobilePay og Monzo tilbyder ingen måde, hvorpå en app kan bekræfte, at en
betaling er sket, så de drikkepenge sendes gennem et lille open source-relæ, som vi driver
på **Cloudflare** på `api.live.tips`. Det rører aldrig penge. Her er alt, hvad det
håndterer.

### Hvad kunstneren gemmer

At oprette en drikkepengeside gemmer kunstnerens **visningsnavn, deres offentlige hilsen,
deres valuta og de betalingsoplysninger, de har valgt at offentliggøre** (deres
Stripe-betalingslink, Revolut-brugernavn, MobilePay Box-ID, Monzo-brugernavn). Det hele er
oplysninger, som kunstneren alligevel bevidst offentliggør over for sine fans.

- **Opbevaring: slettes automatisk efter 90 dages inaktivitet.**
- Kunstneren kan slette det **med det samme** fra appen, når som helst.
- Der indsamles aldrig e-mailadresse, adgangskode, juridisk navn eller bankoplysninger.

### Hvad en fan sender

Drikkepengeformularen beder om et **beløb** og valgfrit et **navn** og en **hilsen**. Det er
hele formularen. Ingen e-mail, intet telefonnummer, ingen konto.

- Er kunstnerens skærm **online**, sendes drikkepengene direkte videre til den og
  **skrives aldrig til disk**.
- Er kunstnerens skærm **offline** — telefonen låst, intet signal — **holdes drikkepengene i
  lagring i op til en time**, så de ikke bare går tabt, og overleveres så i det øjeblik,
  skærmen forbinder igen. Forbinder ingen igen, **slettes de uset**. Dette er den eneste
  fan-skrevne tekst, relæet nogensinde gemmer, og en time er den absolutte grænse.
- Dit navn og din hilsen placeres også i den **betalingsnote**, der åbner i Revolut,
  MobilePay eller Monzo — det er sådan, kunstneren ved, hvem der gav drikkepenge. De
  selskaber behandler det derefter under deres egne privatlivspolitikker.
- Relæet gemmer **ingen drikkepengehistorik**. Det kan ikke vise dig, os eller nogen anden
  en liste over, hvem der har givet drikkepenge til hvem.

### IP-adresser og misbrugsbeskyttelse

En åben formular, som hvem som helst kan sende til, kræver en vis beskyttelse mod bots, så:

- Din IP-adresse bruges til at **rate-limite** forespørgsler og sendes til **Cloudflare
  Turnstile** (et anti-bot-tjek, der kører på drikkepengesiden) for at verificere, at du
  ikke er en bot. Turnstile er Cloudflares produkt og bruges i stedet for en CAPTCHA, der
  profilerer dig.
- For at forhindre nogen i at oprette tusindvis af drikkepengesider gemmes et
  **kryptografisk hash af IP-adressen** på den, der opretter en, i cirka **to timer** og
  kasseres derefter.
- **Cloudflares driftslogfiler** registrerer de tekniske detaljer om forespørgsler til
  relæet — URL, tidspunkt, status — i nogle få dage. De indeholder ikke fans' navne eller
  hilsner. Cloudflare fungerer som vores databehandler; se
  [Cloudflares privatlivspolitik](https://www.cloudflare.com/privacypolicy/).

### Tællere

Relæet tæller, **hvor mange drikkepenge** en given drikkepengeside har videresendt, så vi
kan opdage misbrug og vide, om tingen overhovedet bliver brugt. Det er et tal. Det
indeholder ingen fan-data.

## Retsgrundlag, hvis du har brug for et (GDPR)

- At drive relæet for en kunstner, der har slået det til, og at levere en fans drikkepenge
  til den skærm, de var rettet mod: **opfyldelse af en tjeneste, du har bedt om**.
- Rate limiting, Turnstile og kvoter baseret på hashede IP-adresser: **legitim interesse** i
  at forhindre, at en gratis, åben tjeneste ødelægges af bots og svindel.
- Serverlogfiler: **legitim interesse** i at drive og sikre tjenesten.

## Dine rettigheder

Du kan bede os om at give dig en kopi af, rette eller slette alt, hvad vi har om dig, og du
kan klage til din nationale databeskyttelsesmyndighed. Skriv til
**[contact@live.tips](mailto:contact@live.tips)**.

I praksis er det meste allerede i dine egne hænder: kunstnere kan slette deres
drikkepengeside fra appen med det samme, fans' drikkepenge fordamper inden for en time, og
alt andet bor på din egen enhed.

## Børn

live.tips er ikke rettet mod børn, og vi behandler ikke bevidst deres data.

## Ændringer

Vi opdaterer denne side, når softwaren ændrer sig. Fordi hele projektet er open source,
ligger **hver eneste tidligere version af denne politik i den offentlige git-historik** — du
kan se præcis, hvad der ændrede sig, og hvornår.

## Sprog

Denne politik udgives på alle de sprog, siden understøtter, som en service. Hvis en
oversættelse og den engelske version er uenige, er **det den engelske version, der
gælder**.
