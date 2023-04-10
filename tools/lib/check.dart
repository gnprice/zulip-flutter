// ignore_for_file: avoid_print
import 'dart:io';

Future<void> main() async {
  bool hadFailure = false;
  final result = await AnalyzeCheck().check();
  if (result.failure != null) {
    print(result.failure!.msg);
    hadFailure = true;
  }
  exit(hadFailure ? 1 : 0);
}

typedef CheckResult = ({CheckFailure? failure});

typedef CheckFailure = ({String msg});

abstract class Check {
  String get name;

  Future<CheckResult> check();
}

class AnalyzeCheck extends Check {
  @override
  String get name => 'analyze';

  @override
  Future<CheckResult> check() async {
    final result = await Process.run('flutter', ['analyze']);
    if (result.exitCode != 0) {
      return (failure: (msg:
      // ignore: prefer_interpolation_to_compose_strings
      'error: flutter analyze failed\n'
          + result.stdout
          + result.stderr
      ));
    }
    return (failure: null);
  }
}
