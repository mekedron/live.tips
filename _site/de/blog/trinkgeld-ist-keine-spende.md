# Trinkgeld ist keine Spende — und Stripe behandelt beides als zwei verschiedene Geschäfte

> Ein Straßenmusiker, der nach einem „Spenden-Button" sucht, beschreibt ein Geschäft, das Stripe in weiten Teilen Europas verbietet. Ein Trinkgeld bezahlt eine Leistung, die du bereits erbracht hast; eine Spende ist Spendensammlung für einen gemeinnützigen Zweck. Der Unterschied entscheidet, in welche Kategorie dein Konto fällt — und ein einziger API-Parameter kann die falsche für dich auswählen.

Canonical: https://live.tips/de/blog/trinkgeld-ist-keine-spende/
Published: 2026-07-11
Language: de
Tags: Stripe, donations, busking, compliance, how-to

---

Jedes Werkzeug im Internet will, dass du es Spende nennst. Auf den Buttons steht
*Donate*. In den Blogbeiträgen steht *Spenden-Button für Musiker*. In den
Plugin-Verzeichnissen steht *Spenden annehmen*. Wenn du Musiker bist und einen
Weg suchst, von Leuten bezahlt zu werden, die kein Bargeld dabeihaben, verfolgt
dich dieses Wort überallhin.

Dann eröffnest du ein Stripe-Konto, und Stripe fragt dich, was dein Geschäft
eigentlich macht. Und in diesem Moment hört das Wort auf, Werbetext zu sein, und
wird zu einer **Geschäftskategorie** — einer, die Stripe in weiten Teilen Europas
nicht erlaubt.

Das ist keine Wortklauberei und keine Juristenspitzfindigkeit. Es ist die eine
Frage, die am wahrscheinlichsten dazu führt, dass das Zahlungskonto eines völlig
gewöhnlichen Straßenmusikers geprüft, verzögert oder abgelehnt wird. Fast niemand
hat das für Auftretende einmal klar aufgeschrieben, also hier.

## Zwei Wörter, zwei Geschäfte

Stripe zieht die Linie selbst, in je einem Satz. Aus
[Anforderungen für die Annahme von Trinkgeldern oder Spenden](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations):

> Ein Trinkgeld muss für eine Ware oder Leistung gegeben werden, die erbracht
> wurde (z. B. Inhalte)

> Eine Spende muss an einen bestimmten gemeinnützigen Zweck gebunden sein, den zu
> erfüllen du dich verpflichtest

Stripes Seiten sind auf Englisch; hier stehen die Zitate übersetzt, das Original
liegt hinter dem Link.

Lies die beiden Sätze zweimal, denn alles Weitere in diesem Beitrag folgt aus
ihnen.

Ein **Trinkgeld** blickt zurück auf etwas, das schon geschehen ist. Die Leistung
wurde erbracht, dem Fan hat es gefallen, der Fan hat etwas draufgelegt. Das Geld
ist an keine Bedingung geknüpft, und du schuldest danach nichts mehr. Das ist die
Trinkgeldzeile auf der Restaurantrechnung, die Münzen im Hut, der Fünfer, der
einem nach dem letzten Song in die Hand gedrückt wird.

Eine **Spende** blickt nach vorn auf etwas, das du versprochen hast zu tun. Es
gibt einen Zweck. Es gibt ein Vorhaben, das du demjenigen beschrieben hast, der
dir das Geld gibt. Und — Stripe sagt das ausdrücklich — das Geld muss
tatsächlich diesem Zweck zufließen. Du hältst es treuhänderisch für etwas, das zu
erreichen du zugesagt hast.

Das sind nicht zwei Schattierungen derselben Handlung. Es sind zwei verschiedene
Beziehungen mit zwei verschiedenen Sätzen von Pflichten, und Stripe zeichnet sie
als zwei verschiedene Geschäfte.

## Ein Straßenmusiker steht eindeutig auf der Trinkgeldseite

Du hast zwei Stunden auf einem Platz gestanden und gespielt. Vierzig Leute sind
stehen geblieben. Einer davon scannt deinen Code und schickt dir fünf Euro.

**Das ist ein Trinkgeld.** Der Auftritt ist die Leistung. Sie wurde erbracht — die
Leute haben zugesehen, wie es passierte. Es gibt keinen Zweck, keinen
Begünstigten, kein Vorhaben, zu dessen Erfüllung du dich verpflichtet hättest, und
niemand hat dir Geld für ein Projekt anvertraut. Du bist eine auftretende
Künstlerin, ein auftretender Künstler, und wirst für einen Auftritt bezahlt — eine
der ältesten und unstrittigsten Geschäftsbeziehungen, die es gibt.

Die Verwirrung kommt daher, dass das Trinkgeld eines Straßenmusikers *freiwillig*
ist, und wir sind darauf trainiert, freiwilliges Geld für wohltätiges Geld zu
halten. Ist es nicht. Ein Trinkgeld ist ebenfalls freiwillig. Nicht die
Freiwilligkeit macht etwas zur Spende — ein **gemeinnütziger Zweck** tut das.

Wenn auf deinem Schild also „Spenden willkommen" steht, bist du nicht bescheiden
oder höflich. Du beschreibst, im Vokabular des Zahlungsdienstleisters, ein
Geschäft, in dem du gar nicht tätig bist.

## Was dich das Wort tatsächlich kostet

Hier wird aus der Abstraktion Geld.

Stripe veröffentlicht eine
[Liste eingeschränkter Geschäfte](https://stripe.com/legal/restricted-businesses)
— die Dinge, die du mit einem Stripe-Konto nicht tun darfst oder nur in bestimmten
Ländern. Unter der Überschrift **Crowdfunding und Fundraising** steht wörtlich
diese Zeile:

> Organisationen, die Spenden für einen gemeinnützigen Zweck sammeln (Hinweis:
> Unterstützt in Australien, Kanada, dem Vereinigten Königreich und den
> Vereinigten Staaten. In allen anderen Ländern verboten.)

Lies die Klammer langsam. Spendensammlung für einen gemeinnützigen Zweck ist ein
**in vier Ländern unterstütztes Geschäft** — Australien, Kanada, Großbritannien,
die USA — und **überall sonst verboten.**

Überall sonst, das heißt Deutschland, Österreich, die Schweiz, Frankreich,
Spanien, Italien, die Niederlande, Polen, Finnland und jedes andere Land, in dem
ein Straßenmusiker vernünftigerweise stehen könnte. Wenn du in Berlin, Wien oder
Zürich spielst, bist du geradewegs in „allen anderen Ländern". Der Großteil der
Straßenmusiker dieser Welt lebt dort.

Dieselbe Seite führt auch *„Fundraising durch gemeinnützige Organisationen,
Wohltätigkeitsorganisationen, politische Organisationen und Unternehmen, die eine
Gegenleistung für eine Spende anbieten"* als eingeschränkt auf, und Stripes Seite
zu Trinkgeldern und Spenden legt eine Reihe länderspezifischer Regeln obendrauf:
In Japan dürfen Privatpersonen überhaupt keine Spenden empfangen; in Singapur nur
staatlich registrierte gemeinnützige oder religiöse Organisationen; in Indien,
Hongkong und Thailand werden Spenden nicht unterstützt.

Eine Musikerin in Berlin, die „Spenden für meine Musik" in das
Stripe-Anmeldeformular tippt, hat damit also gerade ein Geschäft beschrieben, das
Stripe in Deutschland verbietet. Nicht weil Straßenmusik verboten wäre —
Straßenmusik ist völlig in Ordnung —, sondern weil die Wörter, die sie gewählt
hat, zu einer Kategorie gehören, die es ist.

## Und jetzt die Einordnung, denn das hier ist keine Horrorgeschichte

**Straßenmusiker sind kein eingeschränktes Geschäft.** Trinkgeld ist kein
eingeschränktes Geschäft. Live-Auftritte stehen nicht auf der Liste, bringen dich
nicht auf die Liste, und sind ungefähr das Gewöhnlichste, was man mit einem
Zahlungskonto anstellen kann. Wenn du dich zutreffend beschreibst, betrifft dich
nichts davon, und die Einrichtung ist langweilig — genau so, wie es sein soll.

Das Risiko hier ist nicht Stripe. Das Risiko ist die **falsche
Selbsteinordnung** — dass du den Raum betrittst und dich als Spendensammler
vorstellst, obwohl du Gitarrist bist. Stripe kann unmöglich wissen, dass du
„bitte gib mir Trinkgeld" gemeint hast. Stripe hat nur das Formular, das du
ausgefüllt hast, die Geschäftsbeschreibung, die du geschrieben hast, und die
Wörter auf der Seite, auf die dein QR-Code zeigt.

Niemand bei Stripe macht Jagd auf Straßenmusiker. Sie lesen schlicht, was du ihnen
selbst gesagt hast.

## Die Falle ist genau einen Parameter tief

Hier kommt der Teil, den fast niemand aufschreibt, und er ist das Nützlichste in
diesem Beitrag.

Stripes Payment Links haben einen Parameter namens `submit_type`. Die
[API-Referenz](https://docs.stripe.com/api/payment-link/object) beschreibt ihn als
etwas beinahe Kosmetisches:

> Gibt die Art der durchgeführten Transaktion an, wodurch der zugehörige Text auf
> der Seite angepasst wird, etwa der Absende-Button.

*Passt den zugehörigen Text an.* Man würde vernünftigerweise schließen, dass das
eine Beschriftung ändert, und dass auf einer Trinkgeldkasse doch wohl eher
'Donate' (spenden) als 'Buy' (kaufen) stehen sollte, denn *Buy* ist ein
merkwürdiges Wort, um es unter den Hut eines Straßenmusikers zu drucken.

Dann liest du, was die einzelnen Werte tatsächlich tun:

> `donate` — Empfohlen für die Annahme von Spenden. Der Absende-Button trägt die
> Beschriftung 'Donate', und die URLs verwenden den Hostnamen `donate.stripe.com`

> `pay` — Der Absende-Button trägt die Beschriftung 'Buy', und die URLs verwenden
> den Hostnamen `buy.stripe.com`

**Es ist keine Beschriftung. Es ist ein Hostname.** Setz `submit_type=donate`, und
der Link, den Stripe dir gibt — der, aus dem du einen QR-Code machst, ihn
ausdruckst und an deinen Gitarrenkoffer klebst — liegt auf `donate.stripe.com`.
Jeder Fan, der ihn scannt, sieht eine Spendenseite. Jede Zahlung in deinem
Dashboard kam durch einen Spendenfluss. Der QR-Code auf deinem Koffer sagt Stripe,
sagt deinem Publikum und irgendwann auch dir selbst, dass du Spenden sammelst.

Du hast das Wort „Spende" nirgendwo hingeschrieben. Ein einziger API-Parameter hat
es für dich geschrieben — und auf ein Plastikschild auf einem öffentlichen Platz
gedruckt.

In diese Falle tappt man leicht, und es ist nicht die Schuld der Lesenden, wenn es
passiert: Der Parameter ist als Textänderung dokumentiert, *Donate* ist
offensichtlich das schönere Wort unter dem Hut eines Straßenmusikers, und die
Folge — eine Geschäftseinstufung — steht zwei Sätze weiter unten, als die meisten
Leute lesen.

live.tips sendet `submit_type=pay`. Der Link jedes Künstlers ist ein
`buy.stripe.com`-Link, und im Code steht ein Kommentar, der erklärt, warum — weil
es die Art Sache ist, die ein künftiger Beitragender sonst „verbessern" würde.

## Was ein Musiker tatsächlich tun sollte

Nichts davon braucht einen Anwalt. Es braucht fünf Minuten und ein paar klare
Wörter.

- **Beschreibe das echte Geschäft** in Stripes Anmeldung. „Live-Musik-Auftritte."
  „Straßenmusiker." „Musikerin — Trinkgelder vom Publikum bei Live-Auftritten."
  Sag, dass du auftrittst und dass die Zahlungen Trinkgelder für diese Auftritte
  sind.
- **Wähle eine passende Kategorie.** Live-Unterhaltung, darstellende Kunst,
  Musiker. Nicht Wohltätigkeit, nicht Gemeinnützigkeit, nicht Fundraising.
- **Nutze `submit_type=pay`**, wenn du den Payment Link selbst baust. Hat ein
  Werkzeug ihn für dich gebaut, schau dir die erzeugte URL an:
  `buy.stripe.com` ist eine Trinkgeldkasse, `donate.stripe.com` ist eine
  Spendenseite. Das ist eine Zwei-Sekunden-Prüfung, und sie sagt dir, wofür dein
  Werkzeug dich hält.
- **Nenn es nicht Spende** — nicht auf dem Schild, nicht auf deiner Website, nicht
  in der Stripe-Geschäftsbeschreibung. „Trinkgeld", „Trinkgeldkasse", „unterstütz
  die Band", „gib uns ein Bier aus" beschreiben alle, was tatsächlich passiert.
  „Spenden" beschreibt etwas anderes.
- **Halte eine echte Spendensammlung getrennt.** Wenn du ein Benefizkonzert
  spielst und das Geld an einen guten Zweck geht, dann *ist* das tatsächlich
  Spendensammlung für einen gemeinnützigen Zweck, und die obigen Regeln gehen dich
  jetzt an — die Länderliste eingeschlossen. Mach das über das richtige Konto, im
  richtigen Land, nachdem du Stripes Bedingungen gelesen hast, und niemals über die
  Trinkgeldkasse, die du an normalen Abenden benutzt.

Der letzte Punkt verdient Nachdruck, denn er ist die ehrliche Hälfte des
Arguments. Wir sagen nicht, Spenden seien schlecht oder Musiker dürften niemals
Geld für einen guten Zweck sammeln. Wir sagen, es ist eine **andere Tätigkeit**,
mit anderen Regeln, und sie klammheimlich durch denselben QR-Code laufen zu
lassen, ist der Weg, mit dem du dir beides verdirbst.

Eine weitere Zeile von Stripes Seite zu Trinkgeldern und Spenden ist es wert,
gekannt zu werden, denn sie schließt ein drittes Ding aus, das Leute mit beidem
verwechseln: Stripe macht keine *„Zahlungsabwicklung für private oder
Peer-to-Peer-Geldübertragung (z. B. Geld unter Freunden schicken)"*. Ein Trinkgeld
ist auch kein Geschenk unter Freunden. Wenn du diese Schiene willst — ein Fan
schickt dir einfach Geld, von Mensch zu Mensch —, dann sind Revolut oder MobilePay
genau das, und deshalb liegen die in unserer App
[vollständig außerhalb von Stripe](https://live.tips/de/blog/ein-qr-code-fuer-jede-zahlungsart/).

## Was dieser Beitrag nicht ist

Er ist keine Rechtsberatung. Er ist keine Steuerberatung — wie Trinkgelder
besteuert werden, ist von Land zu Land, manchmal von Stadt zu Stadt, enorm
verschieden und liegt hier vollkommen außerhalb des Themas; frag jemanden, der
dort qualifiziert ist, wo du lebst.

Und er ist kein Versprechen über dein Konto. **Ob Stripe dich zulässt, ist allein
Stripes Entscheidung.** live.tips hat keine Beziehung zu Stripe, keine Möglichkeit,
eine Prüfung zu beeinflussen, und keinen Weg, für dich Einspruch zu erheben. Was
unsere Software tun kann, ist, dir keine Wörter in den Mund zu legen. Was du auf
das Formular schreibst, schreibst weiterhin du.

Regeln ändern sich außerdem. Die hier zitierten Zeilen standen im Juli 2026 auf
Stripes Seiten, und die Links stehen direkt daneben; geh und lies sie selbst,
statt einem Blogbeitrag zu vertrauen — auch diesem.

## Die Kurzfassung

Du hast das Set gespielt. Sie haben zugesehen. Sie haben dich dafür bezahlt.

Das ist ein Trinkgeld. Sag es so — auf dem Schild, im Formular, in der URL — und
du bekommst genau das langweilige Ergebnis, das du willst. Wir bauen die
Trinkgeldkasse um genau diese Aussage herum, bis hinunter zu
[der Frage, auf welchen Stripe-Hostnamen dein QR-Code zeigt](https://live.tips/de/blog/trinkgeldkasse-auf-deinem-eigenen-stripe-konto/),
und wenn du das größere Bild davon willst, wohin das Geld tatsächlich geht, das
steht [hier](https://live.tips/de/blog/wie-live-tips-mit-geld-umgeht/).
