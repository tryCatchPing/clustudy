import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/models/note_model.dart';
import '../providers/note_editor_provider.dart';
import '../widgets/note_editor_canvas.dart';
import '../widgets/toolbar/note_editor_actions_bar.dart';

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
    required this.note,
  });

  /// 편집할 노트 모델.
  final NoteModel note;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  /// TransformationController: 확대/축소 상태를 관리하는 컨트롤러
  ///
  /// InteractiveViewer와 함께 사용하여 다음을 관리합니다:
  /// - 확대/축소 비율
  /// - 패닝(이동) 상태
  /// - 변환 매트릭스
  late TransformationController transformationController;

  // ✅ _scribbleNotifiers는 이제 Provider에서 관리함 (customScribbleNotifiersProvider)
  // ✅ _pageController는 이제 Provider에서 관리함 (pageControllerProvider)

  @override
  void initState() {
    super.initState();
    transformationController = TransformationController();

    // ✅ _pageController 초기화도 Provider에서 자동으로 됨
    // ✅ notifier 초기화는 Provider에서 자동으로 됨
  }

  // ✅ _initializeNotifiers 삭제됨 - Provider에서 자동으로 초기화

  @override
  void dispose() {
    // ✅ notifier dispose는 Provider에서 자동으로 관리됨
    // ✅ _pageController dispose도 Provider에서 자동으로 관리됨
    transformationController.dispose();
    super.dispose();
  }

  // 페이지 변경 콜백은 Canvas 내부에서 provider로 처리하도록 정리됨

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(
      currentPageIndexProvider(widget.note.noteId),
    );
    final currentNotifier = ref.watch(
      currentNotifierProvider(widget.note.noteId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${widget.note.title} - Page ${currentIndex + 1}/${widget.note.pages.length}',
        ),
        actions: [
          NoteEditorActionsBar(notifier: currentNotifier),
        ],
      ),
      body: NoteEditorCanvas(
        note: widget.note,
        transformationController: transformationController,
      ),
    );
  }
}
