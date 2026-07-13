# Costruisci un barattolo delle mance sul tuo account Stripe

> Tre chiamate API ti danno una pagina ospitata a prezzo libero con Apple Pay e Google Pay, senza alcun server. Ecco il montaggio completo: la chiave con permessi limitati, gli scope, come rileggere le mance senza webhook e i conti sulle commissioni che nessuno stampa.

Canonical: https://live.tips/it/blog/costruisci-un-barattolo-delle-mance-sul-tuo-account-stripe/
Published: 2026-07-11
Language: it
Tags: Stripe, open source, how-to, API, fees

---

Vuoi un barattolo delle mance. Non vuoi regalare a una piattaforma il 5 % della serata
di un musicista di strada, e sai benissimo parlare con un'API. La domanda quindi non è
*a quale barattolo delle mance devo iscrivermi*, ma *quanto devo davvero costruire*.

Meno di quanto pensi. Su Stripe la risposta concreta sono tre chiamate API: nessun
server, nessun backend, nessun endpoint webhook. Il resto di questo articolo è quel
montaggio, più le due cose che sbagliano tutti.

## Il trucco è un Price a prezzo libero

Stripe ha una modalità di prezzo in cui è il fan a digitare l'importo. Si chiama
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) ed è
l'intera funzionalità. Crei un Product, ci attacchi un Price con
`custom_unit_amount[enabled]=true` e ci appendi sopra un
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. la cosa che "vendi"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. il prezzo che sceglie il fan
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. la pagina
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

La terza chiamata restituisce una `url`. Quella URL *è* il tuo barattolo delle mance.
È una pagina ospitata da Stripe: conforme PCI senza che tu ci debba pensare,
localizzata, e mostra Apple Pay o Google Pay a qualunque fan li abbia configurati sul
telefono — i
[metodi di pagamento dinamici](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
lo decidono per te in base a dispositivo e paese. Non hai scritto alcun frontend.

Codifica la URL come QR code con la libreria che preferisci — è solo una stringa —
stampalo, attaccalo alla custodia. Il codice non scade mai e non punta a nessun server
tuo, perché non ne hai uno.

Due parametri da conoscere:

- **`custom_unit_amount[preset]`** è l'importo con cui la pagina si apre. `500` significa
  che il fan vede già 5,00 € precompilati e può cambiarli. Questo numero fa per la tua
  mancia media più di qualunque altra cosa sulla pagina.
- **`custom_unit_amount[minimum]`** è un pavimento. Mettilo. Il motivo è nella sezione
  sulle commissioni, e non è un errore di arrotondamento.

Puoi anche raccogliere un nome e un messaggio. I Payment Links accettano fino a tre
`custom_fields`: è così che ottieni il "ma da chi era?" senza costruire un form:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Il tuo nome o soprannome" \
  -d "custom_fields[0][optional]"=true
```

Stripe ha dei [requisiti per accettare mance e donazioni](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):
leggili una volta. Il prezzo libero non si combina nemmeno con altri line item, sconti o
pagamenti ricorrenti. Per un barattolo delle mance, nulla di tutto ciò dà fastidio.

Vale la pena azzeccare questa distinzione. Stripe la mette così: una mancia è data per un
bene o un servizio già reso, mentre una donazione dev'essere legata a uno scopo benefico.
Hai suonato; la mancia la paga. È anche per questo che la chiamata qui sopra manda
`submit_type=pay` e non `donate` — `donate` ospiterebbe il tuo link su `donate.stripe.com`
e scriverebbe *Dona* sul pulsante. È un altro mestiere, e uno che Stripe esamina molto più
a fondo.

## La chiave: dai per scontato che trapeli, e rendi la cosa noiosa

Non mettere una chiave segreta (`sk_live_…`) su un dispositivo che sta su un palco. Usa
una [chiave con permessi limitati](https://docs.stripe.com/keys/restricted-api-keys)
(`rk_live_…`): scegli un permesso per risorsa, e tutto ciò che non scegli resta su **None**.

Per il montaggio qui sopra, l'elenco completo è di cinque righe:

| Risorsa | Permesso | A cosa serve |
| --- | --- | --- |
| Products | Write | creare il Product |
| Prices | Write | creare il Price a prezzo libero |
| Payment Links | Write | creare il link |
| Checkout Sessions | Read | vedere le mance arrivate |
| Events | Read | il feed live (prossima sezione) |

Tutto il resto — Balance, Payouts, Refunds, Customers, PaymentIntents, tutto Connect —
resta su **None**.

Ora fai l'esercizio che rende tutto questo sensato. Alle una di notte ti fregano il
tablet dal banco del merch. Cosa può farci il ladro con la chiave nel portachiavi?
Leggere lo storico delle mance e creare altri link per le mance nel tuo account. Questo
è tutto il raggio dell'esplosione. Non vede il tuo saldo, non può lanciare un
trasferimento, non può emettere un rimborso su una carta che controlla, non può leggere
una lista clienti. Revochi la chiave dal telefono nel taxi verso casa e il dispositivo si
spegne. Del tuo denaro non si è mosso niente.

Questa asimmetria — accesso in scrittura al barattolo, zero accesso ai soldi — è l'unica
ragione per cui un design serverless con chiave tua è difendibile. È anche il motivo per
cui "Login with Stripe" qui non è la risposta: OAuth richiede un server dello sviluppatore
dell'app che custodisca il tuo token, e un server è esattamente ciò che non stiamo
costruendo.

(Una stranezza in cui inciamperai: il permesso *Prices* internamente si chiama
`plan_write`, quindi il messaggio d'errore di Stripe nomina uno scope che nella dashboard
non compare con quel nome. È Prices.)

## Rileggere le mance senza webhook

Qui la maggior parte delle guide si ferma o tira fuori un webhook — ed è qui che un palco
è davvero diverso da un'app web.

Un webhook è una richiesta HTTP in entrata. Un tablet dietro un'asta del microfono non può
riceverne. Sta sul wi-fi ospiti del locale, dietro un NAT, senza indirizzo pubblico, senza
certificato TLS — e non ha alcun motivo di averli. Se prendi la strada del webhook devi
tirare su un server che intercetti gli eventi e un socket che li spinga al dispositivo:
un backend, un onere operativo e un posto in cui ora vivono i nomi dei tuoi fan. Hai appena
ricostruito la piattaforma che volevi evitare.

Quindi tira invece di farti spingere. L'endpoint
[List all events](https://docs.stripe.com/api/events/list) di Stripe è pubblico,
documentato e restituisce gli eventi dal più recente:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_ULTIMO_VISTO \
  -d limit=100
```

`ending_before` è tutto il design. Tieni l'id dell'evento più recente che hai elaborato;
ogni poll chiede tutto ciò che è strettamente più nuovo, e tu avanzi il cursore. Niente
timestamp, niente clock skew, niente deduplica per importo. Al primo poll di un set chiedi
`limit=1` senza cursore per ancorarti a ciò che c'è già, così non ti ritrovi a riprodurre
al soundcheck le mance di stamattina.

Poi filtra ciò che torna. Entrambi i tipi di evento possono scattare per un solo pagamento,
quindi deduplica sull'id della Checkout Session. Controlla `payment_status == "paid"`: una
sessione completata non è necessariamente pagata. E controlla che `payment_link` corrisponda
al *tuo* link, perché `/v1/events` è a livello di account e ti passerà volentieri il traffico
di qualsiasi altra cosa faccia quell'account Stripe.

Sii onesto sui compromessi, perché sono reali:

- **Stripe consiglia i webhook.** Il polling non è la via benedetta: è un endpoint documentato
  usato deliberatamente. Scrivilo nel README e vai avanti.
- **Gli eventi risalgono a 30 giorni.** [Parole di Stripe](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* È un feed live, non il tuo libro mastro. Il tuo
  libro mastro sono le Checkout Sessions, e quello vero è la dashboard di Stripe.
- **Occhio all'allocazione di lettura.** Tutti guardano il limite al secondo
  ([rate limit](https://docs.stripe.com/rate-limits): 100 req/s in live) e nessuno guarda
  l'altro: Stripe assegna circa **500 richieste di lettura per transazione** su 30 giorni
  mobili, con un pavimento di 10.000 letture al mese. Fai polling ogni 4 secondi e un set di
  tre ore fa ~2.700 letture. Quattro concerti lunghi in un mese e sei al pavimento. Le mance
  ti comprano margine man mano che arrivano, ma se fai polling ogni secondo perché sembrava
  più reattivo, il soffitto lo trovi. Quattro secondi non è un numero pigro: è *il* numero.

Questa è la forma onesta della cosa: il polling ti costa qualche migliaio di GET e ti fa
risparmiare un backend intero.

## I conti sulle commissioni, fatti per bene

Una piattaforma che pubblicizza lo 0 % non è gratis, e nemmeno questo lo è. La commissione di
elaborazione di Stripe si applica a ogni mancia, e Stripe te la addebita direttamente. Oggi,
secondo i [prezzi in euro di Stripe](https://stripe.com/ie/pricing), una carta SEE standard
costa **1,5 % + 0,25 €**. Le carte SEE premium 1,9 % + 0,25 €, quelle britanniche 2,5 % +
0,25 €, e tutto il resto 3,25 % + 0,25 € più un altro 2 % se serve una conversione di valuta.
(Negli Stati Uniti è 2,9 % + 0,30 $, che è peggio esattamente per il motivo qui sotto.)

Il problema non è la percentuale. Sono i venticinque centesimi.

| Mancia | Stripe prende | L'artista tiene | Prelievo effettivo |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Una commissione fissa è una percentuale travestita, e sui piccoli importi il travestimento
cade. Gli stessi 0,25 € invisibili su una mancia da 50 € si mangiano un ottavo di una da 2 €.
Le mance sono piccole per natura — è ciò che le rende mance — quindi non è un caso limite: è
il caso mediano.

Ecco perché imposti `custom_unit_amount[minimum]`. Intorno ai 2 € la transazione smette di
valere la pena; una mancia con carta da 0,50 € arriverebbe come 0,24 € e costerebbe a Stripe
più muoverla di quanto valga. Scegli il tuo pavimento deliberatamente, invece di scoprirlo al
primo trasferimento.

E guarda cosa fa questo al confronto da cui sei partito. Una piattaforma che prende lo 0 %
sopra Stripe ti sta prendendo lo 0 % sopra **questo**. Il loro 0 % è reale — ed è lo 0 % di
ciò che il processore ha lasciato. Il binario delle carte di nessuno è gratis: l'affermazione
onesta è "nessun prelievo oltre quello del processore", e chi sostiene di più o mente o non
usa carte.

## Cosa hai adesso, e cosa no

Tre chiamate API e un QR code, e un vero barattolo delle mance: ospitato, conforme PCI, Apple
Pay, Google Pay, mance che atterrano sul tuo saldo Stripe secondo il tuo calendario di
trasferimenti, e nessun server sul percorso. Per molti è davvero la fine del progetto, e puoi
tranquillamente fermarti qui e spedirlo.

Ciò che non hai è un palco. Hai una pagina di pagamento. In mezzo ci stanno le cose noiose: il
loop di polling con cursore e backoff, uno schermo che il pubblico possa vedere con l'obiettivo
e l'ultimo messaggio, un posto per la chiave che non sia `localStorage`, un blocco perché un
estraneo non smanetti il tablet tra un set e l'altro, e lo strato delle mille piccole decisioni
su cosa succede quando il wi-fi del locale cade a metà set.

Questo è [live.tips](https://github.com/mekedron/live.tips): esattamente questa architettura,
finita, con licenza MIT. La chiave limitata con quei cinque permessi, il loop a cursore su
`/v1/events`, la creazione di Product/Price/Payment Link — tutto in esecuzione sul dispositivo
dell'artista, contro il suo account. Nessun server live.tips nel percorso Stripe e nessun saldo
live.tips da nessuna parte, cosa che abbiamo raccontato a parte in
[come live.tips gestisce il denaro](https://live.tips/it/blog/come-live-tips-gestisce-denaro/).

Leggi il codice, prendi i pezzi che ti servono, o semplicemente usalo. Il punto di questo
articolo è che l'architettura non è né un segreto né difficile: **Stripe ospiterà il tuo
barattolo delle mance gratis, e una chiave limitata più un loop di polling sono tutto ciò che si
frappone tra un artista e i suoi soldi.** Preferiamo che tu lo sappia piuttosto che ti iscriva
da qualche parte.
