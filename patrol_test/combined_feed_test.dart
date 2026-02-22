// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/main.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/widgets/app.dart';

void main() {
  mainInit();
  ZulipBinding.instance.debugRelaxGetGlobalStoreUniquely = true;

  patrolTest('navigate to combined feed', ($) async {
    addTearDown(ZulipApp.debugReset);
    await $.pumpWidget(ZulipApp());

    // Log in.
    await $.waitUntilVisible($('Choose account'));

    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    await $.tap($('Add an account'));

    await $(TextField).enterText(const String.fromEnvironment('REALM_URL'));
    await $.tap($('Continue'));

    final findUsernameInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.email));
    final findPasswordInput = find.byWidgetPredicate((widget) =>
      widget is TextField
      && (widget.autofillHints ?? []).contains(AutofillHints.password));
    await $(findUsernameInput).enterText(const String.fromEnvironment('EMAIL'));
    await $(findPasswordInput).enterText(const String.fromEnvironment('PASSWORD'));
    await $.tap($(find.widgetWithText(ElevatedButton, 'Log in')));

    // Wait for home page to load after login.
    await $.waitUntilVisible($('Inbox'), timeout: Duration(seconds: 30));

    // Navigate to combined feed.
    await $.tap($('Combined feed'));

    // Wait for the message list to load.
    await Future<void>.delayed(Duration(seconds: 3));
  });
}
