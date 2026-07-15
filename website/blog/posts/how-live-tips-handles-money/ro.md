---
title: Cum se ocupă live.tips de bani (nu se ocupă)
description: Nu există niciun sold live.tips, niciun calendar de plăți, niciun comision. Iată arhitectura care face ca aceste trei afirmații să fie plictisitoare în loc de curajoase.
slug: cum-se-ocupa-live-tips-de-bani
---

Orice borcan de bacșiș poate scrie „0% comision" pe pagina lui de prezentare.
Întrebarea interesantă e ce ar trebui să facă software-ul ca să *înceapă* să-și
ia o parte și cât din asta ai putea vedea.

În cazul live.tips, răspunsul e: ar trebui reconstruit. Asta nu e o promisiune
despre intențiile noastre, e o descriere a locului unde ajung banii.

## Banii nu trec niciodată prin noi

Când un fan atinge o sumă pe card, plata este creată în contul **tău** Stripe, se
decontează în soldul **tău** Stripe și este plătită după calendarul **tău**
Stripe. Singurul comision este comisionul standard de procesare al Stripe însuși,
pe care Stripe ți-l percepe direct, exact cum ar face-o dacă ai fi integrat tu
însuți Stripe.

De partea noastră nu există niciun registru, pentru că nu e nimic de înregistrat.
Nu am putea lua un procent fără să construim mai întâi lucrul care ține banii —
iar un asemenea lucru nu există.

Asta e valabil fie că te autentifici, fie că nu. Ceea ce schimbă autentificarea
este traseul *datelor*, nu traseul banilor, iar următoarele două secțiuni sunt
oneste în privința felului exact în care.

## Cheile tale, și unde stau ele

Configurarea cere o cheie API Stripe *restricționată*, nu o cheie secretă reală —
pe acelea le refuzăm din capul locului. Restricționată înseamnă că cheia poate
face două lucruri: să creeze linkul de bacșiș plătește-cât-vrei și să urmărească
bacșișurile care sosesc. Nu poate să-ți citească soldul, să declanșeze plăți, să
emită rambursări sau să atingă datele clienților. Dacă s-ar scurge mâine, raza de
explozie e un link de bacșiș.

**Fără cont, acea cheie nu-ți părăsește niciodată dispozitivul.** Stă în
portcheiul propriului tău dispozitiv și este trimisă doar către `api.stripe.com`,
prin TLS. Niciun server live.tips nu apare deloc în tablou.

**Când te autentifici, cheia se mută la noi** — pentru că o cheie care există
doar pe un singur telefon nu poate deservi și tableta de pe scenă. O criptăm (o
cheie AES-256 per-secret, la rândul ei împachetată de Google Cloud KMS) și o
stocăm undeva unde nimic nu o poate citi înapoi: niciun alt cont, nici noi
aruncând o privire într-o bază de date, nici măcar tu. Este descuiată doar în
interiorul funcțiilor noastre, folosită ca să vorbim cu Stripe în numele tău, și
nu mai este predată niciodată vreunui dispozitiv. Spunem asta pe șleau:
autentificarea pune un server live.tips pe traseul dintre Stripe și istoricul tău
de bacșișuri. Niciodată banii — datele.

## Serverele, și ce nu pot face

Sunt două, și amândouă sunt minimale.

**Releul** există pentru că Revolut și MobilePay nu pot fi controlate dintr-un
browser așa cum poate fi Stripe. Activarea lor pornește o mână de funcții Firebase
care servesc pagina ta de bacșiș la `tip.live.tips`. Stochează profilul public al
paginii tale de bacșiș — numele afișat și identificatorii de plată pe care ai ales
să-i publici — și, pentru o pagină în spatele căreia nu stă niciun cont, nu
păstrează niciun istoric al bacșișurilor: un bacșiș așteaptă doar până când îl
afișează dispozitivul tău de pe scenă, iar tot ce n-a mai venit nimeni să ridice
este măturat în decurs de o oră. Nu vede niciun ban și se autoșterge după 90 de
zile de inactivitate. Dacă folosești doar Stripe și nu te autentifici niciodată,
releul nu este contactat niciodată.

**Webhookul** există doar odată ce te autentifici. Pentru că acum cheia ta stă la
noi, Stripe raportează fiecare bacșiș către o mică funcție de-a noastră, care îl
scrie în propriul tău istoric, ca celelalte dispozitive ale tale să îl poată
afișa. Este o copie a unui eveniment, nu o copie a banilor. Nu poate muta niciun
bănuț și nu poate scrie vreodată decât în singurul cont căruia îi aparține.

Niciunul dintre servere nu poate lua o parte, pentru că niciunul nu se află nici
măcar în apropierea banilor. Cel mult, oricare dintre ele poate să cedeze — iar o
configurație doar-Stripe, fără cont, nu depinde de niciunul.

## Contul pe care nu ești obligat să ți-l faci

Aplicația tot pornește într-un profil care trăiește doar pe dispozitiv, exact cum a
fost dintotdeauna: borcanul tău de bacșiș, cheia ta și istoricul tău de bacșișuri
stau pe dispozitiv și nicăieri altundeva. Nu ai la ce să te înscrii.

Autentificarea — cu Apple, cu Google sau ca invitat — este acum posibilă și există
dintr-un singur motiv: un al doilea dispozitiv. Dacă tableta de pe scenă și
telefonul din buzunarul tău trebuie să arate aceeași seară, ceva trebuie să stea
între ele, iar acel ceva este Firestore, sub un id de utilizator pe care doar tu îl
poți citi. Trupele tale, setările, istoricul bacșișurilor — și, criptată ca mai
sus, cheia ta Stripe — stau acolo. Asta e o schimbare reală în povestea
confidențialității și merită spusă pe față, nu descoperită: fără cont, niciun
server nu vede vreodată un bacșiș; cu cont, îl vede propriul tău colț din al
nostru, iar webhookul nostru este cel care îl scrie acolo. E prețul celui de-al
doilea dispozitiv și rămâne la tine să-l plătești sau să-l refuzi. Ce nu atinge
niciodată sunt banii — un cont îți mută datele, nu soldul, și tot nu luăm niciun
comision.

## De ce n-ar trebui să ne crezi pe cuvânt

Tot ce e mai sus se poate verifica. Codul sursă este licențiat MIT și public, iar
site-ul este o compilare statică publicată de GitHub Actions pe GitHub Pages —
nicio infrastructură ascunsă, nimic compilat în spatele unei uși. Deschide fila
de rețea în timpul unui bacșiș demonstrativ și citește cererile. Sunt mai puține
decât te aștepți.

Asta e adevărata afirmație despre produs. Nu că suntem demni de încredere, ci că
nu ai nevoie să fim.
