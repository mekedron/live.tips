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
}

const EN: PushStrings = { newTip: "New tip", songRequest: "Song request", someone: "Someone left you a tip" };

const STRINGS: Record<string, PushStrings> = {
  en: EN,
  de: { newTip: "Neues Trinkgeld", songRequest: "Songwunsch", someone: "Jemand hat dir Trinkgeld dagelassen" },
  fr: { newTip: "Nouveau pourboire", songRequest: "Chanson demandée", someone: "Quelqu'un vous a laissé un pourboire" },
  es: { newTip: "Nueva propina", songRequest: "Canción pedida", someone: "Alguien te ha dejado una propina" },
  it: { newTip: "Nuova mancia", songRequest: "Canzone richiesta", someone: "Qualcuno ti ha lasciato una mancia" },
  pt: { newTip: "Nova gorjeta", songRequest: "Pedido de música", someone: "Alguém te deixou uma gorjeta" },
  nl: { newTip: "Nieuwe fooi", songRequest: "Verzoeknummer", someone: "Iemand heeft je een fooi gegeven" },
  pl: { newTip: "Nowy napiwek", songRequest: "Zamówiona piosenka", someone: "Ktoś zostawił ci napiwek" },
  uk: { newTip: "Нові чайові", songRequest: "Замовлення пісні", someone: "Хтось залишив вам чайові" },
  cs: { newTip: "Nové spropitné", songRequest: "Přání písně", someone: "Někdo vám nechal spropitné" },
  hu: { newTip: "Új borravaló", songRequest: "Zenekérés", someone: "Valaki borravalót hagyott neked" },
  ro: { newTip: "Bacșiș nou", songRequest: "Melodie cerută", someone: "Cineva ți-a lăsat un bacșiș" },
  el: { newTip: "Νέο φιλοδώρημα", songRequest: "Αίτημα τραγουδιού", someone: "Κάποιος σας άφησε φιλοδώρημα" },
  tr: { newTip: "Yeni bahşiş", songRequest: "Şarkı isteği", someone: "Biri size bahşiş bıraktı" },
  sv: { newTip: "Ny dricks", songRequest: "Låtönskning", someone: "Någon gav dig dricks" },
  da: { newTip: "Nye drikkepenge", songRequest: "Sangønske", someone: "Nogen gav dig drikkepenge" },
  no: { newTip: "Ny driks", songRequest: "Låtønske", someone: "Noen ga deg driks" },
  fi: { newTip: "Uusi tippi", songRequest: "Kappaletoive", someone: "Joku jätti sinulle tipin" },
  is: { newTip: "Nýtt þjórfé", songRequest: "Lagaósk", someone: "Einhver skildi eftir þjórfé handa þér" },
  ru: { newTip: "Новые чаевые", songRequest: "Заказ песни", someone: "Кто-то оставил вам чаевые" },
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
