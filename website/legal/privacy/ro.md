---
title: Politica de confidențialitate
description: live.tips nu are cookie-uri, nu are analitică și nu are urmărire, și funcționează fără niciun cont. Dacă alegi să te autentifici, iată exact ce se stochează, unde, de către cine și pentru cât timp.
updated: 2026-07-15
updated_label: Ultima actualizare 15 iulie 2026
---

live.tips este un borcan de bacșiș open-source pentru artiști. Este administrat de **Nikita Rabykin**,
un dezvoltator individual, nu o companie. Dacă ceva de mai jos contează pentru tine, scrie la
**[contact@live.tips](mailto:contact@live.tips)** — la acea adresă răspunde un om.

Această politică este sinceră inclusiv în privința părților plictisitoare. Preferăm să spunem „îți
păstrăm numele atâta timp cât păstrezi trupa” decât să pretindem că nu păstrăm nimic și să greșim.

## Pe scurt

- **Contul este opțional.** Aplicația funcționează fără niciun cont, iar asta rămâne varianta
  implicită. Dacă vrei să ai trupele și istoricul tău pe un al doilea dispozitiv, te poți
  autentifica — și atunci o parte din ele se stochează pe un server, iar mai mult decât înainte.
  Care anume, scrie mai jos.
- **Fără cookie-uri.** Niciunul, nicăieri.
- **Fără analitică, fără urmărire, fără reclame, fără scripturi terțe** pe acest site.
- **Nu-ți atingem niciodată banii.** Bacșișurile ajung direct de la fan în contul propriu de
  Stripe, Revolut, MobilePay sau Monzo al artistului. Nu există niciodată vreun sold live.tips.
- **Fără cont, aplicația comunică doar cu Stripe** — nu cu vreun server live.tips. Dacă te
  autentifici, asta se schimbă: cheia ta Stripe se mută pe serverul nostru, iar Stripe ne raportează
  nouă bacșișurile tale, ca să le putem pune pe celelalte dispozitive ale tale. Acesta este prețul
  onest al autentificării și este descris în întregime mai jos.
- **Notificările push sunt noi, opționale și doar pentru conturile autentificate.** Nimic nu este
  trimis către un dispozitiv care nu le-a activat niciodată, iar unui dispozitiv fără cont nu i se
  trimite niciodată vreuna.
- Serverele pe care le rulăm sunt pe Firebase-ul Google. Ele există dacă un artist activează
  Revolut, MobilePay sau Monzo — sau dacă se autentifică.

## Acest site

Site-ul este static și găzduit pe **GitHub Pages**. În calitate de gazdă, GitHub primește adresa IP
și user-agentul de browser al oricui încarcă o pagină — este o simplă înregistrare de server web,
se întâmplă înainte să ruleze vreun cod al nostru și nu o putem opri.
GitHub le prelucrează conform propriei
[declarații de confidențialitate](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Noi nu citim acele jurnale, iar GitHub nu ni le arată.

Dincolo de asta, paginile pe care le citești nu încarcă **nimic de la nimeni altcineva**: fonturile,
pictogramele și imaginile sunt servite chiar de live.tips. Nu există Google Analytics, nici tag
manager, nici pixel, nici widget încorporat.

Site-ul stochează **două valori în `localStorage`-ul browserului tău**, ambele setate de tine, ambele
lizibile doar de acest site și niciuna trimisă vreodată undeva:

| Cheie | Ce reține |
| --- | --- |
| `lt-landing-theme` | dacă ai ales culori deschise, întunecate sau automate |
| `lt-langbar-dismissed` | că ai închis bannerul „disponibil și în limba ta” |

Ștergerea datelor din browser le elimină. Nu sunt cookie-uri, nu sunt partajate și nu identifică pe nimeni.

## Aplicația are două moduri, iar diferența dintre ele este toată povestea

Tot ce urmează depinde de o singură întrebare: **te-ai autentificat?**

### Modul unu — fără cont. Rămâne varianta implicită, rămâne neschimbat.

Aplicația rulează **pe dispozitivul artistului**, iar tot ce știe se află acolo:

- **Cheia restricționată Stripe** este păstrată în seiful de chei al dispozitivului (Keychain pe
  iOS/macOS, Keystore pe Android) și este trimisă exclusiv către `api.stripe.com`.
- **Istoricul bacșișurilor, istoricul sesiunilor, obiectivul, lista de cereri de melodii și setările
  aplicației** sunt stocate în memoria locală a dispozitivului. Aici intră și numele și mesajele pe
  care fanii le atașează bacșișurilor.
- Dezinstalarea aplicației șterge tot. Nu există copie de rezervă în cloud la noi, pentru că
  în acest mod la noi nu există niciun cloud.

**Noi nu primim nimic din toate acestea.** Aplicația este livrată fără SDK de analitică, fără raportare
a erorilor și fără cod publicitar — niciunul, nici măcar dezactivat. (Notificările push există, dar
sunt o funcție pentru conturi autentificate și sunt oprite până când le pornești — vezi *Modul doi*.
Unui dispozitiv fără cont nu i se trimite niciodată vreuna.)

Două precizări, ca afirmația „nu vorbește cu nimeni” să rămână exact adevărată:

- Aplicația preia **cursurile de schimb valutar** o dată pe zi de la API-uri publice de cursuri
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Sunt simple cereri pentru o listă
  publică de cursuri. Nu transportă nicio informație despre tine, despre artist sau despre vreun bacșiș
  — dar, ca orice cerere web, îți dezvăluie adresa IP acelor servicii.
- Dacă folosești **versiunea de browser** a aplicației, browserul tău o descarcă de pe gazda noastră
  statică (vezi *Acest site* mai sus).

### Modul doi — te-ai autentificat. Atunci o parte din date părăsesc dispozitivul, în mod intenționat.

Autentificarea este un act deliberat. Nimic nu te autentifică în locul tău și nimic din aplicație nu
încetează să funcționeze dacă nu o faci niciodată. Te autentifici pentru că vrei un al doilea
dispozitiv: telefonul din buzunar și tableta de pe scenă arătând aceeași seară, aceleași trupe,
același istoric.

Asta funcționează doar dacă le ține un server. **Așa că le ține, iar acesta este prețul onest al celui
de-al doilea dispozitiv.**

Serverul este **Firebase**, care înseamnă Google. Există trei feluri de a avea un cont:

- **Autentificare cu Apple** sau **Autentificare cu Google** — Firebase Auth primește tot ce îi predă
  furnizorul: un id de utilizator (uid) și, de obicei, o adresă de e-mail și un nume. (La Apple poți
  să îți ascunzi adresa de e-mail; Apple ne dă atunci o adresă de redirecționare în locul ei și ne
  predă numele tău doar chiar prima oară când te autentifici.)
- **Un cont de invitat** — un cont anonim, fără e-mail și fără nume. Se sincronizează și poate fi
  revocat, dar nu există nimic cu care să îl recuperezi dacă pierzi dispozitivul. Este un uid și
  nimic mai mult. Un cont de invitat nu poate folosi custodia Stripe de pe server și nici notificările
  push descrise mai jos, pentru că amândouă au nevoie de un cont pe care să ți-l putem înapoia.

Odată autentificat, contul primește propriul lui colț privat în baza de date **Cloud Firestore** a
Google, la `users/<your uid>/`. Regulile de securitate acordă acel colț acelui uid **și nimănui
altcuiva** — niciun alt cont nu îl poate citi, nici măcar ghicind adrese URL. Înăuntru:

| Ce | De ce se află acolo |
| --- | --- |
| **Trupele** tale — nume, setările borcanului de bacșiș și ale metodelor de plată, textul afișului, obiectivele și **lista ta de cereri de melodii** | ca o trupă să existe pe fiecare dispozitiv pe care te autentifici |
| **Setările aplicației**, inclusiv preferințele tale de notificare | ca un dispozitiv pe care îl adaugi să fie deja configurat |
| **Înregistrările sesiunilor și istoricul bacșișurilor** — inclusiv **numele și mesajele pe care fanii le atașează bacșișurilor** și orice **melodie cerută de un fan** | pentru că exact acel istoric ai cerut să îl vezi pe celălalt dispozitiv |
| **Sesiunea live** care se desfășoară chiar acum | ca un al doilea ecran să se poată alătura concertului din seara asta |
| **Dispozitivele** tale — numele pe care fiecare și-l dă („iPhone-ul lui Nikita”), platforma și modelul lui, limba interfeței lui, când a fost văzut prima și ultima oară și (dacă ai activat notificările) un **token de push** | ca Setări → Securitate să le poată lista, ca o notificare să ajungă la dispozitivul potrivit în limba potrivită și ca tu să poți revoca unul |
| Un mic **document de profil** — numele de cont pe care l-ai ales și furnizorul pe care l-ai folosit | ca selectorul de conturi să îl poată eticheta |
| Un **flux de clopoțel** — o listă plafonată cu bacșișurile și cererile de melodii recente care au sosit cât timp nu rula niciun concert | ca să poți recupera ce ai ratat |

Iar acum partea importantă, pe șleau: **fără cont, numele și mesajul unui fan nu părăsesc niciodată
dispozitivul artistului. Cu cont, ele se stochează pe serverele Google, sub uid-ul artistului, ca
parte din istoricul propriu sincronizat al acelui artist**, iar — după cum explică următoarele două
secțiuni — **acum serverul nostru este cel care le scrie acolo.** Niciun alt cont nu le poate citi,
noi nu ne uităm la ele și nu deducem nimic din ele — dar ele sunt acolo, și rămân acolo atâta timp cât
trăiește trupa, și e bine să știi asta înainte să te autentifici.

Deconectarea readuce dispozitivul în modul local. Nu șterge datele contului — vezi *Ștergerea
lucrurilor*, mai jos.

#### Cheia ta Stripe, când te autentifici, se mută pe serverul nostru

Aceasta este cea mai mare schimbare și cea care merită citită cel mai mult.

**Fără cont, cheia ta restricționată Stripe nu-ți părăsește niciodată dispozitivul.** Acesta este
Modul unu și rămâne neschimbat.

**Când te autentifici, ea chiar pleacă — la noi.** Cheia este criptată (o cheie AES-256 per-secret, la
rândul ei împachetată de Google Cloud KMS) și stocată pe server într-un loc pe care **nimeni nu-l poate
citi înapoi — niciun alt cont și nici măcar tu.** Este descuiată doar în interiorul Cloud Functions-urilor
noastre, folosită ca să vorbim cu Stripe în numele tău, și nu mai este predată niciodată vreunui
dispozitiv.

Pentru că acum cheia stă la noi, **Stripe raportează bacșișurile tale direct către serverul nostru**:
înregistrăm un webhook pe propriul tău cont Stripe, iar Stripe îi spune acelui webhook de fiecare dată
când se plătește un bacșiș. Funcția noastră scrie bacșișul în istoricul contului tău (vezi mai jos).
Aplicația ta nu mai interoghează Stripe pentru un cont autentificat; ajunge la Stripe doar printr-o
listă îngustă și fixă de operațiuni de pe serverul nostru (crearea linkului tău de bacșiș, generarea
unui link de cerere de melodie și recitirea propriilor tale bacșișuri pentru reconciliere).

Așadar, spus fără eufemisme: **pentru un cont autentificat, există acum un server live.tips pe traseul
dintre Stripe și istoricul tău.** Tot nu atingem niciodată banii — un bacșiș cu cardul este creat în
contul tău Stripe, se decontează în soldul tău Stripe și este plătit după calendarul tău Stripe, exact
ca înainte. Ceea ce s-a schimbat este traseul *datelor*, nu traseul *banilor*. Dacă nu te autentifici
niciodată, nimic din toate acestea nu se aplică, iar aplicația comunică în continuare direct cu
`api.stripe.com` și cu nimeni altcineva.

#### Adăugarea unui dispozitiv prin cod QR

Ca să adaugi un dispozitiv, afișezi un cod QR de pe un dispozitiv deja autentificat. Codul este
aleatoriu, **de unică folosință și expiră în două minute**, iar dispozitivul nou nu primește nimic
până când nu apeși *confirmă* pe cel vechi. Cât timp acel schimb este deschis, păstrăm codul, numele
pe care și l-a dat dispozitivul nou și platforma lui — iar înregistrarea se șterge când codul expiră.
Un cod QR fotografiat nu ajută la nimic fără apăsarea ta de confirmare.

## Cererile de melodii

O trupă poate activa **cererile de melodii**: fanii aleg atunci o melodie din lista artistului și,
opțional, plătesc ca să o urce în coadă. O cerere este doar un bacșiș care poartă în plus **ce melodie**
a fost cerută — așa că aceleași nume și mesaj pe care un fan le poate atașa unui bacșiș se aplică și
aici, iar ea este stocată și păstrată exact ca orice alt bacșiș (mai jos). Coada publică pe care o vede
un fan arată doar **totalurile pe melodie** — cât a strâns o melodie și pe ce loc se află — și nu poartă
**niciun nume de fan**. Fără cont, întreaga listă de cereri de melodii și istoricul ei trăiesc doar pe
dispozitiv.

## Notificările push

Când ești autentificat, aplicația îți poate trimite o **notificare push** — dar numai dacă o activezi,
per dispozitiv, și numai după ce sistemul de operare al dispozitivului tău acordă permisiunea. Există
pentru un singur lucru: un bacșiș sau o cerere de melodie care sosește **cât timp nu rulezi niciun
concert**, ca să afli de bacșișul pe care altfel l-ai fi ratat. Un bacșiș care sosește cât timp scena
ta este live nu trimite nimic — deja îl urmărești.

- Ca să livreze un push, **Firebase Cloud Messaging (FCM)** al Google are nevoie de un **token de push**
  pentru dispozitiv. Stocăm acel token, și limba interfeței dispozitivului, în înregistrarea proprie a
  dispozitivului din contul tău, iar el este șters în clipa în care oprești notificările, revoci
  dispozitivul sau te deconectezi. Tokenii morți sunt eliminați automat.
- Notificarea în sine spune ce a sosit — o sumă și numele unui fan sau titlul unei melodii, dacă a
  lăsat vreunul. Aceeași listă scurtă este păstrată în **fluxul de clopoțel** al contului tău, plafonat
  la cele mai recente o sută de intrări, ca să poți derula înapoi prin ce a venit cât timp ai fost plecat.
- Pe web, livrarea unui push necesită un mic **service worker** la rădăcina site-ului și SDK-ul de
  mesagerie Firebase, pe care browserul tău îl preia de la Google (`gstatic.com`) prima oară. Push-ul
  web este apoi transportat de propriul serviciu de push al browserului tău (pentru Chrome, cel al
  Google). Nimic din toate acestea nu se încarcă decât dacă ai activat notificările.
- **Un cont de invitat și un dispozitiv fără cont nu primesc niciun push**, pentru că un push are nevoie
  de un cont către care să putem livra și de un token pe care ai ales să-l dai.

## Unde stau fizic toate acestea

Firebase Auth, Cloud Firestore, Cloud Functions ale noastre și cheia Cloud KMS care împachetează
secretul tău Stripe rulează toate în **Uniunea Europeană** — baza de date în multiregiunea `eur3` a
Google, funcțiile și inelul de chei în `europe-west1`. Google acționează ca persoană împuternicită de
noi, conform
[termenilor de confidențialitate și securitate Firebase](https://firebase.google.com/support/privacy)
și propriei sale [politici de confidențialitate](https://policies.google.com/privacy). Ca orice
furnizor mare, Google poate implica infrastructură din afara UE pentru suport și securitate; asta este
guvernată de acei termeni, nu de noi. Notificările push, odată predate către Firebase Cloud Messaging
și către serviciul de push al browserului sau telefonului tău, călătoresc peste infrastructura acelor
companii ca să ajungă la dispozitivul tău.

## Stripe

Când un fan plătește cu cardul, se află pe pagina de checkout a **Stripe**, nu pe a noastră. Stripe
colectează și prelucrează datele lui de plată în calitate de operator independent, conform
[Politicii de confidențialitate Stripe](https://stripe.com/privacy). Noi nu vedem niciodată numere de
card.

Cum ajung bacșișurile la tine depinde de mod:

- **Fără cont**, aplicația artistului își citește propriile bacșișuri din Stripe folosind cheia
  restricționată a artistului — direct de pe dispozitiv către `api.stripe.com`. **Pe acel traseu nu
  există niciun server live.tips.**
- **Când ești autentificat**, cheia stă pe serverul nostru (criptată, ca mai sus), iar Stripe
  raportează fiecare bacșiș către webhookul nostru, care îl scrie în istoricul propriu din Firestore al
  acelui artist. **În acest mod există un server live.tips pe traseu** — pentru datele bacșișului,
  niciodată pentru bani. Numele și mesajul unui fan, dacă a lăsat vreunul, călătoresc cu bacșișul în
  istoricul propriu al acelui artist și se opresc acolo.

## Releul — doar dacă Revolut, MobilePay sau Monzo sunt activate

Configurațiile doar-Stripe nu ating niciodată acest lucru.

Revolut, MobilePay și Monzo nu oferă nicio modalitate prin care o aplicație să confirme că o plată a
avut loc, așa că acele bacșișuri sunt rutate printr-un mic releu open-source pe care îl rulăm pe
**Firebase** — Cloud Functions și Firestore în `europe-west1`, cu pagina de bacșiș a fanului servită
de la **`tip.live.tips/t/<id>`**. El nu atinge niciodată banii. Iată tot ce prelucrează.

### Ce stochează artistul

Crearea unei pagini de bacșiș stochează **numele afișat al artistului, mesajul lui public, moneda lui
și identificatorii de plată pe care a ales să îi publice** (linkul lui de plată Stripe, numele de
utilizator Revolut, Box ID-ul MobilePay, numele de utilizator Monzo) și, dacă cererile de melodii sunt
activate, **lista lui publică de melodii și prețurile pe fiecare melodie**. Toate sunt informații pe
care artistul le publică oricum, în mod deliberat, către fani.

- **Retenție: o pagină de bacșiș în spatele căreia nu stă niciun cont este ștearsă automat după 90 de
  zile de inactivitate.** O pagină de bacșiș care aparține unui cont autentificat trăiește atâta timp
  cât trăiește trupa căreia îi aparține.
- Artistul o poate șterge **imediat** din aplicație, oricând.
- Aici nu se colectează nicio adresă de e-mail, nicio parolă, niciun nume legal și niciun fel de date
  bancare.
- Secretul paginii este stocat **doar ca hash**. Nu ți-am putea spune secretul nici dacă ne-ai cere-o;
  putem doar să verificăm unul.

### Ce trimite un fan

Formularul de bacșiș cere o **sumă** și, opțional, un **nume** și un **mesaj** — iar, pentru o cerere
de melodie, ce melodie. Acesta este tot formularul. Fără e-mail, fără număr de telefon, fără cont.

Unde ajunge acel text scris de fan, și pentru cât timp, depinde de dacă artistul este autentificat:

- **Dacă în spatele paginii de bacșiș nu stă niciun cont**, bacșișul este scris într-o **coadă de
  livrare** — un singur document care există pentru a fi predat ecranului artistului. Când ecranul
  afișează bacșișul, **dispozitivul artistului șterge acel document.** Ștergerea *este* confirmarea de
  primire. Dacă ecranul artistului este offline — telefon blocat, fără semnal — bacșișul **așteaptă în
  acea coadă cel mult o oră**, ca să nu se piardă pur și simplu, și trece dincolo în clipa în care
  ecranul se reconectează. Dacă nu se reconectează nimeni, este **șters fără să fie văzut**, măturat
  după un orar. Pentru un artist fără cont, **acea coadă este singurul loc în care textul scris de un
  fan este vreodată stocat pe serverul nostru, iar o oră este limita ei absolută.**
- **Dacă pagina de bacșiș aparține unui cont autentificat**, nu există nicio coadă. Serverul nostru
  scrie bacșișul **direct în istoricul propriu al acelui artist** sub uid-ul lui — în sesiunea din
  seara asta dacă rulează un concert, sau în arhiva proprie a trupei dacă nu. Acolo rămâne **atâta timp
  cât trăiește trupa**; este istoricul propriu al artistului și tocmai pentru asta s-a autentificat.
  Este același istoric în care scrie și webhookul Stripe, de mai sus.
- Numele și mesajul tău sunt puse și în **nota de plată** care se deschide în Revolut, MobilePay sau
  Monzo — așa află artistul cine i-a lăsat bacșiș. Acele companii le prelucrează apoi conform propriilor
  politici de confidențialitate.
- Releul nu păstrează **niciun registru al bacșișurilor între artiști**. Nu îți poate arăta nici ție,
  nici nouă, nici altcuiva o listă cu cine cui i-a lăsat bacșiș între artiști.

### Adresele IP și protecția împotriva abuzurilor

Un formular deschis, în care poate posta oricine, are nevoie de ceva protecție împotriva boților, așa că:

- Adresa ta IP este trimisă către **Cloudflare Turnstile** — o verificare anti-bot care rulează pe
  pagina de bacșiș — pentru a verifica faptul că nu ești un bot. Turnstile este un produs Cloudflare și
  este folosit în locul unui CAPTCHA care te profilează. Turnstile și DNS-ul nostru sunt singurele
  lucruri pe care Cloudflare le mai face pentru noi; releul propriu-zis rulează acum pe Firebase. Vezi
  [Politica de confidențialitate Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Adresa ta IP este folosită și pentru a **limita rata** cererilor — trimiterea unui bacșiș, crearea
  unei pagini de bacșiș, folosirea unui cod de adăugare a unui dispozitiv. Ceea ce stocăm pentru asta
  este un **hash criptografic cu sare al IP-ului**, niciodată IP-ul în sine, timp de aproximativ **două
  ore**, apoi este șters. Sarea este un secret de server: fără ea, codul refuză să stocheze absolut
  nimic, în loc să păstreze un hash care ar putea fi inversat.
- **Jurnalele operaționale ale Google** înregistrează detaliile tehnice ale cererilor către releu —
  URL, timp, stare — pentru câteva zile. Codul nostru nu înregistrează în mod deliberat niciun nume,
  niciun mesaj, niciun secret și niciun antet. Google acționează ca persoană împuternicită de noi.

### Contoare

Releul numără **câte bacșișuri** a transmis o anumită pagină de bacșiș, ca să putem depista abuzurile și
să știm dacă lucrul acesta este folosit măcar. Este un număr. Nu conține date despre fani.

## Cine ce prelucrează

| Cine | Ce primește | De ce |
| --- | --- | --- |
| **Google (Firebase)** | Conturile, datele sincronizate ale unui artist autentificat, cheia Stripe criptată, releul, tokenii de push și livrarea lor, jurnalele de server | Contul opțional, releul opțional și notificările push |
| **Google Cloud KMS** | Cheia care împachetează secretul Stripe al unui artist autentificat (niciodată secretul în clar) | Menținerea cheii Stripe stocate ilizibilă în repaus |
| **Stripe** | Datele de plată ale fanului, în calitate de operator independent; și, pentru un artist autentificat, evenimentele de bacșiș trimise către webhookul nostru | Bacșișurile cu cardul |
| **Cloudflare** | IP-ul fanului, pentru verificarea Turnstile de pe pagina de bacșiș. Și DNS-ul nostru. | Ținerea boților departe de formularul de bacșiș |
| **GitHub** | IP-ul și user-agentul oricui încarcă acest site | Găzduirea site-ului |
| **Serviciul de push al browserului / telefonului tău** (de ex. cel al Google pentru Chrome) | Un token de push și conținutul notificării, dacă ai activat notificările | Livrarea notificărilor push |
| **Revolut / MobilePay / Monzo** | Orice face fanul în propria lor aplicație, inclusiv nota de plată | Acele metode de plată |

Nu vindem nimic nimănui, iar pe acea listă nu mai există nimeni altcineva.

## Temeiul legal, dacă ai nevoie de unul (GDPR)

- Menținerea unui cont pe care l-ai cerut, sincronizarea propriilor tale date pe propriile tale
  dispozitive, păstrarea cheii tale Stripe ca bacșișurile tale să ajungă în istoricul tău, rularea
  releului pentru un artist care l-a activat, livrarea bacșișului unui fan către ecranul căruia îi era
  destinat și trimiterea unui push pe care l-ai activat: **executarea unui serviciu pe care l-ai cerut**.
- Limitarea ratei, Turnstile, cotele bazate pe IP-uri hashuite și revocarea dispozitivelor: **interesul
  legitim** de a împiedica distrugerea de către boți și fraudă a unui serviciu gratuit și deschis, și de
  a păstra conturile artiștilor în siguranță.
- Jurnalele de server: **interesul legitim** de a opera și securiza serviciul.

## Ștergerea lucrurilor

Asta contează mai mult decât orice promisiune pe care am putea-o face în legătură cu ea, așa că iată
exact ce există astăzi — inclusiv ce nu există.

- **Fără cont**: dezinstalează aplicația. Asta e tot, s-a dus.
- **O trupă**: eliminarea unei trupe din aplicație șterge datele din cloud ale acelei trupe — setările,
  cheile, sesiunile, istoricul ei de bacșișuri — împreună cu copia de pe dispozitiv.
- **O pagină de bacșiș**: șterge-o sau regenereaz-o din aplicație și este ștearsă din releu pe loc,
  inclusiv orice bacșișuri în așteptare.
- **Notificările push**: oprește-le pe un dispozitiv și tokenul lui de push este șters. Fluxul de
  clopoțel se golește odată cu trupa sau cu contul.
- **Un dispozitiv**: Setări → Securitate îți listează dispozitivele. Poți revoca unul sau te poți
  deconecta peste tot în altă parte — ceea ce încheie imediat, nu cândva, sesiunea fiecărui alt
  dispozitiv.
- **Întregul tău cont, dintr-o singură apăsare: aplicația nu are încă acest buton.** Preferăm să
  recunoaștem asta decât să pretindem altceva. Până când există, scrie la
  **[contact@live.tips](mailto:contact@live.tips)** și vom șterge contul și tot ce se află sub el, de
  mână. Între timp poți deja să ștergi fiecare trupă, ceea ce elimină tot ce are substanță — inclusiv
  cheia Stripe stocată — și lasă în urmă un cont gol.

## Drepturile tale

Ne poți cere o copie a oricărei informații pe care o deținem despre tine, corectarea sau ștergerea ei, și
te poți plânge autorității naționale de protecție a datelor. Scrie la
**[contact@live.tips](mailto:contact@live.tips)**.

În practică, cea mai mare parte este deja în mâinile tale: un artist își poate șterge instantaneu din
aplicație o pagină de bacșiș sau o trupă, bacșișurile nelivrate ale fanilor se evaporă în decurs de o
oră, iar dacă nu te autentifici niciodată, nimic din toate acestea nu a fost vreodată altundeva decât
pe propriul tău dispozitiv.

## Copii

live.tips nu se adresează copiilor și nu prelucrăm cu bună știință datele lor.

## Modificări

Vom actualiza această pagină atunci când software-ul se schimbă. Pentru că întregul proiect este open
source, **fiecare versiune anterioară a acestei politici se află în istoricul git public** — poți vedea
exact ce s-a schimbat și când.

## Limbă

Această politică este publicată în fiecare limbă acceptată de site, pentru comoditate. Dacă o traducere
și versiunea în engleză nu concordă, **versiunea în engleză este cea care contează**.
