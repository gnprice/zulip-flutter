import 'dart:math';

import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/main.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/widgets/app.dart';

import 'binding.dart';

void main() {
  PatrolLiveZulipBinding.ensureInitialized();
  mainInit();

  patrolTest('notification', ($) async {
    await patrolLiveBinding.reset();

    final globalStore = await ZulipBinding.instance.getGlobalStore();
    await globalStore.insertAccount(LiveCredentials.account().toCompanion(false));
    final account = globalStore.accounts.single;
    await globalStore.setLastVisitedAccount(account.id);

    await $.pumpWidget(ZulipApp());
    await $.waitUntilVisible($('Inbox'));

    if (await $.platform.mobile.isPermissionDialogVisible()) {
      await $.platform.mobile.grantPermissionWhenInUse();
    }

    final navigator = await ZulipApp.navigator;
    final context = navigator.context;
    if (!context.mounted) throw Error();
    final store = globalStore.getAccount(account.id)!;

    await Future<void>.delayed(Duration(milliseconds: 500));

    final token = Random().nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final content = 'hello $token';
    final otherConnection = LiveCredentials.makeOtherConnection();
    await sendMessage(otherConnection,
      destination: DmDestination(userIds: [store.userId]),
      content: content);

    await $.platform.mobile.openNotifications();
    // TODO poll? in a loop, with a timeout
    final notifs = await $.platform.mobile.getNotifications();
    check(notifs).isNotEmpty();

    await $.platform.mobile.tapOnNotificationByIndex(0);
    await $.waitUntilVisible($(RegExp(r'^DMs with')));
    check($(content)).findsOne();
  });
}
