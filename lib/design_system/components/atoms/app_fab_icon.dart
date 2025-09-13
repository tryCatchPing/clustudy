import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_shadows.dart';

class AppFabIcon extends StatelessWidget {
  const AppFabIcon({
    super.key,
    required this.svgPath,
    required this.onPressed,
    this.diameter = 60, // ⬅︎ radius 30 → 지름 60
    this.iconSize = 16, // 아이콘 32px
    this.backgroundColor = AppColors.gray10,
    this.iconColor = AppColors.gray50,
    this.tooltip,
    this.shadows = AppShadows.medium, // 토큰 그림자
  });

  final String svgPath;
  final VoidCallback onPressed;
  final double diameter;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;
  final String? tooltip;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(diameter / 2);

    final child = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius, // radius = 30 (기본)
        boxShadow: shadows, // 예: (0,2,4) 등
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: Tooltip(message: tooltip ?? '', child: child),
      ),
    );
  }
}
