import 'package:flutter/material.dart';

import '../../tokens/app_colors.dart';

/// Molecular component: Vertical toolbar section
/// Groups related toolbar buttons in a vertical container with consistent styling
class ToolbarSection extends StatelessWidget {
  const ToolbarSection({
    super.key,
    required this.children,
    this.width = 40.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
    this.spacing = 0,
    this.borderRadius = 25.0,
    this.backgroundColor,
    this.borderColor,
  });

  final List<Widget> children;
  final double width;
  final EdgeInsets padding;
  final double spacing;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor ?? AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: spacing > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildChildrenWithSpacing(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: children,
              ),
      ),
    );
  }

  List<Widget> _buildChildrenWithSpacing() {
    if (children.isEmpty) return [];

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }
    return spacedChildren;
  }
}
