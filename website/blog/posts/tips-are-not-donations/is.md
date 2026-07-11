---
title: Þjórfé er ekki framlag — og Stripe meðhöndlar þau sem tvo ólíka atvinnurekstur
description: Götuspilari sem biður um „framlagshnapp“ er að lýsa atvinnurekstri sem Stripe bannar í mestallri Evrópu. Þjórfé greiðir fyrir þjónustu sem þú hefur þegar innt af hendi; framlag er fjáröflun í góðgerðarskyni. Munurinn ræður því í hvaða flokk reikningurinn þinn lendir — og einn API-stiki getur valið rangan flokk fyrir þig.
slug: thjorfe-er-ekki-framlag
---

Öll verkfæri á netinu vilja að þú kallir þetta framlag. Á hnöppunum stendur
*Donate*. Bloggfærslurnar tala um *framlagshnapp fyrir tónlistarfólk*.
Viðbótaskrárnar segja *taktu við framlögum*. Ef þú ert tónlistarmaður að leita að
leið til að fá greitt frá fólki sem er ekki með reiðufé, þá eltir orðið þig
hvert sem þú ferð.

Svo opnar þú Stripe-reikning, og Stripe spyr hvað fyrirtækið þitt geri. Og á því
augnabliki hættir orðið að vera markaðstexti og verður að
**atvinnugreinaflokki** — flokki sem Stripe leyfir ekki í mestallri Evrópu.

Þetta er ekki smámunasemi, og þetta er ekki lögfræðilegur hártogningur. Þetta er
sú eina spurning sem líklegust er til að láta greiðslureikning fullkomlega
venjulegs götuspilara fara í yfirferð, tefjast eða vera hafnað. Nánast enginn
hefur skrifað þetta niður á mannamáli fyrir flytjendur, svo hér kemur það.

## Tvö orð, tveir atvinnurekstrar

Stripe dregur línuna sjálft, með einni setningu hvorum megin. Af síðunni
[Kröfur til að taka við þjórfé eða framlögum](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> þjórfé verður að vera gefið fyrir vöru eða þjónustu sem þegar hefur verið innt af
> hendi (t.d. efni)

> framlag verður að vera bundið tilteknum góðgerðartilgangi sem þú skuldbindur þig
> til að uppfylla

Síður Stripe eru á ensku; hér eru þessi orð þýdd, og frumtextinn er á bak við
tenglana.

Lestu þau tvisvar, því allt annað í þessari færslu leiðir af þeim.

**Þjórfé** horfir aftur á bak, á eitthvað sem þegar gerðist. Þjónustan var innt af
hendi, aðdáandanum líkaði hún, aðdáandinn borgaði aukalega. Peningarnir eru
skilyrðislausir og þú skuldar ekkert meira. Þetta er þjórfélínan á
veitingahúsareikningi, myntin í hattinum, fimmhundruðkallinn sem er þrýst í lófann
eftir síðasta lagið.

**Framlag** horfir fram á veginn, á eitthvað sem þú hefur lofað að gera. Það er
málstaður. Það er tilgangur sem þú hefur lýst fyrir þeim sem gefur. Og — Stripe er
afdráttarlaust um þetta — peningarnir verða raunverulega að fara í þann tilgang. Þú
heldur á þeim í trausti, fyrir eitthvað sem þú sagðist ætla að uppfylla.

Þetta eru ekki tvö blæbrigði sama verknaðar. Þetta eru tvö ólík sambönd, með tvennt
ólíkar skyldur, og Stripe metur þau sem tvo ólíka atvinnurekstur.

## Götuspilari er ótvírætt þjórfémegin við línuna

Þú stóðst á torgi í tvo tíma og spilaðir. Fjörutíu manns stöldruðu við. Einn þeirra
skannar kóðann þinn og sendir þér fimm evrur.

**Þetta er þjórfé.** Flutningurinn er þjónustan. Hún var innt af hendi — fólkið
horfði á hana gerast. Það er enginn málstaður, enginn styrkþegi, enginn tilgangur
sem þú hefur skuldbundið þig til að uppfylla, og enginn hefur falið þér peninga
fyrir verkefni. Þú ert listamaður sem fær greitt fyrir flutning, sem er eitt elsta
og ódeilanlegasta viðskiptasamband sem til er.

Ruglingurinn stafar af því að þjórfé götuspilara er *valfrjálst*, og okkur hefur
verið kennt að halda að valfrjálsir peningar séu góðgerðarpeningar. Það eru þeir
ekki. Þjórfé er líka valfrjálst. Það er ekki valfrelsið sem gerir eitthvað að
framlagi — það er **góðgerðartilgangurinn**.

Svo þegar skiltið þitt segir „framlög vel þegin“ ertu ekki að vera hógvær eða
kurteis. Þú ert að lýsa, á tungumáli greiðslumiðlarans, atvinnurekstri sem þú
stundar ekki.

## Hvað orðið kostar þig í raun

Hér verður hugtakið að peningum.

Stripe birtir
[lista yfir takmarkaðan atvinnurekstur](https://stripe.com/legal/restricted-businesses)
— það sem þú mátt ekki gera með Stripe-reikningi, eða mátt aðeins gera í sumum
löndum. Undir fyrirsögninni **Hópfjármögnun og fjáröflun** stendur þessi lína,
orðrétt:

> Samtök sem afla fjár í góðgerðarskyni (Athugið: Stutt í Ástralíu, Kanada,
> Bretlandi og Bandaríkjunum. Bannað í öllum öðrum löndum.)

Lestu svigann hægt. Fjáröflun í góðgerðarskyni er **studdur atvinnurekstur í
fjórum löndum** — Ástralíu, Kanada, Bretlandi, Bandaríkjunum — og **bönnuð alls
staðar annars staðar.**

Alls staðar annars staðar nær yfir Þýskaland, Frakkland, Spán, Ítalíu, Holland,
Pólland, Finnland, **Ísland** og hvert annað land þar sem götuspilari gæti með góðu
móti staðið. Flestir götuspilarar heimsins búa í „öllum öðrum löndum“. Þú býrð
næstum örugglega þar líka.

Sama síða telur einnig upp sem takmarkað *„fjáröflun á vegum félagasamtaka,
góðgerðarsamtaka, stjórnmálasamtaka og fyrirtækja sem bjóða umbun gegn framlagi“*,
og þjórfé- og framlagssíða Stripe bætir við lagi af landsbundnum reglum ofan á: í
Japan geta einstaklingar alls ekki tekið við framlögum; í Singapúr mega aðeins
ríkisskráð góðgerðar- eða trúfélög það; á Indlandi, í Hong Kong og Taílandi eru
framlög óstudd.

Svo tónlistarmaður í Berlín sem slær inn „framlög fyrir tónlistina mína“ í
skráningarform Stripe hefur einmitt lýst atvinnurekstri sem Stripe bannar í
Þýskalandi. Ekki af því að götuspilamennska sé bönnuð — hún er fullkomlega í lagi —
heldur af því að orðin sem hann valdi tilheyra flokki sem er það.

## Nú kvörðunin, því þetta er ekki hryllingssaga

**Götuspilarar eru ekki takmarkaður atvinnurekstur.** Þjórfé er ekki takmarkaður
atvinnurekstur. Lifandi flutningur er ekki á listanum, mun ekki koma þér á listann,
og er álíka hversdagslegur hlutur og hægt er að gera með greiðslureikningi. Ef þú
lýsir sjálfum þér rétt snertir ekkert af þessu þig og uppsetningin er leiðinleg,
sem er nákvæmlega eins og hún á að vera.

Áhættan hér er ekki Stripe. Áhættan er **röng sjálfsflokkun** — að ganga inn í
herbergið og kynna sig sem fjáröflunaraðila í góðgerðarskyni þegar þú ert
gítarleikari. Stripe hefur enga leið til að vita að þú áttir við „vinsamlegast
gefðu mér þjórfé“. Það hefur aðeins eyðublaðið sem þú fylltir út, lýsinguna á
rekstrinum sem þú skrifaðir, og orðin á síðunni sem QR-kóðinn þinn vísar á.

Enginn hjá Stripe er að veiða götuspilara. Þau eru einfaldlega að lesa það sem þú
sagðir þeim.

## Gildran er einn stiki á dýpt

Hér er hlutinn sem nánast enginn skrifar niður, og hann er það gagnlegasta í
þessari færslu.

Payment Links hjá Stripe hafa stika sem heitir `submit_type`.
[API-viðmiðunin](https://docs.stripe.com/api/payment-link/object) lýsir honum sem
nánast útlitslegum:

> Gefur til kynna tegund færslunnar sem er framkvæmd, sem sérsníður viðeigandi texta
> á síðunni, svo sem sendingarhnappinn.

*Sérsníður viðeigandi texta.* Þú myndir með fullum rétti álykta að þetta breyti
merkimiða á hnappi, og að á þjórfékrukku ætti augljóslega að standa *Donate* frekar
en *Buy* — því „kaupa“ er undarlegt orð að prenta undir hatt götuspilara.

Svo lestu hvað einstök gildi gera í raun:

> `donate` — Mælt með þegar tekið er við framlögum. Sendingarhnappurinn ber
> merkimiðann 'Donate' og slóðir nota hýsilheitið `donate.stripe.com`

> `pay` — Sendingarhnappurinn ber merkimiðann 'Buy' og slóðir nota hýsilheitið
> `buy.stripe.com`

**Þetta er ekki merkimiði. Þetta er hýsilheiti.** Stilltu `submit_type=donate` og
tengillinn sem Stripe réttir þér — sá sem þú breytir í QR-kóða, prentar og límir á
gítarkassann — býr á `donate.stripe.com`. Hver einasti aðdáandi sem skannar hann sér
framlagssíðu. Hver einasta greiðsla á mælaborðinu þínu kom í gegnum framlagsferli.
QR-kóðinn á kassanum þínum er að segja Stripe, segja áhorfendum þínum og að lokum
segja þér að þú sért að safna framlögum.

Þú skrifaðir orðið „framlag“ hvergi. Einn API-stiki skrifaði það fyrir þig, og
prentaði það á plastskilti á opinberu torgi.

Það er auðvelt að ganga í þessa gildru, og það er ekki lesandanum að kenna þegar það
gerist: stikanum er lýst sem textabreytingu, *Donate* er augljóslega fallegra orð
að prenta undir hatt götuspilara, og afleiðingin — flokkun atvinnurekstrar — er
tveimur setningum neðar á síðunni en flestir lesa.

live.tips sendir `submit_type=pay`. Tengill hvers listamanns er `buy.stripe.com`
tengill, og í kóðanum stendur athugasemd sem segir af hverju, því þetta er
nákvæmlega það sem framtíðar-þátttakandi myndi annars „bæta“.

## Hvað tónlistarmaður ætti í raun að gera

Ekkert af þessu krefst lögfræðings. Það krefst fimm mínútna og nokkurra einfaldra
orða.

- **Lýstu raunverulega rekstrinum** í skráningu Stripe. „Flutningur lifandi
  tónlistar.“ „Götuspilari.“ „Tónlistarmaður — þjórfé frá áhorfendum á tónleikum.“
  Segðu að þú komir fram, og að greiðslurnar séu þjórfé fyrir þann flutning.
- **Veldu flokk sem passar.** Lifandi skemmtun, sviðslistir, tónlistarmaður. Ekki
  góðgerðarstarf, ekki félagasamtök, ekki fjáröflun.
- **Notaðu `submit_type=pay`** ef þú býrð Payment Link til sjálfur. Ef verkfæri bjó
  hann til fyrir þig, líttu á slóðina sem það framleiddi: `buy.stripe.com` er
  þjórfékrukka, `donate.stripe.com` er framlagssíða. Þetta er tveggja sekúndna
  athugun, og hún segir þér hvað verkfærið þitt telur þig vera.
- **Ekki kalla þetta framlag** — ekki á skiltinu, ekki á vefsíðunni þinni, ekki í
  rekstrarlýsingunni hjá Stripe. „Þjórfé“, „þjórfékrukka“, „styddu bandið“, „kauptu
  handa okkur bjór“ lýsa öll því sem er raunverulega að gerast. „Gefðu framlag“
  lýsir einhverju öðru.
- **Haltu raunverulegri fjáröflun aðskilinni.** Ef þú spilar á styrktartónleikum og
  peningarnir renna til málstaðar, þá er það sannarlega fjáröflun í góðgerðarskyni,
  og reglurnar hér að ofan eiga nú við um þig — landalistinn þar með talinn. Gerðu
  það á réttum reikningi, í réttu landi, eftir að hafa lesið skilmála Stripe, og
  aldrei í gegnum þjórfékrukkuna sem þú notar á venjulegum kvöldum.

Síðasti liðurinn á skilið áherslu, því hann er heiðarlegi helmingurinn af
röksemdinni. Við erum ekki að segja að framlög séu slæm eða að tónlistarfólk megi
aldrei safna fé fyrir málstað. Við erum að segja að þetta sé **önnur athöfn**, með
öðrum reglum, og að það að reka hana hljóðlega gegnum sama QR-kóða sé leiðin til að
koma báðum í vandræði.

Ein lína í viðbót af þjórfé- og framlagssíðu Stripe er þess virði að vita, því hún
útilokar þriðja hlutinn sem fólk ruglar við hina tvo: Stripe sinnir ekki
*„greiðslumiðlun fyrir persónulegar millifærslur eða millifærslur milli einstaklinga
(t.d. að senda peninga milli vina)“*. Þjórfé er ekki heldur gjöf milli vina. Ef þú
vilt þá leið — aðdáandi sem einfaldlega sendir þér peninga, manneskja til manneskju
— þá er það nákvæmlega það sem Revolut og MobilePay eru, og þess vegna búa þau
[algjörlega utan Stripe](post:one-qr-code-every-payment-method) í appinu okkar.

## Hvað þessi færsla er ekki

Hún er ekki lögfræðiráðgjöf. Hún er ekki skattaráðgjöf — hvernig þjórfé er skattlagt
er gríðarlega breytilegt eftir löndum, stundum eftir borgum, og er algjörlega utan
umfangs hér; spurðu einhvern til þess bæran þar sem þú býrð.

Og hún er ekki loforð um reikninginn þinn. **Hvort Stripe samþykkir þig er ákvörðun
Stripe einna.** live.tips hefur ekkert samband við Stripe, enga getu til að hafa
áhrif á yfirferð, og enga leið til að áfrýja henni fyrir þína hönd. Það sem
hugbúnaðurinn okkar getur gert er að forðast að leggja þér orð í munn. Það sem þú
skrifar á eyðublaðið er enn þitt að skrifa.

Stefnur breytast líka. Línurnar sem hér eru tilgreindar stóðu á síðum Stripe í júlí
2026, og tenglarnir eru hérna; farðu og lestu þær sjálf frekar en að treysta
bloggfærslu, þar með talinni þessari.

## Stutta útgáfan

Þú spilaðir settið. Þau horfðu á það. Þau borguðu þér fyrir það.

Það er þjórfé. Segðu það — á skiltinu, á eyðublaðinu, í slóðinni — og þá færðu þá
leiðinlegu niðurstöðu sem þú vilt. Við smíðum þjórfékrukkuna nákvæmlega utan um
þessa fullyrðingu, alla leið niður í
[hvaða Stripe-hýsilheiti QR-kóðinn þinn vísar á](post:build-a-tip-jar-on-your-own-stripe),
og ef þú vilt stærri myndina af því hvert peningarnir fara í raun, þá er hún
[hér](post:how-live-tips-handles-money).
