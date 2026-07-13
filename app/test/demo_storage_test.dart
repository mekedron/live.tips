import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/data/tip_source.dart';
import 'package:live_tips/domain/band_settings.dart';
import 'package:live_tips/domain/device_kind.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:live_tips/domain/tip.dart';
import 'package:live_tips/state/live_session_controller.dart';
import 'package:live_tips/state/providers.dart';
import 'package:live_tips/state/venue_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// A demo is pretending. It must not write into a real band's slots, and it
/// must not write into nobody's (#52).
///
/// Demo renders the whole shell with no band of its own (#47) and it can go
/// live — a demo set persists a crash snapshot, a goal, a QR mode, a poster
/// and, on Stop, an archived session. Keyed by the ACTIVE BAND, as they were,
/// those writes landed either in the band that happened to be open (on a fresh
/// install, the very band the details step names as the artist's first
/// profile — so their History opened on a night that never happened) or, with
/// no band at all, under the empty suffix `<base>_`: a namespace owned by
/// nobody, that no wipe can name.
///
/// Nothing in the suite had ever asserted what a flow LEAVES BEHIND in prefs —
/// which is why a green suite watched this ship. These tests assert the key
/// set, and the last of them is the invariant in one line: enter demo, play a
/// whole night, leave, and the device is byte-for-byte as it was found.
class _ScriptedSource extends TipSource {
  _ScriptedSource(this._batches);
  final List<List<Tip>> _batches;
  var _i = 0;

  @override
  Future<void> prime(DateTime startedAt,
      {String? resumeCursor, bool backfill = false}) async {}

  @override
  Future<List<Tip>> pollNew() async =>
      _i < _batches.length ? _batches[_i++] : const [];

  @override
  String? get cursor => null;
}

/// Demo tips: never livemode. Same shape the DemoTipSource hands out.
Tip _tip(String id, int amountMinor) => Tip(
      id: id,
      amountMinor: amountMinor,
      currency: 'usd',
      createdAt: DateTime.utc(2026, 7, 14),
      livemode: false,
    );

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Every key SharedPreferences holds, with its value — the thing no test in
/// this suite had ever looked at.
Map<String, Object?> _snapshot(LocalStore store) =>
    {for (final key in store.prefs.getKeys()) key: store.prefs.get(key)};

ProviderContainer _container(LocalStore store) {
  final container = ProviderContainer(overrides: [
    localStoreProvider.overrideWithValue(store),
    secureStoreProvider.overrideWithValue(FakeSecureStore()),
    tipSourceFactoryProvider.overrideWithValue(
        ({required demo, required apiKey, required jar}) => _ScriptedSource([
              [_tip('demo_1', 1000), _tip('demo_2', 2500)],
            ])),
  ]);
  addTearDown(container.dispose);
  return container;
}

/// A full demo night: goal, tips, Stop.
Future<LiveSession?> _demoGoLive(ProviderContainer container) async {
  container.read(appStateProvider.notifier).enterDemo();
  final controller = container.read(liveSessionProvider.notifier);
  await controller.start(goalMinor: 5000);
  await _settle();
  return controller.stop();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a demo go-live writes nothing into the band it stands in front of, '
      'and keeps its own night in its own namespace (#52)', () async {
    // The fresh-install shape: one band in the registry — the one main() mints
    // and the details step later NAMES as the artist's first profile.
    final store = await seededStore(values: {LocalStore.kDeviceKind: 'demo'});
    final container = _container(store);

    final session = await _demoGoLive(container);
    expect(session!.totalMinor, 3500, reason: 'the demo night was played');

    // The artist's band: untouched. Its History has no night in it, its goal
    // and stage look are its own, and no crash snapshot claims it was live.
    expect(store.readSessionHistory(kTestAccountId), isEmpty);
    expect(store.readBandSettingsOrNull(kTestAccountId), isNull);
    expect(store.readActiveSession(kTestAccountId), isNull);
    expect(store.accountHasData(kTestAccountId), isFalse);

    // Demo kept everything — where demo can be wiped from. A demo that forgets
    // the set it just played is a worse demo; that is not the fix.
    final demoHistory = store.readSessionHistory(LocalStore.kDemoAccountId);
    expect(demoHistory.single.totalMinor, 3500);
    expect(
        store.readBandSettingsOrNull(LocalStore.kDemoAccountId)!.lastGoalMinor,
        5000);
  });

  test('a demo go-live on a device with NO band writes no empty-suffix keys '
      '(#52)', () async {
    // The registry exists and is empty: the artist removed their last local
    // profile (#47's state). There is no band, so `<base>_<accountId>` becomes
    // `<base>_` — a namespace belonging to nobody.
    SharedPreferences.setMockInitialValues({
      LocalStore.kAccounts: '{"activeId":"","accounts":[]}',
      LocalStore.kDeviceKind: 'demo',
    });
    final store = LocalStore(await SharedPreferences.getInstance());
    final container = _container(store);

    expect(container.read(appStateProvider).accountId, isEmpty);
    final session = await _demoGoLive(container);
    expect(session!.totalMinor, 3500);

    final orphans = store.prefs
        .getKeys()
        .where((k) => LocalStore.accountKeyBases
            .any((base) => k == LocalStore.accountKey(base, '')))
        .toList();
    expect(orphans, isEmpty,
        reason: 'an empty id is not an id: nothing may be stored under it');
    // And the demo still has its night.
    expect(store.readSessionHistory(LocalStore.kDemoAccountId).single.totalMinor,
        3500);
  });

  test('LocalStore refuses every per-band write with an empty id, and reads '
      'one back as "nothing stored" (#52)', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final before = _snapshot(store);

    await store.saveBandSettings('', const BandSettings(lastGoalMinor: 9000));
    await store.appendSessionToHistory(
        '', LiveSession(id: 's', startedAt: DateTime.utc(2026), currency: 'usd',
            goalMinor: 1000));
    await store.saveActiveSession(
        '',
        LiveSession(
            id: 's',
            startedAt: DateTime.utc(2026),
            currency: 'usd',
            goalMinor: 1000),
        'cur_1');
    await store.appendRelayHistory('', [_tip('relay_1', 500)]);
    await store.writeRelaySeenAt('', 1);
    await store.writeRelayLinkReplaced('', 'https://tip.live.tips/t/x');
    await store.purgeSimulatedData('');

    expect(_snapshot(store), before,
        reason: 'no writer may create a namespace owned by nobody');
    expect(store.readSessionHistory(''), isEmpty);
    expect(store.readActiveSession(''), isNull);
    expect(store.readActiveCursor(''), isNull);
    expect(store.readBandSettingsOrNull(''), isNull);
    expect(store.readBandSettings('').lastGoalMinor,
        const BandSettings().lastGoalMinor);
    expect(store.readRelayHistory(''), isEmpty);
    expect(store.readRelaySeenAt(''), isNull);
    expect(store.accountHasData(''), isFalse);
  });

  test('entering demo, playing a whole night and exiting leaves the device '
      'exactly as it was found (#52)', () async {
    // No kind yet — this is Welcome, on a device that has never chosen.
    final store = await seededStore();
    final container = _container(store);
    final before = _snapshot(store);

    await container.read(deviceKindProvider.notifier).choose(DeviceKind.demo);
    await _demoGoLive(container);
    expect(store.prefs.getKeys(), isNot(before.keys),
        reason: 'the demo really did write something while it was on');

    // Exit demo, in the order #45 fixed: the demo's data and the kind go —
    // awaited — before the in-memory flag drops.
    await container.read(deviceKindProvider.notifier).clearDemo();
    container.read(appStateProvider.notifier).exitDemo();

    expect(_snapshot(store), before);
    expect(container.read(appStateProvider).demo, isFalse);
    expect(store.readDeviceKind(), isNull, reason: '#45: the kind is cleared');
    // And the goal on screen is the band's own again, not the demo's.
    expect(container.read(appStateProvider).band.lastGoalMinor,
        const BandSettings().lastGoalMinor);
  });
}
