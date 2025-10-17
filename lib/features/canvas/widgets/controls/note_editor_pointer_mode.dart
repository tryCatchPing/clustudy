import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import '../../providers/note_editor_provider.dart';
import '../../providers/pointer_policy_provider.dart';

// TOOD(xodnd): provider 제공 -> NotePageViewItem에서 Linker와 연결 필요

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
    debugPrint('🎨 [NoteEditorPointerMode] Building for noteId: $noteId');

    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    final policy = ref.watch(pointerPolicyProvider);

    return SegmentedButton<ScribblePointerMode>(
      multiSelectionEnabled: false,
      emptySelectionAllowed: false,
      onSelectionChanged: (v) =>
          ref.read(pointerPolicyProvider.notifier).setPolicy(v.first),
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.all(4)),
      ),
      segments: const [
        ButtonSegment(
          value: ScribblePointerMode.all,
          icon: Icon(Icons.touch_app, size: 18),
        ),
        ButtonSegment(
          value: ScribblePointerMode.penOnly,
          icon: Icon(Icons.draw, size: 18),
        ),
      ],
      selected: {policy},
    );
  }
}
