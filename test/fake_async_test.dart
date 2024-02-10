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

  group('runFakeAsync', () {
    test('basic success', () async {
      const duration = Duration(milliseconds: 100);
      await check(runFakeAsync((async) async {
        final start = clock.now();
        await Future.delayed(duration);
        return clock.now().difference(start);
      })).completes((it) => it.equals(duration));
    });

    test('exceptions propagate', () async {
      Object? error;
      try {
        await runFakeAsync((async) async {
          throw StateError('something wrong');
        });
      } catch (e) {
        error = e;
      }
      check(error).isA<StateError>();

      // await check(runFakeAsync((async) async {
      //   // await null;
      //   throw StateError('something wrong');
      // })).throws((it) => it.isA<StateError>());

      // await check(runFakeAsync((async) async {
      //   throw StateError('something wrong');
      // })).throws((it) => it.isA<StateError>());
    });

    test('deadlocked callback never completes', () {
      check(runFakeAsync((async) async {
        await Completer().future;
      })).doesNotComplete();
    });
  });
}
