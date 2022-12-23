import 'package:flutter/material.dart';
import 'package:zulip/widgets/sticky_header.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sticky Headers example',
      theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: const Color(0xff3366cc))),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Sticky Headers example')),
        body: ListView(children: [
          Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: ElevatedButton(
                  onPressed: () => ExampleDownForward.navigate(context),
                  child: const Text(ExampleDownForward.title)))
        ]));
  }
}

class ExampleDownForward extends StatelessWidget {
  const ExampleDownForward({super.key});

  static const title = 'Standard list orientation';

  static navigate(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ExampleDownForward()));
  }

  @override
  Widget build(BuildContext context) {
    const numSections = 100;
    const numPerSection = 10;
    return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: StickyHeaderListView.separated(
            itemCount: numSections,
            separatorBuilder: (context, i) => const SizedBox.shrink(),
            itemBuilder: (context, i) => StickyHeader(
                header: Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                        title: Text("Section ${i + 1}",
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer)))),
                content: Column(
                    children: List.generate(
                        numPerSection,
                        (j) => ListTile(
                            title: Text("Item ${i + 1}.${j + 1}")))))));
  }
}
