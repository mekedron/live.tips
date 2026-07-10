---
title: Hvernig live.tips meðhöndlar peninga (það gerir það ekki)
description: Það er engin live.tips-innistæða, engin útborgunaráætlun og engin þóknun. Hér er arkitektúrinn sem gerir þessar þrjár fullyrðingar leiðinlegar frekar en djarfar.
slug: hvernig-live-tips-medhondlar-peninga
---

Hvaða þjórfékrukka sem er getur sett „0% þóknun“ á lendingarsíðuna sína. Áhugaverða
spurningin er hvað hugbúnaðurinn þyrfti að gera til að *byrja* að taka þóknun, og
hversu mikið af því þú fengir að sjá.

Hvað live.tips varðar er svarið: það þyrfti að endurbyggja það. Það er ekki loforð um
fyrirætlanir okkar, heldur lýsing á því hvert peningarnir fara.

## Kortaþjórfé fer aldrei í gegnum okkur

Þegar aðdáandi ýtir á kortaupphæð talar vafrinn hans við `api.stripe.com`. Ekki við
live.tips-þjón — það er enginn slíkur á þeirri leið. Greiðslan er stofnuð á **þínum**
Stripe-reikningi, sest inn á **þína** Stripe-innistæðu og er greidd út samkvæmt
**þinni** Stripe-áætlun. Eina þóknunin er venjulegt vinnslugjald Stripe sjálfs, sem
Stripe rukkar þig beint, nákvæmlega eins og ef þú hefðir samþætt Stripe á eigin
spýtur.

Það er ekkert bókhald okkar megin því það er ekkert til að skrá. Við gætum ekki hirt
prósentu án þess að byggja fyrst það sem heldur á peningunum.

## Lyklarnir þínir haldast þínir

Uppsetningin biður um *takmarkaðan* Stripe API-lykil, ekki virkan leynilykil —
slíkum höfnum við umsvifalaust. Hann er geymdur í lyklakippu tækisins þíns og er
aðeins nokkurn tíma sendur til Stripe um TLS.

Takmarkaður þýðir að lykillinn getur gert tvennt: búið til
borgaðu-það-sem-þú-vilt-þjórfétengil og fylgst með þjórfé berast. Hann getur ekki
lesið innistæðuna þína, ræst útborganir, gefið út endurgreiðslur eða snert
viðskiptavinagögn. Ef hann læki á morgun er sprengjuradíusinn einn þjórfétengill.

## Eini staðurinn þar sem þjónn er til

Ekki er hægt að stýra Revolut og MobilePay úr vafra eins og Stripe, svo að með því að
kveikja á þeim ræsist lágmarks-endurvarpi á `api.live.tips`. Það er þess virði að
vera nákvæmur um hvað sá endurvarpi gerir, því „við bættum við bakenda“ er venjulega
staðurinn þar sem þessar sögur fara úrskeiðis.

Hann geymir opinbera þjórfésíðusniðið þitt — birtingarnafnið og greiðsluauðkennin sem
þú kaust að birta. Það er allt og sumt. Hann heldur enga gjafasögu, sér enga peninga,
geymir enga lykla og eyðir sjálfum sér eftir 90 daga aðgerðaleysi. Peningar færast
enn beint milli Revolut- eða MobilePay-forrits aðdáandans þíns og þíns eigin.

Ef þú notar aðeins Stripe er aldrei haft samband við endurvarpann.

## Af hverju þú ættir ekki að taka orð okkar trúanleg

Allt ofangreint er hægt að sannreyna. Kóðagrunnurinn er MIT-leyfður og opinn, og
vefurinn er kyrrstæð bygging sem GitHub Actions dreifir á GitHub Pages — engin falin
grunnvirki, ekkert vélþýtt á bak við luktar dyr. Opnaðu netflipann meðan á
sýnigreiðslu stendur og lestu beiðnirnar. Þær eru færri en þú býst við.

Það er hin raunverulega vörufullyrðing. Ekki að við séum traustsins verð, heldur að
þú þurfir þess ekki.
