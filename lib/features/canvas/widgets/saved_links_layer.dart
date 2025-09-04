import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/link_providers.dart';

/// 저장된 링크 사각형을 그리는 레이어
class SavedLinksLayer extends ConsumerWidget {
  final String pageId;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  const SavedLinksLayer({
    super.key,
    required this.pageId,
    this.fillColor = const Color(0x80FF4081), // pinkAccent with alpha ~0.5
    this.borderColor = const Color(0xFFFF4081),
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rects = ref.watch(linkRectsByPageProvider(pageId));
    return CustomPaint(
      painter: _SavedLinksPainter(
        rects,
        fillColor: fillColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SavedLinksPainter extends CustomPainter {
  final List<Rect> rects;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  const _SavedLinksPainter(
    this.rects, {
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rects.isEmpty) return;
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    for (final r in rects) {
      canvas.drawRect(r, fill);
      canvas.drawRect(r, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SavedLinksPainter oldDelegate) {
    return oldDelegate.rects != rects ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
