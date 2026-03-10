import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:fake_async/fake_async.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/model/database.dart';
import 'package:zulip/model/push_device.dart';
import 'package:zulip/model/push_key.dart';
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
    check(model1.latestPushKey).isNotNull().pushKeyId.equals(1);

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
    check(model2.latestPushKey).isNotNull().pushKeyId.equals(2);
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
    check(globalModel.getPushKeyById(pushKey1.pushKeyId)).equals(pushKey1);
  });

  group('maybeRotatePushKeys', () {
    const secondsPerDay = 86400;
    final now = DateTime.utc(2026, 3, 8);
    final nowTimestamp = now.millisecondsSinceEpoch ~/ 1000;

    late GlobalStore globalStore;

    PushKey? getPushKeyById(int pushKeyId) =>
      globalStore.pushKeys.getPushKeyById(pushKeyId);

    PushKeyStore pushKeyModel() =>
      globalStore.pushKeys.perAccount(eg.selfAccount.id);

    /// Set up a per-account store with the given push keys and device state.
    ///
    /// On startup, the store calls [PushKeyStore.maybeRotatePushKeys]
    /// with [ackedPushKeyId] determined by the device's pushKeyId
    /// in the initial snapshot.
    PerAccountStore initStore(FakeAsync async, {
      List<PushKey> pushKeys = const [],
      int? ackedPushKeyId,
    }) {
      addTearDown(testBinding.reset);
      addTearDown(NotificationService.debugReset);
      PushDeviceManager.debugAutoPause = true;
      addTearDown(() => PushDeviceManager.debugAutoPause = false);
      globalStore = eg.globalStore(
        accounts: [eg.selfAccount], pushKeys: pushKeys);
      final store = eg.store(
        globalStore: globalStore,
        account: eg.selfAccount,
        initialSnapshot: eg.initialSnapshot(
          devices: {eg.selfAccount.deviceId!: ClientDevice(
            pushKeyId: ackedPushKeyId,
            pushTokenId: null,
            pendingPushTokenId: null,
            pushTokenLastUpdatedTimestamp: null,
            pushRegistrationErrorCode: null,
          )},
        ),
      );
      async.flushMicrotasks();
      return store;
    }

    PushKey mkKey(int createdTimestamp, {int? supersededTimestamp}) {
      return eg.pushKey(
        account: eg.selfAccount,
        createdTimestamp: createdTimestamp,
        supersededTimestamp: supersededTimestamp,
      );
    }

    group('generate new key', () {
      test('generate key when no keys exist',
          () => awaitFakeAsync(initialTime: now, (async) async {
        initStore(async);
        check(pushKeyModel().latestPushKey).isNotNull()
          ..createdTimestamp.equals(nowTimestamp)
          ..supersededTimestamp.isNull();
      }));

      test('generate key when latest is old enough',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final oldKey = mkKey(nowTimestamp - 30 * secondsPerDay);
        initStore(async, pushKeys: [oldKey]);
        final latest = pushKeyModel().latestPushKey;
        check(latest).isNotNull()
          ..createdTimestamp.equals(nowTimestamp)
          ..pushKeyId.not((it) => it.equals(oldKey.pushKeyId));
        check(getPushKeyById(oldKey.pushKeyId)).isNotNull();
      }));

      test('no new key when latest is recent',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final recentKey = mkKey(nowTimestamp - 30 * secondsPerDay + 1);
        initStore(async, pushKeys: [recentKey]);
        check(pushKeyModel().latestPushKey).equals(recentKey);
      }));
    });

    group('mark superseded', () {
      test('mark older keys on startup',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final oldKey = mkKey(nowTimestamp - 10 * secondsPerDay);
        final newKey = mkKey(nowTimestamp - 1 * secondsPerDay);
        initStore(async, pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);
        check(getPushKeyById(oldKey.pushKeyId)!)
          .supersededTimestamp.equals(nowTimestamp);
        check(getPushKeyById(newKey.pushKeyId)!)
          .supersededTimestamp.isNull();
      }));

      test('mark older keys on device update event',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final oldKey = mkKey(nowTimestamp - 10 * secondsPerDay);
        final newKey = mkKey(nowTimestamp - 1 * secondsPerDay);
        final store = initStore(async, pushKeys: [oldKey, newKey]);
        check(getPushKeyById(oldKey.pushKeyId)!)
          .supersededTimestamp.isNull();
        // A device-update event acks the new key.
        await store.handleEvent(DeviceUpdateEvent(
          id: 1,
          deviceId: eg.selfAccount.deviceId!,
          pushKeyId: JsonNullable(newKey.pushKeyId),
          pushTokenId: null,
          pendingPushTokenId: null,
          pushTokenLastUpdatedTimestamp: null,
          pushRegistrationErrorCode: null,
        ));
        async.flushMicrotasks();
        check(getPushKeyById(oldKey.pushKeyId)!)
          .supersededTimestamp.equals(nowTimestamp);
        check(getPushKeyById(newKey.pushKeyId)!)
          .supersededTimestamp.isNull();
      }));

      test('no re-mark already-superseded keys',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final supersededTime = nowTimestamp - 5 * secondsPerDay;
        final oldKey = mkKey(nowTimestamp - 20 * secondsPerDay,
          supersededTimestamp: supersededTime);
        final newKey = mkKey(nowTimestamp - 1 * secondsPerDay);
        initStore(async, pushKeys: [oldKey, newKey],
          ackedPushKeyId: newKey.pushKeyId);
        check(getPushKeyById(oldKey.pushKeyId)!)
          .supersededTimestamp.equals(supersededTime);
      }));

      test('no mark when no acked key',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final oldKey = mkKey(nowTimestamp - 10 * secondsPerDay);
        final newKey = mkKey(nowTimestamp - 1 * secondsPerDay);
        initStore(async, pushKeys: [oldKey, newKey]);
        check(getPushKeyById(oldKey.pushKeyId)!)
          .supersededTimestamp.isNull();
      }));
    });

    group('delete obsolete', () {
      test('delete keys superseded long enough ago',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final obsoleteKey = mkKey(nowTimestamp - 90 * secondsPerDay,
          supersededTimestamp: nowTimestamp - 30 * secondsPerDay);
        final currentKey = mkKey(nowTimestamp - 1 * secondsPerDay);
        initStore(async, pushKeys: [obsoleteKey, currentKey]);
        check(getPushKeyById(obsoleteKey.pushKeyId)).isNull();
        check(getPushKeyById(currentKey.pushKeyId)).isNotNull();
      }));

      test('no delete recently-superseded keys',
          () => awaitFakeAsync(initialTime: now, (async) async {
        final recentlySuperseded = mkKey(nowTimestamp - 60 * secondsPerDay,
          supersededTimestamp: nowTimestamp - 30 * secondsPerDay + 1);
        final currentKey = mkKey(nowTimestamp - 1 * secondsPerDay);
        initStore(async, pushKeys: [recentlySuperseded, currentKey]);
        check(getPushKeyById(recentlySuperseded.pushKeyId)).isNotNull();
      }));
    });
  });
}
