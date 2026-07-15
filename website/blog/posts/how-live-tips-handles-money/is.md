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

## Peningar fara aldrei í gegnum okkur

Þegar aðdáandi ýtir á kortaupphæð er greiðslan stofnuð á **þínum** Stripe-reikningi,
sest inn á **þína** Stripe-innistæðu og er greidd út samkvæmt **þinni** Stripe-áætlun.
Eina þóknunin er venjulegt vinnslugjald Stripe sjálfs, sem Stripe rukkar þig beint,
nákvæmlega eins og ef þú hefðir samþætt Stripe á eigin spýtur.

Það er ekkert bókhald okkar megin því það er ekkert til að skrá. Við gætum ekki hirt
prósentu án þess að byggja fyrst það sem heldur á peningunum — og ekkert slíkt er til.

Þetta á við hvort sem þú skráir þig inn eða ekki. Það sem innskráning breytir er
*gagna*leiðin, ekki *peninga*leiðin, og næstu tveir kaflar eru heiðarlegir um nákvæmlega
hvernig.

## Lyklarnir þínir, og hvar þeir búa

Uppsetningin biður um *takmarkaðan* Stripe API-lykil, ekki virkan leynilykil — slíkum
höfnum við umsvifalaust. Takmarkaður þýðir að lykillinn getur gert tvennt: búið til
borgaðu-það-sem-þú-vilt-þjórfétengil og fylgst með þjórfé berast. Hann getur ekki lesið
innistæðuna þína, ræst útborganir, gefið út endurgreiðslur eða snert viðskiptavinagögn.
Ef hann læki á morgun er sprengjuradíusinn einn þjórfétengill.

**Án aðgangs fer sá lykill aldrei úr tækinu þínu.** Hann situr í lyklakippu tækisins
sjálfs og er aðeins nokkurn tíma sendur til `api.stripe.com` um TLS. Enginn
live.tips-þjónn kemur þar nokkuð við sögu.

**Þegar þú skráir þig inn færist lykillinn til okkar** — því lykill sem er aðeins til í
einum síma getur ekki líka þjónað spjaldtölvunni á sviðinu. Við dulkóðum hann
(AES-256-lykill fyrir hvert leyndarmál, sem er sjálfur pakkaður inn af Google Cloud KMS)
og geymum hann þar sem ekkert getur lesið hann til baka: ekki annar aðgangur, ekki við
að kíkja í gagnagrunn, ekki einu sinni þú. Hann er aðeins afinnsiglaður inni í föllunum
okkar, notaður til að tala við Stripe fyrir þína hönd, og aldrei afhentur tæki aftur.
Sagt umbúðalaust: innskráning setur live.tips-þjón á leiðina milli Stripe og
þjórfjársögunnar þinnar. Aldrei peningana — gögnin.

## Þjónarnir, og hvað þeir geta ekki gert

Þeir eru tveir, og báðir eru í lágmarki.

**Endurvarpinn** er til af því að ekki er hægt að stýra Revolut og MobilePay úr vafra
eins og Stripe. Að kveikja á þeim ræsir handfylli af Firebase-föllum sem þjóna
þjórfésíðunni þinni á `tip.live.tips`. Hann geymir opinbera þjórfésíðusniðið þitt —
birtingarnafnið og greiðsluauðkennin sem þú kaust að birta — og, fyrir síðu sem enginn
aðgangur stendur að baki, heldur hann enga þjórfjársögu: þjórfé bíður aðeins þar til
sviðstækið þitt sýnir það, og öllu sem enginn kom aftur eftir er sópað burt innan
klukkustundar. Hann sér enga peninga og eyðir sjálfum sér eftir 90 daga aðgerðaleysi. Ef
þú notar aðeins Stripe og skráir þig aldrei inn er aldrei haft samband við endurvarpann.

**Vefkrókurinn** er aðeins til þegar þú hefur skráð þig inn. Af því að lykillinn þinn býr
nú hjá okkur tilkynnir Stripe hvert þjórfé til lítils falls hjá okkur, sem skrifar það
inn í þína eigin sögu svo hin tækin þín geti sýnt það. Þetta er afrit af viðburði, ekki
afrit af peningunum. Það getur ekki fært einn eyri, og það getur aðeins nokkurn tímann
skrifað inn í þann eina aðgang sem það tilheyrir.

Hvorugur þjónninn getur tekið þóknun, því hvorugur er neins staðar nálægt peningunum. Það
mesta sem hvor um sig getur gert er að bila — og uppsetning sem notar eingöngu Stripe og
engan aðgang reiðir sig á hvorugan.

## Reikningurinn sem þú þarft ekki að stofna

Forritið ræsist enn í tækisbundið snið, alveg eins og það hefur alltaf gert:
þjórfékrukkan þín, lykillinn þinn og þjórfjársagan þín lifa í tækinu og hvergi
annars staðar. Það er ekkert að skrá sig fyrir.

Að skrá sig inn — með Apple, með Google eða sem gestur — er nú mögulegt, og það er
til af einni ástæðu: annað tæki. Ef spjaldtölvan á sviðinu og síminn í vasanum þínum
eiga að sýna sama kvöldið verður eitthvað að sitja á milli þeirra, og það eitthvað er
Firestore, undir notandaauðkenni sem aðeins þú getur lesið. Hljómsveitirnar þínar,
stillingarnar, þjórfjársagan — og, dulkóðaður eins og að ofan, Stripe-lykillinn þinn —
búa þar. Það er raunveruleg breyting á persónuverndarsögunni og hún á skilið að vera sögð
umbúðalaust frekar en að uppgötvast: án reiknings sér enginn þjónn nokkurn tíma
þjórfé; með reikningi sér þitt eigið horn af okkar það, og það er vefkrókurinn okkar sem
skrifar það þangað. Það er verðið fyrir annað tækið, og það er þitt að greiða það eða
hafna því. Það sem það snertir aldrei eru
peningarnir — reikningur færir gögnin þín, ekki innistæðuna þína, og enn er engin
þóknun tekin.

## Af hverju þú ættir ekki að taka orð okkar trúanleg

Allt ofangreint er hægt að sannreyna. Kóðagrunnurinn er MIT-leyfður og opinn, og
vefurinn er kyrrstæð bygging sem GitHub Actions dreifir á GitHub Pages — engin falin
grunnvirki, ekkert vélþýtt á bak við luktar dyr. Opnaðu netflipann meðan á
sýnigreiðslu stendur og lestu beiðnirnar. Þær eru færri en þú býst við.

Það er hin raunverulega vörufullyrðing. Ekki að við séum traustsins verð, heldur að
þú þurfir þess ekki.
