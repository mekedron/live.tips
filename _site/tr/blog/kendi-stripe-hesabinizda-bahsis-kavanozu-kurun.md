# Kendi Stripe hesabınızda bahşiş kavanozu kurun

> Üç API çağrısı size Apple Pay ve Google Pay destekli, barındırılan bir „ne kadar istersen o kadar öde" sayfası verir — hiç sunucu yok. İşte kurulumun tamamı: kısıtlı anahtar, izinler, bahşişleri webhook olmadan nasıl okuyacağınız ve kimsenin basmadığı komisyon hesabı.

Canonical: https://live.tips/tr/blog/kendi-stripe-hesabinizda-bahsis-kavanozu-kurun/
Published: 2026-07-11
Language: tr
Tags: Stripe, open source, how-to, API, fees

---

Bir bahşiş kavanozu istiyorsunuz. Bir sokak müzisyeninin akşamının %5'ini bir platforma
kaptırmak istemiyorsunuz ve bir API ile konuşmayı gayet iyi beceriyorsunuz. Dolayısıyla soru
*hangi bahşiş kavanozuna üye olayım* değil, *aslında ne kadarını inşa etmem gerekiyor*.

Sandığınızdan azını. Stripe üzerinde çalışan cevap şu: üç API çağrısı, sunucu yok, backend
yok, webhook uç noktası yok. Bu yazının geri kalanı tam olarak o kurulum — artı herkesin
yanlış yaptığı iki şey.

## Bütün numara „ne kadar istersen o kadar öde" Price'ı

Stripe'ın, tutarı hayranın kendisinin yazdığı bir fiyatlandırma modu var. Adı
[pay what you want](https://docs.stripe.com/payments/checkout/pay-what-you-want) ve özelliğin
tamamı bu. Bir Product oluşturuyorsunuz, ona `custom_unit_amount[enabled]=true` olan bir Price
takıyorsunuz, üstüne de bir
[Payment Link](https://docs.stripe.com/payment-links/create) asıyorsunuz.

```sh
# 1. "sattığınız" şey
curl https://api.stripe.com/v1/products \
  -u "$RK:" \
  -d name="Tips — Mira" \
  -d "metadata[managed_by]"=my-tip-jar

# 2. hayranın seçeceği fiyat
curl https://api.stripe.com/v1/prices \
  -u "$RK:" \
  -d product=prod_... \
  -d currency=eur \
  -d "custom_unit_amount[enabled]"=true \
  -d "custom_unit_amount[preset]"=500 \
  -d "custom_unit_amount[minimum]"=200

# 3. sayfa
curl https://api.stripe.com/v1/payment_links \
  -u "$RK:" \
  -d "line_items[0][price]"=price_... \
  -d "line_items[0][quantity]"=1 \
  -d submit_type=pay
```

Üçüncü çağrı bir `url` döndürür. O URL *sizin* bahşiş kavanozunuzdur. Stripe'ın barındırdığı
bir sayfadır: siz düşünmeden PCI uyumludur, yerelleştirilmiştir ve telefonunda kurulu olan her
hayrana Apple Pay ya da Google Pay gösterir —
[dinamik ödeme yöntemleri](https://docs.stripe.com/payments/payment-methods/dynamic-payment-methods)
bunu cihaza ve ülkeye göre sizin yerinize karara bağlar. Tek satır frontend yazmadınız.

URL'i istediğiniz kütüphaneyle QR koda çevirin — sadece bir metin dizisi — yazdırın, kılıfa
yapıştırın. Kod hiç sona ermez ve sizin hiçbir sunucunuza işaret etmez, çünkü sunucunuz yok.

Bilmeye değer iki parametre:

- **`custom_unit_amount[preset]`**, sayfanın açıldığı tutardır. `500`, hayranın 5,00 €'yu zaten
  dolu göreceği ve değiştirebileceği anlamına gelir. Bu sayı, ortalama bahşişiniz için sayfadaki
  her şeyden daha fazlasını yapar.
- **`custom_unit_amount[minimum]`** bir tabandır. Koyun. Nedeni aşağıdaki komisyon bölümünde ve
  bu bir yuvarlama hatası değil.

Ad ve mesaj da toplayabilirsiniz. Payment Links en fazla üç `custom_fields` kabul eder — form
kurmadan „bu kimdendi ki?"yi böyle elde edersiniz:

```sh
  -d "custom_fields[0][key]"=nickname \
  -d "custom_fields[0][type]"=text \
  -d "custom_fields[0][label][type]"=custom \
  -d "custom_fields[0][label][custom]"="Adınız veya takma adınız" \
  -d "custom_fields[0][optional]"=true
```

Stripe'ın [bahşiş ve bağış kabulü için gereklilikleri](https://support.stripe.com/questions/requirements-for-accepting-tips-or-donations)
var — bir kez okuyun. „Ne kadar istersen o kadar öde" ayrıca başka line item'larla, indirimlerle
veya yinelenen ödemelerle birleştirilemez. Bir bahşiş kavanozu için bunların hiçbiri sorun değil.

Bu ayrımı doğru yapmaya değer. Stripe şöyle koyuyor: bahşiş, halihazırda sunulmuş bir mal
ya da hizmet için verilir; bağış ise hayır amaçlı bir gayeye bağlı olmak zorundadır. Seti
siz çaldınız; bahşiş onun bedeli. Yukarıdaki çağrının `donate` değil `submit_type=pay`
göndermesinin sebebi de bu — `donate`, bağlantınızı `donate.stripe.com` üzerinde barındırır
ve düğmeye *Bağış yap* yazar. O başka bir iş ve Stripe'ın çok daha sıkı incelediği bir iş.

## Anahtar: sızacağını varsayın ve bunu sıkıcı hale getirin

Sahnede duran bir cihaza gizli anahtar (`sk_live_…`) koymayın.
[Kısıtlı anahtar](https://docs.stripe.com/keys/restricted-api-keys) (`rk_live_…`) kullanın: her
kaynak için bir izin seçersiniz ve seçmediğiniz her şey **None** kalır.

Yukarıdaki kurulum için tam liste beş satır:

| Kaynak | İzin | Ne kazandırır |
| --- | --- | --- |
| Products | Write | Product'ı oluşturmak |
| Prices | Write | „ne kadar istersen" Price'ını oluşturmak |
| Payment Links | Write | bağlantıyı oluşturmak |
| Checkout Sessions | Read | gelen bahşişleri görmek |
| Events | Read | canlı akış (sonraki bölüm) |

Geri kalan her şey — Balance, Payouts, Refunds, Customers, PaymentIntents, tüm Connect —
**None**'da kalır.

Şimdi bunu yapmaya değer kılan alıştırmayı yapın. Gecenin biri, tabletiniz merch masasından
çalınıyor. Hırsız, keychain'deki anahtarla ne yapabilir? Bahşiş geçmişinizi okur ve hesabınızda
birkaç bahşiş bağlantısı daha oluşturur. Patlama yarıçapının tamamı bu. Bakiyenizi göremez, ödeme
tetikleyemez, kontrol ettiği bir karta iade yapamaz, müşteri listesi okuyamaz. Eve dönerken takside
telefondan anahtarı iptal edersiniz ve cihaz kararır. Paranızdan hiçbir şey kıpırdamamıştır.

Bu asimetri — bahşiş kavanozuna yazma yetkisi, paraya sıfır erişim — sunucusuz, kendi anahtarını
getir tasarımının savunulabilir olmasının tek nedeni. „Login with Stripe"ın burada cevap olmamasının
da nedeni bu: OAuth, token'ınızı tutacak, uygulama geliştiricisine ait bir sunucu ister — sunucu ise
tam olarak inşa etmediğimiz şey.

(Karşınıza çıkacak bir tuhaflık: *Prices* izninin dahili adı `plan_write`, yani Stripe'ın hata mesajı
panoda o adla görünmeyen bir scope'u anar. Kastedilen Prices.)

## Bahşişleri webhook olmadan okumak

Çoğu yazı burada ya durur ya da bir webhook'a sarılır — ve bir sahnenin bir web uygulamasından
gerçekten ayrıldığı yer burasıdır.

Webhook, gelen bir HTTP isteğidir. Mikrofon sehpasının arkasındaki bir tablet böyle bir şey alamaz.
Mekânın misafir wi-fi'ında, NAT arkasında oturur; genel bir adresi, TLS sertifikası yoktur — ve
olmasına da gerek yoktur. Webhook yolunu seçerseniz, olayları yakalayacak bir sunucu ve bunları cihaza
itecek bir soket kurmanız gerekir: bir backend, bir işletme yükü ve hayranlarınızın isimlerinin artık
yaşadığı bir yer. Kaçınmaya çalıştığınız platformu yeniden inşa etmiş oldunuz.

O yüzden itilmek yerine çekin. Stripe'ın
[List all events](https://docs.stripe.com/api/events/list) uç noktası herkese açık, belgelenmiş ve
olayları en yeniden başlayarak döndürür:

```sh
curl -G https://api.stripe.com/v1/events \
  -u "$RK:" \
  -d "types[]"=checkout.session.completed \
  -d "types[]"=checkout.session.async_payment_succeeded \
  -d ending_before=evt_GORDUGUM_SON \
  -d limit=100
```

`ending_before` tasarımın tamamıdır. İşlediğiniz en yeni olayın id'sini saklayın; her yoklama ondan
kesinlikle daha yeni olan her şeyi ister, siz de imleci ilerletirsiniz. Zaman damgası yok, saat kayması
yok, tutara göre yineleme ayıklama yok. Bir setin ilk yoklamasında, imleçsiz `limit=1` isteyin ki zaten
orada olana demir atasınız — yoksa ses provasında bu sabahki bahşişleri yeniden oynatırsınız.

Sonra geleni filtreleyin. Her iki olay türü de tek bir ödeme için tetiklenebilir, o yüzden Checkout
Session id'sine göre yinelenenleri ayıklayın. `payment_status == "paid"` kontrolü yapın — tamamlanmış
bir oturum mutlaka ödenmiş değildir. Ve `payment_link`'in *sizin* bağlantınızla eşleştiğini kontrol edin,
çünkü `/v1/events` hesap genelindedir ve o Stripe hesabının yaptığı başka her şeyin trafiğini de size
seve seve uzatır.

Ödünleşimler konusunda dürüst olun, çünkü gerçekler:

- **Stripe webhook'ları önerir.** Yoklama kutsanmış yol değildir; bilinçli olarak kullanılan, belgelenmiş
  bir uç noktadır. Bunu README'nize yazın ve devam edin.
- **Olaylar 30 gün geriye gider.** [Stripe'ın kendi sözleri](https://docs.stripe.com/api/events/list):
  *„List events, going back up to 30 days."* Bu canlı bir akış, defteriniz değil. Defteriniz Checkout
  Sessions — gerçek defteriniz ise Stripe panosu.
- **Okuma kotasına dikkat.** Herkes saniye başına limite bakar
  ([rate limits](https://docs.stripe.com/rate-limits): canlıda 100 istek/sn), kimse diğerine bakmaz: Stripe,
  kayan 30 gün üzerinden **işlem başına yaklaşık 500 okuma isteği** tahsis eder, ayda 10.000 okumalık bir
  tabanla. 4 saniyede bir yoklarsanız, üç saatlik bir set ~2.700 okuma eder. Ayda dört uzun konser ve
  tabandasınız. Bahşişler geldikçe size pay satın alır — ama daha atik hissettirdiği için saniyede bir
  yoklayan, tavanı bulur. Dört saniye tembel bir sayı değildir; *o* sayıdır.

İşin dürüst hali bu: yoklama size birkaç bin GET'e mal olur ve karşılığında koca bir backend'i silmenizi
satın alır.

## Komisyon hesabı, düzgün yapılmış

%0 diye reklam yapan bir platform bedava değildir — bu da değil. Stripe'ın kendi işlem ücreti her bahşişe
uygulanır ve Stripe bunu doğrudan sizden alır. Bugün, [Stripe'ın euro fiyatlarına](https://stripe.com/ie/pricing)
göre standart bir AEA kartı **%1,5 + 0,25 €** tutar. Premium AEA kartları %1,9 + 0,25 €, İngiliz kartları
%2,5 + 0,25 €, geri kalan her şey %3,25 + 0,25 € ve döviz çevrimi gerekiyorsa bir %2 daha. (ABD'de %2,9 + 0,30 $,
ki bu aşağıdaki sebeple tam olarak daha kötü.)

Sorun yüzde değil. Sorun o yirmi beş sent.

| Bahşiş | Stripe alır | Sanatçıda kalır | Etkin kesinti |
| --- | --- | --- | --- |
| 2 € | 0,28 € | 1,72 € | **%14,0** |
| 5 € | 0,33 € | 4,67 € | %6,5 |
| 10 € | 0,40 € | 9,60 € | %4,0 |
| 20 € | 0,55 € | 19,45 € | %2,8 |
| 50 € | 1,00 € | 49,00 € | %2,0 |

Sabit ücret, kılık değiştirmiş bir yüzdedir ve küçük paralarda kılık kayar. 50 €'luk bir bahşişte görünmeyen aynı
0,25 €, 2 €'luk bir bahşişin sekizde birini yer. Bahşişler doğaları gereği küçüktür — onları bahşiş yapan da budur
— yani bu uç bir durum değil, medyan durumdur.

İşte tam da bu yüzden `custom_unit_amount[minimum]` koyarsınız. 2 € civarında bir yerde işlem, işlenmeye değer
olmaktan çıkar; 0,50 €'luk bir kart bahşişi 0,24 € olarak varır ve Stripe'a taşıması değerinden fazlaya mal olur.
Tabanınızı ilk ödemenizde keşfetmek yerine bilinçli seçin.

Ve bunun, başladığınız karşılaştırmaya ne yaptığına bakın. Stripe'ın üstüne %0 alan bir platform, size **bunun**
üstüne %0 alıyordur. Onların %0'ı gerçektir — ve işlemcinin bıraktığının %0'ıdır. Kimsenin kart rayı bedava değildir:
dürüst iddia „işlemcininkinin ötesinde hiçbir kesinti yok"tur ve daha fazlasını iddia eden ya yalan söylüyordur ya da
kart kullanmıyordur.

## Şimdi neyiniz var, neyiniz yok

Üç API çağrısı ve bir QR kod — ve gerçek bir bahşiş kavanozu: barındırılmış, PCI uyumlu, Apple Pay, Google Pay,
kendi ödeme takviminizle kendi Stripe bakiyenize inen bahşişler ve yolda hiç sunucu yok. Pek çok kişi için bu gerçekten
projenin sonudur ve burada durup yayınlayabilirsiniz.

Sahip olmadığınız şey bir sahne. Bir ödeme sayfanız var. İkisinin arasında sıkıcı şeyler duruyor: imleci ve backoff'u
olan yoklama döngüsü; seyircinin görebileceği, hedefin ve son mesajın olduğu bir ekran; anahtar için adı `localStorage`
olmayan bir yer; setler arasında bir yabancının tablete dokunmasını önleyen bir kilit; ve mekânın wi-fi'ı setin ortasında
düştüğünde ne olacağına dair bin küçük karar katmanı.

[live.tips](https://github.com/mekedron/live.tips) işte tam olarak bu — bu mimarinin bitmiş, MIT lisanslı hali. O beş
izinli kısıtlı anahtar, `/v1/events` üzerindeki imleç döngüsü, Product/Price/Payment Link oluşturma — hepsi sanatçının
cihazında, kendi hesabına karşı çalışıyor. Stripe yolunda hiçbir live.tips sunucusu ve hiçbir yerde live.tips bakiyesi
yok; bunu ayrıca [live.tips parayla nasıl başa çıkıyor](https://live.tips/tr/blog/live-tips-parayi-nasil-yonetir/) yazısında anlattık.

Kaynağı okuyun, istediğiniz parçaları alın ya da sadece kullanın. Bu yazının derdi şu: mimari ne bir sır ne de zor:
**Stripe bahşiş kavanozunuzu bedavaya barındırır ve kısıtlı bir anahtar artı bir yoklama döngüsü, bir sanatçıyla kendi
parası arasında duran her şeydir.** Bunu bilmenizi, herhangi bir yere üye olmanıza tercih ederiz.
