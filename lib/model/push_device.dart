import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:sodium_libs/sodium_libs.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/notifications.dart';
import '../log.dart';
import '../notifications/receive.dart';
import 'binding.dart';
import 'store.dart';

/// Manages telling the server this device's push token,
/// and tracking the server's responses on the status of push devices.
// TODO(#1764) do that tracking of responses
class PushDeviceManager extends PerAccountStoreBase {
  PushDeviceManager({
    required super.core,
    required Map<int, PushDeviceEntry> pushDevices,
  }) : _pushDevices = pushDevices {
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

  /// Like [InitialSnapshot.pushDevices], but updated with events.
  ///
  /// For docs, search for "push_device"
  /// in <https://zulip.com/api/register-queue>.
  ///
  /// An absent map in [InitialSnapshot] (from an old server) is treated
  /// as empty, since a server without this feature has none of these records.
  ///
  /// See also [thisDevice].
  // TODO(server-11) simplify doc re an absent map
  late Map<int, PushDeviceEntry> pushDevices = UnmodifiableMapView(_pushDevices);
  final Map<int, PushDeviceEntry> _pushDevices;

  /// The push-device registration status the server currently reports for
  /// this very install of the app, if any.
  ///
  /// This is an entry in [pushDevices].
  PushDeviceEntry? get thisDevice => _pushDevices[account.pushAccountId];

  PushRegistrationStatus pushRegistrationStatus() { // TODO(#323) warn user when status not OK
    // TODO(#1764) TODO(i18n)

    if (connection.zulipFeatureLevel! < 421) { // TODO(#1764): update this
      return PushRegistrationStatus(.ok, 'old server');
    }

    final fromServer = thisDevice;
    switch (fromServer?.status) {
      case PushDeviceStatus.active:
        return PushRegistrationStatus(.ok,
          'Notifications set up successfully');

      case PushDeviceStatus.failed:
        return PushRegistrationStatus(.error,
          fromServer!.errorCode ?? 'Error'); // TODO(#1764) interpret known error codes

      case PushDeviceStatus.pending:
        return switch (_ageOfPushRegistrationAttempt()) {
          null =>                         PushRegistrationStatus(.pending,
              'Preparing to set up notifications…'),
          < const Duration(minutes: 5) => PushRegistrationStatus(.pending,
              'Waiting for server to complete notification setup…'),
          _ =>                            PushRegistrationStatus(.error,
              'Timed out waiting for server to complete notification setup'),
        };

      case null:
        return switch (_ageOfPushRegistrationAttempt()) {
          null =>                         PushRegistrationStatus(.pending,
              'Preparing to set up notifications…'),
          < const Duration(minutes: 5) => PushRegistrationStatus(.pending,
              'Contacting server to set up notifications…'),
          _ =>                            PushRegistrationStatus(.error,
              'Timed out contacting server to set up notifications'),
        };
    }
  }

  Duration? _ageOfPushRegistrationAttempt() {
    final attemptTimestamp = account.pushRegistrationTimestamp;
    if (attemptTimestamp == null) {
      // This condition should occur only briefly, before _registerToken
      // does its work (and before it even starts the request to the server).
      // TODO(#1764) detect if this situation persists
      return null;
    }
    return ZulipBinding.instance.utcNow().difference(
      DateTime.fromMillisecondsSinceEpoch(attemptTimestamp * 1000));
  }

  void handlePushDeviceEvent(PushDeviceEvent event) {
    _pushDevices[event.pushAccountId] = event.data;
  }

  /// Send this client's notification token to the server, now and if it changes.
  // TODO it would be nice to register the token before even registerQueue:
  //   https://github.com/zulip/zulip-flutter/pull/325#discussion_r1365982807
  void _registerTokenAndSubscribe() async {
    _debugMaybePause();
    if (_debugRegisterTokenProceed != null) {
      await _debugRegisterTokenProceed!.future;
    }

    NotificationService.instance.token.addListener(_registerToken);
    await _registerToken();

    _debugRegisterTokenCompleted?.complete();
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
    final token = NotificationService.instance.token.value;
    if (token == null) return;

    if (connection.zulipFeatureLevel! < 421) { // TODO(#1764): update this
      return _legacyRegisterToken(token);
    }

    final timestamp = ZulipBinding.instance.utcNow().millisecondsSinceEpoch ~/ 1000;
    if (token != account.pushToken) {
      // TODO(#1764) if old pushToken not null, maybe tell server to forget
      await updateAccount(AccountsCompanion(
        pushAccountId: drift.Value(generatePushAccountId()),
        pushKey: drift.Value(generatePushKey()),
        pushToken: drift.Value(token),
        pushRegistrationTimestamp: drift.Value(timestamp),
      ));
    } else {
      // We've already attempted registering this token, perhaps succeeded.
      // For now, just go ahead.
      // TODO(#1764)/TODO(#322) if past registration succeeded, and recently,
      //   then skip doing it again.
    }

    final pushAccountId = account.pushAccountId;
    final pushKey = account.pushKey;
    if (pushAccountId == null || pushKey == null) {
      throw StateError('Account missing pushAccountId and/or pushKey, while has pushToken'); // TODO(log)
    }

    final tokenKind = switch (defaultTargetPlatform) {
      TargetPlatform.android => PushTokenKind.fcm,
      TargetPlatform.iOS => PushTokenKind.apns,
      _ => throw StateError('unexpected platform: $defaultTargetPlatform'),
    };

    final pushRegistration = PushRegistration(
      tokenKind: tokenKind, token: token,
      timestamp: timestamp);

    try {
      final encryptedPushRegistration = await _encryptToBouncer(
        _bouncerPublicKey, jsonEncode(pushRegistration));
      await registerPushDevice(connection,
        tokenKind: tokenKind,
        pushAccountId: pushAccountId,
        pushKey: base64Encode(pushKey),
        bouncerPublicKey: base64Encode(_bouncerPublicKey), // TODO(#1764) confirm base64 intended; https://chat.zulip.org/#narrow/channel/412-api-documentation/topic/e2ee.20notifs.3A.20bouncer.20public.20key/near/2352465
        encryptedPushRegistration: base64Encode(encryptedPushRegistration),
      );
      assert(debugLog('registerPushDevice: success'));
    } finally {
      await updateAccount(AccountsCompanion(
        pushRegistrationResult: drift.Value('"completed"'), // TODO(#1764) more detail
      ));
    }
    // TODO(#1764) handle errors
  }

  static final _bouncerPublicKey = utf8.encode('nonsense-bouncer-key-asdf-qwer-z'); // TODO(#1764) fill in

  static Future<Uint8List> _encryptToBouncer(Uint8List publicKey, String plaintext) async {
    // ?? WidgetsFlutterBinding.ensureInitialized();  // TODO(#1764)
    final sodium = await SodiumInit.init();
    return sodium.crypto.box.seal(publicKey: publicKey,
      message: utf8.encode(plaintext));
  }

  Future<void> _legacyRegisterToken(String token) async {
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

  /// Generate a suitable value to pass as `pushAccountId` to [registerPushDevice].
  static int generatePushAccountId() {
    final rand = Random.secure();
    return (rand.nextInt(1 << 32) << 32) + rand.nextInt(1 << 32);
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
