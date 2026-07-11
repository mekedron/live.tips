---
title: Bezkontaktní spropitné pro pouliční muzikanty — poctivě spočítané
description: Tap to Pay na telefonu, čtečka karet, NFC nálepka, QR kód — čtyři různé věci, kterým se všem říká „bezkontaktní". Co každá z nich v roce 2026 doopravdy stojí, co NFC tag ve skutečnosti dělá (není to, co si myslíš) a kdy přiložení vyhraje nad naskenováním.
slug: bezkontaktni-spropitne-pro-poulicni-muzikanty
---

Zkus si vyhledat bezkontaktní spropitné pro pouliční muzikanty a internet ti podá rok
2018. Studentský prototyp z Brunel University jménem Tiptap — stojan, do kterého
zasuneš telefon — dostal tehdy kolo v tisku, a ten tisk sedí na první stránce dodnes.
Byl to hezký nápad. Byl to taky, slovy toho samého zpravodajství, projekt *stále ve
fázi vývoje* — a plánoval si od pouličních muzikantů brát jednorázový poplatek plus
**5 % z každého spropitného**. Nikdy se z toho nestalo nic, co by se dalo koupit.

(„tiptap", na který narazíš, když se po něm dneska podíváš, je nesouvisející firma z
Ontaria, která prodává bezkontaktní dárcovské terminály neziskovkám. Stejné slovo,
jiný produkt, nic pro tebe.)

Poctivý stav věcí tedy osm let nikdo nesepsal. Tady je.

Tohle je hloubkový ponor do přiložení. Jestli je tvoje skutečná otázka ta širší —
jak vůbec dostat zaplaceno, když nikdo nenosí hotovost, a co který způsob stojí —
začni u [jak pouliční muzikanti berou platby
kartou](post:how-buskers-take-card-payments) a pak se sem vrať.

## Čtyři různé věci se všechny jmenují „bezkontaktní"

Právě tady bydlí většina zmatku, tak si je oddělme, než začneme cokoli počítat.

1. **Tap to Pay na tvém vlastním telefonu.** Z telefonu se stane terminál. Fanoušek
   přiloží svou kartu nebo hodinky k *tvému* přístroji. Žádný hardware navíc.
2. **Čtečka karet** — SumUp, Zettle, Square. Malý plastový terminál, který natáhneš
   před sebe. Fanoušek se ho dotkne.
3. **NFC tag** — nálepka nebo cedulka „přilož a dej spropitné". Tohle si skoro
   všichni vykládají špatně, a další sekce je o tom proč.
4. **QR kód.** V NFC smyslu bezkontaktní není — ale čti dál, protože z pohledu
   fanouška velmi často končí přesně stejným přiložením.

Jenom první dvě věci jsou *platební terminály*. O ten rozdíl v celém tomhle článku jde.

## NFC tag žádnou platbu nepřijme

Odbuďme si to pořádně, protože prodejci tě v té víře rádi nechají.

NFC nálepka — ta levná, s čipem NTAG213, který většina z nich používá — má **144
bajtů paměti**. Ne 144 kilobajtů. Neumí spustit kód, nemá baterii, nikdy neslyšela o
kartové asociaci a platební protokol by nepojala, ani kdyby chtěla. Co pojme, je
krátký řetězec ve formátu NDEF, a ten řetězec je v drtivé většině **URL**.

Přiložíš — a telefon otevře webovou stránku. To je celá ta funkce.

Což znamená, že cedulka „přilož a dej spropitné" je QR kód, který otevíráš dotykem
místo mířením. Stejný cíl, stejná webová stránka, stejná platba probíhající v
prohlížeči. Říkají to i specialisté, když je člověk čte pozorně: tiptap na vlastním
webu popisuje své zařízení s volitelnou částkou tak, že když k němu dárci přiloží
telefon, *„budou přesměrováni na vaši online sbírkovou stránku."* Přesměrováni. Na
stránku. Protože to je to, co tag umí.

Je to opravdu užitečné a je to i levné — prázdné nálepky NTAG213 začínají v baleních
na zhruba **$0,24 za kus**. Jestli už stránku na spropitné máš, nalepit tag na
pouzdro vedle vytištěného kódu tě stojí drobné a některým fanouškům to dá rychlejší
cestu dovnitř.

Ale měj jasno v tom, co sis koupil: **druhé vchodové dveře do téže stránky.** Ne
platební terminál.

### A venku jsou to vrtošivé dveře

Ty poruchové stavy jsou reálné a žádný prodejce tagů je nevypisuje:

- **Telefon fanouška musí být odemčený a v používání.** Apple to má ve vlastní
  dokumentaci jasně: čtení tagů na pozadí probíhá jen tehdy, když se iPhone používá,
  a když je telefon zamčený, systém ho nechá nejdřív odemknout.
- **Nefunguje to, když je otevřená kamera.** Apple uvádí zapnutou kameru jako jeden ze
  stavů, ve kterých čtení tagů na pozadí není k dispozici. Vychutnej si tu ironii:
  fanoušek, který sahá po kameře, aby naskenoval tvůj QR kód, právě vypnul tvůj NFC tag.
- **Chce to iPhone XS nebo novější**, a na Androidu musí být zapnuté NFC — které
  některé úsporné režimy vypínají.
- **Dosah je asi 4 cm.** Fanoušek se toho musí opravdu dotknout. V davu, v ohnutí nad
  pouzdrem od kytary, to je docela požadavek.
- **Kov a magnety to zabijou.** Tag přilepený na komb, nebo fanoušek s magnetickým
  pouzdrem — a nestane se vůbec nic.

Tag je hezká druhá možnost. Jako jediná možnost je špatná.

## Tap to Pay na telefonu: skutečná novinka roku 2026

Tohle se od těch článků o Tiptapu změnilo a nic z toho zastaralého zpravodajství o
tom neví.

**Tap to Pay na iPhonu** dělá z telefonu, který už máš v kapse, bezkontaktní terminál.
Žádný dongle, žádná čtečka, žádný stojan. Apple ho uvádí jako dostupný ve **více než
70 zemích a regionech** a poskytovatelé, přes které ho v Evropě můžeš používat, se
čtou jako celé odvětví — jen v Německu: Adyen, Mollie, myPOS, Nexi, PAYONE, Rapyd,
Revolut, Sparkassen, Stripe, SumUp, Viva.com. Británie, Francie, Nizozemsko, Švédsko,
Finsko i Dánsko mají podobné seznamy. Potřebuješ iPhone XS nebo novější.

**Tap to Pay na Androidu** existuje taky, ale je užší. Přes Stripe je obecně dostupný
v AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG a US, dalších
osmnáct zemí je ve veřejném náhledu. Tvůj telefon potřebuje Android 13 nebo novější,
NFC senzor, needitovaný bootloader, Google Mobile Services a vypnuté vývojářské volby
— to poslední chytne víc lidí, než by sis myslel.

Praktická verze: **SumUp uvádí Tap to Pay za £0 hardwaru.** Jestli máš současný iPhone
a jsi v podporované zemi, vstupní náklad na to, abys někomu natáhl bezkontaktní
terminál, je teď nulový. Už jenom tenhle fakt dělá z každého článku z roku 2018 ve
stylu „kup si tenhle stojan" přežitek.

## Čtečky karet a co doopravdy stojí

Jestli chceš samostatný kus plastu — a existují k tomu dobré důvody, viz níž — trh se
skládá ze tří produktů.

| | Hardware | Poplatek za jedno přiložení na místě |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay £0 · Solo Lite £25 · Solo £79 · Terminal £135 | **1,69 %**, žádný pevný poplatek |
| **SumUp** (Německo) | — | **1,39 %**, žádný pevný poplatek |
| **Zettle / PayPal POS** (UK) | Čtečka od £29 pro nového uživatele, potom £69 | **1,75 %**, žádný pevný poplatek |
| **Square** (UK) | Bezkontaktní a čipová čtečka £19 | **1,75 %**, žádný pevný poplatek |
| **Square** (US) | Bezkontaktní a čipová čtečka $59 | **2,6 % + $0,15** |

Ceny bez DPH, tak jak byly zveřejněné v červenci 2026. Jdi si je ověřit; hýbou se.

A teď si tu tabulku přečti znovu, protože říká něco, co odporuje tomu, co ti nejspíš
napovídali.

## Počítání poplatků a to, co má každý obráceně

Přijatá moudrost zní, že kartové poplatky ničí malé spropitné kvůli pevné částce za
transakci — těm pětadvaceti centům, které sežerou osminu spropitného €2. To je pravda
a [sami jsme si tu matematiku sepsali](post:build-a-tip-jar-on-your-own-stripe).

Ale platí to pro kartové platby *online*. **Evropské bezkontaktní čtečky většinou
žádný pevný poplatek vůbec nemají.** SumUp, Zettle a Square v Británii a v EU účtují
čistě procenta. Což znamená:

| Spropitné €2 | Poplatek | Umělci zůstane | Efektivní podíl |
| --- | --- | --- | --- |
| Čtečka SumUp (DE, 1,39 %) | €0,03 | €1,97 | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | €0,04 | €1,96 | 1,8 % |
| Stripe, karta online (EHP, 1,5 % + €0,25) | €0,28 | €1,72 | **14,0 %** |
| Čtečka Square (US, 2,6 % + $0,15) | $0,20 | $1,80 | **10,1 %** |

Na samotném poplatku evropský bezkontaktní terminál u malého spropitného porazí
online kartovou platbu, a není to ani těsné. Jsme QR kódový produkt a říkáme ti to: u
spropitného €2 ti čtečka SumUp nechá €0,25, které ti stránka hostovaná Stripem nenechá.

Dvě věci to vracejí do proporcí.

**Hardware je ten pevný poplatek, jen přesunutý.** Úspora €0,25 na spropitném proti
Solu za £79 znamená zhruba **tři sta přiložení, než se čtečka zaplatí**. Pro
pracujícího pouličního muzikanta je to reálné číslo, pro někoho, kdo hraje dvakrát za
léto, číslo bláznivé. (A Tap to Pay od SumUpu za £0 z toho dělá nula přiložení — a
právě proto je ta možnost důležitější než samotné čtečky.)

**A Spojené státy to překlápějí zpátky.** Americká sazba Square za platbu na místě
nese pevných $0,15, takže i přiložení za $2 přijde na terminálu o desetinu sebe. Dárek
jménem „žádný pevný poplatek" je evropský.

Existuje ještě jedna hranice, na kterou narazíš: SumUp nepřijme platbu pod **£1 / €1**.
Ať si vybereš jakoukoli kolej, opravdu malé spropitné vlastně není kartová transakce.

## Kdy tedy přiložení porazí naskenování?

Sundej z toho technologii a zbude otázka o rukou fanouška.

**Přiložení potřebuje, aby měl fanoušek telefon odemčený a v ruce, a aby ses ty měl
volno něco natáhnout.** Když platí obojí, je to to nejrychlejší, co platby nabízejí.
Žádná aplikace, žádné míření, žádné psaní, hotovo za vteřinu.

**Naskenování potřebuje, aby fanoušek otevřel kameru** — jeden vědomý úkon navíc — ale
od tebe nepotřebuje vůbec nic. Kód sedí na pouzdru. Funguje na fanouškovi, který stojí
vzadu. Funguje na čtyřiceti lidech naráz. Funguje, zatímco pořád hraješ.

Z čehož vychází poctivé dělení:

- **Přiložení vyhrává, když můžeš dojít k lidem.** Konec setu, klobouk kolem, jeden
  fanoušek po druhém, ty volný držet terminál. Přiložení je menší žádost než „vytáhni
  si kameru" a v tu chvíli u toho fyzicky stojíš a můžeš to uzavřít.
- **Naskenování vyhrává, když nemůžeš.** Uprostřed písničky. Dav ve třech řadách.
  Místo, ze kterého nemůžeš odejít od komba. Kdokoli, kdo chce dát cestou kolem.
  Terminál obslouží přesně jednoho člověka; vytištěný kód obslouží celé náměstí
  najednou a nepotřebuje k tomu, abys přestal hrát.

Ten poslední bod prodejci terminálů nikdy neuvádějí, a je největší. **Čtečka karet je
úzké hrdlo s frontou.** QR kód žádnou frontu nemá.

A tady je ta část, která rozpouští polovinu celého sporu: na dobře postavené stránce
na spropitné **naskenování stejně končí přiložením**. Fanoušek naskenuje, stránka se
otevře a jeho telefon nabídne Apple Pay nebo Google Pay. Dvojklik, telefon k obličeji,
hotovo. Z pohledu fanouška je tohle bezkontaktní platba — stejná peněženka, stejná
karta, stejné dvě vteřiny — a tys na to nekoupil žádný hardware.

## Kde v tom sedí live.tips a kdy si místo toho koupit SumUp

[live.tips](https://github.com/mekedron/live.tips) je kasička na spropitné postavená
na QR. Jeden kód, který se nikdy nemění, mířící rovnou na umělcův vlastní platební
odkaz Stripe. Neexistuje žádný zůstatek live.tips, žádný podíl a žádná platforma v
cestě — poplatek je Stripův vlastní a Stripe ho účtuje umělci přímo. Je to pod licencí
MIT a tablet na pódiu ukazuje každé spropitné v okamžiku, kdy dorazí. Cestu peněz jsme
sepsali v [jak live.tips zachází s penězi](post:how-live-tips-handles-money) a proč je
to [jeden kód místo jednoho na každého poskytovatele](post:one-qr-code-every-payment-method)
taky.

Ta stránka podporuje Apple Pay a Google Pay. Takže live.tips *je* z pohledu fanouška
bezkontaktní — u toho přiložení, na kterém záleží, u toho na konci, bez terminálu,
který by se musel kupovat, nabíjet nebo upustit v dešti. Jenom to není terminál.

**Jestli chceš fyzicky něco natahovat a nechat to cizího člověka přiložit, kup si
čtečku karet.** Vezmi Tap to Pay od SumUpu, jestli to tvůj telefon a tvoje země
zvládnou, protože nestojí nic; vezmi Solo, jestli radši nebudeš strkat vlastní telefon
do davu. Tak či tak, u přiložení za €2 v Evropě to porazí náš poplatek, a my to radši
řekneme, než abychom předstírali opak.

Můžeš dělat i obojí, a spousta pouličních muzikantů by měla: kód nalepený na pouzdru
celý večer, chytající kolemjdoucí, zatímco hraješ — a terminál v ruce na těch deset
vteřin po posledním akordu, kdy první řada sahá do kapes. Nesoutěží spolu. Chytají
různé lidi.

Co ani jeden z nich není, je stojan z roku 2018, který si bere 5 %.

Poplatky, ceny hardwaru a dostupnost v zemích tak, jak je v červenci 2026 zveřejnily Apple, Stripe, SumUp, Zettle/PayPal a Square, bez DPH. Ceny NFC nálepek podle GoToTags. Podmínky Tiptapu z roku 2018 podle Brunel University a Finextry. Všechno tady se mění; ověř si to u dodavatele, než utratíš peníze.
{: .footnote }
