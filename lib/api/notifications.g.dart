// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: constant_identifier_names, unnecessary_cast

part of 'notifications.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageFcmMessage _$MessageFcmMessageFromJson(Map<String, dynamic> json) =>
    MessageFcmMessage(
      server: json['server'] as String,
      realmId: json['realm_id'] as int,
      realmUri: Uri.parse(json['realm_uri'] as String),
      userId: json['user_id'] as int,
      senderId: json['sender_id'] as int,
      senderEmail: json['sender_email'] as String,
      senderAvatarUrl: Uri.parse(json['sender_avatar_url'] as String),
      senderFullName: json['sender_full_name'] as String,
      pmUsers: (_parseCommaSeparatedInts(json, 'pm_users') as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      zulipMessageId: json['zulip_message_id'] as int,
      content: json['content'] as String,
      time: json['time'] as int,
    );

Map<String, dynamic> _$MessageFcmMessageToJson(MessageFcmMessage instance) =>
    <String, dynamic>{
      'server': instance.server,
      'realm_id': instance.realmId,
      'realm_uri': instance.realmUri.toString(),
      'user_id': instance.userId,
      'event': instance.type,
      'sender_id': instance.senderId,
      'sender_email': instance.senderEmail,
      'sender_avatar_url': instance.senderAvatarUrl.toString(),
      'sender_full_name': instance.senderFullName,
      'pm_users': instance.pmUsers,
      'zulip_message_id': instance.zulipMessageId,
      'content': instance.content,
      'time': instance.time,
    };

RemoveFcmMessage _$RemoveFcmMessageFromJson(Map<String, dynamic> json) =>
    RemoveFcmMessage(
      server: json['server'] as String,
      realmId: json['realm_id'] as int,
      realmUri: Uri.parse(json['realm_uri'] as String),
      userId: json['user_id'] as int,
      zulipMessageIds:
          (_parseCommaSeparatedInts(json, 'zulip_message_ids') as List<dynamic>)
              .map((e) => e as int)
              .toList(),
    );

Map<String, dynamic> _$RemoveFcmMessageToJson(RemoveFcmMessage instance) =>
    <String, dynamic>{
      'server': instance.server,
      'realm_id': instance.realmId,
      'realm_uri': instance.realmUri.toString(),
      'user_id': instance.userId,
      'event': instance.type,
      'zulip_message_ids': instance.zulipMessageIds,
    };
