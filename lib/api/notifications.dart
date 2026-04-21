
import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'model/model.dart';

part 'notifications.g.dart';

/// An FCM message whose contents are encrypted end-to-end from the Zulip server.
///
/// Firebase Cloud Messaging (FCM) is the service run by Google that we use
/// for delivering notifications to Android devices.  A decrypted FCM message
/// may be to tell us we should show a notification, or something else like
/// to remove one (because the user read the underlying Zulip message).
///
/// Once decrypted, the contents will become a [NotifPayload].
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#data-sent-to-fcm
@JsonSerializable(fieldRename: FieldRename.snake)
class EncryptedFcmMessage {
  @_IntConverter()
  final int pushKeyId;

  @JsonKey(fromJson: base64Decode, toJson: base64Encode)
  final Uint8List encryptedData;

  EncryptedFcmMessage({required this.pushKeyId, required this.encryptedData});

  factory EncryptedFcmMessage.fromJson(Map<String, dynamic> json) =>
    _$EncryptedFcmMessageFromJson(json);

  Map<String, dynamic> toJson() => _$EncryptedFcmMessageToJson(this);
}

class _IntConverter extends JsonConverter<int, String> {
  const _IntConverter();

  @override
  int fromJson(String json) => _parseInt(json);

  @override
  String toJson(int value) => value.toString();
}

int _parseInt(String string) => int.parse(string, radix: 10);

//|//////////////////////////////////////////////////////////////
// Types for parsing E2EE notification payloads.
//

/// Parsed version of decrypted data from an [EncryptedFcmMessage].
///
/// For partial API docs, see:
///   https://zulip.com/api/mobile-notifications
sealed class NotifPayload {
  NotifPayload();

  factory NotifPayload.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'message': return NotifPayloadNewMessage.fromJson(json);
      case 'remove': return NotifPayloadRemove.fromJson(json);
      default: return UnexpectedNotifPayload.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

/// A [NotifPayload] of a 'type' we didn't know about.
class UnexpectedNotifPayload extends NotifPayload {
  final Map<String, dynamic> json;

  UnexpectedNotifPayload.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// Base class for [NotifPayload]s that identify what Zulip account they're for.
///
/// This includes all known types of notification payloads from Zulip
/// (all [NotifPayload] subclasses other than [UnexpectedNotifPayload]),
/// and it seems likely that it always will.
sealed class NotifPayloadWithIdentity extends NotifPayload {
  /// The realm's own URL.
  ///
  /// This is a real, absolute URL which is the base for all URLs a client uses
  /// with this realm.  It corresponds to [GetServerSettingsResult.realmUri].
  Uri get realmUrl;

  /// The realm's name.
  String? get realmName;

  /// This user's ID within the server.
  ///
  /// Useful mainly in the case where the user has multiple accounts in the
  /// same realm.
  int get userId;
}

/// Parsed version of a notification payload of type `message`.
///
/// This corresponds to a Zulip message for which the user wants to
/// see a notification.
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#new-direct-message
@JsonSerializable(fieldRename: FieldRename.snake)
class NotifPayloadNewMessage extends NotifPayloadWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'message';

  @override
  final Uri realmUrl;
  @override
  final String? realmName;
  @override
  final int userId;

  final int senderId;
  final Uri senderAvatarUrl;
  final String senderFullName;

  @JsonKey(includeToJson: false, readValue: _readWhole)
  final NotifPayloadRecipient recipient;

  final int messageId;
  final int time; // in Unix seconds UTC, like [Message.timestamp]

  /// The content of the Zulip message, rendered as plain text.
  ///
  /// This is based on the HTML content, but reduced to plain text specifically
  /// for use in notifications.  For details, see `get_mobile_push_content` in
  /// zulip/zulip:zerver/lib/push_notifications.py .
  final String content;

  NotifPayloadNewMessage({
    required this.realmUrl,
    required this.realmName,
    required this.userId,
    required this.senderId,
    required this.senderAvatarUrl,
    required this.senderFullName,
    required this.recipient,
    required this.messageId,
    required this.content,
    required this.time,
  });

  static Object? _readWhole(Map<dynamic, dynamic> json, String key) => json;

  factory NotifPayloadNewMessage.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'message');
    return _$NotifPayloadNewMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$NotifPayloadNewMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case NotifPayloadDmRecipient(:var allRecipientIds):
        result['recipient_user_ids'] = allRecipientIds;
      case NotifPayloadChannelRecipient():
        result['channel_id'] = recipient.channelId;
        if (recipient.channelName != null) result['channel_name'] = recipient.channelName;
        result['topic'] = recipient.topic;
    }
    return result;
  }
}

/// Data identifying where a Zulip message was sent, as part of a [NotifPayload].
sealed class NotifPayloadRecipient {
  NotifPayloadRecipient();

  factory NotifPayloadRecipient.fromJson(Map<String, dynamic> json) {
    // There's also a `recipient_type` field, but we don't really need it.
    // The presence or absence of `channel_id` is just as informative.
    return (json.containsKey('channel_id'))
      ? NotifPayloadChannelRecipient.fromJson(json)
      : NotifPayloadDmRecipient.fromJson(json);
  }
}

/// A [NotifPayloadRecipient] for a Zulip message to a channel.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NotifPayloadChannelRecipient extends NotifPayloadRecipient {
  final int channelId;

  // Current servers (as of 2025) always send the channel name.  But
  // future servers might not, once clients get the name from local data.
  // So might as well be ready.
  final String? channelName;

  final TopicName topic;

  NotifPayloadChannelRecipient({required this.channelId, required this.channelName, required this.topic});

  factory NotifPayloadChannelRecipient.fromJson(Map<String, dynamic> json) =>
    _$NotifPayloadChannelRecipientFromJson(json);
}

/// A [NotifPayloadRecipient] for a Zulip message that was a DM.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class NotifPayloadDmRecipient extends NotifPayloadRecipient {
  @JsonKey(name: 'recipient_user_ids')
  final List<int> allRecipientIds;

  NotifPayloadDmRecipient({required this.allRecipientIds});

  factory NotifPayloadDmRecipient.fromJson(Map<String, dynamic> json) =>
    _$NotifPayloadDmRecipientFromJson(json);
}

/// Parsed version of a notification payload of type `remove`.
///
/// API docs:
///   https://zulip.com/api/mobile-notifications#remove-notifications
@JsonSerializable(fieldRename: FieldRename.snake)
class NotifPayloadRemove extends NotifPayloadWithIdentity {
  @JsonKey(includeToJson: true)
  String get type => 'remove';

  @override
  final Uri realmUrl;
  @override
  final String? realmName;
  @override
  final int userId;

  final List<int> messageIds;

  NotifPayloadRemove({
    required this.realmUrl,
    required this.realmName,
    required this.userId,
    required this.messageIds,
  });

  factory NotifPayloadRemove.fromJson(Map<String, dynamic> json) {
    assert(json['type'] == 'remove');
    return _$NotifPayloadRemoveFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$NotifPayloadRemoveToJson(this);
}
