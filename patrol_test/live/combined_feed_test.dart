import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/widgets/app.dart';

import 'binding.dart';

void main() {
  PatrolLiveZulipBinding.ensureInitialized();

  patrolTest('navigate to combined feed', ($) async {
    await patrolLiveBinding.reset();
    await patrolLiveBinding.addAccount(LiveCredentials.account());

    await $.pumpWidget(ZulipApp());
    await $.waitUntilVisible($('Inbox'));

    // Navigate to combined feed.
    await $.tap($('Combined feed'));

    // Wait for the message list to load.
    await Future<void>.delayed(Duration(seconds: 3));
  });
}
