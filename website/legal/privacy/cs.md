---
title: Zásady ochrany osobních údajů
description: live.tips nemá žádné cookies, žádnou analytiku a žádné sledování a funguje i úplně bez účtu. Pokud se rozhodnete přihlásit, tady je přesně to, co se ukládá, kde, kým a jak dlouho.
updated: 2026-07-13
updated_label: Naposledy aktualizováno 13. července 2026
---

live.tips je open-source kasička na spropitné pro umělce. Provozuje ji **Nikita Rabykin**,
samostatný vývojář, nikoli firma. Pokud vám na čemkoli níže záleží, napište na
**[contact@live.tips](mailto:contact@live.tips)** — na té adrese je skutečný člověk.

Tyto zásady jsou upřímné i v těch nudných částech. Raději řekneme „vaše jméno uchováváme
až jednu hodinu“, než abychom tvrdili, že neuchováváme nic, a lhali.

## Krátká verze

- **Účet je volitelný.** Aplikace funguje úplně bez účtu a tak to je pořád výchozí. Pokud
  chcete mít své kapely a svou historii i na druhém zařízení, můžete se přihlásit — a pak
  se část z toho ukládá na server. Co přesně je co, je popsáno níže.
- **Žádné cookies.** Ani jedno, nikde.
- **Žádná analytika, žádné sledování, žádné reklamy, žádné skripty třetích stran** na
  tomto webu.
- **Vašich peněz se nikdy nedotkneme.** Spropitné jde přímo od fanouška na umělcův
  vlastní účet u Stripe, Revolutu, MobilePay nebo Monza. V té cestě nestojíme.
- **Ve výchozím nastavení komunikuje aplikace pouze se Stripe** — s žádným serverem
  live.tips.
- Jediný server, který vůbec provozujeme, je malé relé na Firebase od Googlu. Existuje pro
  případ, že si umělec zapne Revolut, MobilePay nebo Monzo — nebo že se přihlásí.

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

## Aplikace má dva režimy a v tom rozdílu je celý příběh

Všechno níže se točí kolem jediné otázky: **přihlásili jste se?**

### Režim jedna — bez účtu. Pořád výchozí, pořád beze změny.

Aplikace běží **na umělcově vlastním zařízení** a všechno, co ví, žije tam:

- **Omezený klíč ke Stripe** je uložený v klíčence zařízení (iOS/macOS Keychain, Android
  Keystore) a odesílá se výhradně na `api.stripe.com`.
- **Historie spropitného, historie vystoupení, cíl a nastavení aplikace** se ukládají do
  lokálního úložiště zařízení. To zahrnuje jména a vzkazy, které fanoušci ke svému
  spropitnému připojí.
- Odinstalováním aplikace se to všechno smaže. Na naší straně neexistuje žádná záloha v
  cloudu, protože v tomto režimu na naší straně neexistuje žádný cloud.

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

### Režim dva — přihlásili jste se. Pak část dat ze zařízení odchází, záměrně.

Přihlášení je vědomý krok. Nikdo vás nepřihlásí za vás a nic v aplikaci nepřestane
fungovat, když se nepřihlásíte nikdy. Přihlásíte se, protože chcete druhé zařízení: telefon
v kapse a tablet na pódiu, které ukazují stejný večer, stejné kapely, stejnou historii.

To funguje jen tehdy, když je někde drží server. **Takže je drží, a to je poctivá cena za
druhé zařízení.**

Tím serverem je **Firebase**, což je Google. Účet můžete mít třemi způsoby:

- **Přihlášení přes Apple** nebo **přihlášení přes Google** — Firebase Auth dostane to, co
  mu poskytovatel předá: uživatelské id (uid) a obvykle e-mailovou adresu a jméno. (U Apple
  můžete svůj e-mail skrýt; Apple nám pak místo něj dá přeposílací adresu.)
- **Účet hosta** — anonymní účet bez e-mailu a bez jména. Synchronizuje a lze ho odvolat,
  ale pokud přijdete o zařízení, není čím ho obnovit. Je to uid a nic víc.

Jakmile jste přihlášení, dostane účet svůj vlastní soukromý kout v databázi Google **Cloud
Firestore**, na `users/<your uid>/`. Bezpečnostní pravidla přidělují tento kout tomu uid **a
nikomu jinému** — žádný jiný účet ho nepřečte, hádání URL v to počítaje. Uvnitř je:

| Co | Proč to tam je |
| --- | --- |
| Vaše **kapely** — jména, nastavení kasičky a platebních metod, text plakátu, cíle | aby kapela existovala na každém zařízení, kam se přihlásíte |
| Váš **omezený klíč ke Stripe** a tajný kód stránky pro spropitné v relé | v dokumentu s tajemstvími, který přečte jen vaše uid, a v mezipaměti klíčenky každého z vašich zařízení |
| **Nastavení aplikace** | aby zařízení, které přidáte, bylo rovnou nastavené |
| **Záznamy o vystoupeních a historie spropitného** — včetně **jmen a vzkazů, které fanoušci ke svému spropitnému připojí** | protože přesně tuhle historii jste chtěli vidět na druhém zařízení |
| **Živé vystoupení**, které právě běží | aby se druhá obrazovka mohla připojit k dnešnímu setu |
| Vaše **zařízení** — jméno, které si každé z nich dá („Nikitův iPhone“), jeho platforma a model, kdy bylo poprvé a naposledy vidět | aby je Nastavení → Zabezpečení mohlo vypsat a vy jste některé mohli odvolat |
| Malý **dokument profilu** — jméno účtu, které jste si zvolili, a přes kterého poskytovatele jste se přihlásili | aby ho přepínač účtů uměl označit |

A teď to podstatné, natvrdo: **bez účtu jméno a vzkaz fanouška nikdy neopustí umělcovo
zařízení. S účtem se ukládají na servery Googlu pod umělcovo uid, jako součást umělcovy
vlastní synchronizované historie.** Žádný jiný účet je nepřečte, my se do nich nedíváme a
nic se z nich nedovozuje — ale jsou tam, a měli byste to vědět dřív, než se přihlásíte.

Odhlášením se zařízení vrátí do lokálního režimu. Data účtu to nesmaže — viz *Mazání věcí*
níže.

### Přidání zařízení pomocí QR kódu

Zařízení přidáte tak, že ukážete QR kód ze zařízení, které už je přihlášené. Kód je
náhodný, **jednorázový a vyprší za dvě minuty**, a nové zařízení nedostane nic, dokud na tom
starém neklepnete na *potvrdit*. Dokud je tenhle handshake otevřený, držíme kód, jméno,
které si nové zařízení dalo, a jeho platformu — a záznam se po vypršení smaže.
Vyfotografovaný QR kód je bez vašeho potvrzujícího klepnutí k ničemu.

## Kde tohle všechno fyzicky žije

Firebase Auth, Cloud Firestore i naše Cloud Functions běží v **Evropské unii** — databáze v
multiregionu Googlu `eur3`, funkce v `europe-west1`. Google vystupuje jako náš zpracovatel
podle
[podmínek ochrany soukromí a bezpečnosti Firebase](https://firebase.google.com/support/privacy)
a vlastních [zásad ochrany osobních údajů](https://policies.google.com/privacy). Jako každý
velký poskytovatel může Google pro podporu a bezpečnost zapojit i infrastrukturu mimo EU;
to se řídí těmi podmínkami, ne námi.

## Stripe

Když fanoušek platí kartou, je na platební stránce **Stripe**, ne na naší. Stripe sbírá a
zpracovává jeho platební údaje jako samostatný správce podle
[zásad ochrany osobních údajů Stripe](https://stripe.com/privacy). Čísla karet nikdy
nevidíme a k umělcovu účtu u Stripe nemáme přístup.

Umělcova aplikace načítá jeho vlastní spropitné ze Stripe pomocí jeho vlastního omezeného
klíče — přímo ze zařízení na `api.stripe.com`. **V té cestě není žádný server live.tips a
nikdy nebyl.** Jméno a vzkaz fanouška, pokud je zanechal, putují ze Stripe do umělcova
zařízení a tam končí — ledaže se umělec přihlásil, a pak je zařízení navíc uloží do jeho
vlastní historie ve Firestore, jak je popsáno výše.

## Relé — jen když jsou zapnuté Revolut, MobilePay nebo Monzo

Nastavení jen se Stripe se ho vůbec netýká.

Revolut, MobilePay ani Monzo nenabízejí aplikaci žádný způsob, jak potvrdit, že platba
proběhla, takže se tato spropitná směrují přes malé open-source relé, které provozujeme na
**Firebase** — Cloud Functions a Firestore v `europe-west1`, se stránkou pro spropitné pro
fanoušky na **`tip.live.tips/t/<id>`**. Peněz se nikdy nedotkne. Tady je všechno, co
zpracovává.

### Co ukládá umělec

Vytvořením stránky pro spropitné se uloží umělcovo **zobrazované jméno, jeho veřejný
vzkaz, jeho měna a platební identifikátory, které se rozhodl zveřejnit** (jeho platební
odkaz Stripe, uživatelské jméno Revolut, MobilePay Box ID, uživatelské jméno Monzo). To
všechno jsou informace, které umělec fanouškům tak jako tak záměrně zveřejňuje.

- **Uchování: stránka pro spropitné, za kterou nestojí žádný účet, se automaticky maže po
  90 dnech nečinnosti.** Stránka pro spropitné, která patří přihlášenému účtu, žije tak
  dlouho jako kapela, ke které patří.
- Umělec ji může kdykoli **okamžitě** smazat z aplikace.
- Nesbírá se tu žádná e-mailová adresa, žádné heslo, žádné občanské jméno, žádné bankovní
  údaje.
- Tajný kód stránky se ukládá **jen jako hash**. Kdybyste se nás na něj zeptali, nedokázali
  bychom vám ho říct; umíme ho jen ověřit.

### Co posílá fanoušek

Formulář pro spropitné se ptá na **částku** a volitelně na **jméno** a **vzkaz**. To je
celý formulář. Žádný e-mail, žádné telefonní číslo, žádný účet.

- Spropitné se zapíše do **doručovací fronty** — jediného dokumentu, který existuje proto,
  aby byl předán na umělcovu obrazovku. Když ho obrazovka zobrazí, **umělcovo zařízení ten
  dokument smaže.** To smazání *je* to potvrzení; není tu žádný příznak „doručeno“, protože
  nezbývá žádný záznam, na kterém by se dal nastavit.
- Pokud je umělcova obrazovka offline — zamčený telefon, žádný signál — spropitné **čeká v
  té frontě až jednu hodinu**, aby se prostě neztratilo, a přejde ve chvíli, kdy se
  obrazovka znovu připojí. Pokud se nikdo nepřipojí, je **smazáno, aniž by ho kdo viděl**,
  vymetené podle rozvrhu bez ohledu na to, jestli se pro něj někdo někdy vrátil.
- **Ta fronta je jediné místo, kde se na našem serveru vůbec kdy ukládá text napsaný
  fanouškem, a jedna hodina je jeho tvrdý limit.** Pokud je umělec přihlášený, jeho zařízení
  si pak spropitné ponechá v *jeho* historii ve Firestore — protože je to jeho historie a
  přesně kvůli ní se přihlásil.
- Vaše jméno a vzkaz se také vkládají do **poznámky k platbě**, která se otevře v
  Revolutu, MobilePay nebo Monzu — tak umělec pozná, kdo poslal spropitné. Tyto firmy je
  pak zpracovávají podle vlastních zásad ochrany osobních údajů.
- Relé neuchovává **žádnou historii spropitného**. Nemůže vám, nám ani nikomu jinému
  ukázat seznam toho, kdo komu poslal spropitné.

### IP adresy a ochrana před zneužitím

Otevřený formulář, do kterého může kdokoli odesílat, potřebuje nějakou ochranu před boty,
takže:

- Vaše IP adresa se odesílá do **Cloudflare Turnstile** — kontroly proti botům, která běží
  na stránce pro spropitné —, aby se ověřilo, že nejste bot. Turnstile je produkt
  Cloudflare a používá se místo CAPTCHA, která by vás profilovala. Turnstile a naše DNS
  jsou jediné, co pro nás Cloudflare ještě dělá; samotné relé teď běží na Firebase. Viz
  [zásady ochrany osobních údajů Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Vaše IP se používá i k **omezování četnosti požadavků** — odeslání spropitného, vytvoření
  stránky pro spropitné, uplatnění kódu pro přidání zařízení. K tomu si ukládáme **solený
  kryptografický hash IP adresy**, nikdy samotnou IP, zhruba na **dvě hodiny**, a pak se
  smaže. Sůl je serverové tajemství: bez ní kód raději neuloží vůbec nic, než aby uchovával
  hash, který by šlo zpětně rozluštit.
- **Provozní logy Googlu** zaznamenávají technické podrobnosti požadavků na relé — URL,
  časování, stav — po dobu několika dní. Náš kód záměrně nezaznamenává žádná jména, žádné
  vzkazy, žádná tajemství a žádné hlavičky. Google vystupuje jako náš zpracovatel.

### Počítadla

Relé počítá, **kolik spropitných** daná stránka pro spropitné přeposlala, abychom mohli
odhalit zneužití a věděli, jestli se to vůbec používá. Je to číslo. Neobsahuje žádná data
o fanoušcích.

## Kdo co zpracovává

| Kdo | Co dostane | Proč |
| --- | --- | --- |
| **Google (Firebase)** | Účty, synchronizovaná data přihlášeného umělce, relé, serverové logy | Volitelný účet a volitelné relé |
| **Stripe** | Platební údaje fanouška, jako samostatný správce | Spropitné kartou |
| **Cloudflare** | IP adresu fanouška, kvůli kontrole Turnstile na stránce pro spropitné. A naše DNS. | Držení botů dál od formuláře pro spropitné |
| **GitHub** | IP adresu a user-agent každého, kdo si načte tento web | Hosting webu |
| **Revolut / MobilePay / Monzo** | Cokoli fanoušek udělá v jejich vlastní aplikaci, včetně poznámky k platbě | Tyto platební metody |

Nikomu nic neprodáváme a na tom seznamu nikdo další není.

## Právní základ, kdybyste ho potřebovali (GDPR)

- Provozování účtu, o který jste požádali, synchronizace vašich vlastních dat na vaše
  vlastní zařízení, provozování relé pro umělce, který si ho zapnul, a doručení fanouškova
  spropitného na obrazovku, které bylo určeno: **plnění služby, o kterou jste požádali**.
- Omezování četnosti požadavků, Turnstile, kvóty podle hashované IP a odvolávání zařízení:
  **oprávněný zájem** na tom, aby bezplatnou, otevřenou službu nezničili boti a podvodníci,
  a na tom, aby účty umělců zůstaly bezpečné.
- Serverové logy: **oprávněný zájem** na provozu a zabezpečení služby.

## Mazání věcí

Na tomhle záleží víc než na jakémkoli slibu, který bychom o tom mohli dát, takže tady je
přesně to, co dnes existuje — včetně toho, co neexistuje.

- **Bez účtu**: odinstalujte aplikaci. To je všechno, a je pryč.
- **Kapela**: odstraněním kapely v aplikaci se smažou její cloudová data — její nastavení,
  její klíče, její vystoupení, její historie spropitného — spolu s kopií na zařízení.
- **Stránka pro spropitné**: smažte ji nebo ji vygenerujte znovu v aplikaci a je z relé
  okamžitě smetená, včetně jakýchkoli čekajících spropitných.
- **Zařízení**: Nastavení → Zabezpečení vypisuje vaše zařízení. Můžete některé odvolat nebo
  se odhlásit všude jinde — což okamžitě, ne někdy později, ukončí relaci každého dalšího
  zařízení.
- **Celý váš účet, jedním klepnutím: takové tlačítko aplikace zatím nemá.** Raději se k
  tomu přiznáme, než bychom předstírali opak. Než začne existovat, napište na
  **[contact@live.tips](mailto:contact@live.tips)** a my účet a všechno pod ním smažeme
  ručně. Mezitím už teď můžete smazat každou kapelu, což odstraní všechno podstatné a
  zanechá prázdný účet.

## Vaše práva

Můžete nás požádat o kopii, opravu nebo smazání čehokoli, co o vás uchováváme, a můžete
si stěžovat u svého národního úřadu pro ochranu osobních údajů. Pište na
**[contact@live.tips](mailto:contact@live.tips)**.

V praxi je většina z toho už teď ve vašich rukou: umělec může stránku pro spropitné nebo
kapelu okamžitě smazat z aplikace, nedoručené spropitné od fanoušků se vypaří do hodiny, a
pokud se nikdy nepřihlásíte, nic z toho nikdy nebylo nikde jinde než na vašem vlastním
zařízení.

## Děti

live.tips není určen dětem a jejich údaje vědomě nezpracováváme.

## Změny

Tuto stránku budeme aktualizovat, jak se bude měnit software. Protože je celý projekt open
source, **každá minulá verze těchto zásad je ve veřejné historii gitu** — můžete si přesně
porovnat, co se změnilo a kdy.

## Jazyk

Tyto zásady vydáváme ve všech jazycích, které web podporuje, pro vaše pohodlí. Pokud se
překlad a anglická verze rozcházejí, **platí anglická verze**.
