import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

void main() {
  final file = File('test/model/content_test.dart'); // TODO
  final text = file.readAsStringSync();
  final parsed = parseString(content: text);

  final examples = [];
  final contentExampleClass = parsed.unit.declarations.firstWhere(
    (decl) => decl is ClassDeclaration && decl.name.value() == 'ContentExample'
  ) as ClassDeclaration;
  for (final member in contentExampleClass.members) {
    if (member is! FieldDeclaration) continue;
    if (!member.isStatic) continue;
    for (final decl in member.fields.variables) {
      if (decl.initializer case MethodInvocation(
            methodName: SimpleIdentifier(name: 'ContentExample'))) {
        examples.add(decl.name.value());
      }
    }
  }

  final testedExamples = findTestedExamples(parsed.unit);

  print(examples);
  print(testedExamples);
}

List<String> findTestedExamples(CompilationUnit unit) {
  final examples = <String>[];
  final mainFunction = unit.declarations.firstWhere(
    (decl) => decl is FunctionDeclaration && decl.name.value() == 'main'
  ) as FunctionDeclaration;
  final mainBody = mainFunction.functionExpression.body as BlockFunctionBody;
  _findTestedExamplesInBlock(examples, mainBody.block);
  return examples;
}

void _findTestedExamplesInBlock(List<String> results, Block block) {
  for (final statement in block.statements) {
    if (statement case ExpressionStatement(expression: MethodInvocation(
          methodName: SimpleIdentifier(name: 'testParseExample'),
          argumentList: ArgumentList(arguments: [
            PrefixedIdentifier(
              prefix: SimpleIdentifier(name: 'ContentExample'),
              identifier: SimpleIdentifier(:final name)),
          ])))) {
      results.add(name);
    } else if (statement case ExpressionStatement(expression: MethodInvocation(
          methodName: SimpleIdentifier(name: 'group'),
          argumentList: ArgumentList(arguments: [
            StringLiteral(),
            FunctionExpression(body: BlockFunctionBody(block: final groupBlock)),
          ])))) {
      _findTestedExamplesInBlock(results, groupBlock);
    }
  }
}
