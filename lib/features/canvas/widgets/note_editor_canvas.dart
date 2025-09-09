import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/sketch_persist_service.dart';
import '../constants/note_editor_constant.dart';
import '../providers/note_editor_provider.dart';
import 'note_page_view_item.dart';
import 'toolbar/toolbar.dart';

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
  const NoteEditorCanvas({
    super.key,
    required this.noteId,
    required this.routeId,
  });

  /// 현재 편집중인 노트 모델
  final String noteId;

  /// 라우트 인스턴스 식별자
  final String routeId;

  // 캔버스 크기 상수
  static const double _canvasWidth = NoteEditorConstants.canvasWidth;
  static const double _canvasHeight = NoteEditorConstants.canvasHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider에서 상태 읽기
    final pageController = ref.watch(pageControllerProvider(noteId, routeId));
    final notePagesCount = ref.watch(notePagesCountProvider(noteId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 캔버스 영역 - 남은 공간을 자동으로 모두 채움
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: notePagesCount,
              onPageChanged: (index) {
                // Page change contract:
                // 1) Ignore spurious callbacks during programmatic jumps
                //    (we set a temporary jump target when calling jumpToPage).
                // 2) Persist the sketch of the page we are leaving.
                // 3) Update the live page index provider so the controller and
                //    toolbar stay in sync.
                // Ignore spurious callbacks during programmatic jumps
                final jumpTarget = ref.read(pageJumpTargetProvider(noteId));
                if (jumpTarget != null && index != jumpTarget) {
                  debugPrint(
                    '🧭 [PageCtrl] onPageChanged ignored (index=$index, target=$jumpTarget)',
                  );
                  return;
                }
                if (jumpTarget != null && index == jumpTarget) {
                  ref.read(pageJumpTargetProvider(noteId).notifier).clear();
                }

                // Save sketch of the previous page (before switching)
                final prevIndex = ref.read(currentPageIndexProvider(noteId));
                if (prevIndex != index && prevIndex >= 0) {
                  debugPrint(
                    '💾 [SketchPersist] onPageChanged: prev=$prevIndex → next=$index (saving prev page)',
                  );
                  scheduleMicrotask(() async {
                    await SketchPersistService.savePageByIndex(
                      ref,
                      noteId,
                      prevIndex,
                    );
                  });
                }

                ref
                    .read(
                      currentPageIndexProvider(noteId).notifier,
                    )
                    .setPage(index);
              },
              itemBuilder: (context, index) {
                return NotePageViewItem(
                  noteId: noteId,
                  pageIndex: index,
                );
              },
            ),
          ),

          // 툴바 (하단) - 페이지 네비게이션 포함
          NoteEditorToolbar(
            noteId: noteId,
            canvasWidth: _canvasWidth,
            canvasHeight: _canvasHeight,
          ),
        ],
      ),
    );
  }
}
