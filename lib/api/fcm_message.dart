import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'model/model.dart';
import 'notifications.dart';

part 'fcm_message.g.dart';

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

//|//////////////////////////////////////////////////////////////
// Types for parsing legacy plaintext notification payloads.
//

// TODO(server-12) remove handling of legacy plaintext notifications

/// Parsed version of a legacy plaintext FCM message.
///
/// See pre-E2EE server implementation for reference:
///   https://github.com/zulip/zulip/blob/10.x/zerver/lib/push_notifications.py#L963
sealed class LegacyFcmMessage {

  static NotifPayload fromJson(Map<String, dynamic> json) {
    switch (json['event']) {
      case 'message': return MessageLegacyFcmMessage.fromJson(json);
      case 'remove': return RemoveLegacyFcmMessage.fromJson(json);
      default: return UnexpectedLegacyFcmMessage.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

/// A [LegacyFcmMessage] of a type (a value of `event`) we didn't know about.
class UnexpectedLegacyFcmMessage extends LegacyFcmMessage implements UnexpectedNotifPayload {
  @override
  final Map<String, dynamic> json;

  UnexpectedLegacyFcmMessage.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

/// Base class for [LegacyFcmMessage]s that identify what Zulip account they're for.
sealed class LegacyFcmMessageWithIdentity extends LegacyFcmMessage {
  // final String server; // ignore; never used, gone with E2EE notifs
  // final int realmId; // ignore; never used, gone with E2EE notifs

  // TODO(server-9): FL 257 deprecated 'realm_uri' in favor of 'realm_url'.
  static String _readRealmUrl(Map<dynamic, dynamic> json, String key) {
    return (json['realm_url'] ?? json['realm_uri']) as String;
  }
}

/// Parsed version of a legacy plaintext FCM message of type `message`.
///
/// This corresponds to a Zulip message for which the user wants to
/// see a notification.
@JsonSerializable(fieldRename: FieldRename.snake)
class MessageLegacyFcmMessage extends LegacyFcmMessageWithIdentity implements NotifPayloadNewMessage {
  @override
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'message';

  @override
  @JsonKey(readValue: LegacyFcmMessageWithIdentity._readRealmUrl) // TODO(server-9)
  final Uri realmUrl;

  @override
  final String? realmName; // TODO(server-8)

  @override
  @_IntConverter()
  final int userId;

  @override
  @_IntConverter()
  final int senderId;
  // final String senderEmail; // obsolete; ignore
  @override
  final Uri senderAvatarUrl;
  @override
  final String senderFullName;

  @override
  @JsonKey(includeToJson: false, readValue: _readWhole, fromJson: LegacyFcmMessageRecipient.fromJson)
  final NotifPayloadRecipient recipient;

  @override
  @JsonKey(name: 'zulip_message_id')
  @_IntConverter()
  final int messageId;
  @override
  @_IntConverter()
  final int time; // in Unix seconds UTC, like [Message.timestamp]

  /// The content of the Zulip message, rendered as plain text.
  ///
  /// This is based on the HTML content, but reduced to plain text specifically
  /// for use in notifications.  For details, see `get_mobile_push_content` in
  /// zulip/zulip:zerver/lib/push_notifications.py .
  @override
  final String content;

  MessageLegacyFcmMessage({
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

  factory MessageLegacyFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'message');
    return _$MessageLegacyFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$MessageLegacyFcmMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case NotifPayloadDmRecipient(allRecipientIds: [_] || [_, _]):
        break;
      case NotifPayloadDmRecipient(:var allRecipientIds):
        result['pm_users'] = const _IntListConverter().toJson(allRecipientIds);
      case NotifPayloadChannelRecipient():
        result['stream_id'] = const _IntConverter().toJson(recipient.channelId);
        if (recipient.channelName != null) result['stream'] = recipient.channelName;
        result['topic'] = recipient.topic;
    }
    result['realm_uri'] = realmUrl.toString(); // TODO(server-9): deprecated in FL 257
    return result;
  }
}

/// Data identifying where a Zulip message was sent, as part of a [LegacyFcmMessage].
abstract class LegacyFcmMessageRecipient {
  LegacyFcmMessageRecipient();

  static NotifPayloadRecipient fromJson(Map<String, dynamic> json) {
    // There's also a `recipient_type` field, but we don't really need it.
    // The presence or absence of `stream_id` is just as informative.
    return json.containsKey('stream_id')
      ? LegacyFcmMessageChannelRecipient.fromJson(json)
      : LegacyFcmMessageDmRecipient.fromJson(json);
  }
}

/// A [LegacyFcmMessageRecipient] for a Zulip message to a stream.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class LegacyFcmMessageChannelRecipient extends LegacyFcmMessageRecipient implements NotifPayloadChannelRecipient {
  @override
  @JsonKey(name: 'stream_id')
  @_IntConverter()
  final int channelId;

  // Current servers (as of 2025) always send the channel name.  But
  // future servers might not, once clients get the name from local data.
  // So might as well be ready.
  @override
  @JsonKey(name: 'stream')
  final String? channelName;

  @override
  final TopicName topic;

  LegacyFcmMessageChannelRecipient({required this.channelId, required this.channelName, required this.topic});

  factory LegacyFcmMessageChannelRecipient.fromJson(Map<String, dynamic> json) =>
    _$LegacyFcmMessageChannelRecipientFromJson(json);
}

/// A [LegacyFcmMessageRecipient] for a Zulip message that was a DM.
class LegacyFcmMessageDmRecipient extends LegacyFcmMessageRecipient implements NotifPayloadDmRecipient {
  @override
  final List<int> allRecipientIds;

  LegacyFcmMessageDmRecipient({required this.allRecipientIds});

  factory LegacyFcmMessageDmRecipient.fromJson(Map<String, dynamic> json) {
    return LegacyFcmMessageDmRecipient(allRecipientIds: switch (json) {
      // Group DM conversations ("huddles") are represented with `pm_users`,
      // which lists all the user IDs in the conversation.
      // TODO check they're sorted.
      {'pm_users': String pmUsers} => const _IntListConverter().fromJson(pmUsers),

      // 1:1 DM conversations have no `pm_users`.  Knowing that it's a
      // 1:1 DM, `sender_id` is enough to identify the conversation.
      {'sender_id': String senderId, 'user_id': String userId} =>
        _pairSet(_parseInt(senderId), _parseInt(userId)),

      _ => throw Exception("bad recipient"),
    });
  }

  /// The set {id1, id2}, represented as a sorted list.
  // (In set theory this is called the "pair" of id1 and id2: https://en.wikipedia.org/wiki/Axiom_of_pairing .)
  static List<int> _pairSet(int id1, int id2) {
    if (id1 == id2) return [id1];
    if (id1 < id2) return [id1, id2];
    return [id2, id1];
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoveLegacyFcmMessage extends LegacyFcmMessageWithIdentity implements NotifPayloadRemove {
  @override
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'remove';

  @override
  @JsonKey(readValue: LegacyFcmMessageWithIdentity._readRealmUrl) // TODO(server-9)
  final Uri realmUrl;

  @override
  final String? realmName; // TODO(server-8)

  @override
  @_IntConverter()
  final int userId;

  // Servers have sent zulip_message_ids, obsoleting the singular zulip_message_id
  // and just sending the first ID there redundantly, since 2019.
  // See zulip-mobile@4acd07376.

  @override
  @JsonKey(name: 'zulip_message_ids')
  @_IntListConverter()
  final List<int> messageIds;
  // final String? zulipMessageId; // obsolete; ignore

  RemoveLegacyFcmMessage({
    required this.realmUrl,
    required this.realmName,
    required this.userId,
    required this.messageIds,
  });

  factory RemoveLegacyFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'remove');
    return _$RemoveLegacyFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() {
    final result = _$RemoveLegacyFcmMessageToJson(this);
    result['realm_uri'] = realmUrl.toString(); // TODO(server-9): deprecated in FL 257
    return result;
  }
}

class _IntListConverter extends JsonConverter<List<int>, String> {
  const _IntListConverter();

  @override
  List<int> fromJson(String json) => json.split(',').map(_parseInt).toList();

  @override
  String toJson(List<int> value) => value.join(',');
}

class _IntConverter extends JsonConverter<int, String> {
  const _IntConverter();

  @override
  int fromJson(String json) => _parseInt(json);

  @override
  String toJson(int value) => value.toString();
}

int _parseInt(String string) => int.parse(string, radix: 10);
