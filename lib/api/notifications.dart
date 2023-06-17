
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

abstract class FcmMessageWithIdentity extends FcmMessage {
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
class MessageFcmMessage extends FcmMessageWithIdentity {
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'message';

  final int senderId;
  final String senderEmail;
  final Uri senderAvatarUrl;
  final String senderFullName;

  @JsonKey(readValue: _parseCommaSeparatedInts)
  final List<int>? pmUsers; // TODO split stream/private

  // final int? streamId; // TODO
  // final String? stream;
  // final String? topic;

  final int zulipMessageId;
  final String content;
  final int time; // in Unix seconds UTC

  MessageFcmMessage({
    required super.server,
    required super.realmId,
    required super.realmUri,
    required super.userId,
    required this.senderId,
    required this.senderEmail,
    required this.senderAvatarUrl,
    required this.senderFullName,
    required this.pmUsers,
    required this.zulipMessageId,
    required this.content,
    required this.time,
  });

  factory MessageFcmMessage.fromJson(Map<String, dynamic> json) {
    assert(json['event'] == 'message');
    return _$MessageFcmMessageFromJson(json);
  }

  @override
  Map<String, dynamic> toJson() => _$MessageFcmMessageToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RemoveFcmMessage extends FcmMessageWithIdentity {
  @JsonKey(includeToJson: true, name: 'event')
  String get type => 'remove';

  // Servers have sent zulipMessageIds, obsoleting the singular zulipMessageId
  // and just sending the first ID there redundantly, since 2019.
  // See zulip-mobile@4acd07376.

  @JsonKey(readValue: _parseCommaSeparatedInts)
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

List<int> _parseCommaSeparatedInts(Map json, String key) {
  return (json[key] as String).split(',').map(int.parse).toList();
}
