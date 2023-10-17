import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/api/notifications.dart';

void main() {
  final baseBaseJson = {
    "server": "zulip.example.cloud",  // corresponds to EXTERNAL_HOST
    "realm_id": "4",
    "realm_uri": "https://zulip.example.com",  // corresponds to realm.uri
    "user_id": "234",
  };

  void checkParseFails(Map<String, String> data) {
    check(() => FcmMessage.fromJson(data)).throws();
  }

  group('FcmMessage', () {
    test('parse fails on missing or bad event type', () {
      check(FcmMessage.fromJson({})).isA<UnexpectedFcmMessage>();
      check(FcmMessage.fromJson({'event': 'nonsense'})).isA<UnexpectedFcmMessage>();
    });
  });

  // TODO adapt RecipientTest

  group('MessageFcmMessage', () {
    final baseJson = {
      ...baseBaseJson,
      "event": "message",

      "zulip_message_id": "12345",

      "sender_id": "123",
      "sender_email": "sender@example.com",
      "sender_avatar_url": "https://zulip.example.com/avatar/123.jpeg",
      "sender_full_name": "A Sender",

      "time": "1546300800",  // a Unix seconds-since-epoch

      "content": "This is a message",  // rendered_content, reduced to plain text
      "content_truncated": "This is a m…",
    };

    final streamJson = {
      ...baseJson,
      "recipient_type": "stream",
      "stream_id": "42",
      "stream": "denmark",
      "topic": "play",

      "alert": "New stream message from A Sender in denmark",
    };

    final groupDmJson = {
      ...baseJson,
      "recipient_type": "private",
      "pm_users": "123,234,345",

      "alert": "New private group message from A Sender",
    };

    final dmJson = {
      ...baseJson,
      "recipient_type": "private",

      "alert": "New private message from A Sender",
    };

    test("'message' messages parse as MessageFcmMessage", () {
      check(FcmMessage.fromJson(streamJson)).isA<MessageFcmMessage>();
    });

    MessageFcmMessage parse(Map<String, dynamic> json) {
      return FcmMessage.fromJson(json) as MessageFcmMessage;
    }

    test("fields get parsed right in 'message' happy path", () {
      check(parse(streamJson))
        ..server.equals(baseJson['server']!)
        ..realmId.equals(4)
        ..realmUri.equals(Uri.parse(baseJson['realm_uri']!))
        ..userId.equals(234)
        ..senderId.equals(123)
        ..senderEmail.equals(streamJson['sender_email']!)
        ..senderAvatarUrl.equals(Uri.parse(streamJson['sender_avatar_url']!))
        ..senderFullName.equals(streamJson['sender_full_name']!)
        ..zulipMessageId.equals(12345)
        ..recipient.isA<FcmMessageStreamRecipient>().which(it()
          ..streamId.equals(42)
          ..stream.equals(streamJson['stream']!)
          ..topic.equals(streamJson['topic']!))
        ..content.equals(streamJson['content']!)
        ..time.equals(1546300800);

      check(parse(groupDmJson))
        .recipient.isA<FcmMessageDmRecipient>()
        .allRecipientIds.deepEquals([123, 234, 345]);

      check(parse(dmJson))
        .recipient.isA<FcmMessageDmRecipient>()
        .allRecipientIds.deepEquals([123, 234]);
    });

    test('optional fields missing cause no error', () {
      check(parse({ ...streamJson }..remove('stream')))
        .recipient.isA<FcmMessageStreamRecipient>().which(it()
          ..streamId.equals(42)
          ..stream.isNull());
    });

    test('obsolete or novel fields have no effect', () {
      final baseline = parse(dmJson);
      check(parse({ ...dmJson, 'user': 'client@example.com' }))
        ..senderId.equals(baseline.senderId)
        ..senderEmail.equals(baseline.senderEmail)
        ..recipient.isA<FcmMessageDmRecipient>()
          .allRecipientIds.deepEquals(
            (baseline.recipient as FcmMessageDmRecipient).allRecipientIds);

      check(parse({ ...dmJson, 'awesome_feature': 'enabled' }))
        ..senderId.equals(baseline.senderId)
        ..senderEmail.equals(baseline.senderEmail)
        ..recipient.isA<FcmMessageDmRecipient>()
          .allRecipientIds.deepEquals(
            (baseline.recipient as FcmMessageDmRecipient).allRecipientIds);
    });

    test("parse failures on malformed 'message'", () {
      checkParseFails({ ...dmJson }..remove('server'));
      checkParseFails({ ...dmJson }..remove('realm_id'));
      checkParseFails({ ...dmJson, 'realm_id': '12,34' });
      checkParseFails({ ...dmJson, 'realm_id': 'abc' });
      checkParseFails({ ...dmJson }..remove('realm_uri'));
      checkParseFails({ ...dmJson, 'realm_uri': 'zulip.example.com' });
      checkParseFails({ ...dmJson, 'realm_uri': '/examplecorp' });

      checkParseFails({ ...streamJson }..remove('recipient_type'));
      checkParseFails({ ...streamJson, 'stream_id': '12,34' });
      checkParseFails({ ...streamJson, 'stream_id': 'abc' });
      checkParseFails({ ...streamJson }..remove('stream'));
      checkParseFails({ ...streamJson }..remove('topic'));
      checkParseFails({ ...groupDmJson }..remove('recipient_type'));
      checkParseFails({ ...groupDmJson, 'pm_users': 'abc,34' });
      checkParseFails({ ...groupDmJson, 'pm_users': '12,abc' });
      checkParseFails({ ...groupDmJson, 'pm_users': '12,' });
      checkParseFails({ ...dmJson }..remove('recipient_type'));
      checkParseFails({ ...dmJson, 'recipient_type': 'nonsense' });

      checkParseFails({ ...dmJson }..remove('sender_avatar_url'));
      checkParseFails({ ...dmJson, 'sender_avatar_url': '/avatar/123.jpeg' });
      checkParseFails({ ...dmJson, 'sender_avatar_url': '' });

      checkParseFails({ ...dmJson }..remove('sender_id'));
      checkParseFails({ ...dmJson }..remove('sender_email'));
      checkParseFails({ ...dmJson }..remove('sender_full_name'));
      checkParseFails({ ...dmJson }..remove('zulip_message_id'));
      checkParseFails({ ...dmJson, 'zulip_message_id': '12,34' });
      checkParseFails({ ...dmJson, 'zulip_message_id': 'abc' });
      checkParseFails({ ...dmJson }..remove('content'));
      checkParseFails({ ...dmJson }..remove('time'));
      checkParseFails({ ...dmJson, 'time': '12:34' });
    });
  });

  group('RemoveFcmMessage', () {
    final baseJson = {
      ...baseBaseJson,
      'event': 'remove',
    };

    // This is the redundant form sent since server-2.0, as of 2023.
    final hybridJson = {
      ...baseJson,
      'zulip_message_ids': '234,345',
      'zulip_message_id': '123',
    };

    // Some future server may drop the singular, unbatched field.
    final batchedJson = {
      ...baseJson,
      'zulip_message_ids': '234,345',
    };

    test("'remove' messages parse as RemoveFcmMessage", () {
      check(FcmMessage.fromJson(batchedJson)).isA<RemoveFcmMessage>();
    });

    RemoveFcmMessage parse(Map<String, dynamic> json) {
      return FcmMessage.fromJson(json) as RemoveFcmMessage;
    }

    test('fields get parsed right in happy path', () {
      check(parse(hybridJson))
        ..server.equals(baseJson['server']!)
        ..realmId.equals(4)
        ..realmUri.equals(Uri.parse(baseJson['realm_uri']!))
        ..userId.equals(234)
        ..zulipMessageIds.deepEquals([123, 234, 345]);

      check(parse(batchedJson))
        ..server.equals(baseJson['server']!)
        ..realmId.equals(4)
        ..realmUri.equals(Uri.parse(baseJson['realm_uri']!))
        ..userId.equals(234)
        ..zulipMessageIds.deepEquals([123, 234, 345]);
    });

    test('parse failures on malformed data', () {
      checkParseFails({ ...hybridJson }..remove('server'));
      checkParseFails({ ...hybridJson }..remove('realm_id'));
      checkParseFails({ ...hybridJson, 'realm_id': 'abc' });
      checkParseFails({ ...hybridJson, 'realm_id': '12,34' });
      checkParseFails({ ...hybridJson }..remove('realm_uri'));
      checkParseFails({ ...hybridJson, 'realm_uri': 'zulip.example.com' });
      checkParseFails({ ...hybridJson, 'realm_uri': '/examplecorp' });

      for (final badIntList in ["abc,34", "12,abc", "12,", ""]) {
        checkParseFails({ ...hybridJson, 'zulip_message_ids': badIntList });
        checkParseFails({ ...batchedJson, 'zulip_message_ids': badIntList });
      }
    });
  });
}

extension UnexpectedFcmMessageChecks on Subject<UnexpectedFcmMessage> {
  Subject<Map<String, dynamic>> get json => has((x) => x.json, 'json');
}

extension FcmMessageWithIdentityChecks on Subject<FcmMessageWithIdentity> {
  Subject<String> get server => has((x) => x.server, 'server');
  Subject<int> get realmId => has((x) => x.realmId, 'realmId');
  Subject<Uri> get realmUri => has((x) => x.realmUri, 'realmUri');
  Subject<int> get userId => has((x) => x.userId, 'userId');
}

extension MessageFcmMessageChecks on Subject<MessageFcmMessage> {
  Subject<int> get senderId => has((x) => x.senderId, 'senderId');
  Subject<String> get senderEmail => has((x) => x.senderEmail, 'senderEmail');
  Subject<Uri> get senderAvatarUrl => has((x) => x.senderAvatarUrl, 'senderAvatarUrl');
  Subject<String> get senderFullName => has((x) => x.senderFullName, 'senderFullName');
  Subject<FcmMessageRecipient> get recipient => has((x) => x.recipient, 'recipient');
  Subject<int> get zulipMessageId => has((x) => x.zulipMessageId, 'zulipMessageId');
  Subject<String> get content => has((x) => x.content, 'content');
  Subject<int> get time => has((x) => x.time, 'time');
}

extension FcmMessageStreamRecipientChecks on Subject<FcmMessageStreamRecipient> {
  Subject<int> get streamId => has((x) => x.streamId, 'streamId');
  Subject<String?> get stream => has((x) => x.stream, 'stream');
  Subject<String> get topic => has((x) => x.topic, 'topic');
}

extension FcmMessageDmRecipientChecks on Subject<FcmMessageDmRecipient> {
  Subject<List<int>> get allRecipientIds => has((x) => x.allRecipientIds, 'allRecipientIds');
}

extension RemoveFcmMessageChecks on Subject<RemoveFcmMessage> {
  Subject<List<int>> get zulipMessageIds => has((x) => x.zulipMessageIds, 'zulipMessageIds');
}
