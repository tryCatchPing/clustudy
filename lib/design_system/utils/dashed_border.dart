// lib/design_system/utils/dashed_border.dart
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.gray50,
    this.strokeWidth = 1.0,
    this.dash = 6.0,
    this.gap = 4.0,
    this.radius = 8.0,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color, strokeWidth, dash, gap, radius),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter(
    this.color,
    this.strokeWidth,
    this.dash,
    this.gap,
    this.radius,
  );
  final Color color;
  final double strokeWidth, dash, gap, radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final next = d + dash;
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    // 이전 Painter의 속성과 현재 Painter의 속성이 하나라도 다르면 다시 그려야 함
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
  }
}
