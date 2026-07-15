---
title: live.tips parayı nasıl yönetir (yönetmez)
description: live.tips bakiyesi yok, ödeme takvimi yok, kesinti yok. İşte bu üç iddiayı cesur değil sıkıcı kılan mimari.
slug: live-tips-parayi-nasil-yonetir
---

Herhangi bir bahşiş kavanozu, açılış sayfasına "%0 komisyon" yazabilir. Asıl
ilginç soru şu: yazılımın bir pay almaya *başlaması* için ne yapması gerekirdi ve
bunun ne kadarını görebilirdin.

live.tips için cevap şu: baştan yeniden yazılması gerekirdi. Bu, niyetlerimize dair
bir söz değil; paranın nereye gittiğinin bir tarifi.

## Para hiçbir zaman bizden geçmez

Bir hayran kartla bir tutara dokunduğunda, ödeme **senin** Stripe hesabında
oluşturulur, **senin** Stripe bakiyene yerleşir ve **senin** Stripe takvimine göre
ödenir. Tek ücret, Stripe'ın kendi standart işlem komisyonudur; onu da Stripe senden
doğrudan tahsil eder, tıpkı Stripe'ı kendin entegre etmiş olsaydın olacağı gibi.

Bizim tarafımızda hiçbir defter yok, çünkü kaydedilecek bir şey yok. Önce parayı
tutan şeyi inşa etmeden bir yüzdeyi sıyırıp alamazdık — ve öyle bir şey de yok.

Bu, oturum açsan da açmasan da geçerli. Oturum açmanın değiştirdiği şey *veri*
yolu, para yolu değil; sonraki iki bölüm bunun tam olarak nasıl olduğu konusunda
dürüst.

## Anahtarların ve nerede durdukları

Kurulum, canlı bir gizli anahtar değil, *kısıtlı* bir Stripe API anahtarı ister —
öylelerini düpedüz reddederiz. "Kısıtlı", anahtarın iki şey yapabildiği anlamına
gelir: "ne kadar istersen öde" bahşiş bağlantısını oluşturmak ve bahşişlerin
gelişini izlemek. Bakiyeni okuyamaz, ödemeleri tetikleyemez, iade yapamaz ya da
müşteri verilerine dokunamaz. Yarın sızsa, patlama yarıçapı bir bahşiş
bağlantısıdır.

**Hesap yokken, o anahtar cihazından asla çıkmaz.** Cihazının kendi anahtar
zincirinde durur ve yalnızca TLS üzerinden `api.stripe.com` adresine gönderilir.
Ortada hiçbir live.tips sunucusu yoktur.

**Oturum açtığında, anahtar bize taşınır** — çünkü yalnızca tek bir telefonda var
olan bir anahtar, sahnedeki tablete de hizmet edemez. Onu şifreleriz (her sır için
ayrı bir AES-256 anahtarı, o da Google Cloud KMS tarafından sarmalanır) ve hiçbir
şeyin geri okuyamayacağı bir yerde saklarız: başka bir hesap değil, bir veritabanına
göz atan biz değil, sen bile değil. Yalnızca fonksiyonlarımızın içinde açılır, senin
adına Stripe ile konuşmak için kullanılır ve bir daha asla bir cihaza verilmez.
Açıkça söyleyelim: oturum açmak, Stripe ile bahşiş geçmişin arasındaki yola bir
live.tips sunucusu koyar. Asla paraya değil — veriye.

## Sunucular ve yapamadıkları

İki tane var ve ikisi de asgari.

**Aktarıcı**, Revolut ve MobilePay'in Stripe gibi bir tarayıcıdan sürülememesi
yüzünden vardır. Bunları etkinleştirmek, bahşiş sayfanı `tip.live.tips` adresinde
sunan bir avuç Firebase fonksiyonunu devreye sokar. Senin herkese açık bahşiş
sayfası profilini saklar — yayımlamayı seçtiğin görünen adı ve ödeme tanıtıcılarını
— ve arkasında hesap olmayan bir sayfa için hiçbir bahşiş geçmişi tutmaz: bir bahşiş
yalnızca sahnedeki cihazın onu gösterene kadar bekler ve kimsenin dönüp almadığı her
şey bir saat içinde süpürülür. Hiç para görmez ve 90 günlük hareketsizliğin ardından
kendini siler. Yalnızca Stripe kullanıyor ve hiç oturum açmıyorsan, aktarıcıya
hiçbir zaman başvurulmaz.

**Webhook** yalnızca oturum açtığında var olur. Anahtarın artık bizde durduğu için,
Stripe her bahşişi bizim küçük bir fonksiyonumuza bildirir; o da bahşişi, diğer
cihazların gösterebilsin diye senin kendi geçmişine yazar. Bu, bir olayın
kopyasıdır, paranın kopyası değil. Tek bir kuruşu bile kıpırdatamaz ve yalnızca ait
olduğu o tek hesaba yazabilir.

İki sunucu da bir pay alamaz, çünkü ikisi de paranın yanına bile yaklaşmaz. İkisinin
de yapabileceği en fazla şey arızalanmaktır — ve yalnızca Stripe kullanan, hesapsız
bir kurulum ikisine de bağlı değildir.

## Açmak zorunda olmadığın hesap

Uygulama hâlâ cihazın kendi yerel profiliyle açılıyor; her zaman olduğu gibi:
bahşiş kavanozun, anahtarın ve bahşiş geçmişin cihazında yaşıyor, başka hiçbir
yerde. Kaydolunacak bir şey yok.

Oturum açmak — Apple ile, Google ile ya da misafir olarak — artık mümkün ve tek bir
sebep için var: ikinci bir cihaz. Sahnedeki tablet ile cebindeki telefon aynı geceyi
gösterecekse, aralarında bir şeyin durması gerekir; o şey de yalnızca senin
okuyabildiğin bir kullanıcı kimliği altındaki Firestore. Grupların, ayarların,
bahşiş geçmişin — ve yukarıda anlatıldığı gibi şifrelenmiş olarak, Stripe anahtarın —
orada durur. Bu, gizlilik hikâyesinde gerçek bir değişiklik ve sonradan
keşfedilmektense açıkça söylenmeyi hak ediyor: hesap olmadan hiçbir sunucu bir
bahşişi görmez; hesapla birlikte bizim sunucumuzun sadece sana ait köşesi görür ve
onu oraya yazan şey bizim webhook'umuzdur. Bu, ikinci cihazın bedeli ve ödemek ya da
reddetmek sana kalmış. Asla dokunmadığı şey ise para: bir hesap verilerini taşır,
bakiyeni değil ve hâlâ hiçbir pay almıyoruz.

## Neden bize öylece inanmamalısın

Yukarıdakilerin hepsi doğrulanabilir. Kod tabanı MIT lisanslı ve herkese açık; site
ise GitHub Actions tarafından GitHub Pages'e dağıtılan statik bir derleme — gizli
altyapı yok, kapalı kapı ardında derlenmiş hiçbir şey yok. Bir demo bahşiş sırasında
ağ sekmesini aç ve istekleri oku. Beklediğinden daha azdır.

Asıl ürün iddiası budur. Güvenilir olduğumuz değil, buna ihtiyacın olmadığı.
</content>
</invoke>
