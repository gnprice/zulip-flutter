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
    return _SliverStickyHeaderList(
      headerPlacement: reverse ? HeaderPlacement.end : HeaderPlacement.start,
      headerBuilder: headerBuilder,
      delegate: childrenDelegate);
  }
}

/// Where a header goes, in terms of the list's scrolling direction.
enum HeaderPlacement { start, end }

class _SliverStickyHeaderList extends RenderObjectWidget {
  const _SliverStickyHeaderList({
    required this.headerPlacement,
    required this.headerBuilder,
    required this.delegate,
  });

  final HeaderPlacement headerPlacement;
  final HeaderBuilder headerBuilder;
  final SliverChildDelegate delegate;

  _SliverStickyHeaderListInner _buildInner() {
    return _SliverStickyHeaderListInner(
      headerPlacement: headerPlacement,
      headerBuilder: headerBuilder,
      delegate: delegate,
    );
  }

  @override
  _SliverStickyHeaderListElement createElement() => _SliverStickyHeaderListElement(this);

  @override
  _RenderSliverStickyHeaderList createRenderObject(BuildContext context) => _RenderSliverStickyHeaderList();
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
    _child = updateChild(_child, widget._buildInner(), _SliverStickyHeaderListSlot.list);
    renderObject.child!._parentElement = this;
    renderObject.child!.markNeedsLayout();
  }

  @override
  void update(_SliverStickyHeaderList newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget._buildInner(), _SliverStickyHeaderListSlot.list);
    // TODO updateChild header too?
    renderObject.child!.markNeedsLayout();
  }

  @override
  void unmount() {
    renderObject.child!._parentElement = null;
    super.unmount();
  }

  void _updateHeader(int? index) {
    @pragma('vm:notify-debugger-on-exception')
    void layoutCallback() {
      final built = index == null ? null : widget.headerBuilder(this, index);
      _header = updateChild(_header, built, _SliverStickyHeaderListSlot.header);
    }

    owner!.buildScope(this, layoutCallback);
  }

  void _layout(int? index) { // TODO refactor this better; fold into the render object?
    renderObject._updateHeader(this, index);
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
  // TODO reorganize this better
  void _updateHeader(_SliverStickyHeaderListElement element, int? index) {
    // The invokeLayoutCallback needs to happen on the same(?) RenderObject
    // that will end up getting mutated.
    invokeLayoutCallback((constraints) {
      element._updateHeader(index);
    });
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
  // and [RenderSliverSingleBoxAdapter] as to [header].
  //

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  @override
  void performLayout() {
    final constraints = this.constraints;

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
    required this.headerBuilder,
    required super.delegate,
  });

  final HeaderPlacement headerPlacement;
  final HeaderBuilder headerBuilder;

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

  _SliverStickyHeaderListElement? _parentElement;

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
    assert(_parentElement != null);
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
      _parentElement!._layout(index);
    }
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
