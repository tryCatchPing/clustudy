// AI Generated code from Figma design
// Original HTML/CSS code converted to Flutter - DO NOT EDIT DIRECTLY
// This file serves as reference for creating proper atomic design components

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// Original Figma design converted to Flutter
/// This represents the main toolbar layout from the Figma design
class FigmaVaultManage extends StatelessWidget {
  const FigmaVaultManage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.toolbarBackground,
      child: Column(
        children: [
          // Top toolbar
          Container(
            height: 61,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navigation toggle
                _buildNavigationToggle(),
                
                // Pen color selector
                _buildPenColorSelector(),
                
                // Pen type selector
                _buildPenTypeSelector(),
                
                // Pen thickness selector
                _buildPenThicknessSelector(),
                
                // Undo/Redo controls
                _buildUndoRedoControls(),
                
                // Settings toggle
                _buildSettingsToggle(),
              ],
            ),
          ),
          
          // Main content area with two note pages
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left note page
                Container(
                  width: 477.5,
                  height: 477.5,
                  decoration: BoxDecoration(
                    color: AppColors.noteBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(width: 100), // Gap between pages
                // Right note page
                Container(
                  width: 477.5,
                  height: 477.5,
                  decoration: BoxDecoration(
                    color: AppColors.noteBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationToggle() {
    return Container(
      width: 40,
      height: 402,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('+', style: TextStyle(fontSize: 15)),
          const Text('note', style: TextStyle(fontSize: 15)),
          const Text('note', style: TextStyle(fontSize: 15)),
          Container(
            width: 188,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.selectedItem,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text('(Current Note)', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPenColorSelector() {
    return Container(
      width: 40,
      height: 154,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildColorCircle(AppColors.penRed),
          _buildColorCircle(AppColors.penBlue),
          _buildColorCircle(AppColors.penGreen),
          _buildColorCircle(AppColors.penBlack),
        ],
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPenTypeSelector() {
    return Container(
      width: 40,
      height: 155,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(true), // Selected tool
        ],
      ),
    );
  }

  Widget _buildPenThicknessSelector() {
    return Container(
      width: 40,
      height: 204,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(true), // Selected thickness
        ],
      ),
    );
  }

  Widget _buildToolButton(bool isSelected) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.penBlack : null,
        border: Border.all(color: AppColors.toolbarBorder),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildUndoRedoControls() {
    return Container(
      width: 40,
      height: 88,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildUndoRedoButton('>'),
          _buildUndoRedoButton('<'),
        ],
      ),
    );
  }

  Widget _buildUndoRedoButton(String icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  Widget _buildSettingsToggle() {
    return Container(
      width: 40,
      height: 256,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text('setting', style: TextStyle(fontSize: 15)),
          const Text('page', style: TextStyle(fontSize: 15)),
          const Text('links', style: TextStyle(fontSize: 15)),
          const Text('+elem', style: TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}