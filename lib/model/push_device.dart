import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:sodium_libs/sodium_libs.dart';

import '../api/model/events.dart';
import '../api/model/model.dart';
import '../api/route/account.dart';
import '../api/route/notifications.dart';
import '../log.dart';
import '../notifications/receive.dart';
import 'binding.dart';
import 'database.dart';
import 'store.dart';

/// Manages telling the server this device's push token,
/// and tracking the server's responses on the status of devices and push tokens.
// TODO(#1764) do that tracking of responses
class PushDeviceManager extends PerAccountStoreBase {
  PushDeviceManager({
    required super.core,
    required Map<int, ClientDevice> devices,
  }) : _devices = devices {
    _init();
  }

  void _init() async {
    await _maybeRotatePushKeys();
    _registerTokenAndSubscribe();
  }

  bool _disposed = false;

  /// Cleans up resources and tells the instance not to make new API requests.
  ///
  /// After this is called, the instance is not in a usable state
  /// and should be abandoned.
  void dispose() {
    assert(!_disposed);
    NotificationService.instance.token.removeListener(_registerToken);
    _disposed = true;
  }

  /// Like [InitialSnapshot.devices], but updated with events.
  ///
  /// For docs, search for "devices"
  /// in <https://zulip.com/api/register-queue>.
  ///
  /// An absent map in [InitialSnapshot] (from an old server) is treated
  /// as empty, since a server without this feature has none of these records.
  ///
  /// See also [thisDevice].
  // TODO(server-12) simplify doc re an absent map
  late Map<int, ClientDevice> devices = UnmodifiableMapView(_devices);
  final Map<int, ClientDevice> _devices;

  /// The client-device information the server currently reports for
  /// this very install of the app, if any.
  ///
  /// This is an entry in [devices].
  ClientDevice? get thisDevice => _devices[account.deviceId];

  PushRegistrationStatus pushRegistrationStatus() { // TODO(#323) warn user when status not OK
    // TODO(#1764) TODO(i18n)

    final currentToken = NotificationService.instance.token.value;
    if (currentToken == null) {
      return PushRegistrationStatus(.error,
        'Device does not support notifications');
    }

    if (connection.zulipFeatureLevel! < 789) { // TODO(#1764): update this
      return PushRegistrationStatus(.ok, 'old server');
    }

    final fromServer = thisDevice;
    if (fromServer == null) {
      return switch (_ageOfPushRegistrationAttempt()) {
        null =>                         PushRegistrationStatus(.pending,
            'Preparing to set up notifications…'),
        < const Duration(minutes: 5) => PushRegistrationStatus(.pending,
            'Contacting server to set up notifications…'),
        _ =>                            PushRegistrationStatus(.error,
            'Timed out contacting server to set up notifications'),
      };
    }

    final currentTokenId = NotificationService.computeTokenId(currentToken);
    if (fromServer.pushTokenId == currentTokenId) {
      return PushRegistrationStatus(.ok, 'success');
    }

    if (fromServer.pushRegistrationErrorCode != null) {
      return PushRegistrationStatus(.error,
        'Error from server: ${fromServer.pushRegistrationErrorCode}');
    }

    return switch (_ageOfPushRegistrationAttempt()) {
      // TODO this null case should be impossible
      null =>                         PushRegistrationStatus(.pending,
          'Preparing to set up notifications…'),
      < const Duration(minutes: 5) => PushRegistrationStatus(.pending,
          'Waiting for server to complete notification setup…'),
      _ =>                            PushRegistrationStatus(.error,
          'Timed out waiting for server to complete notification setup'),
    };
  }

  DateTime? _pushRegistrationAttemptTimestamp;

  Duration? _ageOfPushRegistrationAttempt() {
    final attemptTimestamp = _pushRegistrationAttemptTimestamp;
    if (attemptTimestamp == null) {
      // This condition should occur only briefly, before _registerToken
      // does its work (and before it even starts the request to the server).
      // TODO(#1764) detect if this situation persists
      return null;
    }
    return ZulipBinding.instance.utcNow().difference(attemptTimestamp);
  }

  void handleDeviceEvent(DeviceEvent event) {
    switch (event) {
      case DeviceAddEvent():
        _devices[event.deviceId] = ClientDevice(
          pushKeyId: null,
          pushTokenId: null,
          pushTokenLastUpdatedTimestamp: null,
          pendingPushTokenId: null,
          pushRegistrationErrorCode: null,
        );

      case DeviceUpdateEvent():
        final device = _devices[event.deviceId];
        if (device == null) return; // TODO(log)

        if (event.pushKeyId case final v?) {
          device.pushKeyId = v.value;
          _maybeRotatePushKeys();
        }
        if (event.pushTokenId case final v?) {
          device.pushTokenId = v.value;
        }
        if (event.pushTokenLastUpdatedTimestamp case final v?) {
          device.pushTokenLastUpdatedTimestamp = v.value;
        }
        if (event.pendingPushTokenId case final v?) {
          device.pendingPushTokenId = v.value;
        }
        if (event.pushRegistrationErrorCode case final v?) {
          device.pushRegistrationErrorCode = v.value;
        }

      case DeviceRemoveEvent():
        _devices.remove(event.deviceId);
    }
  }

  /// See if it's time to perform any of the steps of rotating push keys,
  /// and do those.
  Future<void> _maybeRotatePushKeys() async {
    final pushKeys = getPushKeys()..toList();
    final now = ZulipBinding.instance.utcNow();
    final nowTimestamp = now.millisecondsSinceEpoch ~/ 1000;

    // For a given rotation of the keys, each of these steps will happen
    // in a separate call to this function.

    // Step 1: Generate a new key.
    final latestPushKey = maxBy(pushKeys, (k) => k.createdTimestamp);
    if (latestPushKey == null
        || now.difference(dateTimeFromTimestamp(latestPushKey.createdTimestamp))
           >= _keyRotationInterval) {
      // We either have no push key yet for this account,
      // or it's time to rotate the push key.  Make a new one.
      await insertPushKey(PushKeysCompanion.insert(
        pushKeyId: generatePushKeyId(),
        pushKey: generatePushKey(),
        accountId: accountId,
        createdTimestamp: nowTimestamp,
      ));
    }

    // Step 2: Send new key to the server.
    // This is done separately, in [_registerToken] below.

    // Step 3: Mark superseded keys as superseded.
    // A key is superseded when the server acks a newer key.
    // (The ack might come in either an event or a later initial snapshot,
    // which is why we handle it here.)
    final ackedKey = pushKeys.where((k) => k.pushKeyId == thisDevice?.pushKeyId)
      .singleOrNull;
    if (ackedKey != null) {
      for (final oldKey in pushKeys.where((k) =>
             k.createdTimestamp < ackedKey.createdTimestamp
             && k.supersededTimestamp == null)) {
        await updatePushKey(oldKey.pushKeyId, PushKeysCompanion(
          supersededTimestamp: drift.Value(nowTimestamp)));
      }
    }

    // Step 4: Delete obsolete keys: those superseded far enough in the past.
    for (final obsoleteKey in getPushKeys().where((k) =>
           k.supersededTimestamp != null
           && now.difference(dateTimeFromTimestamp(k.supersededTimestamp!))
              >= _oldKeyRetentionDuration)) {
      await removePushKey(obsoleteKey.pushKeyId);
    }
  }

  /// The age at which a push key should be replaced with a new one.
  ///
  /// Rotating the push key allows both the client and the server to
  /// eventually delete the old key (though see [_oldKeyRetentionDuration]),
  /// which is helpful in case of a later compromise of either client or server.
  static const _keyRotationInterval = Duration(days: 30);

  /// The length of time we want to retain a superseded push key.
  ///
  /// After a push key is superseded by a new key, there might still be
  /// notifications in flight that the server sent with the old key.
  ///
  /// We keep the old key around as long as it might still be possible
  /// for some such notifications to be delivered.
  //
  // FCM may store a notification-message up to 28 days while it retries
  // delivering it to the device:
  //   https://firebase.google.com/docs/cloud-messaging/customize-messages/setting-message-lifespan
  //
  // APNs may do so for up to 30 days:
  //   https://developer.apple.com/documentation/usernotifications/viewing-the-status-of-push-notifications-using-metrics-and-apns#Interpret-data-about-stored-notifications
  static const _oldKeyRetentionDuration = Duration(days: 30);

  /// Send this client's notification token to the server, now and if it changes.
  // TODO it would be nice to register the token before even registerQueue:
  //   https://github.com/zulip/zulip-flutter/pull/325#discussion_r1365982807
  void _registerTokenAndSubscribe() async {
    _debugMaybePause();
    if (_debugRegisterTokenProceed != null) {
      await _debugRegisterTokenProceed!.future;
    }

    if (debugEnableRegisterClientDevice
        && account.deviceId == null
        && zulipFeatureLevel >= 789) { // TODO(server-12)
      final result = await registerClientDevice(connection);
      await updateAccount(AccountsCompanion(
        deviceId: drift.Value(result.deviceId),
      ));
      assert(account.deviceId != null);
    }

    NotificationService.instance.token.addListener(_registerToken);
    await _registerToken();

    _debugRegisterTokenCompleted?.complete();
  }

  /// In debug mode, controls whether this class should make
  /// a [registerClientDevice] request when otherwise appropriate.
  ///
  /// Outside of debug mode, this is always true and the setter has no effect.
  static bool get debugEnableRegisterClientDevice {
    bool result = true;
    assert(() {
      result = _debugEnableRegisterClientDevice;
      return true;
    }());
    return result;
  }
  static bool _debugEnableRegisterClientDevice = true;
  static set debugEnableRegisterClientDevice(bool value) {
    assert(() {
      _debugEnableRegisterClientDevice = value;
      return true;
    }());
  }

  Completer<void>? _debugRegisterTokenProceed;
  Completer<void>? _debugRegisterTokenCompleted;

  void _debugMaybePause() {
    assert(() {
      if (debugAutoPause) {
        _debugRegisterTokenProceed = Completer();
        _debugRegisterTokenCompleted = Completer();
      }
      return true;
    }());
  }

  /// Unpause registering the token (after [debugAutoPause]),
  /// returning a future that completes when any immediate request is completed.
  ///
  /// This has no effect if [debugAutoPause] was false
  /// when this instance was constructed,
  /// and therefore no effect outside of debug mode.
  Future<void> debugUnpauseRegisterToken() async {
    await Future<void>.delayed(Duration.zero); // TODO hack to get past _maybeRotateKeys
    _debugRegisterTokenProceed!.complete();
    await _debugRegisterTokenCompleted!.future;
  }

  /// In debug mode, controls whether new instances should pause
  /// before registering the token with the server.
  ///
  /// When paused, token registration can be unpaused
  /// with [debugUnpauseRegisterToken].
  ///
  /// Outside of debug mode, this is always false and the setter has no effect.
  static bool get debugAutoPause {
    bool result = false;
    assert(() {
      result = _debugAutoPause;
      return true;
    }());
    return result;
  }
  static bool _debugAutoPause = false;
  static set debugAutoPause(bool value) {
    assert(() {
      _debugAutoPause = value;
      return true;
    }());
  }

  Future<void> _registerToken() async {
    if (connection.zulipFeatureLevel! < 789) { // TODO(#1764): update this
      return _legacyRegisterToken();
    }

    assert(account.deviceId != null);

    final token = NotificationService.instance.token.value;
    if (token == null) {
      // Nothing to register.
      // (We'll show the user a warning; see [pushRegistrationStatus].)
      return;
    }

    final now = ZulipBinding.instance.utcNow();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;

    // A push key should already exist, thanks to _maybeRotatePushKeys.
    final latestPushKey = maxBy(getPushKeys(), (k) => k.createdTimestamp)!;

    final tokenId = NotificationService.computeTokenId(token);

    final fromServer = thisDevice;

    RegisterPushDeviceKey? keyArgs;
    if (fromServer == null
        || fromServer.pushKeyId != latestPushKey.pushKeyId) {
      keyArgs = RegisterPushDeviceKey(pushKeyId: latestPushKey.pushKeyId,
        pushKey: base64Encode(latestPushKey.pushKey));
    }

    RegisterPushDeviceToken? tokenArgs;
    if (fromServer == null
        || (fromServer.pendingPushTokenId ?? fromServer.pushTokenId)
           != tokenId
        // This case should be impossible: if pendingPushTokenId or pushTokenId
        // is non-null, then so should the timestamp be.
        || fromServer.pushTokenLastUpdatedTimestamp == null
        || now.difference(dateTimeFromTimestamp(
             fromServer.pushTokenLastUpdatedTimestamp!))
           >= _tokenRepeatInterval) {
      final tokenKind = switch (defaultTargetPlatform) {
        TargetPlatform.android => PushTokenKind.fcm,
        TargetPlatform.iOS => PushTokenKind.apns,
        _ => throw StateError('unexpected platform: $defaultTargetPlatform'),
      };

      final pushRegistration = PushRegistration(
        tokenKind: tokenKind, token: token,
        timestamp: timestamp);
      final encryptedPushRegistration = await _encryptToBouncer(
        _bouncerPublicKey, jsonEncode(pushRegistration));

      tokenArgs = RegisterPushDeviceToken(
        tokenKind: tokenKind,
        tokenId: tokenId,
        bouncerPublicKey: base64Encode(_bouncerPublicKey), // TODO(#1764) confirm base64 intended; https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/e2ee.20notifs.3A.20bouncer.20public.20key/near/2352465
        encryptedPushRegistration: base64Encode(encryptedPushRegistration),
      );
    }

    if (keyArgs == null && tokenArgs == null) {
      // The server is already up to date with our data.
      return;
    }

    _pushRegistrationAttemptTimestamp = now;
    try {
      await registerPushDevice(connection,
        deviceId: account.deviceId!, key: keyArgs, token: tokenArgs);
      assert(debugLog('registerPushDevice: success'));
    } finally {
      // await updateAccount(AccountsCompanion(
      //   pushRegistrationResult: drift.Value('"completed"'), // TODO(#1764) more detail
      // ));
    }
    // TODO(#1764) handle errors
  }

  /// The interval at which the client should repeat telling the server
  /// its push token.
  ///
  /// This repetition is recommended in the FCM docs to do once a month:
  ///   https://firebase.google.com/docs/cloud-messaging/manage-tokens#ensuring-registration-token-freshness
  static const _tokenRepeatInterval = Duration(days: 30);

  static final _bouncerPublicKey = utf8.encode('nonsense-bouncer-key-asdf-qwer-z'); // TODO(#1764) fill in

  static Future<Uint8List> _encryptToBouncer(Uint8List publicKey, String plaintext) async {
    // ?? WidgetsFlutterBinding.ensureInitialized();  // TODO(#1764)
    final sodium = await SodiumInit.init();
    return sodium.crypto.box.seal(publicKey: publicKey,
      message: utf8.encode(plaintext));
  }

  Future<void> _legacyRegisterToken() async {
    final token = NotificationService.instance.token.value;
    if (token == null) return;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        await addFcmToken(connection, token: token);

      case TargetPlatform.iOS:
        final packageInfo = await ZulipBinding.instance.packageInfo;
        await addApnsToken(connection,
          token: token,
          appid: packageInfo!.packageName);

      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        assert(false);
    }
  }

  static Future<Uint8List> decryptNotification(Uint8List pushKey, Uint8List cryptotext) async {
    // TODO(#1764) document this; https://chat.zulip.org/#narrow/channel/378-api-design/topic/E2EE.20-.20cryptography/near/2352462
    const nonceLength = 24;
    final nonce = Uint8List.sublistView(cryptotext, 0, nonceLength);
    final actualCryptotext = Uint8List.sublistView(cryptotext, nonceLength);

    // ?? WidgetsFlutterBinding.ensureInitialized();  // TODO(#1764)
    final sodium = await SodiumInit.init();
    final key = SecureKey.fromList(sodium, pushKey);
    return sodium.crypto.secretBox.openEasy(key: key,
      cipherText: actualCryptotext, nonce: nonce);
  }

  /// Generate a suitable value to pass as `pushKeyId` to [registerPushDevice].
  static int generatePushKeyId() {
    final rand = Random.secure();
    return rand.nextInt(1 << 32);
  }

  /// Generate a suitable value to pass as `pushKey` to [registerPushDevice].
  ///
  /// See docs and ZAP 2:
  /// https://zulip.com/api/register-push-device#parameter-push_key
  /// https://github.com/zulip/zulip-architecture/blob/main/zaps/0002-encrypt-push-notifications.md#cryptographic-choices
  /// TODO doc this on [Account.pushKey] instead
  static Uint8List generatePushKey() {
    final rand = Random.secure();
    return Uint8List.fromList([
      pushKeyTagSecretbox,
      ...Iterable.generate(32, (_) => rand.nextInt(1 << 8)),
    ]);
  }

  /// The tag byte for a libsodium secretbox-based `pushKey` value.
  ///
  /// See API doc: https://zulip.com/api/register-push-device#parameter-push_key
  static const pushKeyTagSecretbox = 0x31;
}

class PushRegistrationStatus {
  PushRegistrationStatus(this.code, this.message);

  final PushRegistrationStatusCode code;
  final String message;

  @override
  String toString() {
    return 'PushRegistrationStatus(${code.name}, $message)';
  }
}

enum PushRegistrationStatusCode {
  ok,
  pending,
  error;
}
