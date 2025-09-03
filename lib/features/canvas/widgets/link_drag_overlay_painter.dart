import 'package:flutter/material.dart';

/// 드래그 중 임시 링커 사각형만 그리는 오버레이 페인터
class LinkDragOverlayPainter extends CustomPainter {
  final Offset? currentDragStart;
  final Offset? currentDragEnd;
  final Color currentFillColor;
  final Color currentBorderColor;
  final double currentBorderWidth;

  const LinkDragOverlayPainter({
    required this.currentDragStart,
    required this.currentDragEnd,
    required this.currentFillColor,
    required this.currentBorderColor,
    required this.currentBorderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentDragStart == null || currentDragEnd == null) return;

    final rect = Rect.fromPoints(currentDragStart!, currentDragEnd!);

    final fill = Paint()
      ..color = currentFillColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = currentBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentBorderWidth;

    canvas.drawRect(rect, fill);
    canvas.drawRect(rect, stroke);
  }

  @override
  bool shouldRepaint(covariant LinkDragOverlayPainter oldDelegate) {
    return oldDelegate.currentDragStart != currentDragStart ||
        oldDelegate.currentDragEnd != currentDragEnd ||
        oldDelegate.currentFillColor != currentFillColor ||
        oldDelegate.currentBorderColor != currentBorderColor ||
        oldDelegate.currentBorderWidth != currentBorderWidth;
  }
}
