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

## Bir sunucunun var olduğu tek yer

Revolut ve MobilePay, Stripe gibi bir tarayıcıdan sürülemez; bu yüzden bunları
etkinleştirmek `api.live.tips` adresinde asgari bir aktarıcıyı devreye sokar. Bu
aktarıcının ne yaptığı konusunda kesin olmakta fayda var, çünkü bu hikâyeler
genellikle tam da "bir arka uç ekledik" noktasında yoldan çıkar.

Senin herkese açık bahşiş sayfası profilini saklar — yayımlamayı seçtiğin görünen
adı ve ödeme tanıtıcılarını. Hepsi bu. Hiçbir bahşiş geçmişi tutmaz, hiç para görmez,
hiç anahtar tutmaz ve 90 günlük hareketsizliğin ardından kendini siler. Para yine de
doğrudan hayranının Revolut ya da MobilePay uygulamasıyla seninki arasında hareket
eder.

Yalnızca Stripe kullanıyorsan, aktarıcıya hiçbir zaman başvurulmaz.

## Neden bize öylece inanmamalısın

Yukarıdakilerin hepsi doğrulanabilir. Kod tabanı MIT lisanslı ve herkese açık; site
ise GitHub Actions tarafından GitHub Pages'e dağıtılan statik bir derleme — gizli
altyapı yok, kapalı kapı ardında derlenmiş hiçbir şey yok. Bir demo bahşiş sırasında
ağ sekmesini aç ve istekleri oku. Beklediğinden daha azdır.

Asıl ürün iddiası budur. Güvenilir olduğumuz değil, buna ihtiyacın olmadığı.
