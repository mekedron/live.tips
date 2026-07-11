---
title: Byggðu þjórfékrukku á þínum eigin Stripe-reikningi
description: Þrjú API-köll gefa þér hýsta „borgaðu það sem þú vilt“-síðu með Apple Pay og Google Pay — án nokkurs netþjóns. Hér er öll smíðin: takmarkaði lykillinn, heimildirnar, hvernig þú lest þjórfé inn án webhook, og gjaldareikningurinn sem enginn prentar.
slug: byggdu-thjorfekrukku-a-thinum-eigin-stripe-reikningi
---

Þú vilt þjórfékrukku. Þú vilt ekki afhenda vettvangi 5 % af kvöldi götutónlistarmanns, og þú
ræður fullkomlega við að tala við API. Spurningin er því ekki *í hvaða þjórfékrukku á ég að
skrá mig*, heldur *hversu mikið þarf ég í rauninni að smíða*.

Minna en þú heldur. Á Stripe er virka svarið þrjú API-köll: enginn netþjónn, enginn bakendi,
ekkert webhook-endapunkt. Restin af þessari færslu er nákvæmlega sú smíði — auk þeirra tveggja
atriða sem allir klúðra.

## Trikkið er Price af gerðinni „borgaðu það sem þú vilt“

Stripe er með verðlagningarham þar sem aðdáandinn slær sjálfur inn upphæðina. Hann heitir
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) og er öll
eiginleikinn. Þú býrð til Product, hengir á það Price með
`custom_unit_amount[enabled]=true`, og ofan á það
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. hluturinn sem þú "selur"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. verðið sem aðdáandinn velur
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. síðan
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

Þriðja kallið skilar `url`. Sá URL *er* þjórfékrukkan þín. Þetta er síða sem Stripe hýsir, sem sagt
PCI-samhæfð án þess að þú hugsir um það, staðfærð, og hún sýnir Apple Pay eða Google Pay hverjum
þeim aðdáanda sem hefur þau uppsett í símanum —
[kviklegar greiðsluleiðir](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
ákveða það fyrir þig eftir tæki og landi. Þú skrifaðir ekkert viðmót.

Kóðaðu URL-inn sem QR-kóða með hvaða safni sem er — þetta er bara strengur — prentaðu hann, límdu hann
á kassann. Kóðinn rennur aldrei út og bendir ekki á neinn netþjón þinn, því þú átt engan.

Tveir stikar sem borgar sig að þekkja:

- **`custom_unit_amount[preset]`** er upphæðin sem síðan opnast með. `500` þýðir að aðdáandinn sér 5,00 €
  þegar útfyllt og getur breytt því. Þessi tala gerir meira fyrir meðalþjórféð þitt en nokkuð annað á
  síðunni.
- **`custom_unit_amount[minimum]`** er gólf. Settu það. Ástæðan er í gjaldakaflanum hér að neðan og er
  ekki námundunarvilla.

Þú getur líka safnað nafni og skilaboðum. Payment Links taka allt að þrjú `custom_fields` — þannig færðu
„frá hverjum var þetta?“ á síðuna án þess að smíða eyðublað:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Nafnið þitt eða viðurnefni" \
  -d "custom_fields[0][optional]"=true
```

Stripe hefur [kröfur um móttöku þjórfés og framlaga](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
lestu þær einu sinni. „Borgaðu það sem þú vilt“ verður ekki heldur sameinað öðrum line items, afsláttum eða
endurteknum greiðslum. Fyrir þjórfékrukku bítur ekkert af því.

Þennan greinarmun borgar sig að hafa réttan. Stripe orðar það svona: þjórfé er gefið fyrir
vöru eða þjónustu sem þegar hefur verið veitt, en framlag verður að vera bundið
góðgerðartilgangi. Þú spilaðir settið; þjórféð borgar fyrir það. Þess vegna sendir kallið
hér að ofan líka `submit_type=pay` en ekki `donate` — `donate` myndi hýsa hlekkinn þinn á
`donate.stripe.com` og prenta *Gefa* á hnappinn. Það er annar bransi, og einn sem Stripe
skoðar mun harðar.

## Lykillinn: gerðu ráð fyrir að hann leki — og gerðu það leiðinlegt

Ekki setja leynilykil (`sk_live_…`) í tæki sem stendur á sviði. Notaðu
[takmarkaðan lykil](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): þú velur heimild fyrir
hverja auðlind, og allt sem þú velur ekki stendur á **None**.

Fyrir smíðina hér að ofan er listinn allur fimm línur:

| Auðlind | Heimild | Til hvers |
| --- | --- | --- |
| Products | Write | búa til Product |
| Prices | Write | búa til „borgaðu það sem þú vilt“-Price |
| Payment Links | Write | búa til hlekkinn |
| Checkout Sessions | Read | sjá þjórféð sem kom inn |
| Events | Read | beina streymið (næsti kafli) |

Allt annað — Balance, Payouts, Refunds, Customers, PaymentIntents, allt Connect — stendur áfram á **None**.

Gerðu nú æfinguna sem gerir þetta þess virði. Spjaldtölvunni þinni er stolið af varningsborðinu klukkan eitt um
nótt. Hvað getur þjófurinn gert við lykilinn í lyklakippunni? Lesið þjórfésöguna þína og búið til fleiri
þjórféhlekki á reikningnum þínum. Það er allur sprengiradíusinn. Hann sér ekki innstæðuna þína, getur ekki hrint
af stað útborgun, getur ekki endurgreitt á kort sem hann stýrir, getur ekki lesið viðskiptavinalista. Þú afturkallar
lykilinn úr símanum í leigubílnum heim og tækið slokknar. Ekkert af peningunum þínum hreyfðist.

Þetta ójafnvægi — skrifaðgangur að þjórfékrukkunni, núll aðgangur að peningunum — er eina ástæðan fyrir því að
netþjónslaus hönnun með þínum eigin lykli er yfirhöfuð verjanleg. Hún er líka ástæðan fyrir því að „Login with Stripe“
er ekki svarið hér: OAuth krefst netþjóns í eigu forritarans til að geyma tókann þinn — og netþjónn er nákvæmlega það
sem við erum ekki að smíða.

(Sérviska sem þú rekst á: heimildin *Prices* heitir innanhúss `plan_write`, þannig að villuboð Stripe nefna scope sem er
ekki til undir því nafni í stjórnborðinu. Það er Prices.)

## Að lesa þjórfé inn án webhook

Hér hætta flestar leiðbeiningar, eða þær grípa til webhook — og hér er svið raunverulega frábrugðið vefforriti.

Webhook er innkomin HTTP-beiðni. Spjaldtölva bak við hljóðnemastatíf getur ekki tekið á móti slíkri. Hún hangir á
gestaneti staðarins bak við NAT, hefur ekkert opinbert vistfang, ekkert TLS-vottorð — og hefur ekkert með það að gera.
Ef þú velur webhook-leiðina þarftu að reisa netþjón sem grípur atburðina og sökkul sem ýtir þeim í tækið: bakendi,
rekstrarbyrði, og staður þar sem nöfn aðdáenda þinna búa nú. Þú varst rétt í þessu að endurbyggja vettvanginn sem þú
ætlaðir að forðast.

Togaðu því í stað þess að láta ýta þér. Endapunktur Stripe,
[List all events](https://docs.stripe.com/api/events/list), er opinber, skjalfestur og skilar atburðum með þá nýjustu
fyrst:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_SIDASTI_SEM_EG_SA \
  -d limit=100
```

`ending_before` er öll hönnunin. Geymdu auðkenni nýjasta atburðarins sem þú vannst úr; hver fyrirspurn biður um allt sem
er strangt til tekið nýrra, og þú færir bendilinn. Engir tímastimplar, ekkert klukkurek, engin tvítekningarhreinsun eftir
upphæð. Í fyrstu fyrirspurn setts biður þú um `limit=1` án bendils til að festa þig við það sem þegar er — annars spilarðu
þjórfé morgunsins aftur í hljóðprófinu.

Síaðu svo það sem kemur til baka. Báðar atburðategundirnar geta farið af stað fyrir eina greiðslu, svo hreinsaðu tvítekningar
eftir auðkenni Checkout Session. Athugaðu `payment_status == "paid"` — lokið lota er ekki endilega greidd. Og athugaðu að
`payment_link` passi við *þinn* hlekk, því `/v1/events` nær yfir allan reikninginn og réttir þér fúslega umferðina frá öllu
öðru sem sá Stripe-reikningur gerir.

Vertu heiðarlegur um málamiðlanirnar, því þær eru raunverulegar:

- **Stripe mælir með webhooks.** Fyrirspurnaraðferðin er ekki blessaða leiðin; hún er skjalfestur endapunktur notaður
  meðvitað. Skrifaðu það í README-skrána þína og haltu áfram.
- **Atburðir ná 30 daga aftur.** [Orð Stripe sjálfs](https://docs.stripe.com/api/events/list):
  *„List events, going back up to 30 days.“* Þetta er beint streymi, ekki bókhaldið þitt. Bókhaldið þitt eru Checkout
  Sessions — og hið raunverulega er stjórnborð Stripe.
- **Fylgstu með lestrarkvótanum.** Allir horfa á mörkin á sekúndu
  ([rate limits](https://docs.stripe.com/rate-limits): 100 beiðnir/s í live) og enginn á hin: Stripe úthlutar um það bil
  **500 lestrarbeiðnum á hverja færslu** yfir 30 daga rúllandi glugga, með gólfi upp á 10.000 lestra á mánuði. Spyrðu á
  4 sekúndna fresti og þriggja tíma sett gerir ~2.700 lestra. Fjögur löng gigg í mánuði og þú ert á gólfinu. Þjórfé kaupir
  þér svigrúm um leið og það berst — en sá sem spyr á hverri sekúndu af því það virtist snarpara mun finna þakið. Fjórar
  sekúndur eru ekki löt tala; þær *eru* talan.

Svona lítur þetta út í hreinskilni: fyrirspurnir kosta þig nokkur þúsund GET og kaupa þér að eyða heilum bakenda.

## Gjaldareikningurinn, gerður almennilega

Vettvangur sem auglýsir 0 % er ekki ókeypis — og þetta er það ekki heldur. Vinnslugjald Stripe sjálfs á við um hvert einasta
þjórfé og Stripe rukkar þig beint. Í dag kostar venjulegt EES-kort samkvæmt
[evruverðskrá Stripe](https://stripe.com/ie/pricing) **1,5 % + 0,25 €**. Premium EES-kort 1,9 % + 0,25 €, bresk kort 2,5 % +
0,25 €, og allt annað 3,25 % + 0,25 € auk 2 % ef skipta þarf gjaldmiðli. (Í Bandaríkjunum er það 2,9 % + 0,30 $, sem er verra
af nákvæmlega þeirri ástæðu sem fylgir.)

Vandinn er ekki prósentan. Vandinn eru þessir tuttugu og fimm sent.

| Þjórfé | Stripe tekur | Listamaðurinn heldur | Raunveruleg skerðing |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Fast gjald er prósenta í dulargervi, og á litlum peningum rennur dulargervið af. Sömu 0,25 €, sem eru ósýnileg á 50 € þjórfé,
éta áttunda part af 2 € þjórfé. Þjórfé er lítið að eðlisfari — það er einmitt það sem gerir það að þjórfé — svo þetta er ekki
jaðartilvik, heldur miðgildistilvikið.

Þess vegna setur þú `custom_unit_amount[minimum]`. Einhvers staðar í kringum 2 € hættir færslan að borga sig; 0,50 € kortaþjórfé
kæmi inn sem 0,24 € og kostaði Stripe meira að færa en það er virði. Veldu gólfið þitt meðvitað í stað þess að uppgötva það í
fyrstu útborguninni.

Og taktu eftir hvað þetta gerir við samanburðinn sem þú byrjaðir á. Vettvangur sem tekur 0 % ofan á Stripe er að taka 0 % ofan á
**þetta**. Þeirra 0 % eru raunveruleg — og þau eru 0 % af því sem greiðslumiðlarinn skildi eftir. Kortabraut engins er ókeypis:
heiðarlega fullyrðingin er „engin skerðing umfram skerðingu greiðslumiðlarans“, og sá sem heldur fram meiru annaðhvort lýgur eða
notar ekki kort.

## Hvað þú hefur núna og hvað ekki

Þrjú API-köll og QR-kóði — og alvöru þjórfékrukka: hýst, PCI-samhæfð, Apple Pay, Google Pay, þjórfé sem lendir á þinni eigin
Stripe-innstæðu eftir þinni eigin útborgunaráætlun, og enginn netþjónn á leiðinni. Fyrir marga er þetta einlæglega endirinn á
verkefninu, og þér er velkomið að stoppa hér og gefa það út.

Það sem þú hefur ekki er svið. Þú hefur greiðslusíðu. Þar á milli standa leiðinlegu hlutirnir: fyrirspurnarlykkjan með bendli sínum
og bakslagi; skjár sem áhorfendur sjá, með markmiðinu og síðustu skilaboðunum; staður fyrir lykilinn sem heitir ekki `localStorage`;
læsing svo ókunnugur fikti ekki í spjaldtölvunni milli setta; og lagið með þúsund smáákvörðunum um hvað gerist þegar wifi staðarins
dettur út í miðju setti.

Það er einmitt það sem [live.tips](https://github.com/mekedron/live.tips) er — nákvæmlega þessi högun, fullkláruð, með MIT-leyfi.
Takmarkaði lykillinn með þessum fimm heimildum, bendilslykkjan á `/v1/events`, sköpun Product/Price/Payment Link — allt keyrandi í
tæki listamannsins, gegn hans eigin reikningi. Það er enginn live.tips-netþjónn á Stripe-leiðinni og engin live.tips-innstæða neins
staðar, sem við skrifuðum sérstaklega um í
[hvernig live.tips fer með peninga](post:how-live-tips-handles-money).

Lestu kóðann, taktu þá hluta sem þú vilt, eða notaðu hann bara. Punkturinn í þessari færslu er sá að högunin er hvorki leyndarmál né
erfið: **Stripe hýsir þjórfékrukkuna þína ókeypis, og takmarkaður lykill auk fyrirspurnarlykkju er allt sem stendur á milli
listamanns og hans eigin peninga.** Okkur er meira í mun að þú vitir það en að þú skráir þig nokkurs staðar.
