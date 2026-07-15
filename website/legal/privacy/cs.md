---
title: Zásady ochrany osobních údajů
description: live.tips nemá žádné cookies, žádnou analytiku a žádné sledování a funguje i úplně bez účtu. Pokud se rozhodnete přihlásit, tady je přesně to, co se ukládá, kde, kým a jak dlouho.
updated: 2026-07-15
updated_label: Naposledy aktualizováno 15. července 2026
---

live.tips je open-source kasička na spropitné pro umělce. Provozuje ji **Nikita Rabykin**,
samostatný vývojář, nikoli firma. Pokud vám na čemkoli níže záleží, napište na
**[contact@live.tips](mailto:contact@live.tips)** — na té adrese je skutečný člověk.

Tyto zásady jsou upřímné i v těch nudných částech. Raději řekneme „vaše jméno uchováváme
tak dlouho, dokud máte kapelu“, než abychom tvrdili, že neuchováváme nic, a lhali.

## Krátká verze

- **Účet je volitelný.** Aplikace funguje úplně bez účtu a tak to je pořád výchozí. Pokud
  chcete mít své kapely a svou historii i na druhém zařízení, můžete se přihlásit — a pak
  se část z toho ukládá na server, a víc než dřív. Co přesně je co, je popsáno níže.
- **Žádné cookies.** Ani jedno, nikde.
- **Žádná analytika, žádné sledování, žádné reklamy, žádné skripty třetích stran** na
  tomto webu.
- **Vašich peněz se nikdy nedotkneme.** Spropitné jde přímo od fanouška na umělcův
  vlastní účet u Stripe, Revolutu, MobilePay nebo Monza. Žádný zůstatek live.tips nikdy
  neexistuje.
- **Bez účtu komunikuje aplikace pouze se Stripe** — s žádným serverem live.tips. Pokud se
  přihlásíte, tohle se změní: váš klíč ke Stripe se přesune na náš server a Stripe nám
  hlásí vaše spropitné, abychom ho mohli dostat na vaše další zařízení. To je poctivá cena
  za přihlášení a je níže popsána v plném znění.
- **Push notifikace jsou nové, volitelné a jen pro přihlášené účty.** Na zařízení, které si
  je nikdy nezapnulo, se nic neposílá, a zařízení bez účtu nedostane žádnou vůbec.
- Servery, které provozujeme, běží na Firebase od Googlu. Existují pro případ, že si umělec
  zapne Revolut, MobilePay nebo Monzo — nebo že se přihlásí.

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
- **Historie spropitného, historie vystoupení, cíl, seznam žádostí o písničky a nastavení
  aplikace** se ukládají do lokálního úložiště zařízení. To zahrnuje jména a vzkazy, které
  fanoušci ke svému spropitnému připojí.
- Odinstalováním aplikace se to všechno smaže. Na naší straně neexistuje žádná záloha v
  cloudu, protože v tomto režimu na naší straně neexistuje žádný cloud.

**Nic z toho nikdy nedostaneme.** Aplikace se dodává bez analytického SDK, bez hlášení
pádů a bez reklamního kódu — vůbec žádného, ani vypnutého. (Push notifikace existují, ale
jsou funkcí pro přihlášené a jsou vypnuté, dokud si je nezapnete — viz *Režim dva*. Na
zařízení bez účtu se žádná nikdy neposílá.)

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
  můžete svůj e-mail skrýt; Apple nám pak místo něj dá přeposílací adresu a vaše jméno předá
  jen úplně poprvé, když se přihlásíte.)
- **Účet hosta** — anonymní účet bez e-mailu a bez jména. Synchronizuje a lze ho odvolat,
  ale pokud přijdete o zařízení, není čím ho obnovit. Je to uid a nic víc. Účet hosta nemůže
  využívat úschovu klíče ke Stripe na straně serveru ani push notifikace popsané níže,
  protože obojí potřebuje účet, který vám můžeme vrátit.

Jakmile jste přihlášení, dostane účet svůj vlastní soukromý kout v databázi Google **Cloud
Firestore**, na `users/<your uid>/`. Bezpečnostní pravidla přidělují tento kout tomu uid **a
nikomu jinému** — žádný jiný účet ho nepřečte, hádání URL v to počítaje. Uvnitř je:

| Co | Proč to tam je |
| --- | --- |
| Vaše **kapely** — jména, nastavení kasičky a platebních metod, text plakátu, cíle a váš **seznam žádostí o písničky** | aby kapela existovala na každém zařízení, kam se přihlásíte |
| **Nastavení aplikace**, včetně vašich předvoleb oznámení | aby zařízení, které přidáte, bylo rovnou nastavené |
| **Záznamy o vystoupeních a historie spropitného** — včetně **jmen a vzkazů, které fanoušci ke svému spropitnému připojí**, a **jakékoli písničky, o kterou fanoušek požádal** | protože přesně tuhle historii jste chtěli vidět na druhém zařízení |
| **Živé vystoupení**, které právě běží | aby se druhá obrazovka mohla připojit k dnešnímu setu |
| Vaše **zařízení** — jméno, které si každé z nich dá („Nikitův iPhone“), jeho platforma a model, jazyk jeho rozhraní, kdy bylo poprvé a naposledy vidět, a (pokud jste zapnuli oznámení) **push token** | aby je Nastavení → Zabezpečení mohlo vypsat, aby oznámení dorazilo na správné zařízení ve správném jazyce a abyste některé mohli odvolat |
| Malý **dokument profilu** — jméno účtu, které jste si zvolili, a přes kterého poskytovatele jste se přihlásili | aby ho přepínač účtů uměl označit |
| **Kanál u zvonku** — omezený seznam nedávného spropitného a žádostí o písničky, které dorazily, když neběžel žádný set | abyste dohnali, co vám uteklo |

A teď to podstatné, natvrdo: **bez účtu jméno a vzkaz fanouška nikdy neopustí umělcovo
zařízení. S účtem se ukládají na servery Googlu pod umělcovo uid, jako součást umělcovy
vlastní synchronizované historie**, a — jak vysvětlují další dvě sekce — **teď je zapisuje
náš server.** Žádný jiný účet je nepřečte, my se do nich nedíváme a nic se z nich
nedovozuje — ale jsou tam, a zůstávají tam tak dlouho jako kapela, a měli byste to vědět
dřív, než se přihlásíte.

Odhlášením se zařízení vrátí do lokálního režimu. Data účtu to nesmaže — viz *Mazání věcí*
níže.

#### Váš klíč ke Stripe se při přihlášení přesune na náš server

Tohle je největší změna a ta, kterou se nejvíc vyplatí přečíst.

**Bez účtu váš omezený klíč ke Stripe nikdy neopustí vaše zařízení.** To je Režim jedna a
je beze změny.

**Když se přihlásíte, opustí ho — k nám.** Klíč je zašifrovaný (klíčem AES-256 zvlášť pro
každé tajemství, který je sám obalený přes Google Cloud KMS) a uložený na straně serveru na
místě, kde ho **nikdo nepřečte zpět — žádný jiný účet, ani vy sami.** Rozpečetí se jen
uvnitř našich Cloud Functions, použije se ke komunikaci se Stripe vaším jménem a už nikdy se
nepředá zpět do zařízení.

Protože klíč teď žije u nás, **Stripe hlásí vaše spropitné přímo na náš server**: na vašem
vlastním účtu Stripe zaregistrujeme webhook a Stripe tomu webhooku pokaždé, když se zaplatí
spropitné, dá vědět. Naše funkce spropitné zapíše do historie vašeho účtu (viz níže). Vaše
aplikace už u přihlášeného účtu Stripe nedotazuje; ke Stripe se dostane jen skrz úzký, pevný
seznam operací na našem serveru (vytvoření vašeho odkazu na spropitné, vygenerování odkazu
pro žádost o písničku a zpětné načtení vašeho vlastního spropitného pro odsouhlasení).

Takže bez příkras: **u přihlášeného účtu teď v cestě mezi Stripe a vaší historií stojí
server live.tips.** Peněz se pořád nikdy nedotýkáme — spropitné kartou se vytvoří na vašem
účtu Stripe, připíše se na váš zůstatek Stripe a vyplatí se podle vašeho kalendáře Stripe,
přesně jako dřív. Co se změnilo, je cesta *dat*, ne cesta *peněz*. Pokud se nepřihlásíte
nikdy, nic z toho neplatí a aplikace pořád komunikuje přímo s `api.stripe.com` a s nikým
jiným.

#### Přidání zařízení pomocí QR kódu

Zařízení přidáte tak, že ukážete QR kód ze zařízení, které už je přihlášené. Kód je
náhodný, **jednorázový a vyprší za dvě minuty**, a nové zařízení nedostane nic, dokud na tom
starém neklepnete na *potvrdit*. Dokud je tenhle handshake otevřený, držíme kód, jméno,
které si nové zařízení dalo, a jeho platformu — a záznam se po vypršení smaže.
Vyfotografovaný QR kód je bez vašeho potvrzujícího klepnutí k ničemu.

## Žádosti o písničky

Kapela může zapnout **žádosti o písničky**: fanoušci si pak vyberou písničku z umělcova
seznamu a volitelně zaplatí, aby ji posunuli výš ve frontě. Žádost je prostě spropitné,
které navíc nese **to, o kterou písničku šlo** — takže i tady platí totéž jméno a vzkaz,
které fanoušek ke spropitnému může připojit, a ukládá se a uchovává přesně jako každé jiné
spropitné (níže). Veřejná fronta, kterou fanoušek vidí, ukazuje jen **součty za jednotlivé
písničky** — kolik daná písnička vybrala a na kterém místě je — a **nenese žádná jména
fanoušků**. Bez účtu žije celý seznam žádostí o písničky i jeho historie jen na zařízení.

## Push notifikace

Když jste přihlášení, aplikace vám může poslat **push notifikaci** — ale jen když si ji
zapnete, na každém zařízení zvlášť, a teprve poté, co operační systém vašeho zařízení udělí
povolení. Existuje pro jedinou věc: spropitné nebo žádost o písničku, které dorazí, **když
zrovna neběží žádný set**, abyste se dozvěděli o spropitném, které byste jinak minuli.
Spropitné, které přijde, když je vaše pódium živé, neposílá nic — už se na něj stejně
díváte.

- Aby se push doručila, potřebuje **Firebase Cloud Messaging (FCM)** od Googlu pro zařízení
  **push token**. Ten token a jazyk rozhraní zařízení ukládáme na vlastním záznamu daného
  zařízení pod vaším účtem a smaže se ve chvíli, kdy oznámení vypnete, zařízení odvoláte
  nebo se odhlásíte. Mrtvé tokeny se prořezávají automaticky.
- Samotné oznámení říká, co dorazilo — částku a jméno fanouška nebo název písničky, pokud
  je nechal. Tentýž krátký seznam se uchovává v **kanálu u zvonku** vašeho účtu, omezeném na
  posledních sto položek, abyste si mohli zpětně projít, co přišlo, když jste byli pryč.
- Na webu vyžaduje doručení push malý **service worker** v kořeni webu a messaging SDK od
  Firebase, které si váš prohlížeč poprvé stáhne od Googlu (`gstatic.com`). Web push pak
  nese vlastní push služba vašeho prohlížeče (u Chromu je to ta od Googlu). Nic z toho se
  nenačte, dokud si oznámení nezapnete.
- **Účet hosta a zařízení bez účtu žádné push nedostanou**, protože push potřebuje účet,
  kterému můžeme doručovat, a token, který jste se rozhodli dát.

## Kde tohle všechno fyzicky žije

Firebase Auth, Cloud Firestore, naše Cloud Functions i klíč Cloud KMS, který obaluje vaše
tajemství ke Stripe, běží v **Evropské unii** — databáze v multiregionu Googlu `eur3`,
funkce a key ring v `europe-west1`. Google vystupuje jako náš zpracovatel podle
[podmínek ochrany soukromí a bezpečnosti Firebase](https://firebase.google.com/support/privacy)
a vlastních [zásad ochrany osobních údajů](https://policies.google.com/privacy). Jako každý
velký poskytovatel může Google pro podporu a bezpečnost zapojit i infrastrukturu mimo EU;
to se řídí těmi podmínkami, ne námi. Push notifikace, jakmile jsou předány Firebase Cloud
Messaging a push službě vašeho prohlížeče nebo telefonu, putují k vašemu zařízení po
infrastruktuře těchto firem.

## Stripe

Když fanoušek platí kartou, je na platební stránce **Stripe**, ne na naší. Stripe sbírá a
zpracovává jeho platební údaje jako samostatný správce podle
[zásad ochrany osobních údajů Stripe](https://stripe.com/privacy). Čísla karet nikdy
nevidíme.

Jak se vaše spropitné dostane k vám, závisí na režimu:

- **Bez účtu** načítá umělcova aplikace jeho vlastní spropitné ze Stripe pomocí umělcova
  vlastního omezeného klíče — přímo ze zařízení na `api.stripe.com`. **V té cestě není žádný
  server live.tips.**
- **Když je přihlášený**, klíč žije na našem serveru (zašifrovaný, jak je popsáno výše) a
  Stripe hlásí každé spropitné našemu webhooku, který ho zapíše do umělcovy vlastní historie
  ve Firestore. **V tomto režimu v té cestě server live.tips stojí** — pro data o
  spropitném, nikdy pro peníze. Jméno a vzkaz fanouška, pokud je zanechal, putují se
  spropitným do umělcovy vlastní historie a tam končí.

## Relé — jen když jsou zapnuté Revolut, MobilePay nebo Monzo

Nastavení jen se Stripe se ho vůbec netýká.

Revolut, MobilePay ani Monzo nenabízejí aplikaci žádný způsob, jak potvrdit, že platba
proběhla, takže se tato spropitná směrují přes malé open-source relé, které provozujeme na
**Firebase** — Cloud Functions a Firestore v `europe-west1`, se stránkou pro spropitné pro
fanoušky na **`tip.live.tips/t/<id>`**. Peněz se nikdy nedotkne. Tady je všechno, co
zpracovává.

### Co ukládá umělec

Vytvořením stránky pro spropitné se uloží umělcovo **zobrazované jméno, jeho veřejný
vzkaz, jeho měna, platební identifikátory, které se rozhodl zveřejnit** (jeho platební
odkaz Stripe, uživatelské jméno Revolut, MobilePay Box ID, uživatelské jméno Monzo), a
pokud jsou zapnuté žádosti o písničky, **jeho veřejný seznam písniček a ceny za jednotlivé
písničky**. To všechno jsou informace, které umělec fanouškům tak jako tak záměrně
zveřejňuje.

- **Uchování: stránka pro spropitné, za kterou nestojí žádný účet, se automaticky maže po
  90 dnech nečinnosti.** Stránka pro spropitné, která patří přihlášenému účtu, žije tak
  dlouho jako kapela, ke které patří.
- Umělec ji může kdykoli **okamžitě** smazat z aplikace.
- Nesbírá se tu žádná e-mailová adresa, žádné heslo, žádné občanské jméno, žádné bankovní
  údaje.
- Tajný kód stránky se ukládá **jen jako hash**. Kdybyste se nás na něj zeptali, nedokázali
  bychom vám ho říct; umíme ho jen ověřit.

### Co posílá fanoušek

Formulář pro spropitné se ptá na **částku** a volitelně na **jméno** a **vzkaz** — a u
žádosti o písničku na to, o kterou písničku jde. To je celý formulář. Žádný e-mail, žádné
telefonní číslo, žádný účet.

Kam ten text napsaný fanouškem putuje a na jak dlouho, závisí na tom, jestli je umělec
přihlášený:

- **Pokud za stránkou pro spropitné nestojí žádný účet**, zapíše se spropitné do
  **doručovací fronty** — jediného dokumentu, který existuje proto, aby byl předán na
  umělcovu obrazovku. Když obrazovka spropitné zobrazí, **umělcovo zařízení ten dokument
  smaže.** To smazání *je* to potvrzení. Pokud je umělcova obrazovka offline — zamčený
  telefon, žádný signál — spropitné **čeká v té frontě až jednu hodinu**, aby se prostě
  neztratilo, a přejde ve chvíli, kdy se obrazovka znovu připojí. Pokud se nikdo nepřipojí,
  je **smazáno, aniž by ho kdo viděl**, vymetené podle rozvrhu. U umělce bez účtu je **ta
  fronta jediné místo, kde se text napsaný fanouškem vůbec kdy ukládá na našem serveru, a
  jedna hodina je jeho tvrdý limit.**
- **Pokud stránka pro spropitné patří přihlášenému účtu**, žádná fronta není. Náš server
  zapíše spropitné **rovnou do umělcovy vlastní historie** pod jeho uid — do dnešního
  vystoupení, pokud běží set, nebo do vlastního archivu kapely, pokud neběží. Tam zůstává
  **tak dlouho jako kapela**; je to umělcova vlastní historie a přesně kvůli ní se přihlásil.
  Je to tatáž historie, do které zapisuje webhook Stripe výše.
- Vaše jméno a vzkaz se také vkládají do **poznámky k platbě**, která se otevře v
  Revolutu, MobilePay nebo Monzu — tak umělec pozná, kdo poslal spropitné. Tyto firmy je
  pak zpracovávají podle vlastních zásad ochrany osobních údajů.
- Relé neuchovává **žádnou účetní knihu spropitného napříč umělci**. Nemůže vám, nám ani
  nikomu jinému ukázat seznam toho, kdo komu napříč umělci poslal spropitné.

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
| **Google (Firebase)** | Účty, synchronizovaná data přihlášeného umělce, zašifrovaný klíč ke Stripe, relé, push tokeny a doručování, serverové logy | Volitelný účet, volitelné relé a push notifikace |
| **Google Cloud KMS** | Klíč, který obaluje tajemství přihlášeného umělce ke Stripe (nikdy samotné tajemství v čitelné podobě) | Aby byl uložený klíč ke Stripe v klidu nečitelný |
| **Stripe** | Platební údaje fanouška, jako samostatný správce; a u přihlášeného umělce události spropitného posílané našemu webhooku | Spropitné kartou |
| **Cloudflare** | IP adresu fanouška, kvůli kontrole Turnstile na stránce pro spropitné. A naše DNS. | Držení botů dál od formuláře pro spropitné |
| **GitHub** | IP adresu a user-agent každého, kdo si načte tento web | Hosting webu |
| **Push služba vašeho prohlížeče / telefonu** (např. ta od Googlu u Chromu) | Push token a obsah oznámení, pokud jste zapnuli oznámení | Doručování push notifikací |
| **Revolut / MobilePay / Monzo** | Cokoli fanoušek udělá v jejich vlastní aplikaci, včetně poznámky k platbě | Tyto platební metody |

Nikomu nic neprodáváme a na tom seznamu nikdo další není.

## Právní základ, kdybyste ho potřebovali (GDPR)

- Provozování účtu, o který jste požádali, synchronizace vašich vlastních dat na vaše
  vlastní zařízení, uchovávání vašeho klíče ke Stripe, aby se vaše spropitné dostalo do vaší
  historie, provozování relé pro umělce, který si ho zapnul, doručení fanouškova spropitného
  na obrazovku, které bylo určeno, a odeslání push, kterou jste si zapnuli: **plnění služby,
  o kterou jste požádali**.
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
- **Push notifikace**: vypněte je na zařízení a jeho push token se smaže. Kanál u zvonku se
  vymaže spolu s kapelou nebo účtem.
- **Zařízení**: Nastavení → Zabezpečení vypisuje vaše zařízení. Můžete některé odvolat nebo
  se odhlásit všude jinde — což okamžitě, ne někdy později, ukončí relaci každého dalšího
  zařízení.
- **Celý váš účet, jedním klepnutím: takové tlačítko aplikace zatím nemá.** Raději se k
  tomu přiznáme, než bychom předstírali opak. Než začne existovat, napište na
  **[contact@live.tips](mailto:contact@live.tips)** a my účet a všechno pod ním smažeme
  ručně. Mezitím už teď můžete smazat každou kapelu, což odstraní všechno podstatné —
  včetně uloženého klíče ke Stripe — a zanechá prázdný účet.

## Vaše práva

Můžete nás požádat o kopii, opravu nebo smazání čehokoli, co o vás uchováváme, a můžete
si stěžovat u svého národního úřadu pro ochranu osobních údajů. Pište na
**[contact@live.tips](mailto:contact@live.tips)**.

V praxi je většina z toho už teď ve vašich rukou: umělec může stránku pro spropitné nebo
kapelu okamžitě smazat z aplikace, nedoručené spropitné od fanoušků na stránce bez účtu se
vypaří do hodiny, a pokud se nikdy nepřihlásíte, nic z toho nikdy nebylo nikde jinde než na
vašem vlastním zařízení.

## Děti

live.tips není určen dětem a jejich údaje vědomě nezpracováváme.

## Změny

Tuto stránku budeme aktualizovat, jak se bude měnit software. Protože je celý projekt open
source, **každá minulá verze těchto zásad je ve veřejné historii gitu** — můžete si přesně
porovnat, co se změnilo a kdy.

## Jazyk

Tyto zásady vydáváme ve všech jazycích, které web podporuje, pro vaše pohodlí. Pokud se
překlad a anglická verze rozcházejí, **platí anglická verze**.
