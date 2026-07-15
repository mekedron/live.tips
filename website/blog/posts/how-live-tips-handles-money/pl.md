---
title: Jak live.tips obchodzi się z pieniędzmi (nijak)
description: Nie ma salda live.tips, nie ma harmonogramu wypłat, nie ma prowizji. Oto architektura, dzięki której te trzy stwierdzenia są nudne, a nie odważne.
slug: jak-live-tips-obchodzi-sie-z-pieniedzmi
---

Każdy słoik na napiwki może umieścić na swojej stronie „0% prowizji". Ciekawsze
pytanie brzmi: co oprogramowanie musiałoby zrobić, żeby *zacząć* pobierać swoją
część, i ile z tego dałoby się zobaczyć.

W przypadku live.tips odpowiedź brzmi: musiałoby zostać zbudowane od nowa. To nie
jest obietnica dotycząca naszych zamiarów, to opis tego, dokąd trafiają pieniądze.

## Pieniądze nigdy przez nas nie przechodzą

Kiedy fan dotyka kwoty na karcie, płatność jest tworzona na **twoim** koncie
Stripe, trafia na **twoje** saldo Stripe i jest wypłacana według **twojego**
harmonogramu Stripe. Jedyną opłatą jest standardowa opłata za przetwarzanie samego
Stripe, którą Stripe pobiera od ciebie bezpośrednio, dokładnie tak, jak zrobiłby
to, gdybyś sam zintegrował Stripe.

Po naszej stronie nie ma żadnej księgi, bo nie ma czego zapisywać. Nie
moglibyśmy zgarnąć procentu, nie budując najpierw tego, co przechowuje pieniądze —
a czegoś takiego nie ma.

Jest tak niezależnie od tego, czy się zalogujesz. Zalogowanie zmienia drogę
*danych*, a nie drogę pieniędzy, i dwa kolejne rozdziały są szczere co do tego, jak
dokładnie.

## Twoje klucze i gdzie mieszkają

Konfiguracja prosi o *ograniczony* klucz API Stripe, a nie o prawdziwy klucz
tajny — te odrzucamy z góry. Ograniczony oznacza, że klucz może robić dwie rzeczy:
utworzyć link do napiwków „zapłać, ile chcesz" i obserwować napływające napiwki.
Nie może odczytać twojego salda, uruchomić wypłat, wystawić zwrotów ani dotknąć
danych klientów. Gdyby jutro wyciekł, promień rażenia to link do napiwków.

**Bez konta ten klucz nigdy nie opuszcza twojego urządzenia.** Leży w pęku kluczy
samego urządzenia i jest wysyłany wyłącznie do `api.stripe.com` przez TLS. Żadnego
serwera live.tips nie ma tu w ogóle w kadrze.

**Kiedy się logujesz, klucz przenosi się do nas** — bo klucz, który istnieje tylko
na jednym telefonie, nie obsłuży też tabletu na scenie. Szyfrujemy go (klucz
AES-256 osobny dla każdego sekretu, sam opakowany przez Google Cloud KMS) i
przechowujemy tam, gdzie nikt nie może go odczytać z powrotem: ani inne konto, ani
my zerkając do bazy danych, ani nawet ty. Jest odpieczętowywany wyłącznie wewnątrz
naszych funkcji, używany do rozmowy ze Stripe w twoim imieniu i nigdy więcej nie
jest przekazywany urządzeniu. Powiedzmy to wprost: zalogowanie umieszcza serwer
live.tips na drodze między Stripe a twoją historią napiwków. Nigdy pieniądze —
dane.

## Serwery i czego nie potrafią

Są dwa i oba są minimalne.

**Przekaźnik** istnieje, bo Revolutem i MobilePay nie da się sterować z
przeglądarki tak jak Stripe. Ich włączenie uruchamia garstkę funkcji Firebase
serwujących twoją stronę napiwków pod adresem `tip.live.tips`. Przechowuje
publiczny profil twojej strony napiwków — wyświetlaną nazwę i identyfikatory
płatności, które zdecydowałeś się opublikować — a w przypadku strony, za którą nie
stoi żadne konto, nie prowadzi żadnej historii napiwków: napiwek czeka tylko do
chwili, aż pokaże go twoje sceniczne urządzenie, a to, po co nikt nie wrócił,
zostaje sprzątnięte w ciągu godziny. Nie widzi pieniędzy i samoczynnie usuwa się po
90 dniach bezczynności. Jeśli używasz tylko Stripe i nigdy się nie logujesz,
przekaźnik nie zostaje w ogóle wywołany.

**Webhook** istnieje dopiero wtedy, gdy się zalogujesz. Ponieważ twój klucz mieszka
teraz u nas, Stripe zgłasza każdy napiwek małej naszej funkcji, która zapisuje go w
twojej własnej historii, żeby mogły go pokazać twoje pozostałe urządzenia. To kopia
zdarzenia, a nie kopia pieniędzy. Nie może ruszyć ani centa i może zapisywać
wyłącznie do tego jednego konta, do którego należy.

Żaden z serwerów nie może pobrać prowizji, bo żaden nie znajduje się nigdzie w
pobliżu pieniędzy. Najwięcej, co któryś może zrobić, to zawieść — a konfiguracja
oparta wyłącznie na Stripe, bez konta, nie zależy od żadnego z nich.

## Konto, którego nie musisz zakładać

Aplikacja nadal startuje w profilu żyjącym wyłącznie na urządzeniu, tak jak było
zawsze: twój słoik na napiwki, twój klucz i twoja historia napiwków są na
urządzeniu i nigdzie indziej. Nie ma się do czego zapisywać.

Zalogowanie się — przez Apple, przez Google albo jako gość — jest teraz możliwe i
istnieje z jednego powodu: drugie urządzenie. Jeśli tablet na scenie i telefon w
twojej kieszeni mają pokazywać ten sam wieczór, coś musi znaleźć się między nimi, a
tym czymś jest Firestore, pod identyfikatorem użytkownika, który tylko ty możesz
odczytać. Twoje zespoły, ustawienia, historia napiwków — i, zaszyfrowany jak wyżej,
twój klucz Stripe — mieszkają właśnie tam. To realna zmiana w opowieści o
prywatności i zasługuje na to, by powiedzieć ją wprost, a nie zostawić do odkrycia:
bez konta żaden serwer nigdy nie widzi napiwku; z kontem widzi go twój własny kąt
naszego, a zapisuje go tam nasz webhook. To cena drugiego urządzenia i tylko od
ciebie zależy, czy ją zapłacisz, czy odmówisz. Czego to nigdy nie dotyka, to
pieniądze — konto przenosi twoje dane, a nie twoje saldo, i nadal nie pobieramy
żadnej prowizji.

## Dlaczego nie powinieneś wierzyć nam na słowo

Wszystko powyższe da się sprawdzić. Kod źródłowy jest na licencji MIT i jest
publiczny, a strona to statyczna kompilacja wdrażana przez GitHub Actions na
GitHub Pages — żadnej ukrytej infrastruktury, nic skompilowanego za zamkniętymi
drzwiami. Otwórz zakładkę sieci podczas demonstracyjnego napiwku i przeczytaj
żądania. Jest ich mniej, niż się spodziewasz.

To jest właśnie prawdziwe twierdzenie o produkcie. Nie to, że jesteśmy godni
zaufania, ale że nie potrzebujesz, żebyśmy tacy byli.
