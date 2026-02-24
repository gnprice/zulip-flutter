---
name: patrol-screenshot
description: Inspect a piece of the app's UI by writing a Patrol live test that navigates to it, then taking a screenshot from the Android emulator.
allowed-tools: Bash(patrol *), Bash(adb *), Read, Write, Edit, Glob, Grep
---

# Patrol Screenshot

Write and run a Patrol live test that navigates to a specific part of the
app's UI, then capture a screenshot with `adb` to inspect it.

## Arguments

$ARGUMENTS — a description of what UI to navigate to and screenshot.

## Steps

### 1. Write the Patrol live test

Create or edit a test file in `patrol_test/live/`. Follow this template:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:zulip/widgets/app.dart';

import 'binding.dart';

void main() {
  PatrolLiveZulipBinding.ensureInitialized();

  patrolTest('navigate to ...', ($) async {
    await patrolLiveBinding.reset();
    await patrolLiveBinding.addAccount(LiveCredentials.account());

    await $.pumpWidget(ZulipApp());
    await $.waitUntilVisible($('Inbox'));

    // Navigate to the target UI...

    // Pause so we can take a screenshot with adb.
    await Future<void>.delayed(Duration(seconds: 90));
  });
}
```

Key points:
- Do NOT call `mainInit()` — it's not needed and causes a notification
  permission dialog.
- Use `PatrolLiveZulipBinding`, not `TestZulipBinding` or
  `SemiLiveZulipBinding`.
- Use `LiveCredentials.account()` to log in with env-var credentials
  (from `.patrol.env`).
- Use Patrol selectors like `$('button text')` to tap and navigate.
- End with `Future.delayed(Duration(seconds: 90))` to keep the app open
  long enough for the screenshot. (The build + launch + navigation takes
  ~40-50 seconds, so you need a generous pause.)

### 2. Run the test in background

```
patrol test -d emulator-5554 -t patrol_test/live/the_test.dart
```

Run this command in the background so you can take the screenshot while
the test is paused.

**Important**: Both `patrol` and `adb` commands require
`dangerouslyDisableSandbox: true` because `patrol` writes to the Flutter
cache and `adb` needs device access.

### 3. Wait, then capture the screenshot

Wait about 60 seconds for the test to build, launch, and navigate.
Then capture with:

```
adb shell screencap -p > /tmp/claude-1000/screenshot.png
```

Read the resulting PNG file to inspect the UI.

**Timing tip**: Monitor the background task output to see when the test
reaches the `Future.delayed` pause (all navigation steps will show ✅),
then take the screenshot. Don't rely on a fixed sleep — if you sleep too
long, the pause expires and you'll screenshot the Android home screen.

### 4. Clean up

After confirming the screenshot, remove the `Future.delayed` pause from
the test (or remove the test file if it was one-off).

## Reference

See existing live Patrol tests in `patrol_test/live/` for more patterns
(login flow, sending messages, interacting with notifications).
