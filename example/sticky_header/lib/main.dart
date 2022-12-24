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
    var items = [
      _buildItem(context, 'Standard list orientation',
          ExampleVertical(title: 'Standard list orientation')),
      _buildItem(context, 'Reversed list',
          ExampleVertical(title: 'Reversed list', reverse: true)),
      _buildItem(
          context,
          'Horizontal list',
          ExampleHorizontal(
              title: 'Horizontal list', headerDirection: AxisDirection.right)),
      _buildItem(
          context,
          'Horizontal reverse list',
          ExampleHorizontal(
              title: 'Horizontal reverse list',
              reverse: true,
              headerDirection: AxisDirection.right)),
    ];
    return Scaffold(
        appBar: AppBar(title: const Text('Sticky Headers example')),
        body: ListView(children: items));
  }

  Widget _buildItem(BuildContext context, String title, Widget page) {
    return Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: ElevatedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => page)),
            child: Text(title)));
  }
}

class ExampleVertical extends StatelessWidget {
  ExampleVertical(
      {super.key,
      required this.title,
      this.reverse = false,
      this.headerDirection = AxisDirection.down})
      : assert(axisDirectionToAxis(headerDirection) == Axis.vertical);

  final String title;
  final bool reverse;
  final AxisDirection headerDirection;

  @override
  Widget build(BuildContext context) {
    const numSections = 100;
    const numPerSection = 10;
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: StickyHeaderListView.separated(
            reverse: reverse,
            itemCount: numSections,
            separatorBuilder: (context, i) => const SizedBox.shrink(),
            itemBuilder: (context, i) => StickyHeader(
                direction: headerDirection,
                header: WideHeader(i: i),
                content: Column(
                    children: List.generate(
                        numPerSection, (j) => WideItem(i: i, j: j))))));
  }
}

class WideHeader extends StatelessWidget {
  const WideHeader({super.key, required this.i});

  final int i;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: ListTile(
            title: Text("Section ${i + 1}",
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer))));
  }
}

class WideItem extends StatelessWidget {
  const WideItem({super.key, required this.i, required this.j});

  final int i;
  final int j;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text("Item ${i + 1}.${j + 1}"));
  }
}

class ExampleHorizontal extends StatelessWidget {
  ExampleHorizontal(
      {super.key,
      required this.title,
      this.reverse = false,
      required this.headerDirection})
      : assert(axisDirectionToAxis(headerDirection) == Axis.horizontal);

  final String title;
  final bool reverse;
  final AxisDirection headerDirection;

  @override
  Widget build(BuildContext context) {
    const numSections = 100;
    const numPerSection = 10;
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: StickyHeaderListView.separated(
            scrollDirection: Axis.horizontal,
            reverse: reverse,
            itemCount: numSections,
            separatorBuilder: (context, i) => const SizedBox.shrink(),
            itemBuilder: (context, i) => StickyHeader(
                direction: headerDirection,
                header: TallHeader(i: i),
                content: Row(
                    children: List.generate(
                        numPerSection,
                        (j) => TallItem(
                            i: i, j: j, numPerSection: numPerSection))))));
  }
}

class TallHeader extends StatelessWidget {
  const TallHeader({super.key, required this.i});

  final int i;

  @override
  Widget build(BuildContext context) {
    final contents = Column(children: [
      Text("Section ${i + 1}",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer)),
      const SizedBox(height: 8),
      const Expanded(child: SizedBox.shrink()),
      const SizedBox(height: 8),
      const Text("end"),
    ]);

    return Container(
        alignment: Alignment.center,
        child: Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(padding: const EdgeInsets.all(8), child: contents)));
  }
}

class TallItem extends StatelessWidget {
  const TallItem(
      {super.key,
      required this.i,
      required this.j,
      required this.numPerSection});

  final int i;
  final int j;
  final int numPerSection;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (1 + j) / numPerSection;

    final contents = Column(children: [
      Text("Item ${i + 1}.${j + 1}"),
      const SizedBox(height: 8),
      Expanded(
          child: FractionallySizedBox(
              heightFactor: heightFactor,
              child: ColoredBox(
                  color: Theme.of(context).colorScheme.secondary,
                  child: const SizedBox(width: 4)))),
      const SizedBox(height: 8),
      const Text("end"),
    ]);

    return Container(
        alignment: Alignment.center,
        child: Card(
            child: Padding(padding: const EdgeInsets.all(8), child: contents)));
  }
}
