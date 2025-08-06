import 'package:flutter/material.dart';

import './toolbar_button.dart';
import './toolbar_section.dart';

/// Molecular component: Action controls (undo/redo)
/// Groups action buttons in a vertical toolbar section
class ActionControls extends StatelessWidget {
  const ActionControls({
    super.key,
    required this.onUndo,
    required this.onRedo,
    this.canUndo = true,
    this.canRedo = true,
    this.width = 40.0,
  });

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ToolbarSection(
      width: width,
      children: [
        ToolbarButton(
          onPressed: canRedo ? onRedo : null,
          child: Transform.rotate(
            angle: 0, // Forward arrow for redo
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ),
        ),
        ToolbarButton(
          onPressed: canUndo ? onUndo : null,
          child: Transform.rotate(
            angle: 3.14159, // Backward arrow for undo
            child: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Alternative simple undo/redo controls with text - HORIZONTAL LAYOUT
class SimpleActionControls extends StatelessWidget {
  const SimpleActionControls({
    super.key,
    required this.onUndo,
    required this.onRedo,
    this.canUndo = true,
    this.canRedo = true,
    this.width = 88.0, // Figma design width
  });

  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40, // Figma design height
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ToolbarButton(
            onPressed: canUndo ? onUndo : null,
            size: 32,
            child: const Text(
              '<',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          ToolbarButton(
            onPressed: canRedo ? onRedo : null,
            size: 32,
            child: const Text(
              '>',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
