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
    return ExampleVertical(title: title);
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
    return ExampleVertical(title: title, reverse: true);
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
  const ExampleHorizontal({super.key});

  static const title = 'Horizontal list';

  static navigate(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ExampleHorizontal()));
  }

  @override
  Widget build(BuildContext context) {
    return ExampleHorizontalBase(
        title: title, headerDirection: AxisDirection.right);
  }
}

class ExampleHorizontalReverse extends StatelessWidget {
  const ExampleHorizontalReverse({super.key});

  static const title = 'Horizontal reverse list';

  static navigate(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ExampleHorizontalReverse()));
  }

  @override
  Widget build(BuildContext context) {
    return ExampleHorizontalBase(
        title: title, reverse: true, headerDirection: AxisDirection.right);
  }
}

class ExampleHorizontalBase extends StatelessWidget {
  ExampleHorizontalBase(
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
