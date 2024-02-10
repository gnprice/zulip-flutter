import 'dart:async';

import 'package:checks/checks.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/backoff.dart';

sealed class Result<T> {
  const Result();
}

class SuccessResult<T> extends Result<T> {
  const SuccessResult(this.value);
  final T value;
}

class ErrorResult<T> extends Result<T> {
  const ErrorResult(this.error);
  final Object error;
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

Future<Duration> measureWait(Future<void> future) async {
  final start = clock.now();
  await future;
  return clock.now().difference(start);
}

void main() {
  test('FakeAsync scratch', () {
    const duration = Duration(milliseconds: 100);
    final actual = fakeAsyncBetter((binding) async {
      return await measureWait(Future.delayed(duration));
    });
    check(actual).equals(duration);
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
