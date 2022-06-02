// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';

// All values eyeballed.
const double _kScrollbarMinLength = 36.0;
const double _kScrollbarMinOverscrollLength = 8.0;
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
const Duration _kScrollbarResizeDuration = Duration(milliseconds: 100);

// Extracted from iOS 13.1 beta using Debug View Hierarchy.
const Color _kScrollbarColor = CupertinoDynamicColor.withBrightness(
  color: Color(0x59000000),
  darkColor: Color(0x80FFFFFF),
);

// This is the amount of space from the top of a vertical scrollbar to the
// top edge of the scrollable, measured when the vertical scrollbar overscrolls
// to the top.
// TODO(LongCatIsLooong): fix https://github.com/flutter/flutter/issues/32175
const double _kScrollbarMainAxisMargin = 3.0;
const double _kScrollbarCrossAxisMargin = 3.0;

/// An iOS style scrollbar.
///
/// To add a scrollbar to a [ScrollView], simply wrap the scroll view widget in
/// a [CupertinoScrollbar] widget.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=DbkIQSvwnZc}
///
/// {@macro flutter.widgets.Scrollbar}
///
/// When dragging a [CupertinoScrollbar] thumb, the thickness and radius will
/// animate from [thickness] and [radius] to [thicknessWhileDragging] and
/// [radiusWhileDragging], respectively.
///
/// {@tool dartpad}
/// This sample shows a [CupertinoScrollbar] that fades in and out of view as scrolling occurs.
/// The scrollbar will fade into view as the user scrolls, and fade out when scrolling stops.
/// The `thickness` of the scrollbar will animate from 6 pixels to the `thicknessWhileDragging` of 10
/// when it is dragged by the user. The `radius` of the scrollbar thumb corners will animate from 34
/// to the `radiusWhileDragging` of 0 when the scrollbar is being dragged by the user.
///
/// ** See code in examples/api/lib/cupertino/scrollbar/cupertino_scrollbar.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// When [thumbVisibility] is true, the scrollbar thumb will remain visible without the
/// fade animation. This requires that a [ScrollController] is provided to controller,
/// or that the [PrimaryScrollController] is available. [isAlwaysShown] is
/// deprecated in favor of `thumbVisibility`.
///
/// ** See code in examples/api/lib/cupertino/scrollbar/cupertino_scrollbar.1.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ListView], which displays a linear, scrollable list of children.
///  * [GridView], which displays a 2 dimensional, scrollable array of children.
///  * [Scrollbar], a Material Design scrollbar.
///  * [RawScrollbar], a basic scrollbar that fades in and out, extended
///    by this class to add more animations and behaviors.
class CupertinoScrollbar extends RawScrollbar {
  /// Creates an iOS style scrollbar that wraps the given [child].
  ///
  /// The [child] should be a source of [ScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  const CupertinoScrollbar({
    Key? key,
    required Widget child,
    ScrollController? controller,
    bool? thumbVisibility,
    double thickness = defaultThickness,
    this.thicknessWhileDragging = defaultThicknessWhileDragging,
    Radius radius = defaultRadius,
    this.radiusWhileDragging = defaultRadiusWhileDragging,
    ScrollNotificationPredicate? notificationPredicate,
    ScrollbarOrientation? scrollbarOrientation,
    @Deprecated(
      'Use thumbVisibility instead. '
      'This feature was deprecated after v2.9.0-1.0.pre.',
    )
    bool? isAlwaysShown,
  }) : assert(thickness != null),
       assert(thickness < double.infinity),
       assert(thicknessWhileDragging != null),
       assert(thicknessWhileDragging < double.infinity),
       assert(radius != null),
       assert(radiusWhileDragging != null),
       assert(
         isAlwaysShown == null || thumbVisibility == null,
         'Scrollbar thumb appearance should only be controlled with thumbVisibility, '
         'isAlwaysShown is deprecated.'
       ),
       super(
         key: key,
         child: child,
         controller: controller,
         thumbVisibility: isAlwaysShown ?? thumbVisibility ?? false,
         thickness: thickness,
         radius: radius,
         fadeDuration: _kScrollbarFadeDuration,
         timeToFade: _kScrollbarTimeToFade,
         pressDuration: const Duration(milliseconds: 100),
         notificationPredicate: notificationPredicate ?? defaultScrollNotificationPredicate,
         scrollbarOrientation: scrollbarOrientation,
       );

  /// Default value for [thickness] if it's not specified in [CupertinoScrollbar].
  static const double defaultThickness = 3;

  /// Default value for [thicknessWhileDragging] if it's not specified in
  /// [CupertinoScrollbar].
  static const double defaultThicknessWhileDragging = 8.0;

  /// Default value for [radius] if it's not specified in [CupertinoScrollbar].
  static const Radius defaultRadius = Radius.circular(1.5);

  /// Default value for [radiusWhileDragging] if it's not specified in
  /// [CupertinoScrollbar].
  static const Radius defaultRadiusWhileDragging = Radius.circular(4.0);

  /// The thickness of the scrollbar when it's being dragged by the user.
  ///
  /// When the user starts dragging the scrollbar, the thickness will animate
  /// from [thickness] to this value, then animate back when the user stops
  /// dragging the scrollbar.
  final double thicknessWhileDragging;

  /// The radius of the scrollbar edges when the scrollbar is being dragged by
  /// the user.
  ///
  /// When the user starts dragging the scrollbar, the radius will animate
  /// from [radius] to this value, then animate back when the user stops
  /// dragging the scrollbar.
  final Radius radiusWhileDragging;

  @override
  RawScrollbarState<CupertinoScrollbar> createState() => _CupertinoScrollbarState();
}

class _CupertinoScrollbarState extends RawScrollbarState<CupertinoScrollbar> {
  late AnimationController _thicknessAnimationController;

  double get _thickness {
    return widget().thickness! + _thicknessAnimationController.value * (widget().thicknessWhileDragging - widget().thickness!);
  }

  Radius get _radius {
    return Radius.lerp(widget().radius, widget().radiusWhileDragging, _thicknessAnimationController.value)!;
  }

  @override
  void initState() {
    super.initState();
    _thicknessAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarResizeDuration,
    );
    _thicknessAnimationController.addListener(() {
      updateScrollbarPainter();
    });
  }

  @override
  void updateScrollbarPainter() {
    scrollbarPainter
      ..color = CupertinoDynamicColor.resolve(_kScrollbarColor, context)
      ..textDirection = Directionality.of(context)
      ..thickness = _thickness
      ..mainAxisMargin = _kScrollbarMainAxisMargin
      ..crossAxisMargin = _kScrollbarCrossAxisMargin
      ..radius = _radius
      ..padding = MediaQuery.of(context).padding
      ..minLength = _kScrollbarMinLength
      ..minOverscrollLength = _kScrollbarMinOverscrollLength
      ..scrollbarOrientation = widget().scrollbarOrientation;
  }

  double _pressStartAxisPosition = 0.0;

  // Long press event callbacks handle the gesture where the user long presses
  // on the scrollbar thumb and then drags the scrollbar without releasing.

  @override
  void handleThumbPressStart(Offset localPosition) {
    super.handleThumbPressStart(localPosition);
    final Axis direction = getScrollbarDirection()!;
    switch (direction) {
      case Axis.vertical:
        _pressStartAxisPosition = localPosition.dy;
        break;
      case Axis.horizontal:
        _pressStartAxisPosition = localPosition.dx;
        break;
    }
  }

  @override
  void handleThumbPress() {
    if (getScrollbarDirection() == null) {
      return;
    }
    super.handleThumbPress();
    _thicknessAnimationController.forward().then<void>(
          (_) => HapticFeedback.mediumImpact(),
    );
  }

  @override
  void handleThumbPressEnd(Offset localPosition, Velocity velocity) {
    final Axis? direction = getScrollbarDirection();
    if (direction == null) {
      return;
    }
    _thicknessAnimationController.reverse();
    super.handleThumbPressEnd(localPosition, velocity);
    switch(direction) {
      case Axis.vertical:
        if (velocity.pixelsPerSecond.dy.abs() < 10 &&
          (localPosition.dy - _pressStartAxisPosition).abs() > 0) {
          HapticFeedback.mediumImpact();
        }
        break;
      case Axis.horizontal:
        if (velocity.pixelsPerSecond.dx.abs() < 10 &&
          (localPosition.dx - _pressStartAxisPosition).abs() > 0) {
          HapticFeedback.mediumImpact();
        }
        break;
    }
  }

  @override
  void dispose() {
    _thicknessAnimationController.dispose();
    super.dispose();
  }
}
