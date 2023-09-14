// ignore_for_file: avoid_print
import 'dart:io';

Future<void> main() async {
  final checks = {
    AnalyzeCheck(),
    FlutterTestCheck(),
  };

  print('Running checks: ${checks.map((c) => c.name).join(' ')}');
  final futures = {
    for (final check in checks)
      check: check.check().then((result) => (check: check, result: result)),
  };

  List<String> failures = [];
  while (futures.isNotEmpty) {
    final r = await Future.any(futures.values);
    final (:check, :result) = r; // https://github.com/dart-lang/sdk/issues/52004
    futures.remove(check);
    if (result.failure != null) {
      print("${result.failure!.msg.substring(0, 100)}\n");
      failures.add(check.name);
    } else {
      print(r);
    }
  }

  if (failures.isNotEmpty) {
    print('FAILED: ${failures.join(' ')}');
    exit(1);
  } else {
    print('Passed!');
    exit(0);
  }
}

typedef CheckResult = ({CheckFailure? failure});

typedef CheckFailure = ({String msg});

abstract class Check {
  String get name;

  Future<CheckResult> check();
}

abstract class CommandCheck extends Check {
  List<String> checkCommand();

  @override
  Future<CheckResult> check() async {
    final command = checkCommand();
    print(command);
    final result = await Process.run(command[0], command.sublist(1));
    print('${result.exitCode} $command');
    if (result.exitCode != 0) {
      return (failure: (msg:
      // ignore: prefer_interpolation_to_compose_strings
      'error: suite failed: $name\n'
        'STDOUT ==================\n'
        '${result.stdout}\n'
        'STDERR ==================\n'
        '${result.stderr}\n'
        'end =====================\n'
      ));
    }
    return (failure: null);
  }
}

class AnalyzeCheck extends CommandCheck {
  @override
  String get name => 'analyze';

  @override
  List<String> checkCommand() => ['flutter', 'analyze'];
}

class FlutterTestCheck extends CommandCheck {
  @override
  String get name => 'flutter-test';

  @override
  List<String> checkCommand() => [
    'flutter', 'test',
    'test/',
    // 'test/widgets/message_list_test.dart',
    // '--name', 'dimension updates change',
  ];
}
