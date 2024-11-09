import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zulip/notifications/receive.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../fake_async.dart';
import '../model/binding.dart';
import '../stdlib_checks.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  void init() async {
    addTearDown(testBinding.reset);
    testBinding.firebaseMessagingInitialToken = '012abc';
    addTearDown(NotificationService.debugReset);
    NotificationService.debugBackgroundIsolateIsLive = false;
    NotificationService.instance.start();
  }

  // The calls to firebaseMessagingOnMessage and firebaseMessagingOnBackgroundMessage
  // are tested end-to-end in `display_test.dart`, by posting FCM messages
  // to the respective streams and checking that the right logic then runs.

  group('permissions', () {
    testWidgets('request permission', (tester) async {
      init();
      await tester.pump(Duration.zero);
      check(testBinding.firebaseMessaging.takeRequestPermissionCalls())
        .length.equals(1);
    }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
  });

  group('NotificationTokenRegistrant', () {
    late FakeApiConnection connection;

    void prepare() {
      connection = FakeApiConnection.fromAccount(eg.selfAccount);
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
      // learned the token before the registrant is created.
      // (This is probably the common case.)
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      addTearDown(NotificationService.debugReset);
      NotificationService.instance.start();
      async.flushTimers(); // let NotificationService.start finish work

      // On startup, send the token.
      prepare();
      connection.prepare(json: {});
      NotificationTokenRegistrant(connection: connection).start();
      async.flushMicrotasks();
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
      // This tests the case where the registrant is created while our
      // request for the token is still pending.
      addTearDown(testBinding.reset);
      testBinding.firebaseMessagingInitialToken = '012abc';
      addTearDown(NotificationService.debugReset);
      NotificationService.instance.start();

      // TODO this test is a bit brittle in its interaction with asynchrony;
      //   to fix, probably extend TestZulipBinding to control when getToken finishes.
      //
      // The aim here is to first wait for `start()`
      // to complete whatever it's going to do; then check no request was made;
      // and only after that wait for `NotificationService.start` to finish,
      // including its `getToken` call.

      // On startup, send nothing (because we have nothing to send).
      prepare();
      NotificationTokenRegistrant(connection: connection).start();
      check(connection.lastRequest).isNull();

      // When the token later appears, send it.
      connection.prepare(json: {});
      async.flushTimers(); // let NotificationService.start finish work
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
  });
}

void testAndroidIos(String description, FutureOr<void> Function() body) {
  test('$description (Android)', body);
  test('$description (iOS)', () async {
    final origTargetPlatform = debugDefaultTargetPlatformOverride;
    addTearDown(() => debugDefaultTargetPlatformOverride = origTargetPlatform);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await body();
  });
}
