---
title: Politica de confidențialitate
description: live.tips nu are cookie-uri, nu are analitică și nu are urmărire, și funcționează fără niciun cont. Dacă alegi să te autentifici, iată exact ce se stochează, unde, de către cine și pentru cât timp.
updated: 2026-07-13
updated_label: Ultima actualizare 13 iulie 2026
---

live.tips este un borcan de bacșiș open-source pentru artiști. Este administrat de **Nikita Rabykin**,
un dezvoltator individual, nu o companie. Dacă ceva de mai jos contează pentru tine, scrie la
**[contact@live.tips](mailto:contact@live.tips)** — la acea adresă răspunde un om.

Această politică este sinceră inclusiv în privința părților plictisitoare. Preferăm să spunem „îți
păstrăm numele timp de cel mult o oră” decât să pretindem că nu păstrăm nimic și să greșim.

## Pe scurt

- **Contul este opțional.** Aplicația funcționează fără niciun cont, iar asta rămâne varianta
  implicită. Dacă vrei să ai trupele și istoricul tău pe un al doilea dispozitiv, te poți
  autentifica — și atunci o parte din ele se stochează pe un server. Care anume, scrie mai jos.
- **Fără cookie-uri.** Niciunul, nicăieri.
- **Fără analitică, fără urmărire, fără reclame, fără scripturi terțe** pe acest site.
- **Nu-ți atingem niciodată banii.** Bacșișurile ajung direct de la fan în contul propriu de
  Stripe, Revolut, MobilePay sau Monzo al artistului. Noi nu suntem pe acel traseu.
- **În configurația implicită, aplicația comunică doar cu Stripe** — nu cu vreun server live.tips.
- Singurul server pe care îl rulăm este un mic releu pe Firebase, adică pe infrastructura Google.
  El există doar dacă un artist activează Revolut, MobilePay sau Monzo — sau dacă se autentifică.

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
- **Istoricul bacșișurilor, istoricul sesiunilor, obiectivul și setările aplicației** sunt stocate în
  memoria locală a dispozitivului. Aici intră și numele și mesajele pe care fanii le atașează bacșișurilor.
- Dezinstalarea aplicației șterge tot. Nu există copie de rezervă în cloud la noi, pentru că
  în acest mod la noi nu există niciun cloud.

**Noi nu primim nimic din toate acestea.** Aplicația este livrată fără SDK de analitică, fără raportare
a erorilor, fără notificări push și fără cod publicitar — niciunul, nici măcar dezactivat.

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
  să îți ascunzi adresa de e-mail; Apple ne dă atunci o adresă de redirecționare în locul ei.)
- **Un cont de invitat** — un cont anonim, fără e-mail și fără nume. Se sincronizează și poate fi
  revocat, dar nu există nimic cu care să îl recuperezi dacă pierzi dispozitivul. Este un uid și
  nimic mai mult.

Odată autentificat, contul primește propriul lui colț privat în baza de date **Cloud Firestore** a
Google, la `users/<your uid>/`. Regulile de securitate acordă acel colț acelui uid **și nimănui
altcuiva** — niciun alt cont nu îl poate citi, nici măcar ghicind adrese URL. Înăuntru:

| Ce | De ce se află acolo |
| --- | --- |
| **Trupele** tale — nume, setările borcanului de bacșiș și ale metodelor de plată, textul afișului, obiectivele | ca o trupă să existe pe fiecare dispozitiv pe care te autentifici |
| **Cheia ta restricționată Stripe** și secretul paginii de bacșiș din releu | într-un document de secrete pe care doar uid-ul tău îl poate citi, și în cache în seiful de chei al fiecăruia dintre dispozitivele tale |
| **Setările aplicației** | ca un dispozitiv pe care îl adaugi să fie deja configurat |
| **Înregistrările sesiunilor și istoricul bacșișurilor** — inclusiv **numele și mesajele pe care fanii le atașează bacșișurilor** | pentru că exact acel istoric ai cerut să îl vezi pe celălalt dispozitiv |
| **Sesiunea live** care se desfășoară chiar acum | ca un al doilea ecran să se poată alătura concertului din seara asta |
| **Dispozitivele** tale — numele pe care fiecare și-l dă („iPhone-ul lui Nikita”), platforma și modelul lui, când a fost văzut prima și ultima oară | ca Setări → Securitate să le poată lista, iar tu să poți revoca unul |
| Un mic **document de profil** — numele de cont pe care l-ai ales și furnizorul pe care l-ai folosit | ca selectorul de conturi să îl poată eticheta |

Iar acum partea importantă, pe șleau: **fără cont, numele și mesajul unui fan nu părăsesc niciodată
dispozitivul artistului. Cu cont, ele se stochează pe serverele Google, sub uid-ul artistului, ca
parte din istoricul propriu sincronizat al acelui artist.** Niciun alt cont nu le poate citi, noi nu
ne uităm la ele și nu deducem nimic din ele — dar ele sunt acolo, și e bine să știi asta înainte să
te autentifici.

Deconectarea readuce dispozitivul în modul local. Nu șterge datele contului — vezi *Ștergerea
lucrurilor*, mai jos.

### Adăugarea unui dispozitiv prin cod QR

Ca să adaugi un dispozitiv, afișezi un cod QR de pe un dispozitiv deja autentificat. Codul este
aleatoriu, **de unică folosință și expiră în două minute**, iar dispozitivul nou nu primește nimic
până când nu apeși *confirmă* pe cel vechi. Cât timp acel schimb este deschis, păstrăm codul, numele
pe care și l-a dat dispozitivul nou și platforma lui — iar înregistrarea se șterge când codul expiră.
Un cod QR fotografiat nu ajută la nimic fără apăsarea ta de confirmare.

## Unde stau fizic toate acestea

Firebase Auth, Cloud Firestore și Cloud Functions ale noastre rulează în **Uniunea Europeană** — baza
de date în multiregiunea `eur3` a Google, funcțiile în `europe-west1`. Google acționează ca persoană
împuternicită de noi, conform
[termenilor de confidențialitate și securitate Firebase](https://firebase.google.com/support/privacy)
și propriei sale [politici de confidențialitate](https://policies.google.com/privacy). Ca orice
furnizor mare, Google poate implica infrastructură din afara UE pentru suport și securitate; asta este
guvernată de acei termeni, nu de noi.

## Stripe

Când un fan plătește cu cardul, se află pe pagina de checkout a **Stripe**, nu pe a noastră. Stripe
colectează și prelucrează datele lui de plată în calitate de operator independent, conform
[Politicii de confidențialitate Stripe](https://stripe.com/privacy). Noi nu vedem niciodată numere de
card și nu avem acces la contul Stripe al artistului.

Aplicația artistului își citește propriile bacșișuri din Stripe folosind cheia restricționată a
artistului — direct de pe dispozitiv către `api.stripe.com`. **Pe acel traseu nu există niciun server
live.tips și nici nu a existat vreodată.** Numele și mesajul unui fan, dacă a lăsat vreunul,
călătoresc de la Stripe la dispozitivul artistului și se opresc acolo — cu excepția cazului în care
artistul s-a autentificat, caz în care dispozitivul le salvează și în istoricul propriu din Firestore
al acelui artist, ca mai sus.

## Releul — doar dacă Revolut, MobilePay sau Monzo sunt activate

Configurațiile doar-Stripe nu ating niciodată acest lucru.

Revolut, MobilePay și Monzo nu oferă nicio modalitate prin care o aplicație să confirme că o plată a
avut loc, așa că acele bacșișuri sunt rutate printr-un mic releu open-source pe care îl rulăm pe
**Firebase** — Cloud Functions și Firestore în `europe-west1`, cu pagina de bacșiș a fanului servită
de la **`tip.live.tips/t/<id>`**. El nu atinge niciodată banii. Iată tot ce prelucrează.

### Ce stochează artistul

Crearea unei pagini de bacșiș stochează **numele afișat al artistului, mesajul lui public, moneda lui
și identificatorii de plată pe care a ales să îi publice** (linkul lui de plată Stripe, numele de
utilizator Revolut, Box ID-ul MobilePay, numele de utilizator Monzo). Toate sunt informații pe care
artistul le publică oricum, în mod deliberat, către fani.

- **Retenție: o pagină de bacșiș în spatele căreia nu stă niciun cont este ștearsă automat după 90 de
  zile de inactivitate.** O pagină de bacșiș care aparține unui cont autentificat trăiește atâta timp
  cât trăiește trupa căreia îi aparține.
- Artistul o poate șterge **imediat** din aplicație, oricând.
- Aici nu se colectează nicio adresă de e-mail, nicio parolă, niciun nume legal și niciun fel de date
  bancare.
- Secretul paginii este stocat **doar ca hash**. Nu ți-am putea spune secretul nici dacă ne-ai cere-o;
  putem doar să verificăm unul.

### Ce trimite un fan

Formularul de bacșiș cere o **sumă** și, opțional, un **nume** și un **mesaj**. Acesta este tot
formularul. Fără e-mail, fără număr de telefon, fără cont.

- Bacșișul este scris într-o **coadă de livrare** — un singur document care există pentru a fi predat
  ecranului artistului. Când ecranul afișează bacșișul, **dispozitivul artistului șterge acel
  document.** Ștergerea *este* confirmarea de primire; nu există niciun indicator „livrat”, pentru că
  nu mai rămâne nicio înregistrare pe care să o marchezi.
- Dacă ecranul artistului este offline — telefon blocat, fără semnal — bacșișul **așteaptă în acea
  coadă cel mult o oră**, ca să nu se piardă pur și simplu, și trece dincolo în clipa în care ecranul
  se reconectează. Dacă nu se reconectează nimeni, este **șters fără să fie văzut**, măturat după un
  orar, indiferent dacă s-a mai întors sau nu cineva după el.
- **Acea coadă este singurul loc în care textul scris de un fan este vreodată stocat pe serverul
  nostru, iar o oră este limita ei absolută.** Dacă artistul este autentificat, dispozitivul lui
  păstrează apoi bacșișul în istoricul *lui* din Firestore — pentru că acela este istoricul lui, și
  tocmai pentru asta s-a autentificat.
- Numele și mesajul tău sunt puse și în **nota de plată** care se deschide în Revolut, MobilePay sau
  Monzo — așa află artistul cine i-a lăsat bacșiș. Acele companii le prelucrează apoi conform propriilor
  politici de confidențialitate.
- Releul nu păstrează **niciun istoric al bacșișurilor**. Nu îți poate arăta nici ție, nici nouă, nici
  altcuiva o listă cu cine cui i-a lăsat bacșiș.

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
| **Google (Firebase)** | Conturile, datele sincronizate ale unui artist autentificat, releul, jurnalele de server | Contul opțional și releul opțional |
| **Stripe** | Datele de plată ale fanului, în calitate de operator independent | Bacșișurile cu cardul |
| **Cloudflare** | IP-ul fanului, pentru verificarea Turnstile de pe pagina de bacșiș. Și DNS-ul nostru. | Ținerea boților departe de formularul de bacșiș |
| **GitHub** | IP-ul și user-agentul oricui încarcă acest site | Găzduirea site-ului |
| **Revolut / MobilePay / Monzo** | Orice face fanul în propria lor aplicație, inclusiv nota de plată | Acele metode de plată |

Nu vindem nimic nimănui, iar pe acea listă nu mai există nimeni altcineva.

## Temeiul legal, dacă ai nevoie de unul (GDPR)

- Menținerea unui cont pe care l-ai cerut, sincronizarea propriilor tale date pe propriile tale
  dispozitive, rularea releului pentru un artist care l-a activat și livrarea bacșișului unui fan către
  ecranul căruia îi era destinat: **executarea unui serviciu pe care l-ai cerut**.
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
- **Un dispozitiv**: Setări → Securitate îți listează dispozitivele. Poți revoca unul sau te poți
  deconecta peste tot în altă parte — ceea ce încheie imediat, nu cândva, sesiunea fiecărui alt
  dispozitiv.
- **Întregul tău cont, dintr-o singură apăsare: aplicația nu are încă acest buton.** Preferăm să
  recunoaștem asta decât să pretindem altceva. Până când există, scrie la
  **[contact@live.tips](mailto:contact@live.tips)** și vom șterge contul și tot ce se află sub el, de
  mână. Între timp poți deja să ștergi fiecare trupă, ceea ce elimină tot ce are substanță și lasă în
  urmă un cont gol.

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
