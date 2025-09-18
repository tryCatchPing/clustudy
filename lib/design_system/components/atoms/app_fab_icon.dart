import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import '../../tokens/app_colors.dart';
import '../../tokens/app_shadows.dart';

class AppFabIcon extends StatelessWidget {
  const AppFabIcon({
    super.key,
    required this.svgPath,
    required this.onPressed,
    this.visualDiameter = 36,
    this.minTapTarget = 44,
    this.iconSize = 16, // 아이콘 32px
    this.backgroundColor = AppColors.gray10,
    this.iconColor = AppColors.gray50,
    this.tooltip,
    this.shadows = AppShadows.medium, // 토큰 그림자
  });

  final String svgPath;
  final VoidCallback onPressed;
  final double visualDiameter;
  final double minTapTarget;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final String? tooltip;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final visualRadius = BorderRadius.circular(visualDiameter / 2);
    final inkRadius = math.max(visualDiameter, minTapTarget) / 2;

    final circle = Container(
      width: visualDiameter,
      height: visualDiameter,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: visualRadius,
        boxShadow: shadows,
      ),
      child: Center(
        child: SvgPicture.asset(
          svgPath,
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          semanticsLabel: tooltip,
        ),
      ),
    );

    final child = SizedBox(
      width: minTapTarget,
      height: minTapTarget,
      child: Center(child: tooltip == null ? circle : Tooltip(message: tooltip!, child: circle)),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(inkRadius),
        splashColor: AppColors.gray50.withOpacity(0.08),
        highlightColor: Colors.transparent,
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
