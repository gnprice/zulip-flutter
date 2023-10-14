import 'package:flutter/foundation.dart';

import 'log.dart';
import 'model/binding.dart';

class NotificationService {
  static NotificationService get instance => (_instance ??= NotificationService._());
  static NotificationService? _instance;

  NotificationService._();

  void start() async {
    await ZulipBinding.instance.firebaseInitializeApp();
    ZulipBinding.instance.firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
    _getToken();
  }

  ValueNotifier<String?> token = ValueNotifier(null);

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
}
