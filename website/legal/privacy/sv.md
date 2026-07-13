---
title: Integritetspolicy
description: live.tips har inga kakor, ingen analys och ingen spårning, och fungerar helt utan konto. Om du väljer att logga in — här är exakt vad som lagras, var, av vem och hur länge.
updated: 2026-07-13
updated_label: Senast uppdaterad 13 juli 2026
---

live.tips är en dricksburk med öppen källkod för artister. Den drivs av **Nikita Rabykin**, en
enskild utvecklare, inte ett företag. Om något nedan spelar roll för dig, skriv till
**[contact@live.tips](mailto:contact@live.tips)** — den adressen når en människa.

Den här policyn är ärlig även om de tråkiga delarna. Vi säger hellre ”vi sparar ditt
namn i upp till en timme” än påstår att vi inte sparar något och har fel.

## Den korta versionen

- **Ett konto är valfritt.** Appen fungerar helt utan konto, och det är fortfarande
  standardläget. Vill du ha dina band och din historik på en andra enhet kan du logga in — och
  då lagras en del av det på en server. Vad som är vad framgår nedan.
- **Inga kakor.** Inte en enda, någonstans.
- **Ingen analys, ingen spårning, inga annonser, inga tredjepartsskript** på den här webbplatsen.
- **Vi rör aldrig dina pengar.** Dricksen går direkt från fansen till artistens eget
  konto hos Stripe, Revolut, MobilePay eller Monzo. Vi finns inte i den vägen.
- **I standarduppsättningen pratar appen bara med Stripe** — inte med någon live.tips-server.
- Den enda server vi över huvud taget kör är ett litet relä på Googles **Firebase**. Det finns
  där ifall en artist slår på Revolut, MobilePay eller Monzo — eller loggar in.

## Den här webbplatsen

Webbplatsen är statisk och ligger hos **GitHub Pages**. Som värd tar GitHub emot
IP-adressen och webbläsarens user-agent från alla som laddar en sida — det är vanlig
webbserverloggning, det sker innan någon av våra rader kod körs, och vi kan inte stänga av det.
GitHub behandlar detta enligt sitt eget
[integritetsmeddelande](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Vi läser inte de loggarna och GitHub visar dem inte för oss.

Utöver det laddar sidorna du läser **ingenting från någon annan**: typsnitt, ikoner
och bilder levereras från live.tips självt. Det finns ingen Google Analytics, ingen tag
manager, ingen pixel, ingen inbäddad widget.

Webbplatsen sparar **två värden i webbläsarens `localStorage`**, båda satta av dig, båda
läsbara endast av den här webbplatsen, och ingetdera skickas någonsin någonstans:

| Nyckel | Vad den kommer ihåg |
| --- | --- |
| `lt-landing-theme` | om du valde ljusa, mörka eller automatiska färger |
| `lt-langbar-dismissed` | att du stängde bannern ”finns också på ditt språk” |

Att rensa webbläsarens lagring raderar dem. De är inte kakor, de delas inte, och de
identifierar ingen.

## Appen har två lägen, och skillnaden mellan dem är hela historien

Allt nedan hänger på en enda fråga: **har du loggat in?**

### Läge ett — inget konto. Fortfarande standard, fortfarande oförändrat.

Appen körs **på artistens egen enhet**, och allt den vet finns där:

- Den **begränsade Stripe-nyckeln** sparas i enhetens nyckelring (iOS/macOS Keychain,
  Android Keystore) och skickas aldrig någon annanstans än till `api.stripe.com`.
- **Drickshistorik, sessionshistorik, målet och appens inställningar** sparas i lokal
  lagring på enheten. Det inkluderar namnen och hälsningarna som fansen bifogar sin dricks.
- Att avinstallera appen raderar alltihop. Det finns ingen molnbackup hos oss, för
  i det här läget finns det inget moln hos oss.

**Vi tar aldrig emot något av detta.** Appen levereras utan analys-SDK, utan
kraschrapportering, utan pushnotiser och utan annonskod — ingen alls, inte ens avstängd.

Två förtydliganden, så att påståendet ”pratar med ingen” förblir exakt sant:

- Appen hämtar **växelkurser** en gång om dagen från publika kurs-API:er
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Det är enkla
  förfrågningar om en offentlig lista över kurser. De bär ingen information om dig, artisten
  eller någon dricks — men, som varje webbförfrågan, avslöjar de din IP-adress för de
  tjänsterna.
- Om du använder **webbläsarversionen** av appen laddar din webbläsare ned den från vår
  statiska värd (se *Den här webbplatsen* ovan).

### Läge två — du loggade in. Då lämnar en del data enheten, med avsikt.

Att logga in är en medveten handling. Ingenting loggar in dig åt dig, och ingenting i appen
slutar fungera om du aldrig gör det. Du loggar in för att du vill ha en andra enhet: telefonen
i fickan och plattan på scen som visar samma kväll, samma band, samma historik.

Det fungerar bara om en server håller dem. **Så det gör den, och det är den ärliga kostnaden
för den andra enheten.**

Servern är **Firebase**, alltså Google. Det finns tre sätt att ha ett konto:

- **Logga in med Apple** eller **logga in med Google** — Firebase Auth tar emot vad
  leverantören lämnar över: ett användar-id (uid) och, oftast, en e-postadress och ett namn.
  (Med Apple kan du dölja din e-post; Apple ger oss då en reläadress i stället.)
- **Ett gästkonto** — ett anonymt konto utan e-post och utan namn. Det synkar och det kan
  återkallas, men det finns inget att återställa det med om du tappar enheten. Det är ett uid
  och inget mer.

När du väl är inloggad får kontot sitt eget privata hörn i Googles databas **Cloud
Firestore**, på `users/<your uid>/`. Säkerhetsreglerna ger det hörnet till det uid:et **och
till ingen annan** — inget annat konto kan läsa det, inte heller genom att gissa URL:er.
Därinne:

| Vad | Varför det finns där |
| --- | --- |
| Dina **band** — namn, inställningar för dricksburk och betalsätt, affischtext, mål | så att ett band finns på varje enhet du loggar in på |
| Din **begränsade Stripe-nyckel** och reläets hemlighet för drickssidan | i ett hemlighetsdokument som bara ditt uid kan läsa, och cachad i nyckelringen på var och en av dina enheter |
| **Appinställningar** | så att en enhet du lägger till redan är konfigurerad |
| **Sessionsposter och drickshistorik** — inklusive **namnen och hälsningarna som fansen bifogar sin dricks** | eftersom den historiken är precis vad du bad om att få se på den andra enheten |
| Den **livesession** som pågår just nu | så att en andra skärm kan haka på kvällens set |
| Dina **enheter** — namnet var och en ger sig själv (”Nikitas iPhone”), dess plattform och modell, när den sågs första och senaste gången | så att Inställningar → Säkerhet kan lista dem, och du kan återkalla en |
| Ett litet **profildokument** — kontonamnet du valde, och vilken leverantör du använde | så att kontoväxlaren kan sätta en etikett på det |

Och nu det viktiga, rakt ut: **utan konto lämnar ett fans namn och hälsning aldrig artistens
enhet. Med konto lagras de på Googles servrar under artistens uid, som en del av den artistens
egen synkade historik.** Inget annat konto kan läsa dem, vi tittar inte på dem, och ingenting
härleds ur dem — men de finns där, och det bör du veta innan du loggar in.

Att logga ut sätter tillbaka enheten i det lokala läget. Det raderar inte kontots data — se
*Att radera saker* nedan.

### Att lägga till en enhet med QR-kod

För att lägga till en enhet visar du en QR-kod från en enhet som redan är inloggad. Koden är
slumpmässig, **kan bara användas en gång, och går ut efter två minuter**, och den nya enheten
får ingenting förrän du trycker *bekräfta* på den gamla. Medan den handskakningen är öppen
håller vi koden, namnet den nya enheten gav sig själv, och dess plattform — och posten raderas
när koden går ut. En fotograferad QR-kod är värdelös utan din bekräftande tryckning.

## Var allt detta fysiskt finns

Firebase Auth, Cloud Firestore och våra Cloud Functions körs i **Europeiska unionen** —
databasen i Googles multiregion `eur3`, funktionerna i `europe-west1`. Google agerar som vårt
personuppgiftsbiträde enligt
[Firebases integritets- och säkerhetsvillkor](https://firebase.google.com/support/privacy) och
sin egen [integritetspolicy](https://policies.google.com/privacy). Som varje stor leverantör
kan Google involvera infrastruktur utanför EU för support och säkerhet; det styrs av de
villkoren, inte av oss.

## Stripe

När ett fan betalar med kort befinner de sig på **Stripes** kassasida, inte vår. Stripe
samlar in och behandlar deras betalningsuppgifter som självständig personuppgiftsansvarig enligt
[Stripes integritetspolicy](https://stripe.com/privacy). Vi ser aldrig kortnummer, och vi
har ingen åtkomst till artistens Stripe-konto.

Artistens app läser artistens egen dricks från Stripe med artistens egen begränsade nyckel —
rakt från enheten till `api.stripe.com`. **Det finns ingen live.tips-server i den vägen, och
det har det aldrig funnits.** Ett fans namn och hälsning, om de lämnade någon, färdas från
Stripe till artistens enhet och stannar där — såvida inte artisten loggat in, och då sparar
enheten dem också i den artistens egen Firestore-historik, enligt ovan.

## Reläet — bara om Revolut, MobilePay eller Monzo är påslagna

Uppsättningar med enbart Stripe rör aldrig detta.

Revolut, MobilePay och Monzo erbjuder inget sätt för en app att bekräfta att en betalning skett,
så den dricksen dirigeras genom ett litet relä med öppen källkod som vi kör på **Firebase** —
Cloud Functions och Firestore i `europe-west1`, med fansens drickssida serverad från
**`tip.live.tips/t/<id>`**. Det rör aldrig pengar. Här är allt det hanterar.

### Vad artisten lagrar

Att skapa en drickssida lagrar artistens **visningsnamn, deras publika hälsning, deras
valuta och de betalningsidentifierare de valt att publicera** (deras Stripe-betallänk,
Revolut-användarnamn, MobilePay Box-ID, Monzo-användarnamn). Allt det är information som artisten
ändå medvetet publicerar för sina fans.

- **Lagringstid: en drickssida utan konto bakom sig raderas automatiskt efter 90 dagars
  inaktivitet.** En drickssida som tillhör ett inloggat konto lever så länge som det band den
  hör till.
- Artisten kan radera den **omedelbart** från appen, när som helst.
- Ingen e-postadress, inget lösenord, inget juridiskt namn, inga bankuppgifter samlas in här.
- Sidans hemlighet lagras **bara som en hash**. Vi skulle inte kunna berätta hemligheten för dig
  om du bad om den; vi kan bara kontrollera en.

### Vad ett fan skickar

Dricksformuläret frågar efter ett **belopp**, och valfritt ett **namn** och en **hälsning**. Det är
hela formuläret. Ingen e-post, inget telefonnummer, inget konto.

- Dricksen skrivs till en **leveranskö** — ett enda dokument som finns till för att lämnas över
  till artistens skärm. När skärmen visar dricksen **raderar artistens enhet det dokumentet.**
  Raderingen *är* kvittensen; det finns ingen flagga för ”levererad”, för det finns ingen post
  kvar att flagga.
- Om artistens skärm är offline — låst telefon, ingen täckning — **väntar dricksen i den kön i
  upp till en timme**, så att den inte helt enkelt går förlorad, och lämnas över i samma ögonblick
  som skärmen återansluter. Om ingen återansluter **raderas den osedd**, sopad bort på schema
  vare sig någon någonsin kom tillbaka efter den eller inte.
- **Den kön är det enda ställe där fanskriven text någonsin lagras på vår server, och en timme är
  dess absoluta gräns.** Om artisten är inloggad behåller deras enhet sedan dricksen i *deras*
  Firestore-historik — för det är deras historik, och det är den de loggade in för.
- Ditt namn och din hälsning placeras också i den **betalningsnot** som öppnas i Revolut,
  MobilePay eller Monzo — det är så artisten vet vem som gav dricks. Dessa företag
  behandlar den sedan enligt sina egna integritetspolicyer.
- Reläet sparar **ingen drickshistorik**. Det kan inte visa dig, oss eller någon annan en lista över
  vem som gav dricks till vem.

### IP-adresser och missbruksskydd

Ett öppet formulär som vem som helst kan skicka till behöver visst skydd mot bottar, så:

- Din IP-adress skickas till **Cloudflare Turnstile** — en bottkontroll som körs på drickssidan —
  för att verifiera att du inte är en bott. Turnstile är Cloudflares produkt och används i stället
  för en CAPTCHA som profilerar dig. Turnstile och vår DNS är det enda Cloudflare fortfarande gör
  för oss; själva reläet körs numera på Firebase. Se
  [Cloudflares integritetspolicy](https://www.cloudflare.com/privacypolicy/).
- Din IP används också för att **begränsa antalet förfrågningar** (rate limiting) — att skicka en
  dricks, att skapa en drickssida, att lösa in en kod för att lägga till en enhet. Det vi sparar
  för det är en **saltad kryptografisk hash av IP-adressen**, aldrig IP-adressen själv, i ungefär
  **två timmar**, och sedan raderas den. Saltet är en serverhemlighet: utan det vägrar koden att
  lagra något alls, snarare än att behålla en hash som skulle kunna vändas tillbaka.
- **Googles driftloggar** registrerar de tekniska detaljerna kring förfrågningar till reläet
  — URL, tidpunkt, status — i några dagar. Vår kod loggar med avsikt inga namn, inga hälsningar,
  inga hemligheter och inga headers. Google agerar som vårt personuppgiftsbiträde.

### Räknare

Reläet räknar **hur många dricksar** en viss drickssida har vidarebefordrat, så att vi kan upptäcka missbruk och
veta om saken används över huvud taget. Det är en siffra. Den innehåller inga fandata.

## Vem behandlar vad

| Vem | Vad de får | Varför |
| --- | --- | --- |
| **Google (Firebase)** | Konton, en inloggad artists synkade data, reläet, serverloggar | Det valfria kontot och det valfria reläet |
| **Stripe** | Fansens betalningsuppgifter, som självständig personuppgiftsansvarig | Kortdricks |
| **Cloudflare** | Fansens IP, för Turnstile-kontrollen på drickssidan. Och vår DNS. | Att hålla bottar borta från dricksformuläret |
| **GitHub** | IP-adress och user-agent för alla som laddar den här webbplatsen | Att hosta webbplatsen |
| **Revolut / MobilePay / Monzo** | Vad fanset än gör i deras egen app, betalningsnoten inkluderad | De betalsätten |

Vi säljer ingenting till någon, och det finns ingen annan på den listan.

## Rättslig grund, om du behöver en (GDPR)

- Att köra ett konto du bett om, att synka dina egna data till dina egna enheter, att köra reläet
  för en artist som slagit på det, och att leverera ett fans dricks till den skärm den var riktad
  mot: **utförande av en tjänst du bett om**.
- Rate limiting, Turnstile, kvoter baserade på hashade IP-adresser och återkallande av enheter:
  **berättigat intresse** av att hålla en gratis, öppen tjänst från att förstöras av bottar och
  bedrägeri, och av att hålla artisters konton säkra.
- Serverloggar: **berättigat intresse** av att driva och säkra tjänsten.

## Att radera saker

Det här spelar större roll än något löfte vi skulle kunna ge om det, så här är exakt vad som finns
i dag — inklusive vad som inte gör det.

- **Inget konto**: avinstallera appen. Det var alltihop, borta.
- **Ett band**: att ta bort ett band i appen raderar det bandets molndata — dess inställningar,
  dess nycklar, dess sessioner, dess drickshistorik — tillsammans med kopian på enheten.
- **En drickssida**: radera eller återskapa den i appen så torkas den bort från reläet på en gång,
  inklusive eventuell väntande dricks.
- **En enhet**: Inställningar → Säkerhet listar dina enheter. Du kan återkalla en, eller logga ut
  överallt annars — vilket avslutar varje annan enhets session omedelbart, inte så småningom.
- **Hela ditt konto, med en tryckning: den knappen har appen inte ännu.** Vi erkänner det hellre
  än låtsas något annat. Tills den finns, skriv till
  **[contact@live.tips](mailto:contact@live.tips)** så raderar vi kontot och allt under det, för
  hand. Under tiden kan du redan radera varje band, vilket tar bort allt av substans och lämnar
  ett tomt konto kvar.

## Dina rättigheter

Du kan be oss ge dig en kopia av, rätta eller radera allt vi har om dig, och
du kan klaga hos din nationella dataskyddsmyndighet. Skriv till
**[contact@live.tips](mailto:contact@live.tips)**.

I praktiken ligger det mesta redan i dina händer: en artist kan radera en drickssida eller ett
band från appen direkt, ej levererad fandricks dunstar bort inom en timme, och om du aldrig
loggar in har inget av det någonsin funnits någon annanstans än på din egen enhet.

## Barn

live.tips riktar sig inte till barn och vi behandlar inte medvetet deras uppgifter.

## Ändringar

Vi uppdaterar den här sidan när programvaran ändras. Eftersom hela projektet är öppen
källkod finns **varje tidigare version av den här policyn i den publika git-historiken** — du kan
se exakt vad som ändrades och när.

## Språk

Den här policyn publiceras på alla språk webbplatsen stöder, som en service. Om en
översättning och den engelska versionen inte stämmer överens är **den engelska versionen den som
gäller**.
