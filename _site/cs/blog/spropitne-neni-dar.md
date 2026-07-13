# Spropitné není dar — a Stripe je vede jako dvě různá podnikání

> Pouliční muzikant, který si přeje „tlačítko Donate", popisuje podnikání, které Stripe ve většině Evropy zakazuje. Spropitné platí za službu, kterou jsi už odvedl; dar je dobročinná sbírka. Ten rozdíl rozhoduje, do jaké kategorie tvůj účet spadne — a jeden parametr API ji dokáže vybrat za tebe špatně.

Canonical: https://live.tips/cs/blog/spropitne-neni-dar/
Published: 2026-07-11
Language: cs
Tags: Stripe, donations, busking, compliance, how-to

---

Každý nástroj na internetu chce, abys tomu říkal dar. Tlačítka hlásají *Donate*.
Blogové články mluví o *tlačítku pro dary pro muzikanty*. Katalogy pluginů slibují
*přijímání darů*. Když jsi muzikant a hledáš způsob, jak ti můžou zaplatit lidé bez
hotovosti, to slovo tě pronásleduje všude.

Pak si založíš účet u Stripu a Stripe se zeptá, co tvoje podnikání dělá. A v tu
chvíli to slovo přestává být marketingovou frází a stává se **kategorií podnikání**
— takovou, kterou Stripe ve většině Evropy nepovoluje.

Tohle není hnidopišství a není to právnická finta. Je to jediná otázka, která
nejspíš ze všech dokáže poslat platební účet naprosto obyčejného pouličního
muzikanta do kontroly, do zdržení nebo do zamítnutí. Skoro nikdo to muzikantům
nenapsal na rovinu, tak tady to je.

## Dvě slova, dvě podnikání

Stripe tu čáru vede sám, každou jednou větou. Ze stránky
[Podmínky pro přijímání spropitného nebo darů](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> spropitné musí být dáno za zboží nebo službu, které byly poskytnuty (např. obsah)

> dar musí být vázán na konkrétní charitativní účel, k jehož naplnění se zavazujete

Stripe má tyhle stránky jen anglicky; originální znění najdeš za odkazy.

Přečti si to dvakrát, protože všechno ostatní v tomhle článku z těch dvou vět
vypadává.

**Spropitné** se ohlíží zpátky na něco, co se už stalo. Služba byla poskytnutá,
fanouškovi se líbila, fanoušek přidal peníze navíc. Ty peníze jsou bez podmínek a
už nic nedlužíš. Tohle je řádek se spropitným na účtu v restauraci, mince v
klobouku, stovka vtisknutá do dlaně po poslední písničce.

**Dar** se dívá dopředu na něco, co jsi slíbil udělat. Je tu věc, o kterou jde. Je
tu účel, který jsi tomu, kdo dává, popsal. A — Stripe je v tom naprosto výslovný —
ty peníze na ten účel musí opravdu jít. Držíš je ve svěřenectví pro věc, kterou jsi
řekl, že naplníš.

To nejsou dva odstíny téhož skutku. Jsou to dva různé vztahy se dvěma různými
soubory závazků a Stripe je upisuje jako dvě různá podnikání.

## Pouliční muzikant stojí jednoznačně a bez pochyb na straně spropitného

Stál jsi dvě hodiny na náměstí a hrál. Čtyřicet lidí se zastavilo. Jeden z nich
naskenuje tvůj kód a pošle ti pět eur.

**To je spropitné.** Ta služba je vystoupení. Bylo poskytnuté — dívali se, jak se
děje. Není tu žádná věc, o kterou jde, žádný příjemce, žádný účel, k jehož naplnění
by ses zavázal, a nikdo ti nesvěřil peníze na projekt. Jsi výkonný umělec, kterému
platí za vystoupení, což je jedno z nejstarších a nejméně sporných obchodních
ujednání, jaká existují.

Zmatek plyne z toho, že spropitné pouličnímu muzikantovi je *dobrovolné* a my jsme
vycvičení myslet si, že dobrovolné peníze jsou charitativní peníze. Nejsou.
Spropitné je taky dobrovolné. Dobrovolnost není to, co z něčeho dělá dar — z něčeho
dělá dar **dobročinný účel**.

Takže když máš na ceduli „děkujeme za dary", nejsi skromný ani zdvořilý. Popisuješ,
slovníkem platebního zpracovatele, podnikání, ve kterém nepodnikáš.

## Co tě to slovo doopravdy stojí

Tady se abstrakce mění v peníze.

Stripe zveřejňuje
[seznam omezených podnikání](https://stripe.com/legal/restricted-businesses) — věci,
které se Stripe účtem dělat nesmíš, nebo smíš jen v některých zemích. Pod nadpisem
**Crowdfunding a získávání prostředků** stojí doslova tohle:

> Organizace získávající prostředky na charitativní účel (Poznámka: Podporováno v
> Austrálii, Kanadě, Spojeném království a Spojených státech. Zakázáno ve všech
> ostatních zemích.)

Čti tu závorku pomalu. Dobročinná sbírka je **podporované podnikání ve čtyřech
zemích** — Austrálie, Kanada, Spojené království, Spojené státy — a **zakázané
všude jinde.**

Všude jinde zahrnuje Německo, Francii, Španělsko, Itálii, Nizozemsko, Polsko,
Finsko a každou další zemi, kde by pouliční muzikant mohl rozumně stát. Zahrnuje to
i **Česko**: dobročinná sbírka přes Stripe u nás spadá pod „všechny ostatní země" a
podporovaná není. Většina pouličních umělců světa žije právě tam, ve „všech
ostatních zemích".

Tatáž stránka uvádí jako omezené i *„získávání prostředků prováděné neziskovými
organizacemi, charitami, politickými organizacemi a podniky nabízejícími protiplnění
výměnou za dar"* a stránka Stripu o spropitném a darech k tomu přidává sadu pravidel
pro jednotlivé země: v Japonsku nemůžou jednotlivci přijímat dary vůbec; v Singapuru
jen státem registrované charitativní nebo náboženské organizace; v Indii, Hongkongu
a Thajsku dary podporované nejsou.

Takže muzikant v Berlíně, který do registračního formuláře Stripu napíše „dary na
moji hudbu", právě popsal podnikání, které Stripe v Německu zakazuje. Ne proto, že
by bylo zakázané hrát na ulici — hrát na ulici je naprosto v pořádku — ale proto, že
slova, která si vybral, patří do kategorie, která zakázaná je.

## A teď kalibrace, protože tohle není horor

**Pouliční muzikanti nejsou omezené podnikání.** Spropitné není omezené podnikání.
Živé vystoupení na tom seznamu není, nedostane tě na něj a je asi tak obyčejná věc,
jakou se dá s platebním účtem dělat. Když se popíšeš přesně, nic z tohohle se tě
netýká a nastavení je nudné, což je přesně tak, jak to má být.

Riziko tady není Stripe. Riziko je **špatné zařazení sebe sama** — vejít do
místnosti a ohlásit se jako charitativní sbírka, když jsi kytarista. Stripe nemá jak
vědět, že jsi myslel „dejte mi prosím spropitné". Má jen formulář, který jsi
vyplnil, popis podnikání, který jsi napsal, a slova na stránce, kam míří tvůj QR
kód.

Nikdo ve Stripu nehoní pouliční muzikanty. Jenom čtou, co jsi jim řekl ty.

## Ta past je hluboká na jeden parametr

Tady je část, kterou skoro nikdo nesepsal, a je to to nejužitečnější v celém článku.

Platební odkazy Stripu mají parametr `submit_type`.
[Referenční dokumentace API](https://docs.stripe.com/api/payment-link/object) ho
popisuje jako něco skoro kosmetického:

> Označuje typ prováděné transakce, což upravuje příslušný text na stránce, například
> odesílací tlačítko.

*Upravuje příslušný text.* Rozumně bys z toho usoudil, že to mění popisek tlačítka a
že kasička na spropitné by měla samozřejmě říkat *Donate* („darovat") spíš než *Buy*
(„koupit"), protože *Buy* je pod kloboukem pouličního muzikanta divné slovo.

Pak si přečteš, co jednotlivé hodnoty vlastně dělají:

> `donate` — Doporučeno při přijímání darů. Odesílací tlačítko obsahuje popisek
> 'Donate' a adresy URL používají hostname `donate.stripe.com`

> `pay` — Odesílací tlačítko obsahuje popisek 'Buy' a adresy URL používají hostname
> `buy.stripe.com`

**Není to popisek. Je to hostname.** Nastav `submit_type=donate` a odkaz, který ti
Stripe podá — ten, ze kterého uděláš QR kód, vytiskneš ho a přilepíš na pouzdro od
kytary — bydlí na `donate.stripe.com`. Každý fanoušek, který ho naskenuje, uvidí
stránku pro dary. Každá platba na tvém dashboardu prošla darovacím tokem. QR kód na
tvém pouzdru říká Stripu, říká tvému publiku a nakonec říká i tobě, že vybíráš dary.

Nikdy jsi slovo „dar" nikam nenapsal. Napsal ho za tebe jeden parametr API — a
vytiskl ho na plastovou ceduli na veřejném náměstí.

Do téhle pasti se šlápne snadno a není to chyba toho, kdo do ní šlápne: parametr je
dokumentovaný jako změna textu, *Donate* je pod kloboukem pouličního muzikanta
zjevně hezčí slovo a důsledek — zařazení podnikání — leží na stránce o dvě věty
dál, než většina lidí dočte.

live.tips posílá `submit_type=pay`. Odkaz každého umělce je odkaz na
`buy.stripe.com` a v kódu u toho stojí komentář s vysvětlením proč, protože je to
přesně ta věc, kterou by budoucí přispěvatel jinak „vylepšil".

## Co by měl muzikant doopravdy udělat

Nic z tohohle nevyžaduje právníka. Vyžaduje to pět minut a několik obyčejných slov.

- **Popiš skutečné podnikání** v registraci u Stripu. „Živá hudební produkce."
  „Pouliční umělec." „Muzikant — spropitné od publika na živých vystoupeních." Řekni,
  že vystupuješ a že ty platby jsou spropitné za ta vystoupení.
- **Vyber kategorii, která tomu odpovídá.** Živá zábava, scénická umění, hudebník. Ne
  charita, ne nezisková organizace, ne získávání prostředků.
- **Použij `submit_type=pay`**, pokud si platební odkaz stavíš sám. Jestli ho za tebe
  postavil nějaký nástroj, podívej se na URL, kterou vyrobil: `buy.stripe.com` je
  kasička na spropitné, `donate.stripe.com` je stránka pro dary. To je dvouvteřinová
  kontrola a řekne ti, za co tě tvůj nástroj považuje.
- **Neříkej tomu dar** — ani na ceduli, ani na webu, ani v popisu podnikání u Stripu.
  „Spropitné", „kasička", „podpoř kapelu", „kup nám pivo" — všechno tohle popisuje,
  co se opravdu děje. „Darujte" popisuje něco jiného.
- **Skutečnou sbírku drž zvlášť.** Jestli hraješ benefiční koncert a peníze jdou na
  dobrou věc, tohle opravdu *je* dobročinná sbírka a pravidla výše jsou teď o tobě —
  včetně toho seznamu zemí. Dělej to na správném účtu, ve správné zemi, po přečtení
  podmínek Stripu, a nikdy ne přes kasičku, kterou používáš na běžných koncertech.

Ta poslední zaslouží důraz, protože je to poctivá polovina celého argumentu.
Neříkáme, že dary jsou špatné nebo že muzikant nikdy nesmí vybírat na dobrou věc.
Říkáme, že je to **jiná činnost** s jinými pravidly a že hnát ji potichu přes stejný
QR kód je způsob, jak si zavařit obojí.

Ještě jedna věta ze stránky Stripu o spropitném a darech stojí za to, protože
vylučuje třetí věc, kterou si lidi s oběma pletou: Stripe nedělá *„zpracování plateb
pro osobní převody nebo převody mezi lidmi navzájem (např. posílání peněz mezi
kamarády)"*. Spropitné taky není dárek mezi kamarády. Jestli chceš tuhle kolej —
fanoušek ti prostě pošle peníze, člověk člověku — na to jsou Revolut nebo MobilePay,
a proto v naší aplikaci žijí
[úplně mimo Stripe](https://live.tips/cs/blog/jeden-qr-kod-vsechny-platebni-metody/).

## Čím tenhle článek není

Není to právní poradenství. Není to daňové poradenství — jak se spropitné daní, se
ohromně liší podle země, občas i podle města, a je to úplně mimo rozsah tohohle
textu; zeptej se někoho kvalifikovaného tam, kde bydlíš.

A není to slib ohledně tvého účtu. **Jestli tě Stripe schválí, je čistě rozhodnutí
Stripu.** live.tips nemá se Stripem žádný vztah, žádnou možnost ovlivnit kontrolu a
žádný způsob, jak se proti ní za tebe odvolat. Co náš software udělat může, je
nevkládat ti slova do úst. Co napíšeš do formuláře, píšeš pořád ty.

Pravidla se taky mění. Řádky citované tady byly na stránkách Stripu v červenci 2026
a odkazy jsou hned tamhle; jdi si je přečíst sám, místo abys věřil nějakému
blogovému článku — včetně tohohle.

## Krátká verze

Odehrál jsi set. Dívali se na něj. Zaplatili ti za něj.

To je spropitné. Řekni to tak — na ceduli, ve formuláři, v URL — a nudný výsledek,
který chceš, je ten, který dostaneš. Kasičku na spropitné stavíme přesně kolem
tohohle tvrzení, až dolů k tomu,
[na které hostname Stripu míří tvůj QR kód](https://live.tips/cs/blog/postavte-si-kasicku-na-spropitne-na-vlastnim-uctu-stripe/),
a jestli chceš širší obrázek toho, kudy ty peníze doopravdy tečou, ten je
[tady](https://live.tips/cs/blog/jak-live-tips-naklada-s-penezi/).
