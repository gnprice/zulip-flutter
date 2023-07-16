import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef HeaderBuilder = Widget? Function(BuildContext context, int index);

class StickyHeaderListView extends BoxScrollView {
  // Like ListView, but with sticky headers.
  StickyHeaderListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    required this.headerBuilder,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : childrenDelegate = SliverChildListDelegate(
         children,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(
         semanticChildCount: semanticChildCount ?? children.length,
       );

  // Like ListView.builder, but with sticky headers.
  StickyHeaderListView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.headerBuilder,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(itemCount == null || itemCount >= 0),
       assert(semanticChildCount == null || semanticChildCount <= itemCount!),
       childrenDelegate = SliverChildBuilderDelegate(
         itemBuilder,
         findChildIndexCallback: findChildIndexCallback,
         childCount: itemCount,
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
       ),
       super(
         semanticChildCount: semanticChildCount ?? itemCount,
       );

  // Like ListView.separated, but with sticky headers.
  StickyHeaderListView.separated({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.headerBuilder,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : assert(itemCount >= 0),
       childrenDelegate = SliverChildBuilderDelegate(
         (BuildContext context, int index) {
           final int itemIndex = index ~/ 2;
           final Widget? widget;
           if (index.isEven) {
             widget = itemBuilder(context, itemIndex);
           } else {
             widget = separatorBuilder(context, itemIndex);
             assert(() {
               if (widget == null) {
                 throw FlutterError('separatorBuilder cannot return null.');
               }
               return true;
             }());
           }
           return widget;
         },
         findChildIndexCallback: findChildIndexCallback,
         childCount: math.max(0, itemCount * 2 - 1),
         addAutomaticKeepAlives: addAutomaticKeepAlives,
         addRepaintBoundaries: addRepaintBoundaries,
         addSemanticIndexes: addSemanticIndexes,
         semanticIndexCallback: (Widget _, int index) {
           return index.isEven ? index ~/ 2 : null;
         },
       ),
       super(
         semanticChildCount: itemCount,
       );

  // Like ListView.custom, but with sticky headers.
  const StickyHeaderListView.custom({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.headerBuilder,
    required this.childrenDelegate,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  });

  final SliverChildDelegate childrenDelegate;
  final HeaderBuilder headerBuilder;

  @override
  Widget buildChildLayout(BuildContext context) {
    return _SliverStickyHeaderListInner(
      headerPlacement: reverse ? HeaderPlacement.end : HeaderPlacement.start,
      headerBuilder: headerBuilder,
      delegate: childrenDelegate);
  }
}

/// Where a header goes, in terms of the list's scrolling direction.
enum HeaderPlacement { start, end }

enum _SliverStickyHeaderListSlot { header, list }

class _RenderSliverStickyHeaderList extends RenderSliver {

  //
  // Managing the two children [header] and [child].
  // This is modeled on [RenderObjectWithChildMixin].
  //

  RenderBox? get header => _header;
  RenderBox? _header;
  set header(RenderBox? value) {
    if (_header != null) dropChild(_header!);
    _header = value;
    if (_header != null) adoptChild(_header!);
  }

  RenderSliver? get child => _child;
  RenderSliver? _child;
  set child(RenderSliver? value) {
    if (_child != null) dropChild(_child!);
    _child = value;
    if (_child != null) adoptChild(_child!);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _header?.attach(owner);
    _child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    _header?.detach();
    _child?.detach();
  }

  @override
  void redepthChildren() {
    if (_header != null) redepthChild(_header!);
    if (_child != null) redepthChild(_child!);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_child != null) visitor(_child!);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return [
      if (_header != null) _header!.toDiagnosticsNode(name: 'header'),
      if (_child != null) _child!.toDiagnosticsNode(name: 'child'),
    ];
  }

  @override
  void performLayout() {

  }
}


class _SliverStickyHeaderListInner extends SliverMultiBoxAdaptorWidget {
  const _SliverStickyHeaderListInner({
    super.key,
    required this.headerPlacement,
    required this.headerBuilder,
    required super.delegate,
  });

  final HeaderPlacement headerPlacement;
  final HeaderBuilder headerBuilder;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
    _SliverStickyHeaderListElement(this, replaceMovedChildren: true);

  @override
  _RenderSliverStickyHeaderListInner createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverStickyHeaderListInner(childManager: element);
  }
}

class _SliverStickyHeaderListElement extends SliverMultiBoxAdaptorElement {
  _SliverStickyHeaderListElement(super.widget, {super.replaceMovedChildren});

  @override
  _SliverStickyHeaderListInner get widget => super.widget as _SliverStickyHeaderListInner;

  @override
  _RenderSliverStickyHeaderListInner get renderObject => super.renderObject as _RenderSliverStickyHeaderListInner;

  Element? _header;

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    if (_header != null) visitor(_header!);
  }

  @override
  void forgetChild(Element child) {
    if (child == _header) {
      _header = null;
      // Skip super, which assumes child is one of the super-managed children.
      // This also skips [Element.forgetChild]; TODO is that OK?
    } else {
      super.forgetChild(child);
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    renderObject.updateCallback(_layout);
  }

  @override
  void update(covariant _SliverStickyHeaderListInner newWidget) {
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    renderObject.updateCallback(_layout);
  }

  @override
  void unmount() {
    renderObject.updateCallback(null);
    super.unmount();
  }

  void _layout(int? index) {
    debugPrint("_SliverStickyHeaderListElement._layout index: $index");

    @pragma('vm:notify-debugger-on-exception')
    void layoutCallback() {
      final built = index == null ? null : widget.headerBuilder(this, index);

      _header = updateChild(_header, built, null);

      // TODO finish implementing _layout
    }

    owner!.buildScope(this, layoutCallback);
  }

  @override
  void insertRenderObjectChild(RenderObject child, int? slot) {
    if (slot == null) {
      final renderObject = this.renderObject;
      assert(renderObject.debugValidateChild(child));
      renderObject.header = child as RenderBox;
      assert(renderObject == this.renderObject);
    } else {
      super.insertRenderObjectChild(child, slot);
    }
  }

  @override
  void moveRenderObjectChild(RenderObject child, int? oldSlot, int? newSlot) {
    if (oldSlot == null || newSlot == null) {
      assert(false);
    } else {
      super.moveRenderObjectChild(child, oldSlot, newSlot);
    }
  }

  @override
  void removeRenderObjectChild(RenderObject child, int? slot) {
    if (slot == null) {
      final renderObject = this.renderObject;
      assert(renderObject.header == child);
      renderObject.header = null;
      assert(renderObject == this.renderObject);
    } else {
      super.removeRenderObjectChild(child, slot);
    }
  }
}



class _RenderSliverStickyHeaderListInner extends RenderSliverList {
  _RenderSliverStickyHeaderListInner({required super.childManager});

  _SliverStickyHeaderListInner get widget => (childManager as _SliverStickyHeaderListElement).widget;

  // Modeled on [RenderObjectWithChildMixin.child].
  RenderBox? get header => _header;
  RenderBox? _header;
  set header(RenderBox? value) {
    if (_header != null) dropChild(_header!);
    _header = value;
    if (_header != null) adoptChild(_header!);
  }

  void Function(int? index)? _callback;
  void updateCallback(void Function(int? index)? value) {
    if (value == _callback) return;
    _callback = value;
    markNeedsLayout();
  }

  /// The unique child, if any, that spans the start of the visible portion
  /// of the list.
  ///
  /// This means (child start) <= (viewport start) < (child end).
  RenderBox? _findChildAtStart() {
    final scrollOffset = constraints.scrollOffset;
    // debugPrint("our scroll offset: $scrollOffset");

    RenderBox? child;
    for (child = firstChild; ; child = childAfter(child)) {
      if (child == null) {
        // Ran out of children.
        return null;
      }
      final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(parentData.layoutOffset != null);
      if (scrollOffset < parentData.layoutOffset!) {
        // This child is already past the start of the sliver's viewport.
        return null;
      }
      if (scrollOffset < parentData.layoutOffset! + child.size.onAxis(constraints.axis)) {
        return child;
      }
    }
  }

  /// The unique child, if any, that spans the end of the visible portion
  /// of the list.
  ///
  /// This means (child start) < (viewport end) <= (child end).
  RenderBox? _findChildAtEnd() {
    // TODO should this be our layoutExtent or paintExtent, or what?
    final endOffset = constraints.scrollOffset + geometry!.layoutExtent;

    RenderBox? child;
    for (child = lastChild; ; child = childBefore(child)) {
      if (child == null) {
        // Ran out of children.
        return null;
      }
      final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
      assert(parentData.layoutOffset != null);
      if (endOffset > parentData.layoutOffset! + child.size.onAxis(constraints.axis)) {
        // This child already stops before the end of the sliver's viewport.
        return null;
      }
      if (endOffset > parentData.layoutOffset!) {
        return child;
      }
    }
  }

  int? _previousHeaderProvidingIndex;

  @override
  void performLayout() {
    assert(_callback != null);
    assert(constraints.growthDirection == GrowthDirection.forward); // TODO dir

    super.performLayout();

    // debugPrint("our constraints: $constraints");
    // debugPrint("our geometry: $geometry");

    final child = switch (widget.headerPlacement) {
      HeaderPlacement.start => _findChildAtStart(),
      HeaderPlacement.end   => _findChildAtEnd(),
    };
    final index = child == null ? null : indexOf(child);
    if (index != _previousHeaderProvidingIndex) {
      _previousHeaderProvidingIndex = index;
      invokeLayoutCallback((constraints) {
        _callback!(index);
      });
    }




    // RenderBox? child;
    // for (child = firstChild; child != null; child = childAfter(child)) {
    //   final parentData = child.parentData! as SliverMultiBoxAdaptorParentData;
    //   assert(parentData.layoutOffset != null);
    //
    //   RenderBox? innerChild = child;
    //   while (innerChild is RenderProxyBox) {
    //     innerChild = innerChild.child;
    //   }
    //   if (innerChild is! RenderStickyHeader) {
    //     continue;
    //   }
    //   assert(axisDirectionToAxis(innerChild.direction) == constraints.axis);
    //
    //   double childScrollOffset;
    //   if (innerChild.direction == constraints.axisDirection) {
    //     childScrollOffset = math.max(0.0,
    //       scrollOffset - parentData.layoutOffset!);
    //   } else {
    //     final childEndOffset =
    //       parentData.layoutOffset! + child.size.onAxis(constraints.axis);
    //     // TODO should this be our layoutExtent or paintExtent, or what?
    //     childScrollOffset = math.max(0.0,
    //       childEndOffset - (scrollOffset + geometry!.layoutExtent));
    //   }
    //   innerChild.provideScrollPosition(childScrollOffset);
    // }
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {required double mainAxisPosition, required double crossAxisPosition}) {
    // TODO implement hitTestChildren
    return super.hitTestChildren(result, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
    // return header?.hitTest(result, )
    //   ?? super.hitTestChildren(result, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    header?.paint(context, offset); // TODO allow header an offset
  }
}

class StickyHeaderParentData extends ContainerBoxParentData<RenderBox> {
  Widget? header;
}

class StickyHeaderProvider extends StatelessWidget {
   const StickyHeaderProvider({super.key, required this.child, required this.header});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

// class StickyHeaderProvider extends ParentDataWidget<StickyHeaderParentData> {
//   const StickyHeaderProvider({super.key, required super.child, required this.header});
//
//   final Widget header;
//
//   @override
//   void applyParentData(RenderObject renderObject) {
//     assert(renderObject.parentData is StickyHeaderParentData);
//     final parentData = renderObject.parentData! as StickyHeaderParentData;
//     if (parentData.header != header) {
//       parentData.header = header;
//       renderObject.parent?.markNeedsLayout();
//     }
//   }
//
//   @override
//   Type get debugTypicalAncestorWidgetClass => StickyHeaderListView;
// }






enum StickyHeaderSlot { header, content }

class StickyHeader extends SlottedMultiChildRenderObjectWidget<StickyHeaderSlot, RenderBox> {
  const StickyHeader({
    super.key,
    this.direction = AxisDirection.down,
    this.header,
    this.content,
  });

  final AxisDirection direction;
  final Widget? header;
  final Widget? content;

  @override
  Iterable<StickyHeaderSlot> get slots => StickyHeaderSlot.values;

  @override
  Widget? childForSlot(StickyHeaderSlot slot) {
    switch (slot) {
      case StickyHeaderSlot.header:
        return header;
      case StickyHeaderSlot.content:
        return content;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<StickyHeaderSlot, RenderBox> createRenderObject(
      BuildContext context) {
    return RenderStickyHeader(direction: direction);
  }
}

class RenderStickyHeader extends RenderBox with SlottedContainerRenderObjectMixin<StickyHeaderSlot, RenderBox> {
  RenderStickyHeader({required AxisDirection direction})
    : _direction = direction;

  RenderBox? get _header => childForSlot(StickyHeaderSlot.header);

  RenderBox? get _content => childForSlot(StickyHeaderSlot.content);

  AxisDirection get direction => _direction;
  AxisDirection _direction;

  set direction(AxisDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  Iterable<RenderBox> get children => [
    if (_header != null) _header!,
    if (_content != null) _content!,
  ];

  double? _slackSize;

  void provideScrollPosition(double scrollPosition) {
    assert(hasSize);
    final header = _header;
    if (header == null) return;
    assert(header.hasSize);
    assert(_slackSize != null);

    assert(0.0 <= scrollPosition);
    final position = math.min(scrollPosition, _slackSize!);

    Offset offset;
    if (!axisDirectionIsReversed(direction)) {
      offset = offsetInDirection(direction, position);
    } else {
      // TODO simplify this one
      offset = offsetInDirection(direction, position - _slackSize!);
    }
    if (offset == _parentData(header).offset) {
      return;
    }
    _parentData(header).offset = offset;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    Axis axis = axisDirectionToAxis(direction);

    final constraints = this.constraints;
    assert(!constraints.hasBoundedAxis(axis));
    assert(constraints.hasTightAxis(flipAxis(axis)));

    final header = _header;
    if (header != null) header.layout(constraints, parentUsesSize: true);
    final headerSize = header?.size.onAxis(axis) ?? 0;

    final content = _content;
    if (content != null) content.layout(constraints, parentUsesSize: true);
    final contentSize = content?.size.onAxis(axis) ?? 0;

    if (!axisDirectionIsReversed(direction)) {
      if (header != null) _parentData(header).offset = Offset.zero;
      if (content != null) {
        _parentData(content).offset = offsetInDirection(direction, headerSize);
      }
    } else {
      if (header != null) {
        _parentData(header).offset = offsetInDirection(direction, -contentSize);
      }
      if (content != null) _parentData(content).offset = Offset.zero;
    }

    final totalSize = headerSize + contentSize;
    size = constraints.constrain(sizeOn(axis, main: totalSize));
    _slackSize = contentSize;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintChild(RenderBox child, PaintingContext context, Offset offset) {
      context.paintChild(child, offset + _parentData(child).offset);
    }

    final content = _content;
    if (content != null) paintChild(content, context, offset);
    final header = _header;
    if (header != null) paintChild(header, context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children) {
      final parentData = _parentData(child);
      if (result.addWithPaintOffset(
          offset: parentData.offset,
          position: position,
          hitTest: (result, transformed) {
            assert(transformed == position - parentData.offset);
            return child.hitTest(result, position: transformed);
          })) {
        return true;
      }
    }
    return false;
  }

  BoxParentData _parentData(RenderBox child) => child.parentData! as BoxParentData;
}

Size sizeOn(Axis axis, {double main = 0, double cross = 0}) {
  switch (axis) {
    case Axis.horizontal:
      return Size(main, cross);
    case Axis.vertical:
      return Size(cross, main);
  }
}

Offset offsetInDirection(AxisDirection direction, double extent) {
  switch (direction) {
    case AxisDirection.right:
      return Offset(extent, 0);
    case AxisDirection.left:
      return Offset(-extent, 0);
    case AxisDirection.down:
      return Offset(0, extent);
    case AxisDirection.up:
      return Offset(0, -extent);
  }
}

extension SizeOnAxis on Size {
  double onAxis(Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        return width;
      case Axis.vertical:
        return height;
    }
  }
}

extension BoxConstraintsOnAxis on BoxConstraints {
  bool hasBoundedAxis(Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        return hasBoundedWidth;
      case Axis.vertical:
        return hasBoundedHeight;
    }
  }

  bool hasTightAxis(Axis axis) {
    switch (axis) {
      case Axis.horizontal:
        return hasTightWidth;
      case Axis.vertical:
        return hasTightHeight;
    }
  }
}
