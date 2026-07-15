---
title: Persónuverndarstefna
description: live.tips er án vafrakaka, án greiningartóla og án rakningar, og virkar alveg án aðgangs. Ef þú kýst að skrá þig inn, þá er hér nákvæmlega hvað er geymt, hvar, af hverjum og hversu lengi.
updated: 2026-07-15
updated_label: Síðast uppfært 15. júlí 2026
---

live.tips er þjórfékrukka fyrir listafólk, byggð á opnum hugbúnaði. Hún er rekin af
**Nikita Rabykin**, einstökum forritara, ekki fyrirtæki. Ef eitthvað hér að neðan skiptir
þig máli, skrifaðu þá á **[contact@live.tips](mailto:contact@live.tips)** — þar er
manneskja á hinum endanum.

Þessi stefna er hreinskilin um leiðinlegu atriðin. Við segjum frekar „við geymum nafnið
þitt svo lengi sem þú heldur hljómsveitinni“ en að halda því fram að við geymum ekkert og
hafa rangt fyrir okkur.

## Stutta útgáfan

- **Aðgangur er valfrjáls.** Appið virkar alveg án aðgangs, og það er enn sjálfgefið. Ef
  þú vilt fá hljómsveitirnar þínar og söguna þína í annað tæki geturðu skráð þig inn — og
  þá er sumt af þessu geymt á þjóni, og meira af því en áður. Hvað er hvað er útlistað hér
  að neðan.
- **Engar vafrakökur.** Ekki ein, hvergi.
- **Engin greiningartól, engin rakning, engar auglýsingar, engin skriftur frá þriðja aðila**
  á þessari vefsíðu.
- **Við snertum peningana þína aldrei.** Þjórfé fer beint frá aðdáandanum inn á Stripe-,
  Revolut-, MobilePay- eða Monzo-reikning listamannsins sjálfs. Við erum ekki á þeirri leið.
- **Án aðgangs talar appið aðeins við Stripe** — ekki við neinn live.tips-þjón. Ef þú
  skráir þig inn breytist það: Stripe-lykillinn þinn færist yfir á þjóninn okkar og Stripe
  tilkynnir okkur um þjórféð þitt, svo við getum sett það í hin tækin þín. Það er
  heiðarlegi kostnaðurinn við að skrá sig inn, og hann er útlistaður að fullu hér að neðan.
- **Ýtitilkynningar eru nýjar, valfrjálsar og aðeins fyrir innskráða aðganga.** Ekkert er
  ýtt í tæki sem kveikti aldrei á þeim, og tæki án aðgangs fær aldrei neina.
- Þjónarnir sem við rekum eru á Firebase hjá Google. Þeir eru til ef listamaður kveikir á
  Revolut, MobilePay eða Monzo — eða ef hann skráir sig inn.

## Þessi vefsíða

Vefsíðan er kyrrstæð og hýst á **GitHub Pages**. Sem hýsingaraðili fær GitHub IP-tölu og
vafraauðkenni (user-agent) allra sem hlaða síðu — þetta er venjuleg skráning vefþjóns,
hún gerist áður en nokkur kóði frá okkur keyrir, og við getum ekki slökkt á henni. GitHub
vinnur þessi gögn samkvæmt eigin
[persónuverndaryfirlýsingu](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Við lesum ekki þessar skrár og GitHub sýnir okkur þær ekki.

Að öðru leyti hlaða síðurnar sem þú ert að lesa **ekkert frá neinum öðrum**: letur, tákn
og myndir eru afhent frá live.tips sjálfu. Það er ekkert Google Analytics, enginn
tag manager, enginn pixill, engin ígrædd viðbót.

Vefsíðan geymir **tvö gildi í `localStorage` vafrans þíns**, bæði sett af þér, bæði
læsileg aðeins af þessari síðu, og hvorugt er nokkurn tímann sent neitt:

| Lykill | Hvað hann man |
| --- | --- |
| `lt-landing-theme` | hvort þú valdir ljósa, dökka eða sjálfvirka liti |
| `lt-langbar-dismissed` | að þú lokaðir borðanum „einnig í boði á þínu tungumáli“ |

Að hreinsa vafrageymsluna eyðir þeim. Þau eru ekki vafrakökur, þeim er ekki deilt, og þau
auðkenna engan.

## Appið hefur tvo hætti, og munurinn á þeim er öll sagan

Allt hér að neðan veltur á einni spurningu: **hefur þú skráð þig inn?**

### Fyrsti háttur — enginn aðgangur. Enn sjálfgefið, enn óbreytt.

Appið keyrir **á tæki listamannsins sjálfs**, og allt sem það veit býr þar:

- **Takmarkaði Stripe-lykillinn** er geymdur í lyklakippu tækisins (iOS/macOS Keychain,
  Android Keystore) og er aðeins sendur til `api.stripe.com`.
- **Þjórfésaga, lotusaga, markmiðið, lagabeiðnalistinn og stillingar appsins** eru geymd í
  staðbundinni geymslu tækisins. Þetta felur í sér nöfnin og skilaboðin sem aðdáendur láta
  fylgja þjórfénu sínu.
- Að fjarlægja appið eyðir þessu öllu. Það er ekkert skýjaafrit hjá okkur, því í þessum
  hætti er ekkert ský hjá okkur.

**Við fáum ekkert af þessu.** Appinu fylgir ekkert greiningar-SDK, enginn hrunskýrslugjafi
og enginn auglýsingakóði — ekkert af því, ekki einu sinni óvirkt. (Ýtitilkynningar eru til,
en þær eru eiginleiki fyrir innskráða og eru óvirkar þar til þú kveikir á þeim — sjá *Annan
hátt*. Tæki án aðgangs fær aldrei neina.)

Tvær skýringar, svo fullyrðingin „talar við engan“ standist nákvæmlega:

- Appið sækir **gjaldmiðlagengi** einu sinni á dag frá opinberum gengis-API-um
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Þetta eru einfaldar
  beiðnir um opinberan lista yfir gengi. Þær bera engar upplýsingar um þig, listamanninn
  eða nokkurt þjórfé — en, eins og hver önnur vefbeiðni, afhjúpa þær IP-tölu þína
  gagnvart þessum þjónustum.
- Ef þú notar **vafraútgáfu** appsins hleður vafrinn þinn því niður frá kyrrstæðu
  hýsingunni okkar (sjá *Þessi vefsíða* hér að ofan).

### Annar háttur — þú skráðir þig inn. Þá fara sum gögn úr tækinu, af ásettu ráði.

Að skrá sig inn er meðvituð ákvörðun. Ekkert skráir þig inn fyrir þig, og ekkert í appinu
hættir að virka þótt þú gerir það aldrei. Þú skráir þig inn af því að þú vilt annað tæki:
símann í vasanum og spjaldtölvuna á sviðinu sem sýna sama kvöldið, sömu hljómsveitirnar,
sömu söguna.

Það gengur aðeins upp ef þjónn geymir þær. **Þess vegna gerir hann það, og það er
heiðarlegi kostnaðurinn við annað tækið.**

Þjónninn er **Firebase**, sem er Google. Það eru þrjár leiðir til að eiga aðgang:

- **Innskráning með Apple** eða **innskráning með Google** — Firebase Auth fær það sem
  þjónustuveitandinn afhendir: notandaauðkenni (uid) og, að jafnaði, netfang og nafn. (Hjá
  Apple máttu fela netfangið þitt; Apple gefur okkur þá endurvarpsnetfang í staðinn, og það
  afhendir nafnið þitt aðeins allra fyrsta skiptið sem þú skráir þig inn.)
- **Gestaaðgangur** — nafnlaus aðgangur án netfangs og án nafns. Hann samstillir og hægt er
  að afturkalla hann, en það er ekkert til að endurheimta hann með ef þú týnir tækinu. Hann
  er uid og ekkert annað. Gestaaðgangur getur ekki notað vörslu Stripe-lykilsins á þjóninum
  né ýtitilkynningarnar sem lýst er hér að neðan, því hvort tveggja þarf aðgang sem við
  getum afhent þér aftur.

Þegar þú ert innskráð(ur) fær aðgangurinn sitt eigið einkahorn í **Cloud Firestore**
gagnagrunni Google, á `users/<your uid>/`. Öryggisreglurnar veita þessu uid það horn **og
engum öðrum** — enginn annar aðgangur getur lesið það, ekki heldur með því að giska á
vefslóðir. Þar inni er:

| Hvað | Af hverju það er þarna |
| --- | --- |
| **Hljómsveitirnar þínar** — nöfn, stillingar þjórfékrukkunnar og greiðsluleiða, orðalag plakatsins, markmið og **lagabeiðnalistinn þinn** | svo hljómsveit sé til í hverju því tæki sem þú skráir þig inn í |
| **Stillingar appsins**, þar með taldar tilkynningastillingarnar þínar | svo tæki sem þú bætir við sé þegar uppsett |
| **Lotuskrár og þjórfésaga** — þar með talin **nöfnin og skilaboðin sem aðdáendur láta fylgja þjórfénu sínu**, og hvaða **lag aðdáandi bað um** | því þessi saga er nákvæmlega það sem þú baðst um að sjá í hinu tækinu |
| **Lifandi lotan** sem er í gangi núna | svo annar skjár geti tengst settinu í kvöld |
| **Tækin þín** — nafnið sem hvert þeirra gefur sér („iPhone Nikita“), stýrikerfi og gerð, tungumál viðmótsins, hvenær það sást fyrst og síðast, og (ef þú kveiktir á tilkynningum) **ýtitóki** | svo Stillingar → Öryggi geti talið þau upp, svo tilkynning berist í rétt tæki á réttu tungumáli, og þú getir afturkallað eitt |
| Lítið **prófílskjal** — aðgangsnafnið sem þú valdir og hvaða þjónustuveitanda þú notaðir | svo aðgangsvalið geti merkt hann |
| **Bjölluveita** — takmarkaður listi yfir nýleg þjórfé og lagabeiðnir sem bárust meðan ekkert sett var í gangi | svo þú getir náð í það sem þú misstir af |

Og svo það mikilvæga, umbúðalaust: **án aðgangs fara nafn og skilaboð aðdáanda aldrei úr
tæki listamannsins. Með aðgangi eru þau geymd á þjónum Google undir uid listamannsins, sem
hluti af hans eigin samstilltu sögu** — og, eins og næstu tveir kaflar útskýra, **er það nú
þjónninn okkar sem skrifar þau þangað.** Enginn annar aðgangur getur lesið þau, við lítum
ekki á þau, og ekkert er leitt af þeim — en þau eru þarna, og þau haldast þar svo lengi sem
hljómsveitin er til, og þú ættir að vita það áður en þú skráir þig inn.

Að skrá sig út setur tækið aftur í staðbundna háttinn. Það eyðir ekki gögnum aðgangsins —
sjá *Að eyða hlutum* hér að neðan.

#### Stripe-lykillinn þinn færist yfir á þjóninn okkar þegar þú skráir þig inn

Þetta er stærsta breytingin, og sú sem mest er þess virði að lesa.

**Án aðgangs fer takmarkaði Stripe-lykillinn þinn aldrei úr tækinu.** Það er fyrsti háttur,
og hann er óbreyttur.

**Þegar þú skráir þig inn fer hann — til okkar.** Lykillinn er dulkóðaður (AES-256-lykill
fyrir hvert leyndarmál, sem er sjálfur pakkaður inn af Google Cloud KMS) og geymdur á
þjóninum á stað sem **enginn getur lesið til baka — ekki annar aðgangur, og ekki einu sinni
þú.** Hann er aðeins afinnsiglaður inni í Cloud Functions-föllunum okkar, notaður til að
tala við Stripe fyrir þína hönd, og aldrei afhentur tæki aftur.

Af því að lykillinn býr nú hjá okkur **tilkynnir Stripe þjórféð þitt beint til þjónsins
okkar**: við skráum vefkrók (webhook) á þínum eigin Stripe-reikningi, og Stripe segir þeim
vefkrók í hvert sinn sem þjórfé er greitt. Fallið okkar skrifar þjórféð inn í sögu
aðgangsins þíns (sjá að neðan). Appið þitt spyr Stripe ekki lengur reglulega fyrir
innskráðan aðgang; það nær í Stripe aðeins gegnum þröngan, fastan lista yfir aðgerðir á
þjóninum okkar (að búa til þjórféhlekkinn þinn, að útbúa lagabeiðnahlekk, og að lesa þitt
eigið þjórfé til baka til samstemmingar).

Sem sagt, án fegrunar: **fyrir innskráðan aðgang er nú til live.tips-þjónn á leiðinni milli
Stripe og sögunnar þinnar.** Við snertum enn aldrei peningana — kortaþjórfé er stofnað á
Stripe-reikningnum þínum, sest inn á Stripe-innistæðuna þína og er greitt út samkvæmt
Stripe-áætluninni þinni, nákvæmlega eins og áður. Það sem breyttist er *gagna*leiðin, ekki
*peninga*leiðin. Ef þú skráir þig aldrei inn á ekkert af þessu við og appið talar enn beint
við `api.stripe.com` og engan annan.

#### Að bæta við tæki með QR-kóða

Til að bæta við tæki sýnir þú QR-kóða úr tæki sem er þegar innskráð. Kóðinn er
tilviljanakenndur, **einnota, og rennur út eftir tvær mínútur**, og nýja tækið fær ekkert
fyrr en þú ýtir á *staðfesta* í því gamla. Meðan þetta handaband stendur yfir geymum við
kóðann, nafnið sem nýja tækið gaf sér og stýrikerfi þess — og færslunni er eytt þegar hún
rennur út. Ljósmyndaður QR-kóði er einskis virði án staðfestingar þinnar.

## Lagabeiðnir

Hljómsveit getur kveikt á **lagabeiðnum**: aðdáendur velja þá lag af lista listamannsins
og, valfrjálst, borga til að ýta því ofar í röðina. Beiðni er einfaldlega þjórfé sem ber
líka **hvaða lag** var beðið um — svo sama nafn og skilaboð sem aðdáandi kann að láta fylgja
þjórfé eiga við hér líka, og hún er geymd og varðveitt nákvæmlega eins og hvert annað þjórfé
(hér að neðan). Opinbera röðin sem aðdáandi sér sýnir aðeins **heildartölur á hvert lag** —
hversu mikið lag hefur dregið að sér og hvar það situr — og ber **engin nöfn aðdáenda**. Án
aðgangs búa allur lagabeiðnalistinn og saga hans aðeins í tækinu.

## Ýtitilkynningar

Þegar þú ert innskráð(ur) getur appið sent þér **ýtitilkynningu** — en aðeins ef þú kveikir
á henni, í hverju tæki, og aðeins eftir að stýrikerfi tækisins veitir leyfi. Hún er til
fyrir eitt: þjórfé eða lagabeiðni sem berst **meðan þú ert ekki með sett í gangi**, svo þú
fréttir af þjórfénu sem þú hefðir annars misst af. Þjórfé sem berst meðan sviðið þitt er í
beinni sendir ekkert — þú ert þegar að fylgjast með því.

- Til að afhenda ýtitilkynningu þarf **Firebase Cloud Messaging (FCM)** hjá Google
  **ýtitóka** fyrir tækið. Við geymum þann tóka, og tungumál viðmóts tækisins, á færslu
  tækisins sjálfs undir aðgangnum þínum, og honum er eytt um leið og þú slekkur á
  tilkynningum, afturkallar tækið eða skráir þig út. Dauðir tókar eru grisjaðir sjálfkrafa.
- Tilkynningin sjálf segir hvað barst — upphæð, og nafn aðdáanda eða titil lags ef hann
  skildi eitthvað eftir. Sami stutti listinn er geymdur í **bjölluveitu** aðgangsins þíns,
  takmarkaður við nýjustu hundrað færslurnar, svo þú getir flett til baka gegnum það sem
  barst meðan þú varst í burtu.
- Á vefnum þarf til að afhenda ýtitilkynningu litla **þjónustuvinnu (service worker)** í
  rót síðunnar og Firebase-skilaboða-SDK, sem vafrinn þinn sækir frá Google (`gstatic.com`)
  í fyrsta sinn. Ýtitilkynning á vef er svo borin af ýtiþjónustu vafrans þíns sjálfs (fyrir
  Chrome er það þjónusta Google). Ekkert af þessu hleðst nema þú hafir kveikt á tilkynningum.
- **Gestaaðgangur og tæki án aðgangs fá engar ýtitilkynningar**, því ýtitilkynning þarf
  aðgang sem við getum afhent á og tóka sem þú kaust að gefa.

## Hvar allt þetta býr í raun og veru

Firebase Auth, Cloud Firestore, Cloud Functions-föllin okkar og Cloud KMS-lykillinn sem
pakkar inn Stripe-leyndarmálinu þínu keyra öll í **Evrópusambandinu** — gagnagrunnurinn í
`eur3` fjölsvæðinu hjá Google, föllin og lyklahringurinn í `europe-west1`. Google kemur
fram sem vinnsluaðili okkar samkvæmt
[persónuverndar- og öryggisskilmálum Firebase](https://firebase.google.com/support/privacy)
og eigin [persónuverndarstefnu](https://policies.google.com/privacy). Eins og allir stórir
þjónustuveitendur kann Google að nýta innviði utan ESB vegna stuðnings og öryggis; það fer
eftir þeim skilmálum, ekki okkur. Ýtitilkynningar, þegar þær hafa verið afhentar Firebase
Cloud Messaging og ýtiþjónustu vafrans þíns eða símans, ferðast yfir innviði þeirra
fyrirtækja til að ná til tækisins þíns.

## Stripe

Þegar aðdáandi borgar með korti er hann á greiðslusíðu **Stripe**, ekki okkar. Stripe
safnar og vinnur greiðslugögn hans sem sjálfstæður ábyrgðaraðili samkvæmt
[persónuverndarstefnu Stripe](https://stripe.com/privacy). Við sjáum aldrei kortanúmer.

Hvernig þjórféð þitt berst þér fer eftir hættinum:

- **Án aðgangs** les app listamannsins hans eigið þjórfé frá Stripe með takmarkaða lyklinum
  hans sjálfs — beint úr tækinu til `api.stripe.com`. **Það er enginn live.tips-þjónn á
  þeirri leið.**
- **Þegar innskráð(ur)** býr lykillinn á þjóninum okkar (dulkóðaður, eins og að ofan), og
  Stripe tilkynnir hvert þjórfé til vefkróksins okkar, sem skrifar það inn í hans eigin
  Firestore-sögu listamannsins. **Í þessum hætti er live.tips-þjónn á leiðinni** — fyrir
  þjórfégögnin, aldrei fyrir peningana. Nafn og skilaboð aðdáanda, ef hann skildi eitthvað
  eftir, ferðast með þjórfénu inn í hans eigin sögu listamannsins og stöðvast þar.

## Milliliðurinn — aðeins ef kveikt er á Revolut, MobilePay eða Monzo

Uppsetningar sem nota eingöngu Stripe snerta þetta aldrei.

Revolut, MobilePay og Monzo bjóða enga leið fyrir app til að staðfesta að greiðsla hafi
átt sér stað, svo það þjórfé er leitt í gegnum lítinn millilið með opnum kóða sem við
rekum á **Firebase** — Cloud Functions og Firestore í `europe-west1`, og þjórfjársíða
aðdáandans afhent frá **`tip.live.tips/t/<id>`**. Hann snertir aldrei peninga. Hér er allt
sem hann meðhöndlar.

### Hvað listamaðurinn geymir

Þegar þjórfjársíða er búin til geymir hún **birtingarnafn listamannsins, opinber skilaboð
hans, gjaldmiðil hans og þau greiðsluauðkenni sem hann kaus að birta** (Stripe-þjórféhlekk
hans, Revolut-notandanafn, MobilePay Box ID, Monzo-notandanafn), og, ef kveikt er á
lagabeiðnum, **opinbera lagalistann hans og verðið á hvert lag**. Þetta eru allt
upplýsingar sem listamaðurinn er hvort eð er vísvitandi að birta aðdáendum.

- **Varðveisla: þjórfjársíðu sem enginn aðgangur stendur að baki er eytt sjálfkrafa eftir
  90 daga án virkni.** Þjórfjársíða sem tilheyrir innskráðum aðgangi lifir jafn lengi og
  hljómsveitin sem hún tilheyrir.
- Listamaðurinn getur eytt þessu **samstundis** úr appinu, hvenær sem er.
- Ekkert netfang, ekkert lykilorð, ekkert lögheiti og engar bankaupplýsingar eru teknar
  hér.
- Leyndarmál síðunnar er **aðeins geymt sem tætigildi (hash)**. Við gætum ekki sagt þér
  leyndarmálið þótt þú spyrðir; við getum aðeins athugað hvort eitt sé rétt.

### Hvað aðdáandi sendir

Þjórfjárformið biður um **upphæð**, og valfrjálst **nafn** og **skilaboð** — og, fyrir
lagabeiðni, **hvaða lag**. Það er allt formið. Ekkert netfang, ekkert símanúmer, enginn
aðgangur.

Hvert sá texti sem aðdáandinn skrifar fer, og hversu lengi, fer eftir því hvort
listamaðurinn er innskráður:

- **Ef enginn aðgangur stendur að baki þjórfjársíðunni** er þjórféð skrifað í
  **afhendingarröð** — eitt stakt skjal sem er til þess eins að vera afhent skjá
  listamannsins. Þegar skjárinn sýnir þjórféð **eyðir tæki listamannsins því skjali.**
  Eyðingin *er* kvittunin. Ef skjár listamannsins er ótengdur — sími læstur, ekkert samband
  — **bíður þjórféð í þeirri röð í allt að eina klukkustund**, svo það glatist ekki
  einfaldlega, og fer yfir um leið og skjárinn tengist aftur. Ef enginn tengist aftur er því
  **eytt ólesnu**, sópað burt samkvæmt áætlun. Fyrir listamann án aðgangs er **sú röð eini
  staðurinn þar sem texti frá aðdáanda er nokkurn tímann geymdur á þjóninum okkar, og ein
  klukkustund er algjört hámark hans.**
- **Ef þjórfjársíðan tilheyrir innskráðum aðgangi** er engin röð. Þjónninn okkar skrifar
  þjórféð **beint inn í hans eigin sögu listamannsins** undir hans uid — inn í lotu
  kvöldsins ef sett er í gangi, eða inn í eigið safn hljómsveitarinnar ef ekki. Þar situr
  það **svo lengi sem hljómsveitin er til**; það er hans eigin saga, og það er einmitt það
  sem hann skráði sig inn fyrir. Þetta er sama sagan og Stripe-vefkrókurinn skrifar í, hér
  að ofan.
- Nafn þitt og skilaboð eru einnig sett inn í **greiðsluskýringuna** sem opnast í Revolut,
  MobilePay eða Monzo — þannig veit listamaðurinn hver gaf þjórfé. Þau fyrirtæki vinna það
  síðan samkvæmt eigin persónuverndarstefnum.
- Milliliðurinn geymir **enga þjórfésögu þvert á listamenn**. Hann getur ekki sýnt þér,
  okkur eða nokkrum öðrum lista yfir hver gaf hverjum þjórfé.

### IP-tölur og varnir gegn misnotkun

Opið form sem hver sem er getur sent í þarf einhverja vörn gegn vélmennum, þess vegna:

- IP-tala þín er send til **Cloudflare Turnstile** — vélmennavarnar sem keyrir á
  þjórfjársíðunni — til að staðfesta að þú sért ekki vélmenni. Turnstile er vara frá
  Cloudflare og er notuð í stað CAPTCHA sem greinir þig. Turnstile og DNS-inn okkar er það
  eina sem Cloudflare gerir enn fyrir okkur; milliliðurinn sjálfur keyrir nú á Firebase.
  Sjá [persónuverndarstefnu Cloudflare](https://www.cloudflare.com/privacypolicy/).
- IP-talan þín er einnig notuð til að **takmarka tíðni** beiðna — að senda þjórfé, að búa
  til þjórfjársíðu, að leysa inn kóða til að bæta við tæki. Það sem við geymum í þeim
  tilgangi er **saltað dulkóðunarlegt tætigildi (hash) af IP-tölunni**, aldrei IP-talan
  sjálf, í um **tvær klukkustundir**, og því er svo eytt. Saltið er leyndarmál þjónsins:
  án þess neitar kóðinn að geyma nokkuð yfirhöfuð, frekar en að geyma tætigildi sem hægt
  væri að snúa við.
- **Rekstrarskrár Google** skrá tæknileg atriði beiðna til milliliðarins — vefslóð,
  tímasetningu, stöðu — í nokkra daga. Kóðinn okkar skráir vísvitandi engin nöfn, engin
  skilaboð, engin leyndarmál og enga hausa. Google kemur fram sem vinnsluaðili okkar.

### Teljarar

Milliliðurinn telur **hversu mörg þjórfé** tiltekin þjórfjársíða hefur miðlað, svo við
getum komið auga á misnotkun og vitað hvort þetta er yfirhöfuð notað. Þetta er tala. Hún
inniheldur engin gögn um aðdáendur.

## Hver vinnur hvað

| Hver | Hvað þeir fá | Af hverju |
| --- | --- | --- |
| **Google (Firebase)** | Aðgangar, samstillt gögn innskráðs listamanns, dulkóðaði Stripe-lykillinn, milliliðurinn, ýtitókar og afhending, þjónsskrár | Valfrjálsi aðgangurinn, valfrjálsi milliliðurinn og ýtitilkynningar |
| **Google Cloud KMS** | Lykillinn sem pakkar inn Stripe-leyndarmáli innskráðs listamanns (aldrei leyndarmálið á berum stöfum) | Að halda geymda Stripe-lyklinum ólæsilegum í hvíld |
| **Stripe** | Greiðslugögn aðdáandans, sem sjálfstæður ábyrgðaraðili; og, fyrir innskráðan listamann, þjórféviðburðir sendir til vefkróksins okkar | Þjórfé með korti |
| **Cloudflare** | IP-tala aðdáandans, vegna Turnstile-athugunar á þjórfjársíðunni. Og DNS-inn okkar. | Að halda vélmennum frá þjórfjárforminu |
| **GitHub** | IP-tala og vafraauðkenni allra sem hlaða þessari vefsíðu | Hýsing vefsíðunnar |
| **Ýtiþjónusta vafrans þíns / símans** (t.d. Google fyrir Chrome) | Ýtitóki og innihald tilkynningarinnar, ef þú kveiktir á tilkynningum | Að afhenda ýtitilkynningar |
| **Revolut / MobilePay / Monzo** | Allt sem aðdáandinn gerir í þeirra eigin appi, greiðsluskýringin meðtalin | Þessar greiðsluleiðir |

Við seljum engum neitt, og það er enginn annar á þeim lista.

## Lagagrundvöllur, ef þú þarft slíkan (GDPR)

- Að reka aðgang sem þú baðst um, að samstilla þín eigin gögn í þín eigin tæki, að geyma
  Stripe-lykilinn þinn svo þjórféð þitt rati í söguna þína, að reka milliliðinn fyrir
  listamann sem kveikti á honum, að afhenda þjórfé frá aðdáanda á þann skjá sem því var
  beint að, og að senda ýtitilkynningu sem þú kveiktir á: **framkvæmd þjónustu sem þú baðst
  um**.
- Tíðnitakmarkanir, Turnstile, kvótar byggðir á tættum IP-tölum og afturköllun tækja:
  **lögmætir hagsmunir** af því að verja ókeypis og opna þjónustu fyrir eyðileggingu af
  völdum vélmenna og svika, og af því að halda aðgöngum listafólks öruggum.
- Þjónsskrár: **lögmætir hagsmunir** af því að reka og tryggja öryggi þjónustunnar.

## Að eyða hlutum

Þetta skiptir meira máli en nokkurt loforð sem við gætum gefið um það, svo hér er nákvæmlega
það sem er til í dag — þar með talið það sem er ekki til.

- **Enginn aðgangur**: fjarlægðu appið. Þar með er þetta allt farið.
- **Hljómsveit**: að fjarlægja hljómsveit í appinu eyðir skýjagögnum þeirrar hljómsveitar —
  stillingum hennar, lyklum, lotum, þjórfésögu — ásamt afritinu í tækinu.
- **Þjórfjársíða**: eyddu henni eða endurgerðu hana í appinu og henni er samstundis eytt
  hjá milliliðnum, ásamt öllu þjórfé sem bíður afhendingar.
- **Ýtitilkynningar**: slökktu á þeim í tæki og ýtitóka þess er eytt. Bjölluveitan hreinsast
  með hljómsveitinni eða aðgangnum.
- **Tæki**: Stillingar → Öryggi telja upp tækin þín. Þú getur afturkallað eitt, eða skráð
  þig út alls staðar annars staðar — sem bindur enda á lotu allra hinna tækjanna
  samstundis, ekki einhvern tímann síðar.
- **Öllum aðgangnum þínum, með einni snertingu: appið hefur ekki þann hnapp enn þá.** Við
  viljum frekar viðurkenna það en að láta sem annað. Þar til hann verður til skaltu skrifa
  á **[contact@live.tips](mailto:contact@live.tips)** og við eyðum aðgangnum og öllu undir
  honum, í höndunum. Þangað til geturðu nú þegar eytt hverri einustu hljómsveit, sem
  fjarlægir allt sem einhverju máli skiptir — þar með talinn geymda Stripe-lykilinn — og
  skilur eftir tóman aðgang.

## Réttindi þín

Þú getur beðið okkur um afrit af, leiðréttingu á eða eyðingu á öllu því sem við geymum um
þig, og þú getur kvartað til persónuverndaryfirvalda í þínu landi. Skrifaðu á
**[contact@live.tips](mailto:contact@live.tips)**.

Í reynd er flest af þessu þegar í þínum höndum: listamaður getur eytt þjórfjársíðu eða
hljómsveit úr appinu samstundis, óafhent þjórfé frá aðdáendum gufar upp innan
klukkustundar, og ef þú skráir þig aldrei inn var ekkert af þessu nokkurn tímann annars
staðar en í þínu eigin tæki.

## Börn

live.tips beinist ekki að börnum og við vinnum ekki vitandi vits gögn um þau.

## Breytingar

Við uppfærum þessa síðu þegar hugbúnaðurinn breytist. Þar sem allt verkefnið er opinn
hugbúnaður er **hver einasta fyrri útgáfa þessarar stefnu í opinberri git-sögu** — þú
getur borið nákvæmlega saman hvað breyttist og hvenær.

## Tungumál

Þessi stefna er birt á öllum tungumálum sem vefsíðan styður, til hægðarauka. Ef þýðing og
enska útgáfan stangast á, **er enska útgáfan sú sem gildir**.
</content>
</invoke>
