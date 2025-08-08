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

  // 다중 페이지 관리
  late int totalPages;
  // ✅ _scribbleNotifiers는 이제 Provider에서 관리함 (customScribbleNotifiersProvider)
  // ✅ _pageController는 이제 Provider에서 관리함 (pageControllerProvider)

  @override
  void initState() {
    super.initState();
    transformationController = TransformationController();

    // 다중 페이지 초기화
    totalPages = widget.note.pages.length;
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

  /// 페이지 변경 콜백
  ///
  /// [index]는 변경된 페이지의 인덱스입니다.
  void _onPageChanged(int index) {
    ref.read(currentPageIndexProvider(widget.note).notifier).setPage(index);
  }

  /// 필압 시뮬레이션 토글 콜백
  ///
  /// [value] 필압 시뮬레이션 활성화 여부
  void _onPressureToggleChanged(bool value) {
    ref.read(simulatePressureProvider.notifier).setValue(value);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(currentPageIndexProvider(widget.note));
    final currentNotifier = ref.watch(currentNotifierProvider(widget.note));
    final scribbleNotifiers = ref.watch(
      customScribbleNotifiersProvider(widget.note),
    );
    final pageController = ref.watch(pageControllerProvider(widget.note));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${widget.note.title} - Page ${currentIndex + 1}/$totalPages',
        ),
        actions: [
          NoteEditorActionsBar(notifier: currentNotifier),
        ],
      ),
      body: NoteEditorCanvas(
        note: widget.note,
        totalPages: totalPages,
        pageController: pageController,
        scribbleNotifiers: scribbleNotifiers,
        currentNotifier: currentNotifier,
        transformationController: transformationController,
        onPageChanged: _onPageChanged,
        onPressureToggleChanged: _onPressureToggleChanged,
      ),
    );
  }
}
