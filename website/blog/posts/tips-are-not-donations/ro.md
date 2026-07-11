---
title: Bacșișul nu e donație — iar Stripe le tratează ca pe două afaceri diferite
description: Un muzicant stradal care cere un „buton de donație" descrie o afacere pe care Stripe o interzice în cea mai mare parte a Europei. Bacșișul plătește un serviciu pe care l-ai prestat deja; donația e strângere de fonduri în scop caritabil. Diferența decide în ce categorie ajunge contul tău — și un singur parametru de API o poate alege greșit în locul tău.
slug: bacsisul-nu-e-donatie
---

Fiecare unealtă de pe internet vrea să-i spui donație. Butoanele zic *Donate*.
Articolele de blog zic *buton de donație pentru muzicieni*. Directoarele de plugin-uri
zic *acceptă donații*. Dacă ești muzician și cauți o cale prin care să te plătească
oamenii care n-au numerar la ei, cuvântul te urmărește peste tot.

Apoi îți deschizi un cont Stripe, iar Stripe te întreabă cu ce se ocupă afacerea ta.
Și în clipa aia cuvântul încetează să mai fie text de marketing și devine o
**categorie de afacere** — una pe care, în cea mai mare parte a Europei, Stripe n-o
permite.

Nu e pedanterie și nu e o distincție de avocat. E singura întrebare cu cele mai mari
șanse să trimită contul de plăți al unui muzicant stradal perfect obișnuit la
verificare, la amânare sau la refuz. Aproape nimeni nu le-a scris-o pe șleau
artiștilor, așa că iat-o.

## Două cuvinte, două afaceri

Stripe trasează linia el însuși, în câte o propoziție. Din
[Cerințe pentru acceptarea bacșișurilor sau a donațiilor](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> un bacșiș trebuie dat pentru un bun sau un serviciu care a fost prestat (de ex.,
> conținut)

> o donație trebuie legată de un scop caritabil anume, pe care te angajezi să-l duci
> la capăt

Paginile Stripe sunt în engleză; formularea originală e în spatele linkurilor.

Citește-le de două ori, pentru că tot restul acestui articol decurge din ele.

Un **bacșiș** se uită înapoi, la ceva care s-a întâmplat deja. Serviciul a fost
prestat, fanului i-a plăcut, fanul a plătit în plus. Banii sunt necondiționați și nu
mai datorezi nimic. Ăsta e rândul de bacșiș de pe nota de plată, moneda din pălărie,
bancnota strecurată în palmă după ultima piesă.

O **donație** se uită înainte, la ceva ce ai promis că vei face. Există o cauză.
Există un scop pe care i l-ai descris celui care dă. Și — Stripe e explicit aici —
banii trebuie să ajungă efectiv la acel scop. Îi ții în custodie pentru un lucru
despre care ai spus că-l vei duce la capăt.

Astea nu-s două nuanțe ale aceluiași gest. Sunt două relații diferite, cu două seturi
diferite de obligații, iar Stripe le subscrie ca pe două afaceri diferite.

## Un muzicant stradal e limpede, fără echivoc, de partea bacșișului

Ai stat două ore într-o piață și ai cântat. Patruzeci de oameni s-au oprit. Unul
dintre ei îți scanează codul și-ți trimite cinci euro.

**Ăsta e un bacșiș.** Spectacolul e serviciul. A fost prestat — l-au văzut
întâmplându-se. Nu e nicio cauză, niciun beneficiar, niciun scop pe care te-ai
angajat să-l duci la capăt, și nimeni nu ți-a încredințat bani pentru un proiect.
Ești un artist interpret plătit pentru o interpretare, ceea ce e unul dintre cele mai
vechi și mai puțin controversate aranjamente comerciale care există.

Confuzia vine din faptul că bacșișul unui muzicant stradal e *voluntar*, iar noi am
fost dresați să credem că banii dați de bunăvoie sunt bani caritabili. Nu sunt. Și
bacșișul e voluntar. Nu voluntariatul face din ceva o donație — ci un **scop
caritabil**.

Așa că atunci când pancarta ta zice „donațiile sunt binevenite", nu ești modest sau
politicos. Descrii, în vocabularul procesatorului de plăți, o afacere în care nu
ești.

## Cât te costă de fapt cuvântul

Aici abstracția se transformă în bani.

Stripe publică o
[listă a afacerilor restricționate](https://stripe.com/legal/restricted-businesses) —
lucrurile pe care n-ai voie să le faci cu un cont Stripe, sau pe care le poți face
doar în anumite țări. Sub titlul **Crowdfunding și strângere de fonduri** stă acest
rând, textual:

> Organizații care strâng fonduri în scop caritabil (Notă: Acceptat în Australia,
> Canada, Regatul Unit și Statele Unite. Interzis în toate celelalte țări.)

Citește paranteza încet. Strângerea de fonduri în scop caritabil e o **afacere
acceptată în patru țări** — Australia, Canada, Regatul Unit, Statele Unite — și
**interzisă peste tot în rest.**

Peste tot în rest înseamnă Germania, Franța, Spania, Italia, Olanda, Polonia,
Finlanda și fiecare altă țară în care un muzicant stradal ar putea sta în mod
rezonabil. Înseamnă și **România**, și **Moldova**: strângerea de fonduri în scop
caritabil prin Stripe intră aici la „toate celelalte țări" și nu e acceptată. Cei mai
mulți artiști de stradă din lume trăiesc în „toate celelalte țări".

Aceeași pagină listează ca restricționată și *„strângerea de fonduri efectuată de
organizații non-profit, organizații caritabile, organizații politice și afaceri care
oferă o recompensă în schimbul unei donații"*, iar pagina Stripe despre bacșișuri și
donații mai adaugă un set de reguli pe țări deasupra: în Japonia persoanele fizice
nu pot primi deloc donații; în Singapore doar organizațiile caritabile sau religioase
înregistrate la stat pot; în India, Hong Kong și Thailanda donațiile nu sunt
acceptate.

Așa că un muzician din Berlin care scrie „donații pentru muzica mea" în formularul de
înscriere Stripe tocmai a descris o afacere pe care Stripe o interzice în Germania.
Nu pentru că muzica de stradă ar fi interzisă — muzica de stradă e perfect în regulă
— ci pentru că vorbele pe care le-a ales aparțin unei categorii care e.

## Și acum calibrarea, pentru că asta nu e o poveste de groază

**Muzicanții stradali nu sunt o afacere restricționată.** Bacșișul nu e o afacere
restricționată. Spectacolul live nu e pe listă, nu te va pune pe listă și e cam cel
mai obișnuit lucru pe care-l poți face cu un cont de plăți. Dacă te descrii exact,
nimic din toate astea nu te atinge, iar configurarea e plictisitoare — exact cum ar
trebui să fie.

Riscul aici nu e Stripe. Riscul e **auto-clasificarea greșită** — să intri în
încăpere și să te prezinți drept strângător de fonduri caritabile când ești
chitarist. Stripe n-are cum să știe că tu ai vrut să spui „dați-mi bacșiș, vă rog".
Are doar formularul pe care l-ai completat, descrierea afacerii pe care ai scris-o și
cuvintele de pe pagina spre care indică codul tău QR.

Nimeni de la Stripe nu vânează muzicanți stradali. Pur și simplu citesc ce le-ai spus
tu.

## Capcana e adâncă de un singur parametru

Aici e partea pe care aproape nimeni n-o scrie, și e cel mai util lucru din tot
articolul.

Payment Links de la Stripe au un parametru numit `submit_type`.
[Referința de API](https://docs.stripe.com/api/payment-link/object) îl descrie ca pe
ceva aproape cosmetic:

> Indică tipul tranzacției efectuate, ceea ce personalizează textul relevant de pe
> pagină, cum ar fi butonul de trimitere.

*Personalizează textul relevant.* Ai conchide, pe bună dreptate, că asta schimbă
eticheta unui buton și că un borcan de bacșiș ar trebui evident să zică *Donate*
(„donează") mai degrabă decât *Buy* („cumpără"), pentru că *Buy* e un cuvânt ciudat
de tipărit sub pălăria unui muzicant stradal.

Apoi citești ce fac de fapt valorile în parte:

> `donate` — Recomandat când accepți donații. Butonul de trimitere include eticheta
> 'Donate', iar URL-urile folosesc hostname-ul `donate.stripe.com`

> `pay` — Butonul de trimitere include eticheta 'Buy', iar URL-urile folosesc
> hostname-ul `buy.stripe.com`

**Nu e o etichetă. E un hostname.** Setează `submit_type=donate` și linkul pe care
ți-l dă Stripe — cel pe care-l transformi în cod QR, îl tipărești și-l lipești pe
tocul chitarei — locuiește la `donate.stripe.com`. Fiecare fan care-l scanează vede o
pagină de donații. Fiecare plată din panoul tău a venit printr-un flux de donații.
Codul QR de pe tocul tău îi spune Stripe, îi spune publicului tău și, în cele din
urmă, îți spune și ție că strângi donații.

N-ai scris cuvântul „donație" nicăieri. Un singur parametru de API l-a scris în locul
tău și l-a tipărit pe o plăcuță de plastic într-o piață publică.

E o capcană ușor de călcat, și nu e vina cititorului când o calcă: parametrul e
documentat ca o schimbare de text, *Donate* e clar cuvântul mai frumos de tipărit sub
pălăria unui muzicant stradal, iar consecința — o clasificare de afacere — e cu două
propoziții mai jos decât citește lumea de obicei.

live.tips trimite `submit_type=pay`. Linkul fiecărui artist e un link
`buy.stripe.com`, iar codul poartă un comentariu care spune de ce, pentru că e genul
de lucru pe care un contribuitor viitor l-ar „îmbunătăți" altfel.

## Ce ar trebui de fapt să facă un muzician

Nimic din toate astea nu cere un avocat. Cere cinci minute și niște vorbe simple.

- **Descrie afacerea reală** în înscrierea la Stripe. „Spectacole de muzică live."
  „Artist stradal." „Muzician — bacșișuri de la public la spectacole live." Spune că
  ai spectacole și că plățile sunt bacșișuri pentru acele spectacole.
- **Alege o categorie care se potrivește.** Divertisment live, arte interpretative,
  muzician. Nu caritate, nu non-profit, nu strângere de fonduri.
- **Folosește `submit_type=pay`** dacă îți construiești singur Payment Link-ul. Dacă
  ți l-a construit o unealtă, uită-te la URL-ul pe care l-a produs:
  `buy.stripe.com` e un borcan de bacșiș, `donate.stripe.com` e o pagină de donații.
  E o verificare de două secunde, și-ți spune drept ce te crede unealta ta.
- **Nu-i spune donație** — nici pe pancartă, nici pe site-ul tău, nici în descrierea
  afacerii de la Stripe. „Bacșișuri", „borcan de bacșiș", „susține trupa", „fă-ne
  cinste cu o bere" descriu toate ce se întâmplă cu adevărat. „Donează" descrie
  altceva.
- **Ține separat un eveniment caritabil adevărat.** Dacă dai un concert caritabil și
  banii merg către o cauză, aia chiar *e* strângere de fonduri în scop caritabil, iar
  regulile de mai sus sunt acum despre tine — inclusiv lista de țări. Fă-o pe contul
  potrivit, în țara potrivită, după ce ai citit termenii Stripe, și niciodată prin
  borcanul de bacșiș pe care-l folosești în serile obișnuite.

Ultima merită subliniată, pentru că e jumătatea cinstită a argumentului. Nu spunem că
donațiile sunt rele sau că muzicienii n-au voie să strângă bani pentru o cauză.
Spunem că e o **activitate diferită**, cu reguli diferite, și că a o trece pe tăcute
prin același cod QR e felul în care le pui pe amândouă în pericol.

Mai merită știut un rând de pe pagina Stripe despre bacșișuri și donații, fiindcă
exclude un al treilea lucru pe care lumea îl confundă cu ambele: Stripe nu face
*„procesare de plăți pentru transmiterea de bani personală sau de la persoană la
persoană (de ex., trimiterea de bani între prieteni)"*. Un bacșiș nu e nici cadou
între prieteni. Dacă vrei șina aia — un fan care pur și simplu îți trimite bani, de
la om la om — pentru asta există Revolut sau MobilePay, și de-asta ele trăiesc
[complet în afara Stripe](post:one-qr-code-every-payment-method) în aplicația
noastră.

## Ce nu e articolul ăsta

Nu e consultanță juridică. Nu e consultanță fiscală — felul în care se impozitează
bacșișurile variază enorm de la țară la țară, uneori de la oraș la oraș, și e complet
în afara subiectului aici; întreabă pe cineva calificat acolo unde locuiești.

Și nu e o promisiune despre contul tău. **Dacă Stripe te aprobă sau nu e decizia
Stripe și numai a lui.** live.tips n-are nicio relație cu Stripe, nicio putere de a
influența o verificare și niciun fel de a contesta una în numele tău. Ce poate face
software-ul nostru e să nu-ți pună vorbe în gură. Ce scrii pe formular rămâne al tău
de scris.

Și politicile se schimbă. Rândurile citate aici erau pe paginile Stripe în iulie
2026, iar linkurile sunt chiar acolo; du-te și citește-le singur în loc să crezi un
articol de blog, inclusiv ăsta.

## Varianta scurtă

Ți-ai cântat setul. L-au ascultat. Te-au plătit pentru el.

Ăsta e un bacșiș. Spune-o ca atare — pe pancartă, în formular, în URL — și rezultatul
plictisitor pe care ți-l dorești e chiar cel pe care-l primești. Noi construim
borcanul de bacșiș exact în jurul acestei afirmații, până jos, la
[spre ce hostname Stripe indică codul tău QR](post:build-a-tip-jar-on-your-own-stripe),
iar dacă vrei imaginea mai largă a locului unde ajung banii cu adevărat, e
[aici](post:how-live-tips-handles-money).
