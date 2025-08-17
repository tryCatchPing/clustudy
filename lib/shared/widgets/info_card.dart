import 'package:flutter/material.dart';

/// 📝 정보 표시 카드 위젯
///
/// 중요한 정보나 상태를 표시하는 카드 위젯입니다.
/// 색상과 아이콘을 커스터마이징할 수 있습니다.
class InfoCard extends StatelessWidget {
  /// 카드에 표시될 메시지.
  final String message;

  /// 카드에 표시될 아이콘.
  final IconData icon;

  /// 카드의 주 색상.
  final Color color;

  /// 카드의 배경 색상. (선택 사항)
  final Color? backgroundColor;

  /// 카드의 테두리 색상. (선택 사항)
  final Color? borderColor;

  /// [InfoCard]의 기본 생성자.
  ///
  /// [message]는 카드에 표시될 메시지입니다.
  /// [icon]은 카드에 표시될 아이콘입니다 (기본값: [Icons.info_outline]).
  /// [color]는 카드의 주 색상입니다 (기본값: [Colors.amber]).
  /// [backgroundColor]는 카드의 배경 색상입니다.
  /// [borderColor]는 카드의 테두리 색상입니다.
  const InfoCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = Colors.amber,
    this.backgroundColor,
    this.borderColor,
  });

  /// 경고용 정보 카드 (노란색)를 생성하는 팩토리 생성자.
  ///
  /// [message]는 카드에 표시될 메시지입니다.
  /// [icon]은 카드에 표시될 아이콘입니다 (기본값: [Icons.warning_outlined]).
  const InfoCard.warning({
    super.key,
    required this.message,
    this.icon = Icons.warning_outlined,
  }) : color = Colors.amber,
       backgroundColor = null,
       borderColor = null;

  /// 성공용 정보 카드 (초록색)를 생성하는 팩토리 생성자.
  ///
  /// [message]는 카드에 표시될 메시지입니다.
  /// [icon]은 카드에 표시될 아이콘입니다 (기본값: [Icons.check_circle_outline]).
  const InfoCard.success({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_outline,
  }) : color = Colors.green,
       backgroundColor = null,
       borderColor = null;

  /// 에러용 정보 카드 (빨간색)를 생성하는 팩토리 생성자.
  ///
  /// [message]는 카드에 표시될 메시지입니다.
  /// [icon]은 카드에 표시될 아이콘입니다 (기본값: [Icons.error_outline]).
  const InfoCard.error({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
  }) : color = Colors.red,
       backgroundColor = null,
       borderColor = null;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? color.withAlpha((255 * 0.08).round());
    final effectiveBorderColor = borderColor ?? color.withAlpha((255 * 0.2).round());
    final effectiveTextColor = color.withAlpha((255 * 0.85).round());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveBorderColor, width: 0.5),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: effectiveTextColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
