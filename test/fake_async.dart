import 'dart:async';

import 'package:fake_async/fake_async.dart';

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
