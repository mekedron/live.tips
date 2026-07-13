# Jak live.tips obchodzi się z pieniędzmi (nijak)

> Nie ma salda live.tips, nie ma harmonogramu wypłat, nie ma prowizji. Oto architektura, dzięki której te trzy stwierdzenia są nudne, a nie odważne.

Canonical: https://live.tips/pl/blog/jak-live-tips-obchodzi-sie-z-pieniedzmi/
Published: 2026-07-02
Updated: 2026-07-13
Language: pl
Tags: Stripe, privacy, open source

---

Każdy słoik na napiwki może umieścić na swojej stronie „0% prowizji". Ciekawsze
pytanie brzmi: co oprogramowanie musiałoby zrobić, żeby *zacząć* pobierać swoją
część, i ile z tego dałoby się zobaczyć.

W przypadku live.tips odpowiedź brzmi: musiałoby zostać zbudowane od nowa. To nie
jest obietnica dotycząca naszych zamiarów, to opis tego, dokąd trafiają pieniądze.

## Napiwki kartą nigdy przez nas nie przechodzą

Kiedy fan dotyka kwoty na karcie, jego przeglądarka rozmawia z `api.stripe.com`.
Nie z serwerem live.tips — na tej drodze go nie ma. Płatność jest tworzona na
**twoim** koncie Stripe, trafia na **twoje** saldo Stripe i jest wypłacana według
**twojego** harmonogramu Stripe. Jedyną opłatą jest standardowa opłata za
przetwarzanie samego Stripe, którą Stripe pobiera od ciebie bezpośrednio,
dokładnie tak, jak zrobiłby to, gdybyś sam zintegrował Stripe.

Po naszej stronie nie ma żadnej księgi, bo nie ma czego zapisywać. Nie
moglibyśmy zgarnąć procentu, nie budując najpierw tego, co przechowuje pieniądze.

## Twoje klucze pozostają twoje

Konfiguracja prosi o *ograniczony* klucz API Stripe, a nie o prawdziwy klucz
tajny — te odrzucamy z góry. Jest przechowywany w pęku kluczy twojego własnego
urządzenia i wysyłany do Stripe wyłącznie przez TLS.

Ograniczony oznacza, że klucz może robić dwie rzeczy: utworzyć link do napiwków
„zapłać, ile chcesz" i obserwować napływające napiwki. Nie może odczytać twojego
salda, uruchomić wypłat, wystawić zwrotów ani dotknąć danych klientów. Gdyby
jutro wyciekł, promień rażenia to link do napiwków.

## Jedyny serwer na drodze płatności

Revolutem i MobilePay nie da się sterować z przeglądarki tak jak Stripe, więc ich
włączenie uruchamia minimalny przekaźnik — garstkę funkcji Firebase serwujących
twoją stronę napiwków pod adresem `tip.live.tips`. Warto być precyzyjnym co do
tego, co ten przekaźnik robi, bo „dodaliśmy backend" to zwykle moment, w którym
takie historie idą źle.

Przechowuje publiczny profil twojej strony napiwków — wyświetlaną nazwę i
identyfikatory płatności, które zdecydowałeś się opublikować. To wszystko. Nie
prowadzi historii napiwków, nie widzi pieniędzy, nie trzyma kluczy i samoczynnie
usuwa się po 90 dniach bezczynności. Napiwek z Revoluta czy MobilePay czeka tam
tylko do chwili, aż odbierze go twoje sceniczne urządzenie: wyświetlenie powoduje
jego usunięcie, a to, po co nikt nie wrócił, zostaje sprzątnięte w ciągu godziny.
Pieniądze nadal przepływają bezpośrednio między aplikacją Revolut lub MobilePay
twojego fana a twoją.

Jeśli używasz tylko Stripe, przekaźnik nigdy nie zostaje w ogóle wywołany.

## Konto, którego nie musisz zakładać

Aplikacja nadal startuje w profilu żyjącym wyłącznie na urządzeniu, tak jak było
zawsze: twój słoik na napiwki, twój klucz i twoja historia napiwków są na
urządzeniu i nigdzie indziej. Nie ma się do czego zapisywać.

Zalogowanie się — przez Apple, przez Google albo jako gość — jest teraz możliwe i
istnieje z jednego powodu: drugie urządzenie. Jeśli tablet na scenie i telefon w
twojej kieszeni mają pokazywać ten sam wieczór, coś musi znaleźć się między nimi, a
tym czymś jest Firestore, pod identyfikatorem użytkownika, który tylko ty możesz
odczytać. Twoje zespoły, ustawienia, ograniczony klucz i historia napiwków
synchronizują się właśnie tam. To realna zmiana w opowieści o prywatności i
zasługuje na to, by powiedzieć ją wprost, a nie zostawić do odkrycia: bez konta
żaden serwer nigdy nie widzi napiwku; z kontem widzi go twój własny kąt naszego. To
cena drugiego urządzenia i tylko od ciebie zależy, czy ją zapłacisz, czy odmówisz.
Czego to nigdy nie dotyka, to pieniądze — konto przenosi twoje dane, a nie twoje
saldo, i nadal nie pobieramy żadnej prowizji.

## Dlaczego nie powinieneś wierzyć nam na słowo

Wszystko powyższe da się sprawdzić. Kod źródłowy jest na licencji MIT i jest
publiczny, a strona to statyczna kompilacja wdrażana przez GitHub Actions na
GitHub Pages — żadnej ukrytej infrastruktury, nic skompilowanego za zamkniętymi
drzwiami. Otwórz zakładkę sieci podczas demonstracyjnego napiwku i przeczytaj
żądania. Jest ich mniej, niż się spodziewasz.

To jest właśnie prawdziwe twierdzenie o produkcie. Nie to, że jesteśmy godni
zaufania, ale że nie potrzebujesz, żebyśmy tacy byli.
