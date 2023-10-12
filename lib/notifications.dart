import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api/notifications.dart';
import 'log.dart';
import 'model/binding.dart';
import 'model/narrow.dart';
import 'widgets/app.dart';
import 'widgets/message_list.dart';
import 'widgets/store.dart';

class NotificationService {
  static NotificationService get instance => (_instance ??= NotificationService._());
  static NotificationService? _instance;

  NotificationService._();

  /// Reset the state of the [NotificationService], for testing.
  ///
  /// TODO refactor this better, perhaps unify with ZulipBinding
  @visibleForTesting
  static void debugReset() {
    instance.token.dispose();
    instance.token = ValueNotifier(null);
  }

  /// The FCM registration token for this install of the app.
  ///
  /// This is unique to the (app, device) pair, but not permanent.
  /// Most often it's the same from one run of the app to the next,
  /// but it can change either during a run or between them.
  ///
  /// See also:
  ///  * Upstream docs on FCM registration tokens in general:
  ///    https://firebase.google.com/docs/cloud-messaging/manage-tokens
  ValueNotifier<String?> token = ValueNotifier(null);

  Future<void> start() async {
    if (defaultTargetPlatform != TargetPlatform.android) return; // TODO(#321)

    await ZulipBinding.instance.firebaseInitializeApp();

    // TODO(#324) defer notif setup if user not logged into any accounts
    //   (in order to avoid calling for permissions)

    ZulipBinding.instance.firebaseMessagingOnMessage.listen(_onRemoteMessage);
    ZulipBinding.instance.notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('zulip_notification'),
      ),
      onDidReceiveNotificationResponse: _onNotificationOpened,
    );

    // Get the FCM registration token, now and upon changes.  See FCM API docs:
    //   https://firebase.google.com/docs/cloud-messaging/android/client#sample-register
    ZulipBinding.instance.firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
    await _getToken();
  }

  Future<void> _getToken() async {
    final value = await ZulipBinding.instance.firebaseMessaging.getToken(); // TODO(log) if null
    assert(debugLog("notif token: $value"));
    // On a typical launch of the app (other than the first one after install),
    // this is the only way we learn the token value; onTokenRefresh never fires.
    token.value = value;
  }

  void _onTokenRefresh(String value) {
    assert(debugLog("new notif token: $value"));
    // On first launch after install, our [FirebaseMessaging.getToken] call
    // causes this to fire, followed by completing its own future so that
    // `_getToken` sees the value as well.  So in that case this is redundant.
    //
    // Subsequently, though, this can also potentially fire on its own, if for
    // some reason the FCM system decides to replace the token.  So both paths
    // need to save the value.
    token.value = value;
  }

  void _onRemoteMessage(FirebaseRemoteMessage message) {
    print(message.data);
    final data = FcmMessage.fromJson(message.data);
    switch (data) {
      case MessageFcmMessage(): NotificationDisplayManager._onMessageFcmMessage(data, message.data);
      case RemoveFcmMessage(): break; // TODO handle
      case UnexpectedFcmMessage(): break; // TODO(log)
    }
  }

  void _onNotificationOpened(NotificationResponse response) async {
    final data = MessageFcmMessage.fromJson(jsonDecode(response.payload!));
    print('opened notif: message ${data.zulipMessageId}, content ${data.content}');
    final navigator = navigatorKey.currentState;
    if (navigator == null) return; // TODO(log) handle

    final globalStore = GlobalStoreWidget.of(navigator.context);
    final account = globalStore.accounts.firstWhereOrNull((account) =>
      account.realmUrl == data.realmUri && account.userId == data.userId);
    if (account == null) return; // TODO(log)

    final narrow = switch (data.recipient) {
      FcmMessageStreamRecipient(:var streamId, :var topic) =>
        TopicNarrow(streamId, topic),
      FcmMessageDmRecipient(:var allRecipientIds) =>
        DmNarrow(allRecipientIds: allRecipientIds, selfUserId: account.userId),
    };

    print('  account: $account, narrow: $narrow');
    // TODO(nav): Better interact with existing nav stack on notif open
    navigator.push(MaterialPageRoute(builder: (context) =>
      PerAccountStoreWidget(accountId: account.id,
        child: MessageListPage(narrow: narrow))));
  }
}

/// Service for configuring our Android "notification channel".
class NotificationChannelManager {
  static const _kChannelId = 'messages-1';

  /// The vibration pattern we set for notifications.
  // We try to set a vibration pattern that, with the phone in one's pocket,
  // is both distinctly present and distinctly different from the default.
  // Discussion: https://chat.zulip.org/#narrow/stream/48-mobile/topic/notification.20vibration.20pattern/near/1284530
  static final _kVibrationPattern = Int64List.fromList([0, 125, 100, 450]);

  static void _ensureChannel() async { // TODO "ensure"
    final plugin = ZulipBinding.instance.notifications;
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(AndroidNotificationChannel(
        _kChannelId,
        'Messages', // TODO(i18n)
        importance: Importance.high,
        enableLights: true,
        vibrationPattern: _kVibrationPattern,
        // TODO sound
      ));
  }
}

/// Service for managing the notifications shown to the user.
class NotificationDisplayManager {
  // We rely on the tag instead.
  static const _kNotificationId = 0;

  static void _onMessageFcmMessage(MessageFcmMessage data, Map<String, dynamic> dataJson) {
    NotificationChannelManager._ensureChannel();
    print('content: ${data.content}');
    final title = switch (data.recipient) {
      FcmMessageStreamRecipient(:var stream?, :var topic) =>
        '$stream > $topic',
      FcmMessageStreamRecipient(:var topic) =>
        '(unknown stream) > $topic', // TODO get stream name from data
      FcmMessageDmRecipient(:var allRecipientIds) when allRecipientIds.length > 2 =>
        '${data.senderFullName} to you and ${allRecipientIds.length - 2} others', // TODO(i18n), also plural; TODO use others' names, from data
      FcmMessageDmRecipient() =>
        data.senderFullName,
    };
    ZulipBinding.instance.notifications.show(
      _kNotificationId,
      title,
      data.content, // TODO
      payload: jsonEncode(dataJson),
      NotificationDetails(android: AndroidNotificationDetails(
        NotificationChannelManager._kChannelId, 'channel name',
        tag: _conversationKey(data),
        color: kZulipBrandColor,
        icon: 'zulip_notification', // TODO vary for debug
        // TODO inbox-style
      )));
  }

  static String _conversationKey(MessageFcmMessage data) {
    final groupKey = _groupKey(data);
    final conversation = switch (data.recipient) {
      FcmMessageStreamRecipient(:var streamId, :var topic) => 'stream:$streamId:$topic',
      FcmMessageDmRecipient(:var allRecipientIds) => 'dm:${allRecipientIds.join(',')}',
    };
    return '$groupKey|$conversation';
  }

  static String _groupKey(FcmMessageWithIdentity data) {
    // The realm URL can't contain a `|`, because `|` is not a URL code point:
    //   https://url.spec.whatwg.org/#url-code-points
    return "${data.realmUri}|${data.userId}";
  }
}
