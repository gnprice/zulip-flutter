import 'dart:async';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/backoff.dart';

Future<Duration> measureWait(Future<void> future) async {
  final start = clock.now();
  await future;
  return clock.now().difference(start);
}

Future<void> delayed(Duration duration) {
  final completer = Completer<void>();
  Timer(duration, () {
    completer.complete();
  });
  return completer.future;
}

sealed class Result<T> {}

class SuccessResult<T> extends Result<T> {
  final T value;
  SuccessResult(this.value);
}

class ErrorResult<T> extends Result<T> {
  Object error;
  ErrorResult(this.error);
}

T fakeAsyncBetter<T>(Future<T> Function(FakeAsync) callback) {
  // cf https://stackoverflow.com/a/62676919
  return fakeAsync((binding) {
    Result<T>? result;
    (() async {
      try {
        final value = await callback(binding);
        result = SuccessResult(value);
      } catch (e) {
        result = ErrorResult(e);
      }
    })();
    while (result == null) {
      binding.flushTimers();
    }
    switch (result!) {
      case SuccessResult(:var value): return value;
      case ErrorResult(:var error): throw error;
    }
  });
}

void main() {
  test('FakeAsync scratch', () {
    final result = fakeAsyncBetter((binding) async {
      print('${clock.now()} hi');

      final delay = delayed(Duration(milliseconds: 100));
      // final delay = Future.delayed(Duration(milliseconds: 100));
      print('${clock.now()} future made');
      print(binding.pendingTimers);

      // binding.flushTimers();
      // print('${clock.now()} flushed');
      // print(binding.pendingTimersDebugString);

      print(await measureWait(delay));
      // await delay;
      print('${clock.now()} awaited');

      return 1 + 1;
    });
    print(result);

    return;
  });

  test('BackoffMachine timeouts are random from zero to 100ms, 200ms, 400ms, ...', () {
    // This is a randomized test.  [numTrials] is chosen so that the failure
    // probability < 1e-9.  There are 2 * 11 assertions, and each one has a
    // failure probability < 1e-12; see below.
    const numTrials = 100;
    final expectedMaxDurations = [
      100, 200, 400, 800, 1600, 3200, 6400, 10000, 10000, 10000, 10000,
    ].map((ms) => Duration(milliseconds: ms)).toList();

    final trialResults = <List<Duration>>[];
    for (int i = 0; i < numTrials; i++) {
      final resultsForThisTrial = <Duration>[];
      fakeAsyncBetter((binding) async {
        final backoffMachine = BackoffMachine();
        for (int j = 0; j < expectedMaxDurations.length; j++) {
          final duration = await measureWait(backoffMachine.wait());
          resultsForThisTrial.add(duration);
        }
      });
      trialResults.add(resultsForThisTrial);
    }

    for (int j = 0; j < expectedMaxDurations.length; j++) {
      Duration maxFromAllTrials = trialResults[0][j];
      Duration minFromAllTrials = trialResults[0][j];
      for (final singleTrial in trialResults.skip(1)) {
        final t = singleTrial[j];
        maxFromAllTrials = t > maxFromAllTrials ? t : maxFromAllTrials;
        minFromAllTrials = t < minFromAllTrials ? t : minFromAllTrials;
      }

      final expectedMax = expectedMaxDurations[j];
      // Each of these assertions has a failure probability of:
      //     pow(0.75, numTrials) = pow(0.75, 100) < 1e-12
      check(minFromAllTrials).isLessThan(   expectedMax * 0.25);
      check(maxFromAllTrials).isGreaterThan(expectedMax * 0.75);
    }
  });
}
