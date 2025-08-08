import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../notes/models/note_model.dart';
import '../constants/note_editor_constant.dart';
import '../models/tool_mode.dart';
import '../notifiers/custom_scribble_notifier.dart';

part 'note_editor_provider.g.dart';

// 코드젠 기반 Provider들

@riverpod
class CurrentPageIndex extends _$CurrentPageIndex {
  @override
  int build() => 0;

  void setPage(int newIndex) => state = newIndex;
}

@riverpod
class SimulatePressure extends _$SimulatePressure {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setValue(bool value) => state = value;
}

@riverpod
class CustomScribbleNotifiers extends _$CustomScribbleNotifiers {
  Map<int, CustomScribbleNotifier>? _cache;
  bool? _lastSimulatePressure;

  @override
  Map<int, CustomScribbleNotifier> build(NoteModel note) {
    final simulatePressure = ref.watch(simulatePressureProvider);

    // 동일한 simulatePressure라면 캐시 재사용
    if (_cache != null && _lastSimulatePressure == simulatePressure) {
      return _cache!;
    }

    // 값이 바뀌었거나 캐시가 없다면 기존 인스턴스 정리
    if (_cache != null) {
      for (final notifier in _cache!.values) {
        notifier.dispose();
      }
      _cache = null;
    }

    final created = <int, CustomScribbleNotifier>{};
    for (var i = 0; i < note.pages.length; i++) {
      final notifier = CustomScribbleNotifier(
        ref: ref,
        toolMode: ToolMode.pen,
        page: note.pages[i],
        maxHistoryLength: NoteEditorConstants.maxHistoryLength,
      )
        ..setPen()
        ..setSketch(
          sketch: note.pages[i].toSketch(),
          addToUndoHistory: false,
        );
      created[i] = notifier;
    }

    _cache = created;
    _lastSimulatePressure = simulatePressure;
    ref.onDispose(() {
      if (_cache != null) {
        for (final notifier in _cache!.values) {
          notifier.dispose();
        }
        _cache = null;
      }
    });

    return created;
  }
}

@riverpod
CustomScribbleNotifier currentNotifier(
  Ref ref,
  NoteModel note,
) {
  final currentIndex = ref.watch(currentPageIndexProvider);
  final notifiers = ref.watch(customScribbleNotifiersProvider(note));
  return notifiers[currentIndex]!;
}

/// PageController Provider - 노트별로 독립적으로 관리
@Riverpod(keepAlive: true)
PageController pageController(
  Ref ref,
  NoteModel note,
) {
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
}
