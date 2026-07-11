---
title: Bacșiș contactless pentru muzicanți stradali, pe cinstite
description: Tap to Pay pe telefon, un cititor de card, un sticker NFC, un cod QR — patru lucruri diferite cărora li se spune, tuturor, „contactless". Cât costă fiecare cu adevărat în 2026, ce face de fapt un tag NFC (nu e ce crezi) și când bate atingerea scanarea.
slug: bacsis-contactless-pentru-muzicanti-stradali
---

Caută bacșiș contactless pentru muzicanți stradali și internetul îți servește anul
2018. Un prototip studențesc de la Brunel University, numit Tiptap — un suport în
care înfigi un telefon —, a prins o rundă de presă în anul acela, iar presa aia
stă și azi pe prima pagină. Era o idee drăguță. Era însă, în chiar cuvintele
articolelor, *încă în stadiul de dezvoltare*, și își propunea să le ceară
muzicanților o taxă unică plus **5% din fiecare bacșiș**. N-a devenit niciodată
ceva ce se poate cumpăra.

(„tiptap"-ul pe care-l găsești dacă te apuci să cauți acum e o firmă fără legătură
din Ontario, care vinde terminale de donații contactless către organizații
caritabile. Același cuvânt, alt produs, nu pentru tine.)

Așa că starea cinstită a lucrurilor n-a mai fost scrisă nicăieri de opt ani. Iat-o.

Asta e scufundarea în *tap*. Dacă întrebarea ta adevărată e cea mai largă — cum
încasezi în general acum, când nimeni nu mai are cash, și cât costă fiecare variantă
— începe cu [cum încasează artiștii stradali plăți cu
cardul](post:how-buskers-take-card-payments) și vino înapoi aici.

## Patru lucruri diferite se numesc, toate, „contactless"

Aici locuiește cea mai mare parte a confuziei, așa că hai să le separăm înainte de
a pune vreun preț pe ceva.

1. **Tap to Pay pe propriul tău telefon.** Telefonul tău devine terminalul. Fanul
   își apropie cardul sau ceasul de *aparatul tău*. Absolut niciun hardware în
   plus.
2. **Un cititor de card** — un SumUp, un Zettle, un Square. Un mic terminal de
   plastic pe care-l întinzi. Fanul îl atinge.
3. **Un tag NFC** — stickerul sau plăcuța „atinge aici ca să lași bacșiș". Ăsta e
   înțeles greșit aproape universal, și secțiunea următoare e despre de ce.
4. **Un cod QR.** Nu e contactless în sensul NFC — dar citește mai departe, pentru
   că din partea fanului se termină foarte des exact în aceeași atingere.

Doar primele două sunt *terminale de plată*. Distincția asta e tot articolul.

## Tagul NFC nu încasează nicio plată

Hai să omorâm chestia asta ca lumea, pentru că vânzătorii te lasă bucuroși să crezi
altceva.

Un sticker NFC — soiul ieftin, cipul NTAG213 pe care-l folosesc majoritatea — are
**144 de octeți de memorie**. Nu 144 de kiloocteți. Nu poate rula cod, n-are
baterie, n-a auzit în viața lui de o schemă de carduri și n-ar avea unde să încapă
un protocol de plată nici dacă ar vrea. Ce încape în el e un șir scurt de caractere,
formatat ca înregistrare NDEF, iar șirul acela e, covârșitor de des, un **URL**.

Îl atingi, iar telefonul îți deschide o pagină web. Asta e toată funcția.

Ceea ce înseamnă că o plăcuță „tap to tip" e un cod QR pe care-l deschizi atingând,
în loc să-l ochești. Aceeași destinație, aceeași pagină web, aceeași plată care se
întâmplă în browser. Chiar și specialiștii o spun, dacă îi citești cu atenție: pe
propriul lor site, cei de la tiptap își descriu dispozitivul cu sumă liberă spunând
că *„atunci când donatorii își apropie telefonul de un dispozitiv de donații
personalizat, vor fi direcționați către pagina ta online de strângere de fonduri."*
Direcționați către o pagină. Pentru că asta poate face un tag.

E ceva chiar util, și e și ieftin — stickerele NTAG213 goale pornesc de la vreo
**0,24 $ bucata** la pachet. Dacă ai deja o pagină de bacșiș, un tag lipit pe husă
lângă codul tipărit te costă mărunțiș și le dă unor fani o cale mai rapidă înăuntru.

Dar să fie clar ce ai cumpărat: **o a doua ușă de intrare către aceeași pagină.** Nu
o mașină de carduri.

### Iar afară e o ușă mofturoasă

Modurile de eșec sunt reale, și niciun vânzător de taguri nu le enumeră:

- **Telefonul fanului trebuie să fie deblocat și în uz.** Documentația Apple e
  explicită: citirea tagurilor în fundal se întâmplă doar cât timp iPhone-ul e în
  uz, iar dacă telefonul e blocat, sistemul îl pune întâi să-l deblocheze.
- **Nu funcționează cât timp camera e deschisă.** Apple menționează camera activă
  drept una dintre stările în care citirea tagurilor în fundal nu e disponibilă.
  Savurează ironia: un fan care întinde mâna după cameră ca să-ți scaneze codul QR
  tocmai ți-a dezactivat tagul NFC.
- **Are nevoie de un iPhone XS sau mai nou**, iar pe Android are nevoie de NFC
  pornit — pe care unele moduri de economisire a bateriei îl opresc.
- **Raza e de vreo 4 cm.** Fanul chiar trebuie să atingă obiectul. În mulțime,
  aplecat peste o husă de chitară, asta e o cerere serioasă.
- **Metalul și magneții îl omoară.** Un tag lipit pe amplificator, sau un fan cu o
  husă magnetică, și nu se întâmplă absolut nimic.

Un tag e o a doua opțiune drăguță. E o proastă unică opțiune.

## Tap to Pay pe telefon: adevărata noutate din 2026

Iată lucrul care s-a schimbat de la articolele despre Tiptap încoace și despre care
nicio relatare veche nu știe nimic.

**Tap to Pay pe iPhone** transformă telefonul pe care deja îl ai în buzunar într-un
terminal contactless. Fără dongle, fără cititor, fără suport. Apple îl listează ca
disponibil în **peste 70 de țări și regiuni**, iar furnizorii prin care îl poți
folosi în Europa sună ca toată industria — numai în Germania: Adyen, Mollie, myPOS,
Nexi, PAYONE, Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Marea Britanie,
Franța, Olanda, Suedia, Finlanda și Danemarca au liste asemănătoare. Ai nevoie de un
iPhone XS sau mai nou.

**Tap to Pay pe Android** există și el, dar e mai îngust. Prin Stripe, e disponibil
în general în AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG
și US, cu încă optsprezece țări în previzualizare publică. Telefonul tău are nevoie
de Android 13 sau mai nou, de un senzor NFC, de un bootloader nemodificat, de Google
Mobile Services și de opțiunile pentru dezvoltatori oprite — ultima prinde mai multă
lume decât ți-ai închipui.

Versiunea practică: **SumUp listează Tap to Pay la 0 £ hardware.** Dacă ai un iPhone
recent și ești într-o țară acoperită, costul de intrare pentru a întinde un terminal
contactless e acum zero. Doar faptul ăsta face caduc orice articol din 2018 care-ți
spunea „cumpără-ți suportul ăsta".

## Cititoarele de card și cât costă ele cu adevărat

Dacă vrei o bucată separată de plastic — și există motive bune, mai jos —, piața e
formată din trei produse.

| | Hardware | Comision pe atingere în prezență |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69%**, fără sumă fixă |
| **SumUp** (Germania) | — | **1,39%**, fără sumă fixă |
| **Zettle / PayPal POS** (UK) | Cititor de la 29 £ la prima achiziție, 69 £ după | **1,75%**, fără sumă fixă |
| **Square** (UK) | Cititor contactless + cip 19 £ | **1,75%**, fără sumă fixă |
| **Square** (US) | Cititor contactless + cip 59 $ | **2,6% + 0,15 $** |

Prețurile sunt fără TVA și așa cum erau publicate în iulie 2026. Du-te și
verifică-le; se mișcă.

Acum citește tabelul încă o dată, pentru că spune ceva care contrazice ce ți s-a
spus, probabil, până acum.

## Aritmetica comisioanelor și lucrul pe care toată lumea îl ia invers

Înțelepciunea populară zice că taxele de card distrug bacșișurile mici din cauza
sumei fixe pe tranzacție — cei douăzeci și cinci de cenți care mănâncă o optime
dintr-un bacșiș de 2 €. E adevărat, și
[ne-am scris singuri socoteala](post:build-a-tip-jar-on-your-own-stripe).

Dar e adevărat pentru plățile cu cardul *online*. **Cititoarele contactless europene
n-au, în general, nicio sumă fixă.** SumUp, Zettle și Square, în Marea Britanie și în
UE, sunt doar procent. Ceea ce înseamnă:

| Un bacșiș de 2 € | Comision | Artistul păstrează | Ciupeală efectivă |
| --- | --- | --- | --- |
| Cititor SumUp (DE, 1,39%) | 0,03 € | 1,97 € | **1,4%** |
| Zettle / Square (UK, 1,75%) | 0,04 € | 1,96 € | 1,8% |
| Stripe, card online (SEE, 1,5% + 0,25 €) | 0,28 € | 1,72 € | **14,0%** |
| Cititor Square (US, 2,6% + 0,15 $) | 0,20 $ | 1,80 $ | **10,1%** |

Măsurat doar la comision, un terminal european cu atingere bate o plată cu cardul
online la un bacșiș mic, și nici nu e aproape. Suntem un produs pe bază de cod QR și
îți spunem asta: la un bacșiș de 2 €, un cititor SumUp îți lasă 0,25 € pe care o
pagină găzduită de Stripe nu ți-i lasă.

Două lucruri pun asta la loc în proporție.

**Hardware-ul e suma fixă, doar mutată.** O economie de 0,25 € pe bacșiș față de un
Solo de 79 £ înseamnă aproximativ **trei sute de atingeri până când cititorul se
plătește singur**. E o cifră reală pentru un muzicant care lucrează și una caraghioasă
pentru cineva care cântă de două ori pe vară. (Iar Tap to Pay-ul la 0 £ de la SumUp
face din ea zero atingeri — exact de asta contează opțiunea aia mai mult decât
cititoarele.)

**Iar Statele Unite răstoarnă lucrurile înapoi.** Rata americană în prezență a lui
Square poartă o sumă fixă de 0,15 $, așa că o atingere de 2 $ pierde o zecime din ea
și la terminal. Cadoul „fără sumă fixă" e unul european.

Mai e și un prag de jos pe care-l vei întâlni: SumUp nu acceptă o plată sub **1 £ /
1 €**. Orice șină ai alege, bacșișul foarte mic nu prea e o tranzacție cu cardul.

## Deci când bate atingerea scanarea?

Ia tehnologia deoparte și rămâne o întrebare despre mâinile fanului.

**O atingere cere ca telefonul fanului să fie deblocat și în mână, și cere ca tu să
întinzi ceva.** Când amândouă sunt adevărate, e cel mai rapid lucru din plăți. Fără
aplicație, fără ochit, fără tastat, gata într-o secundă.

**O scanare cere ca fanul să deschidă camera** — un gest deliberat în plus — dar nu-ți
cere absolut nimic ție. Codul stă pe husă. Funcționează pentru un fan care stă în
spate. Funcționează pentru patruzeci de oameni deodată. Funcționează în timp ce tu
încă mai cânți.

Ceea ce dă o împărțire cinstită:

- **Atingerea câștigă când poți merge la oameni.** La finalul setului, cu pălăria pe
  la mese, un fan pe rând, tu liber să ții un terminal. O atingere e o cerere cu mai
  puțină frecare decât „scoate-ți camera", iar în clipa aia ești fizic acolo ca s-o
  închizi.
- **Scanarea câștigă când nu poți.** În mijlocul cântecului. Mulțime pe trei rânduri.
  Un loc din care nu poți pleca de lângă amplificator. Oricine vrea să dea în timp ce
  trece. Un terminal servește exact o persoană; un cod tipărit servește toată piața,
  simultan, și nu-ți cere să te oprești din cântat ca să-l servești.

Ultimul punct e cel pe care vânzătorii de terminale nu-l fac niciodată, și e cel mai
mare. **Un cititor de card e un gât de sticlă cu coadă la el.** Un cod QR n-are
coadă.

Și iată partea care dizolvă jumătate din ceartă: pe o pagină de bacșiș bine făcută,
**scanarea se termină oricum într-o atingere**. Fanul scanează, pagina se deschide,
iar telefonul lui îi oferă Apple Pay sau Google Pay. Dublu clic, își apropie telefonul
de față, gata. Din partea fanului, aia e o plată contactless — același portofel,
același card, aceleași două secunde — și n-ai cumpărat niciun hardware ca să se
întâmple.

## Unde stă live.tips și când să cumperi mai bine un SumUp

[live.tips](https://github.com/mekedron/live.tips) e un borcan de bacșiș pe bază de
QR. Un cod, care nu se schimbă niciodată, îndreptat direct către propriul link de
plată Stripe al artistului. Nu există un sold live.tips, nicio ciupeală și nicio
platformă pe traseu — comisionul e al lui Stripe, iar Stripe i-l percepe artistului
direct. E sub licență MIT, iar tableta de pe scenă arată fiecare bacșiș în clipa în
care aterizează. Am scris drumul banilor în
[cum se ocupă live.tips de bani](post:how-live-tips-handles-money) și de ce e
[un singur cod, nu unul pentru fiecare furnizor](post:one-qr-code-every-payment-method).

Pagina aceea acceptă Apple Pay și Google Pay. Deci live.tips *e* contactless din
partea fanului — atingerea care contează, cea de la final, fără niciun terminal de
cumpărat, de încărcat sau de scăpat în ploaie. Doar că nu e un terminal.

**Dacă ce vrei tu e să întinzi fizic ceva și un străin să-l atingă, cumpără-ți un
cititor de card.** Ia Tap to Pay de la SumUp dacă telefonul și țara ta îl suportă,
pentru că nu costă nimic; ia un Solo dacă preferi să nu-ți întinzi propriul telefon
către o mulțime. Oricum ar fi, la o atingere de 2 € în Europa va bate comisionul
nostru, și preferăm s-o spunem decât să ne prefacem că nu e așa.

Poți face și amândouă, și mulți muzicanți stradali chiar ar trebui: codul lipit pe
husă toată seara, prinzând trecătorii în timp ce cânți, și terminalul în mână pentru
cele zece secunde de după ultimul acord, când primul rând bagă mâna în buzunar. Nu
concurează. Prind oameni diferiți.

Ce nu e niciunul dintre ele: un suport din 2018 care ia 5%.

Comisioanele, prețurile hardware-ului și disponibilitatea pe țări așa cum au fost publicate de Apple, Stripe, SumUp, Zettle/PayPal și Square în iulie 2026, fără TVA. Prețul stickerelor NFC de la GoToTags. Condițiile Tiptap din 2018 așa cum au fost relatate de Brunel University și Finextra. Totul de aici se schimbă; verifică la furnizor înainte să dai bani.
{: .footnote }
