---
title: Come live.tips gestisce il denaro (non lo fa)
description: Non c'è nessun saldo live.tips, nessun calendario di pagamento e nessuna trattenuta. Ecco l'architettura che rende queste tre affermazioni noiose anziché coraggiose.
slug: come-live-tips-gestisce-denaro
---

Qualsiasi barattolo delle mance può scrivere «0% di commissioni» sulla propria pagina
iniziale. La domanda interessante è cosa dovrebbe fare il software per *iniziare* a
prendersi una parte, e quanto ne potresti vedere.

Per live.tips la risposta è: andrebbe ricostruito. Non è una promessa sulle nostre
intenzioni, è una descrizione di dove va il denaro.

## Il denaro non passa mai da noi

Quando un fan tocca un importo con carta, il pagamento viene creato sul **tuo** account
Stripe, si deposita sul **tuo** saldo Stripe e viene versato secondo il **tuo** calendario
Stripe. L'unica commissione è la normale tariffa di elaborazione di Stripe stessa, che
Stripe ti addebita direttamente, esattamente come farebbe se avessi integrato Stripe da
solo.

Dalla nostra parte non c'è alcun registro perché non c'è nulla da annotare. Non
potremmo trattenere una percentuale senza costruire prima ciò che detiene il denaro — e
una cosa del genere non esiste.

Questo vale che tu effettui l'accesso oppure no. Ciò che l'accesso cambia è il percorso
dei *dati*, non quello del denaro, e le prossime due sezioni sono oneste su come,
esattamente.

## Le tue chiavi, e dove vivono

La configurazione chiede una chiave API Stripe *con restrizioni*, non una chiave
segreta di produzione: quelle le rifiutiamo senza esitazioni. Con restrizioni significa
che la chiave sa fare due cose: creare il link delle mance a offerta libera e osservare
l'arrivo delle mance. Non può leggere il tuo saldo, avviare versamenti, emettere rimborsi
né toccare i dati dei clienti. Se trapelasse domani, il raggio dell'esplosione è un link
delle mance.

**Senza account, quella chiave non lascia mai il tuo dispositivo.** Sta nel portachiavi
del dispositivo stesso e viene inviata soltanto a `api.stripe.com`, sempre tramite TLS.
Non c'è alcun server live.tips in gioco.

**Quando effettui l'accesso, la chiave si sposta da noi** — perché una chiave che esiste
solo su un telefono non può servire anche il tablet sul palco. La cifriamo (una chiave
AES-256 per singolo segreto, a sua volta protetta da Google Cloud KMS) e la conserviamo
dove nulla può rileggerla: né un altro account, né noi dando un'occhiata a un database,
e nemmeno tu. Viene aperta soltanto all'interno delle nostre funzioni, usata per dialogare
con Stripe per tuo conto, e mai più consegnata a un dispositivo. Detto chiaramente:
accedere mette un server live.tips nel percorso tra Stripe e il tuo storico delle mance.
Mai il denaro — i dati.

## I server, e cosa non possono fare

Sono due, ed entrambi sono minimi.

**Il relay** esiste perché Revolut e MobilePay non si possono pilotare da un browser come
si fa con Stripe. Attivarli accende una manciata di funzioni Firebase che servono la tua
pagina delle mance su `tip.live.tips`. Conserva il profilo pubblico della tua pagina delle
mance — il nome visualizzato e gli identificativi di pagamento che hai scelto di pubblicare
— e, per una pagina senza un account dietro, non tiene alcuno storico delle mance: una
mancia resta in attesa soltanto finché il tuo dispositivo sul palco non la mostra, e tutto
ciò che nessuno è tornato a prendere viene spazzato via entro un'ora. Non vede denaro e si
autoelimina dopo 90 giorni di inattività. Se usi solo Stripe e non effettui mai l'accesso,
il relay non viene mai contattato affatto.

**Il webhook** esiste soltanto una volta che effettui l'accesso. Poiché la tua chiave ora
vive da noi, Stripe segnala ogni mancia a una nostra piccola funzione, che la scrive nel
tuo storico perché i tuoi altri dispositivi possano mostrarla. È una copia di un evento,
non una copia del denaro. Non può spostare un centesimo e può scrivere soltanto nell'unico
account a cui appartiene.

Nessuno dei due server può prendersi una parte, perché nessuno dei due è vicino al denaro.
Il massimo che ciascuno può fare è guastarsi — e una configurazione solo-Stripe e senza
account non dipende da nessuno dei due.

## L'account che non sei obbligato a creare

L'app si avvia ancora su un profilo locale al dispositivo, esattamente com'è sempre
stato: il tuo barattolo delle mance, la tua chiave e il tuo storico delle mance vivono
sul dispositivo e da nessun'altra parte. Non c'è niente a cui iscriversi.

Accedere — con Apple, con Google o come ospite — ora è possibile, ed esiste per un
motivo soltanto: un secondo dispositivo. Se il tablet sul palco e il telefono che hai
in tasca devono mostrare la stessa serata, qualcosa deve pur stare in mezzo, e quel
qualcosa è Firestore, sotto un id utente che solo tu puoi leggere. Le tue band, le tue
impostazioni, lo storico delle mance — e, cifrata come sopra, la tua chiave Stripe —
vivono lì. È un cambiamento reale nella storia della privacy e merita di essere detto
chiaramente anziché scoperto per caso: senza un account nessun server vede mai una
mancia; con un account il tuo angolo del nostro la vede, ed è il nostro webhook a
scriverla lì. È il prezzo del secondo dispositivo, e sta a te pagarlo o rifiutarlo. Ciò
che non tocca mai è il denaro: un account sposta i tuoi dati, non il tuo saldo, e non c'è
comunque nessuna trattenuta.

## Perché non dovresti crederci sulla parola

Tutto quanto sopra è verificabile. Il codice è rilasciato con licenza MIT ed è
pubblico, e il sito è una build statica che GitHub Actions pubblica su GitHub Pages:
nessuna infrastruttura nascosta, niente compilato dietro una porta. Apri la scheda di
rete durante una mancia di prova e leggi le richieste. Sono meno di quante ti aspetti.

È questa la vera promessa del prodotto. Non che siamo affidabili, ma che non hai bisogno
che lo siamo.
