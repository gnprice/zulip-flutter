import 'package:json_annotation/json_annotation.dart';

import '../core.dart';

part 'notifications.g.dart';

/// https://zulip.com/api/register-push-device
///
/// For constructing [encryptedPushRegistration], see [PushRegistration].
Future<void> registerPushDevice(ApiConnection connection, {
  required PushTokenKind tokenKind,
  required int pushAccountId,
  required String pushKey,
  required String bouncerPublicKey,
  required String encryptedPushRegistration,
}) {
  return connection.post('registerPushDevice', (_) {}, 'mobile_push/register', {
    'token_kind': RawParameter(tokenKind.name),
    'push_account_id': pushAccountId,
    'push_key': RawParameter(pushKey),
    'bouncer_public_key': RawParameter(bouncerPublicKey),
    'encrypted_push_registration': RawParameter(encryptedPushRegistration),
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
