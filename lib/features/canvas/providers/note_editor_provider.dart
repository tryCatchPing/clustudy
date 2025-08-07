import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/models/note_model.dart';
import '../constants/note_editor_constant.dart';
import '../models/tool_mode.dart';
import '../notifiers/custom_scribble_notifier.dart';

// 수동 Provider 방식 (code generation 없이)

/// 현재 페이지 인덱스 상태 관리
class CurrentPageIndexNotifier extends StateNotifier<int> {
  CurrentPageIndexNotifier() : super(0);

  void setPage(int newIndex) {
    state = newIndex;
  }
}

/// 필압 시뮬레이션 상태 관리
class SimulatePressureNotifier extends StateNotifier<bool> {
  SimulatePressureNotifier() : super(false);

  void toggle() {
    state = !state;
  }

  void setValue(bool value) {
    state = value;
  }
}

class CustomScribbleNotifiersNotifier
    extends StateNotifier<Map<int, CustomScribbleNotifier>> {
  CustomScribbleNotifiersNotifier(this.ref, NoteModel note) : super({}) {
    _initializeNotifiers(note);
  }

  final Ref ref;

  void _initializeNotifiers(NoteModel note) {
    final notifiers = <int, CustomScribbleNotifier>{};
    for (var i = 0; i < note.pages.length; i++) {
      final notifier = CustomScribbleNotifier(
        ref: ref,
        toolMode: ToolMode.pen,
        page: note.pages[i],
        maxHistoryLength: NoteEditorConstants.maxHistoryLength,
      );
      notifier.setPen();
      notifier.setSketch(
        sketch: note.pages[i].toSketch(),
        addToUndoHistory: false,
      );
      notifiers[i] = notifier;
    }
    state = notifiers;
  }
}

// Provider 인스턴스들
final currentPageIndexProvider =
    StateNotifierProvider<CurrentPageIndexNotifier, int>(
      (ref) => CurrentPageIndexNotifier(),
    );

final simulatePressureProvider =
    StateNotifierProvider<SimulatePressureNotifier, bool>(
      (ref) => SimulatePressureNotifier(),
    );

final customScribbleNotifiersProvider =
    StateNotifierProvider.family<
      CustomScribbleNotifiersNotifier,
      Map<int, CustomScribbleNotifier>,
      NoteModel
    >(
      (ref, note) => CustomScribbleNotifiersNotifier(ref, note),
    );

final currentNotifierProvider =
    Provider.family<CustomScribbleNotifier, NoteModel>((ref, note) {
      final currentIndex = ref.watch(currentPageIndexProvider);
      final notifiers = ref.watch(customScribbleNotifiersProvider(note));
      return notifiers[currentIndex]!;
    });

/// PageController Provider - 노트별로 독립적으로 관리
final pageControllerProvider = Provider.family<PageController, NoteModel>((ref, note) {
  final controller = PageController(initialPage: 0);
  
  // Provider가 dispose될 때 controller도 정리
  ref.onDispose(() {
    controller.dispose();
  });
  
  // currentPageIndex가 변경되면 PageController도 동기화
  ref.listen<int>(currentPageIndexProvider, (previous, next) {
    if (controller.hasClients && previous != next) {
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  });
  
  return controller;
});
