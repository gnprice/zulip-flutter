import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../model/localizations.dart';
import '../model/narrow.dart';
import 'about_zulip.dart';
import 'login.dart';
import 'message_list.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ZulipApp extends StatelessWidget {
  const ZulipApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      // This sets up the font fallback for normal text that
      // may contain an emoji, where it will use any font from the "sans-serif"
      // group to fetch the glyphs and fallback to "Noto Color Emoji" for emojis.
      //
      // Note that specifiying only "Noto Color Emoji" in the fallback list,
      // Flutter tries to use it to draw even the non emoji characters
      // which leads to broken text rendering.
      fontFamilyFallback: [
        // …since apparently iOS doesn't support 'sans-serif', use this instead:
        //   https://github.com/flutter/flutter/issues/63507#issuecomment-1698504425
        if (Theme.of(context).platform == TargetPlatform.iOS) '.AppleSystemUIFont' else 'sans-serif',
        'Noto Color Emoji',
      ],
      useMaterial3: false, // TODO(#225) fix things and switch to true
      // This applies Material 3's color system to produce a palette of
      // appropriately matching and contrasting colors for use in a UI.
      // The Zulip brand color is a starting point, but doesn't end up as
      // one that's directly used.  (After all, we didn't design it for that
      // purpose; we designed a logo.)  See docs:
      //   https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
      // Or try this tool to see the whole palette:
      //   https://m3.material.io/theme-builder#/custom
      colorScheme: ColorScheme.fromSeed(seedColor: kZulipBrandColor),
      // `preferBelow: false` seems like a better default for mobile;
      // the area below a long-press target seems more likely to be hidden by
      // a finger or thumb than the area above.
      tooltipTheme: const TooltipThemeData(preferBelow: false),
    );
    return GlobalStoreWidget(
      child: MaterialApp(
        title: 'Zulip',
        localizationsDelegates: ZulipLocalizations.localizationsDelegates,
        supportedLocales: ZulipLocalizations.supportedLocales,
        theme: theme,
        navigatorKey: navigatorKey,
        builder: (BuildContext context, Widget? child) {
          GlobalLocalizations.zulipLocalizations = ZulipLocalizations.of(context);
          return child!;
        },
        home: const ChooseAccountPage()));
  }
}

/// The Zulip "brand color", a purplish blue.
///
/// This is chosen as the sRGB midpoint of the Zulip logo's gradient.
// As computed by Anders: https://github.com/zulip/zulip-mobile/pull/4467
const kZulipBrandColor = Color.fromRGBO(0x64, 0x92, 0xfe, 1);

class ChooseAccountPage extends StatelessWidget {
  const ChooseAccountPage({super.key});

  Widget _buildAccountItem(
    BuildContext context, {
    required int accountId,
    required Widget title,
    Widget? subtitle,
  }) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        onTap: () => Navigator.push(context,
          HomePage.buildRoute(accountId: accountId))));
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    assert(!PerAccountStoreWidget.debugExistsOf(context));
    final globalStore = GlobalStoreWidget.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.chooseAccountPageTitle),
        actions: const [ChooseAccountPageOverflowButton()]),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final (:accountId, :account) in globalStore.accountEntries)
                _buildAccountItem(context,
                  accountId: accountId,
                  title: Text(account.realmUrl.toString()),
                  subtitle: Text(account.email)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                  AddAccountPage.buildRoute()),
                child: Text(zulipLocalizations.chooseAccountButtonAddAnAccount)),
            ]))),
      ));
  }
}

enum ChooseAccountPageOverflowMenuItem { aboutZulip }

class ChooseAccountPageOverflowButton extends StatelessWidget {
  const ChooseAccountPageOverflowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ChooseAccountPageOverflowMenuItem>(
      itemBuilder: (BuildContext context) => const [
        PopupMenuItem(
          value: ChooseAccountPageOverflowMenuItem.aboutZulip,
          child: Text('About Zulip')),
      ],
      onSelected: (item) {
        switch (item) {
          case ChooseAccountPageOverflowMenuItem.aboutZulip:
            Navigator.push(context, AboutZulipPage.buildRoute(context));
        }
      });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static Route<void> buildRoute({required int accountId}) {
    return MaterialWidgetRoute(
      page: PerAccountStoreWidget(accountId: accountId,
        child: const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    InlineSpan bold(String text) => TextSpan(
      text: text, style: const TextStyle(fontWeight: FontWeight.bold));

    int? testStreamId;
    if (store.connection.realmUrl.origin == 'https://chat.zulip.org') {
      testStreamId = 7; // i.e. `#test here`; TODO cut this scaffolding hack
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 18),
            child: Column(children: [
              const Text('🚧 Under construction 🚧'),
              const SizedBox(height: 12),
              Text.rich(TextSpan(
                text: 'Connected to: ',
                children: [bold(store.account.realmUrl.toString())])),
              Text.rich(TextSpan(
                text: 'Zulip server version: ',
                children: [bold(store.zulipVersion)])),
              Text(zulipLocalizations.subscribedToNStreams(store.subscriptions.length)),
            ])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              MessageListPage.buildRoute(context: context,
                narrow: const AllMessagesNarrow())),
            child: const Text("All messages")),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
              RecentDmConversationsPage.buildRoute(context: context)),
            child: const Text("Direct messages")),
          if (testStreamId != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                MessageListPage.buildRoute(context: context,
                  narrow: StreamNarrow(testStreamId!))),
              child: const Text("#test here")), // scaffolding hack, see above
          ],
        ])));
  }
}
