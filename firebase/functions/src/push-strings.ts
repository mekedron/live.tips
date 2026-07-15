/// The push notification's words, in the app's 20 languages.
///
/// A push is composed on the SERVER, which never runs the app's i18n: the
/// app resolves its UI language on the device (AppSettings.localeCode, or
/// the OS language when unset) and writes the resolved code onto its device
/// doc next to the FCM token — so every device is pushed to in the language
/// its screen already speaks, and two phones of one account can disagree.
///
/// Three short strings per language, no more: the title labels for the two
/// notification kinds, and the body used when a tip carries no name. Keys
/// mirror app/assets/i18n/<code>.json's language set exactly (app_locale.dart
/// is the authority on which codes exist); anything unknown falls back to
/// English, same as the app's own missing-key rule.

export interface PushStrings {
  /** Title label of a plain tip: "New tip · €5.00". */
  newTip: string;
  /** Title label of a song-request tip (#64): "Song request · €5.00". */
  songRequest: string;
  /** Body when the fan left no name. */
  someone: string;
  /** The settings page's "Send test notification" pair. */
  testTitle: string;
  testBody: string;
}

const EN: PushStrings = { newTip: "New tip", songRequest: "Song request", someone: "Someone left you a tip", testTitle: "Test notification", testBody: "If you can read this, tips will reach this device." };

const STRINGS: Record<string, PushStrings> = {
  en: EN,
  de: { newTip: "Neues Trinkgeld", songRequest: "Songwunsch", someone: "Jemand hat dir Trinkgeld dagelassen", testTitle: "Testbenachrichtigung", testBody: "Wenn du das liest, erreichen Trinkgelder dieses Gerät." },
  fr: { newTip: "Nouveau pourboire", songRequest: "Chanson demandée", someone: "Quelqu'un vous a laissé un pourboire", testTitle: "Notification de test", testBody: "Si vous lisez ceci, les pourboires arriveront sur cet appareil." },
  es: { newTip: "Nueva propina", songRequest: "Canción pedida", someone: "Alguien te ha dejado una propina", testTitle: "Notificación de prueba", testBody: "Si puedes leer esto, las propinas llegarán a este dispositivo." },
  it: { newTip: "Nuova mancia", songRequest: "Canzone richiesta", someone: "Qualcuno ti ha lasciato una mancia", testTitle: "Notifica di prova", testBody: "Se leggi questo, le mance arriveranno su questo dispositivo." },
  pt: { newTip: "Nova gorjeta", songRequest: "Pedido de música", someone: "Alguém te deixou uma gorjeta", testTitle: "Notificação de teste", testBody: "Se consegues ler isto, as gorjetas vão chegar a este dispositivo." },
  nl: { newTip: "Nieuwe fooi", songRequest: "Verzoeknummer", someone: "Iemand heeft je een fooi gegeven", testTitle: "Testmelding", testBody: "Als je dit kunt lezen, komen fooien op dit apparaat aan." },
  pl: { newTip: "Nowy napiwek", songRequest: "Zamówiona piosenka", someone: "Ktoś zostawił ci napiwek", testTitle: "Powiadomienie testowe", testBody: "Jeśli to czytasz, napiwki będą docierać na to urządzenie." },
  uk: { newTip: "Нові чайові", songRequest: "Замовлення пісні", someone: "Хтось залишив вам чайові", testTitle: "Тестове сповіщення", testBody: "Якщо ви це читаєте, чайові надходитимуть на цей пристрій." },
  cs: { newTip: "Nové spropitné", songRequest: "Přání písně", someone: "Někdo vám nechal spropitné", testTitle: "Zkušební oznámení", testBody: "Pokud tohle čtete, spropitné bude na toto zařízení chodit." },
  hu: { newTip: "Új borravaló", songRequest: "Zenekérés", someone: "Valaki borravalót hagyott neked", testTitle: "Tesztértesítés", testBody: "Ha ezt olvasod, a borravalók meg fognak érkezni erre az eszközre." },
  ro: { newTip: "Bacșiș nou", songRequest: "Melodie cerută", someone: "Cineva ți-a lăsat un bacșiș", testTitle: "Notificare de test", testBody: "Dacă citești asta, bacșișurile vor ajunge pe acest dispozitiv." },
  el: { newTip: "Νέο φιλοδώρημα", songRequest: "Αίτημα τραγουδιού", someone: "Κάποιος σας άφησε φιλοδώρημα", testTitle: "Δοκιμαστική ειδοποίηση", testBody: "Αν το διαβάζετε αυτό, τα φιλοδωρήματα θα φτάνουν σε αυτήν τη συσκευή." },
  tr: { newTip: "Yeni bahşiş", songRequest: "Şarkı isteği", someone: "Biri size bahşiş bıraktı", testTitle: "Test bildirimi", testBody: "Bunu okuyabiliyorsanız bahşişler bu cihaza ulaşacak." },
  sv: { newTip: "Ny dricks", songRequest: "Låtönskning", someone: "Någon gav dig dricks", testTitle: "Testavisering", testBody: "Om du kan läsa detta når dricksen den här enheten." },
  da: { newTip: "Nye drikkepenge", songRequest: "Sangønske", someone: "Nogen gav dig drikkepenge", testTitle: "Testnotifikation", testBody: "Hvis du kan læse dette, når drikkepenge frem til denne enhed." },
  no: { newTip: "Ny driks", songRequest: "Låtønske", someone: "Noen ga deg driks", testTitle: "Testvarsel", testBody: "Hvis du kan lese dette, når driksen denne enheten." },
  fi: { newTip: "Uusi tippi", songRequest: "Kappaletoive", someone: "Joku jätti sinulle tipin", testTitle: "Testi-ilmoitus", testBody: "Jos näet tämän, tipit saapuvat tälle laitteelle." },
  is: { newTip: "Nýtt þjórfé", songRequest: "Lagaósk", someone: "Einhver skildi eftir þjórfé handa þér", testTitle: "Prófunartilkynning", testBody: "Ef þú getur lesið þetta mun þjórfé berast í þetta tæki." },
  ru: { newTip: "Новые чаевые", songRequest: "Заказ песни", someone: "Кто-то оставил вам чаевые", testTitle: "Тестовое уведомление", testBody: "Если вы это читаете — чаевые будут приходить на это устройство." },
};

/**
 * Strings for a device's stored locale. Tolerates anything a device doc
 * could carry: an exact code, a regional tag ("de-AT" → "de"), a missing
 * field, or junk — English answers for all of them.
 */
export function pushStrings(locale: string | undefined): PushStrings {
  if (locale === undefined) return EN;
  const exact = STRINGS[locale];
  if (exact !== undefined) return exact;
  return STRINGS[(locale.split(/[-_]/)[0] ?? "").toLowerCase()] ?? EN;
}
