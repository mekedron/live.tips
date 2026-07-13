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

## Spropitné kartou přes nás nikdy neprochází

Když fanoušek ťukne na částku u karty, jeho prohlížeč mluví s `api.stripe.com`.
Ne se serverem live.tips — na téhle cestě žádný není. Platba se vytvoří na
**tvém** účtu Stripe, připíše se na **tvůj** zůstatek Stripe a vyplatí se podle
**tvého** kalendáře Stripe. Jediným poplatkem je standardní zpracovatelský
poplatek samotného Stripe, který ti Stripe účtuje přímo, přesně tak, jako by to
udělal, kdyby sis Stripe integroval sám.

Na naší straně žádná účetní kniha není, protože není co zaznamenávat. Nemohli
bychom si strhnout procenta, aniž bychom nejdřív postavili to, co peníze drží.

## Tvé klíče zůstávají tvé

Nastavení si vyžádá *omezený* API klíč Stripe, ne živý tajný klíč — ty odmítáme
rovnou. Ukládá se do klíčenky tvého vlastního zařízení a odesílá se do Stripe
výhradně přes TLS.

Omezený znamená, že klíč umí dvě věci: vytvořit odkaz na spropitné „zaplať, kolik
chceš" a sledovat příchozí spropitné. Nemůže číst tvůj zůstatek, spouštět
výplaty, vystavovat refundace ani se dotknout dat zákazníků. Kdyby zítra unikl,
poloměr zásahu je jeden odkaz na spropitné.

## Jediný server v platební cestě

Revolut a MobilePay nejde z prohlížeče řídit tak jako Stripe, takže jejich
zapnutí spustí minimální přenašeč — hrstku funkcí Firebase, které obsluhují tvou
stránku se spropitným na `tip.live.tips`. Vyplatí se být přesný v tom, co ten
přenašeč dělá, protože „přidali jsme backend" bývá obvykle místo, kde se tyhle
příběhy zvrtnou.

Ukládá veřejný profil tvé stránky se spropitným — zobrazované jméno a platební
identifikátory, které ses rozhodl zveřejnit. Nic víc. Nevede žádnou historii
spropitného, nevidí žádné peníze, nedrží žádné klíče a po 90 dnech nečinnosti se sám
smaže. Spropitné přes Revolut nebo MobilePay tam čeká jen do chvíle, než si ho
vyzvedne tvoje pódiové zařízení: jakmile se zobrazí, smaže se, a co si nikdo
nevyzvedl, je do hodiny smeteno pryč. Peníze se stále pohybují přímo mezi aplikací
Revolut nebo MobilePay tvého fanouška a tou tvou.

Pokud používáš jen Stripe, přenašeč se nikdy vůbec nekontaktuje.

## Účet, který si nemusíš zakládat

Aplikace se pořád spouští do profilu uloženého v zařízení, což je přesně to, čím
vždycky byla: tvoje kasička, tvůj klíč a tvoje historie spropitného žijí v zařízení
a nikde jinde. Není se kam registrovat.

Přihlásit se — přes Apple, přes Google nebo jako host — teď jde a existuje to z
jediného důvodu: druhé zařízení. Má-li tablet na pódiu a telefon v tvojí kapse
ukazovat tentýž večer, něco mezi nimi stát musí, a tím něčím je Firestore, pod
uživatelským id, které si můžeš přečíst jen ty. Synchronizují se tam tvoje kapely,
nastavení, omezený klíč i historie spropitného. To je skutečná změna v příběhu o
soukromí a zaslouží si být řečena na rovinu, ne objevena: bez účtu žádný server
spropitné nikdy nevidí; s účtem ho vidí tvůj vlastní kout toho našeho. To je cena
za druhé zařízení a je jen na tobě, jestli ji zaplatíš, nebo odmítneš. Čeho se to
nikdy nedotkne, jsou peníze — účet přesouvá tvoje data, ne tvůj zůstatek, a podíl
si pořád nebereme.

## Proč bys nám neměl věřit na slovo

Všechno výše uvedené se dá ověřit. Zdrojový kód má licenci MIT a je veřejný a web
je statický build nasazovaný přes GitHub Actions na GitHub Pages — žádná skrytá
infrastruktura, nic zkompilovaného za zavřenými dveřmi. Otevři při ukázkovém
spropitném záložku sítě a přečti si požadavky. Je jich méně, než čekáš.

To je to skutečné tvrzení o produktu. Ne že jsme důvěryhodní, ale že to od nás
nepotřebuješ.
