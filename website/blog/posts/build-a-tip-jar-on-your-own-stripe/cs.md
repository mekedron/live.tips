---
title: Postavte si kasičku na spropitné na vlastním účtu Stripe
description: Tři volání API vám dají hostovanou stránku „zaplať, kolik chceš“ s Apple Pay a Google Pay — a žádný server. Tady je celá stavba: omezený klíč, oprávnění, jak číst spropitné bez webhooku, a poctivá matematika poplatků, kterou nikdo netiskne.
slug: postavte-si-kasicku-na-spropitne-na-vlastnim-uctu-stripe
---

Chcete kasičku na spropitné. Nechcete dát platformě 5 % z večera pouličního muzikanta a
s API si poradíte úplně bez problémů. Otázka tedy nezní *u které kasičky se mám
zaregistrovat*, ale *kolik toho vlastně musím postavit*.

Míň, než si myslíte. Na Stripu je fungující odpověď: tři volání API, žádný server, žádný
backend, žádný webhookový endpoint. Zbytek tohohle článku je právě ta stavba — plus dvě
věci, které všichni dělají špatně.

## Celý trik je Price typu „zaplať, kolik chceš“

Stripe má cenový režim, ve kterém částku píše sám fanoušek. Jmenuje se
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) a je to
celá ta funkce. Vytvoříte Product, pověsíte na něj Price s
`custom_unit_amount[enabled]=true` a nad to
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. věc, kterou "prodáváte"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. cena, kterou si vybere fanoušek
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. stránka
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=donate
```

To třetí volání vrátí `url`. Ta URL *je* vaše kasička. Je to stránka hostovaná Stripem —
tedy PCI-compliant, aniž byste na to museli myslet, lokalizovaná, a ukáže Apple Pay nebo
Google Pay každému fanouškovi, který je má v telefonu nastavené;
[dynamické platební metody](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
to za vás rozhodnou podle zařízení a země. Nenapsali jste žádný frontend.

Zakódujte URL do QR kódu libovolnou knihovnou — je to jen řetězec — vytiskněte, přilepte na
pouzdro. Kód nikdy nevyprší a neukazuje na žádný váš server, protože žádný nemáte.

Dva parametry, které se vyplatí znát:

- **`custom_unit_amount[preset]`** je částka, se kterou se stránka otevře. `500` znamená, že
  fanoušek vidí předvyplněných 5,00 € a může je změnit. Tohle číslo udělá pro vaše průměrné
  spropitné víc než cokoli jiného na té stránce.
- **`custom_unit_amount[minimum]`** je podlaha. Nastavte ji. Důvod je v sekci o poplatcích
  níž a není to zaokrouhlovací chyba.

Můžete taky sbírat jméno a vzkaz. Payment Links berou až tři `custom_fields` — tak dostanete
„a od koho to bylo“ na stránku, aniž byste stavěli formulář:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Vaše jméno nebo přezdívka" \
  -d "custom_fields[0][optional]"=true
```

Stripe má [požadavky na přijímání spropitného a darů](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
přečtěte si je jednou. „Zaplať, kolik chceš“ se také nedá kombinovat s dalšími line items,
slevami ani opakovanými platbami. U kasičky na spropitné nic z toho nevadí.

## Klíč: počítejte s tím, že unikne — a udělejte z toho nudu

Nedávejte tajný klíč (`sk_live_…`) na zařízení, které stojí na pódiu. Použijte
[omezený klíč](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): u každého
zdroje si vyberete oprávnění a všechno, co nevyberete, zůstane na **None**.

Pro stavbu výše je úplný seznam pět řádků:

| Zdroj | Oprávnění | K čemu to je |
| --- | --- | --- |
| Products | Write | vytvořit Product |
| Prices | Write | vytvořit Price „zaplať, kolik chceš“ |
| Payment Links | Write | vytvořit odkaz |
| Checkout Sessions | Read | vidět došlé spropitné |
| Events | Read | živý feed (další sekce) |

Všechno ostatní — Balance, Payouts, Refunds, Customers, PaymentIntents, celý Connect —
zůstává na **None**.

A teď udělejte cvičení, kvůli kterému to celé stojí za to. V jednu ráno vám od merch stolku
zmizí tablet. Co s klíčem v keychainu zloděj svede? Přečte si historii spropitného a vytvoří
si ve vašem účtu další odkazy na spropitné. To je celý poloměr výbuchu. Neuvidí zůstatek,
nespustí výplatu, nepošle refundaci na kartu, kterou ovládá, nepřečte seznam zákazníků. Klíč
zrušíte z telefonu v taxíku cestou domů a zařízení zhasne. S vašimi penězi se nehnulo nic.

Ta asymetrie — zápis do kasičky, nula přístupu k penězům — je jediný důvod, proč je bezserverový
návrh s vlastním klíčem vůbec obhajitelný. Je to taky důvod, proč „Login with Stripe“ tady není
odpověď: OAuth potřebuje server vývojáře aplikace, který podrží váš token — a server je přesně
to, co nestavíme.

(Zvláštnost, na kterou narazíte: oprávnění *Prices* se interně jmenuje `plan_write`, takže
chybová hláška Stripu pojmenuje scope, který se pod tím jménem v dashboardu nevyskytuje. Jde o
Prices.)

## Číst spropitné bez webhooku

Tady většina návodů končí nebo sáhne po webhooku — a tady se pódium opravdu liší od webové
aplikace.

Webhook je příchozí HTTP požadavek. Tablet za mikrofonním stojanem ho nemůže přijmout. Visí na
hostovské Wi-Fi klubu za NATem, nemá veřejnou adresu ani TLS certifikát — a nemá důvod je mít.
Pokud půjdete cestou webhooku, musíte postavit server, který události chytí, a socket, který je
protlačí do zařízení: backend, provozní zátěž a místo, kde teď bydlí jména vašich fanoušků. Právě
jste znovu postavili platformu, které jste se chtěli vyhnout.

Tak táhněte místo toho, aby vás tlačili. Endpoint
[List all events](https://docs.stripe.com/api/events/list) je veřejný, zdokumentovaný a vrací
události od nejnovější:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_POSLEDNI_VIDENA \
  -d limit=100
```

`ending_before` je celý ten návrh. Držte si id nejnovější zpracované události; každý dotaz si
řekne o všechno striktně novější a vy posunete kurzor. Žádné časové značky, žádný rozjezd hodin,
žádná deduplikace podle částky. Při prvním dotazu setu si řekněte o `limit=1` bez kurzoru, abyste
se ukotvili na tom, co už tam je, a nepřehráli si při zvukovce spropitné z dnešního rána.

Pak filtrujte, co se vrátí. Oba typy událostí mohou vyskočit u jedné platby, takže deduplikujte
podle id Checkout Session. Kontrolujte `payment_status == "paid"` — dokončená session není nutně
zaplacená. A kontrolujte, že `payment_link` odpovídá *vašemu* odkazu, protože `/v1/events` platí
pro celý účet a s radostí vám podá provoz ze všeho ostatního, co ten účet Stripe dělá.

Buďte upřímní ohledně kompromisů, protože jsou skutečné:

- **Stripe doporučuje webhooky.** Polling není posvěcená cesta; je to zdokumentovaný endpoint
  použitý záměrně. Napište to do README a jeďte dál.
- **Události sahají 30 dní zpět.** [Slova samotného Stripu](https://docs.stripe.com/api/events/list):
  *„List events, going back up to 30 days.“* Tohle je živý feed, ne účetní kniha. Vaše kniha jsou
  Checkout Sessions — a ta opravdová je dashboard Stripu.
- **Hlídejte si kvótu čtení.** Všichni koukají na limit za sekundu
  ([rate limits](https://docs.stripe.com/rate-limits): 100 req/s v live) a nikdo na ten druhý:
  Stripe přiděluje zhruba **500 čtecích požadavků na transakci** v klouzavém okně 30 dní, s podlahou
  10 000 čtení za měsíc. Dotazujte se po 4 sekundách a tříhodinový set je ~2 700 čtení. Čtyři dlouhé
  koncerty za měsíc a jste na podlaze. Spropitné vám s příchodem dokupuje rezervu — ale kdo se
  dotazuje každou sekundu, protože to působilo svižněji, ten strop najde. Čtyři sekundy nejsou lenost;
  jsou *to* číslo.

Takhle to vypadá poctivě: polling vás stojí pár tisíc GETů a koupí vám smazání celého backendu.

## Matematika poplatků, udělaná pořádně

Platforma, která inzeruje 0 %, není zadarmo — a tohle taky ne. Vlastní poplatek Stripu se týká
každého spropitného a Stripe ho účtuje přímo vám. Podle
[eurových cen Stripu](https://stripe.com/ie/pricing) stojí dnes standardní karta z EHP
**1,5 % + 0,25 €**. Prémiové karty z EHP 1,9 % + 0,25 €, britské 2,5 % + 0,25 € a všechno ostatní
3,25 % + 0,25 €, plus další 2 %, pokud se musí měnit měna. (V USA je to 2,9 % + 0,30 $, což je horší
přesně z důvodu níže.)

Problém není v procentu. Problém je v těch pětadvaceti centech.

| Spropitné | Stripe si vezme | Umělci zbude | Efektivní ukrojení |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Fixní poplatek je procento v přestrojení a u malých peněz přestrojení sjíždí. Těch samých 0,25 €,
neviditelných u spropitného za 50 €, sežere osminu spropitného za 2 €. Spropitné je ze své podstaty
malé — to z něj dělá spropitné — takže tohle není okrajový případ, ale případ typický.

Právě proto nastavíte `custom_unit_amount[minimum]`. Někde kolem 2 € přestává mít transakce smysl;
kartové spropitné 0,50 € by dorazilo jako 0,24 € a Stripe by stálo víc ho přesunout, než kolik má
hodnotu. Vyberte si podlahu vědomě, místo abyste ji objevili při první výplatě.

A všimněte si, co to udělá se srovnáním, kterým jste začali. Platforma, která si bere 0 % nad rámec
Stripu, si bere 0 % nad rámec **tohohle**. Jejich 0 % je skutečných — a je to 0 % z toho, co nechal
zpracovatel. Ničí kartová kolej není zadarmo: poctivé tvrzení zní „žádné ukrojení nad rámec toho, co
si bere zpracovatel“, a kdo tvrdí víc, buď lže, nebo nepoužívá karty.

## Co teď máte a co ne

Tři volání API a QR kód — a skutečnou kasičku: hostovanou, PCI-compliant, Apple Pay, Google Pay,
spropitné padající na váš vlastní zůstatek u Stripu podle vašeho vlastního výplatního rozvrhu, a žádný
server v cestě. Pro spoustu lidí je tohle upřímně konec projektu a klidně se tu můžete zastavit a vydat to.

Co nemáte, je pódium. Máte platební stránku. Mezi tím stojí ty nudné věci: pollovací smyčka s kurzorem a
backoffem, obrazovka, kterou vidí publikum, s cílem a posledním vzkazem, místo pro klíč, které se nejmenuje
`localStorage`, zámek, aby vám mezi sety cizí člověk nešťoural do tabletu, a vrstva tisíce malých rozhodnutí
o tom, co se stane, když uprostřed setu spadne klubová Wi-Fi.

Přesně tím je [live.tips](https://github.com/mekedron/live.tips) — tahle architektura, dodělaná, pod licencí
MIT. Omezený klíč s těmi pěti oprávněními, kurzorová smyčka nad `/v1/events`, vytváření
Product/Price/Payment Link — všechno běží na zařízení umělce proti jeho vlastnímu účtu. V cestě ke Stripu
není žádný server live.tips a nikde není žádný zůstatek live.tips, což jsme sepsali zvlášť v článku
[jak live.tips zachází s penězi](post:how-live-tips-handles-money).

Přečtěte si zdroják, vezměte si, co chcete, nebo to prostě použijte. Pointa tohohle článku je, že architektura
není tajemství ani nic těžkého: **Stripe vám kasičku na spropitné bude hostovat zdarma a omezený klíč plus
pollovací smyčka je všechno, co stojí mezi umělcem a jeho vlastními penězi.** Radši ať to víte, než abyste se
někam registrovali.
