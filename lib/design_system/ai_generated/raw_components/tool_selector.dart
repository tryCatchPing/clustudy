import 'package:flutter/material.dart';
import './toolbar_button.dart';
import './toolbar_section.dart';

/// Molecular component: Tool selection interface
/// Displays available tools in a vertical toolbar section
class ToolSelector extends StatelessWidget {
  const ToolSelector({
    Key? key,
    required this.tools,
    required this.selectedTool,
    required this.onToolSelected,
    this.width = 40.0,
  }) : super(key: key);

  final List<ToolOption> tools;
  final int selectedTool;
  final ValueChanged<int> onToolSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ToolbarSection(
      width: width,
      children: tools.asMap().entries.map((entry) {
        int index = entry.key;
        ToolOption tool = entry.value;
        
        return ToolbarButton(
          isSelected: index == selectedTool,
          icon: tool.icon,
          onPressed: () => onToolSelected(index),
          child: tool.customWidget,
        );
      }).toList(),
    );
  }
}

/// Represents a tool option in the selector
class ToolOption {
  const ToolOption({
    this.icon,
    this.customWidget,
    required this.name,
  });

  final IconData? icon;
  final Widget? customWidget;
  final String name;
}

/// Predefined pen type selector based on Figma design - HORIZONTAL LAYOUT
class PenTypeSelector extends StatelessWidget {
  const PenTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  final int selectedType;
  final ValueChanged<int> onTypeSelected;

  static const List<ToolOption> penTypes = [
    ToolOption(icon: Icons.edit, name: 'Pen'),
    ToolOption(icon: Icons.brush, name: 'Brush'),
    ToolOption(icon: Icons.create, name: 'Marker'),
    ToolOption(icon: Icons.highlight, name: 'Highlighter'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155, // Figma design width
      height: 40, // Figma design height
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: penTypes.asMap().entries.map((entry) {
          int index = entry.key;
          return ToolbarButton(
            isSelected: index == selectedType,
            icon: entry.value.icon,
            onPressed: () => onTypeSelected(index),
            size: 32,
          );
        }).toList(),
      ),
    );
  }
}

/// Predefined pen thickness selector - HORIZONTAL LAYOUT
class PenThicknessSelector extends StatelessWidget {
  const PenThicknessSelector({
    Key? key,
    required this.selectedThickness,
    required this.onThicknessSelected,
  }) : super(key: key);

  final int selectedThickness;
  final ValueChanged<int> onThicknessSelected;

  static List<ToolOption> get thicknessOptions => [
    ToolOption(
      customWidget: _ThicknessIndicator(size: 2),
      name: 'Extra Thin',
    ),
    ToolOption(
      customWidget: _ThicknessIndicator(size: 4),
      name: 'Thin',
    ),
    ToolOption(
      customWidget: _ThicknessIndicator(size: 6),
      name: 'Medium',
    ),
    ToolOption(
      customWidget: _ThicknessIndicator(size: 8),
      name: 'Thick',
    ),
    ToolOption(
      customWidget: _ThicknessIndicator(size: 12),
      name: 'Extra Thick',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 204, // Figma design width
      height: 40, // Figma design height
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: thicknessOptions.asMap().entries.map((entry) {
          int index = entry.key;
          return ToolbarButton(
            isSelected: index == selectedThickness,
            child: entry.value.customWidget,
            onPressed: () => onThicknessSelected(index),
            size: 32,
          );
        }).toList(),
      ),
    );
  }
}

class _ThicknessIndicator extends StatelessWidget {
  const _ThicknessIndicator({required this.size});
  
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}