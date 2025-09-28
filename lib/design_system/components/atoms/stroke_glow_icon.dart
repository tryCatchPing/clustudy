// lib/design_system/components/atoms/stroke_glow_icon.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart'; // pubspec에 path_drawing 추가
import '../../tokens/app_colors.dart';

class StrokeGlowIcon extends StatelessWidget {
  const StrokeGlowIcon({
    super.key,
    required this.svgPathData, // <path d="..." /> 의 d 문자열
    this.size = 28,
    this.svgViewBox = 32,
    this.svgStroke = 1.5,
    this.color = AppColors.gray50,
    this.glowColor,
    this.glowSigma = 8.0, // 6~12 권장
    this.glowSpread = 2.0, // 글로우가 퍼지는 굵기
    this.onTap,
    this.semanticLabel,
  });

  final String svgPathData;
  final double size;
  final Color color;
  final double svgViewBox;
  final double svgStroke;

  /// null이면 글로우 없음
  final Color? glowColor;
  final double glowSigma;
  final double glowSpread;

  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    String _sanitizeSvgD(String d) {
      // 1) "1." -> "1.0", "-3." -> "-3.0"
      d = d.replaceAllMapped(RegExp(r'(\d+)\.(?!\d)'), (m) => '${m[1]}.0');
      // 2) "-.5" -> "-0.5"
      d = d.replaceAllMapped(RegExp(r'-(?=\.\d)'), (_) => '-0');
      // 3) ".5"  -> "0.5"
      d = d.replaceAllMapped(RegExp(r'(?<![\d-])\.(?=\d)'), (_) => '0.');
      return d;
    }

    final p = parseSvgPathData(_sanitizeSvgD(svgPathData));

    final scaleForStroke = size / svgViewBox;       // 28/32 = 0.875
    final strokePx       = svgStroke * scaleForStroke;
    final glowSpreadPx   = glowSpread * scaleForStroke;

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: InkResponse(
        onTap: onTap,
        radius: size * .8,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _StrokeGlowPainter(
              path: p,
              strokePx: strokePx,
              color: color,
              glowColor: glowColor,
              glowSigma: glowSigma,
              glowSpreadPx: glowSpreadPx,
            ),
          ),
        ),
      ),
    );
  }
}

class _StrokeGlowPainter extends CustomPainter {
  _StrokeGlowPainter({
    required this.path,
    required this.strokePx,
    required this.color,
    required this.glowColor,
    required this.glowSigma,
    required this.glowSpreadPx,
  });

  final Path path;
  final double strokePx;
  final Color color;
  final Color? glowColor;
  final double glowSigma;
  final double glowSpreadPx;

  @override
  void paint(Canvas canvas, Size size) {
    // 1) 원본 path를 캔버스 사이즈에 맞게 스케일
    final bounds = path.getBounds();
    final s = math.min(size.width / bounds.width, size.height / bounds.height);
    final p = path.transform(
      (Matrix4.identity()
            ..translate(-bounds.left, -bounds.top)
            ..scale(s, s)
            ..translate(
              (size.width - bounds.width * s) / s * .5,
              (size.height - bounds.height * s) / s * .5,
            ))
          .storage,
    );

    // 2) 글로우(아래층)
    if (glowColor != null) {
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter
        ..strokeMiterLimit = 2
        ..strokeWidth = strokePx + glowSpreadPx
        ..color = glowColor!
        ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowSigma);
      canvas.drawPath(p, glowPaint);
    }

    // 3) 실제 선(위층)
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokePx
      ..color = color;
    canvas.drawPath(p, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _StrokeGlowPainter old) =>
      old.strokePx != strokePx ||
      old.color != color ||
      old.glowColor != glowColor ||
      old.glowSigma != glowSigma ||
      old.glowSpreadPx != glowSpreadPx ||
      old.path != path;
}
