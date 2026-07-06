import 'package:flutter_test/flutter_test.dart';
import 'package:live_tips/data/local_store.dart';
import 'package:live_tips/domain/donation.dart';
import 'package:live_tips/domain/live_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

Donation _tip(String id, {required bool livemode}) => Donation(
      id: id,
      amountMinor: 500,
      currency: 'usd',
      createdAt: DateTime.utc(2026, 7, 3),
      livemode: livemode,
    );

LiveSession _session(String id, List<Donation> donations) => LiveSession(
      id: id,
      startedAt: DateTime.utc(2026, 7, 3),
      endedAt: DateTime.utc(2026, 7, 3, 1),
      currency: 'usd',
      goalMinor: 10000,
      donations: donations,
    );

Future<LocalStore> _freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStore(await SharedPreferences.getInstance());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('purge keeps live sessions and drops demo/test ones, order intact',
      () async {
    final store = await _freshStore();
    await store.appendSessionToHistory(
        _session('demo', [_tip('demo_1', livemode: false)]));
    await store.appendSessionToHistory(
        _session('live', [_tip('cs_live_1', livemode: true)]));
    await store.appendSessionToHistory(
        _session('test', [_tip('cs_test_1', livemode: false)]));

    await store.purgeSimulatedData();

    expect(store.readSessionHistory().map((s) => s.id), ['live']);
  });

  test('purge keeps an empty session — it may be a genuine zero-tip live set',
      () async {
    final store = await _freshStore();
    await store.appendSessionToHistory(_session('empty', const []));
    await store.appendSessionToHistory(
        _session('demo', [_tip('demo_1', livemode: false)]));

    await store.purgeSimulatedData();

    expect(store.readSessionHistory().map((s) => s.id), ['empty']);
  });

  test('purge discards a simulated active session and its cursor', () async {
    final store = await _freshStore();
    await store.saveActiveSession(
        _session('demo', [_tip('demo_1', livemode: false)]), 'cur_1');

    await store.purgeSimulatedData();

    expect(store.readActiveSession(), isNull);
    expect(store.readActiveCursor(), isNull);
  });

  test('purge preserves a live active session and its cursor', () async {
    final store = await _freshStore();
    await store.saveActiveSession(
        _session('live', [_tip('cs_live_1', livemode: true)]), 'cur_1');

    await store.purgeSimulatedData();

    expect(store.readActiveSession()!.id, 'live');
    expect(store.readActiveCursor(), 'cur_1');
  });
}
