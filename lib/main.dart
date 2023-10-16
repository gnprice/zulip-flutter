import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'licenses.dart';
import 'log.dart';
import 'model/binding.dart';
import 'notif.dart';
import 'widgets/app.dart';

void main() {
  assert(() {
    debugLogEnabled = true;
    return true;
  }());
  LicenseRegistry.addLicense(additionalLicenses);
  LiveZulipBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.instance.start();
  runApp(const ZulipApp());
}
