---
title: Snertilaust þjórfé fyrir götuspilara — reiknað heiðarlega
description: Tap to Pay í símanum, kortalesari, NFC-límmiði, QR-kóði — fjórir ólíkir hlutir sem allir kallast „snertilausir“. Hvað hver þeirra kostar í raun árið 2026, hvað NFC-merki gerir í alvöru (ekki það sem þú heldur), og hvenær snerting slær skönnun.
slug: snertilaust-thjorfe-fyrir-gotuspilara
---

Leitaðu að snertilausu þjórfé fyrir götuspilara og internetið réttir þér árið 2018.
Frumgerð nemenda við Brunel University sem hét Tiptap — statíf sem þú stingur síma í —
fékk umfjöllunarlotu það árið, og sú umfjöllun situr enn á fyrstu síðu. Þetta var
falleg hugmynd. Hún var líka, með orðum umfjöllunarinnar sjálfrar, *enn á
þróunarstigi*, og til stóð að rukka götuspilara um eingreiðslu auk **5 % af hverju
einasta þjórfé**. Það varð aldrei að neinu sem hægt er að kaupa.

(„Tiptap“-ið sem þú finnur ef þú leitar núna er ótengt fyrirtæki í Ontario sem selur
snertilausa styrktarposa til góðgerðarfélaga. Sama orð, önnur vara, ekki fyrir þig.)

Heiðarlega staðan hefur því verið átta ár óskrifuð. Hér er hún.

Þetta er djúpköfun í snertinguna. Ef raunverulega spurningin þín er sú stærri —
hvernig götuspilari fær yfirhöfuð borgað núna þegar enginn ber reiðufé, og hvað hver
leið kostar — byrjaðu þá á [hvernig götuspilarar taka við
kortagreiðslum](post:how-buskers-take-card-payments) og komdu svo aftur hingað.

## Fjórir ólíkir hlutir kallast allir „snertilausir“

Hér býr mestallur ruglingurinn, svo aðskiljum þá áður en við verðleggjum nokkuð.

1. **Tap to Pay í þínum eigin síma.** Síminn þinn verður posinn. Aðdáandinn ber kortið
   sitt eða úrið upp að *þínu* tæki. Enginn aukabúnaður yfirhöfuð.
2. **Kortalesari** — SumUp, Zettle, Square. Lítill plastposi sem þú réttir fram.
   Aðdáandinn ber kortið upp að honum.
3. **NFC-merki** — límmiðinn eða skiltið með „snertu hér til að gefa þjórfé“. Þetta er
   misskilið nánast alls staðar, og næsti kafli fjallar um hvers vegna.
4. **QR-kóði.** Ekki snertilaus í NFC-skilningi — en lestu áfram, því frá sjónarhóli
   aðdáandans endar hann mjög oft í nákvæmlega sömu snertingunni.

Aðeins þeir tveir fyrstu eru *greiðsluposar*. Sá greinarmunur er allur þessi pistill.

## NFC-merkið tekur ekki við greiðslu

Klárum þetta almennilega, því söluaðilar leyfa þér fúslega að halda annað.

NFC-límmiði — ódýra gerðin, NTAG213-kubburinn sem flestir nota — hefur **144 bæti í
minni**. Ekki 144 kílóbæti. Hann getur ekki keyrt kóða, hann hefur enga rafhlöðu, hann
hefur aldrei heyrt minnst á kortakerfi, og hann gæti ekki geymt greiðslusamskiptareglu
þótt hann vildi. Það sem hann geymir er stuttur strengur, sniðinn sem NDEF-færsla, og
sá strengur er í yfirgnæfandi meirihluta tilvika **vefslóð**.

Snertu hann, og síminn þinn opnar vefsíðu. Það er öll virknin.

Sem þýðir að „tap to tip“-skilti er QR-kóði sem þú opnar með því að snerta í stað þess
að miða. Sami áfangastaður, sama vefsíða, sama greiðslan sem á sér stað í vafranum.
Jafnvel sérfræðingarnir segja þetta þegar þeir eru lesnir gaumgæfilega: tiptap lýsir
sjálft tækinu sínu fyrir frjálsar upphæðir þannig að þegar gefendur halda símanum upp
að því, *„er þeim vísað á söfnunarsíðuna þína á netinu.“* Vísað á síðu. Því það er það
sem merki getur gert.

Þetta er raunverulega gagnlegt, og það er líka ódýrt — auð NTAG213-límmiðar byrja í
kringum **0,24 $ stykkið** í pakkningum. Ef þú ert þegar með þjórfésíðu kostar merki á
kassanum við hliðina á prentaða kóðanum þig smápeninga og gefur sumum aðdáendum
hraðari leið inn.

En vertu með á hreinu hvað þú keyptir: **aðrar útidyr að sömu síðunni.** Ekki
kortaposa.

### Og utandyra eru þetta hvimleiðar útidyr

Bilanirnar eru raunverulegar, og enginn sem selur merki telur þær upp:

- **Sími aðdáandans verður að vera ólæstur og í notkun.** Skjöl Apple sjálfs eru skýr:
  bakgrunnslestur merkja gerist aðeins meðan iPhone er í notkun, og sé síminn læstur
  lætur kerfið hann opna hann fyrst.
- **Það virkar ekki meðan myndavélin er opin.** Apple telur myndavél í notkun upp sem
  eitt af þeim ástöndum þar sem bakgrunnslestur merkja er ekki í boði. Njóttu
  kaldhæðninnar: aðdáandi sem grípur í myndavélina til að skanna QR-kóðann þinn er
  nýbúinn að slökkva á NFC-merkinu þínu.
- **Það þarf iPhone XS eða nýrri**, og á Android þarf NFC að vera kveikt — sem sumar
  orkusparnaðarstillingar slökkva á.
- **Drægnin er um 4 cm.** Aðdáandinn þarf í alvöru að snerta hlutinn. Í þröng, boginn
  yfir gítarkassa, er það talsvert að biðja um.
- **Málmur og seglar drepa það.** Merki límt á magnara, eða aðdáandi með segulhulstur —
  og þá gerist ekki neitt.

Merki er fínn annar kostur. Það er slæmur eini kostur.

## Tap to Pay í símanum: raunverulegu fréttirnar 2026

Hér er það sem hefur breyst frá Tiptap-greinunum, og sem engin af úreltu umfjöllununum
veit af.

**Tap to Pay á iPhone** breytir símanum sem þú ert þegar með í vasanum í snertilausan
posa. Enginn tengill, enginn lesari, ekkert statíf. Apple segir það í boði í **70+
löndum og svæðum**, og greiðslumiðlararnir sem þú getur notað það í gegnum í Evrópu
hljóma eins og öll atvinnugreinin — í Þýskalandi einu: Adyen, Mollie, myPOS, Nexi,
PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Bretland, Frakkland,
Holland, Svíþjóð, Finnland og Danmörk eru öll með svipaða lista. Þú þarft iPhone XS eða
nýrri.

**Tap to Pay á Android** er líka til en þrengra. Í gegnum Stripe er það almennt í boði
í AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG og US, og
átján lönd til viðbótar eru í opinni forskoðun. Síminn þinn þarf Android 13 eða nýrri,
NFC-skynjara, órótaðan ræsiforrita, Google Mobile Services — og slökkt á
þróunarvalkostum; það síðasta fellir fleiri en þig grunar.

Hagnýta útgáfan: **SumUp skráir Tap to Pay á 0 £ í vélbúnaði.** Sértu með nýlegan
iPhone og í studdu landi er aðgangskostnaðurinn við að rétta fram snertilausan posa nú
enginn. Sú staðreynd ein gerir hverja einustu „keyptu þetta statíf“-grein frá 2018
úrelta.

## Kortalesarar og hvað þeir kosta í raun

Viljir þú sérstakan plastbút — og það eru góðar ástæður fyrir því, sjá að neðan —
samanstendur markaðurinn af þremur vörum.

| | Vélbúnaður | Gjald á hverja greiðslu á staðnum |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, ekkert fast gjald |
| **SumUp** (Þýskaland) | — | **1,39 %**, ekkert fast gjald |
| **Zettle / PayPal POS** (UK) | Lesari frá 29 £ fyrir fyrsta skipti, 69 £ eftir það | **1,75 %**, ekkert fast gjald |
| **Square** (UK) | Snertilaus- og kubbalesari 19 £ | **1,75 %**, ekkert fast gjald |
| **Square** (US) | Snertilaus- og kubbalesari 59 $ | **2,6 % + 0,15 $** |

Verð eru án virðisaukaskatts og eins og þau voru birt í júlí 2026. Farðu og athugaðu
þau; þau hreyfast.

Lestu nú töfluna aftur, því hún segir eitthvað sem stangast á við það sem þér hefur
líklega verið sagt.

## Gjaldareikningurinn — og það sem allir hafa öfugt

Viðtekna viskan er sú að kortagjöld eyðileggi lítið þjórfé vegna fasta gjaldsins á
hverja færslu — þessi tuttugu og fimm sent sem éta áttunda part af 2 € þjórfé. Það er
satt, og við höfum [skrifað reikninginn út sjálf](post:build-a-tip-jar-on-your-own-stripe).

En það á við um kortagreiðslur *á netinu*. **Í evrópskum snertilausum lesurum er
yfirleitt ekkert fast gjald.** SumUp, Zettle og Square í Bretlandi og ESB rukka hreint
hlutfall. Sem þýðir:

| Þjórfé upp á 2 € | Gjald | Listamaðurinn heldur | Raunveruleg skerðing |
| --- | --- | --- | --- |
| SumUp-lesari (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, kort á netinu (EES, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Square-lesari (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Miðað við gjaldið eitt og sér slær evrópskur snertiposi kortagreiðslu á netinu þegar
þjórféið er lítið, og það er ekki tæpt. Við erum QR-kóða-vara og við segjum þér þetta
samt: á 2 € þjórfé heldur SumUp-lesari eftir handa þér 0,25 € sem síða hýst af Stripe
gerir ekki.

Tvennt setur þetta aftur í samhengi.

**Vélbúnaðurinn er fasta gjaldið, bara fært til.** 0,25 € sparnaður á hvert þjórfé á
móti Solo á 79 £ þýðir í grófum dráttum **þrjú hundruð greiðslur áður en lesarinn hefur
borgað sig**. Það er raunveruleg tala fyrir götuspilara í vinnu og fáránleg tala fyrir
þann sem spilar tvisvar á sumri. (Og Tap to Pay hjá SumUp á 0 £ gerir það að núll
greiðslum — sem er einmitt ástæðan fyrir því að sá valkostur skiptir meira máli en
lesararnir.)

**Og Bandaríkin snúa því aftur við.** Bandaríska staðgreiðsluverð Square ber 0,15 $
fast gjald, svo 2 $ snerting tapar líka tíund af sér við posann. Gjöfin „ekkert fast
gjald“ er evrópsk.

Það er líka gólf sem þú munt reka þig á: SumUp tekur ekki við greiðslu undir **1 £ /
1 €**. Hvaða braut sem þú velur — mjög lítið þjórfé er í raun ekki kortafærsla.

## Hvenær slær snerting þá skönnun?

Flettu tækninni af og eftir stendur spurning um hendur aðdáandans.

**Snerting krefst þess að sími aðdáandans sé ólæstur og í hendinni á honum, og að þú
sért að rétta eitthvað fram.** Þegar hvort tveggja er satt er þetta það hraðasta sem
greiðslur bjóða. Ekkert app, ekkert mið, engin innsláttur, búið á sekúndu.

**Skönnun krefst þess að aðdáandinn opni myndavél** — ein aukaleg meðvituð athöfn — en
hún krefst einskis af þér. Kóðinn situr á kassanum. Hann virkar á aðdáanda sem stendur
aftast. Hann virkar á fjörutíu manns í einu. Hann virkar meðan þú ert enn að spila.

Það gefur heiðarlega verkaskiptingu:

- **Snertingin vinnur þegar þú getur gengið að fólki.** Í lok settsins, hatturinn
  hringinn, einn aðdáandi í einu, þú laus til að halda á posa. Snerting er minni beiðni
  en „náðu í myndavélina þína“, og á því augnabliki stendur þú þarna og getur klárað
  hana.
- **Skönnunin vinnur þegar þú getur það ekki.** Í miðju lagi. Þröng í þremur röðum.
  Staður þar sem þú kemst ekki frá magnaranum. Allir sem vilja gefa á göngu framhjá.
  Posi getur afgreitt nákvæmlega eina manneskju; prentaður kóði afgreiðir allt torgið í
  einu, og hann krefst þess ekki að þú hættir að spila til að afgreiða hann.

Síðasta atriðið er það sem posasalarnir nefna aldrei, og það er stærst.
**Kortalesari er flöskuháls með biðröð.** QR-kóði hefur enga biðröð.

Og hér er hlutinn sem leysir upp hálfa rifrildið: á vel smíðaðri þjórfésíðu **endar
skönnunin hvort eð er í snertingu**. Aðdáandinn skannar, síðan opnast, og síminn hans
býður Apple Pay eða Google Pay. Hann tvísmellir, hann heldur símanum upp að andlitinu,
og það er búið. Frá sjónarhóli aðdáandans er þetta snertilaus greiðsla — sama veskið,
sama kortið, sömu tvær sekúndurnar — og þú keyptir engan vélbúnað til að láta það
gerast.

## Hvar live.tips stendur — og hvenær þú ættir frekar að kaupa SumUp

[live.tips](https://github.com/mekedron/live.tips) er þjórfékrukka byggð á QR. Einn
kóði, sem breytist aldrei, og vísar beint á greiðslutengil listamannsins í Stripe. Það
er engin live.tips-inneign, engin skerðing og enginn vettvangur á leiðinni — gjaldið er
Stripe sjálfs, og Stripe rukkar listamanninn beint. Það er MIT-leyft, og spjaldtölvan á
sviðinu sýnir hvert þjórfé um leið og það lendir. Við skrifuðum peningaleiðina upp í
[hvernig live.tips meðhöndlar peninga](post:how-live-tips-handles-money), og hvers vegna
þetta er [einn kóði frekar en einn á hvern greiðslumiðlara](post:one-qr-code-every-payment-method).

Sú síða styður Apple Pay og Google Pay. Svo live.tips *er* snertilaust frá sjónarhóli
aðdáandans — snertingin sem skiptir máli, sú í lokin, án posa sem þarf að kaupa, hlaða
eða missa í rigningu. Það er bara ekki posi.

**Ef það sem þú vilt er að rétta fram hlut sem ókunnug manneskja snertir, kauptu þá
kortalesara.** Taktu Tap to Pay hjá SumUp ef síminn þinn og landið styðja það, því það
kostar ekkert; taktu Solo ef þú vilt frekar sleppa því að rétta þinn eigin síma inn í
þröng. Hvort sem er mun það slá gjaldið okkar á 2 € snertingu í Evrópu, og við segjum
það frekar en að þykjast annað.

Þú getur líka gert hvort tveggja, og margir götuspilarar ættu að gera það: kóðinn límdur
á kassann allt kvöldið, sem grípur þá sem ganga hjá meðan þú spilar, og posinn í hendinni
þessar tíu sekúndur eftir síðasta hljóminn, þegar fremsta röðin er að grafa í vasana.
Þau keppa ekki. Þau grípa ólíkt fólk.

Það sem hvorugt þeirra er, er statíf frá 2018 sem tekur 5 %.

Gjöld, vélbúnaðarverð og framboð eftir löndum eins og Apple, Stripe, SumUp, Zettle/PayPal og Square birtu þau í júlí 2026, án virðisaukaskatts. Verð á NFC-límmiðum frá GoToTags. Skilmálar Tiptap frá 2018 eins og Brunel University og Finextra greindu frá þeim. Allt hér breytist; athugaðu það hjá söluaðilanum áður en þú eyðir peningum.
{: .footnote }
