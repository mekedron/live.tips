---
title: Informativa sulla privacy
description: live.tips non ha account, non ha cookie, non ha analytics e non traccia nessuno. Ecco l'elenco breve di ciò che viene trattato, da chi e per quanto tempo.
updated: 2026-07-13
updated_label: Ultimo aggiornamento 13 luglio 2026
---

live.tips è un barattolo delle mance open source per artisti. È gestito da **Nikita Rabykin**,
uno sviluppatore individuale, non una società. Se qualcosa di quanto segue ti interessa, scrivi a
**[contact@live.tips](mailto:contact@live.tips)** — a quell'indirizzo risponde una persona.

Questa informativa è onesta anche nelle parti noiose. Preferiamo dire «conserviamo il tuo nome
per un massimo di un'ora» piuttosto che sostenere di non conservare nulla e sbagliarci.

## La versione breve

- **Nessun account.** Non c'è nulla a cui registrarsi.
- **Nessun cookie.** Neanche uno, da nessuna parte.
- **Nessun analytics, nessun tracciamento, nessuna pubblicità, nessuno script di terze parti**
  su questo sito.
- **Non tocchiamo mai il tuo denaro.** Le mance vanno dritte dal fan all'account Stripe,
  Revolut, MobilePay o Monzo dell'artista. Noi non siamo su quel percorso.
- **Nella configurazione predefinita, l'app parla soltanto con Stripe** — con nessun server
  live.tips.
- L'unico server che gestiamo è un piccolo relay, che esiste solo se un artista attiva
  Revolut, MobilePay o Monzo.

## Questo sito

Il sito è statico ed è ospitato su **GitHub Pages**. In quanto host, GitHub riceve l'indirizzo IP
e lo user-agent del browser di chiunque carichi una pagina — è la normale registrazione dei log
di un server web, avviene prima che il nostro codice entri in funzione e non possiamo disattivarla.
GitHub li tratta secondo la propria
[informativa sulla privacy](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Noi non leggiamo quei log e GitHub non ce li mostra.

Al di là di questo, le pagine che stai leggendo non caricano **nulla da nessun altro**: font, icone
e immagini sono serviti da live.tips stesso. Non c'è Google Analytics, non c'è un tag manager,
non c'è alcun pixel, non c'è alcun widget incorporato.

Il sito memorizza **due valori nel `localStorage` del tuo browser**, entrambi impostati da te,
entrambi leggibili solo da questo sito e nessuno dei due inviato mai da nessuna parte:

| Chiave | Cosa ricorda |
| --- | --- |
| `lt-landing-theme` | se hai scelto colori chiari, scuri o automatici |
| `lt-langbar-dismissed` | che hai chiuso il banner «disponibile anche nella tua lingua» |

Svuotare l'archiviazione del browser li cancella. Non sono cookie, non vengono condivisi
e non identificano nessuno.

## L'app

L'app live.tips gira **sul dispositivo dell'artista**. Tutto ciò che sa vive lì:

- La **chiave Stripe con permessi limitati** è salvata nel portachiavi del dispositivo
  (Keychain di iOS/macOS, Keystore di Android) e viene inviata soltanto a `api.stripe.com`.
- **Storico delle mance, storico delle sessioni, obiettivo e impostazioni dell'app** sono
  salvati nell'archiviazione locale del dispositivo. Questo include i nomi e i messaggi che
  i fan allegano alle loro mance.
- Disinstallare l'app cancella tutto quanto. Non c'è alcun backup nel cloud dalla nostra parte,
  perché dalla nostra parte non c'è alcun cloud.

**Noi non riceviamo nulla di tutto ciò.** L'app non contiene alcun SDK di analytics, alcun
strumento di segnalazione dei crash, alcuna notifica push e alcun codice pubblicitario —
nessuno, nemmeno disattivato.

Due precisazioni, perché l'affermazione «non parla con nessuno» resti esattamente vera:

- L'app scarica i **tassi di cambio delle valute** una volta al giorno da API pubbliche
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Sono semplici richieste
  di un elenco pubblico di tassi. Non trasportano alcuna informazione su di te, sull'artista
  o su qualsiasi mancia — ma, come qualsiasi richiesta web, rivelano il tuo indirizzo IP
  a quei servizi.
- Se usi la **versione browser** dell'app, il tuo browser la scarica dal nostro host statico
  (vedi *Questo sito* qui sopra).

## Stripe

Quando un fan paga con carta, si trova sulla pagina di pagamento di **Stripe**, non sulla nostra.
Stripe raccoglie e tratta i suoi dati di pagamento come titolare autonomo, ai sensi della
[Privacy Policy di Stripe](https://stripe.com/privacy). Noi non vediamo mai i numeri delle carte
e non abbiamo accesso all'account Stripe dell'artista.

L'app dell'artista legge le sue mance da Stripe usando la chiave con permessi limitati
dell'artista stesso. Il nome e il messaggio di un fan, se ne ha lasciati, viaggiano da Stripe
al dispositivo dell'artista e si fermano lì.

## Il relay — solo se Revolut, MobilePay o Monzo sono attivi

Le configurazioni solo-Stripe non lo toccano mai e possono smettere di leggere qui.

Revolut, MobilePay e Monzo non offrono ad un'app alcun modo di confermare che un pagamento sia
avvenuto, perciò quelle mance passano attraverso un piccolo relay open source che gestiamo su
**Cloudflare** all'indirizzo `api.live.tips`. Non tocca mai il denaro. Ecco tutto ciò che gestisce.

### Cosa memorizza l'artista

La creazione di una pagina delle mance memorizza il **nome pubblico dell'artista, il suo messaggio
pubblico, la sua valuta e gli identificativi di pagamento che ha scelto di pubblicare** (il suo link
di pagamento Stripe, il nome utente Revolut, il Box ID di MobilePay, il nome utente Monzo). Si tratta
comunque tutto di informazioni che l'artista sta deliberatamente pubblicando per i fan.

- **Conservazione: cancellati automaticamente dopo 90 giorni di inattività.**
- L'artista può cancellarli **immediatamente** dall'app, in qualsiasi momento.
- Non vengono mai raccolti indirizzi email, password, nomi legali o dati bancari.

### Cosa invia un fan

Il modulo della mancia chiede un **importo** e, facoltativamente, un **nome** e un **messaggio**.
Il modulo è tutto qui. Nessuna email, nessun numero di telefono, nessun account.

- Se lo schermo dell'artista è **online**, la mancia gli viene passata direttamente e **non viene
  mai scritta su disco**.
- Se lo schermo dell'artista è **offline** — telefono bloccato, niente segnale — la mancia viene
  **trattenuta in memoria per un massimo di un'ora**, così da non andare semplicemente perduta, e
  poi consegnata nel momento in cui lo schermo si riconnette. Se nessuno si riconnette, viene
  **cancellata senza essere vista**. Questo è l'unico testo scritto da un fan che il relay
  memorizzi mai, e un'ora è il suo limite invalicabile.
- Il tuo nome e il tuo messaggio vengono inoltre inseriti nella **causale del pagamento** che si apre
  in Revolut, MobilePay o Monzo — è così che l'artista sa chi ha lasciato la mancia. Quelle società
  li trattano poi secondo le proprie informative sulla privacy.
- Il relay non conserva **alcuno storico delle mance**. Non può mostrare a te, a noi o a chiunque
  altro un elenco di chi ha lasciato una mancia a chi.

### Indirizzi IP e misure anti-abuso

Un modulo aperto, a cui chiunque può inviare dati, ha bisogno di una qualche protezione dai bot,
perciò:

- Il tuo indirizzo IP viene usato per **limitare la frequenza** delle richieste e viene inviato a
  **Cloudflare Turnstile** (un controllo anti-bot che gira sulla pagina delle mance) per verificare
  che tu non sia un bot. Turnstile è un prodotto di Cloudflare ed è usato al posto di un CAPTCHA
  che ti profila.
- Per impedire a qualcuno di creare migliaia di pagine delle mance, viene conservato un **hash
  crittografico dell'IP** di chi ne crea una per circa **due ore**, poi viene eliminato.
- I **log operativi di Cloudflare** registrano i dettagli tecnici delle richieste al relay — URL,
  tempi, stato — per qualche giorno. Non contengono nomi o messaggi dei fan. Cloudflare agisce come
  nostro responsabile del trattamento; vedi la
  [Privacy Policy di Cloudflare](https://www.cloudflare.com/privacypolicy/).

### Contatori

Il relay conta **quante mance** ha inoltrato una determinata pagina delle mance, così da poter
individuare gli abusi e sapere se la cosa viene usata o no. È un numero. Non contiene alcun dato
dei fan.

## Base giuridica, se ti serve (GDPR)

- Far funzionare il relay per un artista che lo ha attivato e consegnare la mancia di un fan allo
  schermo a cui era destinata: **esecuzione di un servizio che hai richiesto**.
- Limitazione della frequenza, Turnstile e quote basate su IP sottoposto ad hash: **legittimo
  interesse** a impedire che un servizio gratuito e aperto venga distrutto da bot e frodi.
- Log del server: **legittimo interesse** a gestire e mettere in sicurezza il servizio.

## I tuoi diritti

Puoi chiederci di darti una copia, di correggere o di cancellare qualsiasi dato che ti riguardi in
nostro possesso, e puoi presentare un reclamo alla tua autorità nazionale per la protezione dei dati.
Scrivi a **[contact@live.tips](mailto:contact@live.tips)**.

In pratica, la maggior parte di tutto ciò è già nelle tue mani: gli artisti possono cancellare la
propria pagina delle mance dall'app all'istante, le mance dei fan svaniscono nel giro di un'ora e
tutto il resto vive sul tuo dispositivo.

## Minori

live.tips non è rivolto ai minori e non trattiamo consapevolmente i loro dati.

## Modifiche

Aggiorneremo questa pagina quando il software cambia. Poiché l'intero progetto è open source,
**ogni versione passata di questa informativa si trova nella cronologia git pubblica** — puoi
confrontare esattamente cosa è cambiato e quando.

## Lingua

Questa informativa è pubblicata in tutte le lingue supportate dal sito, per comodità. Se una
traduzione e la versione inglese non concordano, **fa fede la versione inglese**.
