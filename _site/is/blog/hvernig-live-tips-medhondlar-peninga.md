# Hvernig live.tips meðhöndlar peninga (það gerir það ekki)

> Það er engin live.tips-innistæða, engin útborgunaráætlun og engin þóknun. Hér er arkitektúrinn sem gerir þessar þrjár fullyrðingar leiðinlegar frekar en djarfar.

Canonical: https://live.tips/is/blog/hvernig-live-tips-medhondlar-peninga/
Published: 2026-07-02
Updated: 2026-07-13
Language: is
Tags: Stripe, privacy, open source

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

## Eini þjónninn á greiðsluleiðinni

Ekki er hægt að stýra Revolut og MobilePay úr vafra eins og Stripe, svo að með því að
kveikja á þeim ræsist lágmarks-endurvarpi — handfylli af Firebase-föllum sem þjóna
þjórfésíðunni þinni á `tip.live.tips`. Það er þess virði að vera nákvæmur um hvað sá
endurvarpi gerir, því „við bættum við bakenda“ er venjulega staðurinn þar sem þessar
sögur fara úrskeiðis.

Hann geymir opinbera þjórfésíðusniðið þitt — birtingarnafnið og greiðsluauðkennin sem
þú kaust að birta. Það er allt og sumt. Hann heldur enga þjórfjársögu, sér enga peninga,
geymir enga lykla og eyðir sjálfum sér eftir 90 daga aðgerðaleysi. Revolut- eða
MobilePay-þjórfé bíður þar aðeins þangað til sviðstækið þitt sækir það: að birta það
eyðir því, og öllu sem enginn kom aftur eftir er sópað burt innan klukkustundar.
Peningar færast enn beint milli Revolut- eða MobilePay-forrits aðdáandans þíns og
þíns eigin.

Ef þú notar aðeins Stripe er aldrei haft samband við endurvarpann.

## Reikningurinn sem þú þarft ekki að stofna

Forritið ræsist enn í tækisbundið snið, alveg eins og það hefur alltaf gert:
þjórfékrukkan þín, lykillinn þinn og þjórfjársagan þín lifa í tækinu og hvergi
annars staðar. Það er ekkert að skrá sig fyrir.

Að skrá sig inn — með Apple, með Google eða sem gestur — er nú mögulegt, og það er
til af einni ástæðu: annað tæki. Ef spjaldtölvan á sviðinu og síminn í vasanum þínum
eiga að sýna sama kvöldið verður eitthvað að sitja á milli þeirra, og það eitthvað er
Firestore, undir notandaauðkenni sem aðeins þú getur lesið. Hljómsveitirnar þínar,
stillingarnar, takmarkaði lykillinn og þjórfjársagan samstillast þangað. Það er
raunveruleg breyting á persónuverndarsögunni og hún á skilið að vera sögð
umbúðalaust frekar en að uppgötvast: án reiknings sér enginn þjónn nokkurn tíma
þjórfé; með reikningi sér þitt eigið horn af okkar það. Það er verðið fyrir annað
tækið, og það er þitt að greiða það eða hafna því. Það sem það snertir aldrei eru
peningarnir — reikningur færir gögnin þín, ekki innistæðuna þína, og enn er engin
þóknun tekin.

## Af hverju þú ættir ekki að taka orð okkar trúanleg

Allt ofangreint er hægt að sannreyna. Kóðagrunnurinn er MIT-leyfður og opinn, og
vefurinn er kyrrstæð bygging sem GitHub Actions dreifir á GitHub Pages — engin falin
grunnvirki, ekkert vélþýtt á bak við luktar dyr. Opnaðu netflipann meðan á
sýnigreiðslu stendur og lestu beiðnirnar. Þær eru færri en þú býst við.

Það er hin raunverulega vörufullyrðing. Ekki að við séum traustsins verð, heldur að
þú þurfir þess ekki.
