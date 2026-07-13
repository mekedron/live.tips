# Bahşiş bağış değildir — ve Stripe bunları iki ayrı iş kolu sayar

> «Bağış butonu» isteyen bir sokak müzisyeni, aslında Stripe'ın Avrupa'nın büyük bölümünde yasakladığı bir iş kolunu tarif ediyordur. Bahşiş, zaten yaptığın bir hizmetin karşılığıdır; bağış ise hayır amaçlı para toplamaktır. Bu fark, hesabının hangi kategoriye düşeceğine karar verir — ve tek bir API parametresi bu seçimi senin yerine yapabilir.

Canonical: https://live.tips/tr/blog/bahsis-bagis-degildir/
Published: 2026-07-11
Language: tr
Tags: Stripe, donations, busking, compliance, how-to

---

İnternetteki her araç, ona bağış demeni istiyor. Butonlarda *Donate* yazıyor.
Blog yazıları *müzisyenler için bağış butonu* diyor. Eklenti dizinleri *bağış
kabul et* diyor. Nakit taşımayan insanlardan para almanın bir yolunu arayan bir
müzisyensen, o kelime her yerde peşini bırakmıyor.

Sonra bir Stripe hesabı açıyorsun ve Stripe sana işinin ne olduğunu soruyor. İşte
o anda kelime bir pazarlama metni olmaktan çıkıp bir **iş kategorisine**
dönüşüyor — Avrupa'nın büyük bölümünde Stripe'ın izin vermediği bir kategoriye.

Bu bir kılı kırk yarma meselesi değil, avukat ayrıntısı da değil. Gayet sıradan
bir sokak müzisyeninin ödeme hesabının incelemeye alınmasına, geciktirilmesine ya
da reddedilmesine yol açması en muhtemel tek soru bu. Bunu sahneye çıkan insanlar
için açık açık yazan neredeyse kimse olmadığı için, buyur, işte burada.

## İki kelime, iki iş kolu

Stripe sınırı kendisi çiziyor, birer cümleyle.
[Bahşiş veya bağış kabul etme koşulları](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations)
sayfasından:

> bir bahşiş, sağlanmış bir mal veya hizmet karşılığında verilmelidir (ör. içerik)

> bir bağış, gerçekleştirmeyi taahhüt ettiğin belirli bir hayır amacına bağlı
> olmalıdır

Stripe'ın sayfaları İngilizce; buradaki alıntıları okur için biz çevirdik,
orijinalleri bağlantıların arkasında duruyor.

Bu iki cümleyi iki kez oku, çünkü bu yazıdaki her şey onlardan çıkıyor.

Bir **bahşiş** geriye, olmuş bitmiş bir şeye bakar. Hizmet verildi, hayran
beğendi, hayran üstüne biraz para verdi. Para koşulsuzdur ve artık kimseye bir
borcun yoktur. Restoran hesabındaki bahşiş satırı budur, şapkanın içindeki
bozukluklar budur, son şarkıdan sonra avuca sıkıştırılan beşlik budur.

Bir **bağış** ise ileriye, yapacağına söz verdiğin bir şeye bakar. Ortada bir dava
vardır. Parayı verene anlattığın bir amaç vardır. Ve — Stripe bu konuda açık —
paranın gerçekten o amaca gitmesi gerekir. Onu, gerçekleştireceğini söylediğin bir
şey için emanet tutuyorsundur.

Bunlar aynı hareketin iki tonu değil. İki farklı ilişki, iki farklı yükümlülük
seti, ve Stripe bunları iki farklı iş kolu olarak değerlendiriyor.

## Sokak müzisyeni tartışmasız biçimde bahşiş tarafındadır

Bir meydanda iki saat durup çaldın. Kırk kişi durup dinledi. İçlerinden biri
kodunu tarayıp sana beş euro gönderdi.

**Bu bir bahşiştir.** Performans, hizmettir. Sağlanmıştır — olurken izlediler.
Ortada bir dava yok, bir yararlanıcı yok, gerçekleştirmeyi taahhüt ettiğin bir
amaç yok, kimse sana bir proje için para emanet etmedi. Sen bir performans
karşılığında para alan bir sahne sanatçısısın; bu da dünyanın en eski ve en az
tartışmalı ticari düzenlerinden biri.

Kafa karışıklığı, sokak müzisyeninin bahşişinin *gönüllü* olmasından geliyor; biz
de gönüllü verilen paranın hayır parası olduğunu düşünmeye alıştırılmışız. Öyle
değil. Bahşiş de gönüllüdür. Bir şeyi bağış yapan şey gönüllülük değil, **hayır
amacı**dır.

Yani tabelanda «bağışlarınızı bekleriz» yazdığında alçakgönüllü ya da nazik
olmuyorsun. Ödeme kuruluşunun sözlüğünde, içinde olmadığın bir işi tarif ediyorsun.

## O kelimenin sana gerçek maliyeti

Soyutlamanın paraya dönüştüğü yer burası.

Stripe bir
[kısıtlı işler listesi](https://stripe.com/legal/restricted-businesses)
yayımlıyor — bir Stripe hesabıyla yapamayacağın, ya da yalnızca bazı ülkelerde
yapabileceğin şeyler. **Kitlesel fonlama ve bağış toplama** başlığının altında,
kelimesi kelimesine şu satır duruyor:

> Hayır amacıyla para toplayan kuruluşlar (Not: Avustralya, Kanada, Birleşik
> Krallık ve Amerika Birleşik Devletleri'nde desteklenir. Diğer tüm ülkelerde
> yasaktır.)

Parantezi yavaş oku. Hayır amaçlı para toplama **dört ülkede desteklenen bir
iştir** — Avustralya, Kanada, Birleşik Krallık, ABD — ve **geri kalan her yerde
yasaktır.**

Geri kalan her yer Türkiye'yi de kapsıyor. Almanya'yı, Fransa'yı, İspanya'yı,
İtalya'yı, Hollanda'yı, Polonya'yı, Finlandiya'yı ve bir sokak müzisyeninin makul
olarak durabileceği diğer bütün ülkeleri de. Dünyadaki sokak müzisyenlerinin
çoğu «diğer tüm ülkeler» içinde yaşıyor.

Aynı sayfa ayrıca *«kâr amacı gütmeyen kuruluşlar, hayır kurumları, siyasi
örgütler ve bağış karşılığında bir ödül sunan işletmeler tarafından yürütülen
bağış toplama»* faaliyetini de kısıtlı sayıyor; Stripe'ın bahşiş-ve-bağış sayfası
ise bunun üstüne ülkeye özel bir dizi kural ekliyor: Japonya'da bireyler hiçbir
şekilde bağış alamıyor; Singapur'da yalnızca devlete kayıtlı hayır veya dini
kuruluşlar alabiliyor; Hindistan, Hong Kong ve Tayland'da bağışlar
desteklenmiyor.

Yani İstanbul'daki bir müzisyen, Stripe kayıt formuna «müziğim için bağış» yazdığı
anda, Stripe'ın Türkiye'de yasakladığı bir işi tarif etmiş oluyor. Sokakta çalmak
yasak olduğu için değil — sokakta çalmak gayet serbest — seçtiği kelimeler yasak
olan bir kategoriye ait olduğu için.

## Şimdi ölçeği ayarlayalım, çünkü bu bir korku hikâyesi değil

**Sokak müzisyenleri kısıtlı bir iş değildir.** Bahşiş kısıtlı bir iş değildir.
Canlı performans o listede yok, seni o listeye sokmaz ve bir ödeme hesabıyla
yapabileceğin en sıradan şeylerden biridir. Kendini doğru tarif edersen bunların
hiçbiri sana dokunmaz, kurulum sıkıcı geçer, ki olması gereken de tam olarak budur.

Buradaki risk Stripe değil. Risk, **kendini yanlış sınıflandırmak** — bir gitarist
olduğun halde odaya girip kendini hayır amaçlı para toplayan biri olarak takdim
etmek. Stripe'ın senin «lütfen bahşiş ver» demek istediğini bilmesinin hiçbir yolu
yok. Elinde yalnızca doldurduğun form, yazdığın iş tanımı ve QR kodunun işaret
ettiği sayfadaki kelimeler var.

Stripe'ta kimse sokak müzisyeni avlamıyor. Yalnızca onlara söylediğini okuyorlar.

## Tuzak tek bir parametre derinliğinde

İşte neredeyse kimsenin yazmadığı kısım, ve bu yazıdaki en işe yarar şey de bu.

Stripe'ın Payment Link'lerinin `submit_type` adında bir parametresi var.
[API referansı](https://docs.stripe.com/api/payment-link/object) onu neredeyse
kozmetik bir şeymiş gibi anlatıyor:

> Sayfadaki ilgili metni — örneğin gönder butonunu — özelleştiren işlem türünü
> belirtir.

*İlgili metni özelleştirir.* Bundan makul olarak bir buton etiketinin değiştiği
sonucunu çıkarırsın, ve bir bahşiş kavanozunun *Buy* yerine elbette *Donate*
demesi gerektiğini düşünürsün, çünkü *Buy* (satın al) bir sokak müzisyeninin
şapkasının altına basılacak tuhaf bir kelimedir.

Sonra tek tek değerlerin ne yaptığını okursun:

> `donate` — Bağış kabul ederken önerilir. Gönder butonunda 'Donate' etiketi yer
> alır ve URL'ler `donate.stripe.com` alan adını kullanır

> `pay` — Gönder butonunda 'Buy' etiketi yer alır ve URL'ler `buy.stripe.com` alan
> adını kullanır

**Bu bir etiket değil. Bu bir alan adı.** `submit_type=donate` ayarla, ve Stripe'ın
sana verdiği bağlantı — QR koduna çevirip bastığın, gitar kutuna bantladığın o
bağlantı — `donate.stripe.com` üzerinde yaşar. Onu tarayan her hayran bir bağış
sayfası görür. Panelindeki her ödeme bir bağış akışından geçmiştir. Kutunun
üstündeki QR kodu Stripe'a, seyircine ve nihayetinde sana, bağış topladığını
söylüyordur.

«Bağış» kelimesini hiçbir yere yazmadın. Tek bir API parametresi senin yerine
yazdı, ve onu bir meydanda plastik bir tabelaya bastı.

Bu, içine düşülmesi kolay bir tuzak ve düşen kişinin suçu da değil: parametre bir
metin değişikliği olarak belgelenmiş, *Donate* bir sokak müzisyeninin şapkasının
altına basılacak açıkça daha hoş kelime, ve sonucu — bir iş sınıflandırması —
sayfada çoğu insanın okumayı bıraktığı yerden iki cümle aşağıda duruyor.

live.tips `submit_type=pay` gönderir. Her sanatçının bağlantısı bir
`buy.stripe.com` bağlantısıdır ve kodda bunun nedenini açıklayan bir yorum satırı
vardır, çünkü bu, ileride bir katkıcının aksi halde «iyileştirmeye» kalkışacağı
türden bir şeydir.

## Bir müzisyen aslında ne yapmalı

Bunların hiçbiri avukat gerektirmiyor. Beş dakika ve birkaç düz kelime gerektiriyor.

- **Gerçek işini tarif et**, Stripe kaydında. «Canlı müzik performansı.» «Sokak
  müzisyeni.» «Müzisyen — canlı performanslarda seyirciden gelen bahşişler.»
  Sahneye çıktığını ve ödemelerin bu performanslar için verilen bahşişler olduğunu
  söyle.
- **Eşleşen bir kategori seç.** Canlı eğlence, sahne sanatları, müzisyen. Hayır
  kurumu değil, kâr amacı gütmeyen kuruluş değil, bağış toplama değil.
- **Payment Link'i kendin kuruyorsan `submit_type=pay` kullan.** Senin için bir
  araç kurduysa, ürettiği URL'ye bak: `buy.stripe.com` bir bahşiş kavanozudur,
  `donate.stripe.com` bir bağış sayfasıdır. Bu iki saniyelik bir kontrol ve
  aracının seni ne sandığını sana söyler.
- **Ona bağış deme** — ne tabelada, ne sitende, ne de Stripe'taki iş tanımında.
  «Bahşiş», «bahşiş kavanozu», «gruba destek ol», «bize bir içki ısmarla» —
  bunların hepsi olan biteni tarif ediyor. «Bağış» başka bir şeyi tarif ediyor.
- **Gerçek bir bağış kampanyasını ayrı tut.** Bir yardım konseri çalıyorsan ve para
  bir davaya gidiyorsa, bu gerçekten *hayır amaçlı para toplamaktır* ve yukarıdaki
  kurallar artık seninle ilgilidir — ülke listesi dahil. Bunu doğru hesap altında,
  doğru ülkede, Stripe'ın şartlarını okuyarak yap; ve asla normal gecelerde
  kullandığın bahşiş kavanozunun içinden geçirme.

Sonuncusu ayrıca vurgulanmayı hak ediyor, çünkü argümanın dürüst yarısı orası.
Bağışlar kötüdür ya da müzisyenler bir dava için asla para toplayamaz demiyoruz.
Bunun **farklı bir faaliyet** olduğunu, farklı kuralları olduğunu ve onu sessizce
aynı QR kodunun içinden geçirmenin ikisini birden başına iş açacak hale
getirdiğini söylüyoruz.

Stripe'ın bahşiş-ve-bağış sayfasından bir satır daha bilmeye değer, çünkü
insanların bu ikisiyle karıştırdığı üçüncü bir şeyi de eliyor: Stripe *«kişisel
veya kişiden kişiye para transferi için ödeme işleme (ör. arkadaşlar arasında para
gönderme)»* yapmıyor. Bahşiş, arkadaşlar arasındaki bir hediye de değildir. O rayı
istiyorsan — bir hayranın sana kişiden kişiye doğrudan para göndermesini — Revolut
ve MobilePay tam olarak budur, ve uygulamamızda bunların
[tamamen Stripe'ın dışında](https://live.tips/tr/blog/tek-qr-kod-her-odeme-yontemi/) durmasının
nedeni de budur.

## Bu yazı ne değildir

Hukuki tavsiye değildir. Vergi tavsiyesi de değildir — bahşişlerin nasıl
vergilendirildiği ülkeden ülkeye, hatta bazen şehirden şehre muazzam biçimde
değişir ve burada tamamen kapsam dışıdır; yaşadığın yerde ehil birine sor.

Ve hesabın hakkında bir söz de değildir. **Stripe'ın seni onaylayıp onaylamayacağı
yalnızca Stripe'ın kararıdır.** live.tips'in Stripe ile hiçbir ilişkisi yok, bir
incelemeyi etkileme gücü yok ve senin adına itiraz etme imkânı yok. Yazılımımızın
yapabileceği şey, ağzına kelime koymamaktır. Forma ne yazacağın hâlâ senin
elinde.

Politikalar da değişir. Burada alıntılanan satırlar Temmuz 2026'da Stripe'ın
sayfalarındaydı ve bağlantılar tam orada duruyor; bir blog yazısına — bu yazı da
dahil — güvenmek yerine git kendin oku.

## Kısa versiyon

Seti çaldın. İzlediler. Bunun için sana para verdiler.

Bu bir bahşiştir. Öyle söyle — tabelada, formda, URL'de — ve istediğin o sıkıcı
sonucu alırsın. Biz bahşiş kavanozunu tam olarak bu iddianın etrafında kuruyoruz,
[QR kodunun hangi Stripe alan adına işaret ettiğine](https://live.tips/tr/blog/kendi-stripe-hesabinizda-bahsis-kavanozu-kurun/)
kadar; paranın gerçekte nereye gittiğine dair geniş resmi istiyorsan, o da
[burada](https://live.tips/tr/blog/live-tips-parayi-nasil-yonetir/).
