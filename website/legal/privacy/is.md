---
title: Persónuverndarstefna
description: live.tips er án vafrakaka, án greiningartóla og án rakningar, og virkar alveg án aðgangs. Ef þú kýst að skrá þig inn, þá er hér nákvæmlega hvað er geymt, hvar, af hverjum og hversu lengi.
updated: 2026-07-13
updated_label: Síðast uppfært 13. júlí 2026
---

live.tips er þjórfékrukka fyrir listafólk, byggð á opnum hugbúnaði. Hún er rekin af
**Nikita Rabykin**, einstökum forritara, ekki fyrirtæki. Ef eitthvað hér að neðan skiptir
þig máli, skrifaðu þá á **[contact@live.tips](mailto:contact@live.tips)** — þar er
manneskja á hinum endanum.

Þessi stefna er hreinskilin um leiðinlegu atriðin. Við segjum frekar „við geymum nafnið
þitt í allt að eina klukkustund“ en að halda því fram að við geymum ekkert og hafa rangt
fyrir okkur.

## Stutta útgáfan

- **Aðgangur er valfrjáls.** Appið virkar alveg án aðgangs, og það er enn sjálfgefið. Ef
  þú vilt fá hljómsveitirnar þínar og söguna þína í annað tæki geturðu skráð þig inn — og
  þá er sumt af þessu geymt á þjóni. Hvað er hvað er útlistað hér að neðan.
- **Engar vafrakökur.** Ekki ein, hvergi.
- **Engin greiningartól, engin rakning, engar auglýsingar, engin skriftur frá þriðja aðila**
  á þessari vefsíðu.
- **Við snertum peningana þína aldrei.** Þjórfé fer beint frá aðdáandanum inn á Stripe-,
  Revolut-, MobilePay- eða Monzo-reikning listamannsins sjálfs. Við erum ekki á þeirri leið.
- **Í sjálfgefinni uppsetningu talar appið aðeins við Stripe** — ekki við neinn
  live.tips-þjón.
- Eini þjónninn sem við rekum yfirhöfuð er lítill milliliður á Firebase, sem er Google.
  Hann er aðeins til ef listamaður kveikir á Revolut, MobilePay eða Monzo — eða ef hann
  skráir sig inn.

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
- **Þjórfésaga, lotusaga, markmiðið og stillingar appsins** eru geymd í staðbundinni
  geymslu tækisins. Þetta felur í sér nöfnin og skilaboðin sem aðdáendur láta fylgja
  þjórfénu sínu.
- Að fjarlægja appið eyðir þessu öllu. Það er ekkert skýjaafrit hjá okkur, því í þessum
  hætti er ekkert ský hjá okkur.

**Við fáum ekkert af þessu.** Appinu fylgir ekkert greiningar-SDK, enginn
hrunskýrslugjafi, engar ýtitilkynningar og enginn auglýsingakóði — ekkert af því, ekki
einu sinni óvirkt.

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
  Apple máttu fela netfangið þitt; Apple gefur okkur þá endurvarpsnetfang í staðinn.)
- **Gestaaðgangur** — nafnlaus aðgangur án netfangs og án nafns. Hann samstillir og hægt er
  að afturkalla hann, en það er ekkert til að endurheimta hann með ef þú týnir tækinu. Hann
  er uid og ekkert annað.

Þegar þú ert innskráð(ur) fær aðgangurinn sitt eigið einkahorn í **Cloud Firestore**
gagnagrunni Google, á `users/<your uid>/`. Öryggisreglurnar veita þessu uid það horn **og
engum öðrum** — enginn annar aðgangur getur lesið það, ekki heldur með því að giska á
vefslóðir. Þar inni er:

| Hvað | Af hverju það er þarna |
| --- | --- |
| **Hljómsveitirnar þínar** — nöfn, stillingar þjórfékrukkunnar og greiðsluleiða, orðalag plakatsins, markmið | svo hljómsveit sé til í hverju því tæki sem þú skráir þig inn í |
| **Takmarkaði Stripe-lykillinn þinn** og leyndarmál þjórfjársíðunnar hjá milliliðnum | í leyndarmálaskjali sem aðeins þitt uid getur lesið, og í skyndiminni í lyklakippu hvers tækis þíns |
| **Stillingar appsins** | svo tæki sem þú bætir við sé þegar uppsett |
| **Lotuskrár og þjórfésaga** — þar með talin **nöfnin og skilaboðin sem aðdáendur láta fylgja þjórfénu sínu** | því þessi saga er nákvæmlega það sem þú baðst um að sjá í hinu tækinu |
| **Lifandi lotan** sem er í gangi núna | svo annar skjár geti tengst settinu í kvöld |
| **Tækin þín** — nafnið sem hvert þeirra gefur sér („iPhone Nikita“), stýrikerfi og gerð, hvenær það sást fyrst og síðast | svo Stillingar → Öryggi geti talið þau upp, og þú getir afturkallað eitt |
| Lítið **prófílskjal** — aðgangsnafnið sem þú valdir og hvaða þjónustuveitanda þú notaðir | svo aðgangsvalið geti merkt hann |

Og svo það mikilvæga, umbúðalaust: **án aðgangs fara nafn og skilaboð aðdáanda aldrei úr
tæki listamannsins. Með aðgangi eru þau geymd á þjónum Google undir uid listamannsins, sem
hluti af hans eigin samstilltu sögu.** Enginn annar aðgangur getur lesið þau, við lítum
ekki á þau, og ekkert er leitt af þeim — en þau eru þarna, og þú ættir að vita það áður en
þú skráir þig inn.

Að skrá sig út setur tækið aftur í staðbundna háttinn. Það eyðir ekki gögnum aðgangsins —
sjá *Að eyða hlutum* hér að neðan.

### Að bæta við tæki með QR-kóða

Til að bæta við tæki sýnir þú QR-kóða úr tæki sem er þegar innskráð. Kóðinn er
tilviljanakenndur, **einnota, og rennur út eftir tvær mínútur**, og nýja tækið fær ekkert
fyrr en þú ýtir á *staðfesta* í því gamla. Meðan þetta handaband stendur yfir geymum við
kóðann, nafnið sem nýja tækið gaf sér og stýrikerfi þess — og færslunni er eytt þegar hún
rennur út. Ljósmyndaður QR-kóði er einskis virði án staðfestingar þinnar.

## Hvar allt þetta býr í raun og veru

Firebase Auth, Cloud Firestore og Cloud Functions-föllin okkar keyra í
**Evrópusambandinu** — gagnagrunnurinn í `eur3` fjölsvæðinu hjá Google, föllin í
`europe-west1`. Google kemur fram sem vinnsluaðili okkar samkvæmt
[persónuverndar- og öryggisskilmálum Firebase](https://firebase.google.com/support/privacy)
og eigin [persónuverndarstefnu](https://policies.google.com/privacy). Eins og allir stórir
þjónustuveitendur kann Google að nýta innviði utan ESB vegna stuðnings og öryggis; það fer
eftir þeim skilmálum, ekki okkur.

## Stripe

Þegar aðdáandi borgar með korti er hann á greiðslusíðu **Stripe**, ekki okkar. Stripe
safnar og vinnur greiðslugögn hans sem sjálfstæður ábyrgðaraðili samkvæmt
[persónuverndarstefnu Stripe](https://stripe.com/privacy). Við sjáum aldrei kortanúmer og
við höfum engan aðgang að Stripe-reikningi listamannsins.

App listamannsins les hans eigið þjórfé frá Stripe með takmarkaða lyklinum hans sjálfs —
beint úr tækinu til `api.stripe.com`. **Það er enginn live.tips-þjónn á þeirri leið, og
hefur aldrei verið.** Nafn og skilaboð aðdáanda, ef hann skildi eitthvað eftir, ferðast frá
Stripe yfir í tæki listamannsins og stöðvast þar — nema listamaðurinn hafi skráð sig inn,
en þá vistar tækið þau einnig í hans eigin Firestore-sögu, eins og lýst er hér að ofan.

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
hans, Revolut-notandanafn, MobilePay Box ID, Monzo-notandanafn). Þetta eru allt
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

Þjórfjárformið biður um **upphæð**, og valfrjálst **nafn** og **skilaboð**. Það er allt
formið. Ekkert netfang, ekkert símanúmer, enginn aðgangur.

- Þjórféð er skrifað í **afhendingarröð** — eitt stakt skjal sem er til þess eins að vera
  afhent skjá listamannsins. Þegar skjárinn sýnir þjórféð **eyðir tæki listamannsins því
  skjali.** Eyðingin *er* kvittunin; það er engin „afhent“-merking, því það er engin
  færsla eftir til að merkja.
- Ef skjár listamannsins er ótengdur — sími læstur, ekkert samband — **bíður þjórféð í
  þeirri röð í allt að eina klukkustund**, svo það glatist ekki einfaldlega, og fer yfir um
  leið og skjárinn tengist aftur. Ef enginn tengist aftur er því **eytt ólesnu**, sópað
  burt samkvæmt áætlun, hvort sem nokkur kom nokkurn tímann aftur að sækja það eða ekki.
- **Þessi röð er eini staðurinn þar sem texti frá aðdáanda er nokkurn tímann geymdur á
  þjóninum okkar, og ein klukkustund er algjört hámark hans.** Ef listamaðurinn er
  innskráður geymir tækið hans þjórféð síðan í *hans* Firestore-sögu — því það er hans
  saga, og það er einmitt það sem hann skráði sig inn fyrir.
- Nafn þitt og skilaboð eru einnig sett inn í **greiðsluskýringuna** sem opnast í Revolut,
  MobilePay eða Monzo — þannig veit listamaðurinn hver gaf þjórfé. Þau fyrirtæki vinna það
  síðan samkvæmt eigin persónuverndarstefnum.
- Milliliðurinn geymir **enga þjórfésögu**. Hann getur ekki sýnt þér, okkur eða nokkrum
  öðrum lista yfir hver gaf hverjum þjórfé.

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
| **Google (Firebase)** | Aðgangar, samstillt gögn innskráðs listamanns, milliliðurinn, þjónsskrár | Valfrjálsi aðgangurinn og valfrjálsi milliliðurinn |
| **Stripe** | Greiðslugögn aðdáandans, sem sjálfstæður ábyrgðaraðili | Þjórfé með korti |
| **Cloudflare** | IP-tala aðdáandans, vegna Turnstile-athugunar á þjórfjársíðunni. Og DNS-inn okkar. | Að halda vélmennum frá þjórfjárforminu |
| **GitHub** | IP-tala og vafraauðkenni allra sem hlaða þessari vefsíðu | Hýsing vefsíðunnar |
| **Revolut / MobilePay / Monzo** | Allt sem aðdáandinn gerir í þeirra eigin appi, greiðsluskýringin meðtalin | Þessar greiðsluleiðir |

Við seljum engum neitt, og það er enginn annar á þeim lista.

## Lagagrundvöllur, ef þú þarft slíkan (GDPR)

- Að reka aðgang sem þú baðst um, að samstilla þín eigin gögn í þín eigin tæki, að reka
  milliliðinn fyrir listamann sem kveikti á honum, og að afhenda þjórfé frá aðdáanda á þann
  skjá sem því var beint að: **framkvæmd þjónustu sem þú baðst um**.
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
- **Tæki**: Stillingar → Öryggi telja upp tækin þín. Þú getur afturkallað eitt, eða skráð
  þig út alls staðar annars staðar — sem bindur enda á lotu allra hinna tækjanna
  samstundis, ekki einhvern tímann síðar.
- **Öllum aðgangnum þínum, með einni snertingu: appið hefur ekki þann hnapp enn þá.** Við
  viljum frekar viðurkenna það en að láta sem annað. Þar til hann verður til skaltu skrifa
  á **[contact@live.tips](mailto:contact@live.tips)** og við eyðum aðgangnum og öllu undir
  honum, í höndunum. Þangað til geturðu nú þegar eytt hverri einustu hljómsveit, sem
  fjarlægir allt sem einhverju máli skiptir og skilur eftir tóman aðgang.

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
