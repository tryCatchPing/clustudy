import 'dart:ui' show clampDouble;

import 'package:flutter/widgets.dart';

/// PageView용 관성 감소 스크롤 물리.
///
/// [PageScrollPhysics]가 생성하는 ballistic simulation에 진입하기 전에
/// 속도를 [velocityFactor]만큼 줄이고, 기본 스프링보다 더 큰 감쇠비를 적용해
/// 관성 구간을 짧게 만듭니다.
class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({
    super.parent,
    this.velocityFactor = 0.3,
    this.dampingRatio = 1.35,
  }) : assert(velocityFactor > 0 && velocityFactor <= 1.0),
       assert(dampingRatio >= 1.0);

  /// 0~1 사이 비율. 낮을수록 관성이 빨리 멈춥니다.
  final double velocityFactor;
  final double dampingRatio;

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(
      parent: buildParent(ancestor),
      velocityFactor: velocityFactor,
      dampingRatio: dampingRatio,
    );
  }

  double _pageFor(ScrollMetrics position) {
    if (position is PageMetrics) {
      return position.page ?? 0.0;
    }
    if (position.viewportDimension == 0) {
      return 0.0;
    }
    return position.pixels / position.viewportDimension;
  }

  double _pixelsFor(ScrollMetrics position, double page) {
    if (position is PageMetrics) {
      final metrics = position;
      return page * metrics.viewportDimension * metrics.viewportFraction;
    }
    return page * position.viewportDimension;
  }

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    double page = _pageFor(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    final pixels = _pixelsFor(position, page.roundToDouble());
    return clampDouble(
      pixels,
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final scaledVelocity = velocity * velocityFactor;
    if ((scaledVelocity <= 0.0 &&
            position.pixels <= position.minScrollExtent) ||
        (scaledVelocity >= 0.0 &&
            position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, scaledVelocity);
    }
    final tolerance = toleranceFor(position);
    final double target = _targetPixels(position, tolerance, scaledVelocity);
    if (target == position.pixels) {
      return null;
    }
    final springDescription = SpringDescription.withDampingRatio(
      mass: 1.0,
      stiffness: spring.stiffness,
      ratio: dampingRatio,
    );
    return ScrollSpringSimulation(
      springDescription,
      position.pixels,
      target,
      scaledVelocity,
      tolerance: tolerance,
    );
  }
}
