# Bau dir eine Trinkgeldkasse auf deinem eigenen Stripe-Konto

> Drei API-Aufrufe geben dir eine gehostete Pay-what-you-want-Seite mit Apple Pay und Google Pay — ganz ohne Server. Hier ist der komplette Bau: der Restricted Key, die Berechtigungen, wie du Trinkgelder ohne Webhook zurücklieferst, und die Gebührenrechnung, die niemand abdruckt.

Canonical: https://live.tips/de/blog/trinkgeldkasse-auf-deinem-eigenen-stripe-konto/
Published: 2026-07-11
Language: de
Tags: Stripe, open source, how-to, API, fees

---

Du willst eine Trinkgeldkasse. Du willst keiner Plattform 5 % vom Abend eines
Straßenmusikers überlassen, und du kommst mit einer API bestens zurecht. Die Frage
ist also nicht *bei welcher Trinkgeldkasse melde ich mich an*, sondern *wie viel
muss ich eigentlich bauen*.

Weniger, als du denkst. Auf Stripe lautet die praktische Antwort: drei
API-Aufrufe, kein Server, kein Backend, kein Webhook-Endpunkt. Der Rest dieses
Beitrags ist genau dieser Bau — plus die zwei Dinge, die dabei alle falsch machen.

## Der Trick ist ein Pay-what-you-want-Price

Stripe kennt einen Preismodus, bei dem der Fan den Betrag selbst eintippt. Er heißt
[Pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want),
und er ist das ganze Feature. Du legst ein Product an, hängst einen Price mit
`custom_unit_amount[enabled]=true` daran und darüber einen
[Payment Link](https://docs.stripe.com/payment-links/create).

```sh
# 1. das Ding, das du "verkaufst"
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. der Preis, den der Fan wählen darf
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. die Seite
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

Der dritte Aufruf liefert eine `url` zurück. Diese URL *ist* deine Trinkgeldkasse.
Sie ist eine von Stripe gehostete Seite — also PCI-konform, ohne dass du darüber
nachdenken musst, lokalisiert, und sie zeigt Apple Pay oder Google Pay bei jedem
Fan, dessen Telefon das eingerichtet hat.
[Dynamic payment methods](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
entscheiden das für dich, je nach Gerät und Land. Du hast kein Frontend
geschrieben.

Kodiere die URL mit irgendeiner Bibliothek als QR-Code — es ist nur ein String —
drucke ihn, klebe ihn auf den Koffer. Der Code läuft nie ab, und er zeigt auf
keinen Server von dir, weil du keinen hast.

Zwei Parameter, die du kennen solltest:

- **`custom_unit_amount[preset]`** ist der Betrag, mit dem die Seite öffnet. `500`
  heißt: der Fan sieht bereits 5,00 € eingetragen und kann das ändern. Diese Zahl
  tut mehr für dein durchschnittliches Trinkgeld als alles andere auf der Seite.
- **`custom_unit_amount[minimum]`** ist eine Untergrenze. Setz sie. Warum, steht im
  Gebühren-Abschnitt weiter unten, und es ist kein Rundungsfehler.

Du kannst auch Namen und Nachricht einsammeln. Payment Links nehmen bis zu drei
`custom_fields` — so bekommst du "von wem war das denn" auf die Seite, ohne ein
Formular zu bauen:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Dein Name oder Spitzname" \
  -d "custom_fields[0][optional]"=true
```

Stripe hat [Anforderungen für Trinkgelder und Spenden](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations) —
lies sie einmal. Pay what you want lässt sich außerdem nicht mit weiteren Line
Items, Rabatten oder wiederkehrenden Zahlungen kombinieren. Für eine
Trinkgeldkasse stört nichts davon.

Diese Unterscheidung lohnt sich. Stripe formuliert es so: Ein Trinkgeld wird für eine
bereits erbrachte Leistung gegeben, eine Spende muss an einen wohltätigen Zweck gebunden
sein. Du hast gespielt; das Trinkgeld bezahlt das. Deshalb schickt der Aufruf oben auch
`submit_type=pay` und nicht `donate` — `donate` würde deinen Link auf `donate.stripe.com`
legen und *Spenden* auf den Button schreiben. Das ist ein anderes Geschäft, und eines, das
Stripe deutlich strenger prüft.

## Der Key: nimm an, dass er leakt — und mach das langweilig

Leg keinen Secret Key (`sk_live_…`) auf ein Gerät, das auf einer Bühne steht. Nimm
einen [Restricted Key](https://docs.stripe.com/keys/restricted-api-keys)
(`rk_live_…`): Du wählst eine Berechtigung pro Ressource, und alles, was du nicht
wählst, steht auf **None**.

Für den Bau oben ist die vollständige Liste fünf Zeilen lang:

| Ressource | Berechtigung | Wofür |
| --- | --- | --- |
| Products | Write | das Product anlegen |
| Prices | Write | den Pay-what-you-want-Price anlegen |
| Payment Links | Write | den Link anlegen |
| Checkout Sessions | Read | die eingegangenen Trinkgelder sehen |
| Events | Read | der Live-Feed (nächster Abschnitt) |

Alles andere — Balance, Payouts, Refunds, Customers, PaymentIntents, das gesamte
Connect — bleibt auf **None**.

Und jetzt die Übung, die das Ganze überhaupt lohnenswert macht. Dein Tablet wird um
1 Uhr nachts vom Merch-Tisch geklaut. Was kann der Dieb mit dem Key im Keychain
anfangen? Deine Trinkgeld-Historie lesen und weitere Trinkgeld-Links in deinem Konto
anlegen. Das ist der gesamte Schadensradius. Er sieht dein Guthaben nicht, kann
keine Auszahlung auslösen, keine Rückerstattung auf eine Karte schicken, die ihm
gehört, keine Kundenliste lesen. Du widerrufst den Key vom Handy im Taxi nach Hause,
und das Gerät geht dunkel. Von deinem Geld hat sich nichts bewegt.

Diese Asymmetrie — Schreibzugriff auf die Trinkgeldkasse, null Zugriff auf das Geld
— ist der einzige Grund, warum ein serverloses Bring-your-own-key-Design überhaupt
vertretbar ist. Sie ist auch der Grund, warum "Login with Stripe" hier nicht die
Antwort ist: OAuth braucht einen Server des App-Entwicklers, der dein Token hält —
und ein Server ist genau das, was wir nicht bauen.

(Eine Eigenheit, über die du stolpern wirst: die *Prices*-Berechtigung heißt intern
`plan_write`. Stripes Fehlermeldung nennt also einen Scope, der im Dashboard unter
diesem Namen gar nicht auftaucht. Gemeint ist Prices.)

## Trinkgelder ohne Webhook zurücklesen

Hier hören die meisten Anleitungen auf oder greifen zum Webhook — und hier
unterscheidet sich eine Bühne wirklich von einer Web-App.

Ein Webhook ist ein eingehender HTTP-Request. Ein Tablet hinter einem
Mikrofonständer kann keinen empfangen. Es hängt im Gäste-WLAN einer Location hinter
NAT, hat keine öffentliche Adresse, kein TLS-Zertifikat — und braucht das alles auch
nicht. Nimmst du den Webhook-Weg, musst du einen Server aufsetzen, der die Events
fängt, und einen Socket, der sie aufs Gerät schiebt: ein Backend, Betriebsaufwand,
und ein Ort, an dem jetzt die Namen deiner Fans liegen. Du hast gerade die
Plattform nachgebaut, die du vermeiden wolltest.

Also zieh, statt dich schieben zu lassen. Stripes Endpunkt
[List all events](https://docs.stripe.com/api/events/list) ist öffentlich,
dokumentiert und liefert Events neueste-zuerst:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_LETZTES_GESEHENES \
  -d limit=100
```

`ending_before` ist das ganze Design. Merk dir die ID des neuesten Events, das du
verarbeitet hast; jeder Poll fragt nach allem, was strikt neuer ist, und du schiebst
den Cursor weiter. Keine Zeitstempel, kein Clock Skew, kein Deduplizieren über
Beträge. Beim ersten Poll eines Sets fragst du mit `limit=1` und ohne Cursor, um dich
auf das zu verankern, was schon da ist — sonst spielst du beim Soundcheck die
Trinkgelder von heute Morgen nochmal ab.

Dann filtere, was zurückkommt. Beide Event-Typen können für *eine* Zahlung feuern,
also dedupliziere über die Checkout-Session-ID. Prüfe `payment_status == "paid"` —
eine abgeschlossene Session ist nicht zwingend eine bezahlte. Und prüfe, dass
`payment_link` *deinem* Link entspricht, denn `/v1/events` gilt kontoweit und
reicht dir bereitwillig den Traffic von allem anderen durch, was dieses
Stripe-Konto sonst noch tut.

Sei ehrlich zu den Kompromissen, denn sie sind real:

- **Stripe empfiehlt Webhooks.** Polling ist nicht der gesegnete Pfad; es ist ein
  dokumentierter Endpunkt, den man bewusst einsetzt. Schreib das in deine README
  und gut ist.
- **Events reichen 30 Tage zurück.** [Stripes eigene Worte](https://docs.stripe.com/api/events/list):
  *"List events, going back up to 30 days."* Das ist ein Live-Feed, kein Hauptbuch.
  Dein Hauptbuch sind die Checkout Sessions — und dein echtes Hauptbuch ist das
  Stripe-Dashboard.
- **Achte auf das Read-Kontingent.** Alle schauen auf das Limit pro Sekunde
  ([Rate Limits](https://docs.stripe.com/rate-limits): 100 req/s live) und niemand
  auf das andere: Stripe gewährt etwa **500 Lese-Requests pro Transaktion** über
  rollierende 30 Tage, mit einem Boden von 10.000 Reads pro Monat. Poll alle 4
  Sekunden, und ein dreistündiges Set sind ~2.700 Reads. Vier lange Gigs im Monat,
  und du bist am Boden. Trinkgelder kaufen dir Luft, sobald sie eintreffen — aber
  wer im Sekundentakt pollt, weil es sich flotter anfühlte, findet die Decke. Vier
  Sekunden sind keine faule Zahl; das *ist* die Zahl.

So sieht es ehrlich aus: Polling kostet dich ein paar tausend GETs und erspart dir
ein komplettes Backend.

## Die Gebührenrechnung, sauber gemacht

Eine Plattform, die mit 0 % wirbt, ist nicht kostenlos — und das hier auch nicht.
Stripes eigene Bearbeitungsgebühr fällt auf jedes Trinkgeld an, und Stripe stellt
sie dir direkt in Rechnung. Heute kostet eine Standard-EWR-Karte laut
[Stripes Euro-Preisliste](https://stripe.com/ie/pricing) **1,5 % + 0,25 €**.
Premium-EWR-Karten 1,9 % + 0,25 €, UK-Karten 2,5 % + 0,25 €, alles andere 3,25 % +
0,25 € plus 2 %, wenn eine Währung umgerechnet werden muss. (In den USA sind es
2,9 % + 0,30 $, was aus dem folgenden Grund schlechter ist.)

Das Problem ist nicht der Prozentsatz. Es sind die fünfundzwanzig Cent.

| Trinkgeld | Stripe nimmt | Künstler behält | Effektiver Anteil |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **14,0 %** |
| 5 € | 0,33 € | 4,67 € | 6,5 % |
| 10 € | 0,40 € | 9,60 € | 4,0 % |
| 20 € | 0,55 € | 19,45 € | 2,8 % |
| 50 € | 1,00 € | 49,00 € | 2,0 % |

Eine Pauschalgebühr ist ein verkleideter Prozentsatz, und bei kleinem Geld rutscht
die Verkleidung. Dieselben 0,25 €, die bei 50 € unsichtbar sind, fressen ein Achtel
eines 2-€-Trinkgelds. Trinkgelder sind naturgemäß klein — deshalb sind es
Trinkgelder — das ist also kein Randfall, das ist der Regelfall.

Genau darum setzt du `custom_unit_amount[minimum]`. Irgendwo um 2 € lohnt sich die
Transaktion schlicht nicht mehr; ein 0,50-€-Kartentrinkgeld käme als 0,24 € an und
kostet Stripe mehr an Bewegung, als es wert ist. Wähle deine Untergrenze bewusst,
statt sie bei der ersten Auszahlung zu entdecken.

Und sieh, was das mit dem Vergleich macht, mit dem du angefangen hast. Eine
Plattform, die 0 % *auf Stripe obendrauf* nimmt, nimmt 0 % auf **genau das** hier.
Ihre 0 % sind echt — und es sind 0 % von dem, was der Zahlungsdienstleister übrig
gelassen hat. Niemandes Kartenschiene ist gratis. Die ehrliche Aussage lautet "kein
Anteil über den des Prozessors hinaus", und wer mehr behauptet, lügt entweder oder
benutzt keine Karten.

## Was du jetzt hast — und was nicht

Drei API-Aufrufe und einen QR-Code, und eine echte Trinkgeldkasse: gehostet,
PCI-konform, Apple Pay, Google Pay, Trinkgelder, die in deinem eigenen
Stripe-Guthaben landen, nach deinem eigenen Auszahlungsplan, ohne Server im Weg.
Für viele Leute ist das tatsächlich das Ende des Projekts, und du darfst hier
gerne aufhören und ausliefern.

Was du nicht hast, ist eine Bühne. Du hast eine Zahlungsseite. Dazwischen liegen die
langweiligen Dinge: die Poll-Schleife mit Cursor und Backoff, ein Bildschirm, den das
Publikum sehen kann, mit Ziel und letzter Nachricht darauf, ein Ort für den Key, der
nicht `localStorage` heißt, eine Sperre, damit kein Fremder zwischen den Sets aufs
Tablet tippt — und die tausend kleinen Entscheidungen dazu, was passiert, wenn das
WLAN der Location mitten im Set wegbricht.

Genau das ist [live.tips](https://github.com/mekedron/live.tips) — exakt diese
Architektur, fertig gebaut, MIT-lizenziert. Der Restricted Key mit diesen fünf
Berechtigungen, die `/v1/events`-Cursor-Schleife, das Anlegen von
Product/Price/Payment Link, alles auf dem Gerät des Künstlers gegen dessen eigenes
Konto. Im Stripe-Pfad steht kein live.tips-Server, und ein live.tips-Guthaben gibt es
nirgends — das haben wir separat aufgeschrieben in
[wie live.tips mit Geld umgeht](https://live.tips/de/blog/wie-live-tips-mit-geld-umgeht/).

Lies den Quellcode, nimm dir raus, was du brauchst, oder benutz es einfach. Der Punkt
dieses Beitrags ist, dass die Architektur weder ein Geheimnis noch schwer ist:
**Stripe hostet deine Trinkgeldkasse umsonst, und ein Restricted Key plus eine
Poll-Schleife sind alles, was zwischen einem Künstler und seinem eigenen Geld
steht.** Uns ist lieber, du weißt das, als dass du dich irgendwo anmeldest.
