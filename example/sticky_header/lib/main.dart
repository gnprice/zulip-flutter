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
                  onPressed: () => ExampleDown.navigate(context),
                  child: const Text(ExampleDown.title))),
          Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: ElevatedButton(
                  onPressed: () => ExampleUp.navigate(context),
                  child: const Text(ExampleUp.title))),
          Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: ElevatedButton(
                  onPressed: () => ExampleHorizontal.navigate(context),
                  child: const Text(ExampleHorizontal.title))),
          Container(
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              child: ElevatedButton(
                  onPressed: () => ExampleHorizontalReverse.navigate(context),
                  child: const Text(ExampleHorizontalReverse.title))),
        ]));
  }
}

class ExampleDown extends StatelessWidget {
  const ExampleDown({super.key});

  static const title = 'Standard list orientation';

  static navigate(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const ExampleDown()));
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

class ExampleUp extends StatelessWidget {
  const ExampleUp({super.key});

  static const title = 'Reversed list';

  static navigate(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ExampleUp()));
  }

  @override
  Widget build(BuildContext context) {
    const numSections = 100;
    const numPerSection = 10;
    return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: StickyHeaderListView.separated(
            reverse: true,
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

class ExampleHorizontal extends StatelessWidget {
  const ExampleHorizontal({super.key});

  static const title = 'Horizontal list';

  static navigate(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ExampleHorizontal()));
  }

  static const numSections = 100;
  static const lengthPeriod = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: numSections,
            separatorBuilder: (context, i) => const SizedBox.shrink(),
            itemBuilder: (context, i) => Container(
                alignment: Alignment.center,
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildItemContents(context, i))))));
  }

  Widget _buildItemContents(BuildContext context, int i) {
    return Column(children: [
      Text("Item ${i + 1}"),
      const SizedBox(height: 8),
      Expanded(
          child: FractionallySizedBox(
              heightFactor: (1 + (i % lengthPeriod) / (lengthPeriod - 1)) / 2.0,
              child: ColoredBox(
                  color: Theme.of(context).colorScheme.secondary,
                  child: const SizedBox(width: 4)))),
      const SizedBox(height: 8),
      const Text("end"),
    ]);
  }
}

class ExampleHorizontalReverse extends StatelessWidget {
  const ExampleHorizontalReverse({super.key});

  static const title = 'Horizontal reverse list';

  static navigate(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ExampleHorizontalReverse()));
  }

  static const numSections = 100;
  static const lengthPeriod = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text(title)),
        body: ListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: numSections,
            separatorBuilder: (context, i) => const SizedBox.shrink(),
            itemBuilder: (context, i) => Container(
                alignment: Alignment.center,
                child: Card(
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildItemContents(context, i))))));
  }

  Widget _buildItemContents(BuildContext context, int i) {
    return Column(children: [
      Text("Item ${i + 1}"),
      const SizedBox(height: 8),
      Expanded(
          child: FractionallySizedBox(
              heightFactor: (1 + (i % lengthPeriod) / (lengthPeriod - 1)) / 2.0,
              child: ColoredBox(
                  color: Theme.of(context).colorScheme.secondary,
                  child: const SizedBox(width: 4)))),
      const SizedBox(height: 8),
      const Text("end"),
    ]);
  }
}
