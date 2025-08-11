import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/note_editor_provider.dart';
import 'style_selector.dart';
import 'tool_selector.dart';

/// 그리기 도구 모음을 표시하는 툴바 위젯입니다.
///
/// 펜, 하이라이터, 지우개, 링커 도구 선택 및 색상, 굵기 조절 기능을 제공합니다.
class NoteEditorDrawingToolbar extends ConsumerWidget {
  /// [NoteEditorDrawingToolbar]의 생성자.
  ///
  const NoteEditorDrawingToolbar({
    required this.noteId,
    super.key,
  });

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(currentNotifierProvider(noteId));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: NoteEditorToolSelector(notifier: notifier),
        ), // 🎯 Flexible 추가
        const VerticalDivider(width: 12),
        const VerticalDivider(width: 12),
        Flexible(child: NoteEditorStyleSelector(notifier: notifier)),
      ],
    );
  }
}
