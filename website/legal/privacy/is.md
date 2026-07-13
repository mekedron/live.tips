---
title: Persónuverndarstefna
description: live.tips er án aðganga, án vafrakaka, án greiningartóla og án rakningar. Hér er stutti listinn yfir það sem er unnið, af hverjum og hversu lengi.
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

- **Engir aðgangar.** Það er ekkert að skrá sig fyrir.
- **Engar vafrakökur.** Ekki ein, hvergi.
- **Engin greiningartól, engin rakning, engar auglýsingar, engin skriftur frá þriðja aðila**
  á þessari vefsíðu.
- **Við snertum peningana þína aldrei.** Þjórfé fer beint frá aðdáandanum inn á Stripe-,
  Revolut-, MobilePay- eða Monzo-reikning listamannsins sjálfs. Við erum ekki á þeirri leið.
- **Í sjálfgefinni uppsetningu talar appið aðeins við Stripe** — ekki við neinn
  live.tips-þjón.
- Eini þjónninn sem við rekum yfirhöfuð er lítill milliliður, og hann er aðeins til ef
  listamaður kveikir á Revolut, MobilePay eða Monzo.

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

## Appið

live.tips-appið keyrir **á tæki listamannsins sjálfs**. Allt sem það veit býr þar:

- **Takmarkaði Stripe-lykillinn** er geymdur í lyklakippu tækisins (iOS/macOS Keychain,
  Android Keystore) og er aðeins sendur til `api.stripe.com`.
- **Þjórfésaga, lotusaga, markmiðið og stillingar appsins** eru geymd í staðbundinni
  geymslu tækisins. Þetta felur í sér nöfnin og skilaboðin sem aðdáendur láta fylgja
  þjórfénu sínu.
- Að fjarlægja appið eyðir þessu öllu. Það er ekkert skýjaafrit hjá okkur, því það er
  ekkert ský hjá okkur.

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

## Stripe

Þegar aðdáandi borgar með korti er hann á greiðslusíðu **Stripe**, ekki okkar. Stripe
safnar og vinnur greiðslugögn hans sem sjálfstæður ábyrgðaraðili samkvæmt
[persónuverndarstefnu Stripe](https://stripe.com/privacy). Við sjáum aldrei kortanúmer og
við höfum engan aðgang að Stripe-reikningi listamannsins.

App listamannsins les hans eigið þjórfé frá Stripe með takmarkaða lyklinum hans sjálfs.
Nafn og skilaboð aðdáanda, ef hann skildi eitthvað eftir, ferðast frá Stripe yfir í tæki
listamannsins og stöðvast þar.

## Milliliðurinn — aðeins ef kveikt er á Revolut, MobilePay eða Monzo

Uppsetningar sem nota eingöngu Stripe snerta þetta aldrei og mega hætta lestri hér.

Revolut, MobilePay og Monzo bjóða enga leið fyrir app til að staðfesta að greiðsla hafi
átt sér stað, svo það þjórfé er leitt í gegnum lítinn millilið með opnum kóða sem við
rekum á **Cloudflare** á `api.live.tips`. Hann snertir aldrei peninga. Hér er allt sem
hann meðhöndlar.

### Hvað listamaðurinn geymir

Þegar þjórfjársíða er búin til geymir hún **birtingarnafn listamannsins, opinber skilaboð
hans, gjaldmiðil hans og þau greiðsluauðkenni sem hann kaus að birta** (Stripe-þjórféhlekk
hans, Revolut-notandanafn, MobilePay Box ID, Monzo-notandanafn). Þetta eru allt
upplýsingar sem listamaðurinn er hvort eð er vísvitandi að birta aðdáendum.

- **Varðveisla — eytt sjálfkrafa eftir 90 daga án virkni.**
- Listamaðurinn getur eytt þessu **samstundis** úr appinu, hvenær sem er.
- Ekkert netfang, ekkert lykilorð, ekkert lögheiti og engar bankaupplýsingar eru nokkurn
  tímann teknar.

### Hvað aðdáandi sendir

Þjórfjárformið biður um **upphæð**, og valfrjálst **nafn** og **skilaboð**. Það er allt
formið. Ekkert netfang, ekkert símanúmer, enginn aðgangur.

- Ef skjár listamannsins er **á neti** er þjórféð sent beint áfram til hans og **aldrei
  skrifað á disk**.
- Ef skjár listamannsins er **ótengdur** — sími læstur, ekkert samband — er þjórféð
  **geymt í allt að eina klukkustund** svo það glatist ekki einfaldlega, og síðan afhent um
  leið og skjárinn tengist aftur. Ef enginn tengist aftur er því **eytt ólesnu**. Þetta er
  eini textinn frá aðdáanda sem milliliðurinn geymir nokkurn tímann, og ein klukkustund er
  algjört hámark hans.
- Nafn þitt og skilaboð eru einnig sett inn í **greiðsluskýringuna** sem opnast í Revolut,
  MobilePay eða Monzo — þannig veit listamaðurinn hver gaf þjórfé. Þau fyrirtæki vinna það
  síðan samkvæmt eigin persónuverndarstefnum.
- Milliliðurinn geymir **enga þjórfésögu**. Hann getur ekki sýnt þér, okkur eða nokkrum
  öðrum lista yfir hver gaf hverjum þjórfé.

### IP-tölur og varnir gegn misnotkun

Opið form sem hver sem er getur sent í þarf einhverja vörn gegn vélmennum, þess vegna:

- IP-tala þín er notuð til að **takmarka tíðni** beiðna, og er send til **Cloudflare
  Turnstile** (vélmennavörn sem keyrir á þjórfjársíðunni) til að staðfesta að þú sért ekki
  vélmenni. Turnstile er vara frá Cloudflare og er notuð í stað CAPTCHA sem greinir þig.
- Til að koma í veg fyrir að einhver búi til þúsundir þjórfjársíðna er **dulkóðunarleg
  tætingargildi (hash) af IP-tölu** þess sem býr til síðu geymt í um **tvær klukkustundir**
  og því svo hent.
- **Rekstrarskrár Cloudflare** skrá tæknileg atriði beiðna til milliliðarins — vefslóð,
  tímasetningu, stöðu — í nokkra daga. Þær innihalda ekki nöfn eða skilaboð aðdáenda.
  Cloudflare kemur fram sem vinnsluaðili okkar; sjá
  [persónuverndarstefnu Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Teljarar

Milliliðurinn telur **hversu mörg þjórfé** tiltekin þjórfjársíða hefur miðlað, svo við
getum komið auga á misnotkun og vitað hvort þetta er yfirhöfuð notað. Þetta er tala. Hún
inniheldur engin gögn um aðdáendur.

## Lagagrundvöllur, ef þú þarft slíkan (GDPR)

- Rekstur milliliðarins fyrir listamann sem kveikti á honum, og afhending þjórfjár frá
  aðdáanda á þann skjá sem því var beint að: **framkvæmd þjónustu sem þú baðst um**.
- Tíðnitakmarkanir, Turnstile og kvótar byggðir á tættum IP-tölum: **lögmætir hagsmunir**
  af því að verja ókeypis og opna þjónustu fyrir eyðileggingu af völdum vélmenna og svika.
- Þjónsskrár: **lögmætir hagsmunir** af því að reka og tryggja öryggi þjónustunnar.

## Réttindi þín

Þú getur beðið okkur um afrit af, leiðréttingu á eða eyðingu á öllu því sem við geymum um
þig, og þú getur kvartað til persónuverndaryfirvalda í þínu landi. Skrifaðu á
**[contact@live.tips](mailto:contact@live.tips)**.

Í reynd er flest af þessu þegar í þínum höndum: listamenn geta eytt þjórfjársíðunni sinni
úr appinu samstundis, þjórfé frá aðdáendum gufar upp innan klukkustundar, og allt annað
býr í þínu eigin tæki.

## Börn

live.tips beinist ekki að börnum og við vinnum ekki vitandi vits gögn um þau.

## Breytingar

Við uppfærum þessa síðu þegar hugbúnaðurinn breytist. Þar sem allt verkefnið er opinn
hugbúnaður er **hver einasta fyrri útgáfa þessarar stefnu í opinberri git-sögu** — þú
getur borið nákvæmlega saman hvað breyttist og hvenær.

## Tungumál

Þessi stefna er birt á öllum tungumálum sem vefsíðan styður, til hægðarauka. Ef þýðing og
enska útgáfan stangast á, **er enska útgáfan sú sem gildir**.
