import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
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
    // A base time to use as "now" in these tests, as a Unix timestamp
    // in seconds.
    final baseTimestamp = 1772513819;
    final baseTime = DateTime.fromMillisecondsSinceEpoch(
      baseTimestamp * 1000, isUtc: true);

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
    void prepareStoreForRotation({
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
        initialSnapshot: eg.initialSnapshot(
          devices: {eg.selfAccount.deviceId!: ClientDevice(
            pushKeyId: ackedPushKeyId,
            pushTokenId: null,
            pendingPushTokenId: null,
            pushTokenLastUpdatedTimestamp: null,
            pushRegistrationErrorCode: null,
          )}));
    }

    PushKey? getPushKeyById(int id) => globalStore.pushKeys.getPushKeyById(id);

    group('generate new key', () {
      test('generates key when no keys exist',
          () => awaitFakeAsync((async) async {
        prepareStoreForRotation();
        async.flushMicrotasks();

        check(store.pushKeys.latestPushKey).isNotNull()
          ..createdTimestamp.equals(baseTimestamp)
          ..pushKey.isNotNull().length.equals(33);
      }, initialTime: baseTime));

      test('generates key when latest is older than rotation interval',
          () => awaitFakeAsync((async) async {
        final oldKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 100, createdTimestamp: baseTimestamp - thirtyDays);
        prepareStoreForRotation(pushKeys: [oldKey]);
        async.flushMicrotasks();

        // A new key was generated, distinct from the old one.
        check(store.pushKeys.latestPushKey).isNotNull()
          ..pushKeyId.not((it) => it.equals(100))
          ..createdTimestamp.equals(baseTimestamp);
        // The old key is still there.
        check(getPushKeyById(100)).isA<PushKey>();
      }, initialTime: baseTime));

      test('no new key when latest is fresh',
          () => awaitFakeAsync((async) async {
        // The latest key is only 1 day old — well within the 30-day interval.
        final recentKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 200,
          createdTimestamp: baseTimestamp - Duration(days: 1).inSeconds);
        prepareStoreForRotation(pushKeys: [recentKey]);
        async.flushMicrotasks();

        // Still the same single key; no new one generated.
        check(store.pushKeys.latestPushKey).isNotNull()
          .pushKeyId.equals(200);
      }, initialTime: baseTime));

      test('no new key when latest is just under rotation interval',
          () => awaitFakeAsync((async) async {
        // Latest key is 30 days minus 1 second old.
        final key = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 300,
          createdTimestamp: baseTimestamp - thirtyDays + 1);
        prepareStoreForRotation(pushKeys: [key]);
        async.flushMicrotasks();

        check(store.pushKeys.latestPushKey).isNotNull()
          .pushKeyId.equals(300);
      }, initialTime: baseTime));
    });

    group('mark superseded keys', () {
      test('marks older keys when server has acked push key',
          () => awaitFakeAsync((async) async {
        final oldKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 200);
        final newKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 20, createdTimestamp: baseTimestamp - 100);
        prepareStoreForRotation(
          pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);
        async.flushMicrotasks();

        // The old key is now superseded.
        check(getPushKeyById(oldKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.equals(baseTimestamp);
        // The new (acked) key is unaffected.
        check(getPushKeyById(newKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
      }, initialTime: baseTime));

      test('does not re-mark already-superseded keys',
          () => awaitFakeAsync((async) async {
        final earlierSupersededTimestamp = baseTimestamp - 500;
        final oldKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 200)
          .copyWith(
            supersededTimestamp: drift.Value(earlierSupersededTimestamp));
        final newKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 20, createdTimestamp: baseTimestamp - 100);
        prepareStoreForRotation(
          pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);
        async.flushMicrotasks();

        // The already-superseded key keeps its original timestamp.
        check(getPushKeyById(oldKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.equals(earlierSupersededTimestamp);
      }, initialTime: baseTime));

      test('no superseding when no acked push key',
          () => awaitFakeAsync((async) async {
        final key1 = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 200);
        final key2 = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 20, createdTimestamp: baseTimestamp - 100);
        prepareStoreForRotation(pushKeys: [key1, key2]);
        async.flushMicrotasks();

        check(getPushKeyById(key1.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
        check(getPushKeyById(key2.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
      }, initialTime: baseTime));
    });

    group('delete obsolete keys', () {
      test('deletes key superseded longer than retention duration',
          () => awaitFakeAsync((async) async {
        // A key superseded exactly 30 days ago.
        final obsoleteKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 10000)
          .copyWith(
            supersededTimestamp: drift.Value(baseTimestamp - thirtyDays));
        // A current key (so step 1 doesn't generate one).
        final currentKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 20, createdTimestamp: baseTimestamp - 100);
        prepareStoreForRotation(pushKeys: [obsoleteKey, currentKey]);
        async.flushMicrotasks();

        check(getPushKeyById(obsoleteKey.pushKeyId)).isNull();
        check(getPushKeyById(currentKey.pushKeyId)).isA<PushKey>();
      }, initialTime: baseTime));

      test('does not delete key superseded less than retention duration',
          () => awaitFakeAsync((async) async {
        // A key superseded just under 30 days ago.
        final recentlySupersededKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 10000)
          .copyWith(
            supersededTimestamp: drift.Value(baseTimestamp - thirtyDays + 1));
        final currentKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 20, createdTimestamp: baseTimestamp - 100);
        prepareStoreForRotation(
          pushKeys: [recentlySupersededKey, currentKey]);
        async.flushMicrotasks();

        check(getPushKeyById(recentlySupersededKey.pushKeyId))
          .isA<PushKey>();
      }, initialTime: baseTime));

      test('does not delete non-superseded keys',
          () => awaitFakeAsync((async) async {
        final key = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 100);
        prepareStoreForRotation(pushKeys: [key]);
        async.flushMicrotasks();

        check(getPushKeyById(key.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();
      }, initialTime: baseTime));
    });

    test('all steps together: generate, supersede, delete',
        () => awaitFakeAsync((async) async {
      // Set up three keys, all old enough that a new key is generated:
      // - obsoleteKey: superseded long ago — should be deleted
      // - supersedableKey: not yet superseded, older than ackedKey — should
      //     be marked superseded
      // - ackedKey: the one the server acked — triggers superseding
      final obsoleteKey = eg.pushKey(account: eg.selfAccount,
        pushKeyId: 1, createdTimestamp: baseTimestamp - 3 * thirtyDays)
        .copyWith(supersededTimestamp: drift.Value(baseTimestamp - thirtyDays));
      final supersedableKey = eg.pushKey(account: eg.selfAccount,
        pushKeyId: 2, createdTimestamp: baseTimestamp - 2 * thirtyDays);
      final ackedKey = eg.pushKey(account: eg.selfAccount,
        pushKeyId: 3, createdTimestamp: baseTimestamp - thirtyDays);
      prepareStoreForRotation(
        pushKeys: [obsoleteKey, supersedableKey, ackedKey],
        ackedPushKeyId: ackedKey.pushKeyId);
      async.flushMicrotasks();

      // A new key was generated (all existing keys are >= 30 days old).
      check(store.pushKeys.latestPushKey).isNotNull()
        .createdTimestamp.equals(baseTimestamp);

      // supersedableKey was marked superseded.
      check(getPushKeyById(supersedableKey.pushKeyId))
        .isA<PushKey>().supersededTimestamp.equals(baseTimestamp);

      // obsoleteKey was deleted.
      check(getPushKeyById(obsoleteKey.pushKeyId)).isNull();

      // The acked key itself is not superseded.
      check(getPushKeyById(ackedKey.pushKeyId)).isA<PushKey>()
        .supersededTimestamp.isNull();
    }, initialTime: baseTime));
  });
}
