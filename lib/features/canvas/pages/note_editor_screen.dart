import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  @override
  Widget build(BuildContext context) {
    // 임시 해결책: build 메서드에서 세션 Observer 활성화
    ref.watch(noteSessionObserverProvider);
    
    // 추가적인 안전장치: 현재 화면에서 직접 세션 확인 및 시작
    final currentSession = ref.watch(noteSessionProvider);
    if (currentSession != widget.noteId) {
      // Widget tree building 중 provider 수정 방지를 위해 Future로 지연
      Future(() {
        ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
      });
    }
    
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final note = noteAsync.value;
    final noteTitle = note?.title ?? widget.noteId;
    final notePagesCount = ref.watch(notePagesCountProvider(widget.noteId));
    final currentIndex = ref.watch(currentPageIndexProvider(widget.noteId));

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
