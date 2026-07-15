---
title: Gizlilik Politikası
description: live.tips'te çerez yok, analitik yok, takip yok ve uygulama hiç hesap açmadan çalışır. Yine de oturum açmayı seçerseniz, tam olarak neyin nerede, kim tarafından ve ne kadar süreyle saklandığı burada.
updated: 2026-07-15
updated_label: Son güncelleme 15 Temmuz 2026
---

live.tips, sahne sanatçıları için açık kaynaklı bir bahşiş kavanozudur. Bir şirket değil,
bireysel bir geliştirici olan **Nikita Rabykin** tarafından işletilir. Aşağıdakilerden
herhangi biri sizin için önemliyse **[contact@live.tips](mailto:contact@live.tips)**
adresine yazın — o adres gerçek bir insana ulaşır.

Bu politika, sıkıcı kısımlar konusunda dürüsttür. "Hiçbir şey saklamıyoruz" deyip
yanılmaktansa, "grubunuzu tuttuğunuz sürece adınızı saklıyoruz" demeyi tercih ederiz.

## Kısa özet

- **Hesap isteğe bağlıdır.** Uygulama hiç hesap olmadan çalışır ve bu hâlâ varsayılan
  durumdur. Gruplarınızı ve geçmişinizi ikinci bir cihazda da görmek isterseniz oturum
  açabilirsiniz — o zaman bunların bir kısmı bir sunucuda saklanır, hem de öncekinden daha
  fazlası. Hangisinin hangisi olduğu aşağıda anlatılıyor.
- **Çerez yok.** Hiçbir yerde, tek bir tane bile.
- Bu web sitesinde **analitik yok, takip yok, reklam yok, üçüncü taraf betiği yok**.
- **Paranıza asla dokunmayız.** Bahşişler doğrudan hayrandan sanatçının kendi Stripe,
  Revolut, MobilePay veya Monzo hesabına gider. Hiçbir zaman bir live.tips bakiyesi yoktur.
- **Hesap yokken uygulama yalnızca Stripe ile konuşur** — herhangi bir live.tips sunucusuyla
  değil. Oturum açarsanız bu değişir: Stripe anahtarınız sunucumuza taşınır ve Stripe
  bahşişlerinizi bize bildirir; böylece onları diğer cihazlarınıza koyabiliriz. Oturum
  açmanın dürüst bedeli budur ve aşağıda tam olarak anlatılıyor.
- **Anlık bildirimler yeni, isteğe bağlı ve yalnızca oturum açmış hesaplar içindir.** Hiçbir
  zaman açmamış bir cihaza hiçbir bildirim gönderilmez ve hesapsız bir cihaza asla bir tane
  bile gönderilmez.
- İşlettiğimiz sunucular Google'ın Firebase'i üzerindedir. Bir sanatçı Revolut, MobilePay
  veya Monzo'yu açarsa — ya da oturum açarsa — devreye girerler.

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
- **Bahşiş geçmişi, oturum geçmişi, hedef, şarkı isteği listesi ve uygulama ayarları** yerel
  cihaz deposunda saklanır. Buna hayranların bahşişlerine ekledikleri adlar ve mesajlar da
  dahildir.
- Uygulamayı kaldırmak bunların tümünü siler. Bizim tarafımızda bulut yedeği yoktur, çünkü
  bu kipte bizim tarafımızda bulut yoktur.

**Bunların hiçbiri bize ulaşmaz.** Uygulama; analitik SDK'sı, çökme raporlayıcısı ve reklam
kodu olmadan gelir — hiçbiri yok, devre dışı bırakılmış olanlar bile. (Anlık bildirimler
vardır, ama bunlar oturum açmaya bağlı bir özelliktir ve siz açana kadar kapalıdır — bkz.
*İkinci kip*. Hesapsız bir cihaza asla bir tane gönderilmez.)

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
  adresi verir ve adınızı yalnızca ilk oturum açtığınızda bir kez verir.)
- **Bir misafir hesabı** — e-postası ve adı olmayan anonim bir hesap. Eşitleme yapar ve iptal
  edilebilir, ama cihazı kaybederseniz onu kurtaracak hiçbir şey yoktur. Yalnızca bir uid'dir,
  başka bir şey değil. Bir misafir hesabı, aşağıda anlatılan sunucu tarafı Stripe muhafazasını
  ya da anlık bildirimleri kullanamaz, çünkü ikisi de size geri verebileceğimiz bir hesap
  gerektirir.

Oturum açtığınızda hesap, Google'ın **Cloud Firestore** veritabanında kendi özel köşesini
alır: `users/<your uid>/`. Güvenlik kuralları bu köşeyi o uid'e verir **ve başka hiç kimseye
vermez** — URL tahmin etmek de dahil, başka hiçbir hesap orayı okuyamaz. İçinde şunlar var.

| Ne | Neden orada |
| --- | --- |
| **Gruplarınız** — adlar, bahşiş kavanozu ve ödeme yöntemi ayarları, afiş metni, hedefler ve **şarkı isteği listeniz** | oturum açtığınız her cihazda grup var olsun diye |
| **Uygulama ayarları**, bildirim tercihleriniz dahil | eklediğiniz bir cihaz baştan ayarlı gelsin diye |
| **Oturum kayıtları ve bahşiş geçmişi** — **hayranların bahşişlerine ekledikleri adlar ve mesajlar** ve bir **hayranın istediği herhangi bir şarkı** dahil | çünkü diğer cihazda görmek istediğiniz şey tam olarak bu geçmiş |
| Şu anda süren **canlı oturum** | ikinci bir ekran bu geceki sete katılabilsin diye |
| **Cihazlarınız** — her birinin kendine verdiği ad ("Nikita'nın iPhone'u"), platformu ve modeli, arayüz dili, ilk ve son görüldüğü zaman ve (bildirimleri açtıysanız) bir **anlık bildirim jetonu** | Ayarlar → Güvenlik onları listeleyebilsin, bir bildirim doğru cihaza doğru dilde ulaşabilsin ve siz birini iptal edebilesiniz diye |
| Küçük bir **profil belgesi** — seçtiğiniz hesap adı ve hangi sağlayıcıyı kullandığınız | hesap değiştirici onu etiketleyebilsin diye |
| Bir **zil akışı** — hiçbir set çalışmazken gelen son bahşişlerin ve şarkı isteklerinin sınırlı bir listesi | kaçırdıklarınızı sonradan görebilesiniz diye |

Şimdi asıl önemli kısım, açıkça: **hesap yokken bir hayranın adı ve mesajı sanatçının
cihazından asla ayrılmaz. Hesap varken bunlar, sanatçının kendi eşitlenmiş geçmişinin parçası
olarak, sanatçının uid'i altında Google'ın sunucularında saklanır** ve — sonraki iki bölümün
açıkladığı gibi — **onları oraya artık bizim sunucumuz yazar.** Başka hiçbir hesap onları
okuyamaz, biz onlara bakmayız ve onlardan hiçbir şey türetilmez — ama oradadırlar ve grup
durdukça orada kalırlar; oturum açmadan önce bunu bilmelisiniz.

Oturumu kapatmak cihazı yerel kipe geri döndürür. Hesabın verilerini silmez — aşağıdaki
*Silme işlemleri* bölümüne bakın.

#### Stripe anahtarınız, oturum açtığınızda sunucumuza taşınır

Bu, en büyük değişikliktir ve okunmaya en çok değer olanıdır.

**Hesap yokken, Stripe kısıtlı anahtarınız cihazınızdan asla çıkmaz.** Bu, birinci kiptir ve
değişmemiştir.

**Oturum açtığınızda ise çıkar — bize.** Anahtar şifrelenir (her sır için ayrı bir AES-256
anahtarı, o da Google Cloud KMS tarafından sarmalanır) ve sunucu tarafında, **hiç kimsenin
geri okuyamayacağı bir yerde — başka bir hesabın değil, sizin bile değil** — saklanır.
Yalnızca Cloud Functions'ımızın içinde açılır, sizin adınıza Stripe ile konuşmak için
kullanılır ve bir daha asla bir cihaza verilmez.

Anahtar artık bizde durduğu için, **Stripe bahşişlerinizi doğrudan sunucumuza bildirir**:
kendi Stripe hesabınıza bir webhook kaydederiz ve Stripe, her bahşiş ödendiğinde o webhook'a
haber verir. Fonksiyonumuz bahşişi, hesabınızın geçmişine yazar (aşağıya bakın). Oturum açmış
bir hesap için uygulamanız artık Stripe'ı yoklamaz; Stripe'a yalnızca sunucumuzdaki dar ve
sabit bir işlem listesi üzerinden ulaşır (bahşiş bağlantınızı oluşturmak, bir şarkı isteği
bağlantısı üretmek ve mutabakat için kendi bahşişlerinizi geri okumak).

Yani, dolambaçsız söylersek: **oturum açmış bir hesap için artık Stripe ile geçmişiniz
arasındaki yolda bir live.tips sunucusu vardır.** Yine de paraya asla dokunmayız — bir kartlı
bahşiş, tam eskisi gibi, Stripe hesabınıza karşı oluşturulur, Stripe bakiyenize yerleşir ve
Stripe takviminize göre ödenir. Değişen şey *veri* yoludur, *para* yolu değil. Hiç oturum
açmazsanız bunların hiçbiri geçerli olmaz ve uygulama yine doğrudan `api.stripe.com` ile
konuşur, başka hiç kimseyle değil.

#### QR koduyla cihaz ekleme

Bir cihaz eklemek için, zaten oturum açmış bir cihazdan bir QR kodu gösterirsiniz. Kod
rastgeledir, **tek kullanımlıktır ve iki dakikada geçerliliğini yitirir**; siz eski cihazda
*onayla*'ya dokunana kadar yeni cihaz hiçbir şey almaz. Bu el sıkışma açıkken kodu, yeni
cihazın kendine verdiği adı ve platformunu tutarız — ve kod süresi dolduğunda kayıt silinir.
Fotoğrafı çekilmiş bir QR kodu, sizin onay dokunuşunuz olmadan işe yaramaz.

## Şarkı istekleri

Bir grup **şarkı isteklerini** açabilir: hayranlar o zaman sanatçının listesinden bir şarkı
seçer ve isteğe bağlı olarak, onu kuyrukta yukarı taşımak için ödeme yapar. Bir istek,
yalnızca **hangi şarkının** istendiğini de taşıyan bir bahşiştir — dolayısıyla bir hayranın
bir bahşişe ekleyebileceği aynı ad ve mesaj burada da geçerlidir ve tıpkı başka herhangi bir
bahşiş gibi saklanır ve tutulur (aşağıda). Bir hayranın gördüğü herkese açık kuyruk yalnızca
**şarkı başına toplamları** gösterir — bir şarkının ne kadar topladığını ve nerede durduğunu
— ve **hiçbir hayran adı** taşımaz. Hesap yokken, şarkı isteği listesinin tamamı ve geçmişi
yalnızca cihazda yaşar.

## Anlık bildirimler

Oturum açtığınızda, uygulama size bir **anlık bildirim** gönderebilir — ama yalnızca cihaz
başına onu açarsanız ve yalnızca cihazınızın işletim sistemi izin verdikten sonra. Tek bir şey
için vardır: **bir set çalıştırmadığınız sırada** gelen bir bahşiş ya da bir şarkı isteği;
böylece aksi hâlde kaçıracağınız bahşişten haberdar olursunuz. Sahneniz canlıyken gelen bir
bahşiş hiçbir şey göndermez — onu zaten izliyorsunuz.

- Bir anlık bildirimi teslim etmek için Google'ın **Firebase Cloud Messaging (FCM)**
  hizmetinin cihaza ait bir **anlık bildirim jetonuna** ihtiyacı vardır. O jetonu ve cihazın
  arayüz dilini, hesabınız altındaki cihazın kendi kaydında saklarız; bildirimleri
  kapattığınız, cihazı iptal ettiğiniz ya da oturumu kapattığınız anda silinir. Ölü jetonlar
  otomatik olarak temizlenir.
- Bildirimin kendisi neyin geldiğini söyler — bir tutar ve bir hayran bıraktıysa adını ya da
  şarkı başlığını. Aynı kısa liste, hesabınızın **zil akışında** en fazla son yüz girişle
  sınırlı olarak tutulur; böylece siz yokken gelenleri geriye doğru kaydırarak görebilirsiniz.
- Web'de bir anlık bildirimi teslim etmek, site kökünde küçük bir **service worker** ile
  tarayıcınızın ilk seferde Google'dan (`gstatic.com`) çektiği Firebase mesajlaşma SDK'sını
  gerektirir. Web anlık bildirimi daha sonra tarayıcınızın kendi anlık bildirim hizmetiyle
  taşınır (Chrome için bu, Google'ınkidir). Bildirimleri açmadıkça bunların hiçbiri yüklenmez.
- **Bir misafir hesabı ve hesapsız bir cihaz hiçbir anlık bildirim almaz**, çünkü bir anlık
  bildirim, teslim edebileceğimiz bir hesap ve sizin vermeyi seçtiğiniz bir jeton gerektirir.

## Bütün bunlar fiziksel olarak nerede duruyor

Firebase Auth, Cloud Firestore, Cloud Functions'ımız ve Stripe sırrınızı sarmalayan Cloud KMS
anahtarı **Avrupa Birliği**'nde çalışır: veritabanı Google'ın `eur3` çoklu bölgesinde,
fonksiyonlar ve anahtar halkası `europe-west1`'de. Google,
[Firebase gizlilik ve güvenlik koşulları](https://firebase.google.com/support/privacy) ile
kendi [gizlilik politikası](https://policies.google.com/privacy) kapsamında bizim veri
işleyenimiz olarak hareket eder. Her büyük sağlayıcı gibi Google da destek ve güvenlik için
AB dışındaki altyapıyı devreye sokabilir; bunu biz değil, o koşullar düzenler. Anlık
bildirimler, bir kez Firebase Cloud Messaging'e ve tarayıcınızın ya da telefonunuzun anlık
bildirim hizmetine devredildikten sonra, cihazınıza ulaşmak için o şirketlerin altyapısı
üzerinden yol alır.

## Stripe

Bir hayran kartla ödediğinde, bizim değil **Stripe'ın** ödeme sayfasındadır. Stripe, onun
ödeme verilerini bağımsız bir veri sorumlusu olarak
[Stripe Gizlilik Politikası](https://stripe.com/privacy) kapsamında toplar ve işler. Kart
numaralarını asla görmeyiz.

Bahşişlerinizin size nasıl ulaştığı kipe bağlıdır:

- **Hesap yokken**, sanatçının uygulaması kendi bahşişlerini Stripe'tan sanatçının kendi
  kısıtlı anahtarıyla okur — doğrudan cihazdan `api.stripe.com` adresine. **Bu yolun üzerinde
  hiçbir live.tips sunucusu yoktur.**
- **Oturum açıldığında**, anahtar sunucumuzda durur (yukarıdaki gibi şifreli) ve Stripe her
  bahşişi webhook'umuza bildirir; o da bahşişi o sanatçının kendi Firestore geçmişine yazar.
  **Bu kipte yolun üzerinde bir live.tips sunucusu vardır** — bahşiş verisi için, asla para
  için değil. Bir hayranın adı ve mesajı, bıraktıysa, bahşişle birlikte o sanatçının kendi
  geçmişine gider ve orada durur.

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
kullanıcı adı, MobilePay Box ID, Monzo kullanıcı adı) ve şarkı istekleri açıksa **herkese açık
şarkı listesini ve şarkı başına fiyatlarını** saklar. Bunların tümü, sanatçının zaten bilerek
hayranlara yayımladığı bilgilerdir.

- **Saklama süresi — arkasında hesap olmayan bir bahşiş sayfası, 90 gün hareketsizlikten sonra
  otomatik olarak silinir.** Oturum açmış bir hesaba ait bir bahşiş sayfası, bağlı olduğu grup
  yaşadığı sürece yaşar.
- Sanatçı bunu istediği zaman, uygulamadan **anında** silebilir.
- Burada e-posta adresi, parola, resmî ad ya da banka bilgisi toplanmaz.
- Sayfanın sırrı **yalnızca özet (hash) olarak** saklanır. İsteseniz de size o sırrı
  söyleyemeyiz; yalnızca elimizdekiyle karşılaştırıp doğrulayabiliriz.

### Bir hayranın gönderdikleri

Bahşiş formu bir **tutar** ister, isteğe bağlı olarak da bir **ad** ve bir **mesaj** — ve bir
şarkı isteği için, hangi şarkı olduğunu. Formun tamamı bu kadar. E-posta yok, telefon numarası
yok, hesap yok.

O hayran tarafından yazılmış metnin nereye gittiği ve ne kadar süreyle orada kaldığı,
sanatçının oturum açıp açmadığına bağlıdır:

- **Bahşiş sayfasının arkasında hesap yoksa**, bahşiş bir **teslim kuyruğuna** yazılır — bu,
  yalnızca sanatçının ekranına devredilmek için var olan tek bir belgedir. Ekran bahşişi
  gösterdiğinde, **sanatçının cihazı o belgeyi siler.** Silme işlemi teslim onayının *ta
  kendisidir*. Sanatçının ekranı çevrimdışıysa — telefon kilitli, sinyal yok — bahşiş, öylece
  kaybolmaması için **bu kuyrukta en fazla bir saat bekler** ve ekran yeniden bağlandığı anda
  teslim edilir. Kimse yeniden bağlanmazsa, bahşiş **görülmeden silinir**; zamanlanmış bir
  görev onu temizler. Hesapsız bir sanatçı için, **hayran tarafından yazılmış metnin
  sunucumuzda saklandığı tek yer bu kuyruktur ve bir saat onun kesin sınırıdır.**
- **Bahşiş sayfası oturum açmış bir hesaba aitse**, kuyruk yoktur. Sunucumuz bahşişi, o
  sanatçının uid'i altında **doğrudan kendi geçmişine** yazar — bir set çalışıyorsa bu geceki
  oturuma, çalışmıyorsa grubun kendi arşivine. Orada **grup durdukça kalır**; bu, sanatçının
  kendi geçmişidir ve oturumu bunun için açmıştır. Bu, yukarıda Stripe webhook'unun yazdığı
  geçmişin aynısıdır.
- Adınız ve mesajınız ayrıca Revolut, MobilePay veya Monzo'da açılan **ödeme notuna** da
  yerleştirilir — sanatçı kimin bahşiş bıraktığını böyle bilir. Bu şirketler daha sonra
  bunu kendi gizlilik politikaları kapsamında işler.
- Aktarıcı **hiçbir sanatçılar arası bahşiş defteri tutmaz**. Size, bize ya da bir başkasına,
  sanatçılar arasında kimin kime bahşiş verdiğine dair bir liste gösteremez.

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
| **Google (Firebase)** | Hesaplar, oturum açmış bir sanatçının eşitlenmiş verileri, şifreli Stripe anahtarı, aktarıcı, anlık bildirim jetonları ve teslimatı, sunucu günlükleri | İsteğe bağlı hesap, isteğe bağlı aktarıcı ve anlık bildirimler |
| **Google Cloud KMS** | Oturum açmış bir sanatçının Stripe sırrını sarmalayan anahtar (sır asla açık hâliyle değil) | Saklanan Stripe anahtarını beklerken okunamaz tutmak |
| **Stripe** | Hayranın ödeme verileri, bağımsız veri sorumlusu olarak; ve oturum açmış bir sanatçı için webhook'umuza gönderilen bahşiş olayları | Kartlı bahşişler |
| **Cloudflare** | Bahşiş sayfasındaki Turnstile denetimi için hayranın IP'si. Bir de DNS'imiz. | Bahşiş formunu botlardan uzak tutmak |
| **GitHub** | Bu web sitesini yükleyen herkesin IP'si ve kullanıcı aracısı | Web sitesini barındırmak |
| **Tarayıcınız / telefonunuzun anlık bildirim hizmeti** (ör. Chrome için Google'ınki) | Bildirimleri açtıysanız bir anlık bildirim jetonu ve bildirim içeriği | Anlık bildirimleri teslim etmek |
| **Revolut / MobilePay / Monzo** | Hayranın kendi uygulamalarında yaptığı her şey, ödeme notu dahil | O ödeme yöntemleri |

Kimseye hiçbir şey satmıyoruz ve bu listede başka kimse yok.

## Hukuki dayanak, gerekirse (GDPR)

- İstediğiniz hesabı çalıştırmak, kendi verilerinizi kendi cihazlarınıza eşitlemek,
  bahşişleriniz geçmişinize ulaşsın diye Stripe anahtarınızı tutmak, aktarıcıyı açan bir
  sanatçı için onu çalıştırmak, bir hayranın bahşişini hedeflediği ekrana ulaştırmak ve
  açtığınız bir anlık bildirimi göndermek — **talep ettiğiniz bir hizmetin ifası**.
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
- **Anlık bildirimler**: bir cihazda onları kapatın, cihazın anlık bildirim jetonu silinir.
  Zil akışı, grup ya da hesapla birlikte temizlenir.
- **Bir cihaz**: Ayarlar → Güvenlik cihazlarınızı listeler. Birini iptal edebilir ya da diğer
  her yerde oturumu kapatabilirsiniz — bu, diğer her cihazın oturumunu bir süre sonra değil,
  anında sonlandırır.
- **Hesabınızın tamamı, tek dokunuşla: uygulamada henüz o düğme yok.** Aksini iddia etmektense
  bunu itiraf etmeyi tercih ederiz. O düğme gelene kadar
  **[contact@live.tips](mailto:contact@live.tips)** adresine yazın; hesabı ve altındaki her şeyi
  elle sileriz. Bu arada şimdiden her grubu silebilirsiniz; bu, saklanan Stripe anahtarı dahil
  kayda değer her şeyi kaldırır ve geriye boş bir hesap bırakır.

## Haklarınız

Hakkınızda tuttuğumuz her şeyin bir kopyasını vermemizi, düzeltmemizi veya silmemizi
isteyebilir ve ulusal veri koruma otoritenize şikâyette bulunabilirsiniz.
**[contact@live.tips](mailto:contact@live.tips)** adresine yazın.

Uygulamada bunların çoğu zaten sizin elinizde. Bir sanatçı bir bahşiş sayfasını ya da bir grubu
uygulamadan anında silebilir, hesapsız bir sayfadaki teslim edilmemiş hayran bahşişleri bir saat
içinde buharlaşır ve hiç oturum açmadıysanız, bunların hiçbiri kendi cihazınızdan başka hiçbir
yerde olmamıştır.

## Çocuklar

live.tips çocuklara yönelik değildir ve bilerek onların verilerini işlemeyiz.

## Değişiklikler

Yazılım değiştikçe bu sayfayı güncelleyeceğiz. Projenin tamamı açık kaynak olduğu için, **bu
politikanın geçmiş her sürümü herkese açık git geçmişinde bulunur** — neyin ne zaman
değiştiğini birebir karşılaştırabilirsiniz.

## Dil

Bu politika, kolaylık olsun diye sitenin desteklediği her dilde yayımlanır. Bir çeviri ile
İngilizce sürüm arasında uyuşmazlık olursa, **geçerli olan İngilizce sürümdür**.
</content>
