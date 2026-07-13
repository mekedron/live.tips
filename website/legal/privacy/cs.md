---
title: Zásady ochrany osobních údajů
description: live.tips nemá žádné účty, žádné cookies, žádnou analytiku a žádné sledování. Tady je krátký seznam toho, co se skutečně zpracovává, kým a jak dlouho.
updated: 2026-07-13
updated_label: Naposledy aktualizováno 13. července 2026
---

live.tips je open-source kasička na spropitné pro umělce. Provozuje ji **Nikita Rabykin**,
samostatný vývojář, nikoli firma. Pokud vám na čemkoli níže záleží, napište na
**[contact@live.tips](mailto:contact@live.tips)** — na té adrese je skutečný člověk.

Tyto zásady jsou upřímné i v těch nudných částech. Raději řekneme „vaše jméno uchováváme
až jednu hodinu“, než abychom tvrdili, že neuchováváme nic, a lhali.

## Krátká verze

- **Žádné účty.** Není se kam registrovat.
- **Žádné cookies.** Ani jedno, nikde.
- **Žádná analytika, žádné sledování, žádné reklamy, žádné skripty třetích stran** na
  tomto webu.
- **Vašich peněz se nikdy nedotkneme.** Spropitné jde přímo od fanouška na umělcův
  vlastní účet u Stripe, Revolutu, MobilePay nebo Monza. V té cestě nestojíme.
- **Ve výchozím nastavení komunikuje aplikace pouze se Stripe** — s žádným serverem
  live.tips.
- Jediný server, který vůbec provozujeme, je malé relé, a to existuje jen tehdy, když si
  umělec zapne Revolut, MobilePay nebo Monzo.

## Tento web

Web je statický a hostovaný na **GitHub Pages**. Jako hostitel dostává GitHub IP adresu a
user-agent prohlížeče každého, kdo si načte stránku — jde o běžné logování webového
serveru, děje se dřív, než se spustí jakýkoli náš kód, a nemůžeme ho vypnout. GitHub tato
data zpracovává podle vlastního
[prohlášení o ochraně soukromí](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
My do těchto logů nenahlížíme a GitHub nám je neukazuje.

Kromě toho stránky, které právě čtete, nenačítají **nic od nikoho dalšího**: písma, ikony
i obrázky se servírují přímo z live.tips. Není tu žádná Google Analytics, žádný tag
manager, žádný pixel, žádný vložený widget.

Web ukládá **dvě hodnoty do `localStorage` vašeho prohlížeče**, obě nastavujete vy, obě
jsou čitelné jen tímto webem a ani jedna se nikam neodesílá:

| Klíč | Co si pamatuje |
| --- | --- |
| `lt-landing-theme` | zda jste zvolili světlé, tmavé nebo automatické barvy |
| `lt-langbar-dismissed` | že jste zavřeli banner „také dostupné ve vašem jazyce“ |

Vymazáním úložiště prohlížeče je smažete. Nejsou to cookies, nikam se nesdílejí a
neidentifikují nikoho.

## Aplikace

Aplikace live.tips běží **na umělcově vlastním zařízení**. Všechno, co ví, žije tam:

- **Omezený klíč ke Stripe** je uložený v klíčence zařízení (iOS/macOS Keychain, Android
  Keystore) a odesílá se výhradně na `api.stripe.com`.
- **Historie spropitného, historie vystoupení, cíl a nastavení aplikace** se ukládají do
  lokálního úložiště zařízení. To zahrnuje jména a vzkazy, které fanoušci ke svému
  spropitnému připojí.
- Odinstalováním aplikace se to všechno smaže. Na naší straně neexistuje žádná záloha v
  cloudu, protože na naší straně neexistuje žádný cloud.

**Nic z toho nikdy nedostaneme.** Aplikace se dodává bez analytického SDK, bez hlášení
pádů, bez push notifikací a bez reklamního kódu — vůbec žádného, ani vypnutého.

Dvě upřesnění, aby tvrzení „nekomunikuje s nikým“ zůstalo přesně pravdivé:

- Aplikace si jednou denně stahuje **směnné kurzy** z veřejných kurzovních API
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Jde o prosté
  požadavky na veřejný seznam kurzů. Nenesou žádnou informaci o vás, o umělci ani o
  jakémkoli spropitném — ale stejně jako každý webový požadavek prozradí těmto službám
  vaši IP adresu.
- Pokud používáte **prohlížečovou verzi** aplikace, váš prohlížeč si ji stáhne z našeho
  statického hostingu (viz *Tento web* výše).

## Stripe

Když fanoušek platí kartou, je na platební stránce **Stripe**, ne na naší. Stripe sbírá a
zpracovává jeho platební údaje jako samostatný správce podle
[zásad ochrany osobních údajů Stripe](https://stripe.com/privacy). Čísla karet nikdy
nevidíme a k umělcovu účtu u Stripe nemáme přístup.

Umělcova aplikace načítá jeho vlastní spropitné ze Stripe pomocí jeho vlastního omezeného
klíče. Jméno a vzkaz fanouška, pokud je zanechal, putují ze Stripe do umělcova zařízení a
tam končí.

## Relé — jen když jsou zapnuté Revolut, MobilePay nebo Monzo

Nastavení jen se Stripe se ho vůbec netýká a tady může přestat číst.

Revolut, MobilePay ani Monzo nenabízejí aplikaci žádný způsob, jak potvrdit, že platba
proběhla, takže se tato spropitná směrují přes malé open-source relé, které provozujeme
na **Cloudflare** na `api.live.tips`. Peněz se nikdy nedotkne. Tady je všechno, co
zpracovává.

### Co ukládá umělec

Vytvořením stránky pro spropitné se uloží umělcovo **zobrazované jméno, jeho veřejný
vzkaz, jeho měna a platební identifikátory, které se rozhodl zveřejnit** (jeho platební
odkaz Stripe, uživatelské jméno Revolut, MobilePay Box ID, uživatelské jméno Monzo). To
všechno jsou informace, které umělec fanouškům tak jako tak záměrně zveřejňuje.

- **Uchování: automaticky smazáno po 90 dnech nečinnosti.**
- Umělec je může kdykoli **okamžitě** smazat z aplikace.
- Nikdy se nesbírá e-mailová adresa, heslo, občanské jméno ani bankovní údaje.

### Co posílá fanoušek

Formulář pro spropitné se ptá na **částku** a volitelně na **jméno** a **vzkaz**. To je
celý formulář. Žádný e-mail, žádné telefonní číslo, žádný účet.

- Pokud je umělcova obrazovka **online**, spropitné je na ni přímo předáno a **nikdy se
  nezapíše na disk**.
- Pokud je umělcova obrazovka **offline** — zamčený telefon, žádný signál — je spropitné
  **uchováno v úložišti až jednu hodinu**, aby se prostě neztratilo, a předáno ve chvíli,
  kdy se obrazovka znovu připojí. Pokud se nikdo nepřipojí, je **smazáno, aniž by ho kdo
  viděl**. Tohle je jediný text napsaný fanouškem, který relé vůbec kdy ukládá, a jedna
  hodina je jeho tvrdý limit.
- Vaše jméno a vzkaz se také vkládají do **poznámky k platbě**, která se otevře v
  Revolutu, MobilePay nebo Monzu — tak umělec pozná, kdo poslal spropitné. Tyto firmy je
  pak zpracovávají podle vlastních zásad ochrany osobních údajů.
- Relé neuchovává **žádnou historii spropitného**. Nemůže vám, nám ani nikomu jinému
  ukázat seznam toho, kdo komu poslal spropitné.

### IP adresy a ochrana před zneužitím

Otevřený formulář, do kterého může kdokoli odesílat, potřebuje nějakou ochranu před boty,
takže:

- Vaše IP adresa se používá k **omezování četnosti požadavků** a odesílá se do
  **Cloudflare Turnstile** (kontrola proti botům běžící na stránce pro spropitné), aby se
  ověřilo, že nejste bot. Turnstile je produkt Cloudflare a používá se místo CAPTCHA,
  která by vás profilovala.
- Aby někdo nemohl vytvořit tisíce stránek pro spropitné, uchovává se **kryptografický
  hash IP adresy** toho, kdo stránku vytváří, zhruba **dvě hodiny**, a poté se zahodí.
- **Provozní logy Cloudflare** zaznamenávají technické podrobnosti požadavků na relé —
  URL, časování, stav — po dobu několika dní. Neobsahují jména ani vzkazy fanoušků.
  Cloudflare vystupuje jako náš zpracovatel; viz
  [zásady ochrany osobních údajů Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Počítadla

Relé počítá, **kolik spropitných** daná stránka pro spropitné přeposlala, abychom mohli
odhalit zneužití a věděli, jestli se to vůbec používá. Je to číslo. Neobsahuje žádná data
o fanoušcích.

## Právní základ, kdybyste ho potřebovali (GDPR)

- Provozování relé pro umělce, který si ho zapnul, a doručení fanouškova spropitného na
  obrazovku, které bylo určeno: **plnění služby, o kterou jste požádali**.
- Omezování četnosti požadavků, Turnstile a kvóty podle hashované IP: **oprávněný zájem**
  na tom, aby bezplatnou, otevřenou službu nezničili boti a podvodníci.
- Serverové logy: **oprávněný zájem** na provozu a zabezpečení služby.

## Vaše práva

Můžete nás požádat o kopii, opravu nebo smazání čehokoli, co o vás uchováváme, a můžete
si stěžovat u svého národního úřadu pro ochranu osobních údajů. Pište na
**[contact@live.tips](mailto:contact@live.tips)**.

V praxi je většina z toho už teď ve vašich rukou: umělci mohou svou stránku pro spropitné
okamžitě smazat z aplikace, spropitné od fanoušků se vypaří do hodiny a všechno ostatní
žije na vašem vlastním zařízení.

## Děti

live.tips není určen dětem a jejich údaje vědomě nezpracováváme.

## Změny

Tuto stránku budeme aktualizovat, jak se bude měnit software. Protože je celý projekt open
source, **každá minulá verze těchto zásad je ve veřejné historii gitu** — můžete si přesně
porovnat, co se změnilo a kdy.

## Jazyk

Tyto zásady vydáváme ve všech jazycích, které web podporuje, pro vaše pohodlí. Pokud se
překlad a anglická verze rozcházejí, **platí anglická verze**.
