import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../notes/data/derived_note_providers.dart';
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
@Riverpod(keepAlive: true)
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
    final noteAsync = ref.watch(noteProvider(noteId));

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          // 노트를 찾지 못한 경우: 기존 캐시가 있으면 유지, 없으면 빈 맵
          return _cache ?? <int, CustomScribbleNotifier>{};
        }

        // 캐시 재사용 조건: simulatePressure 동일 + 페이지 수 동일
        if (_cache != null &&
            _lastSimulatePressure == simulatePressure &&
            _cache!.length == note.pages.length) {
          return _cache!;
        }

        // 기존 캐시 정리
        if (_cache != null) {
          for (final notifier in _cache!.values) {
            notifier.dispose();
          }
          _cache = null;
        }

        // 새로 생성
        final created = <int, CustomScribbleNotifier>{};
        for (var i = 0; i < note.pages.length; i++) {
          final notifier =
              CustomScribbleNotifier(
                  toolMode: ToolMode.pen,
                  page: note.pages[i],
                  simulatePressure: simulatePressure,
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
      },
      loading: () => _cache ?? <int, CustomScribbleNotifier>{},
      error: (_, __) => _cache ?? <int, CustomScribbleNotifier>{},
    );
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

@riverpod
CustomScribbleNotifier pageNotifier(
  Ref ref,
  String noteId,
  int pageIndex,
) {
  final notifiers = ref.watch(customScribbleNotifiersProvider(noteId));
  return notifiers[pageIndex]!;
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

/// 노트 페이지 수를 반환하는 파생 provider
@riverpod
int notePagesCount(
  Ref ref,
  String noteId,
) {
  final noteAsync = ref.watch(noteProvider(noteId));
  return noteAsync.when(
    data: (note) => note?.pages.length ?? 0,
    error: (_, __) => 0,
    loading: () => 0,
  );
}
