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

## Bacșișurile cu cardul nu trec niciodată prin noi

Când un fan atinge o sumă pe card, browserul lui vorbește cu `api.stripe.com`. Nu
cu un server live.tips — nu există niciunul pe traseul ăsta. Plata este creată în
contul **tău** Stripe, se decontează în soldul **tău** Stripe și este plătită
după calendarul **tău** Stripe. Singurul comision este comisionul standard de
procesare al Stripe însuși, pe care Stripe ți-l percepe direct, exact cum ar
face-o dacă ai fi integrat tu însuți Stripe.

De partea noastră nu există niciun registru, pentru că nu e nimic de înregistrat.
Nu am putea lua un procent fără să construim mai întâi lucrul care ține banii.

## Cheile tale rămân ale tale

Configurarea cere o cheie API Stripe *restricționată*, nu o cheie secretă reală —
pe acelea le refuzăm din capul locului. Este stocată în portcheiul propriului tău
dispozitiv și trimisă către Stripe doar prin TLS.

Restricționată înseamnă că cheia poate face două lucruri: să creeze linkul de
bacșiș plătește-cât-vrei și să urmărească bacșișurile care sosesc. Nu poate
să-ți citească soldul, să declanșeze plăți, să emită rambursări sau să atingă
datele clienților. Dacă s-ar scurge mâine, raza de explozie e un link de bacșiș.

## Singurul server din traseul plății

Revolut și MobilePay nu pot fi controlate dintr-un browser așa cum poate fi
Stripe, așa că activarea lor pornește un releu minimal — o mână de funcții
Firebase care servesc pagina ta de bacșiș la `tip.live.tips`. Merită să fim
preciși în privința a ceea ce face acel releu, pentru că „am adăugat un
backend" e de obicei momentul în care poveștile astea o iau razna.

Stochează profilul public al paginii tale de bacșiș — numele afișat și
identificatorii de plată pe care ai ales să-i publici. Atât. Nu păstrează niciun
istoric al bacșișurilor, nu vede niciun ban, nu ține nicio cheie și se
autoșterge după 90 de zile de inactivitate. Un bacșiș prin Revolut sau MobilePay
așteaptă acolo doar până când îl preia dispozitivul tău de pe scenă: afișarea lui
îl șterge, iar tot ce n-a mai venit nimeni să ridice este măturat în decurs de o
oră. Banii tot circulă direct între aplicația Revolut sau MobilePay a fanului tău
și a ta.

Dacă folosești doar Stripe, releul nu este contactat niciodată.

## Contul pe care nu ești obligat să ți-l faci

Aplicația tot pornește într-un profil care trăiește doar pe dispozitiv, exact cum a
fost dintotdeauna: borcanul tău de bacșiș, cheia ta și istoricul tău de bacșișuri
stau pe dispozitiv și nicăieri altundeva. Nu ai la ce să te înscrii.

Autentificarea — cu Apple, cu Google sau ca invitat — este acum posibilă și există
dintr-un singur motiv: un al doilea dispozitiv. Dacă tableta de pe scenă și
telefonul din buzunarul tău trebuie să arate aceeași seară, ceva trebuie să stea
între ele, iar acel ceva este Firestore, sub un id de utilizator pe care doar tu îl
poți citi. Trupele tale, setările, cheia restricționată și istoricul bacșișurilor
se sincronizează acolo. Asta e o schimbare reală în povestea confidențialității și
merită spusă pe față, nu descoperită: fără cont, niciun server nu vede vreodată un
bacșiș; cu cont, îl vede propriul tău colț din al nostru. E prețul celui de-al
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
