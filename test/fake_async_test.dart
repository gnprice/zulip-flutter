import 'dart:async';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:test/scaffolding.dart';

import 'fake_async.dart';

void main() {
  group('awaitFakeAsync', () {
    test('basic success', () {
      const duration = Duration(milliseconds: 100);
      check(awaitFakeAsync((async) async {
        final start = clock.now();
        await Future.delayed(duration);
        return clock.now().difference(start);
      })).equals(duration);
    });

    test('TimeoutException on deadlocked callback', () {
      check(() => awaitFakeAsync((async) async {
        await Completer().future;
      })).throws().isA<TimeoutException>();
    });
  });
}
