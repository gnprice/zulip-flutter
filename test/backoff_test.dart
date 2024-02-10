import 'package:checks/checks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/scaffolding.dart';
import 'package:zulip/backoff.dart';

Future<Duration> measureWait(Future<void> future) async {
  final start = DateTime.now();
  print('    measure: started $start');
  await future;
  print('    measure: done');
  return DateTime.now().difference(start);
}

void main() {
  test('FakeAsync scratch', () async {
    await fakeAsync((binding) async {
      print('${DateTime.now()} ${} hi');

      final delay = Future.delayed(Duration(milliseconds: 100));
      print('${DateTime.now()} future made');
      print(binding.pendingTimersDebugString);

      binding.flushTimers();
      print('${DateTime.now()} flushed');
      print(binding.pendingTimersDebugString);

      await delay;
      print('${DateTime.now()} awaited');
    });
  });

  test('BackoffMachine timeouts are random from zero to 100ms, 200ms, 400ms, ...', () async {
    // This is a randomized test.  [numTrials] is chosen so that the failure
    // probability < 1e-9.  There are 2 * 11 assertions, and each one has a
    // failure probability < 1e-12; see below.
    const numTrials = 3; //100;
    final expectedMaxDurations = [
      100, // 200, 400, 800, 1600, 3200, 6400, 10000, 10000, 10000, 10000,
    ].map((ms) => Duration(milliseconds: ms)).toList();

    final trialResults = <List<Duration>>[];
    for (int i = 0; i < numTrials; i++) {
      final resultsForThisTrial = <Duration>[];
      await fakeAsync((binding) async {
        print('start $i');
        final backoffMachine = BackoffMachine();
        print('have backoffMachine');
        for (int j = 0; j < expectedMaxDurations.length; j++) {
          print('  step $j');
          final duration = await measureWait(backoffMachine.wait());
          print('  -> $duration');
          resultsForThisTrial.add(duration);
        }
      });
      trialResults.add(resultsForThisTrial);
    }
    print(trialResults.map((r) => r[0].inMilliseconds).toList()..sort());

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
