import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api/notifications.dart';
import 'log.dart';
import 'model/binding.dart';
import 'widgets/app.dart';

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

    FirebaseMessaging.onMessage.listen(_onRemoteMessage);

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

  void _onRemoteMessage(RemoteMessage message) {
    print(message.data);
    final data = FcmMessage.fromJson(message.data);
    if (data is MessageFcmMessage) {
      _ensureChannel();
      print('content: ${data.content}');
      FlutterLocalNotificationsPlugin().show(
        _kNotificationId,
        switch (data) {
          // TODO stream messages
          MessageFcmMessage(:var pmUsers?, :var senderFullName) =>
            '$senderFullName to you and ${pmUsers.length - 2} others', // TODO(i18n), also plural; TODO use others' names, from data
          MessageFcmMessage(:var senderFullName) =>
            senderFullName,
        },
        data.content, // TODO
        NotificationDetails(android: AndroidNotificationDetails(
          _kChannelId, 'channel name',
          tag: _conversationKey(data),
          color: kZulipBrandColor,
          icon: 'zulip_notification', // TODO vary for debug
          // TODO inbox-style
        )));
    }
  }

  String _conversationKey(MessageFcmMessage data) {
    final groupKey = _groupKey(data);
    final conversation = switch (data) {
      // TODO stream messages
      MessageFcmMessage(:var pmUsers?) => 'group-dm:$pmUsers', // TODO
      MessageFcmMessage(:var senderId) => 'dm:$senderId',
    };
    return '$groupKey|$conversation';
  }

  String _groupKey(FcmMessageWithIdentity data) {
    // The realm URL can't contain a `|`, because `|` is not a URL code point:
    //   https://url.spec.whatwg.org/#url-code-points
    return "${data.realmUri}|${data.userId}";
  }

  void _ensureChannel() async { // TODO "ensure"
    final plugin = FlutterLocalNotificationsPlugin();
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

const _kNotificationId = 435;

const _kChannelId = 'messages-1';

/// The vibration pattern we set for notifications.
// We try to set a vibration pattern that, with the phone in one's pocket,
// is both distinctly present and distinctly different from the default.
// Discussion: https://chat.zulip.org/#narrow/stream/48-mobile/topic/notification.20vibration.20pattern/near/1284530
final _kVibrationPattern = Int64List.fromList([0, 125, 100, 450]);
