import 'package:flutter/material.dart';

// import './toolbar_section.dart'; // Not using ToolbarSection here
import '../../tokens/app_colors.dart';

/// Molecular component: Navigation section - HORIZONTAL LAYOUT
/// Handles navigation between notes and current note display
class NavigationSection extends StatelessWidget {
  const NavigationSection({
    super.key,
    required this.onNewNote,
    required this.onNoteSelect,
    required this.currentNoteName,
    this.width = 402.0, // Figma design width
    this.height = 40.0, // Figma design height
  });

  final VoidCallback onNewNote;
  final VoidCallback onNoteSelect;
  final String currentNoteName;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Note indicator (leftmost)
          _buildCurrentNoteIndicator(),
          // Note button
          GestureDetector(
            onTap: onNoteSelect,
            child: const Text(
              'note',
              style: TextStyle(fontSize: 15),
            ),
          ),
          // Note button
          GestureDetector(
            onTap: onNoteSelect,
            child: const Text(
              'note',
              style: TextStyle(fontSize: 15),
            ),
          ),
          // Plus button (rightmost)
          GestureDetector(
            onTap: onNewNote,
            child: const SizedBox(
              width: 20,
              child: Text(
                '+',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentNoteIndicator() {
    return Container(
      width: 188,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.selectedItem,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          currentNoteName,
          style: const TextStyle(fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Settings/menu section similar to navigation - HORIZONTAL LAYOUT
class MenuSection extends StatelessWidget {
  const MenuSection({
    super.key,
    required this.onSettings,
    required this.onPage,
    required this.onLinks,
    required this.onAddElement,
    this.width = 256.0, // Figma design width
    this.height = 40.0, // Figma design height
  });

  final VoidCallback onSettings;
  final VoidCallback onPage;
  final VoidCallback onLinks;
  final VoidCallback onAddElement;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.toolbarBorder),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onSettings,
            child: const Text(
              'setting',
              style: TextStyle(fontSize: 15),
            ),
          ),
          GestureDetector(
            onTap: onPage,
            child: const Text(
              'page',
              style: TextStyle(fontSize: 15),
            ),
          ),
          GestureDetector(
            onTap: onLinks,
            child: const Text(
              'links',
              style: TextStyle(fontSize: 15),
            ),
          ),
          GestureDetector(
            onTap: onAddElement,
            child: const Text(
              '+elem',
              style: TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
