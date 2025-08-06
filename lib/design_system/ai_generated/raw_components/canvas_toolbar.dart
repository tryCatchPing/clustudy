import 'package:flutter/material.dart';
import './color_palette.dart';
import './tool_selector.dart';
import './action_controls.dart';
import './navigation_section.dart';
import '../../tokens/app_colors.dart';

/// Organism component: Complete canvas toolbar
/// Combines all toolbar sections into a cohesive interface
class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    Key? key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.selectedPenType,
    required this.onPenTypeChanged,
    required this.selectedThickness,
    required this.onThicknessChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onNewNote,
    required this.onNoteSelect,
    required this.onSettings,
    required this.onPage,
    required this.onLinks,
    required this.onAddElement,
    this.currentNoteName = '(Current Note)',
    this.canUndo = true,
    this.canRedo = true,
    this.height = 61.0,
  }) : super(key: key);

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final int selectedPenType;
  final ValueChanged<int> onPenTypeChanged;
  final int selectedThickness;
  final ValueChanged<int> onThicknessChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onNewNote;
  final VoidCallback onNoteSelect;
  final VoidCallback onSettings;
  final VoidCallback onPage;
  final VoidCallback onLinks;
  final VoidCallback onAddElement;
  final String currentNoteName;
  final bool canUndo;
  final bool canRedo;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.toolbarBackground,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Navigation toggle
          NavigationSection(
            onNewNote: onNewNote,
            onNoteSelect: onNoteSelect,
            currentNoteName: currentNoteName,
          ),

          // Pen color selector
          PenColorPalette(
            selectedColor: selectedColor,
            onColorSelected: onColorChanged,
          ),

          // Pen type selector
          PenTypeSelector(
            selectedType: selectedPenType,
            onTypeSelected: onPenTypeChanged,
          ),

          // Pen thickness selector
          PenThicknessSelector(
            selectedThickness: selectedThickness,
            onThicknessSelected: onThicknessChanged,
          ),

          // Undo/Redo controls
          SimpleActionControls(
            onUndo: onUndo,
            onRedo: onRedo,
            canUndo: canUndo,
            canRedo: canRedo,
          ),

          // Settings menu
          MenuSection(
            onSettings: onSettings,
            onPage: onPage,
            onLinks: onLinks,
            onAddElement: onAddElement,
          ),
        ],
      ),
    );
  }
}

/// Simplified canvas toolbar for basic functionality
class SimpleCanvasToolbar extends StatelessWidget {
  const SimpleCanvasToolbar({
    Key? key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.onUndo,
    required this.onRedo,
    this.canUndo = true,
    this.canRedo = true,
    this.height = 61.0,
  }) : super(key: key);

  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.toolbarBackground,
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pen color selector
          PenColorPalette(
            selectedColor: selectedColor,
            onColorSelected: onColorChanged,
          ),

          const SizedBox(width: 16),

          // Undo/Redo controls
          SimpleActionControls(
            onUndo: onUndo,
            onRedo: onRedo,
            canUndo: canUndo,
            canRedo: canRedo,
          ),
        ],
      ),
    );
  }
}