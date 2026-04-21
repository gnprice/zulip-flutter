// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotifPayloadNewMessage _$NotifPayloadNewMessageFromJson(
  Map<String, dynamic> json,
) => NotifPayloadNewMessage(
  realmUrl: Uri.parse(json['realm_url'] as String),
  realmName: json['realm_name'] as String?,
  userId: (json['user_id'] as num).toInt(),
  senderId: (json['sender_id'] as num).toInt(),
  senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
  senderFullName: json['sender_full_name'] as String,
  recipient: NotifPayloadRecipient.fromJson(
    NotifPayloadNewMessage._readWhole(json, 'recipient')
        as Map<String, dynamic>,
  ),
  messageId: (json['message_id'] as num).toInt(),
  content: json['content'] as String,
  time: (json['time'] as num).toInt(),
);

Map<String, dynamic> _$NotifPayloadNewMessageToJson(
  NotifPayloadNewMessage instance,
) => <String, dynamic>{
  'realm_url': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'user_id': instance.userId,
  'type': instance.type,
  'sender_id': instance.senderId,
  'sender_avatar_url': instance.senderAvatarUrl.toString(),
  'sender_full_name': instance.senderFullName,
  'message_id': instance.messageId,
  'time': instance.time,
  'content': instance.content,
};

NotifPayloadChannelRecipient _$NotifPayloadChannelRecipientFromJson(
  Map<String, dynamic> json,
) => NotifPayloadChannelRecipient(
  channelId: (json['channel_id'] as num).toInt(),
  channelName: json['channel_name'] as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

NotifPayloadDmRecipient _$NotifPayloadDmRecipientFromJson(
  Map<String, dynamic> json,
) => NotifPayloadDmRecipient(
  allRecipientIds: (json['recipient_user_ids'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

NotifPayloadRemove _$NotifPayloadRemoveFromJson(Map<String, dynamic> json) =>
    NotifPayloadRemove(
      realmUrl: Uri.parse(json['realm_url'] as String),
      realmName: json['realm_name'] as String?,
      userId: (json['user_id'] as num).toInt(),
      messageIds: (json['message_ids'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$NotifPayloadRemoveToJson(NotifPayloadRemove instance) =>
    <String, dynamic>{
      'realm_url': instance.realmUrl.toString(),
      'realm_name': instance.realmName,
      'user_id': instance.userId,
      'type': instance.type,
      'message_ids': instance.messageIds,
    };
