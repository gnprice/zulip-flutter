import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notifications/receive.dart';
import 'widgets/app.dart';

void main() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  PlatformDispatcher.instance.onError = zulipPlatformDispatcherOnError;
  LicenseRegistry.addLicense(additionalLicenses);
  WidgetsFlutterBinding.ensureInitialized();
  LiveZulipBinding.ensureInitialized();
  NotificationService.instance.start();
  runApp(const ZulipApp());
}
