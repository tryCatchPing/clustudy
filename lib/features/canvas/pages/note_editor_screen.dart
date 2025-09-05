import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/routing/route_observer.dart';
import '../../notes/data/derived_note_providers.dart';
import '../providers/note_editor_provider.dart';
import '../widgets/note_editor_canvas.dart';
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
    debugPrint('🧭 [RouteAware] didPushNext noteId=${widget.noteId} (no-op)');
  }

  @override
  void didPop() {
    debugPrint(
      '🧭 [RouteAware] didPop noteId=${widget.noteId} → schedule exit session',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteSessionProvider.notifier).exitNote();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 [NoteEditorScreen] Building for noteId: ${widget.noteId}');

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
      body: NoteEditorCanvas(noteId: widget.noteId),
    );
  }
}
