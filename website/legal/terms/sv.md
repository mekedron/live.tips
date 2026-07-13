---
title: Användarvillkor
description: live.tips är fri programvara med öppen källkod. Vi är inte en betaltjänst, vi håller aldrig dina pengar, och vi lovar inget om dricks vi inte kan se. Detaljerna, i klarspråk.
updated: 2026-07-13
updated_label: Senast uppdaterad 13 juli 2026
---

Dessa villkor omfattar live.tips-appen, den här webbplatsen, det valfria live.tips-**kontot**
och det valfria reläet bakom drickssidorna på `tip.live.tips`. live.tips drivs av **Nikita
Rabykin**, en enskild utvecklare — inte ett företag, inte ett team — och släpps som fri
programvara med öppen källkod under
[MIT-licensen](https://github.com/mekedron/live.tips/blob/main/LICENSE).

Genom att använda live.tips accepterar du det som följer. Det är kort, för live.tips gör mycket
lite å dina vägnar — och det är hela poängen.

## Vad live.tips är

live.tips är **programvara du kör själv**. Den förvandlar ditt eget Stripe-konto (eller Revolut,
MobilePay, Monzo) till en live-dricksburk med en QR-kod och en skärm som fylls
medan fansen ger dricks.

## Vad live.tips inte är

**Vi är inte en betaltjänst, en bank, en depositionstjänst eller en part i dina transaktioner.** Vi
håller, dirigerar eller rör aldrig någons pengar. En dricks färdas direkt från fanset till
artistens eget betalkonto. Det finns inget live.tips-saldo i mitten, för det finns inget
live.tips-saldo alls.

Konkret betyder det:

- Vi tar **ingen provision** och tar ut **ingen avgift**. Det finns inget att betala oss.
- Vi **kan inte återbetala en dricks**, för vi har aldrig haft den. Återbetalningar hör till artisten och
  dennes betaltjänstleverantör.
- Vi **kan inte se, frysa, återkalla eller återskapa** någon betalning.
- Din relation för själva pengarna är med **Stripe, Revolut, MobilePay eller Monzo**,
  enligt deras villkor — inte med oss.

## Dricks är betalning för en föreställning

Dricks som samlas in genom live.tips är **frivilliga betalningar till en artist för dennes
liveframträdande**. Det är **inte välgörenhetsgåvor**, och live.tips är inte en
insamlingsplattform. Artister måste beskriva sin verksamhet för sin betaltjänstleverantör därefter —
Stripe, i synnerhet, behandlar framträdanden och insamlingar som olika saker, och bara
det ena av dem är du.

## Konton

Ett konto är **valfritt**, och det finns fortfarande ingenting du måste registrera dig för. Appen
fungerar helt utan konto — det är standardläget, allt stannar på din enhet, och ingen
live.tips-server är inblandad.

Vill du ha dina band, inställningar och din historik på mer än en enhet kan du logga in med
**Apple**, med **Google**, eller som anonym **gäst**. Ett konto är en plats att förvara *dina egna*
data på, hos **Firebase** (Google), läsbara av ditt konto och av inget annat. Vad det innehåller —
och vad inloggningen ändrar för din integritet — framgår av Integritetspolicyn, som är värd att
läsa innan du loggar in.

Om du har ett konto:

- **Det är ditt att sköta om.** Var och en som kan logga in som du ser allt i det. Håll din
  inloggningsmetod säker, och använd **Inställningar → Säkerhet** för att granska dina enheter,
  återkalla en, eller logga ut överallt annars.
- **Ett gästkonto kan inte återställas.** Det har ingen e-post och inget lösenord. Tappa varje
  enhet som är inloggad på det och dess data är borta — det är bytet mot att logga in utan att ge
  oss något. Använd Apple eller Google om det spelar roll för dig.
- **Du ansvarar för vad som finns i det** — dina bandnamn, dina publika hälsningar, och allt annat
  du lägger där.
- **Att lägga till en enhet kräver din bekräftelse** på en enhet som redan är inloggad. Bekräfta
  inte en enhet du inte bett om, och låt inte någon fotografera QR-koden och tryck sedan bekräfta
  ändå.
- **Vi kan stänga av eller radera ett konto** — se *Att avsluta det*, nedan.

## Om du är artist

Du ansvarar för:

- **Ditt eget betalkonto** — att hålla det i gott skick och följa Stripes eller
  Revoluts, MobilePays eller Monzos regler.
- **Din skatt.** Dricks är inkomst. Vi rapporterar ingenting till någon, utfärdar inget
  skatteunderlag och vet inte vad du tjänat.
- **Återbetalningar, tvister och chargebacks**, som du hanterar i din egen betalpanel.
- **Lagen där du uppträder** — gatumusiktillstånd, lokalens regler och allt annat lokalt.
- **Vad du publicerar.** Ditt artistnamn och din hälsning visas på en publik drickssida; håll dem
  lagliga och dina egna.
- **Din Stripe-nyckel.** Det är en begränsad nyckel du själv skapat, och den bor på din enhet — och,
  om du loggar in, i ditt kontos privata lagring också, så att dina andra enheter kan använda den.
  Hur som helst är den din: behandla enheten som du skulle behandla kontanter, och återkalla nyckeln
  i din Stripe-panel om en enhet försvinner.
- **Dina band, och fanhälsningarna du sätter upp på skärmen.** Ett namn och en hälsning visas för
  ett rum fullt av människor. Vad som dyker upp på den skärmen är ditt att moderera.

## Om du är fan

- Att ge dricks är **frivilligt** och, när den väl skickats, är en dricks i regel **slutgiltig** — en livedricks är
  inte ett köp med ångerrätt.
- Om något gick fel med en betalning, ta upp det med **artisten** eller med den
  betaltjänstleverantör som behandlade den. Vi har ingen uppgift om den och ingen makt över den.
- Håll namnet och hälsningen du bifogar lagliga och hyfsade. De visas på en
  skärm, på scenen, framför ett rum fullt av människor.

## Overifierad dricks — läs den här

Revolut, MobilePay och Monzo ger en app **inget sätt att bekräfta att en betalning faktiskt
skett**. En dricks som skickas via de metoderna dyker upp på artistens skärm **i samma ögonblick som
fanset skickar formuläret** — vare sig de sedan genomför betalningen eller inte.

live.tips märker sådan dricks som **overifierad**, och det betyder exakt det: *någon sa
att de betalat.* Det är en scenaffekt, inte ett kvitto.

**Behandla aldrig en overifierad dricks som betalningsbevis.** Artister måste stämma av mot
sin egen Revolut-, MobilePay- eller Monzo-app. Dricks via Stripe är den enda live.tips faktiskt
kan bekräfta, och det är därför Stripe är den rekommenderade metoden.

## Reläet och drickssidorna

Drickssidor ligger på `tip.live.tips` och serveras av ett litet relä vi kör på Firebase. Det
erbjuds **kostnadsfritt, som en gentjänst, utan någon som helst garanti**.
Det är best-effort: det kan bli hastighetsbegränsat, det kan vara otillgängligt, dricks kan bli försenad eller
gå förlorad, och det behåller med avsikt inget som skulle låta någon återskapa den efteråt — en
levererad dricks raderas i samma ögonblick som artistens skärm visar den, och en ej levererad
raderas efter en timme.

- En drickssida **utan konto bakom sig raderas efter 90 dagars inaktivitet**.
- Vi kan **hastighetsbegränsa, blockera eller radera vilken drickssida som helst**, när som helst, utan förvarning — i
  synnerhet där vi ser bedrägeri, identitetskapning, missbruk, olagligt innehåll eller försök att
  överbelasta tjänsten.
- Vi kan **ändra reläet eller stänga ned det helt**. Om vi någonsin gör det kommer uppsättningar med enbart Stripe
  att fortsätta fungera, eftersom de aldrig var beroende av oss.

Du får inte använda reläet, en drickssida eller ett konto för att utge dig för att vara någon annan,
för att begå bedrägeri, för att publicera olagligt eller kränkande innehåll, för att samla in
välgörenhetsgåvor under falska förespeglingar, för att kringgå hastighetsbegränsningarna eller
bottkontrollen, eller för att angripa tjänsten.

## Att avsluta det

- **Du** kan sluta när som helst: logga ut, ta bort ett band, radera en drickssida, eller
  avinstallera appen. Integritetspolicyn säger exakt vad var och en av dem raderar — och säger
  ärligt att radering av ett helt konto för närvarande är ett mejl till
  **[contact@live.tips](mailto:contact@live.tips)** snarare än en knapp i appen.
- **Vi** kan stänga av, återkalla eller radera ett konto, en drickssida, eller åtkomsten till
  tjänsten där den används till något av det som räknats upp ovan, eller där det skulle utsätta
  tjänsten eller andra människor för risk att låta den fortsätta. Det finns ingen
  överklagandenämnd här. Det finns en e-postadress, och en människa som läser den.
- Om den hostade tjänsten någonsin läggs ned kommer vi att säga det på den här webbplatsen.
  Inget av värde är inlåst i den: pengarna finns redan på ditt eget betalkonto, appen är öppen
  källkod, och en uppsättning med enbart Stripe behövde aldrig oss alls.

## Ingen garanti

live.tips tillhandahålls **”i befintligt skick”, utan garanti av något slag**, uttrycklig eller underförstådd,
inklusive garanti om säljbarhet, lämplighet för ett visst ändamål eller
frånvaro av intrång. Detta är standardpositionen i MIT, och den är menad bokstavligt.

Vi lovar inte att programvaran är fri från buggar, att appen visar varje dricks,
att ditt konto synkar, att reläet går att nå under ditt set, eller att någon tredjepartstjänst
uppför sig.

## Ansvar

**I den utsträckning lagen tillåter ansvarar vi inte** för någon förlust eller skada
som uppstår ur din användning av live.tips. Det inkluderar — utan begränsning — utebliven,
försenad, dubblerad eller ej levererad dricks; dricks som visas som overifierad men aldrig betalades;
data som inte gick att synka, eller som försvann med ett konto du inte kunde återställa;
förlorad inkomst; en enhet som slutade fungera på scenen; handlingar, avbrott eller beslut hos Stripe,
Revolut, MobilePay, Monzo, Google, Apple, Cloudflare eller GitHub; och allt du förlorade för att du
litade på en siffra på en skärm.

live.tips är fri programvara som ges bort av en enda person. Det finns inga intäkter här att finansiera ett
ansvar med, och inget ansvar accepteras.

Två ärliga begränsningar av det stycket, för ett villkor som tar sig för mycket är ingenting värt:

- Vi utesluter **inte** ansvar för **dödsfall eller personskada orsakad av vårdslöshet,
  för bedrägeri, eller för något annat som inte lagligen kan uteslutas**.
- Om du är **konsument** behåller du varje **tvingande rättighet som din lokala lag ger dig**.
  Inget här tar bort dem.

## Programvaran är din

live.tips är MIT-licensierad. Du får **läsa, forka, ändra, självhosta och köra den själv**
— inklusive reläet. Om du inte gillar hur vi driver tjänsten är det ärliga svar som
öppen källkod ger dig: kör din egen. Källkoden finns på
[github.com/mekedron/live.tips](https://github.com/mekedron/live.tips).

Inget i dessa villkor begränsar de rättigheter MIT-licensen ger dig över själva koden;
dessa villkor styr den **hostade tjänsten** — den här webbplatsen, kontona och reläet vi kör.

## Ändringar

Vi kan uppdatera dessa villkor när programvaran ändras. Varje tidigare version finns i den publika
git-historiken, så du kan se exakt vad som ändrades och när. Att fortsätta använda
tjänsten efter en ändring betyder att du accepterar den.

## Kontakt

**[contact@live.tips](mailto:contact@live.tips)** — en riktig människa läser den.

## Språk

Dessa villkor publiceras på alla språk webbplatsen stöder, som en service. Om en
översättning och den engelska versionen inte stämmer överens är **den engelska versionen den som
gäller**.
