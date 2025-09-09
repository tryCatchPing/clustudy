import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/routing/route_observer.dart';
import '../../../shared/services/sketch_persist_service.dart';
import '../../notes/data/derived_note_providers.dart';
import '../providers/note_editor_provider.dart';
import '../widgets/note_editor_canvas.dart';
import '../widgets/panels/backlinks_panel.dart';
import '../widgets/toolbar/actions_bar.dart';

/// 노트 편집 화면을 구성하는 위젯입니다.
///
/// 위젯 계층 구조:
/// MyApp
/// ㄴ HomeScreen
///   ㄴ NavigationCard → 라우트 이동 (/notes) → NoteListScreen
///     ㄴ NavigationCard → 라우트 이동 (/notes/:noteId/edit) → (현 위젯)
class NoteEditorScreen extends ConsumerStatefulWidget {
  /// [NoteEditorScreen]의 생성자.
  ///
  /// [note]는 편집할 노트 모델입니다.
  const NoteEditorScreen({
    super.key,
    required this.noteId,
  });

  /// 편집할 노트 ID.
  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with RouteAware {
  /// Restores the last visited page for this note after a route transition.
  ///
  /// Context:
  /// - Editor routes use `maintainState=false`, so returning creates a new
  ///   screen instance which would otherwise start at page 0.
  /// - We therefore read `resumePageIndexProvider(noteId)` on the first
  ///   visible frame, clamp to bounds, write into
  ///   `currentPageIndexProvider(noteId)`, and then clear the resume value.
  void _scheduleRestoreResumeIndexIfAny() {
    // Attempt to restore the stored resume page index safely after the route becomes current
    // and note data is available. Clears the stored value after applying.
    void attempt() {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.isCurrent != true) return;

      final resume = ref.read(resumePageIndexProvider(widget.noteId));
      if (resume == null) return; // nothing to restore

      final note = ref.read(noteProvider(widget.noteId)).value;
      if (note == null) {
        // Note not loaded yet, try next frame
        WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
        return;
      }
      if (note.pages.isEmpty) {
        // No pages to restore, clear stored value and stop
        ref.read(resumePageIndexProvider(widget.noteId).notifier).state = null;
        return;
      }

      var idx = resume;
      if (idx < 0) idx = 0;
      if (idx >= note.pages.length) idx = note.pages.length - 1;

      ref.read(currentPageIndexProvider(widget.noteId).notifier).setPage(idx);

      // Clear after applying to avoid repeated jumps
      ref.read(resumePageIndexProvider(widget.noteId).notifier).state = null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
      debugPrint('🧭 [RouteAware] subscribe noteId=${widget.noteId}');
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    debugPrint('🧭 [RouteAware] unsubscribe noteId=${widget.noteId}');
    super.dispose();
  }

  @override
  void didPush() {
    debugPrint(
      '🧭 [RouteAware] didPush noteId=${widget.noteId} → schedule enter session',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
      // After session enter, restore page if a resume index is stored.
      // We schedule it for the next frame to avoid provider writes during the
      // same build cycle as the route transition.
      WidgetsBinding.instance.addPostFrameCallback((__) {
        _scheduleRestoreResumeIndexIfAny();
      });
    });
  }

  @override
  void didPopNext() {
    final route = ModalRoute.of(context);
    final isCurrent = route?.isCurrent ?? false;
    debugPrint(
      '🧭 [RouteAware] didPopNext noteId=${widget.noteId} (isCurrent=$isCurrent)',
    );
    if (!isCurrent) {
      debugPrint(
        '🧭 [RouteAware] didPopNext skipped re-enter (route not current)',
      );
      return;
    }
    // Ensure re-enter runs one frame AFTER didPop's exit to avoid final null.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route2 = ModalRoute.of(context);
      if (route2?.isCurrent != true) {
        debugPrint('🧭 [RouteAware] re-enter skipped (route lost current)');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((__) {
        if (!mounted) return;
        final route3 = ModalRoute.of(context);
        if (route3?.isCurrent != true) {
          debugPrint(
            '🧭 [RouteAware] re-enter skipped (route lost current, 2nd frame)',
          );
          return;
        }
        debugPrint('🧭 [RouteAware] re-enter session noteId=${widget.noteId}');
        ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
      });
    });
  }

  @override
  void didPushNext() {
    debugPrint(
      '🧭 [RouteAware] didPushNext noteId=${widget.noteId} (save & no-op)',
    );
    // Save current page sketch when another route is pushed above
    // Fire-and-forget; errors are logged inside the service
    SketchPersistService.saveCurrentPage(ref, widget.noteId);
  }

  @override
  void didPop() {
    debugPrint(
      '🧭 [RouteAware] didPop noteId=${widget.noteId} → schedule exit session',
    );
    // Save current page when leaving editor via back
    SketchPersistService.saveCurrentPage(ref, widget.noteId);
    // Store resume page index for potential future returns to this note
    // Delay to avoid modifying providers during route pop build phase
    // 라우트 업데이트 중 provider 수정 방지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = ref.read(currentPageIndexProvider(widget.noteId));
      ref.read(resumePageIndexProvider(widget.noteId).notifier).state = idx;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteSessionProvider.notifier).exitNote();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 [NoteEditorScreen] Building for noteId: ${widget.noteId}');

    // Guard: When using maintainState=false, this screen is recreated when
    // returning from the next route, so didPopNext won't fire on the old
    // (disposed) instance. Ensure session re-entry on first visible frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      final isCurrent = route?.isCurrent ?? false;
      final active = ref.read(noteSessionProvider);
      if (isCurrent && active != widget.noteId) {
        debugPrint(
          '🧭 [RouteAware] build-guard enter session noteId=${widget.noteId}',
        );
        ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
        // After entering session, attempt to restore resume index
        WidgetsBinding.instance.addPostFrameCallback((__) {
          _scheduleRestoreResumeIndexIfAny();
        });
      }
    });

    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final note = noteAsync.value;
    final noteTitle = note?.title ?? widget.noteId;
    final notePagesCount = ref.watch(notePagesCountProvider(widget.noteId));
    final currentIndex = ref.watch(currentPageIndexProvider(widget.noteId));

    debugPrint('📝 [NoteEditorScreen] Note async value: $note');
    debugPrint('📝 [NoteEditorScreen] Note pages count: $notePagesCount');
    debugPrint('📝 [NoteEditorScreen] Current page index: $currentIndex');

    // 노트가 사라진 경우(삭제 직후 등) 즉시 빈 화면 처리하여 BadState 방지
    if (note == null || notePagesCount == 0) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '$noteTitle - Page ${currentIndex + 1}/$notePagesCount',
        ),
        actions: [NoteEditorActionsBar(noteId: widget.noteId)],
      ),
      endDrawer: BacklinksPanel(noteId: widget.noteId),
      body: NoteEditorCanvas(noteId: widget.noteId),
    );
  }
}
