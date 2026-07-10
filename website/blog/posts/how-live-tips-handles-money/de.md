---
title: Wie live.tips mit Geld umgeht (gar nicht)
description: Es gibt kein live.tips-Guthaben, keinen Auszahlungsplan und keinen Anteil. Hier ist die Architektur, die diese drei Aussagen langweilig statt mutig macht.
slug: wie-live-tips-mit-geld-umgeht
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

## Die eine Stelle, an der ein Server existiert

Revolut und MobilePay lassen sich nicht so aus einem Browser steuern wie Stripe,
deshalb schaltet ihre Aktivierung ein minimales Relay unter `api.live.tips` ein.
Es lohnt sich, genau zu sein, was dieses Relay tut, denn „wir haben ein Backend
hinzugefügt" ist meist die Stelle, an der solche Geschichten schieflaufen.

Es speichert dein öffentliches Trinkgeld-Seiten-Profil – den Anzeigenamen und die
Zahlungs-Handles, die du veröffentlichen wolltest. Mehr nicht. Es führt keine
Spendenhistorie, sieht kein Geld, hält keine Schlüssel und löscht sich nach
90 Tagen Inaktivität selbst. Das Geld bewegt sich weiterhin direkt zwischen der
Revolut- oder MobilePay-App deines Fans und deiner.

Wenn du nur Stripe nutzt, wird das Relay überhaupt nie kontaktiert.

## Warum du uns nicht einfach glauben solltest

All das lässt sich überprüfen. Der Code ist MIT-lizenziert und öffentlich, und die
Seite ist ein statischer Build, den GitHub Actions auf GitHub Pages ausliefert –
keine versteckte Infrastruktur, nichts, das hinter einer Tür kompiliert wird.
Öffne den Netzwerk-Tab während eines Demo-Trinkgelds und lies die Requests. Es
sind weniger, als du erwartest.

Das ist das eigentliche Produktversprechen. Nicht, dass wir vertrauenswürdig sind,
sondern dass wir es nicht sein müssen.
