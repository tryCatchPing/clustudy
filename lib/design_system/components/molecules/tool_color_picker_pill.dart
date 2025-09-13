// lib/design_system/components/molecules/tool_color_picker_pill.dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';

class ToolColorPickerPill extends StatelessWidget {
  const ToolColorPickerPill({
    super.key,
    required this.colors,                 // 표시할 색들 (좌→우)
    required this.selected,               // 현재 선택된 색
    required this.onSelect,               // 탭 시 선택 콜백
    this.dotSize = 24,                    // 원 크기
    this.gap = AppSpacing.small,          // 8px
    this.horizontal = AppSpacing.medium,  // 16px
    this.vertical = 8,                    // 8px
    this.borderWidth = 1.5,
    this.borderColor = AppColors.gray50,
    this.radius = 30,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  final double dotSize;
  final double gap;
  final double horizontal;
  final double vertical;
  final double borderWidth;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < colors.length; i++) ...[
              _ColorDot(
                color: colors[i],
                selected: colors[i].value == selected.value,
                size: dotSize,
                onTap: () => onSelect(colors[i]),
              ),
              if (i != colors.length - 1) SizedBox(width: gap),
            ],
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 터치 여유(48px 미니멈 히트 권장)
    final double hit = size < 40 ? 40 : size;

    return InkResponse(
      onTap: onTap,
      radius: hit / 2,
      containedInkWell: false,
      child: SizedBox(
        width: hit,
        height: hit,
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.background : Colors.transparent,
                width: selected ? 2 : 0,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
