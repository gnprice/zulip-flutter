import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/model/events.dart';
import '../api/model/initial_snapshot.dart';
import '../api/model/model.dart';
import '../api/route/notifications.dart';
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
  // TODO(#322) save acked token, to dedupe updating it on the server
  // TODO(#323) track the addFcmToken/etc request, warn if not succeeding
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
