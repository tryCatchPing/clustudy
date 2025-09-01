import 'package:flutter/material.dart';

/// 캔버스에서 사용할 기본 색상들
enum CanvasColor {
  /// 숯색 (검정)
  charcoal('검정', Color(0xFF1A1A1A)),

  /// 사파이어색 (파랑)
  sapphire('파랑', Color(0xFF1A5DBA)),

  /// 숲색 (녹색)
  forest('녹색', Color(0xFF277A3E)),

  /// 진홍색 (빨강)
  crimson('빨강', Color(0xFFC72C2C));

  /// [displayName]은 사용자에게 표시할 한글 이름입니다.
  /// [color]는 실제 Color 값입니다.
  const CanvasColor(this.displayName, this.color);

  /// 사용자에게 표시할 한글 이름
  final String displayName;

  /// 실제 Color 값
  final Color color;

  /// 하이라이터용 반투명 색상 (50% 투명도)
  Color get highlighterColor => color.withAlpha(50);

  /// 지정된 투명도로 색상 생성
  /// [opacity]는 0.0부터 1.0까지의 투명도 값입니다.
  Color withOpacity(double opacity) => color.withAlpha((255 * opacity).round());

  /// 모든 색상 리스트 (UI 구성용)
  static List<CanvasColor> get all => CanvasColor.values;

  /// 기본 색상 (첫 번째 색상)
  static CanvasColor get defaultColor => CanvasColor.charcoal;
}
