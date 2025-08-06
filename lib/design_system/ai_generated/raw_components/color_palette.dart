import 'package:flutter/material.dart';
import './color_circle.dart';
import './toolbar_section.dart';
import '../../tokens/app_colors.dart';

/// Molecular component: Color selection palette
/// Displays available colors in a vertical toolbar section
class ColorPalette extends StatelessWidget {
  const ColorPalette({
    Key? key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
    this.width = 40.0,
    this.colorSize = 32.0,
  }) : super(key: key);

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final double width;
  final double colorSize;

  @override
  Widget build(BuildContext context) {
    return ToolbarSection(
      width: width,
      children: colors.map((color) => 
        ColorCircle(
          color: color,
          isSelected: color == selectedColor,
          size: colorSize,
          borderColor: AppColors.toolbarBorder,
          onTap: () => onColorSelected(color),
        ),
      ).toList(),
    );
  }
}

/// Predefined pen color palette based on Figma design - HORIZONTAL LAYOUT
class PenColorPalette extends StatelessWidget {
  const PenColorPalette({
    Key? key,
    required this.selectedColor,
    required this.onColorSelected,
  }) : super(key: key);

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  static const List<Color> penColors = [
    AppColors.penRed,
    AppColors.penBlue,
    AppColors.penGreen,
    AppColors.penBlack,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154, // Figma design width
      height: 40, // Figma design height
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: penColors.map((color) => 
          ColorCircle(
            color: color,
            isSelected: color == selectedColor,
            size: 32,
            borderColor: AppColors.toolbarBorder,
            onTap: () => onColorSelected(color),
          ),
        ).toList(),
      ),
    );
  }
}