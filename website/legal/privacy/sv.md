---
title: Integritetspolicy
description: live.tips har inga konton, inga kakor, ingen analys och ingen spårning. Här är den korta listan över vad som faktiskt behandlas, av vem och hur länge.
updated: 2026-07-13
updated_label: Senast uppdaterad 13 juli 2026
---

live.tips är en dricksburk med öppen källkod för artister. Den drivs av **Nikita Rabykin**, en
enskild utvecklare, inte ett företag. Om något nedan spelar roll för dig, skriv till
**[contact@live.tips](mailto:contact@live.tips)** — den adressen når en människa.

Den här policyn är ärlig även om de tråkiga delarna. Vi säger hellre ”vi sparar ditt
namn i upp till en timme” än påstår att vi inte sparar något och har fel.

## Den korta versionen

- **Inga konton.** Det finns inget att registrera sig för.
- **Inga kakor.** Inte en enda, någonstans.
- **Ingen analys, ingen spårning, inga annonser, inga tredjepartsskript** på den här webbplatsen.
- **Vi rör aldrig dina pengar.** Dricksen går direkt från fansen till artistens eget
  konto hos Stripe, Revolut, MobilePay eller Monzo. Vi finns inte i den vägen.
- **I standarduppsättningen pratar appen bara med Stripe** — inte med någon live.tips-server.
- Den enda server vi över huvud taget kör är ett litet relä, och det existerar bara om en
  artist slår på Revolut, MobilePay eller Monzo.

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

## Appen

live.tips-appen körs **på artistens egen enhet**. Allt den vet finns där:

- Den **begränsade Stripe-nyckeln** sparas i enhetens nyckelring (iOS/macOS Keychain,
  Android Keystore) och skickas aldrig någon annanstans än till `api.stripe.com`.
- **Drickshistorik, sessionshistorik, målet och appens inställningar** sparas i lokal
  lagring på enheten. Det inkluderar namnen och hälsningarna som fansen bifogar sin dricks.
- Att avinstallera appen raderar alltihop. Det finns ingen molnbackup hos oss, för
  det finns inget moln hos oss.

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

## Stripe

När ett fan betalar med kort befinner de sig på **Stripes** kassasida, inte vår. Stripe
samlar in och behandlar deras betalningsuppgifter som självständig personuppgiftsansvarig enligt
[Stripes integritetspolicy](https://stripe.com/privacy). Vi ser aldrig kortnummer, och vi
har ingen åtkomst till artistens Stripe-konto.

Artistens app läser artistens egen dricks från Stripe med artistens egen begränsade nyckel.
Ett fans namn och hälsning, om de lämnade någon, färdas från Stripe till artistens enhet
och stannar där.

## Reläet — bara om Revolut, MobilePay eller Monzo är påslagna

Uppsättningar med enbart Stripe rör aldrig detta, och kan sluta läsa här.

Revolut, MobilePay och Monzo erbjuder inget sätt för en app att bekräfta att en betalning skett,
så den dricksen dirigeras genom ett litet relä med öppen källkod som vi kör på **Cloudflare** på
`api.live.tips`. Det rör aldrig pengar. Här är allt det hanterar.

### Vad artisten lagrar

Att skapa en drickssida lagrar artistens **visningsnamn, deras publika hälsning, deras
valuta och de betalningsidentifierare de valt att publicera** (deras Stripe-betallänk,
Revolut-användarnamn, MobilePay Box-ID, Monzo-användarnamn). Allt det är information som artisten
ändå medvetet publicerar för sina fans.

- **Lagringstid: raderas automatiskt efter 90 dagars inaktivitet.**
- Artisten kan radera den **omedelbart** från appen, när som helst.
- Ingen e-postadress, inget lösenord, inget juridiskt namn, inga bankuppgifter samlas någonsin in.

### Vad ett fan skickar

Dricksformuläret frågar efter ett **belopp**, och valfritt ett **namn** och en **hälsning**. Det är
hela formuläret. Ingen e-post, inget telefonnummer, inget konto.

- Om artistens skärm är **online** skickas dricksen rakt igenom till den och
  **skrivs aldrig till disk**.
- Om artistens skärm är **offline** — låst telefon, ingen täckning — **hålls dricksen i
  lagring i upp till en timme** så att den inte helt enkelt går förlorad, och lämnas sedan över i samma ögonblick som
  skärmen återansluter. Om ingen återansluter **raderas den osedd**. Detta är den enda
  fanskrivna text som reläet någonsin lagrar, och en timme är dess absoluta gräns.
- Ditt namn och din hälsning placeras också i den **betalningsnot** som öppnas i Revolut,
  MobilePay eller Monzo — det är så artisten vet vem som gav dricks. Dessa företag
  behandlar den sedan enligt sina egna integritetspolicyer.
- Reläet sparar **ingen drickshistorik**. Det kan inte visa dig, oss eller någon annan en lista över
  vem som gav dricks till vem.

### IP-adresser och missbruksskydd

Ett öppet formulär som vem som helst kan skicka till behöver visst skydd mot bottar, så:

- Din IP-adress används för att **begränsa antalet förfrågningar** (rate limiting), och skickas till **Cloudflare
  Turnstile** (en bottkontroll som körs på drickssidan) för att verifiera att du inte är en bott.
  Turnstile är Cloudflares produkt och används i stället för en CAPTCHA som profilerar dig.
- För att hindra någon från att skapa tusentals drickssidor sparas en **kryptografisk hash av IP-adressen** för
  den som skapar en, i ungefär **två timmar**, och kastas sedan.
- **Cloudflares driftloggar** registrerar de tekniska detaljerna kring förfrågningar till reläet
  — URL, tidpunkt, status — i några dagar. De innehåller inte fansens namn eller hälsningar.
  Cloudflare agerar som vårt personuppgiftsbiträde; se
  [Cloudflares integritetspolicy](https://www.cloudflare.com/privacypolicy/).

### Räknare

Reläet räknar **hur många dricksar** en viss drickssida har vidarebefordrat, så att vi kan upptäcka missbruk och
veta om saken används över huvud taget. Det är en siffra. Den innehåller inga fandata.

## Rättslig grund, om du behöver en (GDPR)

- Att köra reläet för en artist som slagit på det, och att leverera ett fans dricks till den
  skärm den var riktad mot: **utförande av en tjänst du bett om**.
- Rate limiting, Turnstile och kvoter baserade på hashade IP-adresser: **berättigat intresse** av att hålla en
  gratis, öppen tjänst från att förstöras av bottar och bedrägeri.
- Serverloggar: **berättigat intresse** av att driva och säkra tjänsten.

## Dina rättigheter

Du kan be oss ge dig en kopia av, rätta eller radera allt vi har om dig, och
du kan klaga hos din nationella dataskyddsmyndighet. Skriv till
**[contact@live.tips](mailto:contact@live.tips)**.

I praktiken ligger det mesta redan i dina händer: artister kan radera sin drickssida från
appen direkt, fansens dricks dunstar bort inom en timme, och allt annat lever på din
egen enhet.

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
