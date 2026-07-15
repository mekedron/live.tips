---
title: Informativa sulla privacy
description: live.tips non ha cookie, non ha analytics e non traccia nessuno, e funziona senza alcun account. Se scegli di accedere, ecco esattamente cosa viene conservato, dove, da chi e per quanto tempo.
updated: 2026-07-15
updated_label: Ultimo aggiornamento 15 luglio 2026
---

live.tips è un barattolo delle mance open source per artisti. È gestito da **Nikita Rabykin**,
uno sviluppatore individuale, non una società. Se qualcosa di quanto segue ti interessa, scrivi a
**[contact@live.tips](mailto:contact@live.tips)** — a quell'indirizzo risponde una persona.

Questa informativa è onesta anche nelle parti noiose. Preferiamo dire «conserviamo il tuo nome
finché conservi la band» piuttosto che sostenere di non conservare nulla e sbagliarci.

## La versione breve

- **L'account è facoltativo.** L'app funziona senza alcun account, e questa è tuttora
  l'impostazione predefinita. Se vuoi le tue band e il tuo storico su un secondo dispositivo,
  puoi accedere — e allora una parte di tutto ciò viene conservata su un server, e più di prima.
  Cosa e come è spiegato qui sotto.
- **Nessun cookie.** Neanche uno, da nessuna parte.
- **Nessun analytics, nessun tracciamento, nessuna pubblicità, nessuno script di terze parti**
  su questo sito.
- **Non tocchiamo mai il tuo denaro.** Le mance vanno dritte dal fan all'account Stripe,
  Revolut, MobilePay o Monzo dell'artista. Non esiste alcun saldo live.tips, mai.
- **Senza account, l'app parla soltanto con Stripe** — con nessun server live.tips. Se effettui
  l'accesso, questo cambia: la tua chiave Stripe si sposta sul nostro server e Stripe ci segnala
  le tue mance, così da poterle mettere sui tuoi altri dispositivi. È questo il costo onesto
  dell'accesso, ed è spiegato per intero qui sotto.
- **Le notifiche push sono una novità, facoltative e solo per gli account con accesso effettuato.**
  Nulla viene inviato a un dispositivo che non le ha mai attivate, e a un dispositivo senza account
  non ne viene inviata nessuna.
- I server che gestiamo sono sul Firebase di Google. Esistono se un artista attiva Revolut,
  MobilePay o Monzo — oppure se effettua l'accesso.

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

## L'app ha due modalità, e la differenza è tutta la storia

Tutto ciò che segue dipende da una sola domanda: **hai effettuato l'accesso?**

### Modalità uno — nessun account. Ancora quella predefinita, ancora invariata.

L'app gira **sul dispositivo dell'artista**, e tutto ciò che sa vive lì:

- La **chiave Stripe con permessi limitati** è salvata nel portachiavi del dispositivo
  (Keychain di iOS/macOS, Keystore di Android) e viene inviata soltanto a `api.stripe.com`.
- **Storico delle mance, storico delle sessioni, l'obiettivo, l'elenco delle richieste di brani e
  le impostazioni dell'app** sono salvati nell'archiviazione locale del dispositivo. Questo include
  i nomi e i messaggi che i fan allegano alle loro mance.
- Disinstallare l'app cancella tutto quanto. Non c'è alcun backup nel cloud dalla nostra parte,
  perché in questa modalità dalla nostra parte non c'è alcun cloud.

**Noi non riceviamo nulla di tutto ciò.** L'app non contiene alcun SDK di analytics, alcuno
strumento di segnalazione dei crash e alcun codice pubblicitario — nessuno, nemmeno disattivato.
(Le notifiche push esistono, ma sono una funzione riservata a chi ha effettuato l'accesso e sono
disattivate finché non le attivi — vedi *Modalità due*. A un dispositivo senza account non ne viene
mai inviata nessuna.)

Due precisazioni, perché l'affermazione «non parla con nessuno» resti esattamente vera:

- L'app scarica i **tassi di cambio delle valute** una volta al giorno da API pubbliche
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Sono semplici richieste
  di un elenco pubblico di tassi. Non trasportano alcuna informazione su di te, sull'artista
  o su qualsiasi mancia — ma, come qualsiasi richiesta web, rivelano il tuo indirizzo IP
  a quei servizi.
- Se usi la **versione browser** dell'app, il tuo browser la scarica dal nostro host statico
  (vedi *Questo sito* qui sopra).

### Modalità due — hai effettuato l'accesso. Allora alcuni dati lasciano il dispositivo, di proposito.

Accedere è un atto deliberato. Nulla ti fa accedere al posto tuo, e nulla dell'app smette di
funzionare se non lo fai mai. Accedi perché vuoi un secondo dispositivo: il telefono in tasca
e il tablet sul palco che mostrano la stessa serata, le stesse band, lo stesso storico.

Questo funziona solo se un server li conserva. **E infatti li conserva, ed è questo il prezzo
onesto del secondo dispositivo.**

Il server è **Firebase**, cioè Google. Ci sono tre modi per avere un account:

- **Accedi con Apple** o **Accedi con Google** — Firebase Auth riceve ciò che il provider gli
  passa: un identificativo utente (uid) e, di solito, un indirizzo email e un nome. (Con Apple
  puoi nascondere la tua email; in quel caso Apple ci dà un indirizzo relay al suo posto, e ci
  passa il tuo nome soltanto la primissima volta che effettui l'accesso.)
- **Un account ospite** — un account anonimo, senza email e senza nome. Si sincronizza e può
  essere revocato, ma se perdi il dispositivo non c'è nulla con cui recuperarlo. È un uid e
  niente più. Un account ospite non può usare la custodia della chiave Stripe lato server né le
  notifiche push descritte più avanti, perché entrambe richiedono un account che possiamo
  restituirti.

Una volta effettuato l'accesso, l'account riceve un proprio angolo privato del database **Cloud
Firestore** di Google, all'indirizzo `users/<your uid>/`. Le regole di sicurezza concedono
quell'angolo a quell'uid **e a nessun altro** — nessun altro account può leggerlo, nemmeno
provando a indovinare gli URL. Al suo interno:

| Cosa | Perché si trova lì |
| --- | --- |
| Le tue **band** — nomi, impostazioni del barattolo delle mance e dei metodi di pagamento, testo del poster, obiettivi e il tuo **elenco delle richieste di brani** | perché una band esista su ogni dispositivo da cui accedi |
| **Impostazioni dell'app**, incluse le tue preferenze di notifica | perché un dispositivo che aggiungi sia già configurato |
| **Registri delle sessioni e storico delle mance** — inclusi **i nomi e i messaggi che i fan allegano alle loro mance** e qualsiasi **brano richiesto da un fan** | perché quello storico è esattamente ciò che hai chiesto di vedere sull'altro dispositivo |
| La **sessione dal vivo** in corso in questo momento | perché un secondo schermo possa unirsi al set di stasera |
| I tuoi **dispositivi** — il nome che ciascuno si dà («iPhone di Nikita»), la sua piattaforma e il modello, la sua lingua dell'interfaccia, quando è stato visto la prima e l'ultima volta e (se hai attivato le notifiche) un **token push** | perché Impostazioni → Sicurezza possa elencarli, perché una notifica raggiunga il dispositivo giusto nella lingua giusta e perché tu possa revocarne uno |
| Un piccolo **documento di profilo** — il nome dell'account che hai scelto e il provider che hai usato | perché il selettore degli account possa etichettarlo |
| Un **feed della campanella** — un elenco limitato di mance e richieste di brani recenti arrivate mentre non era in corso alcun set | perché tu possa recuperare ciò che ti sei perso |

E ora la parte importante, detta chiaramente: **senza account, il nome e il messaggio di un fan
non lasciano mai il dispositivo dell'artista. Con un account, vengono conservati sui server di
Google sotto l'uid dell'artista, come parte dello storico sincronizzato di quell'artista**, ed —
come spiegano le prossime due sezioni — **è ora il nostro server a scriverli lì.** Nessun altro
account può leggerli, noi non li guardiamo e da essi non viene ricavato nulla — ma sono lì, e vi
restano finché resta la band, e dovresti saperlo prima di accedere.

Uscire dall'account riporta il dispositivo alla modalità locale. Non cancella i dati dell'account
— vedi *Cancellare le cose*, qui sotto.

#### La tua chiave Stripe, quando effettui l'accesso, si sposta sul nostro server

Questo è il cambiamento più grande, e quello che vale di più la pena leggere.

**Senza account, la tua chiave Stripe con permessi limitati non lascia mai il tuo dispositivo.**
È la Modalità uno, ed è invariata.

**Quando effettui l'accesso, invece lo lascia — verso di noi.** La chiave viene cifrata (una
chiave AES-256 per singolo segreto, a sua volta protetta da Google Cloud KMS) e conservata lato
server in un posto che **nessuno può rileggere — né un altro account, né nemmeno tu.** Viene aperta
soltanto all'interno delle nostre Cloud Functions, usata per dialogare con Stripe per tuo conto,
e mai più consegnata a un dispositivo.

Poiché la chiave ora vive da noi, **Stripe segnala le tue mance direttamente al nostro server**:
registriamo un webhook sul tuo account Stripe, e Stripe avvisa quel webhook ogni volta che una
mancia viene pagata. La nostra funzione scrive la mancia nello storico del tuo account (vedi sotto).
Per un account con accesso effettuato, la tua app non interroga più Stripe; raggiunge Stripe
soltanto attraverso un elenco ristretto e fisso di operazioni sul nostro server (creare il tuo link
delle mance, generare un link per le richieste di brani e rileggere le tue stesse mance per la
riconciliazione).

Quindi, detto senza eufemismi: **per un account con accesso effettuato c'è ora un server live.tips
nel percorso tra Stripe e il tuo storico.** Continuiamo a non toccare mai il denaro — una mancia con
carta viene creata sul tuo account Stripe, si deposita sul tuo saldo Stripe e viene versata secondo
il tuo calendario Stripe, esattamente come prima. Ciò che è cambiato è il percorso dei *dati*, non
quello del *denaro*. Se non effettui mai l'accesso, nulla di tutto ciò ti riguarda e l'app parla
ancora direttamente con `api.stripe.com` e con nessun altro.

#### Aggiungere un dispositivo con un QR code

Per aggiungere un dispositivo mostri un QR code da un dispositivo che ha già effettuato l'accesso.
Il codice è casuale, **usabile una volta sola e scade in due minuti**, e il nuovo dispositivo non
riceve nulla finché non tocchi *conferma* su quello vecchio. Mentre quella stretta di mano è
aperta conserviamo il codice, il nome che il nuovo dispositivo si è dato e la sua piattaforma —
e il record viene cancellato alla scadenza. Un QR code fotografato non serve a nulla senza il
tuo tocco di conferma.

## Richieste di brani

Una band può attivare le **richieste di brani**: i fan scelgono allora un brano dall'elenco
dell'artista e, facoltativamente, pagano per farlo salire nella coda. Una richiesta è semplicemente
una mancia che porta con sé anche **quale brano** è stato chiesto — quindi qui valgono anche lo
stesso nome e messaggio che un fan può allegare a una mancia, ed è memorizzata e conservata
esattamente come qualsiasi altra mancia (vedi sotto). La coda pubblica che un fan vede mostra
soltanto i **totali per brano** — quanto ha raccolto un brano e dov'è collocato — e non riporta
**alcun nome di fan**. Senza account, l'intero elenco delle richieste di brani e il suo storico
vivono soltanto sul dispositivo.

## Notifiche push

Quando hai effettuato l'accesso, l'app può inviarti una **notifica push** — ma solo se la attivi,
dispositivo per dispositivo, e solo dopo che il sistema operativo del tuo dispositivo concede il
permesso. Esiste per una cosa sola: una mancia o una richiesta di brano che arriva **mentre non
stai conducendo un set**, così da venire a sapere della mancia che altrimenti ti saresti perso.
Una mancia che arriva mentre il tuo palco è dal vivo non invia nulla — la stai già guardando.

- Per consegnare una push, il **Firebase Cloud Messaging (FCM)** di Google ha bisogno di un
  **token push** per il dispositivo. Conserviamo quel token, e la lingua dell'interfaccia del
  dispositivo, nel record del dispositivo stesso sotto il tuo account, e viene cancellato nel
  momento in cui disattivi le notifiche, revochi il dispositivo o esci dall'account. I token morti
  vengono rimossi automaticamente.
- La notifica in sé dice cosa è arrivato — un importo, e il nome di un fan o il titolo di un brano
  se ne hanno lasciato uno. Lo stesso breve elenco è conservato nel **feed della campanella** del
  tuo account, limitato alle cento voci più recenti, così da poter scorrere all'indietro tra ciò
  che è arrivato mentre eri via.
- Sul web, consegnare una push richiede un piccolo **service worker** alla radice del sito e l'SDK
  di messaggistica Firebase, che il tuo browser scarica da Google (`gstatic.com`) la prima volta.
  La push web viene poi trasportata dal servizio push del tuo browser stesso (per Chrome, quello di
  Google). Nulla di tutto ciò viene caricato a meno che tu non abbia attivato le notifiche.
- **Un account ospite e un dispositivo senza account non ricevono alcuna push**, perché una push ha
  bisogno di un account a cui possiamo consegnarla e di un token che hai scelto di dare.

## Dove vive fisicamente tutto questo

Firebase Auth, Cloud Firestore, le nostre Cloud Functions e la chiave Cloud KMS che protegge il tuo
segreto Stripe girano tutti nell'**Unione europea** — il database nella multiregione `eur3` di
Google, le funzioni e il key ring in `europe-west1`. Google agisce come nostro responsabile del
trattamento ai sensi dei
[termini su privacy e sicurezza di Firebase](https://firebase.google.com/support/privacy) e della
propria [privacy policy](https://policies.google.com/privacy). Come qualsiasi grande fornitore,
Google può coinvolgere infrastrutture fuori dall'UE per assistenza e sicurezza; questo è
disciplinato da quei termini, non da noi. Le notifiche push, una volta consegnate a Firebase Cloud
Messaging e al servizio push del tuo browser o telefono, viaggiano sull'infrastruttura di quelle
società per raggiungere il tuo dispositivo.

## Stripe

Quando un fan paga con carta, si trova sulla pagina di pagamento di **Stripe**, non sulla nostra.
Stripe raccoglie e tratta i suoi dati di pagamento come titolare autonomo, ai sensi della
[Privacy Policy di Stripe](https://stripe.com/privacy). Noi non vediamo mai i numeri delle carte.

Come le tue mance ti raggiungono dipende dalla modalità:

- **Senza account**, l'app dell'artista legge le sue mance da Stripe usando la chiave con permessi
  limitati dell'artista stesso — direttamente dal dispositivo a `api.stripe.com`. **Non c'è alcun
  server live.tips su quel percorso.**
- **Con l'accesso effettuato**, la chiave vive sul nostro server (cifrata, come sopra), e Stripe
  segnala ogni mancia al nostro webhook, che la scrive nello storico Firestore di quell'artista
  stesso. **In questa modalità c'è un server live.tips nel percorso** — per i dati della mancia,
  mai per il denaro. Il nome e il messaggio di un fan, se ne ha lasciati, viaggiano con la mancia
  nello storico di quell'artista stesso e si fermano lì.

## Il relay — solo se Revolut, MobilePay o Monzo sono attivi

Le configurazioni solo-Stripe non lo toccano mai.

Revolut, MobilePay e Monzo non offrono ad un'app alcun modo di confermare che un pagamento sia
avvenuto, perciò quelle mance passano attraverso un piccolo relay open source che gestiamo su
**Firebase** — Cloud Functions e Firestore in `europe-west1`, con la pagina delle mance per il
fan servita da **`tip.live.tips/t/<id>`**. Non tocca mai il denaro. Ecco tutto ciò che gestisce.

### Cosa memorizza l'artista

La creazione di una pagina delle mance memorizza il **nome pubblico dell'artista, il suo messaggio
pubblico, la sua valuta e gli identificativi di pagamento che ha scelto di pubblicare** (il suo link
di pagamento Stripe, il nome utente Revolut, il Box ID di MobilePay, il nome utente Monzo) e, se le
richieste di brani sono attive, **il suo elenco pubblico di brani e i relativi prezzi per brano**.
Si tratta comunque tutto di informazioni che l'artista sta deliberatamente pubblicando per i fan.

- **Conservazione: una pagina delle mance senza un account dietro viene cancellata
  automaticamente dopo 90 giorni di inattività.** Una pagina delle mance che appartiene a un
  account con accesso effettuato vive quanto la band a cui appartiene.
- L'artista può cancellarla **immediatamente** dall'app, in qualsiasi momento.
- Non vengono mai raccolti qui indirizzi email, password, nomi legali o dati bancari.
- Il segreto della pagina è memorizzato **solo come hash**. Non potremmo dirti il segreto
  nemmeno se ce lo chiedessi; possiamo soltanto verificarne uno.

### Cosa invia un fan

Il modulo della mancia chiede un **importo** e, facoltativamente, un **nome** e un **messaggio** —
e, per una richiesta di brano, quale brano. Il modulo è tutto qui. Nessuna email, nessun numero di
telefono, nessun account.

Dove va quel testo scritto dal fan, e per quanto tempo, dipende dal fatto che l'artista abbia
effettuato l'accesso:

- **Se dietro la pagina delle mance non c'è alcun account**, la mancia viene scritta in una **coda
  di consegna** — un singolo documento che esiste per essere consegnato allo schermo dell'artista.
  Quando lo schermo mostra la mancia, **il dispositivo dell'artista cancella quel documento.** La
  cancellazione *è* la conferma di ricezione. Se lo schermo dell'artista è offline — telefono
  bloccato, niente segnale — la mancia **resta in quella coda per un massimo di un'ora**, così da
  non andare semplicemente perduta, e passa nel momento in cui lo schermo si riconnette. Se nessuno
  si riconnette, viene **cancellata senza essere vista**, ripulita a intervalli programmati. Per un
  artista senza account, **quella coda è l'unico posto in cui un testo scritto da un fan venga mai
  memorizzato sul nostro server, e un'ora è il suo limite invalicabile.**
- **Se la pagina delle mance appartiene a un account con accesso effettuato**, non c'è alcuna coda.
  Il nostro server scrive la mancia **direttamente nello storico di quell'artista stesso** sotto il
  suo uid — nella sessione di stasera se è in corso un set, oppure nell'archivio della band se non
  lo è. Lì resta **finché resta la band**; è lo storico dell'artista stesso, ed è ciò per cui ha
  effettuato l'accesso. È lo stesso storico in cui scrive il webhook di Stripe, qui sopra.
- Il tuo nome e il tuo messaggio vengono inoltre inseriti nella **causale del pagamento** che si apre
  in Revolut, MobilePay o Monzo — è così che l'artista sa chi ha lasciato la mancia. Quelle società
  li trattano poi secondo le proprie informative sulla privacy.
- Il relay non conserva **alcuno storico delle mance tra artisti diversi**. Non può mostrare a te,
  a noi o a chiunque altro un elenco di chi ha lasciato una mancia a chi tra artisti diversi.

### Indirizzi IP e misure anti-abuso

Un modulo aperto, a cui chiunque può inviare dati, ha bisogno di una qualche protezione dai bot,
perciò:

- Il tuo indirizzo IP viene inviato a **Cloudflare Turnstile** — un controllo anti-bot che gira
  sulla pagina delle mance — per verificare che tu non sia un bot. Turnstile è un prodotto di
  Cloudflare ed è usato al posto di un CAPTCHA che ti profila. Turnstile e il nostro DNS sono le
  uniche cose che Cloudflare fa ancora per noi; il relay in sé ora gira su Firebase. Vedi la
  [Privacy Policy di Cloudflare](https://www.cloudflare.com/privacypolicy/).
- Il tuo IP viene usato anche per **limitare la frequenza** delle richieste — inviare una mancia,
  creare una pagina delle mance, riscattare un codice di aggiunta dispositivo. Ciò che
  memorizziamo per questo è un **hash crittografico dell'IP con sale**, mai l'IP stesso, per circa
  **due ore**, e poi viene eliminato. Il sale è un segreto del server: senza di esso il codice si
  rifiuta di memorizzare alcunché, piuttosto che conservare un hash reversibile.
- I **log operativi di Google** registrano i dettagli tecnici delle richieste al relay — URL,
  tempi, stato — per qualche giorno. Il nostro codice non registra deliberatamente alcun nome,
  alcun messaggio, alcun segreto e alcun header. Google agisce come nostro responsabile del
  trattamento.

### Contatori

Il relay conta **quante mance** ha inoltrato una determinata pagina delle mance, così da poter
individuare gli abusi e sapere se la cosa viene usata o no. È un numero. Non contiene alcun dato
dei fan.

## Chi tratta cosa

| Chi | Cosa riceve | Perché |
| --- | --- | --- |
| **Google (Firebase)** | Gli account, i dati sincronizzati di un artista che ha effettuato l'accesso, la chiave Stripe cifrata, il relay, i token push e la loro consegna, i log del server | L'account facoltativo, il relay facoltativo e le notifiche push |
| **Google Cloud KMS** | La chiave che protegge il segreto Stripe di un artista che ha effettuato l'accesso (mai il segreto in chiaro) | Mantenere illeggibile a riposo la chiave Stripe conservata |
| **Stripe** | I dati di pagamento del fan, come titolare autonomo; e, per un artista che ha effettuato l'accesso, gli eventi delle mance inviati al nostro webhook | Le mance con carta |
| **Cloudflare** | L'IP del fan, per il controllo Turnstile sulla pagina delle mance. E il nostro DNS. | Tenere i bot lontani dal modulo delle mance |
| **GitHub** | L'IP e lo user-agent di chiunque carichi questo sito | L'hosting del sito |
| **Il servizio push del tuo browser / telefono** (per es. quello di Google per Chrome) | Un token push e il contenuto della notifica, se hai attivato le notifiche | Consegnare le notifiche push |
| **Revolut / MobilePay / Monzo** | Tutto ciò che il fan fa nella loro app, causale del pagamento compresa | Quei metodi di pagamento |

Non vendiamo nulla a nessuno, e su quell'elenco non c'è nessun altro.

## Base giuridica, se ti serve (GDPR)

- Far funzionare un account che hai richiesto, sincronizzare i tuoi dati sui tuoi dispositivi,
  custodire la tua chiave Stripe così che le tue mance raggiungano il tuo storico, far funzionare
  il relay per un artista che lo ha attivato, consegnare la mancia di un fan allo schermo a cui era
  destinata e inviare una push che hai attivato: **esecuzione di un servizio che hai richiesto**.
- Limitazione della frequenza, Turnstile, quote basate su IP sottoposto ad hash e revoca dei
  dispositivi: **legittimo interesse** a impedire che un servizio gratuito e aperto venga distrutto
  da bot e frodi, e a mantenere sicuri gli account degli artisti.
- Log del server: **legittimo interesse** a gestire e mettere in sicurezza il servizio.

## Cancellare le cose

Questo conta più di qualsiasi promessa potremmo fare al riguardo, quindi ecco esattamente cosa
esiste oggi — compreso ciò che non esiste.

- **Nessun account**: disinstalla l'app. È tutto, sparito.
- **Una band**: rimuovere una band nell'app cancella i dati cloud di quella band — le sue
  impostazioni, le sue chiavi, le sue sessioni, il suo storico delle mance — insieme alla copia
  sul dispositivo.
- **Una pagina delle mance**: cancellala o rigenerala nell'app e viene spazzata via dal relay
  all'istante, comprese le eventuali mance in attesa.
- **Le notifiche push**: disattivale su un dispositivo e il suo token push viene cancellato. Il
  feed della campanella si svuota insieme alla band o all'account.
- **Un dispositivo**: Impostazioni → Sicurezza elenca i tuoi dispositivi. Puoi revocarne uno, o
  uscire da ogni altro dispositivo — cosa che termina immediatamente la sessione di tutti gli
  altri dispositivi, non prima o poi.
- **L'intero account, con un tocco: nell'app quel pulsante non c'è ancora.** Preferiamo
  ammetterlo piuttosto che far finta di niente. Finché non esisterà, scrivi a
  **[contact@live.tips](mailto:contact@live.tips)** e cancelleremo a mano l'account e tutto ciò
  che vi sta sotto. Nel frattempo puoi già cancellare ogni band, il che rimuove tutto ciò che ha
  sostanza — inclusa la chiave Stripe conservata — e lascia dietro di sé un account vuoto.

## I tuoi diritti

Puoi chiederci di darti una copia, di correggere o di cancellare qualsiasi dato che ti riguardi in
nostro possesso, e puoi presentare un reclamo alla tua autorità nazionale per la protezione dei dati.
Scrivi a **[contact@live.tips](mailto:contact@live.tips)**.

In pratica, la maggior parte di tutto ciò è già nelle tue mani: un artista può cancellare
all'istante una pagina delle mance o una band dall'app, le mance dei fan non consegnate su una
pagina senza account svaniscono nel giro di un'ora e, se non effettui mai l'accesso, nulla di tutto
ciò è mai stato da qualche altra parte che sul tuo dispositivo.

## Minori

live.tips non è rivolto ai minori e non trattiamo consapevolmente i loro dati.

## Modifiche

Aggiorneremo questa pagina quando il software cambia. Poiché l'intero progetto è open source,
**ogni versione passata di questa informativa si trova nella cronologia git pubblica** — puoi
confrontare esattamente cosa è cambiato e quando.

## Lingua

Questa informativa è pubblicata in tutte le lingue supportate dal sito, per comodità. Se una
traduzione e la versione inglese non concordano, **fa fede la versione inglese**.
