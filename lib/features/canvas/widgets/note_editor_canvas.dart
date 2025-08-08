import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/models/note_model.dart';
import '../constants/note_editor_constant.dart';
import '../providers/note_editor_provider.dart';
import 'note_page_view_item.dart';
import 'toolbar/note_editor_toolbar.dart';

/// 📱 캔버스 영역을 담당하는 위젯
///
/// 다음을 포함합니다:
/// - 다중 페이지 뷰 (PageView)
/// - 그리기 도구 모음 (Toolbar)
///
/// 위젯 계층 구조:
/// MyApp
/// ㄴ HomeScreen
///   ㄴ NavigationCard → 라우트 이동 (/notes) → NoteListScreen
///     ㄴ NavigationCard → 라우트 이동 (/notes/:noteId/edit) → NoteEditorScreen
///       ㄴ (현 위젯)
class NoteEditorCanvas extends ConsumerWidget {
  /// [NoteEditorCanvas]의 생성자.
  ///
  /// [note]는 현재 편집중인 노트 모델입니다.
  /// [transformationController]는 캔버스의 변환을 제어하는 컨트롤러입니다.
  /// [onPressureToggleChanged]는 필압 토글 변경 시 호출되는 콜백 함수입니다.
  const NoteEditorCanvas({
    super.key,
    required this.note,
    required this.transformationController,
  });

  /// 현재 편집중인 노트 모델
  final NoteModel note;

  /// 캔버스의 변환을 제어하는 컨트롤러.
  final TransformationController transformationController;

  // 캔버스 크기 상수
  static const double _canvasWidth = NoteEditorConstants.canvasWidth;
  static const double _canvasHeight = NoteEditorConstants.canvasHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider에서 상태 읽기
    final simulatePressure = ref.watch(simulatePressureProvider);
    final pageController = ref.watch(pageControllerProvider(note.noteId));
    final scribbleNotifiers = ref.watch(
      customScribbleNotifiersProvider(note.noteId),
    );
    final currentNotifier = ref.watch(currentNotifierProvider(note.noteId));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 캔버스 영역 - 남은 공간을 자동으로 모두 채움
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: note.pages.length,
              onPageChanged: (index) {
                ref
                    .read(
                      currentPageIndexProvider(note.noteId).notifier,
                    )
                    .setPage(index);
              },
              itemBuilder: (context, index) {
                return NotePageViewItem(
                  notifier: scribbleNotifiers[index]!,
                  transformationController: transformationController,
                  simulatePressure: simulatePressure,
                );
              },
            ),
          ),

          // 툴바 (하단) - 페이지 네비게이션 포함
          NoteEditorToolbar(
            note: note,
            notifier: currentNotifier,
            canvasWidth: _canvasWidth,
            canvasHeight: _canvasHeight,
            transformationController: transformationController,
            simulatePressure: simulatePressure,
          ),
        ],
      ),
    );
  }
}
