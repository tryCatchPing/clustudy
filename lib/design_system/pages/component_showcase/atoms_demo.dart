import 'package:flutter/material.dart';

import '../../ai_generated/raw_components/color_circle.dart';
import '../../ai_generated/raw_components/toolbar_button.dart';
import '../../ai_generated/raw_components/toolbar_section.dart';
import '../../tokens/app_colors.dart';

/// ⚛️ 아토믹 컴포넌트 데모 페이지
///
/// 가장 기본적인 UI 요소들을 개별적으로 테스트하고 상호작용할 수 있는 페이지
class AtomsDemo extends StatefulWidget {
  const AtomsDemo({super.key});

  @override
  State<AtomsDemo> createState() => _AtomsDemoState();
}

class _AtomsDemoState extends State<AtomsDemo> {
  // ================== State Management ==================
  bool isButtonSelected = false;
  Color selectedAtomColor = AppColors.penRed;

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
                Icon(Icons.widgets, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                Text(
                  'Atomic Components',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Basic building blocks of the design system - buttons, circles, and containers',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // ================== Atomic Components Grid ==================
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                // Toolbar Button Demo
                _buildAtomCard(
                  title: 'Toolbar Button',
                  description: 'Basic interactive button with selection state',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ToolbarButton(
                                icon: Icons.edit,
                                isSelected: false,
                                onPressed: () =>
                                    _showSnackBar('Normal button pressed'),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Normal',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ToolbarButton(
                                icon: Icons.edit,
                                isSelected: true,
                                onPressed: () =>
                                    _showSnackBar('Selected button pressed'),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Selected',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ToolbarButton(
                                icon: Icons.edit,
                                isSelected: isButtonSelected,
                                onPressed: () {
                                  setState(() {
                                    isButtonSelected = !isButtonSelected;
                                  });
                                  _showSnackBar('Toggle: $isButtonSelected');
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toggle',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Color Circle Demo
                _buildAtomCard(
                  title: 'Color Circle',
                  description: 'Color selection with visual feedback',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ColorCircle(
                                color: AppColors.penRed,
                                isSelected:
                                    selectedAtomColor == AppColors.penRed,
                                borderColor: AppColors.toolbarBorder,
                                onTap: () {
                                  setState(() {
                                    selectedAtomColor = AppColors.penRed;
                                  });
                                  _showSnackBar('Red selected');
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text('Red', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              ColorCircle(
                                color: AppColors.penBlue,
                                isSelected:
                                    selectedAtomColor == AppColors.penBlue,
                                borderColor: AppColors.toolbarBorder,
                                onTap: () {
                                  setState(() {
                                    selectedAtomColor = AppColors.penBlue;
                                  });
                                  _showSnackBar('Blue selected');
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Blue',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ColorCircle(
                                color: AppColors.penGreen,
                                isSelected:
                                    selectedAtomColor == AppColors.penGreen,
                                borderColor: AppColors.toolbarBorder,
                                onTap: () {
                                  setState(() {
                                    selectedAtomColor = AppColors.penGreen;
                                  });
                                  _showSnackBar('Green selected');
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Green',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ColorCircle(
                                color: AppColors.penBlack,
                                isSelected:
                                    selectedAtomColor == AppColors.penBlack,
                                borderColor: AppColors.toolbarBorder,
                                onTap: () {
                                  setState(() {
                                    selectedAtomColor = AppColors.penBlack;
                                  });
                                  _showSnackBar('Black selected');
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Black',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Toolbar Section Demo
                _buildAtomCard(
                  title: 'Toolbar Section',
                  description: 'Container with border and padding',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ToolbarSection(
                                width: 50,
                                children: [
                                  ToolbarButton(
                                    icon: Icons.edit,
                                    isSelected: false,
                                    onPressed: () =>
                                        _showSnackBar('Section button 1'),
                                  ),
                                  ToolbarButton(
                                    icon: Icons.brush,
                                    isSelected: false,
                                    onPressed: () =>
                                        _showSnackBar('Section button 2'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '2 Items',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ToolbarSection(
                                width: 50,
                                children: [
                                  ToolbarButton(
                                    icon: Icons.create,
                                    isSelected: false,
                                    onPressed: () =>
                                        _showSnackBar('Section button A'),
                                  ),
                                  ToolbarButton(
                                    icon: Icons.highlight,
                                    isSelected: true,
                                    onPressed: () =>
                                        _showSnackBar('Section button B'),
                                  ),
                                  ToolbarButton(
                                    icon: Icons.text_fields,
                                    isSelected: false,
                                    onPressed: () =>
                                        _showSnackBar('Section button C'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '3 Items',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Button Variations Demo
                _buildAtomCard(
                  title: 'Button Variations',
                  description: 'Different sizes and styles',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ToolbarButton(
                                size: 24,
                                icon: Icons.star,
                                isSelected: false,
                                onPressed: () => _showSnackBar('Small button'),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '24px',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ToolbarButton(
                                size: 32,
                                icon: Icons.star,
                                isSelected: false,
                                onPressed: () => _showSnackBar('Medium button'),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '32px',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ToolbarButton(
                                size: 40,
                                icon: Icons.star,
                                isSelected: false,
                                onPressed: () => _showSnackBar('Large button'),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '40px',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Custom Content Demo
                _buildAtomCard(
                  title: 'Custom Content',
                  description: 'Buttons with text or custom widgets',
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ToolbarButton(
                                isSelected: false,
                                onPressed: () => _showSnackBar('Text button A'),
                                child: const Text(
                                  'A',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Text',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ToolbarButton(
                                isSelected: false,
                                onPressed: () => _showSnackBar('Custom widget'),
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Custom',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ================== Interactive State Display ==================
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
                          'Interactive State',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStateRow(
                      'Toggle Button:',
                      isButtonSelected ? 'Selected' : 'Not Selected',
                    ),
                    _buildStateRow(
                      'Selected Color:',
                      _getColorName(selectedAtomColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtomCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: 320,
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
