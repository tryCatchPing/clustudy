// AI Generated code from Figma design - HORIZONTAL LAYOUT VERSION
// Original HTML/CSS code converted to Flutter - DO NOT EDIT DIRECTLY
// This file serves as reference for creating proper horizontal toolbar components

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// Updated Figma design converted to Flutter - HORIZONTAL TOOLBAR
/// This represents the horizontal toolbar layout from the updated Figma design
class FigmaVaultManageV2 extends StatelessWidget {
  const FigmaVaultManageV2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.toolbarBackground,
      child: Column(
        children: [
          // Top horizontal toolbar (updated layout)
          Container(
            height: 61,
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navigation toggle (horizontal)
                _buildNavigationSection(),
                
                // Pen color selector (horizontal)
                _buildColorSection(),
                
                // Pen type selector (horizontal)
                _buildPenTypeSection(),
                
                // Pen thickness selector (horizontal)
                _buildPenThicknessSection(),
                
                // Undo/Redo controls (horizontal)
                _buildUndoRedoSection(),
                
                // Settings menu (horizontal)
                _buildSettingsSection(),
              ],
            ),
          ),
          
          // Main content area with two note pages
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left note page (955px as per Figma)
                Container(
                  width: 477.5,
                  height: 477.5,
                  decoration: BoxDecoration(
                    color: AppColors.noteBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(width: 100), // Gap between pages
                // Right note page (955px as per Figma)
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

  // Navigation section - horizontal layout (402px width)
  Widget _buildNavigationSection() {
    return Container(
      width: 402,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Note indicator (leftmost)
          Container(
            width: 188,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.selectedItem,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Center(
              child: Text(
                '(Current Note)',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
          // Note button
          const Center(
            child: Text('note', style: TextStyle(fontSize: 15)),
          ),
          // Note button
          const Center(
            child: Text('note', style: TextStyle(fontSize: 15)),
          ),
          // Plus button
          const Center(
            child: Text('+', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Color section - horizontal layout (154px width)
  Widget _buildColorSection() {
    return Container(
      width: 154,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  // Pen type section - horizontal layout (155px width)
  Widget _buildPenTypeSection() {
    return Container(
      width: 155,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(false),
          _buildToolButton(true), // Selected tool
        ],
      ),
    );
  }

  // Pen thickness section - horizontal layout (204px width)
  Widget _buildPenThicknessSection() {
    return Container(
      width: 204,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

  // Undo/Redo section - horizontal layout (88px width)
  Widget _buildUndoRedoSection() {
    return Container(
      width: 88,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildUndoRedoButton('<'),
          _buildUndoRedoButton('>'),
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
        child: Text(icon, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Settings section - horizontal layout (256px width)
  Widget _buildSettingsSection() {
    return Container(
      width: 256,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Center(child: Text('setting', style: TextStyle(fontSize: 15))),
          const Center(child: Text('page', style: TextStyle(fontSize: 15))),
          const Center(child: Text('links', style: TextStyle(fontSize: 15))),
          const Center(child: Text('+elem', style: TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}