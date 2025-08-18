import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/data/derived_note_providers.dart';
import '../../../notes/pages/page_controller_screen.dart';
import '../../../notes/widgets/pdf_export_modal.dart';
import '../../notifiers/scribble_notifier_x.dart';
import '../../providers/note_editor_provider.dart';

/// 노트 편집기에서 실행할 수 있는 액션 버튼들을 모아놓은 위젯입니다.
class NoteEditorActionsBar extends ConsumerWidget {
  /// [NoteEditorActionsBar]의 생성자.
  ///
  /// [notifier]는 스케치 상태를 관리하는 Notifier입니다.
  const NoteEditorActionsBar({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    final notifier = ref.watch(currentNotifierProvider(noteId));
    final note = ref.watch(noteProvider(noteId)).value;
    final currentPageIndex = ref.watch(currentPageIndexProvider(noteId));

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
        IconButton(
          icon: const Icon(Icons.view_agenda),
          tooltip: '페이지 설정',
          onPressed: () => PageControllerScreen.show(context, noteId),
        ),
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: 'PDF 내보내기',
          onPressed: note == null ? null : () => _onPdfExport(context, ref),
        ),
      ],
    );
  }

  /// PDF 내보내기 모달을 표시합니다.
  void _onPdfExport(BuildContext context, WidgetRef ref) async {
    final note = ref.read(noteProvider(noteId)).value;
    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('노트를 불러올 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 모든 페이지의 ScribbleNotifier 수집
    final allNotifiers = ref.read(customScribbleNotifiersProvider(noteId));
    final currentPageIndex = ref.read(currentPageIndexProvider(noteId));

    // PDF 내보내기 모달 표시
    await PdfExportModal.show(
      context,
      note: note,
      pageNotifiers: allNotifiers,
      currentPageIndex: currentPageIndex,
    );
  }
}
