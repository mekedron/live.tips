---
title: Tek QR kod, her ödeme yöntemi
description: Çoğu bahşiş aracı sana her ödeme sağlayıcısı için bir kod verir. Üç tanesini mikrofon sehpasına yapıştır ve insanların pes edişini izle. İşte live.tips neden tek kodda kalıyor.
slug: tek-qr-kod-her-odeme-yontemi
---

Yeterince sokak müzisyeninin önünden geç, bir süre sonra bandı fark etmeye
başlarsın. Gitar kutusunda bir Revolut kodu. Amfide bir MobilePay kodu. Belki bir
de PayPal'ınki, köşeleri kıvrılmış, iki yaz önceki bir turnedan kalma.

Bu kodların her biri, kalabalıktan birinin tam da o uygulamayı kullandığına dair
küçük bir bahis. Hep birlikte bir ödev duvarı oluşturuyorlar; hem de çoktan durmuş,
çoktan telefonuna uzanmış ve arkadaşı *hadi gel* demeden önce belki sekiz saniyelik
iyi niyeti kalmış bir insanın önüne konmuş bir duvar.

## Sorun çatal, uygulama değil

Ödeme sağlayıcıları bölgeseldir. Revolut Avrupa genelinde iyi yol alır. MobilePay,
Finlerin ve Danimarkalıların birbirine ödeme yapma biçimidir. Swish İsveç'e
hükmeder. Turist dolu bir meydana çalan Helsinkili bir sokak müzisyeninin gerçekten
birden fazlasına ihtiyacı vardır — işte o kısım hata değil.

Hata, bunu izleyiciye çözdürmektir. MobilePay yüklü olmadan bir MobilePay kodunu
tarayan bir hayran, diğer kodlarını aramaya gitmez. Telefonu cebine koyar. Bahşişi,
vermek istemedikleri için kaybetmedin; tam da cömert hissettikleri anda ellerine bir
yönlendirme kararı tutuşturduğun için kaybettin.

## Bunun yerine ne yapıyoruz

live.tips sana tek bir QR kod verir ve o kod asla değişmez. Stripe, Revolut ve
MobilePay'i birlikte aç; aynı kod, kabul ettiğin her yöntemi listeleyen tek bir
bahşiş sayfasını açar. Hayran, zaten sahip olduğu yöntemi seçer. Kimse hiçbir şeyi
iki kez taramaz.

Yalnızca kartla ödeme istiyorsan, listeyi hiç görmezsin — birleşik sayfa ancak
ikinci bir yöntemi etkinleştirdiğinde ortaya çıkar. Tek kod, tek sayfa; ve sayfa
sağlayıcıya değil, sana uyum sağlar.

Daha sessiz bir fayda daha var. Kutunun üzerindeki kod artık kalıcı bir nesne. Bir
kez basabilir, lamine edebilir, kapağa yapıştırabilirsin; gelecek bahar Revolut
eklediğinde ya da taşındıktan sonra MobilePay'i çıkardığında çalışmaya devam eder.
Sahne ekipmanın artık ödeme yığınının bir fonksiyonu olmaktan çıkar.

## Para aslında nereye gidiyor

Açıkça söylemekte fayda var, çünkü "her yöntem için tek sayfa", bir platformun
komisyonunu açıklamadan hemen önce kurduğu cümlenin ta kendisidir: kartlı bahşişler
doğrudan hayranından senin kendi Stripe hesabına gider. Biz bunun ortasında değiliz.
live.tips bakiyesi yok, ödeme takvimi yok, kesinti yok.

Revolut ve MobilePay akışları biraz farklı çalışır; bunu ayrıca
[live.tips parayı nasıl yönetir](post:how-live-tips-handles-money) yazısında anlattık
— gitar kutuna bir şey yapıştırmadan önce şartları okuyan türden biriysen, beş
dakikaya değer. Öyle biri olmalısın.

## Dene

[Uygulamayı](/app/?lang=tr) aç, Stripe'ı demo modunda bırak ve kendi telefonunu
ürettiği koda tut. İkinci bir yöntem ekle ve aynı kodu tekrar tara. Aynı kod.
Özelliğin tamamı bu.
