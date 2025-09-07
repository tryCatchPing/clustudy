import 'package:flutter/material.dart';

/// 🌑 앱 전체에서 사용할 그림자 시스템
///
/// Figma 디자인 시스템을 기반으로 한 그림자 토큰입니다.
/// BoxDecoration에서 하드코딩된 그림자 대신 이 클래스를 사용해주세요.
///
/// 예시:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.medium,
///     borderRadius: BorderRadius.circular(12),
///   ),
/// )
/// ```
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

  /// (유틸) 필요 시 동적으로 커스터마이즈
  static List<BoxShadow> custom({
    double x = 0,
    double y = 2,
    double blur = 4,
    double spread = 0,
    double opacity = 0.25,
    Color base = Colors.black,
  }) =>
      [
        BoxShadow(
          color: base.withOpacity(opacity),
          offset: Offset(x, y),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];
}
