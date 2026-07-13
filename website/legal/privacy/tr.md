---
title: Gizlilik Politikası
description: live.tips'te hesap yok, çerez yok, analitik yok, takip yok. İşlenen şeylerin kısa listesi, kimin işlediği ve ne kadar süreyle sakladığı burada.
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

- **Hesap yok.** Kaydolunacak bir şey yok.
- **Çerez yok.** Hiçbir yerde, tek bir tane bile.
- Bu web sitesinde **analitik yok, takip yok, reklam yok, üçüncü taraf betiği yok**.
- **Paranıza asla dokunmayız.** Bahşişler doğrudan hayrandan sanatçının kendi Stripe,
  Revolut, MobilePay veya Monzo hesabına gider. Biz bu yolun üzerinde değiliz.
- **Varsayılan kurulumda uygulama yalnızca Stripe ile konuşur** — herhangi bir live.tips
  sunucusuyla değil.
- İşlettiğimiz tek sunucu küçük bir aktarıcıdır ve yalnızca bir sanatçı Revolut,
  MobilePay veya Monzo'yu açarsa devreye girer.

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

## Uygulama

live.tips uygulaması **sanatçının kendi cihazında** çalışır. Bildiği her şey orada durur.

- **Stripe kısıtlı anahtarı**, cihazın anahtar zincirinde (iOS/macOS Keychain, Android
  Keystore) saklanır ve yalnızca `api.stripe.com` adresine gönderilir.
- **Bahşiş geçmişi, oturum geçmişi, hedef ve uygulama ayarları** yerel cihaz deposunda
  saklanır. Buna hayranların bahşişlerine ekledikleri adlar ve mesajlar da dahildir.
- Uygulamayı kaldırmak bunların tümünü siler. Bizim tarafımızda bulut yedeği yoktur, çünkü
  bizim tarafımızda bulut yoktur.

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

## Stripe

Bir hayran kartla ödediğinde, bizim değil **Stripe'ın** ödeme sayfasındadır. Stripe, onun
ödeme verilerini bağımsız bir veri sorumlusu olarak
[Stripe Gizlilik Politikası](https://stripe.com/privacy) kapsamında toplar ve işler. Kart
numaralarını asla görmeyiz ve sanatçının Stripe hesabına erişimimiz yoktur.

Sanatçının uygulaması, kendi bahşişlerini Stripe'tan sanatçının kendi kısıtlı anahtarıyla
okur. Bir hayranın bıraktığı ad ve mesaj, varsa, Stripe'tan sanatçının cihazına gider ve
orada kalır.

## Aktarıcı — yalnızca Revolut, MobilePay veya Monzo açıksa

Yalnızca Stripe kullanan kurulumlar buna hiç temas etmez ve okumayı burada bırakabilir.

Revolut, MobilePay ve Monzo, bir uygulamanın ödemenin gerçekleştiğini doğrulamasına imkân
tanımaz. Bu nedenle o bahşişler, **Cloudflare** üzerinde `api.live.tips` adresinde
işlettiğimiz küçük ve açık kaynaklı bir aktarıcıdan geçirilir. Aktarıcı paraya asla
dokunmaz. İşlediği her şey aşağıda.

### Sanatçının sakladıkları

Bir bahşiş sayfası oluşturmak; sanatçının **görünen adını, herkese açık mesajını, para
birimini ve yayımlamayı seçtiği ödeme kimliklerini** (Stripe ödeme bağlantısı, Revolut
kullanıcı adı, MobilePay Box ID, Monzo kullanıcı adı) saklar. Bunların tümü, sanatçının
zaten bilerek hayranlara yayımladığı bilgilerdir.

- **Saklama süresi — 90 gün hareketsizlikten sonra otomatik olarak silinir.**
- Sanatçı bunu istediği zaman, uygulamadan **anında** silebilir.
- E-posta adresi, parola, resmî ad ya da banka bilgisi asla toplanmaz.

### Bir hayranın gönderdikleri

Bahşiş formu bir **tutar** ister, isteğe bağlı olarak da bir **ad** ve bir **mesaj**.
Formun tamamı bu kadar. E-posta yok, telefon numarası yok, hesap yok.

- Sanatçının ekranı **çevrimiçiyse**, bahşiş doğrudan ona iletilir ve **hiçbir zaman diske
  yazılmaz**.
- Sanatçının ekranı **çevrimdışıysa** — telefon kilitli, sinyal yok — bahşiş, öylece
  kaybolmaması için **en fazla bir saat boyunca depoda tutulur** ve ekran yeniden
  bağlandığı anda teslim edilir. Kimse yeniden bağlanmazsa, bahşiş **görülmeden silinir**.
  Aktarıcının sakladığı, hayran tarafından yazılmış tek metin budur ve bir saat onun kesin
  sınırıdır.
- Adınız ve mesajınız ayrıca Revolut, MobilePay veya Monzo'da açılan **ödeme notuna** da
  yerleştirilir — sanatçı kimin bahşiş bıraktığını böyle bilir. Bu şirketler daha sonra
  bunu kendi gizlilik politikaları kapsamında işler.
- Aktarıcı **hiçbir bahşiş geçmişi tutmaz**. Size, bize ya da bir başkasına kimin kime
  bahşiş verdiğine dair bir liste gösteremez.

### IP adresleri ve kötüye kullanımın önlenmesi

Herkesin gönderi yapabileceği açık bir formun botlara karşı bir miktar korumaya ihtiyacı
vardır, bu yüzden.

- IP adresiniz, istekleri **hız sınırlamak** için kullanılır ve bot olmadığınızı doğrulamak
  üzere **Cloudflare Turnstile**'a (bahşiş sayfasında çalışan bir bot karşıtı denetim)
  gönderilir. Turnstile, Cloudflare'in ürünüdür ve sizi profilleyen bir CAPTCHA yerine
  kullanılır.
- Birinin binlerce bahşiş sayfası oluşturmasını engellemek için, sayfayı oluşturanın
  **IP'sinin kriptografik özeti** yaklaşık **iki saat** boyunca tutulur, sonra atılır.
- **Cloudflare'in operasyonel günlükleri**, aktarıcıya yapılan isteklerin teknik
  ayrıntılarını — URL, zamanlama, durum — birkaç gün boyunca kaydeder. Bu günlükler hayran
  adlarını veya mesajlarını içermez. Cloudflare bizim veri işleyenimiz olarak hareket eder;
  bkz. [Cloudflare Gizlilik Politikası](https://www.cloudflare.com/privacypolicy/).

### Sayaçlar

Aktarıcı, belirli bir bahşiş sayfasının **kaç bahşiş** aktardığını sayar; böylece kötüye
kullanımı fark edebilir ve bu şeyin hiç kullanılıp kullanılmadığını bilebiliriz. Bu bir
sayıdır. Hiçbir hayran verisi içermez.

## Hukuki dayanak, gerekirse (GDPR)

- Aktarıcıyı açan bir sanatçı için onu çalıştırmak ve bir hayranın bahşişini hedeflediği
  ekrana ulaştırmak — **talep ettiğiniz bir hizmetin ifası**.
- Hız sınırlama, Turnstile ve özetlenmiş IP kotaları — ücretsiz ve açık bir hizmetin botlar
  ve dolandırıcılık tarafından yok edilmesini önlemede **meşru menfaat**.
- Sunucu günlükleri — hizmeti işletme ve güvenliğini sağlamada **meşru menfaat**.

## Haklarınız

Hakkınızda tuttuğumuz her şeyin bir kopyasını vermemizi, düzeltmemizi veya silmemizi
isteyebilir ve ulusal veri koruma otoritenize şikâyette bulunabilirsiniz.
**[contact@live.tips](mailto:contact@live.tips)** adresine yazın.

Uygulamada bunların çoğu zaten sizin elinizde. Sanatçılar bahşiş sayfalarını uygulamadan
anında silebilir, hayran bahşişleri bir saat içinde buharlaşır ve geri kalan her şey kendi
cihazınızda durur.

## Çocuklar

live.tips çocuklara yönelik değildir ve bilerek onların verilerini işlemeyiz.

## Değişiklikler

Yazılım değiştikçe bu sayfayı güncelleyeceğiz. Projenin tamamı açık kaynak olduğu için, **bu
politikanın geçmiş her sürümü herkese açık git geçmişinde bulunur** — neyin ne zaman
değiştiğini birebir karşılaştırabilirsiniz.

## Dil

Bu politika, kolaylık olsun diye sitenin desteklediği her dilde yayımlanır. Bir çeviri ile
İngilizce sürüm arasında uyuşmazlık olursa, **geçerli olan İngilizce sürümdür**.
