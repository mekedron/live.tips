---
title: Gizlilik Politikası
description: live.tips'te çerez yok, analitik yok, takip yok ve uygulama hiç hesap açmadan çalışır. Yine de oturum açmayı seçerseniz, tam olarak neyin nerede, kim tarafından ve ne kadar süreyle saklandığı burada.
updated: 2026-07-13
updated_label: Son güncelleme 13 Temmuz 2026
---

live.tips, sahne sanatçıları için açık kaynaklı bir bahşiş kavanozudur. Bir şirket değil,
bireysel bir geliştirici olan **Nikita Rabykin** tarafından işletilir. Aşağıdakilerden
herhangi biri sizin için önemliyse **[contact@live.tips](mailto:contact@live.tips)**
adresine yazın — o adres gerçek bir insana ulaşır.

Bu politika, sıkıcı kısımlar konusunda dürüsttür. "Hiçbir şey saklamıyoruz" deyip
yanılmaktansa, "adınızı en fazla bir saat saklıyoruz" demeyi tercih ederiz.

## Kısa özet

- **Hesap isteğe bağlıdır.** Uygulama hiç hesap olmadan çalışır ve bu hâlâ varsayılan
  durumdur. Gruplarınızı ve geçmişinizi ikinci bir cihazda da görmek isterseniz oturum
  açabilirsiniz — o zaman bunların bir kısmı bir sunucuda saklanır. Hangisinin hangisi
  olduğu aşağıda anlatılıyor.
- **Çerez yok.** Hiçbir yerde, tek bir tane bile.
- Bu web sitesinde **analitik yok, takip yok, reklam yok, üçüncü taraf betiği yok**.
- **Paranıza asla dokunmayız.** Bahşişler doğrudan hayrandan sanatçının kendi Stripe,
  Revolut, MobilePay veya Monzo hesabına gider. Biz bu yolun üzerinde değiliz.
- **Varsayılan kurulumda uygulama yalnızca Stripe ile konuşur** — herhangi bir live.tips
  sunucusuyla değil.
- İşlettiğimiz tek sunucu, Google'ın Firebase'i üzerinde duran küçük bir aktarıcıdır. Bir
  sanatçı Revolut, MobilePay veya Monzo'yu açarsa — ya da oturum açarsa — devreye girer.

## Bu web sitesi

Site statiktir ve **GitHub Pages** üzerinde barındırılır. Barındırıcı olarak GitHub, bir
sayfayı yükleyen herkesin IP adresini ve tarayıcı kullanıcı aracısını alır — bu, sıradan
bir web sunucusu günlüğüdür, bizim kodumuz çalışmadan önce gerçekleşir ve kapatamayız.
GitHub bunu kendi
[gizlilik beyanı](https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement)
kapsamında işler. Bu günlükleri biz okumayız ve GitHub bize göstermez.

Bunun ötesinde, okuduğunuz sayfalar **başka hiç kimseden hiçbir şey yüklemez**. Yazı
tipleri, simgeler ve görseller live.tips'in kendisinden sunulur. Google Analytics yok, etiket
yöneticisi yok, piksel yok, gömülü bileşen yok.

Site, tarayıcınızın **`localStorage` alanında iki değer** saklar. Her ikisini de siz
belirlersiniz, her ikisi de yalnızca bu site tarafından okunabilir ve hiçbiri hiçbir yere
gönderilmez.

| Anahtar | Neyi hatırlar |
| --- | --- |
| `lt-landing-theme` | açık, koyu ya da otomatik renkleri seçip seçmediğinizi |
| `lt-langbar-dismissed` | "kendi dilinizde de mevcut" bandını kapattığınızı |

Tarayıcı deposunu temizlemek bunları siler. Çerez değildirler, paylaşılmazlar ve kimseyi
tanımlamazlar.

## Uygulamanın iki kipi var ve bütün mesele aradaki farkta

Aşağıdaki her şey tek bir soruya bağlı: **oturum açtınız mı?**

### Birinci kip — hesap yok. Hâlâ varsayılan, hâlâ değişmemiş.

Uygulama **sanatçının kendi cihazında** çalışır ve bildiği her şey orada durur.

- **Stripe kısıtlı anahtarı**, cihazın anahtar zincirinde (iOS/macOS Keychain, Android
  Keystore) saklanır ve yalnızca `api.stripe.com` adresine gönderilir.
- **Bahşiş geçmişi, oturum geçmişi, hedef ve uygulama ayarları** yerel cihaz deposunda
  saklanır. Buna hayranların bahşişlerine ekledikleri adlar ve mesajlar da dahildir.
- Uygulamayı kaldırmak bunların tümünü siler. Bizim tarafımızda bulut yedeği yoktur, çünkü
  bu kipte bizim tarafımızda bulut yoktur.

**Bunların hiçbiri bize ulaşmaz.** Uygulama; analitik SDK'sı, çökme raporlayıcısı, anlık
bildirim ve reklam kodu olmadan gelir — hiçbiri yok, devre dışı bırakılmış olanlar bile.

"Kimseyle konuşmuyor" iddiasının tam anlamıyla doğru kalması için iki açıklama.

- Uygulama, günde bir kez genel kur API'lerinden (`frankfurter.dev`, `open.er-api.com`,
  `currency-api.pages.dev`) **döviz kurlarını** çeker. Bunlar, herkese açık bir kur
  listesi için yapılan sıradan isteklerdir. Sizin, sanatçının ya da herhangi bir bahşişin
  hakkında hiçbir bilgi taşımazlar — ancak her web isteği gibi, IP adresinizi bu
  servislere ifşa ederler.
- Uygulamanın **tarayıcı sürümünü** kullanıyorsanız, tarayıcınız onu statik
  barındırıcımızdan indirir (yukarıdaki *Bu web sitesi* bölümüne bakın).

### İkinci kip — oturum açtınız. O zaman bazı veriler cihazdan bilerek ayrılır.

Oturum açmak bilinçli bir eylemdir. Sizin yerinize kimse oturum açmaz ve hiç açmasanız da
uygulamanın hiçbir yanı çalışmayı bırakmaz. Oturumu, ikinci bir cihaz istediğiniz için
açarsınız: cebinizdeki telefon ile sahnedeki tablet aynı geceyi, aynı grupları, aynı geçmişi
göstersin diye.

Bu yalnızca bunları bir sunucu tutuyorsa mümkün olur. **Dolayısıyla tutuyor ve ikinci
cihazın dürüst bedeli budur.**

Sunucu, Google demek olan **Firebase**'dir. Hesap sahibi olmanın üç yolu vardır.

- **Apple ile oturum açma** veya **Google ile oturum açma** — Firebase Auth, sağlayıcının
  verdiği her şeyi alır: bir kullanıcı kimliği (uid) ve genellikle bir e-posta adresi ile bir
  ad. (Apple'da e-postanızı gizleyebilirsiniz; o zaman Apple bize onun yerine bir aktarma
  adresi verir.)
- **Bir misafir hesabı** — e-postası ve adı olmayan anonim bir hesap. Eşitleme yapar ve iptal
  edilebilir, ama cihazı kaybederseniz onu kurtaracak hiçbir şey yoktur. Yalnızca bir uid'dir,
  başka bir şey değil.

Oturum açtığınızda hesap, Google'ın **Cloud Firestore** veritabanında kendi özel köşesini
alır: `users/<your uid>/`. Güvenlik kuralları bu köşeyi o uid'e verir **ve başka hiç kimseye
vermez** — URL tahmin etmek de dahil, başka hiçbir hesap orayı okuyamaz. İçinde şunlar var.

| Ne | Neden orada |
| --- | --- |
| **Gruplarınız** — adlar, bahşiş kavanozu ve ödeme yöntemi ayarları, afiş metni, hedefler | oturum açtığınız her cihazda grup var olsun diye |
| **Stripe kısıtlı anahtarınız** ve aktarıcıdaki bahşiş sayfası sırrı | yalnızca sizin uid'inizin okuyabildiği bir sırlar belgesinde ve cihazlarınızın her birinin anahtar zincirinde önbelleklenmiş olarak |
| **Uygulama ayarları** | eklediğiniz bir cihaz baştan ayarlı gelsin diye |
| **Oturum kayıtları ve bahşiş geçmişi** — **hayranların bahşişlerine ekledikleri adlar ve mesajlar** dahil | çünkü diğer cihazda görmek istediğiniz şey tam olarak bu geçmiş |
| Şu anda süren **canlı oturum** | ikinci bir ekran bu geceki sete katılabilsin diye |
| **Cihazlarınız** — her birinin kendine verdiği ad ("Nikita'nın iPhone'u"), platformu ve modeli, ilk ve son görüldüğü zaman | Ayarlar → Güvenlik onları listeleyebilsin ve siz birini iptal edebilesiniz diye |
| Küçük bir **profil belgesi** — seçtiğiniz hesap adı ve hangi sağlayıcıyı kullandığınız | hesap değiştirici onu etiketleyebilsin diye |

Şimdi asıl önemli kısım, açıkça: **hesap yokken bir hayranın adı ve mesajı sanatçının
cihazından asla ayrılmaz. Hesap varken bunlar, sanatçının kendi eşitlenmiş geçmişinin parçası
olarak, sanatçının uid'i altında Google'ın sunucularında saklanır.** Başka hiçbir hesap onları
okuyamaz, biz onlara bakmayız ve onlardan hiçbir şey türetilmez — ama oradadırlar ve oturum
açmadan önce bunu bilmelisiniz.

Oturumu kapatmak cihazı yerel kipe geri döndürür. Hesabın verilerini silmez — aşağıdaki
*Silme işlemleri* bölümüne bakın.

### QR koduyla cihaz ekleme

Bir cihaz eklemek için, zaten oturum açmış bir cihazdan bir QR kodu gösterirsiniz. Kod
rastgeledir, **tek kullanımlıktır ve iki dakikada geçerliliğini yitirir**; siz eski cihazda
*onayla*'ya dokunana kadar yeni cihaz hiçbir şey almaz. Bu el sıkışma açıkken kodu, yeni
cihazın kendine verdiği adı ve platformunu tutarız — ve kod süresi dolduğunda kayıt silinir.
Fotoğrafı çekilmiş bir QR kodu, sizin onay dokunuşunuz olmadan işe yaramaz.

## Bütün bunlar fiziksel olarak nerede duruyor

Firebase Auth, Cloud Firestore ve Cloud Functions'ımız **Avrupa Birliği**'nde çalışır:
veritabanı Google'ın `eur3` çoklu bölgesinde, fonksiyonlar `europe-west1`'de. Google,
[Firebase gizlilik ve güvenlik koşulları](https://firebase.google.com/support/privacy) ile
kendi [gizlilik politikası](https://policies.google.com/privacy) kapsamında bizim veri
işleyenimiz olarak hareket eder. Her büyük sağlayıcı gibi Google da destek ve güvenlik için
AB dışındaki altyapıyı devreye sokabilir; bunu biz değil, o koşullar düzenler.

## Stripe

Bir hayran kartla ödediğinde, bizim değil **Stripe'ın** ödeme sayfasındadır. Stripe, onun
ödeme verilerini bağımsız bir veri sorumlusu olarak
[Stripe Gizlilik Politikası](https://stripe.com/privacy) kapsamında toplar ve işler. Kart
numaralarını asla görmeyiz ve sanatçının Stripe hesabına erişimimiz yoktur.

Sanatçının uygulaması, kendi bahşişlerini Stripe'tan sanatçının kendi kısıtlı anahtarıyla
okur — doğrudan cihazdan `api.stripe.com` adresine. **Bu yolun üzerinde hiçbir live.tips
sunucusu yoktur ve hiçbir zaman olmadı.** Bir hayranın bıraktığı ad ve mesaj, varsa,
Stripe'tan sanatçının cihazına gider ve orada kalır — sanatçı oturum açmadıysa. Açtıysa, cihaz
bunları yukarıda anlatıldığı gibi sanatçının kendi Firestore geçmişine de kaydeder.

## Aktarıcı — yalnızca Revolut, MobilePay veya Monzo açıksa

Yalnızca Stripe kullanan kurulumlar buna hiç temas etmez.

Revolut, MobilePay ve Monzo, bir uygulamanın ödemenin gerçekleştiğini doğrulamasına imkân
tanımaz. Bu nedenle o bahşişler, **Firebase** üzerinde işlettiğimiz küçük ve açık kaynaklı bir
aktarıcıdan geçirilir: `europe-west1`'de Cloud Functions ve Firestore, hayranın gördüğü bahşiş
sayfası ise **`tip.live.tips/t/<id>`** adresinden sunulur. Aktarıcı paraya asla dokunmaz.
İşlediği her şey aşağıda.

### Sanatçının sakladıkları

Bir bahşiş sayfası oluşturmak; sanatçının **görünen adını, herkese açık mesajını, para
birimini ve yayımlamayı seçtiği ödeme kimliklerini** (Stripe ödeme bağlantısı, Revolut
kullanıcı adı, MobilePay Box ID, Monzo kullanıcı adı) saklar. Bunların tümü, sanatçının
zaten bilerek hayranlara yayımladığı bilgilerdir.

- **Saklama süresi — arkasında hesap olmayan bir bahşiş sayfası, 90 gün hareketsizlikten sonra
  otomatik olarak silinir.** Oturum açmış bir hesaba ait bir bahşiş sayfası, bağlı olduğu grup
  yaşadığı sürece yaşar.
- Sanatçı bunu istediği zaman, uygulamadan **anında** silebilir.
- Burada e-posta adresi, parola, resmî ad ya da banka bilgisi toplanmaz.
- Sayfanın sırrı **yalnızca özet (hash) olarak** saklanır. İsteseniz de size o sırrı
  söyleyemeyiz; yalnızca elimizdekiyle karşılaştırıp doğrulayabiliriz.

### Bir hayranın gönderdikleri

Bahşiş formu bir **tutar** ister, isteğe bağlı olarak da bir **ad** ve bir **mesaj**.
Formun tamamı bu kadar. E-posta yok, telefon numarası yok, hesap yok.

- Bahşiş bir **teslim kuyruğuna** yazılır — bu, yalnızca sanatçının ekranına devredilmek için
  var olan tek bir belgedir. Ekran bahşişi gösterdiğinde, **sanatçının cihazı o belgeyi
  siler.** Silme işlemi teslim onayının *ta kendisidir*; "teslim edildi" diye bir işaret
  yoktur, çünkü işaretlenecek bir kayıt kalmaz.
- Sanatçının ekranı çevrimdışıysa — telefon kilitli, sinyal yok — bahşiş, öylece kaybolmaması
  için **bu kuyrukta en fazla bir saat bekler** ve ekran yeniden bağlandığı anda teslim edilir.
  Kimse yeniden bağlanmazsa, bahşiş **görülmeden silinir**; kimse geri gelmiş olsun ya da
  olmasın, zamanlanmış bir görev onu temizler.
- **Hayran tarafından yazılmış metnin sunucumuzda saklandığı tek yer bu kuyruktur ve bir saat
  onun kesin sınırıdır.** Sanatçı oturum açmışsa, cihazı bahşişi sonrasında *kendi* Firestore
  geçmişinde tutar — çünkü bu onun geçmişidir ve oturumu bunun için açmıştır.
- Adınız ve mesajınız ayrıca Revolut, MobilePay veya Monzo'da açılan **ödeme notuna** da
  yerleştirilir — sanatçı kimin bahşiş bıraktığını böyle bilir. Bu şirketler daha sonra
  bunu kendi gizlilik politikaları kapsamında işler.
- Aktarıcı **hiçbir bahşiş geçmişi tutmaz**. Size, bize ya da bir başkasına kimin kime
  bahşiş verdiğine dair bir liste gösteremez.

### IP adresleri ve kötüye kullanımın önlenmesi

Herkesin gönderi yapabileceği açık bir formun botlara karşı bir miktar korumaya ihtiyacı
vardır, bu yüzden.

- IP adresiniz, bot olmadığınızı doğrulamak üzere **Cloudflare Turnstile**'a — bahşiş
  sayfasında çalışan bir bot karşıtı denetim — gönderilir. Turnstile, Cloudflare'in ürünüdür ve
  sizi profilleyen bir CAPTCHA yerine kullanılır. Turnstile ile DNS'imiz, Cloudflare'in bizim
  için hâlâ yaptığı tek şeydir; aktarıcının kendisi artık Firebase üzerinde çalışıyor. Bkz.
  [Cloudflare Gizlilik Politikası](https://www.cloudflare.com/privacypolicy/).
- IP adresiniz ayrıca istekleri **hız sınırlamak** için de kullanılır — bahşiş göndermek, bahşiş
  sayfası oluşturmak, cihaz ekleme kodunu kullanmak. Bunun için sakladığımız şey, IP'nin
  kendisi değil, **tuzlanmış kriptografik bir IP özetidir**; yaklaşık **iki saat** tutulur ve
  sonra silinir. Tuz bir sunucu sırrıdır: o olmadan kod, geri çevrilebilecek bir özet tutmaktansa
  hiçbir şey saklamamayı seçer.
- **Google'ın operasyonel günlükleri**, aktarıcıya yapılan isteklerin teknik ayrıntılarını —
  URL, zamanlama, durum — birkaç gün boyunca kaydeder. Kodumuz bilerek hiçbir ad, mesaj, sır
  veya başlık günlüğe yazmaz. Google bizim veri işleyenimiz olarak hareket eder.

### Sayaçlar

Aktarıcı, belirli bir bahşiş sayfasının **kaç bahşiş** aktardığını sayar; böylece kötüye
kullanımı fark edebilir ve bu şeyin hiç kullanılıp kullanılmadığını bilebiliriz. Bu bir
sayıdır. Hiçbir hayran verisi içermez.

## Kim neyi işliyor

| Kim | Ne alıyor | Neden |
| --- | --- | --- |
| **Google (Firebase)** | Hesaplar, oturum açmış bir sanatçının eşitlenmiş verileri, aktarıcı, sunucu günlükleri | İsteğe bağlı hesap ve isteğe bağlı aktarıcı |
| **Stripe** | Hayranın ödeme verileri, bağımsız veri sorumlusu olarak | Kartlı bahşişler |
| **Cloudflare** | Bahşiş sayfasındaki Turnstile denetimi için hayranın IP'si. Bir de DNS'imiz. | Bahşiş formunu botlardan uzak tutmak |
| **GitHub** | Bu web sitesini yükleyen herkesin IP'si ve kullanıcı aracısı | Web sitesini barındırmak |
| **Revolut / MobilePay / Monzo** | Hayranın kendi uygulamalarında yaptığı her şey, ödeme notu dahil | O ödeme yöntemleri |

Kimseye hiçbir şey satmıyoruz ve bu listede başka kimse yok.

## Hukuki dayanak, gerekirse (GDPR)

- İstediğiniz hesabı çalıştırmak, kendi verilerinizi kendi cihazlarınıza eşitlemek, aktarıcıyı
  açan bir sanatçı için onu çalıştırmak ve bir hayranın bahşişini hedeflediği ekrana ulaştırmak
  — **talep ettiğiniz bir hizmetin ifası**.
- Hız sınırlama, Turnstile, özetlenmiş IP kotaları ve cihaz iptali — ücretsiz ve açık bir
  hizmetin botlar ve dolandırıcılık tarafından yok edilmesini önlemede ve sanatçıların
  hesaplarını güvende tutmada **meşru menfaat**.
- Sunucu günlükleri — hizmeti işletme ve güvenliğini sağlamada **meşru menfaat**.

## Silme işlemleri

Bu, bu konuda verebileceğimiz her sözden daha önemlidir; dolayısıyla bugün elimizde tam olarak
ne var — ve ne yok — işte aşağıda.

- **Hesap yoksa**: uygulamayı kaldırın. Hepsi bu, hepsi gitti.
- **Bir grup**: uygulamada bir grubu kaldırmak, o grubun buluttaki verilerini — ayarlarını,
  anahtarlarını, oturumlarını, bahşiş geçmişini — cihazdaki kopyasıyla birlikte siler.
- **Bir bahşiş sayfası**: uygulamada silin ya da yeniden oluşturun; bekleyen bahşişler dahil,
  aktarıcıdan anında silinir.
- **Bir cihaz**: Ayarlar → Güvenlik cihazlarınızı listeler. Birini iptal edebilir ya da diğer
  her yerde oturumu kapatabilirsiniz — bu, diğer her cihazın oturumunu bir süre sonra değil,
  anında sonlandırır.
- **Hesabınızın tamamı, tek dokunuşla: uygulamada henüz o düğme yok.** Aksini iddia etmektense
  bunu itiraf etmeyi tercih ederiz. O düğme gelene kadar
  **[contact@live.tips](mailto:contact@live.tips)** adresine yazın; hesabı ve altındaki her şeyi
  elle sileriz. Bu arada şimdiden her grubu silebilirsiniz; bu, kayda değer her şeyi kaldırır ve
  geriye boş bir hesap bırakır.

## Haklarınız

Hakkınızda tuttuğumuz her şeyin bir kopyasını vermemizi, düzeltmemizi veya silmemizi
isteyebilir ve ulusal veri koruma otoritenize şikâyette bulunabilirsiniz.
**[contact@live.tips](mailto:contact@live.tips)** adresine yazın.

Uygulamada bunların çoğu zaten sizin elinizde. Bir sanatçı bir bahşiş sayfasını ya da bir grubu
uygulamadan anında silebilir, teslim edilmemiş hayran bahşişleri bir saat içinde buharlaşır ve
hiç oturum açmadıysanız, bunların hiçbiri kendi cihazınızdan başka hiçbir yerde olmamıştır.

## Çocuklar

live.tips çocuklara yönelik değildir ve bilerek onların verilerini işlemeyiz.

## Değişiklikler

Yazılım değiştikçe bu sayfayı güncelleyeceğiz. Projenin tamamı açık kaynak olduğu için, **bu
politikanın geçmiş her sürümü herkese açık git geçmişinde bulunur** — neyin ne zaman
değiştiğini birebir karşılaştırabilirsiniz.

## Dil

Bu politika, kolaylık olsun diye sitenin desteklediği her dilde yayımlanır. Bir çeviri ile
İngilizce sürüm arasında uyuşmazlık olursa, **geçerli olan İngilizce sürümdür**.
