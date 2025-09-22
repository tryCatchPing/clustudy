import 'dart:ui' as ui show ImageFilter;

import 'package:flutter/material.dart';

class AppShadows {
  // Private constructor to prevent instantiation
  AppShadows._();

  /// Base drop shadow (바깥쪽)
  /// x=0, y=2, blur=4, spread=0, color=#000000 @25%
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x40000000), // #000000 with 25% opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// (선택) 조금 더 떠 보이게 하고 싶을 때
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x33000000), // 20%
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  /// (선택) 카드/모달 등 깊은 느낌
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x2A000000), // ~16%
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static Widget shadowizeVector({
    required double width,
    required double height,
    required Widget child,
    double y = 2,
    double sigma = 4,
    Color color = const Color(0x40000000),
    double? borderRadius,
  }) {
    Widget content({bool forShadow = false}) {
      final c = forShadow
          ? ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: child,
            )
          : child;

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: c,
        );
      }
      return c;
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            top: y,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: content(forShadow: true),
            ),
          ),
          Positioned.fill(child: content()),
        ],
      ),
    );
  }
}
