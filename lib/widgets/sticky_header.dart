import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef HeaderBuilder = Widget? Function(BuildContext context, int index);

class StickyHeaderItem extends SingleChildRenderObjectWidget {
  const StickyHeaderItem({super.key, super.child, required this.header});

  final Widget header;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderStickyHeaderItem(header: header);
  }

  @override
  void updateRenderObject(BuildContext context, RenderStickyHeaderItem renderObject) {
    renderObject.header = header;
  }
}

class RenderStickyHeaderItem extends RenderProxyBox {
  RenderStickyHeaderItem({required Widget header})
   : _header = header;

  Widget get header => _header;
  Widget _header;
  set header(Widget value) {
    if (header == value) return;
    _header = value;
    // Mark for layout, to cause the enclosing list to lay out
    // so that [_RenderSliverStickyListInner.performLayout] runs.
    markNeedsLayout();
  }
}

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
    required this.childrenDelegate,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  });

  final SliverChildDelegate childrenDelegate;

  @override
  Widget buildChildLayout(BuildContext context) {
    return _SliverStickyHeaderList(
      headerPlacement: reverse ? HeaderPlacement.end : HeaderPlacement.start,
      delegate: childrenDelegate);
  }
}

/// Where a header goes, in terms of the list's scrolling direction.
enum HeaderPlacement { start, end }

class _SliverStickyHeaderList extends RenderObjectWidget {
  _SliverStickyHeaderList({
    required HeaderPlacement headerPlacement,
    required SliverChildDelegate delegate,
  }) : child = _SliverStickyHeaderListInner(
    headerPlacement: headerPlacement,
    delegate: delegate,
  );

  final _SliverStickyHeaderListInner child;

  @override
  _SliverStickyHeaderListElement createElement() => _SliverStickyHeaderListElement(this);

  @override
  _RenderSliverStickyHeaderList createRenderObject(BuildContext context) {
    final element = context as _SliverStickyHeaderListElement;
    return _RenderSliverStickyHeaderList(element: element);
  }
}

enum _SliverStickyHeaderListSlot { header, list }

class _SliverStickyHeaderListElement extends RenderObjectElement {
  _SliverStickyHeaderListElement(_SliverStickyHeaderList super.widget);

  @override
  _SliverStickyHeaderList get widget => super.widget as _SliverStickyHeaderList;

  @override
  _RenderSliverStickyHeaderList get renderObject => super.renderObject as _RenderSliverStickyHeaderList;

  //
  // Compare SingleChildRenderObjectElement.
  //

  Element? _header;
  Element? _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_header != null) visitor(_header!);
    if (_child != null) visitor(_child!);
  }

  @override
  void forgetChild(Element child) {
    if (child == _header) {
      assert(child != _child);
      _header = null;
    } else if (child == _child) {
      _child = null;
    }
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, _SliverStickyHeaderListSlot.list);
  }

  @override
  void update(_SliverStickyHeaderList newWidget) {
    debugPrint("update");
    // debugPrintStack();
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, _SliverStickyHeaderListSlot.list);
    renderObject.child!.markHeaderNeedsRebuild();
  }

  @override
  void performRebuild() {
    debugPrint("performRebuild");
    renderObject.child!.markHeaderNeedsRebuild();
    super.performRebuild();
  }

  void _rebuildHeader(RenderStickyHeaderItem? item) {
    owner!.buildScope(this, () {
      _header = updateChild(_header, item?.header, _SliverStickyHeaderListSlot.header);
    });
  }

  @override
  void insertRenderObjectChild(RenderObject child, _SliverStickyHeaderListSlot slot) {
    final renderObject = this.renderObject;
    switch (slot) {
      case _SliverStickyHeaderListSlot.header:
        assert(child is RenderBox);
        renderObject.header = child as RenderBox;
      case _SliverStickyHeaderListSlot.list:
        assert(child is _RenderSliverStickyHeaderListInner);
        renderObject.child = child as _RenderSliverStickyHeaderListInner;
    }
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(covariant RenderObject child, covariant Object? oldSlot, covariant Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(RenderObject child, _SliverStickyHeaderListSlot slot) {
    final renderObject = this.renderObject;
    switch (slot) {
      case _SliverStickyHeaderListSlot.header:
        assert(renderObject.header == child);
        renderObject.header = null;
      case _SliverStickyHeaderListSlot.list:
        assert(renderObject.child == child);
        renderObject.child = null;
    }
    assert(renderObject == this.renderObject);
  }
}

class _RenderSliverStickyHeaderList extends RenderSliver with RenderSliverHelpers {
  _RenderSliverStickyHeaderList({
    required _SliverStickyHeaderListElement element,
  }) : _element = element;

  final _SliverStickyHeaderListElement _element;

  Widget? _headerWidget;

  void _rebuildHeader(RenderBox? listChild) {
    final item = _findStickyHeaderItem(listChild);

    if (item?.header == _headerWidget) {
      // Nothing to update; we can save the cost of invokeLayoutCallback.
      return;
    }
    _headerWidget = item?.header;

    debugPrint('_RenderSliverStickyHeaderList._rebuildHeader');
    // The invokeLayoutCallback needs to happen on the same(?) RenderObject
    // that will end up getting mutated.  Attempting it on the child RenderObject
    // would trip an assertion.
    invokeLayoutCallback((constraints) {
      _element._rebuildHeader(item);
    });
  }

  RenderStickyHeaderItem? _findStickyHeaderItem(RenderBox? child) {
    RenderBox? node = child;
    do {
      if (node is RenderStickyHeaderItem) return node;
      if (node is! RenderProxyBox) return null;
      node = node.child;
    } while (true);
  }

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

  _RenderSliverStickyHeaderListInner? get child => _child;
  _RenderSliverStickyHeaderListInner? _child;
  set child(_RenderSliverStickyHeaderListInner? value) {
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

  //
  // The sliver protocol.
  // Modeled on [RenderProxySliver] as to [child],
  // and [RenderSliverToBoxAdapter] (along with [RenderSliverSingleBoxAdapter],
  // its base class) as to [header].
  //

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void performLayout() {
    assert(child != null);
    child!.layout(constraints, parentUsesSize: true);
    SliverGeometry geometry = child!.geometry!;

    if (header != null) {
      header!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
      final headerExtent = header!.size.onAxis(constraints.axis);
      final paintedHeaderSize = calculatePaintOffset(constraints, from: 0, to: headerExtent);
      final cacheExtent = calculateCacheOffset(constraints, from: 0, to: headerExtent);

      assert(0 <= paintedHeaderSize && paintedHeaderSize.isFinite);

      geometry = SliverGeometry( // TODO review these again
        scrollExtent: geometry.scrollExtent,
        paintExtent: math.max(geometry.paintExtent, paintedHeaderSize),
        cacheExtent: math.max(geometry.cacheExtent, cacheExtent),
        maxPaintExtent: math.max(geometry.maxPaintExtent, headerExtent),
        hitTestExtent: math.max(geometry.hitTestExtent, paintedHeaderSize),
        hasVisualOverflow: geometry.hasVisualOverflow
          || headerExtent > constraints.remainingPaintExtent,
      );
    }

    this.geometry = geometry;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
    if (header != null && geometry!.visible) {
      context.paintChild(header!, offset); // TODO give header an offset
    }
  }

  @override
  bool hitTestChildren(SliverHitTestResult result, {required double mainAxisPosition, required double crossAxisPosition}) {
    assert(child != null);
    assert(geometry!.hitTestExtent > 0.0);
    if (header != null
      && hitTestBoxChild(BoxHitTestResult.wrap(result), header!,
           mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition)) {
      return true;
    }
    return child!.hitTest(result,
      mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
  }

  @override
  double childMainAxisPosition(RenderObject child) {
    if (child == this.child) return 0.0;
    assert(child == header);
    return 0.0; // TODO fix for headerPlacement end; TODO also give header an offset
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child == this.child || child == header);
    final childParentData = child.parentData! as SliverPhysicalParentData;
    childParentData.applyPaintTransform(transform);
  }
}

class _SliverStickyHeaderListInner extends SliverMultiBoxAdaptorWidget {
  const _SliverStickyHeaderListInner({
    required this.headerPlacement,
    required super.delegate,
  });

  final HeaderPlacement headerPlacement;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
    SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  _RenderSliverStickyHeaderListInner createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return _RenderSliverStickyHeaderListInner(childManager: element);
  }
}

class _RenderSliverStickyHeaderListInner extends RenderSliverList {
  _RenderSliverStickyHeaderListInner({required super.childManager});

  _SliverStickyHeaderListInner get widget => (childManager as SliverMultiBoxAdaptorElement).widget as _SliverStickyHeaderListInner;

  /// The unique child, if any, that spans the start of the visible portion
  /// of the list.
  ///
  /// This means (child start) <= (viewport start) < (child end).
  RenderBox? _findChildAtStart() {
    final scrollOffset = constraints.scrollOffset;

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

  void markHeaderNeedsRebuild() {
    debugPrint('markHeaderNeedsRebuild');
    markNeedsLayout();
  }

  @override
  void performLayout() {
    assert(constraints.growthDirection == GrowthDirection.forward); // TODO dir

    super.performLayout();

    final child = switch (widget.headerPlacement) {
      HeaderPlacement.start => _findChildAtStart(),
      HeaderPlacement.end   => _findChildAtEnd(),
    };
    (parent! as _RenderSliverStickyHeaderList)._rebuildHeader(child);
  }
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
