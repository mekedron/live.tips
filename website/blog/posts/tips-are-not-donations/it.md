---
title: Le mance non sono donazioni — e Stripe le tratta come due attività diverse
description: Un musicista di strada che chiede un «pulsante per le donazioni» sta descrivendo un'attività che Stripe vieta in quasi tutta l'Europa. Una mancia paga un servizio che hai già reso; una donazione è raccolta fondi a scopo benefico. La differenza decide in quale categoria finisce il tuo account — e un solo parametro dell'API può sceglierla al posto tuo, sbagliando.
slug: le-mance-non-sono-donazioni
---

Ogni strumento su internet vuole che tu la chiami donazione. I pulsanti dicono
*Donate*. I post dei blog dicono *pulsante per le donazioni per musicisti*. Gli
elenchi di plugin dicono *accetta donazioni*. Se sei un musicista in cerca di un
modo per farti pagare da gente che non ha contanti, la parola ti insegue ovunque.

Poi apri un account Stripe, e Stripe ti chiede di cosa si occupa la tua attività. E
in quel momento la parola smette di essere un testo pubblicitario e diventa una
**categoria di attività** — una che, in quasi tutta l'Europa, Stripe non consente.

Non è pedanteria, e non è una distinzione da avvocati. È la singola domanda che con
più probabilità manda in revisione, in ritardo o in rifiuto l'account di pagamento
di un musicista di strada del tutto ordinario. Quasi nessuno l'ha scritta in chiaro
per chi fa spettacolo dal vivo, quindi eccola.

## Due parole, due attività

Stripe traccia la linea da sé, in una frase ciascuna. Da
[Requisiti per accettare mance o donazioni](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> una mancia dev'essere data per un bene o un servizio che è stato fornito (ad
> esempio, dei contenuti)

> una donazione dev'essere legata a uno specifico scopo benefico che ti impegni a
> realizzare

Le pagine di Stripe sono in inglese; qui le citazioni sono tradotte, e l'originale
sta dietro il link.

Rileggile due volte, perché tutto il resto di questo post discende da lì.

Una **mancia** guarda indietro, a qualcosa che è già successo. Il servizio è stato
reso, al fan è piaciuto, il fan ha pagato qualcosa in più. Il denaro è
incondizionato e tu non devi più nulla. È la riga della mancia sul conto del
ristorante, le monete nel cappello, i cinque euro messi in mano dopo l'ultima
canzone.

Una **donazione** guarda avanti, a qualcosa che hai promesso di fare. C'è una causa.
C'è uno scopo che hai descritto a chi ti dà il denaro. E — Stripe è esplicito su
questo — il denaro deve davvero andare a quello scopo. Lo stai tenendo in custodia
per una cosa che hai detto che avresti realizzato.

Non sono due sfumature dello stesso gesto. Sono due relazioni diverse, con due
insiemi diversi di obblighi, e Stripe le assicura come due attività diverse.

## Un musicista di strada sta pienamente, senza ambiguità, dalla parte della mancia

Sei stato due ore in una piazza a suonare. Quaranta persone si sono fermate. Una di
loro scansiona il tuo codice e ti manda cinque euro.

**Quella è una mancia.** L'esibizione è il servizio. È stato fornito — l'hanno visto
accadere. Non c'è una causa, non c'è un beneficiario, non c'è uno scopo che ti sei
impegnato a realizzare, e nessuno ti ha affidato del denaro per un progetto. Sei un
artista interprete pagato per un'esibizione, che è uno degli accordi commerciali più
antichi e meno controversi che esistano.

La confusione nasce dal fatto che la mancia di un musicista di strada è *volontaria*,
e siamo stati addestrati a pensare che il denaro volontario sia denaro benefico. Non
lo è. Anche una mancia è volontaria. Non è la volontarietà a fare di una cosa una
donazione — è uno **scopo benefico**.

Quindi quando il tuo cartello dice «donazioni gradite», non stai facendo il modesto o
l'educato. Stai descrivendo, nel vocabolario del processore di pagamenti, un'attività
che non è la tua.

## Quanto ti costa davvero quella parola

Qui l'astrazione diventa denaro.

Stripe pubblica un
[elenco delle attività soggette a restrizioni](https://stripe.com/legal/restricted-businesses)
— le cose che non puoi fare con un account Stripe, o che puoi fare solo in alcuni
paesi. Sotto il titolo **Crowdfunding e raccolta fondi** c'è questa riga, testuale:

> Organizzazioni che raccolgono fondi a scopo benefico (Nota: supportato in
> Australia, Canada, Regno Unito e Stati Uniti. Vietato in tutti gli altri paesi.)

Leggi la parentesi con calma. La raccolta fondi a scopo benefico è un'**attività
supportata in quattro paesi** — Australia, Canada, Regno Unito, Stati Uniti — e
**vietata ovunque altrove.**

Ovunque altrove comprende l'Italia, la Germania, la Francia, la Spagna, i Paesi
Bassi, la Polonia, la Finlandia e ogni altro paese in cui un musicista di strada
possa ragionevolmente trovarsi. Se suoni a Milano, a Roma o a Bologna sei in pieno
dentro «tutti gli altri paesi». La maggior parte degli artisti di strada del mondo
vive lì.

La stessa pagina elenca come soggetta a restrizioni anche la *«raccolta fondi
condotta da organizzazioni non profit, enti benefici, organizzazioni politiche e
imprese che offrono una ricompensa in cambio di una donazione»*, e la pagina di
Stripe su mance e donazioni ci aggiunge sopra una serie di regole per paese: in
Giappone i privati non possono ricevere donazioni affatto; a Singapore possono farlo
solo gli enti benefici o religiosi registrati presso lo Stato; in India, a Hong Kong
e in Thailandia le donazioni non sono supportate.

Così una musicista a Milano che scrive «donazioni per la mia musica» nel modulo di
registrazione di Stripe ha appena descritto un'attività che Stripe vieta in Italia.
Non perché suonare per strada sia proibito — suonare per strada va benissimo — ma
perché le parole che ha scelto appartengono a una categoria che lo è.

## E adesso la giusta misura, perché questa non è una storia dell'orrore

**I musicisti di strada non sono un'attività soggetta a restrizioni.** Le mance non
sono un'attività soggetta a restrizioni. L'esibizione dal vivo non è nell'elenco, non
ti ci farà finire, ed è più o meno la cosa più ordinaria che si possa fare con un
account di pagamento. Se ti descrivi in modo accurato, niente di tutto questo ti
tocca e la configurazione è noiosa, che è esattamente come dev'essere.

Il rischio qui non è Stripe. Il rischio è la **classificazione sbagliata di te
stesso** — entrare nella stanza e presentarti come raccoglitore di fondi benefici
quando sei un chitarrista. Stripe non ha modo di sapere che intendevi «lasciami una
mancia». Ha soltanto il modulo che hai compilato, la descrizione dell'attività che
hai scritto, e le parole sulla pagina a cui punta il tuo codice QR.

Nessuno in Stripe va a caccia di musicisti di strada. Stanno semplicemente leggendo
quello che gli hai detto tu.

## La trappola è profonda un solo parametro

Ecco la parte che quasi nessuno mette per iscritto, ed è la cosa più utile di questo
post.

I Payment Links di Stripe hanno un parametro chiamato `submit_type`. Il
[riferimento dell'API](https://docs.stripe.com/api/payment-link/object) lo descrive
come qualcosa di quasi cosmetico:

> Indica il tipo di transazione che viene eseguita, personalizzando il testo relativo
> sulla pagina, come il pulsante di invio.

*Personalizza il testo relativo.* Ne concluderesti ragionevolmente che cambi
l'etichetta di un pulsante, e che un barattolo delle mance debba ovviamente dire
'Donate' (dona) invece di 'Buy' (compra), perché *Buy* è una parola strana da
stampare sotto il cappello di un musicista di strada.

Poi leggi cosa fanno davvero i singoli valori:

> `donate` — Consigliato quando si accettano donazioni. Il pulsante di invio riporta
> l'etichetta 'Donate' e gli URL usano il nome host `donate.stripe.com`

> `pay` — Il pulsante di invio riporta l'etichetta 'Buy' e gli URL usano il nome host
> `buy.stripe.com`

**Non è un'etichetta. È un nome host.** Imposta `submit_type=donate` e il link che
Stripe ti consegna — quello che trasformi in codice QR, stampi e attacchi alla
custodia della chitarra — vive su `donate.stripe.com`. Ogni fan che lo scansiona vede
una pagina di donazione. Ogni pagamento nella tua dashboard è arrivato da un flusso
di donazione. Il codice QR sulla tua custodia sta dicendo a Stripe, sta dicendo al
tuo pubblico e alla lunga sta dicendo anche a te che stai raccogliendo donazioni.

Tu la parola «donazione» non l'hai scritta da nessuna parte. L'ha scritta per te un
solo parametro dell'API, e l'ha stampata su un cartello di plastica in una piazza
pubblica.

È una trappola facile in cui cadere, e non è colpa di chi legge quando ci cade: il
parametro è documentato come un cambio di testo, *Donate* è chiaramente la parola più
bella da stampare sotto il cappello di un musicista di strada, e la conseguenza — una
classificazione dell'attività — sta due frasi più in basso di dove arriva quasi
chiunque a leggere.

live.tips invia `submit_type=pay`. Il link di ogni artista è un link
`buy.stripe.com`, e nel codice c'è un commento che spiega perché, perché è il tipo di
cosa che altrimenti un futuro contributore andrebbe a «migliorare».

## Cosa dovrebbe fare davvero un musicista

Niente di tutto questo richiede un avvocato. Richiede cinque minuti e qualche parola
chiara.

- **Descrivi l'attività reale** nella registrazione a Stripe. «Esibizioni di musica
  dal vivo.» «Artista di strada.» «Musicista — mance del pubblico durante esibizioni
  dal vivo.» Di' che ti esibisci, e che i pagamenti sono mance per quelle esibizioni.
- **Scegli una categoria che corrisponda.** Intrattenimento dal vivo, arti
  performative, musicista. Non beneficenza, non non profit, non raccolta fondi.
- **Usa `submit_type=pay`** se costruisci tu stesso il Payment Link. Se te l'ha
  costruito uno strumento, guarda l'URL che ha prodotto: `buy.stripe.com` è un
  barattolo delle mance, `donate.stripe.com` è una pagina di donazioni. È un
  controllo da due secondi, e ti dice cosa crede di te il tuo strumento.
- **Non chiamarla donazione** — non sul cartello, non sul tuo sito, non nella
  descrizione dell'attività su Stripe. «Mance», «barattolo delle mance», «sostieni la
  band», «offrici da bere» descrivono tutte quello che sta succedendo. «Dona»
  descrive un'altra cosa.
- **Tieni separata una raccolta fondi vera.** Se suoni a un concerto di beneficenza e
  i soldi vanno a una causa, quella *è* genuinamente raccolta fondi a scopo benefico,
  e le regole qui sopra adesso riguardano te — elenco dei paesi compreso. Fallo con
  l'account giusto, nel paese giusto, dopo aver letto i termini di Stripe, e mai
  attraverso il barattolo delle mance che usi nelle serate normali.

Quest'ultimo punto merita enfasi, perché è la metà onesta dell'argomento. Non stiamo
dicendo che le donazioni siano una cosa brutta o che un musicista non possa mai
raccogliere soldi per una causa. Stiamo dicendo che è un'**attività diversa**, con
regole diverse, e che farla passare in sordina dallo stesso codice QR è il modo per
metterti nei guai su entrambi i fronti.

Vale la pena conoscere un'altra riga dalla pagina di Stripe su mance e donazioni,
perché esclude una terza cosa che si confonde con le altre due: Stripe non fa
*«elaborazione di pagamenti per la trasmissione di denaro personale o peer-to-peer
(ad esempio, mandare soldi tra amici)»*. Neanche una mancia è un regalo tra amici. Se
vuoi quel binario — un fan che ti manda semplicemente dei soldi, da persona a persona
— quello è esattamente ciò che sono Revolut e MobilePay, ed è il motivo per cui nella
nostra app vivono
[interamente fuori da Stripe](post:one-qr-code-every-payment-method).

## Cosa non è questo post

Non è una consulenza legale. Non è una consulenza fiscale — il modo in cui le mance
vengono tassate varia enormemente da paese a paese, a volte da città a città, ed è
completamente fuori dal perimetro di questo testo; chiedi a qualcuno di qualificato
dove vivi.

E non è una promessa sul tuo account. **Se Stripe ti approvi o no è una decisione
soltanto di Stripe.** live.tips non ha alcun rapporto con Stripe, nessuna possibilità
di influenzare una revisione e nessun modo di fare appello al posto tuo. Quello che
il nostro software può fare è evitare di metterti parole in bocca. Quello che scrivi
sul modulo resta tuo da scrivere.

Anche le regole cambiano. Le righe citate qui erano sulle pagine di Stripe a luglio
2026, e i link sono lì; vai a leggerle da te invece di fidarti di un post su un blog,
questo compreso.

## La versione breve

Hai suonato il set. Loro hanno guardato. Ti hanno pagato per quello.

Quella è una mancia. Dillo — sul cartello, nel modulo, nell'URL — e l'esito noioso
che vuoi è esattamente quello che ottieni. Il barattolo delle mance lo costruiamo
attorno a questa precisa affermazione, fin giù
[a quale nome host di Stripe punta il tuo codice QR](post:build-a-tip-jar-on-your-own-stripe),
e se vuoi il quadro più ampio di dove va davvero il denaro, è
[qui](post:how-live-tips-handles-money).
