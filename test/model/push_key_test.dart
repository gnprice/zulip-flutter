import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/push_device.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';

import '../example_data.dart' as eg;
import '../fake_async.dart';
import 'binding.dart';
import 'store_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  test('initial load, getPushKeyById', () {
    final pushKey1 = eg.pushKey(account: eg.selfAccount, pushKeyId: 1);
    final pushKey2 = eg.pushKey(account: eg.selfAccount, pushKeyId: 2);
    final globalStore = eg.globalStore(accounts: [eg.selfAccount],
      pushKeys: [pushKey1, pushKey2]);
    final globalModel = globalStore.pushKeys;

    check(globalModel.getPushKeyById(1)).equals(pushKey1);
    check(globalModel.getPushKeyById(2)).equals(pushKey2);
    check(globalModel.getPushKeyById(3)).isNull();
  });

  test('perAccount, latestPushKey: keys exist', () {
    final time1 = 1772513819;
    final pushKey1 = eg.pushKey(account: eg.selfAccount,
      pushKeyId: 234, createdTimestamp: time1);
    final pushKey2 = eg.pushKey(account: eg.selfAccount,
      pushKeyId: 123, createdTimestamp: time1 + 300);
    final globalStore = eg.globalStore(accounts: [eg.selfAccount],
      pushKeys: [pushKey1, pushKey2]);
    final globalModel = globalStore.pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);

    // Gets the one with latest timestamp, not greatest ID.
    // (The IDs are random.)
    assert(pushKey1.pushKeyId > pushKey2.pushKeyId);
    check(model.latestPushKey).equals(pushKey2);
  });

  test('perAccount, latestPushKey: no keys', () {
    final globalStore = eg.globalStore(accounts: [eg.selfAccount],
      pushKeys: []);
    final globalModel = globalStore.pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);

    check(model.latestPushKey).isNull();
  });

  test('perAccount: repeated calls get same PushKeyStore', () {
    final globalStore = eg.globalStore(accounts: [eg.selfAccount]);
    final globalModel = globalStore.pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);
    check(globalModel.perAccount(eg.selfAccount.id)).identicalTo(model);
  });

  test('removeAccount, via global store', () async {
    final globalStore = eg.globalStore(
      accounts: [eg.selfAccount, eg.otherAccount],
      pushKeys: [
        eg.pushKey(account: eg.selfAccount, pushKeyId: 1),
        eg.pushKey(account: eg.otherAccount, pushKeyId: 2),
      ]);
    final globalModel = globalStore.pushKeys;
    final model1 = globalModel.perAccount(eg.selfAccount.id);
    final model2 = globalModel.perAccount(eg.otherAccount.id);
    check(globalModel.getPushKeyById(1)).isNotNull();
    check(model1.latestPushKey?.pushKeyId).equals(1);

    await globalStore.removeAccount(eg.selfAccount.id);

    // Push key on that account is gone.
    check(globalModel.getPushKeyById(1)).isNull();
    // So is the [PushKeyStore].  To demonstrate that, (artificially)
    // request a new one and note it's different from the old.
    final newModel = globalModel.perAccount(eg.selfAccount.id);
    check(newModel).not((it) => it.identicalTo(model1));
    // The new [PushKeyStore] also shows the push key is gone.
    check(newModel.latestPushKey).isNull();

    // The other account, meanwhile, is unaffected.
    check(globalModel.perAccount(eg.otherAccount.id)).identicalTo(model2);
    check(globalModel.getPushKeyById(2)).isNotNull();
    check(model2.latestPushKey?.pushKeyId).equals(2);
  });

  test('insertPushKey, removePushKey', () async {
    final globalModel = eg.globalStore(accounts: [eg.selfAccount]).pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);
    check(model.latestPushKey).isNull();

    final time1 = 1772513819;
    final pushKey1 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1);
    await model.insertPushKey(pushKey1.toCompanion(false));
    check(model.latestPushKey).equals(pushKey1);
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).equals(pushKey1);

    final pushKey2 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1 + 1);
    await model.insertPushKey(pushKey2.toCompanion(false));
    check(model.latestPushKey).equals(pushKey2);
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).equals(pushKey1);
    check(globalModel.getPushKeyById(pushKey2.pushKeyId)).equals(pushKey2);

    await model.removePushKey(pushKey1.pushKeyId);
    check(model.latestPushKey).equals(pushKey2);
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).isNull();
    check(globalModel.getPushKeyById(pushKey2.pushKeyId)).equals(pushKey2);

    await model.removePushKey(pushKey2.pushKeyId);
    check(model.latestPushKey).isNull();
    check(globalModel.getPushKeyById(pushKey2.pushKeyId)).isNull();
  });

  test('updatePushKey', () async {
    final globalModel = eg.globalStore(accounts: [eg.selfAccount]).pushKeys;
    final model = globalModel.perAccount(eg.selfAccount.id);

    final time1 = 1772513819;
    final pushKey1 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1);
    await model.insertPushKey(pushKey1.toCompanion(false));
    final pushKey2 = eg.pushKey(account: eg.selfAccount,
      createdTimestamp: time1 + 30);
    await model.insertPushKey(pushKey2.toCompanion(false));
    check(model.latestPushKey).equals(pushKey2);

    // Update one push key.
    final timeLater = 1772515410;
    await model.updatePushKey(pushKey2.pushKeyId, PushKeysCompanion(
      supersededTimestamp: drift.Value(timeLater)));
    // It's indeed updated.
    check(globalModel.getPushKeyById(pushKey2.pushKeyId))
      ..equals(pushKey2.copyWith(supersededTimestamp: drift.Value(timeLater)))
      ..identicalTo(model.latestPushKey);
    // The other push key is unaffected.
    check(globalModel.getPushKeyById(pushKey1.pushKeyId))
      ..equals(pushKey1)
      ..isNotNull().supersededTimestamp.isNull();
  });

  group('maybeRotatePushKeys', () {
    final thirtyDays = Duration(days: 30).inSeconds;

    late GlobalStore globalStore;
    late PerAccountStore store;

    /// Set up a store with the given push keys, triggering
    /// [PushDeviceManager._init] which calls [PushKeyStore.maybeRotatePushKeys].
    ///
    /// The [ackedPushKeyId] becomes [ClientDevice.pushKeyId] on this device
    /// in the initial snapshot, so that the rotation logic sees it as
    /// the server's acknowledged push key.
    ///
    /// Push keys passed here should be created with `eg.selfAccount`.
    void initStore(FakeAsync async, {
      List<PushKey>? pushKeys,
      int? ackedPushKeyId,
    }) {
      addTearDown(testBinding.reset);
      addTearDown(NotificationService.debugReset);
      PushDeviceManager.debugAutoPause = true;
      addTearDown(() => PushDeviceManager.debugAutoPause = false);
      globalStore = eg.globalStore(
        accounts: [eg.selfAccount],
        pushKeys: pushKeys ?? [],
      );
      store = eg.store(
        globalStore: globalStore,
        account: eg.selfAccount,
        initialSnapshot: eg.initialSnapshot(devices: {
          eg.selfAccount.deviceId!: eg.clientDevice(pushKeyId: ackedPushKeyId),
        }));
      async.flushMicrotasks();
    }

    PushKey mkKey(int createdTimestamp, {int? supersededTimestamp}) {
      return eg.pushKey(
        account: eg.selfAccount,
        createdTimestamp: createdTimestamp,
        supersededTimestamp: supersededTimestamp,
      );
    }

    PushKey? getPushKeyById(int id) => globalStore.pushKeys.getPushKeyById(id);

    group('generate new key', () {
      test('generates key when no keys exist', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        initStore(async);

        check(store.pushKeys.latestPushKey).isNotNull()
          .createdTimestamp.equals(now);
      }));

      test('generates key when latest is older than rotation interval', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - thirtyDays);
        initStore(async, pushKeys: [oldKey]);

        // A new key was generated…
        check(store.pushKeys.latestPushKey).isNotNull()
          .createdTimestamp.equals(now);
        // … distinct from the old key, which is still there.
        check(getPushKeyById(oldKey.pushKeyId)).isNotNull()
          ..equals(oldKey)
          ..createdTimestamp.equals(now - thirtyDays);
      }));

      test('no new key when latest is just under rotation interval', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        // Latest key is 30 days minus 1 second old.
        final key = mkKey(now - thirtyDays + 1);
        initStore(async, pushKeys: [key]);

        check(store.pushKeys.latestPushKey).equals(key);
      }));
    });

    group('mark superseded keys', () {
      test('marks older keys when server has acked push key', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final oldKey = mkKey(now - 200);
        final newKey = mkKey(now - 100);
        initStore(async,
          pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);

        // The old key is now superseded.
        check(getPushKeyById(oldKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.equals(now);
        // The new (acked) key is unaffected.
        check(getPushKeyById(newKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
      }));

      test('does not re-mark already-superseded keys', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final earlierSupersededTimestamp = now - 500;
        final oldKey = mkKey(now - 200,
          supersededTimestamp: earlierSupersededTimestamp);
        final newKey = mkKey(now - 100);
        initStore(async,
          pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);

        // The already-superseded key keeps its original timestamp.
        check(getPushKeyById(oldKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.equals(earlierSupersededTimestamp);
      }));

      test('no superseding when no acked push key', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final key1 = mkKey(now - 200);
        final key2 = mkKey(now - 100);
        initStore(async, pushKeys: [key1, key2]);

        check(getPushKeyById(key1.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
        check(getPushKeyById(key2.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
      }));
    });

    group('delete obsolete keys', () {
      test('deletes key superseded longer than retention duration', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        // A key superseded exactly 30 days ago.
        final obsoleteKey = mkKey(now - 10000,
          supersededTimestamp: now - thirtyDays);
        // A current key (so step 1 doesn't generate one).
        final currentKey = mkKey(now - 100);
        initStore(async, pushKeys: [obsoleteKey, currentKey]);

        check(getPushKeyById(obsoleteKey.pushKeyId)).isNull();
        check(getPushKeyById(currentKey.pushKeyId)).isA<PushKey>();
      }));

      test('does not delete key superseded less than retention duration', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        // A key superseded just under 30 days ago.
        final recentlySupersededKey = mkKey(now - 10000,
          supersededTimestamp: now - thirtyDays + 1);
        final currentKey = mkKey(now - 100);
        initStore(async, pushKeys: [recentlySupersededKey, currentKey]);

        check(getPushKeyById(recentlySupersededKey.pushKeyId))
          .isA<PushKey>();
      }));

      test('does not delete non-superseded keys', () => awaitFakeAsync((async) async {
        final now = testBinding.utcNow().millisecondsSinceEpoch ~/ 1000;
        final key = mkKey(now - 100);
        initStore(async, pushKeys: [key]);

        check(getPushKeyById(key.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
      }));
    });
  });
}
