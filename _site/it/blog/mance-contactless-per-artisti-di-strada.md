# Mance contactless per artisti di strada, onestamente

> Tap to Pay sul telefono, un lettore di carte, un adesivo NFC, un codice QR — quattro cose diverse che vengono tutte chiamate «contactless». Quanto costa davvero ciascuna nel 2026, cosa fa realmente un tag NFC (non è quello che pensi) e quando un tap batte una scansione.

Canonical: https://live.tips/it/blog/mance-contactless-per-artisti-di-strada/
Published: 2026-07-11
Language: it
Tags: contactless, NFC, QR codes, Tap to Pay, fees

---

Cerca «mance contactless per artisti di strada» e internet ti riconsegna il 2018. Un
prototipo studentesco della Brunel University chiamato Tiptap — un supporto in cui
infili un telefono — ebbe il suo giro di stampa quell'anno, e quella stampa sta
ancora in prima pagina. Era una bella idea. Era anche, per usare le parole della
copertura stessa, *ancora in fase di sviluppo*, e prevedeva di far pagare ai
musicisti di strada una quota una tantum più il **5% di ogni mancia**. Non è mai
diventata qualcosa che puoi comprare.

(Il «tiptap» che trovi se vai a cercarlo oggi è un'azienda dell'Ontario che non
c'entra nulla e vende terminali per donazioni contactless alle organizzazioni
benefiche. Stessa parola, prodotto diverso, non fa per te.)

Così lo stato onesto delle cose è rimasto otto anni senza che nessuno lo scrivesse.
Eccolo.

Questo è l'approfondimento sul tap. Se la tua domanda vera è quella più larga —
tutti i modi di farsi pagare ora che nessuno ha contanti, e quanto costa ognuno —,
parti da [come gli artisti di strada incassano con la
carta](https://live.tips/it/blog/pagamenti-con-carta-artisti-di-strada/) e poi torna qui.

## Quattro cose diverse si chiamano tutte «contactless»

È qui che vive quasi tutta la confusione, quindi separiamole prima di mettere un
prezzo a qualsiasi cosa.

1. **Tap to Pay sul tuo telefono.** Il telefono diventa il terminale. Il fan avvicina
   la sua carta o il suo orologio al *tuo* apparecchio. Zero hardware in più.
2. **Un lettore di carte** — un SumUp, uno Zettle, un Square. Un piccolo terminale di
   plastica che porgi. Il fan lo tocca.
3. **Un tag NFC** — l'adesivo o la targhetta «tocca qui per lasciare una mancia».
   Questo viene frainteso quasi universalmente, e la sezione seguente spiega perché.
4. **Un codice QR.** Non contactless nel senso NFC — ma continua a leggere, perché dal
   lato del fan finisce molto spesso esattamente nello stesso tap.

Solo i primi due sono *terminali di pagamento*. Tutto questo articolo sta in quella
distinzione.

## Il tag NFC non incassa un pagamento

Chiudiamola per bene, perché i venditori sono felicissimi di lasciarti credere il
contrario.

Un adesivo NFC — quello economico, il chip NTAG213 che usa la maggior parte di loro —
ha **144 byte di memoria**. Non 144 kilobyte. Non può eseguire codice, non ha
batteria, non ha mai sentito parlare di un circuito di carte e non potrebbe contenere
un protocollo di pagamento nemmeno volendo. Quel che contiene è una stringa breve,
formattata come record NDEF, e in modo schiacciante quella stringa è un **URL**.

Lo tocchi e il telefono apre una pagina web. È tutta qui la funzione.

Il che significa che una targhetta «tap to tip» è un codice QR che apri toccando
invece che inquadrando. Stessa destinazione, stessa pagina web, stesso pagamento che
avviene nel browser. Lo dicono perfino gli specialisti, se li leggi con attenzione:
il sito di tiptap descrive il proprio dispositivo a importo libero dicendo che
*«quando i donatori avvicinano il telefono a un dispositivo di donazione
personalizzato, vengono indirizzati alla tua pagina di raccolta fondi online»*.
Indirizzati a una pagina. Perché è questo che un tag sa fare.

È genuinamente utile, ed è anche economico — gli adesivi NTAG213 vergini partono da
circa **0,24 $ l'uno** in confezione. Se hai già una pagina delle mance, attaccare un
tag sulla custodia accanto al codice stampato ti costa spiccioli e dà ad alcuni fan
una via d'ingresso più rapida.

Ma sii chiaro su cosa hai comprato: **una seconda porta d'ingresso alla stessa
pagina.** Non una macchinetta per le carte.

### E all'aperto è una porta d'ingresso capricciosa

I modi in cui fallisce sono reali, e nessuno che venda tag li elenca:

- **Il telefono del fan deve essere sbloccato e in uso.** La documentazione di Apple è
  esplicita: la lettura dei tag in background avviene solo mentre l'iPhone è in uso, e
  se il telefono è bloccato il sistema gli fa sbloccare prima.
- **Non funziona mentre la fotocamera è aperta.** Apple elenca la fotocamera in uso
  come uno degli stati in cui la lettura dei tag in background non è disponibile.
  Assapora l'ironia: un fan che tira fuori la fotocamera per scansionare il tuo codice
  QR ha appena disattivato il tuo tag NFC.
- **Serve un iPhone XS o successivo**, e su Android serve l'NFC acceso — che alcune
  modalità di risparmio energetico spengono.
- **La portata è di circa 4 cm.** Il fan deve toccare davvero l'oggetto. In mezzo alla
  folla, chinandosi su una custodia di chitarra, è una bella pretesa.
- **Metallo e magneti lo uccidono.** Un tag attaccato all'amplificatore, o un fan con
  una custodia magnetica, e non succede assolutamente nulla.

Un tag è una bella seconda opzione. È una pessima unica opzione.

## Tap to Pay sul telefono: la vera notizia del 2026

Ecco la cosa che è cambiata dai tempi degli articoli su Tiptap, e di cui nessuna di
quelle vecchie coperture sa niente.

**Tap to Pay su iPhone** trasforma il telefono che hai già in tasca in un terminale
contactless. Nessun dongle, nessun lettore, nessun supporto. Apple lo dà disponibile
in **oltre 70 paesi e regioni**, e i fornitori attraverso cui puoi usarlo in Europa
sembrano l'intero settore — solo in Germania: Adyen, Mollie, myPOS, Nexi, PAYONE,
Rapyd, Revolut, Sparkassen, Stripe, SumUp, Viva.com. Regno Unito, Francia, Paesi
Bassi, Svezia, Finlandia e Danimarca hanno elenchi simili. Ti serve un iPhone XS o
successivo.

**Tap to Pay su Android** esiste anch'esso, ma è più stretto. Tramite Stripe è
generalmente disponibile in AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL,
NZ, PL, SE, SG e US, con altri diciotto paesi in anteprima pubblica. Il telefono ha
bisogno di Android 13 o successivo, di un sensore NFC, di un bootloader non
sbloccato, dei Google Mobile Services e delle opzioni sviluppatore disattivate —
quest'ultima frega più gente di quanta immagini.

In pratica: **SumUp mette Tap to Pay a 0 £ di hardware.** Se hai un iPhone recente e
sei in un paese supportato, il costo d'ingresso per porgere un terminale contactless
adesso è zero. Questo fatto da solo rende obsoleto ogni articolo del 2018 che ti dice
«compra questo supporto».

## I lettori di carte, e quanto costano davvero

Se vuoi un pezzo di plastica a parte — e ci sono buoni motivi, più sotto — il mercato
è fatto di tre prodotti.

| | Hardware | Commissione per pagamento di persona |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69%**, nessuna quota fissa |
| **SumUp** (Germania) | — | **1,39%**, nessuna quota fissa |
| **Zettle / PayPal POS** (UK) | Lettore da 29 £ al primo acquisto, 69 £ dopo | **1,75%**, nessuna quota fissa |
| **Square** (UK) | Lettore contactless e chip 19 £ | **1,75%**, nessuna quota fissa |
| **Square** (US) | Lettore contactless e chip 59 $ | **2,6% + 0,15 $** |

Prezzi IVA esclusa, come pubblicati a luglio 2026. Vai a controllarli; si muovono.

Ora rileggi quella tabella, perché dice una cosa che contraddice quello che ti hanno
probabilmente raccontato.

## Il conto delle commissioni, e la cosa che tutti prendono al contrario

La saggezza corrente dice che le commissioni delle carte distruggono le mance piccole
per via dell'addebito fisso per transazione — i venticinque centesimi che si mangiano
un ottavo di una mancia da 2 €. È vero, e
[il conto ce lo siamo scritto da soli](https://live.tips/it/blog/costruisci-un-barattolo-delle-mance-sul-tuo-account-stripe/).

Ma è vero dei pagamenti con carta *online*. **I lettori contactless europei per lo
più non hanno alcuna quota fissa.** SumUp, Zettle e Square nel Regno Unito e nell'UE
sono a sola percentuale. Il che significa:

| Una mancia da 2 € | Commissione | All'artista restano | Prelievo effettivo |
| --- | --- | --- | --- |
| Lettore SumUp (DE, 1,39%) | 0,03 € | 1,97 € | **1,4%** |
| Zettle / Square (UK, 1,75%) | 0,04 € | 1,96 € | 1,8% |
| Stripe, carta online (SEE, 1,5% + 0,25 €) | 0,28 € | 1,72 € | **14,0%** |
| Lettore Square (US, 2,6% + 0,15 $) | 0,20 $ | 1,80 $ | **10,1%** |

Sulla sola commissione, un terminale contactless europeo batte un pagamento con carta
online su una mancia piccola, e non è nemmeno vicino. Siamo un prodotto a codice QR e
te lo diciamo lo stesso: su una mancia da 2 €, un lettore SumUp ti tiene in tasca
0,25 € che una pagina ospitata da Stripe non ti lascia.

Due cose rimettono la cosa in proporzione.

**L'hardware è la quota fissa, solo spostata.** Un risparmio di 0,25 € a mancia
contro un Solo da 79 £ significa circa **trecento tap prima che il lettore si sia
ripagato**. È un numero reale per un musicista di strada che lavora, e un numero
ridicolo per chi suona due volte l'estate. (E il Tap to Pay a 0 £ di SumUp lo porta a
zero tap — ed è esattamente per questo che quell'opzione conta più dei lettori.)

**E gli Stati Uniti ribaltano tutto.** La tariffa americana di persona di Square porta
con sé 0,15 $ di quota fissa, quindi anche un tap da 2 $ perde un decimo di sé al
terminale. Il regalo «nessuna quota fissa» è europeo.

C'è anche un pavimento che incontrerai: SumUp non accetta un pagamento sotto **1 £ /
1 €**. Qualunque binario tu scelga, la mancia molto piccola non è davvero una
transazione con carta.

## Allora, quando un tap batte una scansione?

Togli la tecnologia e resta una domanda sulle mani del fan.

**Un tap richiede che il telefono del fan sia sbloccato e in mano, e richiede che tu
stia porgendo qualcosa.** Quando entrambe le cose sono vere, è la cosa più veloce che
i pagamenti abbiano. Nessuna app, nessuna inquadratura, niente da digitare, fatto in
un secondo.

**Una scansione richiede che il fan apra una fotocamera** — un atto deliberato in più
— ma non richiede niente da te. Il codice sta sulla custodia. Funziona con un fan
rimasto in fondo. Funziona con quaranta persone insieme. Funziona mentre tu stai
ancora suonando.

Da cui una divisione onesta:

- **Il tap vince quando puoi andare dalle persone.** Fine del set, giro col cappello,
  un fan alla volta, tu libero di reggere un terminale. Un tap è una richiesta con
  meno attrito di «tira fuori la fotocamera», e in quel momento sei fisicamente lì a
  chiuderla.
- **La scansione vince quando non puoi.** A metà canzone. Una folla su tre file. Una
  postazione da cui non puoi allontanarti dall'amplificatore. Chiunque voglia dare
  mentre passa. Un terminale serve esattamente una persona; un codice stampato serve
  tutta la piazza, contemporaneamente, e non ha bisogno che tu smetta di suonare per
  servirlo.

Quest'ultimo punto è quello che i venditori di terminali non fanno mai, ed è il più
grosso. **Un lettore di carte è un collo di bottiglia con la fila.** Un codice QR non
ha fila.

Ed ecco la parte che dissolve metà della discussione: su una pagina delle mance fatta
bene, **la scansione finisce comunque in un tap**. Il fan scansiona, la pagina si
apre, e il suo telefono gli propone Apple Pay o Google Pay. Doppio clic, avvicina il
telefono al viso, fatto. Dal lato del fan quello è un pagamento contactless — stesso
wallet, stessa carta, stessi due secondi — e tu non hai comprato alcun hardware per
farlo accadere.

## Dove sta live.tips, e quando invece conviene comprare un SumUp

[live.tips](https://github.com/mekedron/live.tips) è un barattolo delle mance basato
su QR. Un codice, che non cambia mai, che punta dritto al link di pagamento Stripe
dell'artista. Non c'è un saldo live.tips, non c'è una quota e non c'è una piattaforma
lungo il percorso — la commissione è quella di Stripe, e Stripe la addebita
direttamente all'artista. È rilasciato con licenza MIT, e il tablet sul palco mostra
ogni mancia nel momento in cui atterra. Abbiamo scritto il percorso del denaro in
[come live.tips gestisce il denaro](https://live.tips/it/blog/come-live-tips-gestisce-denaro/), e perché è
[un codice solo invece di uno per fornitore](https://live.tips/it/blog/un-qr-code-tutti-metodi-pagamento/).

Quella pagina supporta Apple Pay e Google Pay. Quindi live.tips *è* contactless dal
lato del fan — il tap che conta, quello alla fine, senza un terminale da comprare,
caricare o far cadere sotto la pioggia. Semplicemente non è un terminale.

**Se quello che vuoi è porgere fisicamente qualcosa e far sì che uno sconosciuto lo
tocchi, compra un lettore di carte.** Prendi il Tap to Pay di SumUp se il telefono e
il paese lo permettono, perché non costa niente; prendi un Solo se preferisci non
mettere il tuo telefono in mano a una folla. In ogni caso, su un tap da 2 € in Europa
batterà la nostra commissione, e preferiamo dirlo che far finta di niente.

Puoi anche fare entrambe le cose, e parecchi artisti di strada dovrebbero: il codice
attaccato alla custodia tutta la sera, a raccogliere i passanti mentre suoni, e il
terminale in mano per i dieci secondi dopo l'ultimo accordo, quando la prima fila
infila la mano in tasca. Non sono in concorrenza. Prendono persone diverse.

Quello che nessuno dei due è: un supporto del 2018 che si prende il 5%.

Commissioni, prezzi dell'hardware e disponibilità per paese come pubblicati da Apple, Stripe, SumUp, Zettle/PayPal e Square a luglio 2026, IVA esclusa. Prezzi degli adesivi NFC da GoToTags. Le condizioni di Tiptap del 2018 come riportate dalla Brunel University e da Finextra. Tutto qui dentro cambia; verificalo presso il venditore prima di spendere soldi.
{: .footnote }
