import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import '../../providers/note_editor_provider.dart';

/// 포인터 모드 (모든 터치, 펜 전용)를 선택하는 위젯입니다.
class NoteEditorPointerMode extends ConsumerWidget {
  /// [NoteEditorPointerMode]의 생성자.
  ///
  const NoteEditorPointerMode({
    required this.noteId,
    super.key,
  });

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }
    final notifier = ref.watch(currentNotifierProvider(noteId));

    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, state, child) {
        return SegmentedButton<ScribblePointerMode>(
          multiSelectionEnabled: false,
          emptySelectionAllowed: false,
          onSelectionChanged: (v) => notifier.setAllowedPointersMode(v.first),
          style: ButtonStyle(
            padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
          ),
          segments: const [
            ButtonSegment(
              value: ScribblePointerMode.all,
              icon: Icon(Icons.touch_app, size: 18), // 아이콘 크기 축소 (24->18)
            ),
            ButtonSegment(
              value: ScribblePointerMode.penOnly,
              icon: Icon(Icons.draw, size: 18), // 아이콘 크기 축소 (24->18)
            ),
          ],
          selected: {state.allowedPointersMode},
        );
      },
    );
  }
}
