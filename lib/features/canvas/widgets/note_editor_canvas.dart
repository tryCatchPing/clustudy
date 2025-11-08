import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/sketch_persist_service.dart';
import '../providers/note_editor_provider.dart';
import '../providers/pointer_snapshot_provider.dart';
import 'note_page_view_item.dart';
import 'snappy_page_scroll_physics.dart';

/// 📱 캔버스 영역을 담당하는 위젯
///
/// 다음을 포함합니다:
/// - 다중 페이지 뷰 (PageView)
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider에서 상태 읽기
    final pageController = ref.watch(pageControllerProvider(noteId, routeId));
    final notePagesCount = ref.watch(notePagesCountProvider(noteId));
    final lockScroll = ref.watch(pageScrollLockProvider(noteId));
    final scrollPhysics = lockScroll
        ? const NeverScrollableScrollPhysics()
        : const SnappyPageScrollPhysics(velocityFactor: 0.05);

    return PageView.builder(
      controller: pageController,
      physics: scrollPhysics,
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
    );
  }
}
