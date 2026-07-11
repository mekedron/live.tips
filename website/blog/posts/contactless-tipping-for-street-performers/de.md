---
title: Kontaktloses Trinkgeld für Straßenmusiker — ehrlich gerechnet
description: Tap to Pay auf dem Handy, ein Kartenlesegerät, ein NFC-Sticker, ein QR-Code — vier verschiedene Dinge, die alle „kontaktlos" heißen. Was jedes davon 2026 wirklich kostet, was ein NFC-Tag tatsächlich tut (nicht das, was du denkst), und wann Tippen den Scan schlägt.
slug: kontaktloses-trinkgeld-fuer-strassenmusiker
---

Wer nach kontaktlosem Trinkgeld für Straßenmusiker sucht, bekommt vom Internet das
Jahr 2018 serviert. Ein Studentenprototyp der Brunel University namens Tiptap —
ein Ständer, in den man ein Handy steckt — bekam damals eine Runde Presse, und
diese Presse steht bis heute auf Seite eins. Nette Idee. Aber, in den Worten der
Berichterstattung selbst, *noch in der Entwicklungsphase* — und geplant war eine
einmalige Gebühr plus **5 % von jedem Trinkgeld**. Ein Produkt zum Kaufen wurde
daraus nie.

(Das „tiptap", das du heute findest, ist ein völlig anderes Unternehmen aus
Ontario, das kontaktlose Spendenterminals an gemeinnützige Organisationen
verkauft. Gleiches Wort, anderes Produkt, nichts für dich.)

Der ehrliche Stand der Dinge ist also seit acht Jahren nicht aufgeschrieben
worden. Hier ist er.

Das hier ist die Tiefenbohrung zum Tap. Wenn deine eigentliche Frage die größere ist
— wie ein Straßenmusiker überhaupt noch an Geld kommt, jetzt wo niemand mehr Bargeld
dabeihat, und was jeder Weg kostet —, dann fang bei [wie Straßenmusiker
Kartenzahlungen annehmen](post:how-buskers-take-card-payments) an und komm danach
hierher zurück.

## Vier verschiedene Dinge heißen alle „kontaktlos"

Genau hier sitzt die Verwirrung. Trennen wir sie, bevor wir irgendetwas ausrechnen.

1. **Tap to Pay auf dem eigenen Handy.** Dein Telefon wird zum Terminal. Der Fan
   hält seine Karte oder Uhr an *dein* Gerät. Null Zusatzhardware.
2. **Ein Kartenlesegerät** — SumUp, Zettle, Square. Ein kleines Plastikterminal,
   das du hinhältst. Der Fan tippt es an.
3. **Ein NFC-Tag** — der „Hier tippen fürs Trinkgeld"-Sticker. Dieser Punkt wird
   fast durchgehend missverstanden, und der nächste Abschnitt erklärt, warum.
4. **Ein QR-Code.** Im NFC-Sinne nicht kontaktlos — aber lies weiter, denn aus
   Sicht des Fans endet er sehr oft in genau demselben Tippen.

Nur die ersten beiden sind *Zahlungsterminals*. Um diesen Unterschied geht es hier.

## Der NFC-Tag nimmt kein Geld an

Räumen wir das ordentlich ab, denn Anbieter lassen dich gerne im Glauben.

Ein NFC-Sticker — die billige Sorte, der NTAG213-Chip, den die meisten benutzen —
hat **144 Byte Speicher**. Nicht 144 Kilobyte. Er kann keinen Code ausführen, hat
keine Batterie, hat noch nie von einem Kartensystem gehört und könnte ein
Zahlungsprotokoll gar nicht fassen. Was er fasst, ist eine kurze Zeichenkette im
NDEF-Format, und die ist ganz überwiegend eine **URL**.

Antippen — und das Handy öffnet eine Webseite. Das ist die ganze Funktion.

Ein „Tap to Tip"-Schild ist also ein QR-Code, den man durch Berühren statt durch
Zielen öffnet. Dasselbe Ziel, dieselbe Webseite, dieselbe Zahlung im Browser.
Selbst die Spezialisten sagen es, wenn man genau liest: tiptap beschreibt sein
Gerät für frei wählbare Beträge auf der eigenen Seite so, dass Spender, die ihr
Handy daran halten, *„auf deine Online-Spendenseite geleitet werden"*. Geleitet.
Auf eine Seite. Weil ein Tag genau das kann.

Das ist wirklich nützlich, und es ist billig — leere NTAG213-Sticker beginnen im
Paket bei etwa **0,24 $ pro Stück**. Wenn du ohnehin eine Trinkgeld-Seite hast,
kostet ein Tag neben dem gedruckten Code nichts und gibt manchen Fans einen
schnelleren Weg hinein.

Aber sei dir klar darüber, was du gekauft hast: **eine zweite Haustür zur selben
Seite.** Kein Kartenterminal.

### Und draußen ist es eine zickige Haustür

Die Fehlerfälle sind real, und kein Tag-Verkäufer listet sie auf:

- **Das Handy des Fans muss entsperrt und in Benutzung sein.** Apples eigene
  Dokumentation ist eindeutig: Hintergrund-Tag-Lesen passiert nur, während das
  iPhone in Benutzung ist; ist es gesperrt, muss der Nutzer erst entsperren.
- **Es funktioniert nicht, während die Kamera offen ist.** Apple nennt die aktive
  Kamera ausdrücklich als einen Zustand, in dem Hintergrund-Tag-Lesen nicht
  verfügbar ist. Genieß die Ironie: Ein Fan, der die Kamera öffnet, um deinen
  QR-Code zu scannen, hat gerade deinen NFC-Tag abgeschaltet.
- **Es braucht ein iPhone XS oder neuer**, und auf Android muss NFC eingeschaltet
  sein — was manche Energiesparmodi ausschalten.
- **Die Reichweite liegt bei rund 4 cm.** Der Fan muss das Ding tatsächlich
  berühren. In einer Menge, gebückt über einen Gitarrenkoffer, ist das viel
  verlangt.
- **Metall und Magnete töten es.** Ein Tag am Verstärker, oder ein Fan mit
  Magnet-Hülle — und es passiert schlicht nichts.

Ein Tag ist eine schöne zweite Möglichkeit. Als einzige Möglichkeit ist er schlecht.

## Tap to Pay auf dem Handy: die eigentliche Neuigkeit von 2026

Das hier hat sich seit den Tiptap-Artikeln geändert, und keine der veralteten
Berichte weiß davon.

**Tap to Pay auf dem iPhone** macht das Telefon in deiner Tasche zum kontaktlosen
Terminal. Kein Dongle, kein Leser, kein Ständer. Apple führt es in **über 70
Ländern und Regionen**. Die Anbieter, über die es in Europa läuft, sind praktisch
die ganze Branche — allein in Deutschland: Adyen, Commerz Globalpay, Hobex, Mollie,
myPOS, Nexi, PAYONE, Rapyd, Revolut, Sparkassen-Finanzgruppe, Stripe, SumUp,
Viva.com. Großbritannien, Frankreich, die Niederlande, Schweden, Finnland und
Dänemark haben ähnliche Listen. Du brauchst ein iPhone XS oder neuer.

**Tap to Pay auf Android** gibt es auch, aber schmaler. Über Stripe ist es
allgemein verfügbar in AT, AU, BE, CA, CH, DE, DK, FI, FR, GB, IE, IT, MY, NL, NZ,
PL, SE, SG und US, weitere achtzehn Länder sind in der öffentlichen Vorschau. Das
Handy braucht Android 13 oder neuer, einen NFC-Sensor, einen unveränderten
Bootloader, Google Mobile Services — und die Entwickleroptionen müssen aus sein.
Letzteres erwischt mehr Leute, als man denkt.

Praktisch heißt das: **SumUp führt Tap to Pay mit 0 € Hardware.** Mit einem
aktuellen iPhone in einem unterstützten Land kostet der Einstieg in ein
kontaktloses Terminal jetzt genau nichts. Allein diese Tatsache macht jeden
„Kauf-dir-diesen-Ständer"-Artikel von 2018 hinfällig.

## Kartenlesegeräte und was sie wirklich kosten

Wenn du ein eigenes Stück Plastik willst — und es gibt gute Gründe dafür, siehe
unten —, besteht der Markt aus drei Produkten.

| | Hardware | Gebühr pro Zahlung vor Ort |
| --- | --- | --- |
| **SumUp** (DE) | — | **1,39 %**, keine Fixgebühr |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **1,69 %**, keine Fixgebühr |
| **Zettle / PayPal POS** (UK) | Reader ab 29 £ beim ersten Mal, danach 69 £ | **1,75 %**, keine Fixgebühr |
| **Square** (UK) | Kontaktlos-und-Chip-Leser 19 £ | **1,75 %**, keine Fixgebühr |
| **Square** (US) | Kontaktlos-und-Chip-Leser 59 $ | **2,6 % + 0,15 $** |

Preise ohne MwSt., Stand Juli 2026. Prüf sie selbst nach; sie bewegen sich.

Und jetzt lies die Tabelle noch einmal, denn sie sagt etwas, das dem widerspricht,
was dir vermutlich erzählt wurde.

## Die Gebührenrechnung — und was alle falsch herum haben

Die verbreitete Weisheit lautet: Kartengebühren zerstören kleine Trinkgelder wegen
der festen Gebühr pro Transaktion — die 25 Cent, die ein Achtel eines
2-€-Trinkgelds auffressen. Das stimmt, und wir haben
[die Rechnung selbst aufgeschrieben](post:build-a-tip-jar-on-your-own-stripe).

Aber es stimmt für *Online*-Kartenzahlungen. **Europäische kontaktlose Lesegeräte
haben meist gar keine Fixgebühr.** SumUp, Zettle und Square rechnen in der EU und
in Großbritannien rein prozentual ab. Das heißt:

| Ein Trinkgeld von 2 € | Gebühr | Es bleiben | Effektiver Abzug |
| --- | --- | --- | --- |
| SumUp-Leser (DE, 1,39 %) | 0,03 € | 1,97 € | **1,4 %** |
| Zettle / Square (UK, 1,75 %) | 0,04 € | 1,96 € | 1,8 % |
| Stripe, Karte online (EWR, 1,5 % + 0,25 €) | 0,28 € | 1,72 € | **14,0 %** |
| Square-Leser (US, 2,6 % + 0,15 $) | 0,20 $ | 1,80 $ | **10,1 %** |

Rein an der Gebühr gemessen schlägt ein europäisches Tap-Terminal bei einem kleinen
Trinkgeld die Online-Kartenzahlung, und zwar deutlich. Wir sind ein QR-Code-Produkt
und sagen dir das trotzdem: Bei 2 € behältst du mit einem SumUp-Leser 25 Cent, die
eine von Stripe gehostete Seite dir nicht lässt.

Zwei Dinge rücken das wieder zurecht.

**Die Hardware ist die Fixgebühr, nur verschoben.** 25 Cent Ersparnis pro
Trinkgeld gegen einen Solo für 79 £ heißt: rund **dreihundert Zahlungen, bis sich
das Gerät bezahlt gemacht hat**. Für einen arbeitenden Straßenmusiker ist das eine
echte Zahl; für jemanden, der zweimal im Sommer spielt, eine alberne. (Und SumUps
Tap to Pay für 0 € macht daraus null Zahlungen — was genau der Grund ist, warum
diese Option wichtiger ist als die Lesegeräte.)

**Und die USA drehen es wieder um.** Squares amerikanischer Vor-Ort-Tarif trägt
0,15 $ Fixgebühr, ein 2-$-Tap verliert also auch am Terminal ein Zehntel. Das
Geschenk „keine Fixgebühr" ist ein europäisches.

Es gibt außerdem eine Untergrenze: SumUp nimmt keine Zahlung unter **1 £ / 1 €**
an. Welche Schiene du auch wählst — das sehr kleine Trinkgeld ist eigentlich keine
Kartenzahlung.

## Wann schlägt Tippen also den Scan?

Nimm die Technik weg, und es bleibt eine Frage über die Hände des Fans.

**Tippen verlangt, dass sein Handy entsperrt in der Hand liegt — und dass du etwas
hinhältst.** Wenn beides zutrifft, ist es das Schnellste, was der Zahlungsverkehr
zu bieten hat. Keine App, kein Zielen, kein Tippen, in einer Sekunde erledigt.

**Scannen verlangt, dass der Fan die Kamera öffnet** — ein bewusster Handgriff mehr
— aber es verlangt von dir überhaupt nichts. Der Code klebt am Koffer. Er
funktioniert bei jemandem, der hinten steht. Er funktioniert bei vierzig Leuten
gleichzeitig. Er funktioniert, während du noch spielst.

Daraus folgt eine ehrliche Aufteilung:

- **Tippen gewinnt, wenn du zu den Leuten hingehen kannst.** Nach dem Set, Hut
  herum, einer nach dem anderen, du frei, ein Terminal zu halten. Ein Tap ist die
  kleinere Zumutung als „hol mal deine Kamera raus", und in diesem Moment stehst du
  daneben und kannst es abschließen.
- **Scannen gewinnt, wenn du das nicht kannst.** Mitten im Lied. Menge in dritter
  Reihe. Ein Platz, an dem du nicht vom Verstärker weg kannst. Jeder, der im
  Vorbeigehen geben will. Ein Terminal bedient genau eine Person; ein gedruckter
  Code bedient den ganzen Platz gleichzeitig — und du musst zum Bedienen nicht
  aufhören zu spielen.

Der letzte Punkt ist der, den Terminal-Anbieter nie machen, und er ist der größte.
**Ein Kartenleser ist ein Nadelöhr mit Warteschlange.** Ein QR-Code hat keine
Warteschlange.

Und dann ist da noch das, was die halbe Debatte auflöst: Auf einer gut gebauten
Trinkgeld-Seite **endet der Scan ohnehin in einem Tap**. Der Fan scannt, die Seite
öffnet sich, sein Handy bietet Apple Pay oder Google Pay an. Doppelklick, Blick
aufs Display, fertig. Aus Sicht des Fans ist das eine kontaktlose Zahlung — gleiche
Wallet, gleiche Karte, gleiche zwei Sekunden — und du hast dafür keine Hardware
gekauft.

## Wo live.tips steht — und wann du lieber einen SumUp kaufst

[live.tips](https://github.com/mekedron/live.tips) ist eine Trinkgeld-Kasse auf
QR-Basis. Ein Code, der sich nie ändert, und der direkt auf den Stripe-Payment-Link
des Künstlers zeigt. Es gibt kein live.tips-Guthaben, keinen Abzug und keine
Plattform dazwischen — die Gebühr ist Stripes eigene, und Stripe berechnet sie dem
Künstler direkt. Alles MIT-lizenziert, und das Tablet auf der Bühne zeigt jedes
Trinkgeld in dem Moment, in dem es ankommt. Den Geldweg haben wir in
[wie live.tips mit Geld umgeht](post:how-live-tips-handles-money) aufgeschrieben,
und warum es
[ein Code statt einer pro Anbieter](post:one-qr-code-every-payment-method) ist.

Diese Seite unterstützt Apple Pay und Google Pay. live.tips *ist* also kontaktlos —
aus Sicht des Fans, beim Tap, der zählt, und ohne ein Terminal, das man kaufen,
laden oder im Regen fallen lassen kann. Es ist nur eben kein Terminal.

**Wenn du etwas hinhalten willst, das ein Fremder antippt, kauf ein
Kartenlesegerät.** Nimm SumUps Tap to Pay, wenn Handy und Land es hergeben, denn es
kostet nichts; nimm einen Solo, wenn du dein eigenes Handy lieber nicht in eine
Menge hältst. So oder so schlägt es bei 2 € in Europa unsere Gebühr, und wir sagen
das lieber, als so zu tun, als wäre es anders.

Du kannst auch beides machen, und viele Straßenmusiker sollten das: der Code am
Koffer den ganzen Abend, für die Vorbeigehenden, während du spielst — und das
Terminal in der Hand für die zehn Sekunden nach dem letzten Akkord, wenn die erste
Reihe in die Tasche greift. Die beiden konkurrieren nicht. Sie fangen verschiedene
Leute auf.

Was keines von beiden ist: ein Ständer von 2018, der 5 % nimmt.

Gebühren, Hardwarepreise und Länderverfügbarkeit wie von Apple, Stripe, SumUp, Zettle/PayPal und Square im Juli 2026 veröffentlicht, ohne MwSt. NFC-Sticker-Preise von GoToTags. Tiptaps Konditionen von 2018 nach Brunel University und Finextra. All das ändert sich; prüf es beim Anbieter, bevor du Geld ausgibst.
{: .footnote }
