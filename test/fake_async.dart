import 'dart:async';

import 'package:fake_async/fake_async.dart';

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
  late final T value;
  Object? error;
  StackTrace? stackTrace;
  bool completed = false;
  FakeAsync(initialTime: initialTime)
    ..run((async) {
        callback(async).then<void>((v) { value = v; completed = true; },
          onError: (e, s) { error = e; stackTrace = s; completed = true; });
      })
    ..flushTimers();

  // TODO: if the future returned by [callback] completes with an error,
  //   it would be good to throw that error immediately rather than finish
  //   flushing timers.  (This probably requires [FakeAsync] to have a richer
  //   API, like a `fireNextTimer` that does one iteration of `flushTimers`.)
  //
  //   In particular, if flushing timers later causes an uncaught exception, the
  //   current behavior is that that uncaught exception gets printed first
  //   (while `flushTimers` is running), and then only later (after
  //   `flushTimers` has returned control to this function) do we throw the
  //   error that the [callback] future completed with.  That's confusing
  //   because it causes the exceptions to appear in test output in an order
  //   that's misleading about what actually happened.

  if (!completed) {
    throw TimeoutException(
      'A callback passed to awaitFakeAsync returned a Future that '
      'did not complete even after calling FakeAsync.flushTimers.');
  } else if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  } else {
    return value;
  }
}

Future<T> runFakeAsync<T>(Future<T> Function(FakeAsync async) callback,
    {DateTime? initialTime}) {
  final async = FakeAsync(initialTime: initialTime);

  // late final Future<T> resultFakeFuture;
  // async.run((async) => resultFakeFuture = callback(async));
  final resultFakeFuture = async.run(callback);
  print(resultFakeFuture);

  // cf [AutomatedTestWidgetsFlutterBinding.runTest]
  return Future.microtask(() async {
    final resultFuture = resultFakeFuture.then((v) => v);
    // resultFakeFuture.then((v) {}, onError: (e) {});
    // resultFuture.then((v) {}, onError: (e) {}); // TODO but why is this needed?
    print('runFakeAsync flushing');
    async.flushTimers();
    print('runFakeAsync returning');
    return resultFuture;
  });
}

// More notes:
// Issue about fake_async being confusing, closely related to that SO answer:
//   https://github.com/dart-lang/fake_async/issues/38
// And issue by natebosch that seems like the core of it:
//   https://github.com/dart-lang/fake_async/issues/24
// and another related issue:
//   https://github.com/dart-lang/fake_async/issues/43

/*
Draft new answer for https://stackoverflow.com/questions/62656200 :

The problem is that because the `await a` runs inside the zone set up by `FakeAsync.run`, the microtask that would run the rest of the function after that point is only a "fake" microtask belonging to the `FakeAsync` object, and the only way that those get run is by calling a method like `async.flushMicrotasks` or `async.elapse`.

Effectively I think this means that a callback passed to `FakeAsync().run(…)` (or, equivalently, to `fakeAsync`) should never use `await`.  When any function is going to call `await` in a `FakeAsync` context, there needs to be some other code that has a reference to that `FakeAsync` object and can call methods on it to get it to run its microtasks so that those `await`s can ever finish.

(And this isn't specific to the `await` syntax; similarly a `FakeAsync().run(…)` callback should never say `return foo.then(…)`, which is what a simple `await` desugars into, because the microtask set up by the `then` would never get run.)




Instead, any `await`s should happen inside some nested function, so that the outer callback can call methods on the `FakeAsync` to cause it to run its microtasks so that those `await`s can ever finish.  (And this isn't specific to the `await` syntax; similarly the outer callback should never say `return foo.then(…)`, which is what a simple `await` desugars into, because the microtask set up by the `then` would never get run.)




 — it's an element in the `Queue<void Function()>` data structure that is  _microtasks` on the `FakeAsync` object

 */
