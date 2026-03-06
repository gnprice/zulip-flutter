import 'package:checks/checks.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:test/scaffolding.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/account.dart';
import 'package:zulip/model/push_device.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import 'binding.dart';
import 'store_checks.dart';
import 'store_test.dart';
import '../stdlib_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late PushDeviceManager model;
  late FakeApiConnection connection;

  void prepareStore({int? zulipFeatureLevel}) {
    addTearDown(testBinding.reset);
    addTearDown(NotificationService.debugReset);
    PushDeviceManager.debugAutoPause = true;
    addTearDown(() => PushDeviceManager.debugAutoPause = false);
    store = eg.store(
      account: eg.account(user: eg.selfUser, zulipFeatureLevel: zulipFeatureLevel),
      initialSnapshot: eg.initialSnapshot(zulipFeatureLevel: zulipFeatureLevel));
    model = store.pushDevices;
    connection = store.connection as FakeApiConnection;
  }

  group('register device', () {
    test('registers', () => awaitFakeAsync((async) async {
      prepareStore();
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(null)));
      check(store.account.deviceId).isNull();

      connection.prepare(json: RegisterClientDeviceResult(deviceId: 123).toJson());
      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).equals(123);
    }));

    test('no register when already done', () => awaitFakeAsync((async) async {
      prepareStore();
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(123)));

      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).equals(123);
    }));

    test('no register when server old', () => awaitFakeAsync((async) async {
      prepareStore(zulipFeatureLevel: 468 - 1);
      await store.updateAccount(AccountsCompanion(deviceId: drift.Value(null)));

      await model.debugUnpauseRegisterToken();
      check(store.account.deviceId).isNull();
    }));
  });

  group('register token', () {
    group('legacy', () {
      void prepareStoreLegacy() {
        prepareStore(zulipFeatureLevel: 468 - 1);
      }

      void checkLastRequestApns({required String token, required String appid}) {
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/users/me/apns_device_token')
          ..bodyFields.deepEquals({'token': token, 'appid': appid});
      }

      void checkLastRequestFcm({required String token}) {
        check(connection.takeRequests()).single.isA<http.Request>()
          ..method.equals('POST')
          ..url.path.equals('/api/v1/users/me/android_gcm_reg_id')
          ..bodyFields.deepEquals({'token': token});
      }

      testAndroidIos('token already known', () => awaitFakeAsync((async) async {
        // This tests the case where [NotificationService.start] has already
        // learned the token before the store is created.
        // (This is probably the common case.)
        testBinding.firebaseMessagingInitialToken = '012abc';
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
        await NotificationService.instance.start();

        // On store startup, send the token.
        prepareStoreLegacy();
        connection.prepare(json: {});
        await model.debugUnpauseRegisterToken();
        if (defaultTargetPlatform == TargetPlatform.android) {
          checkLastRequestFcm(token: '012abc');
        } else {
          checkLastRequestApns(token: '012abc', appid: 'com.zulip.flutter');
        }

        if (defaultTargetPlatform == TargetPlatform.android) {
          // If the token changes, send it again.
          testBinding.firebaseMessaging.setToken('456def');
          connection.prepare(json: {});
          async.flushMicrotasks();
          checkLastRequestFcm(token: '456def');
        }
      }));

      testAndroidIos('token initially unknown', () => awaitFakeAsync((async) async {
        // This tests the case where the store is created while our
        // request for the token is still pending.
        testBinding.firebaseMessagingInitialToken = '012abc';
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.zulip.flutter');
        final startFuture = Future<void>.delayed(Duration(milliseconds: 100))
          .then((_) => NotificationService.instance.start());

        // TODO this test is a bit brittle in its interaction with asynchrony;
        //   to fix, probably extend TestZulipBinding to control when getToken finishes.
        //
        // The aim here is to first wait for `model.debugUnpauseRegisterToken`
        // to complete whatever it's going to do; then check no request was made;
        // and only after that wait for `NotificationService.start` to finish,
        // including its `getToken` call.

        // On store startup, send nothing (because we have nothing to send).
        prepareStoreLegacy();
        await model.debugUnpauseRegisterToken();
        check(connection.lastRequest).isNull();

        // When the token later appears, send it.
        connection.prepare(json: {});
        await startFuture;
        async.flushMicrotasks();
        if (defaultTargetPlatform == TargetPlatform.android) {
          checkLastRequestFcm(token: '012abc');
        } else {
          checkLastRequestApns(token: '012abc', appid: 'com.zulip.flutter');
        }

        if (defaultTargetPlatform == TargetPlatform.android) {
          // If the token subsequently changes, send it again.
          testBinding.firebaseMessaging.setToken('456def');
          connection.prepare(json: {});
          async.flushMicrotasks();
          checkLastRequestFcm(token: '456def');
        }
      }));

      test('on iOS, use provided app ID from packageInfo', () => awaitFakeAsync((async) async {
        final origTargetPlatform = debugDefaultTargetPlatformOverride;
        addTearDown(() => debugDefaultTargetPlatformOverride = origTargetPlatform);
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        testBinding.firebaseMessagingInitialToken = '012abc';
        testBinding.packageInfoResult = eg.packageInfo(packageName: 'com.example.test');
        await NotificationService.instance.start();

        prepareStoreLegacy();
        connection.prepare(json: {});
        await model.debugUnpauseRegisterToken();
        checkLastRequestApns(token: '012abc', appid: 'com.example.test');
      }));

      test('set possibleLegacyPushToken', () => awaitFakeAsync((async) async {
        testBinding.firebaseMessagingInitialToken = '012abc';
        await NotificationService.instance.start();

        prepareStoreLegacy();
        check(store.account).possibleLegacyPushToken.isFalse();

        // Start registering the token.  Make the request take a while.
        connection.prepare(json: {}, delay: Duration(seconds: 1));
        final future = model.debugUnpauseRegisterToken();
        await Future<void>.delayed(Duration.zero);

        // The possibleLegacyPushToken flag is now true,
        // even before the register request completes.
        check(store.account).possibleLegacyPushToken.isTrue();

        await Future<void>.delayed(Duration(seconds: 1));
        await future;
        checkLastRequestFcm(token: '012abc');
      }));
    });
  });

  group('push key rotation', () {
    // A base time to use as "now" in these tests, as a Unix timestamp
    // in seconds.
    final baseTimestamp = 1772513819;
    final baseTime = DateTime.fromMillisecondsSinceEpoch(
      baseTimestamp * 1000, isUtc: true);

    final thirtyDays = Duration(days: 30).inSeconds;

    late GlobalStore globalStore;

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
      model = store.pushDevices;
      connection = store.connection as FakeApiConnection;
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
      test('marks older keys when initial snapshot has acked push key',
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

      test('marks older keys when device event acks a push key',
          () => awaitFakeAsync((async) async {
        final oldKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 10, createdTimestamp: baseTimestamp - 200);
        final newKey = eg.pushKey(account: eg.selfAccount,
          pushKeyId: 20, createdTimestamp: baseTimestamp - 100);
        // Initially no acked push key.
        prepareStoreForRotation(pushKeys: [oldKey, newKey]);
        async.flushMicrotasks();
        // No superseding yet.
        check(getPushKeyById(oldKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.isNull();

        // A device-update event acks the new key.
        await store.handleEvent(DeviceUpdateEvent(
          id: 1,
          deviceId: store.account.deviceId!,
          pushKeyId: JsonNullable(newKey.pushKeyId),
          pushTokenId: null,
          pendingPushTokenId: null,
          pushTokenLastUpdatedTimestamp: null,
          pushRegistrationErrorCode: null,
        ));
        async.flushMicrotasks();

        check(getPushKeyById(oldKey.pushKeyId)).isA<PushKey>()
          .supersededTimestamp.equals(baseTimestamp);
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
