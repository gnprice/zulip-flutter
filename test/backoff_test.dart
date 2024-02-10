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

/// Run [callback] to completion in a [Zone] where all asynchrony is
/// controlled by an instance of [FakeAsync].
///
/// See [FakeAsync.run] for details on what it means that all asynchrony is
/// controlled by an instance of [FakeAsync].
///
/// After calling [callback], this function uses [FakeAsync.flushTimers] to
/// advance the computation started by [callback], and then expects the
/// [Future] that was returned by [callback] to have completed.
///
/// If that future completed with a value, that value is returned.
/// If it completed with an error, that error is thrown.
/// If it hasn't completed, a [TimeoutException] is thrown.
T awaitFakeAsync<T>(Future<T> Function(FakeAsync async) callback,
    {DateTime? initialTime}) {
  // cf dantup's https://stackoverflow.com/a/62676919

  Result<T>? result;
  FakeAsync(initialTime: initialTime)
    ..run((async) {
        callback(async)
          .then<void>((value) => result = SuccessResult(value))
          .catchError((error) => result = ErrorResult(error));
      })
    ..flushTimers();

  switch (result) {
    case SuccessResult(:var value): return value;
    case ErrorResult(:var error): throw error;
    case null: throw TimeoutException(
      'A callback passed to awaitFakeAsync returned a Future that '
      'did not complete even after calling FakeAsync.flushTimers.');
  }
}

Future<Duration> measureWait(Future<void> future) async {
  final start = clock.now();
  await future;
  return clock.now().difference(start);
}

void main() {
  group('awaitFakeAsync', () {
    test('basic success', () {
      const duration = Duration(milliseconds: 100);
      check(awaitFakeAsync((async) async {
        return await measureWait(Future.delayed(duration));
      })).equals(duration);
    });

    test('TimeoutException on deadlocked callback', () {
      check(() => awaitFakeAsync((async) async {
        await Completer().future;
      })).throws().isA<TimeoutException>();
    });
  });

  test('BackoffMachine timeouts are random from zero to 100ms, 200ms, 400ms, ...', () {
    // This is a randomized test.  [numTrials] is chosen so that the failure
    // probability < 1e-9.  There are 2 * 11 assertions, and each one has a
    // failure probability < 1e-12; see below.
    const numTrials = 100;
    final expectedMaxDurations = [
      100, 200, 400, 800, 1600, 3200, 6400, 10000, 10000, 10000, 10000,
    ].map((ms) => Duration(milliseconds: ms)).toList();

    final trialResults = List.generate(numTrials, (_) =>
      awaitFakeAsync((async) async {
        final backoffMachine = BackoffMachine();
        final results = <Duration>[];
        for (int i = 0; i < expectedMaxDurations.length; i++) {
          final duration = await measureWait(backoffMachine.wait());
          results.add(duration);
        }
        return results;
      }));

    for (int i = 0; i < expectedMaxDurations.length; i++) {
      Duration maxFromAllTrials = trialResults[0][i];
      Duration minFromAllTrials = trialResults[0][i];
      for (final singleTrial in trialResults.skip(1)) {
        final t = singleTrial[i];
        maxFromAllTrials = t > maxFromAllTrials ? t : maxFromAllTrials;
        minFromAllTrials = t < minFromAllTrials ? t : minFromAllTrials;
      }

      final expectedMax = expectedMaxDurations[i];
      // Each of these assertions has a failure probability of:
      //     pow(0.75, numTrials) = pow(0.75, 100) < 1e-12
      check(minFromAllTrials).isLessThan(   expectedMax * 0.25);
      check(maxFromAllTrials).isGreaterThan(expectedMax * 0.75);
    }
  });
}
