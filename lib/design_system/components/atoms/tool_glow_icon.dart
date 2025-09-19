// lib/design_system/components/atoms/tool_glow_icon.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';

enum ToolAccent { none, black, red, blue, green, yellow }

class ToolGlowIcon extends StatelessWidget {
  const ToolGlowIcon({
    super.key,
    required this.svgPath,
    this.onTap,
    this.accent = ToolAccent.none, // none이면 하이라이트 없음
    this.glowColor,                  // NEW: 원하는 색으로 바로 발광
    this.size = 32,                // 아이콘 크기 (툴바 세컨드라인은 20~24 추천)
    this.glowDiameter,             // null이면 size + 12
    this.blurSigma = 8,           // Figma Layer blur에 대응 (적당한 값 8~12)
    this.iconColor = AppColors.gray50,
    this.semanticLabel,
  });

  final String svgPath;
  final VoidCallback? onTap;

  /// 선택된 색상(하이라이트 색)
  final ToolAccent accent;

  final Color? glowColor;            // 여기에 AppColors.primary 넘기면 됨

  /// 아이콘 크기(px)
  final double size;

  /// 블러가 적용될 원의 지름(px)
  final double? glowDiameter;

  /// 가우시안 블러 세기
  final double blurSigma;

  /// 아이콘 선 색(보통 gray50 유지)
  final Color iconColor;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final glowSize = glowDiameter ?? (size + 12);
    final bool   glowOn     = glowColor != null;
    final Color? resolved = glowColor;

    final icon = SvgPicture.asset(
      svgPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );

    return InkResponse(
      onTap: onTap,
      radius: size + AppSpacing.small,
      child: SizedBox(
        width: glowSize, height: glowSize,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (glowOn) // resolved != null
              RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                  child: Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: BoxDecoration(
                      color: resolved,   // ← 이미 알파 포함된 색을 그대로 사용
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            icon,
          ],
        ),
      ),
    );
  }

  
}
