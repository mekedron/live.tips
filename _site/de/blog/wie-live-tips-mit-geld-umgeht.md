# Wie live.tips mit Geld umgeht (gar nicht)

> Es gibt kein live.tips-Guthaben, keinen Auszahlungsplan und keinen Anteil. Hier ist die Architektur, die diese drei Aussagen langweilig statt mutig macht.

Canonical: https://live.tips/de/blog/wie-live-tips-mit-geld-umgeht/
Published: 2026-07-02
Updated: 2026-07-13
Language: de
Tags: Stripe, privacy, open source

---

Jede Trinkgeld-Kasse kann „0 % Gebühr" auf ihre Landingpage schreiben. Die
interessante Frage ist, was die Software tun müsste, um *anzufangen*, einen Anteil
zu nehmen – und wie viel davon du sehen könntest.

Bei live.tips lautet die Antwort: Sie müsste neu gebaut werden. Das ist kein
Versprechen über unsere Absichten, sondern eine Beschreibung dessen, wohin das
Geld geht.

## Karten-Trinkgeld läuft nie über uns

Wenn ein Fan auf einen Kartenbetrag tippt, spricht sein Browser mit
`api.stripe.com`. Nicht mit einem live.tips-Server – in diesem Pfad gibt es keinen.
Die Zahlung wird auf **deinem** Stripe-Konto angelegt, landet in **deinem**
Stripe-Guthaben und wird nach **deinem** Stripe-Zeitplan ausgezahlt. Die einzige
Gebühr ist Stripes eigene Standard-Bearbeitungsgebühr, die Stripe dir direkt
berechnet – genau so, wie es wäre, wenn du Stripe selbst eingebunden hättest.

Auf unserer Seite gibt es kein Kassenbuch, weil es nichts zu verbuchen gibt. Wir
könnten keinen Prozentsatz abschöpfen, ohne zuerst das zu bauen, was das Geld hält.

## Deine Schlüssel bleiben deine

Die Einrichtung verlangt einen *eingeschränkten* Stripe-API-Schlüssel, keinen
Live-Secret-Key – die lehnen wir rundweg ab. Er wird im Schlüsselbund deines
eigenen Geräts gespeichert und nur über TLS an Stripe gesendet.

Eingeschränkt heißt, der Schlüssel kann zwei Dinge: den
Zahl-was-du-willst-Trinkgeld-Link erstellen und beobachten, wie Trinkgeld
eintrifft. Er kann dein Guthaben nicht lesen, keine Auszahlungen auslösen, keine
Rückerstattungen veranlassen und keine Kundendaten anrühren. Würde er morgen
durchsickern, reicht der Schaden gerade bis zu einem Trinkgeld-Link.

## Der eine Server im Zahlungsweg

Revolut und MobilePay lassen sich nicht so aus einem Browser steuern wie Stripe,
deshalb schaltet ihre Aktivierung ein minimales Relay ein – eine Handvoll
Firebase-Funktionen, die deine Trinkgeld-Seite unter `tip.live.tips` ausliefern.
Es lohnt sich, genau zu sein, was dieses Relay tut, denn „wir haben ein Backend
hinzugefügt" ist meist die Stelle, an der solche Geschichten schieflaufen.

Es speichert dein öffentliches Trinkgeld-Seiten-Profil – den Anzeigenamen und die
Zahlungs-Handles, die du veröffentlichen wolltest. Mehr nicht. Es führt keine
Trinkgeld-Historie, sieht kein Geld, hält keine Schlüssel und löscht sich nach
90 Tagen Inaktivität selbst. Ein Revolut- oder MobilePay-Trinkgeld wartet dort nur,
bis dein Bühnengerät es abholt: Es anzuzeigen löscht es, und was niemand abgeholt
hat, wird binnen einer Stunde weggeräumt. Das Geld bewegt sich weiterhin direkt
zwischen der Revolut- oder MobilePay-App deines Fans und deiner.

Wenn du nur Stripe nutzt, wird das Relay überhaupt nie kontaktiert.

## Das Konto, das du nicht anlegen musst

Die App startet weiterhin in ein gerätelokales Profil – genau das, was sie immer
war: deine Trinkgeld-Kasse, dein Schlüssel und deine Trinkgeld-Historie liegen auf
dem Gerät und sonst nirgends. Es gibt nichts, wofür man sich anmelden müsste.

Sich anzumelden – mit Apple, mit Google oder als Gast – ist jetzt möglich, und es
gibt das aus genau einem Grund: ein zweites Gerät. Wenn das Tablet auf der Bühne und
das Telefon in deiner Tasche denselben Abend zeigen sollen, muss etwas dazwischen
sitzen, und dieses Etwas ist Firestore, unter einer Nutzer-ID, die nur du lesen
kannst. Deine Bands, Einstellungen, der eingeschränkte Schlüssel und die
Trinkgeld-Historie werden dorthin synchronisiert. Das ist eine echte Änderung an der
Datenschutz-Geschichte, und sie gehört klar gesagt statt entdeckt: Ohne Konto sieht
nie ein Server ein Trinkgeld; mit Konto sieht es deine eigene Ecke von unserem. Das
ist der Preis für das zweite Gerät, und es liegt bei dir, ihn zu zahlen oder
abzulehnen. Was es nie anrührt, ist das Geld – ein Konto verschiebt deine Daten,
nicht dein Guthaben, und einen Anteil gibt es weiterhin nicht.

## Warum du uns nicht einfach glauben solltest

All das lässt sich überprüfen. Der Code ist MIT-lizenziert und öffentlich, und die
Seite ist ein statischer Build, den GitHub Actions auf GitHub Pages ausliefert –
keine versteckte Infrastruktur, nichts, das hinter einer Tür kompiliert wird.
Öffne den Netzwerk-Tab während eines Demo-Trinkgelds und lies die Requests. Es
sind weniger, als du erwartest.

Das ist das eigentliche Produktversprechen. Nicht, dass wir vertrauenswürdig sind,
sondern dass wir es nicht sein müssen.
