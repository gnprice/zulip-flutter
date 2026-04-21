// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'fcm_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageLegacyFcmMessage _$MessageLegacyFcmMessageFromJson(
  Map<String, dynamic> json,
) => MessageLegacyFcmMessage(
  realmUrl: Uri.parse(
    LegacyFcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
  ),
  realmName: json['realm_name'] as String?,
  userId: const _IntConverter().fromJson(json['user_id'] as String),
  senderId: const _IntConverter().fromJson(json['sender_id'] as String),
  senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
  senderFullName: json['sender_full_name'] as String,
  recipient: LegacyFcmMessageRecipient.fromJson(
    MessageLegacyFcmMessage._readWhole(json, 'recipient')
        as Map<String, dynamic>,
  ),
  messageId: const _IntConverter().fromJson(json['zulip_message_id'] as String),
  content: json['content'] as String,
  time: const _IntConverter().fromJson(json['time'] as String),
);

Map<String, dynamic> _$MessageLegacyFcmMessageToJson(
  MessageLegacyFcmMessage instance,
) => <String, dynamic>{
  'event': instance.type,
  'realm_url': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'user_id': const _IntConverter().toJson(instance.userId),
  'sender_id': const _IntConverter().toJson(instance.senderId),
  'sender_avatar_url': instance.senderAvatarUrl.toString(),
  'sender_full_name': instance.senderFullName,
  'zulip_message_id': const _IntConverter().toJson(instance.messageId),
  'time': const _IntConverter().toJson(instance.time),
  'content': instance.content,
};

LegacyFcmMessageChannelRecipient _$LegacyFcmMessageChannelRecipientFromJson(
  Map<String, dynamic> json,
) => LegacyFcmMessageChannelRecipient(
  channelId: const _IntConverter().fromJson(json['stream_id'] as String),
  channelName: json['stream'] as String?,
  topic: TopicName.fromJson(json['topic'] as String),
);

RemoveLegacyFcmMessage _$RemoveLegacyFcmMessageFromJson(
  Map<String, dynamic> json,
) => RemoveLegacyFcmMessage(
  realmUrl: Uri.parse(
    LegacyFcmMessageWithIdentity._readRealmUrl(json, 'realm_url') as String,
  ),
  realmName: json['realm_name'] as String?,
  userId: const _IntConverter().fromJson(json['user_id'] as String),
  messageIds: const _IntListConverter().fromJson(
    json['zulip_message_ids'] as String,
  ),
);

Map<String, dynamic> _$RemoveLegacyFcmMessageToJson(
  RemoveLegacyFcmMessage instance,
) => <String, dynamic>{
  'event': instance.type,
  'realm_url': instance.realmUrl.toString(),
  'realm_name': instance.realmName,
  'user_id': const _IntConverter().toJson(instance.userId),
  'zulip_message_ids': const _IntListConverter().toJson(instance.messageIds),
};
