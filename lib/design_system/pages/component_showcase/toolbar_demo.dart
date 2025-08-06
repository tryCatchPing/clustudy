import 'package:flutter/material.dart';

import '../../ai_generated/raw_components/action_controls.dart';
import '../../ai_generated/raw_components/color_palette.dart';
import '../../ai_generated/raw_components/navigation_section.dart';
import '../../ai_generated/raw_components/tool_selector.dart';
import '../../tokens/app_colors.dart';

/// 🔧 툴바 컴포넌트 개별 데모 페이지
///
/// 각 툴바 컴포넌트를 격리된 환경에서 테스트하고 상호작용할 수 있는 페이지
class ToolbarDemo extends StatefulWidget {
  const ToolbarDemo({super.key});

  @override
  State<ToolbarDemo> createState() => _ToolbarDemoState();
}

class _ToolbarDemoState extends State<ToolbarDemo> {
  // ================== State Management ==================
  Color selectedColor = AppColors.penRed;
  int selectedPenType = 0;
  int selectedThickness = 2;
  String currentNoteName = 'Demo Note';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================== Page Header ==================
            const Row(
              children: [
                Icon(Icons.build_circle, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Toolbar Components',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Individual toolbar components in isolation for testing and development',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // ================== Component Showcase ==================
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                // Color Palette Demo
                _buildComponentCard(
                  title: 'Color Palette',
                  description: 'Pen color selection with predefined colors',
                  child: PenColorPalette(
                    selectedColor: selectedColor,
                    onColorSelected: (color) {
                      setState(() {
                        selectedColor = color;
                      });
                      _showSnackBar('Selected color: ${_getColorName(color)}');
                    },
                  ),
                ),

                // Tool Selector Demo
                _buildComponentCard(
                  title: 'Pen Type Selector',
                  description: 'Different pen types for drawing',
                  child: PenTypeSelector(
                    selectedType: selectedPenType,
                    onTypeSelected: (type) {
                      setState(() {
                        selectedPenType = type;
                      });
                      _showSnackBar(
                        'Selected pen type: ${PenTypeSelector.penTypes[type].name}',
                      );
                    },
                  ),
                ),

                // Thickness Selector Demo
                _buildComponentCard(
                  title: 'Pen Thickness Selector',
                  description: 'Adjustable pen thickness levels',
                  child: PenThicknessSelector(
                    selectedThickness: selectedThickness,
                    onThicknessSelected: (thickness) {
                      setState(() {
                        selectedThickness = thickness;
                      });
                      _showSnackBar(
                        'Selected thickness: ${PenThicknessSelector.thicknessOptions[thickness].name}',
                      );
                    },
                  ),
                ),

                // Action Controls Demo
                _buildComponentCard(
                  title: 'Action Controls',
                  description: 'Undo and redo functionality',
                  child: SimpleActionControls(
                    onUndo: () => _showSnackBar('Undo action triggered'),
                    onRedo: () => _showSnackBar('Redo action triggered'),
                    canUndo: true,
                    canRedo: true,
                  ),
                ),

                // Navigation Section Demo
                _buildComponentCard(
                  title: 'Navigation Section',
                  description: 'Note navigation and current note display',
                  child: NavigationSection(
                    onNewNote: () {
                      setState(() {
                        currentNoteName =
                            'New Note ${DateTime.now().millisecond}';
                      });
                      _showSnackBar('Created: $currentNoteName');
                    },
                    onNoteSelect: () => _showSnackBar('Note selection opened'),
                    currentNoteName: currentNoteName,
                  ),
                ),

                // Menu Section Demo
                _buildComponentCard(
                  title: 'Menu Section',
                  description: 'Settings and additional options',
                  child: MenuSection(
                    onSettings: () => _showSnackBar('Settings opened'),
                    onPage: () => _showSnackBar('Page options opened'),
                    onLinks: () => _showSnackBar('Links panel opened'),
                    onAddElement: () =>
                        _showSnackBar('Add element panel opened'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ================== Current State Display ==================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Current State',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStateRow(
                      'Selected Color:',
                      _getColorName(selectedColor),
                    ),
                    _buildStateRow(
                      'Pen Type:',
                      PenTypeSelector.penTypes[selectedPenType].name,
                    ),
                    _buildStateRow(
                      'Thickness:',
                      PenThicknessSelector
                          .thicknessOptions[selectedThickness]
                          .name,
                    ),
                    _buildStateRow('Current Note:', currentNoteName),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Center(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildStateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == AppColors.penRed) return 'Red';
    if (color == AppColors.penBlue) return 'Blue';
    if (color == AppColors.penGreen) return 'Green';
    if (color == AppColors.penBlack) return 'Black';
    return 'Unknown';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
