import 'package:flutter/material.dart';
import 'package:zulip/widgets/sticky_header.dart';

/// Example page using [StickyHeaderListView] and [StickyHeader] in a
/// vertically-scrolling list.
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

/// Example page using [StickyHeaderListView] and [StickyHeader] in a
/// horizontally-scrolling list.
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

enum _ExampleType { vertical, horizontal }

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final verticalItems = [
      _buildItem(context, _ExampleType.vertical,
          primary: true,
          title: 'Scroll down, headers at top (a standard list)',
          headerDirection: AxisDirection.down),
      _buildItem(context, _ExampleType.vertical,
          title: 'Scroll up, headers at top',
          reverse: true,
          headerDirection: AxisDirection.down),
      _buildItem(context, _ExampleType.vertical,
          title: 'Scroll down, headers at bottom',
          headerDirection: AxisDirection.up),
      _buildItem(context, _ExampleType.vertical,
          title: 'Scroll up, headers at bottom',
          reverse: true,
          headerDirection: AxisDirection.up),
    ];
    final horizontalItems = [
      _buildItem(context, _ExampleType.horizontal,
          title: 'Scroll right, headers at left',
          headerDirection: AxisDirection.right),
      _buildItem(context, _ExampleType.horizontal,
          title: 'Scroll left, headers at left',
          reverse: true,
          headerDirection: AxisDirection.right),
      _buildItem(context, _ExampleType.horizontal,
          title: 'Scroll right, headers at right',
          headerDirection: AxisDirection.left),
      _buildItem(context, _ExampleType.horizontal,
          title: 'Scroll left, headers at right',
          reverse: true,
          headerDirection: AxisDirection.left),
    ];
    return Scaffold(
        appBar: AppBar(title: const Text('Sticky Headers example')),
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                      child: Text("Vertical lists",
                          style: Theme.of(context).textTheme.headlineMedium)))),
          SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              sliver: SliverGrid.count(
                  childAspectRatio: 2,
                  crossAxisCount: 2,
                  children: verticalItems)),
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                      child: Text("Horizontal lists",
                          style: Theme.of(context).textTheme.headlineMedium)))),
          SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              sliver: SliverGrid.count(
                  childAspectRatio: 2,
                  crossAxisCount: 2,
                  children: horizontalItems)),
        ]));
  }

  Widget _buildItem(BuildContext context, _ExampleType exampleType,
      {required String title,
      bool reverse = false,
      required AxisDirection headerDirection,
      bool primary = false}) {
    Widget page;
    switch (exampleType) {
      case _ExampleType.vertical:
        page = ExampleVertical(
            title: title, reverse: reverse, headerDirection: headerDirection);
        break;
      case _ExampleType.horizontal:
        page = ExampleHorizontal(
            title: title, reverse: reverse, headerDirection: headerDirection);
        break;
    }

    var label = Text(title,
        textAlign: TextAlign.center,
        style: TextStyle(
            inherit: true,
            fontSize: Theme.of(context).textTheme.titleLarge?.fontSize));
    var buttonStyle = primary
        ? null
        : ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary);
    return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
            style: buttonStyle,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => page)),
            child: label));
  }
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

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

void main() {
  runApp(const ExampleApp());
}
