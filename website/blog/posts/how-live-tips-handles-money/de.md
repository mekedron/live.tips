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

## Geld läuft nie über uns

Wenn ein Fan auf einen Kartenbetrag tippt, wird die Zahlung auf **deinem**
Stripe-Konto angelegt, landet in **deinem** Stripe-Guthaben und wird nach **deinem**
Stripe-Zeitplan ausgezahlt. Die einzige Gebühr ist Stripes eigene
Standard-Bearbeitungsgebühr, die Stripe dir direkt berechnet – genau so, wie es
wäre, wenn du Stripe selbst eingebunden hättest.

Auf unserer Seite gibt es kein Kassenbuch, weil es nichts zu verbuchen gibt. Wir
könnten keinen Prozentsatz abschöpfen, ohne zuerst das zu bauen, was das Geld hält –
und so etwas gibt es nicht.

Das gilt, ob du dich anmeldest oder nicht. Was die Anmeldung ändert, ist der
*Daten*pfad, nicht der *Geld*pfad, und die nächsten beiden Abschnitte sind ehrlich
darüber, wie genau.

## Deine Schlüssel, und wo sie liegen

Die Einrichtung verlangt einen *eingeschränkten* Stripe-API-Schlüssel, keinen
Live-Secret-Key – die lehnen wir rundweg ab. Eingeschränkt heißt, der Schlüssel kann
zwei Dinge: den Zahl-was-du-willst-Trinkgeld-Link erstellen und beobachten, wie
Trinkgeld eintrifft. Er kann dein Guthaben nicht lesen, keine Auszahlungen auslösen,
keine Rückerstattungen veranlassen und keine Kundendaten anrühren. Würde er morgen
durchsickern, reicht der Schaden gerade bis zu einem Trinkgeld-Link.

**Ohne Konto verlässt dieser Schlüssel niemals dein Gerät.** Er sitzt im
Schlüsselbund deines eigenen Geräts und wird nur über TLS an `api.stripe.com`
gesendet. Kein live.tips-Server ist überhaupt im Spiel.

**Meldest du dich an, wandert der Schlüssel zu uns** – denn ein Schlüssel, der nur
auf einem Telefon existiert, kann nicht auch das Tablet auf der Bühne bedienen. Wir
verschlüsseln ihn (ein eigener AES-256-Schlüssel je Geheimnis, der seinerseits von
Google Cloud KMS umschlossen wird) und speichern ihn dort, wo ihn nichts zurücklesen
kann: kein anderes Konto, nicht wir mit einem Blick in eine Datenbank, nicht einmal
du. Er wird nur innerhalb unserer Funktionen entsiegelt, dort in deinem Namen für die
Kommunikation mit Stripe genutzt und nie wieder an ein Gerät herausgegeben. Sag es
klar: Die Anmeldung setzt einen live.tips-Server in den Pfad zwischen Stripe und
deiner Trinkgeld-Historie. Nie das Geld – die Daten.

## Die Server, und was sie nicht können

Es sind zwei, und beide sind minimal.

**Das Relay** existiert, weil sich Revolut und MobilePay nicht so aus einem Browser
steuern lassen wie Stripe. Ihre Aktivierung schaltet eine Handvoll
Firebase-Funktionen ein, die deine Trinkgeld-Seite unter `tip.live.tips` ausliefern.
Es speichert dein öffentliches Trinkgeld-Seiten-Profil – den Anzeigenamen und die
Zahlungs-Handles, die du veröffentlichen wolltest – und führt für eine Seite ohne
Konto dahinter keine Trinkgeld-Historie: Ein Trinkgeld wartet nur, bis dein
Bühnengerät es anzeigt, und was niemand abgeholt hat, wird binnen einer Stunde
weggeräumt. Es sieht kein Geld und löscht sich nach 90 Tagen Inaktivität selbst. Wenn
du nur Stripe nutzt und dich nie anmeldest, wird das Relay überhaupt nie kontaktiert.

**Der Webhook** existiert erst, sobald du dich anmeldest. Weil dein Schlüssel jetzt
bei uns liegt, meldet Stripe jedes Trinkgeld an eine kleine Funktion von uns, die es
in deine eigene Historie schreibt, damit deine anderen Geräte es anzeigen können. Es
ist eine Kopie eines Ereignisses, keine Kopie des Geldes. Sie kann keinen Cent
bewegen, und sie kann immer nur in das eine Konto schreiben, zu dem sie gehört.

Keiner der beiden Server kann einen Anteil nehmen, weil keiner auch nur in die Nähe
des Geldes kommt. Das Höchste, was einer von beiden tun kann, ist auszufallen – und
eine reine Stripe-Konfiguration ohne Konto hängt von keinem ab.

## Das Konto, das du nicht anlegen musst

Die App startet weiterhin in ein gerätelokales Profil – genau das, was sie immer
war: deine Trinkgeld-Kasse, dein Schlüssel und deine Trinkgeld-Historie liegen auf
dem Gerät und sonst nirgends. Es gibt nichts, wofür man sich anmelden müsste.

Sich anzumelden – mit Apple, mit Google oder als Gast – ist jetzt möglich, und es
gibt das aus genau einem Grund: ein zweites Gerät. Wenn das Tablet auf der Bühne und
das Telefon in deiner Tasche denselben Abend zeigen sollen, muss etwas dazwischen
sitzen, und dieses Etwas ist Firestore, unter einer Nutzer-ID, die nur du lesen
kannst. Deine Bands, Einstellungen, Trinkgeld-Historie – und, verschlüsselt wie oben,
dein Stripe-Schlüssel – liegen dort. Das ist eine echte Änderung an der
Datenschutz-Geschichte, und sie gehört klar gesagt statt entdeckt: Ohne Konto sieht
nie ein Server ein Trinkgeld; mit Konto sieht es deine eigene Ecke von unserem, und
unser Webhook ist es, der es dorthin schreibt. Das ist der Preis für das zweite
Gerät, und es liegt bei dir, ihn zu zahlen oder abzulehnen. Was es nie anrührt, ist
das Geld – ein Konto verschiebt deine Daten, nicht dein Guthaben, und einen Anteil
gibt es weiterhin nicht.

## Warum du uns nicht einfach glauben solltest

All das lässt sich überprüfen. Der Code ist MIT-lizenziert und öffentlich, und die
Seite ist ein statischer Build, den GitHub Actions auf GitHub Pages ausliefert –
keine versteckte Infrastruktur, nichts, das hinter einer Tür kompiliert wird.
Öffne den Netzwerk-Tab während eines Demo-Trinkgelds und lies die Requests. Es
sind weniger, als du erwartest.

Das ist das eigentliche Produktversprechen. Nicht, dass wir vertrauenswürdig sind,
sondern dass wir es nicht sein müssen.
</content>
