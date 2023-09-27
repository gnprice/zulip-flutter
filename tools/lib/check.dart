// ignore_for_file: avoid_print
import 'dart:io';

Future<void> main() async {
  final checks = {
    AnalyzeCheck(),
    FlutterTestCheck(),
  };

  print('Running checks: ${checks.map((c) => c.name).join(' ')}');
  List<String> failures = [];
  for (final check in checks) {
    print("Running ${check.name}...");
    final result = await check.check();
    if (result.failure != null) {
      print("${result.failure!.msg}\n");
      failures.add(check.name);
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
    final process = await Process.start(command[0], command.sublist(1));
    process.stdout.pipe(stdout);
    process.stderr.pipe(stderr);
    print('awaiting...');
    final exitCode = await process.exitCode;
    print('$exitCode $command'); // ... this never gets reached!?
    if (exitCode != 0) {
      return (failure: (msg:
        'error: suite failed: $name'
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
