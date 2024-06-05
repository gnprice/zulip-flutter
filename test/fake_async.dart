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

  final async = FakeAsync(initialTime: initialTime);
  async.run((async) {
    callback(async).then<void>((v) { value = v; completed = true; },
      onError: (Object? e, StackTrace? s) { error = e; stackTrace = s; completed = true; });
  });

  const timeout = Duration(hours: 1);
  final absoluteTimeout = async.elapsed + timeout;
  while (async.runNextTimer(timeout: absoluteTimeout - async.elapsed)) {
    if (error != null) {
      Error.throwWithStackTrace(error!, stackTrace!);
    }
  }

  if (!completed) {
    throw TimeoutException(
      'A callback passed to awaitFakeAsync returned a Future that '
      'did not complete within timeout $timeout.');
  } else if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  } else {
    return value;
  }
}
