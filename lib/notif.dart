import 'package:firebase_messaging/firebase_messaging.dart';
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
    final result = await ZulipBinding.instance.firebaseMessaging.getToken(); // TODO(log) if null
    assert(debugLog("notif token: $result"));
    token.value = result;
  }

  void _onTokenRefresh(String value) {
    assert(debugLog("refreshed token: $value"));
    token.value = value;
  }
}
