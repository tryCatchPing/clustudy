import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';

/// Atomic component: Basic toolbar button
/// Used across various toolbar components for consistent styling and behavior
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    Key? key,
    required this.onPressed,
    this.child,
    this.icon,
    this.isSelected = false,
    this.backgroundColor,
    this.borderColor,
    this.size = 32.0,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected 
            ? (backgroundColor ?? AppColors.penBlack)
            : backgroundColor,
          border: Border.all(
            color: borderColor ?? AppColors.toolbarBorder,
          ),
          shape: BoxShape.circle,
        ),
        child: child ?? (icon != null 
          ? Icon(
              icon,
              color: isSelected ? AppColors.noteBackground : AppColors.penBlack,
              size: 16,
            )
          : null),
      ),
    );
  }
}