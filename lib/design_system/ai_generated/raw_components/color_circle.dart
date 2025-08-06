import 'package:flutter/material.dart';

/// Atomic component: Color selection circle
/// Used in color pickers and palettes
class ColorCircle extends StatelessWidget {
  const ColorCircle({
    Key? key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
    this.size = 32.0,
    this.borderWidth = 2.0,
    this.borderColor,
  }) : super(key: key);

  final Color color;
  final VoidCallback onTap;
  final bool isSelected;
  final double size;
  final double borderWidth;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected && borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        ),
        child: isSelected
          ? Icon(
              Icons.check,
              color: _getContrastColor(color),
              size: size * 0.5,
            )
          : null,
      ),
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if white or black text is more readable
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}