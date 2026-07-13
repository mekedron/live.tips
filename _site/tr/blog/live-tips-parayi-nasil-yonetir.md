# live.tips parayı nasıl yönetir (yönetmez)

> live.tips bakiyesi yok, ödeme takvimi yok, kesinti yok. İşte bu üç iddiayı cesur değil sıkıcı kılan mimari.

Canonical: https://live.tips/tr/blog/live-tips-parayi-nasil-yonetir/
Published: 2026-07-02
Updated: 2026-07-13
Language: tr
Tags: Stripe, privacy, open source

---

Herhangi bir bahşiş kavanozu, açılış sayfasına "%0 komisyon" yazabilir. Asıl
ilginç soru şu: yazılımın bir pay almaya *başlaması* için ne yapması gerekirdi ve
bunun ne kadarını görebilirdin.

live.tips için cevap şu: baştan yeniden yazılması gerekirdi. Bu, niyetlerimize dair
bir söz değil; paranın nereye gittiğinin bir tarifi.

## Kartlı bahşişler hiçbir zaman bizden geçmez

Bir hayran kartla bir tutara dokunduğunda, tarayıcısı `api.stripe.com` ile konuşur.
Bir live.tips sunucusuyla değil — o yolda öyle bir şey yok. Ödeme **senin** Stripe
hesabında oluşturulur, **senin** Stripe bakiyene yerleşir ve **senin** Stripe
takvimine göre ödenir. Tek ücret, Stripe'ın kendi standart işlem komisyonudur; onu
da Stripe senden doğrudan tahsil eder, tıpkı Stripe'ı kendin entegre etmiş olsaydın
olacağı gibi.

Bizim tarafımızda hiçbir defter yok, çünkü kaydedilecek bir şey yok. Önce parayı
tutan şeyi inşa etmeden bir yüzdeyi sıyırıp alamazdık.

## Anahtarların senin kalır

Kurulum, canlı bir gizli anahtar değil, *kısıtlı* bir Stripe API anahtarı ister —
öylelerini düpedüz reddederiz. Anahtar, cihazının kendi anahtar zincirinde saklanır
ve yalnızca TLS üzerinden Stripe'a gönderilir.

"Kısıtlı", anahtarın iki şey yapabildiği anlamına gelir: "ne kadar istersen öde"
bahşiş bağlantısını oluşturmak ve bahşişlerin gelişini izlemek. Bakiyeni okuyamaz,
ödemeleri tetikleyemez, iade yapamaz ya da müşteri verilerine dokunamaz. Yarın
sızsa, patlama yarıçapı bir bahşiş bağlantısıdır.

## Ödeme yolundaki tek sunucu

Revolut ve MobilePay, Stripe gibi bir tarayıcıdan sürülemez; bu yüzden bunları
etkinleştirmek asgari bir aktarıcıyı devreye sokar — bahşiş sayfanı
`tip.live.tips` adresinde sunan bir avuç Firebase fonksiyonu. Bu aktarıcının ne
yaptığı konusunda kesin olmakta fayda var, çünkü bu hikâyeler genellikle tam da
"bir arka uç ekledik" noktasında yoldan çıkar.

Senin herkese açık bahşiş sayfası profilini saklar — yayımlamayı seçtiğin görünen
adı ve ödeme tanıtıcılarını. Hepsi bu. Hiçbir bahşiş geçmişi tutmaz, hiç para görmez,
hiç anahtar tutmaz ve 90 günlük hareketsizliğin ardından kendini siler. Revolut ya
da MobilePay'le verilen bir bahşiş orada yalnızca sahnedeki cihazın onu alana kadar
bekler: gösterilmesi onu siler ve kimsenin dönüp almadığı her şey bir saat içinde
süpürülür. Para yine de doğrudan hayranının Revolut ya da MobilePay uygulamasıyla
seninki arasında hareket eder.

Yalnızca Stripe kullanıyorsan, aktarıcıya hiçbir zaman başvurulmaz.

## Açmak zorunda olmadığın hesap

Uygulama hâlâ cihazın kendi yerel profiliyle açılıyor; her zaman olduğu gibi:
bahşiş kavanozun, anahtarın ve bahşiş geçmişin cihazında yaşıyor, başka hiçbir
yerde. Kaydolunacak bir şey yok.

Oturum açmak — Apple ile, Google ile ya da misafir olarak — artık mümkün ve tek bir
sebep için var: ikinci bir cihaz. Sahnedeki tablet ile cebindeki telefon aynı geceyi
gösterecekse, aralarında bir şeyin durması gerekir; o şey de yalnızca senin
okuyabildiğin bir kullanıcı kimliği altındaki Firestore. Grupların, ayarların,
kısıtlı anahtarın ve bahşiş geçmişin oraya eşitlenir. Bu, gizlilik hikâyesinde
gerçek bir değişiklik ve sonradan keşfedilmektense açıkça söylenmeyi hak ediyor:
hesap olmadan hiçbir sunucu bir bahşişi görmez; hesapla birlikte bizim sunucumuzun
sadece sana ait köşesi görür. Bu, ikinci cihazın bedeli ve ödemek ya da reddetmek
sana kalmış. Asla dokunmadığı şey ise para: bir hesap verilerini taşır, bakiyeni
değil ve hâlâ hiçbir pay almıyoruz.

## Neden bize öylece inanmamalısın

Yukarıdakilerin hepsi doğrulanabilir. Kod tabanı MIT lisanslı ve herkese açık; site
ise GitHub Actions tarafından GitHub Pages'e dağıtılan statik bir derleme — gizli
altyapı yok, kapalı kapı ardında derlenmiş hiçbir şey yok. Bir demo bahşiş sırasında
ağ sekmesini aç ve istekleri oku. Beklediğinden daha azdır.

Asıl ürün iddiası budur. Güvenilir olduğumuz değil, buna ihtiyacın olmadığı.
