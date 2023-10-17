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
      final streamParsed = parse(streamJson);
      check(streamParsed.server).equals(baseJson['server']!);
      check(streamParsed.realmId).equals(4);
      check(streamParsed.realmUri).equals(Uri.parse(baseJson['realm_uri']!));
      check(streamParsed.userId).equals(234);
      // TODO more here
    });
  });

  // TODO adapt remaining test cases from zulip-mobile:android/app/src/test/java/com/zulipmobile/notifications/FcmMessageTest.kt
}
