import 'package:flutter/material.dart';
import '../../ai_generated/raw_components/canvas_toolbar.dart';
import '../../tokens/app_colors.dart';

/// 📋 Figma 노트 에디터 디자인 재현 페이지
/// 
/// 원본 Figma 디자인: https://www.figma.com/design/MtvaMAiatLnIYEilnFKB2F/design-duplicated?node-id=21-1697&m=dev
/// 이 페이지는 디자이너와 개발자가 실제 동작을 확인하고 피드백할 수 있는 living documentation 역할
class NoteEditorDemo extends StatefulWidget {
  const NoteEditorDemo({Key? key}) : super(key: key);

  @override
  State<NoteEditorDemo> createState() => _NoteEditorDemoState();
}

class _NoteEditorDemoState extends State<NoteEditorDemo> {
  // ================== State Management ==================
  Color selectedColor = AppColors.penRed;
  int selectedPenType = 3; // 기본값: 4번째 툴 선택됨
  int selectedThickness = 4; // 기본값: 5번째 굵기 선택됨
  String currentNoteName = '(Current Note)';
  bool canUndo = true;
  bool canRedo = false;

  // ================== Event Handlers ==================
  void _onColorChanged(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  void _onPenTypeChanged(int type) {
    setState(() {
      selectedPenType = type;
    });
  }

  void _onThicknessChanged(int thickness) {
    setState(() {
      selectedThickness = thickness;
    });
  }

  void _onUndo() {
    setState(() {
      canRedo = true;
      // 실제 앱에서는 실제 undo 로직 실행
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Undo performed'), duration: Duration(seconds: 1)),
    );
  }

  void _onRedo() {
    setState(() {
      canUndo = true;
      // 실제 앱에서는 실제 redo 로직 실행
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redo performed'), duration: Duration(seconds: 1)),
    );
  }

  void _onNewNote() {
    setState(() {
      currentNoteName = 'New Note ${DateTime.now().millisecond}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created: $currentNoteName'), duration: const Duration(seconds: 1)),
    );
  }

  void _onNoteSelect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note selection opened'), duration: Duration(seconds: 1)),
    );
  }

  void _onSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings opened'), duration: Duration(seconds: 1)),
    );
  }

  void _onPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Page options opened'), duration: Duration(seconds: 1)),
    );
  }

  void _onLinks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Links panel opened'), duration: Duration(seconds: 1)),
    );
  }

  void _onAddElement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add element panel opened'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.toolbarBackground,
      body: Column(
        children: [
          // ================== Top Toolbar ==================
          CanvasToolbar(
            selectedColor: selectedColor,
            onColorChanged: _onColorChanged,
            selectedPenType: selectedPenType,
            onPenTypeChanged: _onPenTypeChanged,
            selectedThickness: selectedThickness,
            onThicknessChanged: _onThicknessChanged,
            onUndo: _onUndo,
            onRedo: _onRedo,
            onNewNote: _onNewNote,
            onNoteSelect: _onNoteSelect,
            onSettings: _onSettings,
            onPage: _onPage,
            onLinks: _onLinks,
            onAddElement: _onAddElement,
            currentNoteName: currentNoteName,
            canUndo: canUndo,
            canRedo: canRedo,
          ),

          // ================== Main Content Area ==================
          Expanded(
            child: Container(
              color: AppColors.toolbarBackground,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left Note Page
                  Container(
                    width: 477.5,
                    height: 477.5,
                    decoration: BoxDecoration(
                      color: AppColors.noteBackground,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Left Note Canvas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Canvas functionality will be integrated here',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 100), // Gap between pages

                  // Right Note Page
                  Container(
                    width: 477.5,
                    height: 477.5,
                    decoration: BoxDecoration(
                      color: AppColors.noteBackground,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Right Note Canvas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Additional canvas or page preview',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}