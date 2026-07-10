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

## Le mance con carta non passano mai da noi

Quando un fan tocca un importo con carta, il suo browser dialoga con `api.stripe.com`.
Non con un server live.tips: su quel percorso non ce n'è nessuno. Il pagamento viene
creato sul **tuo** account Stripe, si deposita sul **tuo** saldo Stripe e viene versato
secondo il **tuo** calendario Stripe. L'unica commissione è la normale tariffa di
elaborazione di Stripe stessa, che Stripe ti addebita direttamente, esattamente come
farebbe se avessi integrato Stripe da solo.

Dalla nostra parte non c'è alcun registro perché non c'è nulla da annotare. Non
potremmo trattenere una percentuale senza costruire prima ciò che detiene il denaro.

## Le tue chiavi restano tue

La configurazione chiede una chiave API Stripe *con restrizioni*, non una chiave
segreta di produzione: quelle le rifiutiamo senza esitazioni. Viene conservata nel
portachiavi del tuo dispositivo e inviata soltanto a Stripe, sempre tramite TLS.

Con restrizioni significa che la chiave sa fare due cose: creare il link delle mance a
offerta libera e osservare l'arrivo delle mance. Non può leggere il tuo saldo, avviare
versamenti, emettere rimborsi né toccare i dati dei clienti. Se trapelasse domani, il
raggio dell'esplosione è un link delle mance.

## L'unico punto in cui esiste un server

Revolut e MobilePay non si possono pilotare da un browser come si fa con Stripe, quindi
attivarli accende un relay minimo su `api.live.tips`. Vale la pena essere precisi su
cosa fa quel relay, perché «abbiamo aggiunto un backend» è di solito il punto in cui
queste storie prendono una brutta piega.

Conserva il profilo pubblico della tua pagina delle mance: il nome visualizzato e gli
identificativi di pagamento che hai scelto di pubblicare. Tutto qui. Non tiene alcuno
storico delle donazioni, non vede denaro, non custodisce chiavi e si autoelimina dopo
90 giorni di inattività. Il denaro continua a spostarsi direttamente tra l'app Revolut
o MobilePay del tuo fan e la tua.

Se usi solo Stripe, il relay non viene mai contattato affatto.

## Perché non dovresti crederci sulla parola

Tutto quanto sopra è verificabile. Il codice è rilasciato con licenza MIT ed è
pubblico, e il sito è una build statica che GitHub Actions pubblica su GitHub Pages:
nessuna infrastruttura nascosta, niente compilato dietro una porta. Apri la scheda di
rete durante una mancia di prova e leggi le richieste. Sono meno di quante ti aspetti.

È questa la vera promessa del prodotto. Non che siamo affidabili, ma che non hai bisogno
che lo siamo.
