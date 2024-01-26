import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [SingleChildScrollView] that always shows a Material [Scrollbar].
///
/// This differs from the behavior provided by [MaterialScrollBehavior] in that
/// (a) the scrollbar appears even when [scrollDirection] is [Axis.horizontal],
/// and (b) the scrollbar appears on all platforms, rather than only on
/// desktop platforms.
// TODO(upstream): SingleChildScrollView should have a scrollBehavior field
//   and pass it on to Scrollable, just like ScrollView does; then this would
//   be covered by using that.
// TODO: Maybe show scrollbar only on mobile platforms, like MaterialScrollBehavior
//   and the base ScrollBehavior do?
class SingleChildScrollViewWithScrollbar extends StatefulWidget {
  const SingleChildScrollViewWithScrollbar(
    {super.key, required this.scrollDirection, required this.child});

  final Axis scrollDirection;
  final Widget child;

  @override
  State<SingleChildScrollViewWithScrollbar> createState() =>
    _SingleChildScrollViewWithScrollbarState();
}

class _SingleChildScrollViewWithScrollbarState
    extends State<SingleChildScrollViewWithScrollbar> {
  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: widget.scrollDirection,
        child: widget.child));
  }
}

/// A [CustomScrollView] where the first sliver in [slivers] paints on top.
///
/// This is just like [CustomScrollView] except that the paint order runs
/// through the [slivers] list from end to start, and the hit-test order runs
/// from start to end.  This means that the sliver at the start of [slivers]
/// is effectively on top in the z-direction, with the next sliver below it,
/// and so on.
///
/// When [center] is null or corresponds to the first sliver in the list, this
/// is the same behavior as [CustomScrollView].  Otherwise, [CustomScrollView]
/// has the [center] sliver on top in the z-direction, followed by the slivers
/// after it to the end of [slivers], followed by the slivers before [center]
/// in reverse order, with the first sliver in the list at the bottom in the
/// z-direction.
// TODO(upstream): add an option [ScrollView.zOrder]?  (An enum, or possibly
//   a delegate.)  Or at minimum document on [ScrollView.center] the
//   existing behavior, which is counterintuitive.
//   Nearest related upstream feature requests I find are for a "z-index",
//   for CustomScrollView, Column, and Stack respectively:
//     https://github.com/flutter/flutter/issues/121173#issuecomment-1712825747
//     https://github.com/flutter/flutter/issues/121173
//     https://github.com/flutter/flutter/issues/70836
//   A delegate would give enough flexibility for that and much else,
//   but I'm not sure how many use cases wouldn't be covered by a small enum.
//
// TODO: perh sticky_header should configure a FirstSliverTopScrollView automatically?
class FirstSliverTopScrollView extends CustomScrollView {
  const FirstSliverTopScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.scrollBehavior,
    // super.shrinkWrap, // omitted, always false
    super.center,
    super.anchor,
    super.cacheExtent,
    super.slivers,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  });

  @override
  Widget buildViewport(BuildContext context, ViewportOffset offset,
      AxisDirection axisDirection, List<Widget> slivers) {
    return FirstSliverTopViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
      clipBehavior: clipBehavior,
    );
  }
}

class FirstSliverTopViewport extends Viewport {
  FirstSliverTopViewport({
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    super.anchor,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.slivers,
    super.clipBehavior,
  });

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return RenderFirstSliverTopViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ?? Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
    );
  }
}

class RenderFirstSliverTopViewport extends RenderViewport {
  RenderFirstSliverTopViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    super.anchor,
    super.children,
    super.center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
  });

  @override
  Iterable<RenderSliver> get childrenInPaintOrder {
    final List<RenderSliver> children = <RenderSliver>[];
    RenderSliver? child = lastChild;
    while (child != null) {
      children.add(child);
      child = childBefore(child);
    }
    return children;
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder {
    final List<RenderSliver> children = <RenderSliver>[];
    RenderSliver? child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }
}
