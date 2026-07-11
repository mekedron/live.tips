---
title: Sokak müzisyenleri için temassız bahşiş, dürüstçe
description: Telefonda Tap to Pay, bir kart okuyucu, bir NFC etiketi, bir QR kod — hepsine «temassız» denen dört ayrı şey. 2026'da her birinin gerçekte neye mal olduğu, bir NFC etiketinin aslında ne yaptığı (sandığın şey değil) ve dokunmanın taramayı ne zaman geçtiği.
slug: sokak-muzisyenleri-icin-temassiz-bahsis
---

Sokak müzisyenleri için temassız bahşişi ara, internet sana 2018'i uzatsın. Brunel
University'den Tiptap adlı bir öğrenci prototipi — telefonu içine geçirdiğin bir
stant — o yıl bir tur basın ilgisi gördü ve o haberler hâlâ birinci sayfada duruyor.
Güzel bir fikirdi. Ayrıca, haberlerin kendi ifadesiyle, *hâlâ geliştirme
aşamasındaydı* ve sokak müzisyenlerinden tek seferlik bir ücret artı **her bahşişin
%5'ini** almayı planlıyordu. Satın alabileceğin bir şeye hiç dönüşmedi.

(Şimdi aramaya kalkarsan bulacağın «tiptap», hayır kurumlarına temassız bağış
terminalleri satan, alakasız bir Ontario şirketi. Aynı kelime, başka ürün, sana göre
değil.)

Yani işin dürüst hâli sekiz yıldır hiçbir yere yazılmadı. Buyur.

Bu yazı *tap*'in derinlemesine hâli. Asıl merak ettiğin daha genel şeyse — kimse
nakit taşımazken parayı nasıl alacağın ve her yolun ne kadara mal olduğu — [sokak
müzisyenleri kartla ödemeyi nasıl alıyor](post:how-buskers-take-card-payments)
yazısından başla, sonra buraya dön.

## Dört ayrı şeye birden «temassız» deniyor

Kafa karışıklığının çoğu burada yaşıyor, o yüzden herhangi bir şeye fiyat biçmeden
önce bunları ayıralım.

1. **Kendi telefonunda Tap to Pay.** Telefonun terminal olur. Hayran kartını ya da
   saatini *senin* cihazına dokundurur. Hiç ek donanım yok.
2. **Bir kart okuyucu** — bir SumUp, bir Zettle, bir Square. Uzattığın küçük bir
   plastik terminal. Hayran ona dokunur.
3. **Bir NFC etiketi** — «bahşiş için buraya dokun» çıkartması ya da plakası. Bu,
   neredeyse evrensel biçimde yanlış anlaşılıyor ve bir sonraki bölüm bunun nedenini
   anlatıyor.
4. **Bir QR kod.** NFC anlamında temassız değil — ama okumaya devam et, çünkü
   hayranın tarafından bakıldığında çok sık olarak tam da aynı dokunuşla bitiyor.

Yalnızca ilk ikisi *ödeme terminali*. Bu ayrım, bu yazının tamamı.

## NFC etiketi ödeme almaz

Bunu düzgünce halledelim, çünkü satıcılar aksini düşünmene seve seve göz yumuyor.

Bir NFC çıkartması — ucuz olanı, çoğunun kullandığı NTAG213 çipi — **144 bayt
belleğe** sahip. 144 kilobayt değil. Kod çalıştıramaz, pili yok, hayatında bir kart
şemasının adını duymadı ve istese de bir ödeme protokolünü içine sığdıramaz. İçine
sığdırdığı şey, NDEF kaydı olarak biçimlendirilmiş kısa bir metin dizisi ve o dizi
ezici çoğunlukla bir **URL**.

Dokunuyorsun, telefonun bir web sayfası açıyor. Özelliğin tamamı bu.

Yani bir «tap to tip» plakası, nişan alarak değil dokunarak açtığın bir QR koddur.
Aynı hedef, aynı web sayfası, tarayıcıda gerçekleşen aynı ödeme. Dikkatle okursan
uzmanları bile bunu söylüyor: tiptap'in kendi sitesi, serbest tutarlı cihazını
anlatırken *«bağışçılar telefonlarını özel bir bağış cihazına yaklaştırdığında,
çevrimiçi bağış toplama sayfanıza yönlendirilirler.»* diyor. Bir sayfaya
yönlendirilirler. Çünkü bir etiketin yapabileceği şey bu.

Bu gerçekten işe yarar, ve ucuzdur da — boş NTAG213 çıkartmaları paketlerde **tanesi
0,24 $** civarından başlıyor. Zaten bir bahşiş sayfan varsa, basılı kodun yanına
kılıfına bir etiket yapıştırmak sana bozuk paraya mal olur ve bazı hayranlara daha
hızlı bir giriş yolu verir.

Ama ne satın aldığın konusunda net ol: **aynı sayfaya açılan ikinci bir ön kapı.** Kart
makinesi değil.

### Ve açık havada, huysuz bir ön kapı

Başarısızlık biçimleri gerçek ve hiçbir etiket satıcısı bunları listelemiyor:

- **Hayranın telefonu kilidi açık ve kullanımda olmalı.** Apple'ın kendi belgeleri açık:
  arka planda etiket okuma yalnızca iPhone kullanımdayken olur, telefon kilitliyse sistem
  önce kilidi açtırır.
- **Kamera açıkken çalışmaz.** Apple, kameranın kullanımda olmasını, arka planda etiket
  okumanın kullanılamadığı durumlardan biri olarak sayıyor. İroninin tadını çıkar: QR
  kodunu taramak için kameraya uzanan bir hayran, tam da o anda NFC etiketini devre dışı
  bıraktı.
- **iPhone XS veya sonrası gerekiyor** ve Android'de NFC'nin açık olması gerekiyor — ki
  bazı güç tasarrufu modları onu kapatıyor.
- **Menzil yaklaşık 4 cm.** Hayranın o şeye gerçekten dokunması gerekiyor. Kalabalıkta,
  bir gitar kılıfına eğilerek — bu ciddi bir talep.
- **Metal ve mıknatıslar onu öldürür.** Amfiye bantlanmış bir etiket ya da manyetik cüzdan
  kılıfı olan bir hayran, ve hiçbir şey olmaz.

Etiket, hoş bir ikinci seçenek. Kötü bir tek seçenek.

## Telefonda Tap to Pay: 2026'nın asıl haberi

İşte Tiptap yazılarından bu yana değişen ve bayat haberlerin hiçbirinin bilmediği şey.

**iPhone'da Tap to Pay**, zaten cebinde olan telefonu temassız bir terminale çeviriyor.
Dongle yok, okuyucu yok, stant yok. Apple bunu **70'ten fazla ülke ve bölgede** kullanıma
açık olarak listeliyor ve Avrupa'da üzerinden kullanabileceğin sağlayıcılar neredeyse
sektörün tamamı — yalnızca Almanya'da: Adyen, Mollie, myPOS, Nexi, PAYONE, Rapyd, Revolut,
Sparkassen, Stripe, SumUp, Viva.com. Birleşik Krallık, Fransa, Hollanda, İsveç, Finlandiya
ve Danimarka'nın da benzer listeleri var. iPhone XS veya sonrası gerekiyor.

**Android'de Tap to Pay** de var ama daha dar. Stripe üzerinden AT, AU, BE, CA, CH, DE, DK,
FI, FR, GB, IE, IT, MY, NL, NZ, PL, SE, SG ve US'te genel kullanıma açık, on sekiz ülke daha
herkese açık önizlemede. Telefonunun Android 13 ya da sonrası, bir NFC sensörü, kurcalanmamış
bir bootloader, Google Mobile Services ve kapalı geliştirici seçenekleri gerekiyor — sonuncusu
sandığından çok daha fazla insanı yakalıyor.

Pratik hâli: **SumUp, Tap to Pay'i 0 £ donanımla listeliyor.** Yeni bir iPhone'un varsa ve
desteklenen bir ülkedeysen, temassız bir terminali uzatmanın giriş maliyeti artık sıfır. Tek
başına bu gerçek, 2018'in bütün «şu standı al» yazılarını geçersiz kılıyor.

## Kart okuyucular ve gerçek maliyetleri

Ayrı bir plastik parçası istiyorsan — ve bunun iyi sebepleri var, aşağıda — piyasa üç üründen
ibaret.

| | Donanım | Yüz yüze dokunuş başına ücret |
| --- | --- | --- |
| **SumUp** (UK) | Tap to Pay 0 £ · Solo Lite 25 £ · Solo 79 £ · Terminal 135 £ | **%1,69**, sabit ücret yok |
| **SumUp** (Almanya) | — | **%1,39**, sabit ücret yok |
| **Zettle / PayPal POS** (UK) | İlk alımda 29 £'dan, sonrasında 69 £ okuyucu | **%1,75**, sabit ücret yok |
| **Square** (UK) | Temassız + çipli okuyucu 19 £ | **%1,75**, sabit ücret yok |
| **Square** (US) | Temassız + çipli okuyucu 59 $ | **%2,6 + 0,15 $** |

Fiyatlar KDV hariç ve Temmuz 2026'da yayımlandığı hâliyle. Git kendin kontrol et; oynuyorlar.

Şimdi o tabloyu bir daha oku, çünkü sana muhtemelen anlatılanla çelişen bir şey söylüyor.

## Ücret aritmetiği ve herkesin ters anladığı şey

Yerleşik kanı şu: kart ücretleri, işlem başına sabit ücret yüzünden küçük bahşişleri mahveder
— 2 €'luk bir bahşişin sekizde birini yiyen yirmi beş sent. Bu doğru, ve
[aritmetiğini kendimiz yazdık](post:build-a-tip-jar-on-your-own-stripe).

Ama bu, *çevrimiçi* kart ödemeleri için doğru. **Avrupa'daki temassız okuyucuların çoğunda
sabit ücret diye bir şey yok.** SumUp, Zettle ve Square, Birleşik Krallık'ta ve AB'de yalnızca
yüzde alıyor. Yani:

| 2 €'luk bir bahşiş | Ücret | Sanatçıya kalan | Efektif kesinti |
| --- | --- | --- | --- |
| SumUp okuyucu (DE, %1,39) | 0,03 € | 1,97 € | **%1,4** |
| Zettle / Square (UK, %1,75) | 0,04 € | 1,96 € | %1,8 |
| Stripe, çevrimiçi kart (AEA, %1,5 + 0,25 €) | 0,28 € | 1,72 € | **%14,0** |
| Square okuyucu (US, %2,6 + 0,15 $) | 0,20 $ | 1,80 $ | **%10,1** |

Sadece ücrete bakınca, küçük bir bahşişte Avrupalı bir dokunmatik terminal çevrimiçi kart
ödemesini geçiyor, hem de farkla. Biz bir QR kod ürünüyüz ve sana bunu söylüyoruz: 2 €'luk bir
bahşişte SumUp okuyucu, Stripe'ın barındırdığı bir sayfanın bırakmadığı 0,25 €'yu sana bırakıyor.

İki şey bunu yeniden ölçüsüne oturtuyor.

**Donanım, yer değiştirmiş sabit ücrettir.** Bahşiş başına 0,25 €'luk tasarrufa karşılık 79 £'luk
bir Solo, kabaca **okuyucunun kendini amorti etmesi için üç yüz dokunuş** demek. Sokakta çalışan
bir müzisyen için gerçek bir sayı, yazın iki kez çalan biri içinse gülünç bir sayı. (Ve SumUp'ın
0 £'luk Tap to Pay'i bunu sıfır dokunuşa indiriyor — o seçeneğin okuyuculardan neden daha önemli
olduğunun sebebi tam olarak bu.)

**Ve ABD işi tersine çeviriyor.** Square'in Amerika'daki yüz yüze oranı 0,15 $ sabit ücret
taşıyor, yani 2 $'lık bir dokunuş terminalde de onda birini kaybediyor. «Sabit ücret yok» hediyesi
Avrupa'ya özgü.

Karşılaşacağın bir de alt sınır var: SumUp **1 £ / 1 €** altındaki bir ödemeyi kabul etmiyor. Hangi
rayı seçersen seç, çok küçük bahşiş aslında bir kart işlemi değil.

## Peki dokunmak taramayı ne zaman geçer?

Teknolojiyi bir kenara koy, geriye hayranın elleriyle ilgili bir soru kalır.

**Dokunmak, hayranın telefonunun kilidinin açık ve elinde olmasını, senin de bir şey uzatmanı
gerektirir.** İkisi de doğruysa, ödemeler dünyasındaki en hızlı şeydir. Uygulama yok, nişan alma
yok, yazma yok, bir saniyede bitti.

**Taramak, hayranın kamerasını açmasını gerektirir** — fazladan bir bilinçli hareket — ama senden
hiçbir şey istemez. Kod kılıfın üstünde durur. Arkada duran bir hayranda çalışır. Aynı anda kırk
kişide çalışır. Sen hâlâ çalarken çalışır.

Bu da dürüst bir iş bölümü verir:

- **İnsanların yanına gidebiliyorsan dokunmak kazanır.** Setin sonunda, şapka elden ele, teker
  teker hayranlar, sen terminali tutmakta serbest. Dokunmak, «kameranı çıkar»dan daha az sürtünmeli
  bir istektir ve o anda onu kapatmak için fiziksel olarak oradasındır.
- **Gidemiyorsan taramak kazanır.** Şarkının ortası. Üç sıra derinliğinde bir kalabalık. Amfiden
  ayrılamadığın bir mevzi. Geçerken vermek isteyen herkes. Bir terminal tam olarak bir kişiye hizmet
  eder; basılı bir kod bütün meydana aynı anda hizmet eder, ve hizmet etmesi için çalmayı bırakmanı
  istemez.

Bu son nokta, terminal satıcılarının asla dile getirmediği ve en büyük olanı. **Bir kart okuyucu,
kuyruğu olan bir dar boğazdır.** Bir QR kodun kuyruğu yoktur.

Ve işte tartışmanın yarısını eriten kısım: iyi kurulmuş bir bahşiş sayfasında **tarama zaten bir
dokunuşla biter**. Hayran tarar, sayfa açılır ve telefonu ona Apple Pay ya da Google Pay önerir. Çift
tıklar, telefonu yüzüne tutar, bitti. Hayranın tarafından bakılınca bu temassız bir ödemedir — aynı
cüzdan, aynı kart, aynı iki saniye — ve bunun olması için hiç donanım almadın.

## live.tips nerede duruyor ve ne zaman onun yerine SumUp almalısın

[live.tips](https://github.com/mekedron/live.tips), QR tabanlı bir bahşiş kavanozu. Hiç değişmeyen
tek bir kod, doğrudan sanatçının kendi Stripe ödeme bağlantısını gösteriyor. live.tips bakiyesi yok,
kesinti yok, yolda platform yok — ücret Stripe'ın kendi ücreti ve Stripe onu doğrudan sanatçıdan
alıyor. MIT lisanslı, ve sahnedeki tablet her bahşişi düştüğü anda gösteriyor. Paranın yolunu
[live.tips parayı nasıl yönetiyor](post:how-live-tips-handles-money) yazısında anlattık, ve neden
[her sağlayıcı için ayrı değil, tek bir kod](post:one-qr-code-every-payment-method) olduğunu da.

O sayfa Apple Pay ve Google Pay destekliyor. Yani live.tips, hayranın tarafından bakınca temassız
*evet* — önemli olan dokunuş, sondaki dokunuş, satın alınacak, şarj edilecek ya da yağmurda
düşürülecek bir terminal olmadan. Sadece bir terminal değil.

**İstediğin şey, fiziksel olarak bir şey uzatıp bir yabancının ona dokunmasıysa, bir kart okuyucu
al.** Telefonun ve ülken destekliyorsa SumUp'ın Tap to Pay'ini al, çünkü hiçbir şeye mal olmuyor;
kendi telefonunu kalabalığa uzatmak istemiyorsan bir Solo al. Her hâlükârda, Avrupa'da 2 €'luk bir
dokunuşta bizim ücretimizi geçecek, ve bunu aksini gizlemektense söylemeyi tercih ederiz.

İkisini birden de yapabilirsin, ve pek çok sokak müzisyeni yapmalı: bütün gece kılıfa bantlı kod, sen
çalarken geçenleri yakalar; ve son akordun ardından ön sıranın ceplerine uzandığı o on saniye için
elinde terminal. Birbirleriyle yarışmıyorlar. Farklı insanları yakalıyorlar.

Hiçbirinin olmadığı şey ise: %5 alan 2018 model bir stant.

Ücretler, donanım fiyatları ve ülke kullanılabilirliği, Temmuz 2026'da Apple, Stripe, SumUp, Zettle/PayPal ve Square tarafından yayımlandığı hâliyle, KDV hariç. NFC çıkartma fiyatları GoToTags'ten. Tiptap'in 2018 koşulları, Brunel University ve Finextra'nın aktardığı hâliyle. Buradaki her şey değişir; para harcamadan önce sağlayıcıdan kontrol et.
{: .footnote }
