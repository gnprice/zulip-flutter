
import 'package:json_annotation/json_annotation.dart';

part 'notifications.g.dart';

sealed class FcmMessage {
  FcmMessage();

  factory FcmMessage.fromJson(Map<String, dynamic> json) {
    switch (json['event']) {
      case 'message': return MessageFcmMessage.fromJson(json);
      case 'remove': return RemoveFcmMessage.fromJson(json);
      default: return UnexpectedFcmMessage.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

class UnexpectedFcmMessage extends FcmMessage {
  final Map<String, dynamic> json;

  UnexpectedFcmMessage.fromJson(this.json);

  @override
  Map<String, dynamic> toJson() => json;
}

sealed class FcmMessageWithIdentity extends FcmMessage {
  final String server;
  final int realmId;
  final Uri realmUri;
  final int userId;

  FcmMessageWithIdentity({
    required this.server,
    required this.realmId,
    required this.realmUri,
    required this.userId,
  });
}

@JsonSerializable(fieldRename: FieldRename.snake)
@_IntConverter()
@_IntListConverter()
class MessageFcmMessage extends FcmMessageWithIdentity {
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'message';

  final int senderId;
  final String senderEmail;
  final Uri senderAvatarUrl;
  final String senderFullName;

  @JsonKey(includeToJson: false, readValue: _readWhole)
  final FcmMessageRecipient recipient;

  final int zulipMessageId;
  final String content;
  final int time; // in Unix seconds UTC

  static Object? _readWhole(Map json, String key) => json;

  MessageFcmMessage({
    required super.server,
    required super.realmId,
    required super.realmUri,
    required super.userId,
    required this.senderId,
    required this.senderEmail,
    required this.senderAvatarUrl,
    required this.senderFullName,
    required this.recipient,
    required this.zulipMessageId,
    required this.content,
    required this.time,
  });

  factory MessageFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'message');
    return _$MessageFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() { // TODO test MessageFcmMessage.toJson round-trip
    final result = _$MessageFcmMessageToJson(this);
    final recipient = this.recipient;
    switch (recipient) {
      case FcmMessageDmRecipient(allRecipientIds: [_] || [_, _]):
        break;
      case FcmMessageDmRecipient(:var allRecipientIds):
        result['pm_users'] = const _IntListConverter().toJson(allRecipientIds);
      case FcmMessageStreamRecipient():
        result['stream_id'] = recipient.streamId;
        if (recipient.stream != null) result['stream'] = recipient.stream;
        result['topic'] = recipient.topic;
    }
    return result;
  }
}

sealed class FcmMessageRecipient {
  FcmMessageRecipient();

  factory FcmMessageRecipient.fromJson(Map<String, dynamic> json) {
    return json.containsKey('stream_id')
      ? FcmMessageStreamRecipient.fromJson(json)
      : FcmMessageDmRecipient.fromJson(json);
  }
}

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
@_IntConverter()
class FcmMessageStreamRecipient extends FcmMessageRecipient {
  final int streamId;
  final String? stream;
  final String topic;

  FcmMessageStreamRecipient({required this.streamId, required this.stream, required this.topic});

  factory FcmMessageStreamRecipient.fromJson(Map<String, dynamic> json) =>
    _$FcmMessageStreamRecipientFromJson(json);
}

class FcmMessageDmRecipient extends FcmMessageRecipient {
  final List<int> allRecipientIds;

  FcmMessageDmRecipient({required this.allRecipientIds});

  factory FcmMessageDmRecipient.fromJson(Map<String, dynamic> json) {
    return FcmMessageDmRecipient(allRecipientIds: switch (json) {
      {'pm_users': var pmUsers} => const _IntListConverter().fromJson(pmUsers),
      {'sender_id': var senderId, 'user_id': var userId} =>
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
@_IntConverter()
@_IntListConverter()
class RemoveFcmMessage extends FcmMessageWithIdentity {
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'remove';

  // Servers have sent zulipMessageIds, obsoleting the singular zulipMessageId
  // and just sending the first ID there redundantly, since 2019.
  // See zulip-mobile@4acd07376.

  final List<int> zulipMessageIds;
  // final String? zulipMessageId; // obsolete; ignore

  RemoveFcmMessage({
    required super.server,
    required super.realmId,
    required super.realmUri,
    required super.userId,
    required this.zulipMessageIds,
  });

  factory RemoveFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'remove');
    return _$RemoveFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$RemoveFcmMessageToJson(this);
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
