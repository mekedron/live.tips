---
title: Politica de confidențialitate
description: live.tips nu are conturi, nu are cookie-uri, nu are analitică și nu are urmărire. Iată lista scurtă a ceea ce se prelucrează totuși, de către cine și pentru cât timp.
updated: 2026-07-13
updated_label: Ultima actualizare 13 iulie 2026
---

live.tips este un borcan de bacșiș open-source pentru artiști. Este administrat de **Nikita Rabykin**,
un dezvoltator individual, nu o companie. Dacă ceva de mai jos contează pentru tine, scrie la
**[contact@live.tips](mailto:contact@live.tips)** — la acea adresă răspunde un om.

Această politică este sinceră inclusiv în privința părților plictisitoare. Preferăm să spunem „îți
păstrăm numele timp de cel mult o oră” decât să pretindem că nu păstrăm nimic și să greșim.

## Pe scurt

- **Fără conturi.** Nu ai la ce să te înregistrezi.
- **Fără cookie-uri.** Niciunul, nicăieri.
- **Fără analitică, fără urmărire, fără reclame, fără scripturi terțe** pe acest site.
- **Nu-ți atingem niciodată banii.** Bacșișurile ajung direct de la fan în contul propriu de
  Stripe, Revolut, MobilePay sau Monzo al artistului. Noi nu suntem pe acel traseu.
- **În configurația implicită, aplicația comunică doar cu Stripe** — nu cu vreun server live.tips.
- Singurul server pe care îl rulăm este un mic releu, iar el există doar dacă un artist
  activează Revolut, MobilePay sau Monzo.

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

## Aplicația

Aplicația live.tips rulează **pe dispozitivul artistului**. Tot ce știe se află acolo:

- **Cheia restricționată Stripe** este păstrată în seiful de chei al dispozitivului (Keychain pe
  iOS/macOS, Keystore pe Android) și este trimisă exclusiv către `api.stripe.com`.
- **Istoricul bacșișurilor, istoricul sesiunilor, obiectivul și setările aplicației** sunt stocate în
  memoria locală a dispozitivului. Aici intră și numele și mesajele pe care fanii le atașează bacșișurilor.
- Dezinstalarea aplicației șterge tot. Nu există copie de rezervă în cloud la noi, pentru că
  la noi nu există niciun cloud.

**Noi nu primim nimic din toate acestea.** Aplicația este livrată fără SDK de analitică, fără raportare
a erorilor, fără notificări push și fără cod publicitar — niciunul, nici măcar dezactivat.

Două precizări, ca afirmația „nu vorbește cu nimeni” să rămână exact adevărată:

- Aplicația preia **cursurile de schimb valutar** o dată pe zi de la API-uri publice de cursuri
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Sunt simple cereri pentru o listă
  publică de cursuri. Nu transportă nicio informație despre tine, despre artist sau despre vreun bacșiș
  — dar, ca orice cerere web, îți dezvăluie adresa IP acelor servicii.
- Dacă folosești **versiunea de browser** a aplicației, browserul tău o descarcă de pe gazda noastră
  statică (vezi *Acest site* mai sus).

## Stripe

Când un fan plătește cu cardul, se află pe pagina de checkout a **Stripe**, nu pe a noastră. Stripe
colectează și prelucrează datele lui de plată în calitate de operator independent, conform
[Politicii de confidențialitate Stripe](https://stripe.com/privacy). Noi nu vedem niciodată numere de
card și nu avem acces la contul Stripe al artistului.

Aplicația artistului își citește propriile bacșișuri din Stripe folosind cheia restricționată a
artistului. Numele și mesajul unui fan, dacă a lăsat vreunul, călătoresc de la Stripe la dispozitivul
artistului și se opresc acolo.

## Releul — doar dacă Revolut, MobilePay sau Monzo sunt activate

Configurațiile doar-Stripe nu ating niciodată acest lucru și pot să nu citească mai departe.

Revolut, MobilePay și Monzo nu oferă nicio modalitate prin care o aplicație să confirme că o plată a
avut loc, așa că acele bacșișuri sunt rutate printr-un mic releu open-source pe care îl rulăm pe
**Cloudflare**, la `api.live.tips`. El nu atinge niciodată banii. Iată tot ce prelucrează.

### Ce stochează artistul

Crearea unei pagini de bacșiș stochează **numele afișat al artistului, mesajul lui public, moneda lui
și identificatorii de plată pe care a ales să îi publice** (linkul lui de plată Stripe, numele de
utilizator Revolut, Box ID-ul MobilePay, numele de utilizator Monzo). Toate sunt informații pe care
artistul le publică oricum, în mod deliberat, către fani.

- **Retenție: șterse automat după 90 de zile de inactivitate.**
- Artistul le poate șterge **imediat** din aplicație, oricând.
- Nu se colectează niciodată adresă de e-mail, parolă, nume legal sau date bancare.

### Ce trimite un fan

Formularul de bacșiș cere o **sumă** și, opțional, un **nume** și un **mesaj**. Acesta este tot
formularul. Fără e-mail, fără număr de telefon, fără cont.

- Dacă ecranul artistului este **online**, bacșișul îi este transmis direct și **nu este scris niciodată
  pe disc**.
- Dacă ecranul artistului este **offline** — telefon blocat, fără semnal — bacșișul este **păstrat în
  memorie timp de cel mult o oră**, ca să nu se piardă pur și simplu, apoi este predat în clipa în care
  ecranul se reconectează. Dacă nu se reconectează nimeni, este **șters fără să fie văzut**. Acesta este
  singurul text scris de un fan pe care releul îl stochează vreodată, iar o oră este limita lui absolută.
- Numele și mesajul tău sunt puse și în **nota de plată** care se deschide în Revolut, MobilePay sau
  Monzo — așa află artistul cine i-a lăsat bacșiș. Acele companii le prelucrează apoi conform propriilor
  politici de confidențialitate.
- Releul nu păstrează **niciun istoric al bacșișurilor**. Nu îți poate arăta nici ție, nici nouă, nici
  altcuiva o listă cu cine cui i-a lăsat bacșiș.

### Adresele IP și protecția împotriva abuzurilor

Un formular deschis, în care poate posta oricine, are nevoie de ceva protecție împotriva boților, așa că:

- Adresa ta IP este folosită pentru a **limita rata** cererilor și este trimisă către **Cloudflare
  Turnstile** (o verificare anti-bot care rulează pe pagina de bacșiș) pentru a verifica faptul că nu
  ești un bot. Turnstile este un produs Cloudflare și este folosit în locul unui CAPTCHA care te
  profilează.
- Pentru a împiedica pe cineva să creeze mii de pagini de bacșiș, un **hash criptografic al IP-ului**
  celui care creează una este păstrat aproximativ **două ore**, apoi este eliminat.
- **Jurnalele operaționale ale Cloudflare** înregistrează detaliile tehnice ale cererilor către releu —
  URL, timp, stare — pentru câteva zile. Ele nu conțin nume sau mesaje de la fani. Cloudflare acționează
  ca persoană împuternicită de noi; vezi
  [Politica de confidențialitate Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Contoare

Releul numără **câte bacșișuri** a transmis o anumită pagină de bacșiș, ca să putem depista abuzurile și
să știm dacă lucrul acesta este folosit măcar. Este un număr. Nu conține date despre fani.

## Temeiul legal, dacă ai nevoie de unul (GDPR)

- Rularea releului pentru un artist care l-a activat și livrarea bacșișului unui fan către ecranul căruia
  îi era destinat: **executarea unui serviciu pe care l-ai cerut**.
- Limitarea ratei, Turnstile și cotele bazate pe IP-uri hashuite: **interesul legitim** de a împiedica
  distrugerea de către boți și fraudă a unui serviciu gratuit și deschis.
- Jurnalele de server: **interesul legitim** de a opera și securiza serviciul.

## Drepturile tale

Ne poți cere o copie a oricărei informații pe care o deținem despre tine, corectarea sau ștergerea ei, și
te poți plânge autorității naționale de protecție a datelor. Scrie la
**[contact@live.tips](mailto:contact@live.tips)**.

În practică, cea mai mare parte este deja în mâinile tale: artiștii își pot șterge instantaneu pagina de
bacșiș din aplicație, bacșișurile fanilor se evaporă în decurs de o oră, iar tot restul se află pe
propriul tău dispozitiv.

## Copii

live.tips nu se adresează copiilor și nu prelucrăm cu bună știință datele lor.

## Modificări

Vom actualiza această pagină atunci când software-ul se schimbă. Pentru că întregul proiect este open
source, **fiecare versiune anterioară a acestei politici se află în istoricul git public** — poți vedea
exact ce s-a schimbat și când.

## Limbă

Această politică este publicată în fiecare limbă acceptată de site, pentru comoditate. Dacă o traducere
și versiunea în engleză nu concordă, **versiunea în engleză este cea care contează**.
