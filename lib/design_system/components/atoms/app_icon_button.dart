// lib/design_system/components/atoms/app_icon_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AppIconButtonSize { sm, md, lg }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.svgPath,
    this.onPressed,
    this.size = AppIconButtonSize.md,
    this.tooltip,
    this.semanticLabel,
    this.shape = const CircleBorder(), // 필요하면 RoundedRectangleBorder로
    this.color,
  });

  final String svgPath;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final String? tooltip;
  final String? semanticLabel;
  final OutlinedBorder shape;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final side = switch (size) { // 최소 터치영역
      AppIconButtonSize.sm => 36.0,
      AppIconButtonSize.md => 40.0,
      AppIconButtonSize.lg => 48.0,
    };
    final iconSize = switch (size) {
      AppIconButtonSize.sm => 18.0,
      AppIconButtonSize.md => 20.0,
      AppIconButtonSize.lg => 24.0,
    };

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip ?? semanticLabel,
      iconSize: iconSize,
      style: IconButton.styleFrom(
        minimumSize: Size(side, side),
        padding: EdgeInsets.zero,
        shape: shape, // 기본 원형
        // 배경/테두리/foreground 색 계산 없음
      ),
      icon: SvgPicture.asset(
        svgPath,
        width: iconSize,
        height: iconSize,
        // 색은 SVG 원본 그대로 사용 (tint 없음)
        semanticsLabel: semanticLabel,
      ),
    );
  }
}
