import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'notifications.g.dart';

/// DRAFT API: see https://chat.zulip.org/#narrow/channel/378-api-design/topic/E2EE.20-.20key.20rotation/near/2353451
///
/// https://zulip.com/api/register-push-device
///
/// For constructing [encryptedPushRegistration], see [PushRegistration].
Future<void> registerPushDevice(ApiConnection connection, {
  required int deviceId,
  RegisterPushDeviceKey? key,
  RegisterPushDeviceToken? token,
}) {
  assert(key != null || token != null);
  return connection.post('registerPushDevice', (_) {}, 'mobile_push/register', {
    'device_id': deviceId,
    if (key != null) ...{
      'push_key_id': key.pushKeyId,
      'push_key': RawParameter(key.pushKey),
    },
    if (token != null) ...{
      'token_kind': RawParameter(token.tokenKind.name),
      'token_id': token.tokenId,
      'bouncer_public_key': RawParameter(token.bouncerPublicKey),
      'encrypted_push_registration': RawParameter(token.encryptedPushRegistration),
    },
  });
}

class RegisterPushDeviceKey {
  final int pushKeyId;
  final String pushKey;

  RegisterPushDeviceKey({required this.pushKeyId, required this.pushKey});
}

class RegisterPushDeviceToken {
  final PushTokenKind tokenKind;
  final String tokenId;
  final String bouncerPublicKey;
  final String encryptedPushRegistration;

  RegisterPushDeviceToken({
    required this.tokenKind,
    required this.tokenId,
    required this.bouncerPublicKey,
    required this.encryptedPushRegistration,
  });
}

/// As in the `tokenKind` parameter to [registerPushDevice].
enum PushTokenKind { fcm, apns }

/// The plaintext for the `encryptedPushRegistration` parameter to [registerPushDevice].
@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class PushRegistration {
  final PushTokenKind tokenKind;
  final String token;
  final int timestamp;

  PushRegistration({
    required this.tokenKind,
    required this.token,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => _$PushRegistrationToJson(this);
}

/// https://zulip.com/api/add-fcm-token
Future<void> addFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.post('addFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

/// https://zulip.com/api/remove-fcm-token
Future<void> removeFcmToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('removeFcmToken', (_) {}, 'users/me/android_gcm_reg_id', {
    'token': RawParameter(token),
  });
}

/// https://zulip.com/api/add-apns-token
Future<void> addApnsToken(ApiConnection connection, {
  required String token,
  required String appid,
}) {
  return connection.post('addApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
    'appid': RawParameter(appid),
  });
}

/// https://zulip.com/api/remove-apns-token
Future<void> removeApnsToken(ApiConnection connection, {
  required String token,
}) {
  return connection.delete('removeApnsToken', (_) {}, 'users/me/apns_device_token', {
    'token': RawParameter(token),
  });
}
