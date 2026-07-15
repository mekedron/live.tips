---
title: Datenschutzerklärung
description: live.tips hat keine Cookies, keine Analyse und kein Tracking und funktioniert ganz ohne Konto. Wenn du dich anmeldest, steht hier genau, was gespeichert wird, wo, von wem und wie lange.
updated: 2026-07-15
updated_label: Zuletzt aktualisiert am 15. Juli 2026
---

live.tips ist ein quelloffenes Trinkgeldglas für Künstlerinnen und Künstler. Betrieben wird
es von **Nikita Rabykin**, einem einzelnen Entwickler, nicht von einem Unternehmen. Wenn
dich etwas von dem Folgenden bewegt, schreib an
**[contact@live.tips](mailto:contact@live.tips)** — unter dieser Adresse sitzt ein Mensch.

Diese Erklärung ist auch dort ehrlich, wo es langweilig wird. Uns ist es lieber zu sagen
„wir behalten deinen Namen, solange du die Band behältst", als zu behaupten, wir behielten
gar nichts, und damit falsch zu liegen.

## Die Kurzfassung

- **Ein Konto ist optional.** Die App funktioniert ganz ohne Konto, und das ist weiterhin
  der Normalfall. Wenn du deine Bands und deine Historie auf einem zweiten Gerät haben
  willst, kannst du dich anmelden — und dann liegt ein Teil davon auf einem Server, und mehr
  davon als früher. Was wovon, steht weiter unten.
- **Keine Cookies.** Kein einziges, nirgends.
- **Keine Analyse, kein Tracking, keine Werbung, keine Skripte Dritter** auf dieser Website.
- **Wir fassen dein Geld nie an.** Trinkgeld geht direkt vom Fan auf das eigene Stripe-,
  Revolut-, MobilePay- oder Monzo-Konto des Künstlers. Es gibt kein live.tips-Guthaben,
  niemals.
- **Ohne Konto spricht die App ausschließlich mit Stripe** — mit keinem live.tips-Server.
  Meldest du dich an, ändert sich das: Dein Stripe-Schlüssel wandert auf unseren Server, und
  Stripe meldet deine Trinkgelder an uns, damit wir sie auf deine anderen Geräte bringen
  können. Das ist der ehrliche Preis der Anmeldung, und weiter unten steht er in voller Länge.
- **Push-Benachrichtigungen sind neu, optional und nur für angemeldete Konten.** An ein
  Gerät, das sie nie eingeschaltet hat, wird nichts gepusht, und an ein Gerät ohne Konto wird
  überhaupt keine gesendet.
- Die Server, die wir betreiben, laufen auf Googles Firebase. Sie existieren für den Fall,
  dass ein Künstler Revolut, MobilePay oder Monzo einschaltet — oder dass er sich anmeldet.

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
| `lt-langbar-dismissed` | dass du das Banner „auch in deiner Sprache verfügbar" geschlossen hast |

Wenn du den Browserspeicher leerst, sind sie weg. Sie sind keine Cookies, sie werden nicht
geteilt, und sie identifizieren niemanden.

## Die App hat zwei Modi, und dieser Unterschied ist die ganze Geschichte

Alles Weitere hängt an einer einzigen Frage: **Hast du dich angemeldet?**

### Modus eins — kein Konto. Weiterhin der Normalfall, weiterhin unverändert.

Die App läuft **auf dem eigenen Gerät des Künstlers**, und alles, was sie weiß, liegt dort:

- Der **eingeschränkte Stripe-Schlüssel** wird im Schlüsselbund des Geräts gespeichert
  (iOS/macOS Keychain, Android Keystore) und ausschließlich an `api.stripe.com` gesendet.
- **Trinkgeld-Historie, Session-Historie, das Ziel, die Songwunsch-Liste und die
  App-Einstellungen** werden im lokalen Gerätespeicher abgelegt. Dazu gehören die Namen und
  Nachrichten, die Fans ihrem Trinkgeld beilegen.
- Deinstallierst du die App, ist all das gelöscht. Bei uns gibt es kein Cloud-Backup, weil
  es in diesem Modus bei uns keine Cloud gibt.

**Wir bekommen nichts davon jemals zu sehen.** Die App wird ohne Analyse-SDK, ohne
Crash-Reporter und ohne Werbecode ausgeliefert — gar keinen, auch keinen deaktivierten.
(Push-Benachrichtigungen gibt es zwar, aber sie sind eine Funktion für Angemeldete und
bleiben aus, bis du sie einschaltest — siehe *Modus zwei*. An ein Gerät ohne Konto wird nie
eine gesendet.)

Zwei Klarstellungen, damit die Aussage „spricht mit niemandem" exakt stimmt:

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
  Weiterleitungsadresse und übergibt deinen Namen nur bei der allerersten Anmeldung.)
- **Ein Gastkonto** — ein anonymes Konto ohne E-Mail und ohne Namen. Es synchronisiert und
  es lässt sich widerrufen, aber wenn du das Gerät verlierst, gibt es nichts, womit man es
  wiederherstellen könnte. Es ist eine uid und sonst nichts. Ein Gastkonto kann weder die
  serverseitige Stripe-Verwahrung noch die weiter unten beschriebenen
  Push-Benachrichtigungen nutzen, weil beides ein Konto braucht, das wir dir zurückgeben
  können.

Sobald du angemeldet bist, bekommt das Konto seine eigene private Ecke in Googles Datenbank
**Cloud Firestore**, unter `users/<your uid>/`. Die Sicherheitsregeln geben diese Ecke
dieser uid **und sonst niemandem** — kein anderes Konto kann sie lesen, auch nicht durch
Raten von URLs. Darin liegen:

| Was | Warum es dort liegt |
| --- | --- |
| Deine **Bands** — Namen, Einstellungen für Trinkgeldglas und Zahlungsmethoden, Plakattext, Ziele und deine **Songwunsch-Liste** | damit eine Band auf jedem Gerät existiert, an dem du dich anmeldest |
| **App-Einstellungen**, einschließlich deiner Benachrichtigungseinstellungen | damit ein Gerät, das du hinzufügst, schon eingerichtet ist |
| **Session-Aufzeichnungen und Trinkgeld-Historie** — einschließlich **der Namen und Nachrichten, die Fans ihrem Trinkgeld beilegen**, und **jedes Songs, den ein Fan gewünscht hat** | weil genau diese Historie das ist, was du auf dem anderen Gerät sehen wolltest |
| Die **Live-Session**, die gerade läuft | damit ein zweiter Bildschirm zum heutigen Set dazustoßen kann |
| Deine **Geräte** — der Name, den jedes sich selbst gibt („Nikitas iPhone"), Plattform und Modell, seine Oberflächensprache, wann es zuerst und zuletzt gesehen wurde, und (falls du Benachrichtigungen eingeschaltet hast) ein **Push-Token** | damit Einstellungen → Sicherheit sie auflisten kann, damit eine Benachrichtigung das richtige Gerät in der richtigen Sprache erreicht und du eines widerrufen kannst |
| Ein kleines **Profildokument** — der Kontoname, den du gewählt hast, und über welchen Anbieter du dich angemeldet hast | damit der Kontowechsler es beschriften kann |
| Ein **Glocken-Feed** — eine begrenzte Liste jüngster Trinkgelder und Songwünsche, die eingingen, während kein Set lief | damit du nachholen kannst, was du verpasst hast |

Und jetzt das Wichtige, ganz nüchtern: **Ohne Konto verlassen Name und Nachricht eines Fans
niemals das Gerät des Künstlers. Mit Konto liegen sie auf Googles Servern unter der uid des
Künstlers, als Teil der eigenen synchronisierten Historie dieses Künstlers**, und — wie die
nächsten beiden Abschnitte erklären — **schreibt sie jetzt unser Server dorthin.** Kein
anderes Konto kann sie lesen, wir sehen sie uns nicht an, und es wird nichts daraus
abgeleitet — aber sie sind dort, und sie bleiben dort, solange die Band besteht, und das
solltest du wissen, bevor du dich anmeldest.

Meldest du dich ab, kehrt das Gerät in den lokalen Modus zurück. Die Daten des Kontos werden
dadurch nicht gelöscht — siehe *Dinge löschen* weiter unten.

#### Dein Stripe-Schlüssel wandert bei der Anmeldung auf unseren Server

Das ist die größte Änderung und die, die man am ehesten lesen sollte.

**Ohne Konto verlässt dein eingeschränkter Stripe-Schlüssel niemals dein Gerät.** Das ist
Modus eins, und daran hat sich nichts geändert.

**Meldest du dich an, verlässt er es sehr wohl — zu uns.** Der Schlüssel wird verschlüsselt
(ein eigener AES-256-Schlüssel je Geheimnis, der seinerseits von Google Cloud KMS umschlossen
wird) und serverseitig an einem Ort gespeichert, den **niemand zurücklesen kann — kein
anderes Konto und nicht einmal du.** Er wird nur innerhalb unserer Cloud Functions
entsiegelt, dort in deinem Namen für die Kommunikation mit Stripe genutzt und nie wieder an
ein Gerät herausgegeben.

Weil der Schlüssel jetzt bei uns liegt, **meldet Stripe deine Trinkgelder direkt an unseren
Server**: Wir registrieren einen Webhook auf deinem eigenen Stripe-Konto, und Stripe teilt
diesem Webhook jedes Mal mit, wenn ein Trinkgeld gezahlt wird. Unsere Funktion schreibt das
Trinkgeld in die Historie deines Kontos (siehe unten). Deine App fragt Stripe für ein
angemeldetes Konto nicht mehr ab; sie erreicht Stripe nur noch über eine enge, feste Liste
von Vorgängen auf unserem Server (das Erstellen deines Trinkgeld-Links, das Ausstellen eines
Songwunsch-Links und das Zurücklesen deiner eigenen Trinkgelder zum Abgleich).

Also, ohne Beschönigung gesagt: **Bei einem angemeldeten Konto steht jetzt ein
live.tips-Server im Pfad zwischen Stripe und deiner Historie.** Wir fassen das Geld weiterhin
nie an — ein Kartentrinkgeld wird auf deinem Stripe-Konto angelegt, landet in deinem
Stripe-Guthaben und wird nach deinem Stripe-Zeitplan ausgezahlt, genau wie zuvor. Geändert
hat sich der *Daten*pfad, nicht der *Geld*pfad. Meldest du dich nie an, trifft nichts davon
zu, und die App spricht weiterhin direkt mit `api.stripe.com` und mit sonst niemandem.

#### Ein Gerät per QR-Code hinzufügen

Um ein Gerät hinzuzufügen, zeigst du einen QR-Code von einem Gerät, das bereits angemeldet
ist. Der Code ist zufällig, **nur einmal verwendbar und läuft nach zwei Minuten ab**, und
das neue Gerät bekommt nichts, bevor du auf dem alten auf *bestätigen* tippst. Solange
dieser Handshake offen ist, halten wir den Code, den Namen, den das neue Gerät sich gegeben
hat, und seine Plattform — und der Eintrag wird gelöscht, wenn er abläuft. Ein
abfotografierter QR-Code ist ohne deinen bestätigenden Tipp wertlos.

## Songwünsche

Eine Band kann **Songwünsche** einschalten: Fans wählen dann einen Song aus der Liste des
Künstlers und zahlen optional, um ihn in der Warteschlange nach oben zu schieben. Ein Wunsch
ist einfach ein Trinkgeld, das zusätzlich trägt, **welcher Song** gewünscht wurde — also
gelten derselbe Name und dieselbe Nachricht, die ein Fan einem Trinkgeld beilegen kann, auch
hier, und er wird genau wie jedes andere Trinkgeld gespeichert und aufbewahrt (siehe unten).
Die öffentliche Warteschlange, die ein Fan sieht, zeigt nur **Summen je Song** — wie viel ein
Song eingebracht hat und wo er steht — und enthält **keine Fan-Namen**. Ohne Konto liegen die
gesamte Songwunsch-Liste und ihre Historie nur auf dem Gerät.

## Push-Benachrichtigungen

Wenn du angemeldet bist, kann die App dir eine **Push-Benachrichtigung** senden — aber nur,
wenn du sie pro Gerät einschaltest, und erst, nachdem das Betriebssystem deines Geräts die
Erlaubnis erteilt hat. Sie existiert für eine einzige Sache: ein Trinkgeld oder einen
Songwunsch, der eintrifft, **während du gerade kein Set spielst**, damit du von dem Trinkgeld
erfährst, das du sonst verpasst hättest. Ein Trinkgeld, das eintrifft, während deine Bühne
live ist, sendet nichts — du siehst es ohnehin schon.

- Um eine Push-Nachricht zuzustellen, braucht Googles **Firebase Cloud Messaging (FCM)** ein
  **Push-Token** für das Gerät. Wir speichern dieses Token und die Oberflächensprache des
  Geräts im geräteeigenen Datensatz unter deinem Konto, und es wird in dem Moment gelöscht, in
  dem du Benachrichtigungen ausschaltest, das Gerät widerrufst oder dich abmeldest. Tote
  Tokens werden automatisch entfernt.
- Die Benachrichtigung selbst sagt, was eingetroffen ist — ein Betrag und, falls hinterlassen,
  der Name eines Fans oder ein Songtitel. Dieselbe kurze Liste wird im **Glocken-Feed** deines
  Kontos vorgehalten, begrenzt auf die jüngsten hundert Einträge, damit du zurückscrollen
  kannst durch das, was hereinkam, während du weg warst.
- Im Web erfordert das Zustellen einer Push-Nachricht einen kleinen **Service Worker** im
  Wurzelverzeichnis der Seite und das Firebase-Messaging-SDK, das dein Browser beim ersten Mal
  von Google (`gstatic.com`) holt. Web-Push wird dann vom eigenen Push-Dienst deines Browsers
  befördert (bei Chrome ist das Googles). Nichts davon lädt, solange du Benachrichtigungen
  nicht eingeschaltet hast.
- **Ein Gastkonto und ein Gerät ohne Konto bekommen keine Push-Nachrichten**, denn eine
  Push-Nachricht braucht ein Konto, an das wir zustellen können, und ein Token, das du zu geben
  gewählt hast.

## Wo das alles physisch liegt

Firebase Auth, Cloud Firestore, unsere Cloud Functions und der Cloud-KMS-Schlüssel, der dein
Stripe-Geheimnis umschließt, laufen allesamt in der **Europäischen Union** — die Datenbank in
Googles Multiregion `eur3`, die Funktionen und der Schlüsselbund (Key Ring) in `europe-west1`.
Google handelt als unser Auftragsverarbeiter nach den
[Firebase-Datenschutz- und Sicherheitsbedingungen](https://firebase.google.com/support/privacy)
und seiner eigenen [Datenschutzerklärung](https://policies.google.com/privacy). Wie jeder
große Anbieter kann Google für Support und Sicherheit auch Infrastruktur außerhalb der EU
einbeziehen; das regeln jene Bedingungen, nicht wir. Push-Benachrichtigungen reisen, sobald
sie an Firebase Cloud Messaging und den Push-Dienst deines Browsers oder Telefons übergeben
sind, über die Infrastruktur jener Unternehmen, um dein Gerät zu erreichen.

## Stripe

Wenn ein Fan mit Karte zahlt, befindet er sich auf der Checkout-Seite von **Stripe**, nicht
auf unserer. Stripe erhebt und verarbeitet seine Zahlungsdaten als eigenständiger
Verantwortlicher nach der
[Stripe-Datenschutzerklärung](https://stripe.com/privacy). Wir sehen niemals Kartennummern.

Wie deine Trinkgelder dich erreichen, hängt vom Modus ab:

- **Ohne Konto** liest die App des Künstlers seine eigenen Trinkgelder mit dem eigenen
  eingeschränkten Schlüssel des Künstlers aus Stripe aus — direkt vom Gerät an
  `api.stripe.com`. **Auf diesem Weg gibt es keinen live.tips-Server.**
- **Wenn angemeldet**, liegt der Schlüssel auf unserem Server (verschlüsselt, wie oben), und
  Stripe meldet jedes Trinkgeld an unseren Webhook, der es in die eigene Firestore-Historie
  dieses Künstlers schreibt. **In diesem Modus steht ein live.tips-Server im Pfad** — für die
  Trinkgeld-Daten, nie für das Geld. Name und Nachricht eines Fans, falls hinterlassen,
  wandern mit dem Trinkgeld in die eigene Historie dieses Künstlers und enden dort.

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
Monzo-Benutzername) und, falls Songwünsche eingeschaltet sind, **seine öffentliche Songliste
und deren Preise je Song**. All das sind Informationen, die der Künstler ohnehin bewusst
gegenüber den Fans veröffentlicht.

- **Speicherdauer: Eine Trinkgeldseite ohne Konto dahinter wird nach 90 Tagen Inaktivität
  automatisch gelöscht.** Eine Trinkgeldseite, die zu einem angemeldeten Konto gehört, lebt
  so lange wie die Band, zu der sie gehört.
- Der Künstler kann sie jederzeit **sofort** aus der App löschen.
- Es werden hier niemals E-Mail-Adresse, Passwort, bürgerlicher Name oder Bankdaten erhoben.
- Das Geheimnis der Seite wird **nur als Hash** gespeichert. Wir könnten dir das Geheimnis
  nicht nennen, wenn du danach fragtest; wir können eines nur prüfen.

### Was ein Fan sendet

Das Trinkgeldformular fragt nach einem **Betrag** und optional nach einem **Namen** und einer
**Nachricht** — und, bei einem Songwunsch, nach welchem Song. Das ist das ganze Formular.
Keine E-Mail, keine Telefonnummer, kein Konto.

Wohin dieser von Fans geschriebene Text geht und wie lange, hängt davon ab, ob der Künstler
angemeldet ist:

- **Hat die Trinkgeldseite kein Konto dahinter**, wird das Trinkgeld in eine
  **Zustellwarteschlange** geschrieben — ein einzelnes Dokument, das nur dafür existiert, an
  den Bildschirm des Künstlers übergeben zu werden. Zeigt der Bildschirm das Trinkgeld an,
  **löscht das Gerät des Künstlers dieses Dokument.** Das Löschen *ist* die Bestätigung. Ist
  der Bildschirm des Künstlers offline — Handy gesperrt, kein Empfang —, **wartet das
  Trinkgeld bis zu einer Stunde in dieser Warteschlange**, damit es nicht einfach verloren
  geht, und geht in dem Moment hinüber, in dem der Bildschirm wieder verbunden ist. Verbindet
  sich niemand mehr, wird es **ungesehen gelöscht**, planmäßig weggeräumt. Für einen Künstler
  ohne Konto ist **diese Warteschlange der einzige Ort, an dem von Fans geschriebener Text auf
  unserem Server überhaupt gespeichert wird, und eine Stunde ist ihre harte Obergrenze.**
- **Gehört die Trinkgeldseite zu einem angemeldeten Konto**, gibt es keine Warteschlange.
  Unser Server schreibt das Trinkgeld **direkt in die eigene Historie dieses Künstlers** unter
  seiner uid — in die heutige Session, wenn ein Set läuft, oder sonst in das eigene Archiv der
  Band. Dort bleibt es, **solange die Band besteht**; es ist die eigene Historie des
  Künstlers, und genau dafür hat er sich angemeldet. Das ist dieselbe Historie, in die der
  Stripe-Webhook oben schreibt.
- Dein Name und deine Nachricht werden außerdem in den **Zahlungsverwendungszweck**
  eingesetzt, der sich in Revolut, MobilePay oder Monzo öffnet — so weiß der Künstler, wer
  Trinkgeld gegeben hat. Diese Unternehmen verarbeiten die Angaben dann nach ihren eigenen
  Datenschutzerklärungen.
- Das Relay führt **kein künstlerübergreifendes Trinkgeld-Kassenbuch**. Es kann weder dir noch
  uns noch sonst jemandem eine Liste darüber zeigen, wer wem über verschiedene Künstler hinweg
  Trinkgeld gegeben hat.

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
| **Google (Firebase)** | Konten, die synchronisierten Daten eines angemeldeten Künstlers, den verschlüsselten Stripe-Schlüssel, das Relay, Push-Tokens und deren Zustellung, Server-Logs | Das optionale Konto, das optionale Relay und Push-Benachrichtigungen |
| **Google Cloud KMS** | Den Schlüssel, der das Stripe-Geheimnis eines angemeldeten Künstlers umschließt (nie das Geheimnis im Klartext) | Den gespeicherten Stripe-Schlüssel im Ruhezustand unlesbar halten |
| **Stripe** | Die Zahlungsdaten des Fans, als eigenständiger Verantwortlicher; und, bei einem angemeldeten Künstler, die an unseren Webhook gesendeten Trinkgeld-Ereignisse | Trinkgelder per Karte |
| **Cloudflare** | Die IP des Fans, für die Turnstile-Prüfung auf der Trinkgeldseite. Und unser DNS. | Bots vom Trinkgeldformular fernhalten |
| **GitHub** | Die IP und den User-Agent aller, die diese Website laden | Hosting der Website |
| **Dein Browser / der Push-Dienst deines Telefons** (z. B. Googles bei Chrome) | Ein Push-Token und den Inhalt der Benachrichtigung, falls du Benachrichtigungen eingeschaltet hast | Push-Benachrichtigungen zustellen |
| **Revolut / MobilePay / Monzo** | Was auch immer der Fan in ihrer eigenen App tut, den Zahlungsverwendungszweck eingeschlossen | Diese Zahlungsmethoden |

Wir verkaufen nichts an niemanden, und sonst steht niemand auf dieser Liste.

## Rechtsgrundlage, falls du eine brauchst (DSGVO)

- Betrieb eines Kontos, um das du gebeten hast, Synchronisation deiner eigenen Daten auf
  deine eigenen Geräte, Verwahrung deines Stripe-Schlüssels, damit deine Trinkgelder in deine
  Historie gelangen, Betrieb des Relays für einen Künstler, der es eingeschaltet hat,
  Zustellung des Trinkgelds eines Fans an den Bildschirm, für den es bestimmt war, und Senden
  einer Push-Nachricht, die du eingeschaltet hast: **Erfüllung eines von dir angeforderten
  Dienstes**.
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
- **Push-Benachrichtigungen**: Schalte sie auf einem Gerät aus, und sein Push-Token wird
  gelöscht. Der Glocken-Feed wird mit der Band oder dem Konto geleert.
- **Ein Gerät**: Einstellungen → Sicherheit listet deine Geräte auf. Du kannst eines
  widerrufen oder dich überall sonst abmelden — was die Sitzung jedes anderen Geräts sofort
  beendet, nicht irgendwann.
- **Dein ganzes Konto, mit einem Tipp: Diesen Knopf hat die App noch nicht.** Das geben wir
  lieber zu, als etwas anderes vorzuspielen. Bis es ihn gibt, schreib an
  **[contact@live.tips](mailto:contact@live.tips)**, und wir löschen das Konto und alles
  darunter von Hand. In der Zwischenzeit kannst du schon jetzt jede Band löschen, was alles
  Wesentliche entfernt — einschließlich des gespeicherten Stripe-Schlüssels — und ein leeres
  Konto zurücklässt.

## Deine Rechte

Du kannst von uns eine Kopie all dessen verlangen, was wir über dich gespeichert haben, es
berichtigen oder löschen lassen, und du kannst dich bei deiner nationalen Datenschutzbehörde
beschweren. Schreib an **[contact@live.tips](mailto:contact@live.tips)**.

In der Praxis liegt das meiste davon ohnehin schon in deiner Hand: Ein Künstler kann eine
Trinkgeldseite oder eine Band sofort aus der App löschen, nicht zugestellte Trinkgelder von
Fans auf einer Seite ohne Konto verflüchtigen sich innerhalb einer Stunde, und wenn du dich
nie anmeldest, war nichts davon jemals irgendwo anders als auf deinem eigenen Gerät.

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
</content>
</invoke>
