/// Everything the app needs to know about creating the restricted API key —
/// shown in the connect screen and mirrored in docs/onboarding.
///
/// Permission slugs and the prefilled create-key URL were verified against
/// the live dashboard on 2026-07-03 (see docs/onboarding). Note that the
/// "Prices" permission is internally called `plan_write` — Stripe's error
/// messages and the `rak_plan_write` slug both use the legacy "plan" name.
library;

class RequiredPermission {
  const RequiredPermission({
    required this.slug,
    required this.resource,
    required this.access,
    required this.why,
  });

  /// Stable id for i18n lookup (`enum.perm_why.<slug>`). The [resource] and
  /// [access] mirror the (English) Stripe dashboard and stay untranslated;
  /// only [why] — our own explanation — is localized, keyed by this slug.
  final String slug;

  final String resource;
  final String access; // "Read" | "Write"
  final String why;
}

/// Minimum permissions, per the principle of least privilege. Everything
/// else stays "None" — the key can't touch balances, payouts, refunds,
/// or customer data.
const kRequiredPermissions = [
  RequiredPermission(
    slug: 'checkout_sessions',
    resource: 'Checkout Sessions',
    access: 'Read',
    why: 'See incoming donations — history and details.',
  ),
  RequiredPermission(
    slug: 'events',
    resource: 'Events',
    access: 'Read',
    why: 'Live feed: poll for new donations during a session.',
  ),
  // Read-only, like the two above. A restricted key only sees an event whose
  // object it may read, so the charge.succeeded feed — in-person contactless
  // tips — needs this row as well as Events. Nothing here grants a write, a
  // refund, a balance or a payout; that promise is the point.
  RequiredPermission(
    slug: 'charges',
    resource: 'Charges',
    access: 'Read',
    why: 'See in-person tips you tap on a card reader or phone.',
  ),
  RequiredPermission(
    slug: 'payment_links',
    resource: 'Payment Links',
    access: 'Write',
    why: 'Create and manage your donation link.',
  ),
  RequiredPermission(
    slug: 'products',
    resource: 'Products',
    access: 'Write',
    why: 'Create the "Tips" product behind the link.',
  ),
  RequiredPermission(
    slug: 'prices',
    resource: 'Prices',
    access: 'Write',
    why: 'Create the pay-what-you-want price for tips.',
  ),
];

/// Dashboard page where keys are managed manually.
const kApiKeysDashboardUrl = 'https://dashboard.stripe.com/apikeys';

/// Opens the dashboard's "create restricted key" form with the key name and
/// exactly the six permissions above pre-selected. The artist still reviews
/// everything and clicks "Create key" in their own dashboard — we never see
/// the account. (Slugs verified by creating a key from this URL and
/// exercising it against the API.)
///
/// An unknown slug is ignored by the form rather than rejected, so a wrong one
/// fails quietly: the row simply arrives unticked, and the app's permission
/// check then names the missing row. That is the safety net behind
/// `rak_charge_read` — re-verify it in the dashboard the next time you open
/// this form.
const kCreateKeyUrl =
    'https://dashboard.stripe.com/apikeys/create?name=live.tips%20app'
    '&permissions[0]=rak_bucket_checkout_read'
    '&permissions[1]=rak_event_read'
    '&permissions[2]=rak_charge_read'
    '&permissions[3]=rak_bucket_payment_links_write'
    '&permissions[4]=rak_product_write'
    '&permissions[5]=rak_plan_write'
    '&thirdparty_integration_name=live.tips'
    '&thirdparty_integration_url=https%3A%2F%2Flive.tips';

const kProjectUrl = 'https://github.com/mekedron/app.live.tips';
