// ignore_for_file: avoid_print
import 'dart:io';

Future<void> main() async {
  final result = await Process.run('flutter', ['analyze']);
  if (result.exitCode != 0) {
    print("error: flutter analyze failed");
    print(result.stdout);
    print(result.stderr);
  }
}
