import 'package:flutter/material.dart';

/// 📝 정보 표시 카드 위젯
///
/// 중요한 정보나 상태를 표시하는 카드 위젯입니다.
/// 색상과 아이콘을 커스터마이징할 수 있습니다.
class InfoCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final Color? borderColor;

  const InfoCard({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = Colors.amber,
    this.backgroundColor,
    this.borderColor,
  });

  /// 경고용 정보 카드 (노란색)
  const InfoCard.warning({
    super.key,
    required this.message,
    this.icon = Icons.warning_outlined,
  }) : color = Colors.amber,
       backgroundColor = null,
       borderColor = null;

  /// 성공용 정보 카드 (초록색)
  const InfoCard.success({
    super.key,
    required this.message,
    this.icon = Icons.check_circle_outline,
  }) : color = Colors.green,
       backgroundColor = null,
       borderColor = null;

  /// 에러용 정보 카드 (빨간색)
  const InfoCard.error({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
  }) : color = Colors.red,
       backgroundColor = null,
       borderColor = null;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor =
        backgroundColor ?? color.withValues(alpha: 0.1);
    final effectiveBorderColor = borderColor ?? color.withValues(alpha: 0.3);
    final effectiveTextColor = color.withValues(alpha: 0.9);
    final effectiveIconColor = color.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effectiveBorderColor),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: effectiveIconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: effectiveTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
