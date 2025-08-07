import 'package:flutter/material.dart';

import '../../notifiers/custom_scribble_notifier.dart';
import '../../notifiers/scribble_notifier_x.dart';

/// 노트 편집기에서 실행할 수 있는 액션 버튼들을 모아놓은 위젯입니다.
class NoteEditorActionsBar extends StatelessWidget {
  /// [NoteEditorActionsBar]의 생성자.
  ///
  /// [notifier]는 스케치 상태를 관리하는 Notifier입니다.
  const NoteEditorActionsBar({super.key, required this.notifier});

  /// 스케치 상태를 관리하는 Notifier.
  final CustomScribbleNotifier notifier;

  @override
  Widget build(BuildContext context) {
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
