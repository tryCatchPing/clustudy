import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_contest/canvas/canvas_pipeline.dart';

import 'package:it_contest/features/canvas/constants/note_editor_constant.dart';
import 'package:it_contest/features/canvas/providers/note_editor_provider.dart';
import 'package:it_contest/features/canvas/widgets/note_page_view_item.dart';
import 'package:it_contest/features/canvas/widgets/toolbar/toolbar.dart';
import 'package:it_contest/features/notes/data/derived_note_providers.dart';
import 'package:it_contest/snapshot/snapshot_service.dart';

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
class NoteEditorCanvas extends ConsumerStatefulWidget {
  /// [NoteEditorCanvas]의 생성자.
  ///
  const NoteEditorCanvas({
    super.key,
    required this.noteId,
  });

  /// 현재 편집중인 노트 모델
  final String noteId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NoteEditorCanvasState();
}

class _NoteEditorCanvasState extends ConsumerState<NoteEditorCanvas> {
  // 캔버스 크기 상수
  static const double _canvasWidth = NoteEditorConstants.canvasWidth;
  static const double _canvasHeight = NoteEditorConstants.canvasHeight;

  @override
  void dispose() {
    // 위젯이 dispose될 때 모든 보류중인 스냅샷을 저장합니다.
    SnapshotService.flushAllPending();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider에서 상태 읽기
    final pageController = ref.watch(pageControllerProvider(widget.noteId));
    final notePagesCount = ref.watch(notePagesCountProvider(widget.noteId));
    final note = ref.watch(noteProvider(widget.noteId)).value;
    final notePages = note?.pages ?? [];

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
                // 페이지를 넘길 때 현재 페이지의 스냅샷을 즉시 저장합니다.
                final previousPageIndex = ref.read(currentPageIndexProvider(widget.noteId));
                final pageId = notePages[previousPageIndex].pageId;
                CanvasPipeline.flushSnapshotForPage(int.parse(pageId));

                ref.read(currentPageIndexProvider(widget.noteId).notifier).setPage(index);
              },
              itemBuilder: (context, index) {
                return NotePageViewItem(
                  noteId: widget.noteId,
                  pageIndex: index,
                );
              },
            ),
          ),

          // 툴바 (하단) - 페이지 네비게이션 포함
          NoteEditorToolbar(
            noteId: widget.noteId,
            canvasWidth: _canvasWidth,
            canvasHeight: _canvasHeight,
          ),
        ],
      ),
    );
  }
}