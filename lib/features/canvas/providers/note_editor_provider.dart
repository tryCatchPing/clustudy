import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../notes/data/fake_notes.dart';
import '../constants/note_editor_constant.dart';
import '../models/tool_mode.dart';
import '../notifiers/custom_scribble_notifier.dart';

part 'note_editor_provider.g.dart';

// fvm dart run build_runner watch 명령어로 코드 변경 시 자동으로 빌드됨

/// 현재 페이지 인덱스 관리
/// noteId(String)로 노트별 독립 관리 (family provider)
@riverpod
class CurrentPageIndex extends _$CurrentPageIndex {
  @override
  int build(String noteId) => 0; // 노트별로 독립적인 현재 페이지 인덱스

  void setPage(int newIndex) => state = newIndex;
}

/// 필압 시뮬레이션 상태 관리
/// 파라미터 없으므로 싱글톤, 전역 상태 관리 (모든 노트 적용)
@riverpod
class SimulatePressure extends _$SimulatePressure {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setValue(bool value) => state = value;
}

/// 노트별 CustomScribbleNotifier 관리
/// noteId(String)로 노트별로 독립적으로 관리 (family provider)
/// SimulatePressure 상태가 변경되면 캐시 정리 후 새로 생성
@riverpod
class CustomScribbleNotifiers extends _$CustomScribbleNotifiers {
  Map<int, CustomScribbleNotifier>? _cache;
  bool? _lastSimulatePressure;

  @override
  Map<int, CustomScribbleNotifier> build(String noteId) {
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

    // noteId 로 NoteModel 조회 (임시: fakeNotes 사용)
    // TODO(xodnd): 추후 repository/provider 로 변경
    final note = fakeNotes.firstWhere(
      (n) => n.noteId == noteId,
      orElse: () => fakeNotes.first,
    );

    final created = <int, CustomScribbleNotifier>{};
    for (var i = 0; i < note.pages.length; i++) {
      final notifier =
          CustomScribbleNotifier(
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

/// 현재 페이지 인덱스에 해당하는 CustomScribbleNotifier 반환
/// 단순한 함수로 구현 (노트별로 독립적인 관리 필요 없음)
@riverpod
CustomScribbleNotifier currentNotifier(
  Ref ref,
  String noteId,
) {
  final currentIndex = ref.watch(currentPageIndexProvider(noteId));
  final notifiers = ref.watch(customScribbleNotifiersProvider(noteId));
  return notifiers[currentIndex]!;
}

/// PageController
/// 노트별로 독립적으로 관리 (family provider)
/// 화면 이탈 시 해제되어 재입장 시 0페이지부터 시작
@riverpod
PageController pageController(
  Ref ref,
  String noteId,
) {
  final controller = PageController(initialPage: 0);

  // Provider가 dispose될 때 controller도 정리
  ref.onDispose(() {
    controller.dispose();
  });

  // currentPageIndex가 변경되면 PageController도 동기화 (노트별)
  ref.listen<int>(currentPageIndexProvider(noteId), (previous, next) {
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
