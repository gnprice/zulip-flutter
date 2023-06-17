import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'model/binding.dart';

class NotificationService {
  static NotificationService get instance => (_instance ??= NotificationService._());
  static NotificationService? _instance;

  NotificationService._();

  void start() async {
    await ZulipBinding.instance.firebaseInitializeApp();
    _getToken();
  }

  ValueNotifier<String?> token = ValueNotifier(null);

  Future<void> _getToken() async {
    final result = await ZulipBinding.instance.firebaseMessaging.getToken(); // TODO(log) if null
    print("notif token: $result");
    token.value = result;
  }
}
