import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_contest/features/canvas/notifiers/custom_scribble_notifier.dart';
import 'package:it_contest/features/canvas/providers/note_editor_providers.dart';

/// 노트 편집기에서 실행할 수 있는 액션 버튼들을 모아놓은 위젯입니다.
class NoteEditorActionsBar extends ConsumerWidget {
  /// [NoteEditorActionsBar]의 생성자.
  ///
  /// [notifier]는 스케치 상태를 관리하는 Notifier입니다.
  const NoteEditorActionsBar({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch<int>(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    final notifier = ref.watch<CustomScribbleNotifier>(currentNotifierProvider(noteId));

    return Row(
      children: [
        ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, value, child) => IconButton(
            icon: child as Icon,
            tooltip: 'Undo',
            onPressed: notifier.canUndo ? notifier.undo : null,
          ),
          child: const Icon(Icons.undo),
        ),
        ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, value, child) => IconButton(
            icon: child as Icon,
            tooltip: 'Redo',
            onPressed: notifier.canRedo ? notifier.redo : null,
          ),
          child: const Icon(Icons.redo),
        ),
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear',
          onPressed: notifier.clear,
        ),
        IconButton(
          icon: const Icon(Icons.image),
          tooltip: 'Show PNG Image',
          onPressed: () => notifier.showImage(context),
        ),
        IconButton(
          icon: const Icon(Icons.data_object),
          tooltip: 'Show JSON',
          onPressed: () => notifier.showJson(context),
        ),
        IconButton(
          icon: const Icon(Icons.save),
          tooltip: 'Save',
          onPressed: () => notifier.saveSketch(),
        ),
      ],
    );
  }
}
