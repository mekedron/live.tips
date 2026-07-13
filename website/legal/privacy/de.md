---
title: Datenschutzerklärung
description: live.tips hat keine Konten, keine Cookies, keine Analyse und kein Tracking. Hier die kurze Liste dessen, was doch verarbeitet wird, von wem und wie lange.
updated: 2026-07-13
updated_label: Zuletzt aktualisiert am 13. Juli 2026
---

live.tips ist ein quelloffenes Trinkgeldglas für Künstlerinnen und Künstler. Betrieben wird
es von **Nikita Rabykin**, einem einzelnen Entwickler, nicht von einem Unternehmen. Wenn
dich etwas von dem Folgenden bewegt, schreib an
**[contact@live.tips](mailto:contact@live.tips)** — unter dieser Adresse sitzt ein Mensch.

Diese Erklärung ist auch dort ehrlich, wo es langweilig wird. Uns ist es lieber zu sagen
„wir behalten deinen Namen bis zu einer Stunde“, als zu behaupten, wir behielten gar
nichts, und damit falsch zu liegen.

## Die Kurzfassung

- **Keine Konten.** Es gibt nichts, wofür man sich anmelden müsste.
- **Keine Cookies.** Kein einziges, nirgends.
- **Keine Analyse, kein Tracking, keine Werbung, keine Skripte Dritter** auf dieser Website.
- **Wir fassen dein Geld nie an.** Trinkgeld geht direkt vom Fan auf das eigene Stripe-,
  Revolut-, MobilePay- oder Monzo-Konto des Künstlers. Wir sind auf diesem Weg nicht dabei.
- **In der Standardkonfiguration spricht die App ausschließlich mit Stripe** — mit keinem
  live.tips-Server.
- Der einzige Server, den wir überhaupt betreiben, ist ein kleines Relay, und es existiert
  nur dann, wenn ein Künstler Revolut, MobilePay oder Monzo einschaltet.

## Diese Website

Die Seite ist statisch und wird auf **GitHub Pages** gehostet. Als Hoster erhält GitHub die
IP-Adresse und den Browser-User-Agent aller, die eine Seite laden — das ist ganz gewöhnliches
Webserver-Logging, es passiert, bevor irgendein Code von uns läuft, und wir können es nicht
abschalten. GitHub verarbeitet diese Daten nach seiner eigenen
[Datenschutzerklärung](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement).
Wir lesen diese Logs nicht, und GitHub zeigt sie uns auch nicht.

Darüber hinaus laden die Seiten, die du gerade liest, **nichts von irgendjemand anderem**:
Schriften, Icons und Bilder kommen von live.tips selbst. Es gibt kein Google Analytics,
keinen Tag-Manager, kein Pixel, kein eingebettetes Widget.

Die Seite speichert **zwei Werte im `localStorage` deines Browsers**, beide von dir gesetzt,
beide nur von dieser Seite lesbar, und keiner wird jemals irgendwohin gesendet:

| Schlüssel | Was er sich merkt |
| --- | --- |
| `lt-landing-theme` | ob du helle, dunkle oder automatische Farben gewählt hast |
| `lt-langbar-dismissed` | dass du das Banner „auch in deiner Sprache verfügbar“ geschlossen hast |

Wenn du den Browserspeicher leerst, sind sie weg. Sie sind keine Cookies, sie werden nicht
geteilt, und sie identifizieren niemanden.

## Die App

Die live.tips-App läuft **auf dem eigenen Gerät des Künstlers**. Alles, was sie weiß, liegt
dort:

- Der **eingeschränkte Stripe-Schlüssel** wird im Schlüsselbund des Geräts gespeichert
  (iOS/macOS Keychain, Android Keystore) und ausschließlich an `api.stripe.com` gesendet.
- **Trinkgeld-Historie, Session-Historie, das Ziel und die App-Einstellungen** werden im
  lokalen Gerätespeicher abgelegt. Dazu gehören die Namen und Nachrichten, die Fans ihrem
  Trinkgeld beilegen.
- Deinstallierst du die App, ist all das gelöscht. Bei uns gibt es kein Cloud-Backup, weil
  es bei uns keine Cloud gibt.

**Wir bekommen nichts davon jemals zu sehen.** Die App wird ohne Analyse-SDK, ohne
Crash-Reporter, ohne Push-Benachrichtigungen und ohne Werbecode ausgeliefert — gar keinen,
auch keinen deaktivierten.

Zwei Klarstellungen, damit die Aussage „spricht mit niemandem“ exakt stimmt:

- Die App holt einmal täglich **Währungskurse** von öffentlichen Kurs-APIs
  (`frankfurter.dev`, `open.er-api.com`, `currency-api.pages.dev`). Das sind schlichte
  Anfragen nach einer öffentlichen Kursliste. Sie enthalten keine Information über dich, den
  Künstler oder irgendein Trinkgeld — aber wie jede Webanfrage geben sie deine IP-Adresse an
  diese Dienste preis.
- Wenn du die **Browser-Version** der App nutzt, lädt dein Browser sie von unserem statischen
  Hoster herunter (siehe *Diese Website* oben).

## Stripe

Wenn ein Fan mit Karte zahlt, befindet er sich auf der Checkout-Seite von **Stripe**, nicht
auf unserer. Stripe erhebt und verarbeitet seine Zahlungsdaten als eigenständiger
Verantwortlicher nach der
[Stripe-Datenschutzerklärung](https://stripe.com/privacy). Wir sehen niemals Kartennummern,
und wir haben keinen Zugriff auf das Stripe-Konto des Künstlers.

Die App des Künstlers liest seine eigenen Trinkgelder mit dem eigenen eingeschränkten
Schlüssel des Künstlers aus Stripe aus. Name und Nachricht eines Fans, falls hinterlassen,
wandern von Stripe auf das Gerät des Künstlers und bleiben dort.

## Das Relay — nur, wenn Revolut, MobilePay oder Monzo eingeschaltet sind

Reine Stripe-Konfigurationen berühren das nie und können hier aufhören zu lesen.

Revolut, MobilePay und Monzo bieten einer App keine Möglichkeit zu bestätigen, dass eine
Zahlung stattgefunden hat. Deshalb laufen solche Trinkgelder über ein kleines quelloffenes
Relay, das wir bei **Cloudflare** unter `api.live.tips` betreiben. Es fasst niemals Geld an.
Hier ist alles, womit es umgeht.

### Was der Künstler speichert

Beim Anlegen einer Trinkgeldseite werden der **Anzeigename des Künstlers, seine öffentliche
Nachricht, seine Währung und die Zahlungskennungen, die er veröffentlichen möchte**,
gespeichert (sein Stripe-Zahlungslink, Revolut-Benutzername, MobilePay-Box-ID,
Monzo-Benutzername). All das sind Informationen, die der Künstler ohnehin bewusst gegenüber
den Fans veröffentlicht.

- **Speicherdauer: automatische Löschung nach 90 Tagen Inaktivität.**
- Der Künstler kann sie jederzeit **sofort** aus der App löschen.
- Es werden niemals E-Mail-Adresse, Passwort, bürgerlicher Name oder Bankdaten erhoben.

### Was ein Fan sendet

Das Trinkgeldformular fragt nach einem **Betrag** und optional nach einem **Namen** und einer
**Nachricht**. Das ist das ganze Formular. Keine E-Mail, keine Telefonnummer, kein Konto.

- Ist der Bildschirm des Künstlers **online**, wird das Trinkgeld direkt durchgereicht und
  **nie auf die Festplatte geschrieben**.
- Ist der Bildschirm des Künstlers **offline** — Handy gesperrt, kein Empfang —, wird das
  Trinkgeld **bis zu einer Stunde gespeichert**, damit es nicht einfach verloren geht, und in
  dem Moment übergeben, in dem der Bildschirm wieder verbunden ist. Verbindet sich niemand
  mehr, wird es **ungesehen gelöscht**. Das ist der einzige von Fans geschriebene Text, den
  das Relay überhaupt speichert, und eine Stunde ist die harte Obergrenze.
- Dein Name und deine Nachricht werden außerdem in den **Zahlungsverwendungszweck**
  eingesetzt, der sich in Revolut, MobilePay oder Monzo öffnet — so weiß der Künstler, wer
  Trinkgeld gegeben hat. Diese Unternehmen verarbeiten die Angaben dann nach ihren eigenen
  Datenschutzerklärungen.
- Das Relay führt **keine Trinkgeld-Historie**. Es kann weder dir noch uns noch sonst jemandem
  eine Liste darüber zeigen, wer wem Trinkgeld gegeben hat.

### IP-Adressen und Missbrauchsschutz

Ein offenes Formular, an das jeder etwas senden kann, braucht einen gewissen Schutz vor Bots,
daher:

- Deine IP-Adresse wird zur **Ratenbegrenzung** von Anfragen verwendet und an **Cloudflare
  Turnstile** gesendet (eine Bot-Prüfung, die auf der Trinkgeldseite läuft), um zu prüfen,
  dass du kein Bot bist. Turnstile ist ein Produkt von Cloudflare und wird anstelle eines
  CAPTCHAs eingesetzt, das dich profiliert.
- Damit niemand tausende Trinkgeldseiten anlegt, wird ein **kryptografischer Hash der
  IP-Adresse** desjenigen, der eine Seite anlegt, für etwa **zwei Stunden** aufbewahrt und
  dann verworfen.
- **Die Betriebslogs von Cloudflare** halten die technischen Details der Anfragen an das Relay
  fest — URL, Zeitpunkt, Status — für einige Tage. Sie enthalten keine Namen oder Nachrichten
  von Fans. Cloudflare handelt als unser Auftragsverarbeiter; siehe die
  [Cloudflare-Datenschutzerklärung](https://www.cloudflare.com/privacypolicy/).

### Zähler

Das Relay zählt, **wie viele Trinkgelder** eine bestimmte Trinkgeldseite weitergeleitet hat,
damit wir Missbrauch erkennen und wissen, ob die Sache überhaupt genutzt wird. Es ist eine
Zahl. Sie enthält keine Daten von Fans.

## Rechtsgrundlage, falls du eine brauchst (DSGVO)

- Betrieb des Relays für einen Künstler, der es eingeschaltet hat, und Zustellung des
  Trinkgelds eines Fans an den Bildschirm, für den es bestimmt war: **Erfüllung eines von dir
  angeforderten Dienstes**.
- Ratenbegrenzung, Turnstile und Kontingente über gehashte IP-Adressen: **berechtigtes
  Interesse** daran, einen kostenlosen, offenen Dienst nicht von Bots und Betrug zerstören zu
  lassen.
- Server-Logs: **berechtigtes Interesse** am Betrieb und an der Absicherung des Dienstes.

## Deine Rechte

Du kannst von uns eine Kopie all dessen verlangen, was wir über dich gespeichert haben, es
berichtigen oder löschen lassen, und du kannst dich bei deiner nationalen Datenschutzbehörde
beschweren. Schreib an **[contact@live.tips](mailto:contact@live.tips)**.

In der Praxis liegt das meiste davon ohnehin schon in deiner Hand: Künstler können ihre
Trinkgeldseite sofort aus der App löschen, Trinkgelder von Fans verflüchtigen sich innerhalb
einer Stunde, und alles Übrige liegt auf deinem eigenen Gerät.

## Kinder

live.tips richtet sich nicht an Kinder, und wir verarbeiten ihre Daten nicht wissentlich.

## Änderungen

Wir aktualisieren diese Seite, wenn sich die Software ändert. Da das gesamte Projekt Open
Source ist, **steht jede frühere Fassung dieser Erklärung in der öffentlichen Git-Historie** —
du kannst genau nachlesen, was sich wann geändert hat.

## Sprache

Diese Erklärung wird der Bequemlichkeit halber in allen Sprachen veröffentlicht, die die Seite
unterstützt. Wenn eine Übersetzung und die englische Fassung voneinander abweichen, **gilt die
englische Fassung**.
