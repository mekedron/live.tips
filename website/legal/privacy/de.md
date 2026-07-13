---
title: Datenschutzerklärung
description: live.tips hat keine Cookies, keine Analyse und kein Tracking und funktioniert ganz ohne Konto. Wenn du dich anmeldest, steht hier genau, was gespeichert wird, wo, von wem und wie lange.
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

- **Ein Konto ist optional.** Die App funktioniert ganz ohne Konto, und das ist weiterhin
  der Normalfall. Wenn du deine Bands und deine Historie auf einem zweiten Gerät haben
  willst, kannst du dich anmelden — und dann liegt ein Teil davon auf einem Server. Was
  wovon, steht weiter unten.
- **Keine Cookies.** Kein einziges, nirgends.
- **Keine Analyse, kein Tracking, keine Werbung, keine Skripte Dritter** auf dieser Website.
- **Wir fassen dein Geld nie an.** Trinkgeld geht direkt vom Fan auf das eigene Stripe-,
  Revolut-, MobilePay- oder Monzo-Konto des Künstlers. Wir sind auf diesem Weg nicht dabei.
- **In der Standardkonfiguration spricht die App ausschließlich mit Stripe** — mit keinem
  live.tips-Server.
- Der einzige Server, den wir überhaupt betreiben, ist ein kleines Relay auf Googles
  Firebase. Es existiert für den Fall, dass ein Künstler Revolut, MobilePay oder Monzo
  einschaltet — oder dass er sich anmeldet.

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

## Die App hat zwei Modi, und dieser Unterschied ist die ganze Geschichte

Alles Weitere hängt an einer einzigen Frage: **Hast du dich angemeldet?**

### Modus eins — kein Konto. Weiterhin der Normalfall, weiterhin unverändert.

Die App läuft **auf dem eigenen Gerät des Künstlers**, und alles, was sie weiß, liegt dort:

- Der **eingeschränkte Stripe-Schlüssel** wird im Schlüsselbund des Geräts gespeichert
  (iOS/macOS Keychain, Android Keystore) und ausschließlich an `api.stripe.com` gesendet.
- **Trinkgeld-Historie, Session-Historie, das Ziel und die App-Einstellungen** werden im
  lokalen Gerätespeicher abgelegt. Dazu gehören die Namen und Nachrichten, die Fans ihrem
  Trinkgeld beilegen.
- Deinstallierst du die App, ist all das gelöscht. Bei uns gibt es kein Cloud-Backup, weil
  es in diesem Modus bei uns keine Cloud gibt.

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

### Modus zwei — du hast dich angemeldet. Dann verlassen manche Daten das Gerät, mit Absicht.

Sich anzumelden ist eine bewusste Handlung. Niemand meldet dich nebenbei an, und nichts an
der App hört auf zu funktionieren, wenn du es nie tust. Du meldest dich an, weil du ein
zweites Gerät willst: das Telefon in der Tasche und das Tablet auf der Bühne, die denselben
Abend zeigen, dieselben Bands, dieselbe Historie.

Das geht nur, wenn ein Server sie hält. **Also hält er sie, und das ist der ehrliche Preis
für das zweite Gerät.**

Dieser Server ist **Firebase**, und das ist Google. Es gibt drei Wege zu einem Konto:

- **Anmelden mit Apple** oder **Anmelden mit Google** — Firebase Auth erhält, was der
  Anbieter herausgibt: eine Benutzer-ID (uid) und meistens eine E-Mail-Adresse und einen
  Namen. (Bei Apple kannst du deine E-Mail verbergen; Apple gibt uns dann stattdessen eine
  Weiterleitungsadresse.)
- **Ein Gastkonto** — ein anonymes Konto ohne E-Mail und ohne Namen. Es synchronisiert und
  es lässt sich widerrufen, aber wenn du das Gerät verlierst, gibt es nichts, womit man es
  wiederherstellen könnte. Es ist eine uid und sonst nichts.

Sobald du angemeldet bist, bekommt das Konto seine eigene private Ecke in Googles Datenbank
**Cloud Firestore**, unter `users/<your uid>/`. Die Sicherheitsregeln geben diese Ecke
dieser uid **und sonst niemandem** — kein anderes Konto kann sie lesen, auch nicht durch
Raten von URLs. Darin liegen:

| Was | Warum es dort liegt |
| --- | --- |
| Deine **Bands** — Namen, Einstellungen für Trinkgeldglas und Zahlungsmethoden, Plakattext, Ziele | damit eine Band auf jedem Gerät existiert, an dem du dich anmeldest |
| Dein **eingeschränkter Stripe-Schlüssel** und das Geheimnis der Trinkgeldseite im Relay | in einem Geheimnis-Dokument, das nur deine uid lesen kann, und im Schlüsselbund jedes deiner Geräte zwischengespeichert |
| **App-Einstellungen** | damit ein Gerät, das du hinzufügst, schon eingerichtet ist |
| **Session-Aufzeichnungen und Trinkgeld-Historie** — einschließlich **der Namen und Nachrichten, die Fans ihrem Trinkgeld beilegen** | weil genau diese Historie das ist, was du auf dem anderen Gerät sehen wolltest |
| Die **Live-Session**, die gerade läuft | damit ein zweiter Bildschirm zum heutigen Set dazustoßen kann |
| Deine **Geräte** — der Name, den jedes sich selbst gibt („Nikitas iPhone“), Plattform und Modell, wann es zuerst und zuletzt gesehen wurde | damit Einstellungen → Sicherheit sie auflisten kann und du eines widerrufen kannst |
| Ein kleines **Profildokument** — der Kontoname, den du gewählt hast, und über welchen Anbieter du dich angemeldet hast | damit der Kontowechsler es beschriften kann |

Und jetzt das Wichtige, ganz nüchtern: **Ohne Konto verlassen Name und Nachricht eines Fans
niemals das Gerät des Künstlers. Mit Konto liegen sie auf Googles Servern unter der uid des
Künstlers, als Teil der eigenen synchronisierten Historie dieses Künstlers.** Kein anderes
Konto kann sie lesen, wir sehen sie uns nicht an, und es wird nichts daraus abgeleitet —
aber sie sind dort, und das solltest du wissen, bevor du dich anmeldest.

Meldest du dich ab, kehrt das Gerät in den lokalen Modus zurück. Die Daten des Kontos werden
dadurch nicht gelöscht — siehe *Dinge löschen* weiter unten.

### Ein Gerät per QR-Code hinzufügen

Um ein Gerät hinzuzufügen, zeigst du einen QR-Code von einem Gerät, das bereits angemeldet
ist. Der Code ist zufällig, **nur einmal verwendbar und läuft nach zwei Minuten ab**, und
das neue Gerät bekommt nichts, bevor du auf dem alten auf *bestätigen* tippst. Solange
dieser Handshake offen ist, halten wir den Code, den Namen, den das neue Gerät sich gegeben
hat, und seine Plattform — und der Eintrag wird gelöscht, wenn er abläuft. Ein
abfotografierter QR-Code ist ohne deinen bestätigenden Tipp wertlos.

## Wo das alles physisch liegt

Firebase Auth, Cloud Firestore und unsere Cloud Functions laufen in der **Europäischen
Union** — die Datenbank in Googles Multiregion `eur3`, die Funktionen in `europe-west1`.
Google handelt als unser Auftragsverarbeiter nach den
[Firebase-Datenschutz- und Sicherheitsbedingungen](https://firebase.google.com/support/privacy)
und seiner eigenen [Datenschutzerklärung](https://policies.google.com/privacy). Wie jeder
große Anbieter kann Google für Support und Sicherheit auch Infrastruktur außerhalb der EU
einbeziehen; das regeln jene Bedingungen, nicht wir.

## Stripe

Wenn ein Fan mit Karte zahlt, befindet er sich auf der Checkout-Seite von **Stripe**, nicht
auf unserer. Stripe erhebt und verarbeitet seine Zahlungsdaten als eigenständiger
Verantwortlicher nach der
[Stripe-Datenschutzerklärung](https://stripe.com/privacy). Wir sehen niemals Kartennummern,
und wir haben keinen Zugriff auf das Stripe-Konto des Künstlers.

Die App des Künstlers liest seine eigenen Trinkgelder mit dem eigenen eingeschränkten
Schlüssel des Künstlers aus Stripe aus — direkt vom Gerät an `api.stripe.com`. **Auf diesem
Weg gibt es keinen live.tips-Server, und es gab nie einen.** Name und Nachricht eines Fans,
falls hinterlassen, wandern von Stripe auf das Gerät des Künstlers und bleiben dort — es sei
denn, der Künstler hat sich angemeldet; dann speichert das Gerät sie zusätzlich in der
eigenen Firestore-Historie dieses Künstlers, wie oben beschrieben.

## Das Relay — nur, wenn Revolut, MobilePay oder Monzo eingeschaltet sind

Reine Stripe-Konfigurationen berühren das nie.

Revolut, MobilePay und Monzo bieten einer App keine Möglichkeit zu bestätigen, dass eine
Zahlung stattgefunden hat. Deshalb laufen solche Trinkgelder über ein kleines quelloffenes
Relay, das wir auf **Firebase** betreiben — Cloud Functions und Firestore in `europe-west1`,
mit der Trinkgeldseite für den Fan unter **`tip.live.tips/t/<id>`**. Es fasst niemals Geld
an. Hier ist alles, womit es umgeht.

### Was der Künstler speichert

Beim Anlegen einer Trinkgeldseite werden der **Anzeigename des Künstlers, seine öffentliche
Nachricht, seine Währung und die Zahlungskennungen, die er veröffentlichen möchte**,
gespeichert (sein Stripe-Zahlungslink, Revolut-Benutzername, MobilePay-Box-ID,
Monzo-Benutzername). All das sind Informationen, die der Künstler ohnehin bewusst gegenüber
den Fans veröffentlicht.

- **Speicherdauer: Eine Trinkgeldseite ohne Konto dahinter wird nach 90 Tagen Inaktivität
  automatisch gelöscht.** Eine Trinkgeldseite, die zu einem angemeldeten Konto gehört, lebt
  so lange wie die Band, zu der sie gehört.
- Der Künstler kann sie jederzeit **sofort** aus der App löschen.
- Es werden hier niemals E-Mail-Adresse, Passwort, bürgerlicher Name oder Bankdaten erhoben.
- Das Geheimnis der Seite wird **nur als Hash** gespeichert. Wir könnten dir das Geheimnis
  nicht nennen, wenn du danach fragtest; wir können eines nur prüfen.

### Was ein Fan sendet

Das Trinkgeldformular fragt nach einem **Betrag** und optional nach einem **Namen** und einer
**Nachricht**. Das ist das ganze Formular. Keine E-Mail, keine Telefonnummer, kein Konto.

- Das Trinkgeld wird in eine **Zustellwarteschlange** geschrieben — ein einzelnes Dokument,
  das nur dafür existiert, an den Bildschirm des Künstlers übergeben zu werden. Zeigt der
  Bildschirm das Trinkgeld an, **löscht das Gerät des Künstlers dieses Dokument.** Das
  Löschen *ist* die Bestätigung; es gibt kein „zugestellt“-Kennzeichen, weil kein Eintrag
  übrig bleibt, den man kennzeichnen könnte.
- Ist der Bildschirm des Künstlers offline — Handy gesperrt, kein Empfang —, **wartet das
  Trinkgeld bis zu einer Stunde in dieser Warteschlange**, damit es nicht einfach verloren
  geht, und geht in dem Moment hinüber, in dem der Bildschirm wieder verbunden ist.
  Verbindet sich niemand mehr, wird es **ungesehen gelöscht**, planmäßig weggeräumt, ganz
  gleich, ob jemals jemand dafür zurückkam.
- **Diese Warteschlange ist der einzige Ort, an dem von Fans geschriebener Text auf unserem
  Server überhaupt gespeichert wird, und eine Stunde ist die harte Obergrenze.** Ist der
  Künstler angemeldet, behält sein Gerät das Trinkgeld anschließend in *seiner*
  Firestore-Historie — denn das ist seine Historie, und genau dafür hat er sich angemeldet.
- Dein Name und deine Nachricht werden außerdem in den **Zahlungsverwendungszweck**
  eingesetzt, der sich in Revolut, MobilePay oder Monzo öffnet — so weiß der Künstler, wer
  Trinkgeld gegeben hat. Diese Unternehmen verarbeiten die Angaben dann nach ihren eigenen
  Datenschutzerklärungen.
- Das Relay führt **keine Trinkgeld-Historie**. Es kann weder dir noch uns noch sonst jemandem
  eine Liste darüber zeigen, wer wem Trinkgeld gegeben hat.

### IP-Adressen und Missbrauchsschutz

Ein offenes Formular, an das jeder etwas senden kann, braucht einen gewissen Schutz vor Bots,
daher:

- Deine IP-Adresse wird an **Cloudflare Turnstile** gesendet — eine Bot-Prüfung, die auf der
  Trinkgeldseite läuft —, um zu prüfen, dass du kein Bot bist. Turnstile ist ein Produkt von
  Cloudflare und wird anstelle eines CAPTCHAs eingesetzt, das dich profiliert. Turnstile und
  unser DNS sind das Einzige, was Cloudflare noch für uns tut; das Relay selbst läuft
  inzwischen auf Firebase. Siehe die
  [Cloudflare-Datenschutzerklärung](https://www.cloudflare.com/privacypolicy/).
- Deine IP wird außerdem zur **Ratenbegrenzung** von Anfragen verwendet — ein Trinkgeld
  senden, eine Trinkgeldseite anlegen, einen Code zum Hinzufügen eines Geräts einlösen. Was
  wir dafür speichern, ist ein **gesalzener kryptografischer Hash der IP-Adresse**, niemals
  die IP-Adresse selbst, für etwa **zwei Stunden**, und dann wird er gelöscht. Das Salt ist
  ein Servergeheimnis: ohne es weigert sich der Code, überhaupt irgendetwas zu speichern,
  statt einen Hash aufzubewahren, der sich umkehren ließe.
- **Die Betriebslogs von Google** halten die technischen Details der Anfragen an das Relay
  fest — URL, Zeitpunkt, Status — für einige Tage. Unser Code protokolliert bewusst keine
  Namen, keine Nachrichten, keine Geheimnisse und keine Header. Google handelt als unser
  Auftragsverarbeiter.

### Zähler

Das Relay zählt, **wie viele Trinkgelder** eine bestimmte Trinkgeldseite weitergeleitet hat,
damit wir Missbrauch erkennen und wissen, ob die Sache überhaupt genutzt wird. Es ist eine
Zahl. Sie enthält keine Daten von Fans.

## Wer was verarbeitet

| Wer | Was sie bekommen | Wofür |
| --- | --- | --- |
| **Google (Firebase)** | Konten, die synchronisierten Daten eines angemeldeten Künstlers, das Relay, Server-Logs | Das optionale Konto und das optionale Relay |
| **Stripe** | Die Zahlungsdaten des Fans, als eigenständiger Verantwortlicher | Trinkgelder per Karte |
| **Cloudflare** | Die IP des Fans, für die Turnstile-Prüfung auf der Trinkgeldseite. Und unser DNS. | Bots vom Trinkgeldformular fernhalten |
| **GitHub** | Die IP und den User-Agent aller, die diese Website laden | Hosting der Website |
| **Revolut / MobilePay / Monzo** | Was auch immer der Fan in ihrer eigenen App tut, den Zahlungsverwendungszweck eingeschlossen | Diese Zahlungsmethoden |

Wir verkaufen nichts an niemanden, und sonst steht niemand auf dieser Liste.

## Rechtsgrundlage, falls du eine brauchst (DSGVO)

- Betrieb eines Kontos, um das du gebeten hast, Synchronisation deiner eigenen Daten auf
  deine eigenen Geräte, Betrieb des Relays für einen Künstler, der es eingeschaltet hat, und
  Zustellung des Trinkgelds eines Fans an den Bildschirm, für den es bestimmt war:
  **Erfüllung eines von dir angeforderten Dienstes**.
- Ratenbegrenzung, Turnstile, Kontingente über gehashte IP-Adressen und Geräte-Widerruf:
  **berechtigtes Interesse** daran, einen kostenlosen, offenen Dienst nicht von Bots und
  Betrug zerstören zu lassen und die Konten der Künstler sicher zu halten.
- Server-Logs: **berechtigtes Interesse** am Betrieb und an der Absicherung des Dienstes.

## Dinge löschen

Das zählt mehr als jedes Versprechen, das wir dazu geben könnten, also hier genau, was es
heute gibt — einschließlich dessen, was es nicht gibt.

- **Kein Konto**: Deinstalliere die App. Das war alles, und es ist weg.
- **Eine Band**: Entfernst du eine Band in der App, werden ihre Cloud-Daten gelöscht — ihre
  Einstellungen, ihre Schlüssel, ihre Sessions, ihre Trinkgeld-Historie — zusammen mit der
  Kopie auf dem Gerät.
- **Eine Trinkgeldseite**: Lösche sie in der App oder erzeuge sie neu, und sie ist sofort aus
  dem Relay getilgt, samt aller noch ausstehenden Trinkgelder.
- **Ein Gerät**: Einstellungen → Sicherheit listet deine Geräte auf. Du kannst eines
  widerrufen oder dich überall sonst abmelden — was die Sitzung jedes anderen Geräts sofort
  beendet, nicht irgendwann.
- **Dein ganzes Konto, mit einem Tipp: Diesen Knopf hat die App noch nicht.** Das geben wir
  lieber zu, als etwas anderes vorzuspielen. Bis es ihn gibt, schreib an
  **[contact@live.tips](mailto:contact@live.tips)**, und wir löschen das Konto und alles
  darunter von Hand. In der Zwischenzeit kannst du schon jetzt jede Band löschen, was alles
  Wesentliche entfernt und ein leeres Konto zurücklässt.

## Deine Rechte

Du kannst von uns eine Kopie all dessen verlangen, was wir über dich gespeichert haben, es
berichtigen oder löschen lassen, und du kannst dich bei deiner nationalen Datenschutzbehörde
beschweren. Schreib an **[contact@live.tips](mailto:contact@live.tips)**.

In der Praxis liegt das meiste davon ohnehin schon in deiner Hand: Ein Künstler kann eine
Trinkgeldseite oder eine Band sofort aus der App löschen, nicht zugestellte Trinkgelder von
Fans verflüchtigen sich innerhalb einer Stunde, und wenn du dich nie anmeldest, war nichts
davon jemals irgendwo anders als auf deinem eigenen Gerät.

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
