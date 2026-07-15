---
title: Jak live.tips nakládá s penězi (nijak)
description: Neexistuje žádný zůstatek live.tips, žádný výplatní kalendář, žádná provize. Tady je architektura, díky které jsou ta tři tvrzení nudná místo odvážných.
slug: jak-live-tips-naklada-s-penezi
---

Jakákoli kasička na spropitné může na svou úvodní stránku napsat „0% poplatek".
Zajímavější otázka zní, co by software musel udělat, aby si *začal* brát podíl, a
kolik z toho bys viděl.

U live.tips je odpověď: musel by se přestavět od základu. To není slib o našich
úmyslech, je to popis toho, kam peníze putují.

## Peníze přes nás nikdy neprocházejí

Když fanoušek ťukne na částku u karty, platba se vytvoří na **tvém** účtu Stripe,
připíše se na **tvůj** zůstatek Stripe a vyplatí se podle **tvého** kalendáře Stripe.
Jediným poplatkem je standardní zpracovatelský poplatek samotného Stripe, který ti
Stripe účtuje přímo, přesně tak, jako by to udělal, kdyby sis Stripe integroval sám.

Na naší straně žádná účetní kniha není, protože není co zaznamenávat. Nemohli
bychom si strhnout procenta, aniž bychom nejdřív postavili to, co peníze drží — a nic
takového neexistuje.

To platí, ať už se přihlásíš, nebo ne. Co přihlášení mění, je cesta *dat*, ne cesta
*peněz*, a další dvě sekce jsou upřímné přesně v tom, jak.

## Tvé klíče a kde žijí

Nastavení si vyžádá *omezený* API klíč Stripe, ne živý tajný klíč — ty odmítáme
rovnou. Omezený znamená, že klíč umí dvě věci: vytvořit odkaz na spropitné „zaplať,
kolik chceš" a sledovat příchozí spropitné. Nemůže číst tvůj zůstatek, spouštět
výplaty, vystavovat refundace ani se dotknout dat zákazníků. Kdyby zítra unikl,
poloměr zásahu je jeden odkaz na spropitné.

**Bez účtu ten klíč nikdy neopustí tvé zařízení.** Sedí v klíčence tvého vlastního
zařízení a odesílá se výhradně na `api.stripe.com` přes TLS. Žádný server live.tips
v tom není vůbec.

**Když se přihlásíš, klíč se přesune k nám** — protože klíč, který existuje jen na
jednom telefonu, nemůže obsloužit i tablet na pódiu. Zašifrujeme ho (klíčem AES-256
zvlášť pro každé tajemství, který je sám obalený přes Google Cloud KMS) a uložíme
tam, kde ho nic nepřečte zpět: žádný jiný účet, ani my při mrknutí do databáze, ani
ty sám. Rozpečetí se jen uvnitř našich funkcí, použije se ke komunikaci se Stripe
tvým jménem a už nikdy se nepředá zpět do zařízení. Řekněme to na rovinu: přihlášení
staví server live.tips do cesty mezi Stripe a tvou historii spropitného. Nikdy ne
peníze — data.

## Servery a co nedokážou

Jsou dva a oba jsou minimální.

**Přenašeč** existuje, protože Revolut a MobilePay nejde z prohlížeče řídit tak jako
Stripe. Jejich zapnutí spustí hrstku funkcí Firebase, které obsluhují tvou stránku
se spropitným na `tip.live.tips`. Ukládá veřejný profil tvé stránky se spropitným —
zobrazované jméno a platební identifikátory, které ses rozhodl zveřejnit — a u
stránky, za kterou nestojí žádný účet, nevede žádnou historii spropitného: spropitné
čeká jen do chvíle, než ho zobrazí tvoje pódiové zařízení, a co si nikdo nevyzvedl,
je do hodiny smeteno pryč. Nevidí žádné peníze a po 90 dnech nečinnosti se sám smaže.
Pokud používáš jen Stripe a nikdy se nepřihlásíš, přenašeč se nikdy vůbec
nekontaktuje.

**Webhook** existuje, teprve když se přihlásíš. Protože tvůj klíč teď žije u nás,
Stripe hlásí každé spropitné naší malé funkci, která ho zapíše do tvé vlastní
historie, aby ho tvá další zařízení mohla ukázat. Je to kopie události, ne kopie
peněz. Nemůže pohnout ani centem a vždy může zapisovat jen do toho jednoho účtu,
kterému patří.

Ani jeden server si nemůže vzít podíl, protože ani jeden není nikde blízko penězům.
Nejvíc, co který z nich dokáže, je selhat — a nastavení jen se Stripe a bez účtu
nezávisí ani na jednom.

## Účet, který si nemusíš zakládat

Aplikace se pořád spouští do profilu uloženého v zařízení, což je přesně to, čím
vždycky byla: tvoje kasička, tvůj klíč a tvoje historie spropitného žijí v zařízení
a nikde jinde. Není se kam registrovat.

Přihlásit se — přes Apple, přes Google nebo jako host — teď jde a existuje to z
jediného důvodu: druhé zařízení. Má-li tablet na pódiu a telefon v tvojí kapse
ukazovat tentýž večer, něco mezi nimi stát musí, a tím něčím je Firestore, pod
uživatelským id, které si můžeš přečíst jen ty. Žijí tam tvoje kapely, nastavení,
historie spropitného — a, zašifrovaný jak výše, tvůj klíč ke Stripe. To je skutečná
změna v příběhu o soukromí a zaslouží si být řečena na rovinu, ne objevena: bez účtu
žádný server spropitné nikdy nevidí; s účtem ho vidí tvůj vlastní kout toho našeho, a
je to náš webhook, kdo ho tam zapíše. To je cena za druhé zařízení a je jen na tobě,
jestli ji zaplatíš, nebo odmítneš. Čeho se to nikdy nedotkne, jsou peníze — účet
přesouvá tvoje data, ne tvůj zůstatek, a podíl si pořád nebereme.

## Proč bys nám neměl věřit na slovo

Všechno výše uvedené se dá ověřit. Zdrojový kód má licenci MIT a je veřejný a web
je statický build nasazovaný přes GitHub Actions na GitHub Pages — žádná skrytá
infrastruktura, nic zkompilovaného za zavřenými dveřmi. Otevři při ukázkovém
spropitném záložku sítě a přečti si požadavky. Je jich méně, než čekáš.

To je to skutečné tvrzení o produktu. Ne že jsme důvěryhodní, ale že to od nás
nepotřebuješ.
