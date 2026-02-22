# Getting UI Screenshots via Live Patrol Tests

## Goal

Write a live Patrol test that navigates to a specific piece of the UI,
then capture a screenshot with `adb` while the test holds the screen open.

## Prerequisites

- An Android emulator running (e.g. `emulator-5554`).
- A `.patrol.env` file at the project root with login credentials:
  ```
  REALM_URL=https://chat.example.com
  EMAIL=user@example.com
  PASSWORD=hunter2
  ```
- Patrol CLI installed (`flutter pub global activate patrol_cli`).

## Writing the test

Create a file in `patrol_test/`, e.g. `patrol_test/my_screenshot_test.dart`.
Use this template:

```dart
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

  patrolTest('navigate to <destination>', ($) async {
    addTearDown(ZulipApp.debugReset);
    await $.pumpWidget(ZulipApp());

    // --- Login boilerplate (required for live tests) ---
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
    // --- End login boilerplate ---

    // Navigate to the target UI.
    // Examples:
    //   await $.tap($('Combined feed'));
    //   await $.tap($('Channels'));
    //   await $.tap($('Direct messages'));
    //   // Or open the menu and tap an item:
    //   await $.tap($('Menu'));
    //   await $.tap($('Starred messages'));

    // Hold the screen open for the screenshot.
    await Future<void>.delayed(Duration(seconds: 30));
  });
}
```

### Key points

- **Login is required**: Patrol reinstalls the app fresh each run, so
  there is no saved login state. Every live test must log in first.
- **Single test**: Put login and navigation in the same `patrolTest`.
  Splitting into separate `patrolTest` calls doesn't reliably transfer
  state — the second test may fail to find "Inbox".
- **`pumpWidget` not `pumpWidgetAndSettle`**: Use `$.pumpWidget(ZulipApp())`
  for the initial pump. The app loads data asynchronously from a real
  server, so `pumpWidgetAndSettle` may not behave as expected.
- **Permission dialog**: Always include the `isPermissionDialogVisible` /
  `grantPermissionWhenInUse` check after the first screen appears.
- **Generous timeouts**: Use `timeout: Duration(seconds: 30)` on
  `waitUntilVisible` calls that depend on server responses.
- **Hold the screen**: End the test with a `Future.delayed` of ~30 seconds
  to keep the UI visible while you capture the screenshot externally.

### Navigation targets from the home page

The bottom navigation bar has these items (use their label text with `$.tap`):
- `'Inbox'` — already visible after login (it's a tab, not a navigation)
- `'Combined feed'` — pushes a new route with the message list
- `'Channels'` — tab on the home page
- `'Direct messages'` — tab on the home page
- `'Menu'` — opens the main menu drawer

After tapping `'Menu'`, these items are available:
- `'Inbox'`, `'Mentions'`, `'Starred messages'`, `'Combined feed'`,
  `'Channels'`, `'Direct messages'`, `'My profile'`, `'Settings'`,
  `'About Zulip'`

## Running the test and capturing the screenshot

### Step 1: Run the analyzer

Always check for errors before running:
```
flutter analyze --no-pub
```

### Step 2: Run the test in the background

```
patrol test -t patrol_test/my_screenshot_test.dart -d emulator-5554 &
```

### Step 3: Capture the screenshot

The build takes ~12s and login + navigation takes ~12s, so the UI is
typically ready ~25s after starting the command. Wait, then capture:

```
sleep 40 && adb shell screencap -p > /tmp/screenshot.png
```

Adjust the sleep duration based on how long your navigation takes.
The test's 30-second delay at the end gives a wide window to capture.

### Timing tips

- Build phase: ~12s (shorter on incremental rebuilds)
- Test execution up to "Inbox" visible: ~10s
- Additional navigation steps: a few seconds each
- Total from command start to UI ready: typically 25-35s
- The 30s delay at the end of the test gives you until ~55-65s
