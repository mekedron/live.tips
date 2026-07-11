---
title: Construiește un borcan de bacșiș pe propriul cont Stripe
description: Trei apeluri de API îți dau o pagină găzduită de tip „plătește cât vrei”, cu Apple Pay și Google Pay, fără niciun server. Iată construcția completă: cheia restricționată, permisiunile, cum citești bacșișurile fără webhook și calculul comisioanelor pe care nu-l tipărește nimeni.
slug: construieste-un-borcan-de-bacsis-pe-propriul-cont-stripe
---

Vrei un borcan de bacșiș. Nu vrei să dai unei platforme 5 % din seara unui muzician
stradal și te descurci perfect cu un API. Așa că întrebarea nu este *la ce borcan de
bacșiș să mă înscriu*, ci *cât trebuie de fapt să construiesc*.

Mai puțin decât crezi. Pe Stripe, răspunsul funcțional este: trei apeluri de API, niciun
server, niciun backend, niciun endpoint de webhook. Restul acestui articol este exact acea
construcție — plus cele două lucruri pe care le greșește toată lumea.

## Trucul este un Price „plătește cât vrei”

Stripe are un mod de tarifare în care fanul scrie el suma. Se numește
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) și este
toată funcționalitatea. Creezi un Product, îi atașezi un Price cu
`custom_unit_amount[enabled]=true` și pui deasupra un
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. lucrul pe care îl "vinzi"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. prețul pe care îl alege fanul
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. pagina
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=donate
```

Al treilea apel returnează un `url`. Acel URL *este* borcanul tău de bacșiș. E o pagină
găzduită de Stripe: conformă PCI fără să te gândești la asta, localizată, și afișează Apple
Pay sau Google Pay oricărui fan al cărui telefon le are configurate —
[metodele de plată dinamice](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
decid asta în locul tău, în funcție de dispozitiv și țară. N-ai scris niciun frontend.

Codifică URL-ul ca un cod QR cu orice bibliotecă vrei — e doar un șir de caractere —,
printează-l, lipește-l pe toc. Codul nu expiră niciodată și nu arată către niciun server al
tău, pentru că nu ai niciunul.

Doi parametri pe care merită să-i știi:

- **`custom_unit_amount[preset]`** este suma cu care se deschide pagina. `500` înseamnă că
  fanul vede deja 5,00 € completați și poate schimba. Numărul ăsta face mai mult pentru
  bacșișul tău mediu decât orice altceva de pe pagină.
- **`custom_unit_amount[minimum]`** este un prag minim. Pune-l. Motivul e în secțiunea despre
  comisioane de mai jos și nu e o eroare de rotunjire.

Poți colecta și un nume și un mesaj. Payment Links acceptă până la trei `custom_fields` — așa
obții „de la cine a fost?” fără să construiești un formular:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Numele sau porecla ta" \
  -d "custom_fields[0][optional]"=true
```

Stripe are [cerințe pentru acceptarea bacșișurilor și donațiilor](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
citește-le o dată. „Plătește cât vrei” nu se combină nici cu alte line items, reduceri sau plăți
recurente. Pentru un borcan de bacșiș, nimic din toate astea nu deranjează.

## Cheia: presupune că se scurge — și fă din asta ceva plictisitor

Nu pune o cheie secretă (`sk_live_…`) pe un dispozitiv care stă pe o scenă. Folosește o
[cheie restricționată](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`): alegi o
permisiune pentru fiecare resursă, iar tot ce nu alegi rămâne pe **None**.

Pentru construcția de mai sus, lista completă are cinci rânduri:

| Resursă | Permisiune | La ce folosește |
| --- | --- | --- |
| Products | Write | crearea Product-ului |
| Prices | Write | crearea Price-ului „plătește cât vrei” |
| Payment Links | Write | crearea linkului |
| Checkout Sessions | Read | vizualizarea bacșișurilor intrate |
| Events | Read | fluxul live (secțiunea următoare) |

Tot restul — Balance, Payouts, Refunds, Customers, PaymentIntents, tot Connect — rămâne pe
**None**.

Acum fă exercițiul care face ca totul să merite. La ora unu noaptea îți dispare tableta de pe
masa de merch. Ce poate face hoțul cu cheia din keychain? Îți citește istoricul de bacșișuri și
creează încă niște linkuri de bacșiș în contul tău. Ăsta e tot raza de explozie. Nu-ți vede
soldul, nu poate declanșa o plată, nu poate emite o rambursare către un card pe care-l
controlează, nu poate citi o listă de clienți. Revoci cheia de pe telefon, din taxiul spre casă,
și dispozitivul se stinge. Din banii tăi nu s-a mișcat nimic.

Această asimetrie — acces de scriere la borcan, zero acces la bani — este singurul motiv pentru
care un design fără server, cu cheia ta, poate fi apărat. E și motivul pentru care „Login with
Stripe” nu e răspunsul aici: OAuth are nevoie de un server al dezvoltatorului aplicației care
să-ți țină tokenul, iar un server este exact ce nu construim.

(O ciudățenie de care vei da: permisiunea *Prices* se numește intern `plan_write`, așa că mesajul
de eroare al Stripe numește un scope care în dashboard nu apare sub numele ăsta. E vorba de Prices.)

## Citirea bacșișurilor fără webhook

Aici majoritatea ghidurilor se opresc sau apucă un webhook — și aici o scenă chiar diferă de o
aplicație web.

Un webhook este o cerere HTTP de intrare. O tabletă din spatele unui stativ de microfon nu poate
primi așa ceva. Stă pe wi-fi-ul de oaspeți al sălii, în spatele unui NAT, fără adresă publică, fără
certificat TLS — și n-are ce căuta cu ele. Dacă alegi calea webhookului, trebuie să ridici un
server care să prindă evenimentele și un socket care să le împingă spre dispozitiv: un backend, o
povară operațională și un loc în care acum locuiesc numele fanilor tăi. Tocmai ai reconstruit
platforma pe care voiai s-o eviți.

Deci trage, în loc să te lași împins. Endpointul
[List all events](https://docs.stripe.com/api/events/list) al Stripe este public, documentat și
returnează evenimentele începând cu cel mai nou:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_ULTIMUL_VAZUT \
  -d limit=100
```

`ending_before` este tot designul. Ține id-ul celui mai nou eveniment procesat; fiecare interogare
cere tot ce e strict mai nou, iar tu avansezi cursorul. Fără timestampuri, fără derivă de ceas, fără
deduplicare după sumă. La prima interogare a unui set, cere `limit=1` fără cursor ca să te ancorezi
în ce există deja, ca să nu redai la proba de sunet bacșișurile de azi-dimineață.

Apoi filtrează ce vine înapoi. Ambele tipuri de eveniment se pot declanșa pentru o singură plată, deci
deduplică după id-ul Checkout Session. Verifică `payment_status == "paid"` — o sesiune finalizată nu
este neapărat una plătită. Și verifică dacă `payment_link` corespunde linkului *tău*, pentru că
`/v1/events` e la nivel de cont și îți va înmâna bucuros traficul a tot ce mai face acel cont Stripe.

Fii sincer în privința compromisurilor, pentru că sunt reale:

- **Stripe recomandă webhookuri.** Polling-ul nu e calea binecuvântată; e un endpoint documentat folosit
  deliberat. Spune asta în README și mergi mai departe.
- **Evenimentele merg 30 de zile în urmă.** [Cuvintele Stripe](https://docs.stripe.com/api/events/list):
  *„List events, going back up to 30 days.”* Ăsta e un flux live, nu registrul tău contabil. Registrul tău
  sunt Checkout Sessions — iar cel adevărat e dashboardul Stripe.
- **Atenție la cota de citiri.** Toată lumea se uită la limita pe secundă
  ([rate limits](https://docs.stripe.com/rate-limits): 100 cereri/s în live) și nimeni la cealaltă: Stripe
  alocă aproximativ **500 de cereri de citire per tranzacție** pe o fereastră mobilă de 30 de zile, cu un
  prag minim de 10 000 de citiri pe lună. Interoghează la fiecare 4 secunde și un set de trei ore înseamnă
  ~2 700 de citiri. Patru concerte lungi într-o lună și ești la prag. Bacșișurile îți cumpără spațiu pe
  măsură ce sosesc — dar dacă interoghezi în fiecare secundă pentru că părea mai vioi, o să găsești
  plafonul. Patru secunde nu e un număr leneș: *este* numărul.

Asta e forma cinstită a lucrurilor: polling-ul te costă câteva mii de GET-uri și îți cumpără ștergerea unui
backend întreg.

## Calculul comisioanelor, făcut ca lumea

O platformă care afișează 0 % nu e gratuită, și nici asta nu e. Comisionul de procesare al Stripe se aplică
fiecărui bacșiș, iar Stripe ți-l facturează direct. Astăzi, conform
[prețurilor în euro ale Stripe](https://stripe.com/ie/pricing), un card standard din SEE costă
**1,5 % + 0,25 €**. Cardurile premium din SEE: 1,9 % + 0,25 €; cele britanice: 2,5 % + 0,25 €; iar restul:
3,25 % + 0,25 €, plus încă 2 % dacă trebuie convertită o monedă. (În SUA e 2,9 % + 0,30 $, ceea ce e mai rău
exact din motivul de mai jos.)

Problema nu e procentul. Problema sunt cei douăzeci și cinci de cenți.

| Bacșiș | Stripe ia | Artistul păstrează | Reținere efectivă |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Un comision fix este un procent deghizat, iar la bani mărunți deghizarea alunecă. Aceiași 0,25 € invizibili la
un bacșiș de 50 € mănâncă o optime dintr-unul de 2 €. Bacșișurile sunt mici prin natura lor — asta le face
bacșișuri — deci nu e un caz-limită, e cazul median.

Exact de asta setezi `custom_unit_amount[minimum]`. Pe undeva pe la 2 €, tranzacția încetează să merite; un
bacșiș cu cardul de 0,50 € ar ajunge ca 0,24 € și l-ar costa pe Stripe mai mult să-l mute decât valorează.
Alege-ți pragul deliberat, în loc să-l descoperi la prima plată.

Și observă ce face asta comparației cu care ai pornit. O platformă care ia 0 % peste Stripe îți ia 0 % peste
**asta**. 0 %-ul lor e real — și e 0 % din ce a lăsat procesatorul. Șina de card a nimănui nu e gratuită:
afirmația cinstită e „niciun comision peste cel al procesatorului”, iar cine pretinde mai mult ori minte, ori
nu folosește carduri.

## Ce ai acum și ce nu ai

Trei apeluri de API și un cod QR — și un borcan de bacșiș adevărat: găzduit, conform PCI, Apple Pay, Google
Pay, bacșișuri care aterizează în propriul tău sold Stripe, pe propriul tău calendar de plăți, și niciun server
în drum. Pentru mulți oameni, ăsta e sincer finalul proiectului, și poți foarte bine să te oprești aici și să-l
livrezi.

Ce nu ai este o scenă. Ai o pagină de plată. Între cele două stau lucrurile plictisitoare: bucla de polling cu
cursorul și backoff-ul ei; un ecran pe care publicul îl poate vedea, cu obiectivul și ultimul mesaj; un loc pentru
cheie care să nu se numească `localStorage`; o blocare ca un străin să nu umble la tabletă între seturi; și stratul
celor o mie de decizii mărunte despre ce se întâmplă când cade wi-fi-ul sălii la mijlocul setului.

Exact asta este [live.tips](https://github.com/mekedron/live.tips) — fix această arhitectură, terminată, sub licență
MIT. Cheia restricționată cu acele cinci permisiuni, bucla cu cursor pe `/v1/events`, crearea
Product/Price/Payment Link — toate rulând pe dispozitivul artistului, pe contul lui. Nu există niciun server
live.tips pe traseul Stripe și niciun sold live.tips nicăieri, lucru pe care l-am scris separat în
[cum se poartă live.tips cu banii](post:how-live-tips-handles-money).

Citește sursa, ia bucățile care te interesează sau pur și simplu folosește-l. Ideea acestui articol este că
arhitectura nu e nici secret, nici greu: **Stripe îți va găzdui gratis borcanul de bacșiș, iar o cheie
restricționată plus o buclă de polling e tot ce stă între un artist și banii lui.** Preferăm să știi asta decât să
te înscrii undeva.
