import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_contest/features/canvas/widgets/controls/note_editor_page_navigation.dart';
import 'package:it_contest/features/canvas/widgets/controls/note_editor_pointer_mode.dart';
import 'package:it_contest/features/canvas/widgets/controls/note_editor_pressure_toggle.dart';
import 'package:it_contest/features/canvas/widgets/controls/note_editor_viewport_info.dart';
import 'package:it_contest/features/canvas/widgets/toolbar/drawing_toolbar.dart';

/// 노트 편집기 하단에 표시되는 툴바 위젯입니다.
///
/// 그리기 도구, 페이지 네비게이션, 필압 토글, 캔버스 정보, 포인터 모드 등을 포함합니다.
class NoteEditorToolbar extends ConsumerWidget {
  /// [NoteEditorToolbar]의 생성자.
  ///
  /// [noteId]는 현재 편집중인 노트 ID입니다.
  /// [canvasWidth]는 캔버스의 너비입니다.
  /// [canvasHeight]는 캔버스의 높이입니다.
  /// ✅ 페이지 네비게이션 파라미터들은 제거됨 (Provider에서 직접 읽음)
  const NoteEditorToolbar({
    required this.noteId,
    required this.canvasWidth,
    required this.canvasHeight,
    super.key,
  });

  /// 현재 편집중인 노트 모델
  final String noteId;

  /// 캔버스의 너비.
  final double canvasWidth;

  /// 캔버스의 높이.
  final double canvasHeight;

  // ✅ 페이지 네비게이션 관련 파라미터들은 제거됨 - Provider에서 직접 읽음

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // 상단: 기존 그리기 도구들
          NoteEditorDrawingToolbar(noteId: noteId),

          // 하단: 페이지 네비게이션, 필압 토글, 캔버스 정보, 포인터 모드
          SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (totalPages > 1) NoteEditorPageNavigation(noteId: noteId),
                // 필압 토글 컨트롤
                // TODO(xodnd): simplify 0 으로 수정 필요
                const NoteEditorPressureToggle(),
                // 캔버스와 뷰포트 정보를 표시하는 위젯
                NoteEditorViewportInfo(
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                  noteId: noteId,
                ),
                NoteEditorPointerMode(noteId: noteId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
