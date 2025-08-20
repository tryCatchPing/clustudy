// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_contest/features/canvas/constants/note_editor_constant.dart';
import 'package:it_contest/features/canvas/models/tool_mode.dart';
import 'package:it_contest/features/canvas/notifiers/custom_scribble_notifier.dart';
import 'package:it_contest/features/canvas/providers/tool_settings_provider.dart';
import 'package:it_contest/features/notes/data/derived_note_providers.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scribble/scribble.dart';


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

/// 노트별 포인터 모드 상태 관리
/// noteId(String)로 노트별 독립 관리 (family provider)
@Riverpod(keepAlive: true)
class AllowedPointersMode extends _$AllowedPointersMode {
  @override
  ScribblePointerMode build(String noteId) => ScribblePointerMode.all;

  void setMode(ScribblePointerMode mode) => state = mode;
}

/// 노트별 CustomScribbleNotifier 관리
/// noteId(String)로 노트별로 독립적으로 관리 (family provider)
@riverpod
class CustomScribbleNotifiers extends _$CustomScribbleNotifiers {
  // 페이지 ID 기반 캐시로 페이지 추가/삭제/재정렬에도 개별 히스토리 유지
  Map<String, CustomScribbleNotifier>? _cacheByPageId;
  bool _simulatePressureListenerAttached = false;
  bool _toolSettingsListenerAttached = false;

  void _applyToolSettings(
    CustomScribbleNotifier notifier,
    ToolSettings settings,
  ) {
    notifier.setTool(settings.toolMode);
    switch (settings.toolMode) {
      case ToolMode.pen:
        notifier
          ..setColor(settings.penColor)
          ..setStrokeWidth(settings.penWidth);
        break;
      case ToolMode.highlighter:
        notifier
          ..setColor(settings.highlighterColor)
          ..setStrokeWidth(settings.highlighterWidth);
        break;
      case ToolMode.eraser:
        // 지우개는 색상 없음: setColor 호출 금지
        notifier.setStrokeWidth(settings.eraserWidth);
        break;
      case ToolMode.linker:
        // 링크 모드는 Scribble 상태 변경 없음
        break;
    }
  }

  @override
  Future<Map<String, CustomScribbleNotifier>> build(String noteId) async {
    final noteAsync = ref.watch(noteProvider(noteId));
    // 재생성 트리거가 되지 않도록 listen으로만 처리
    final simulatePressure = ref.read(simulatePressureProvider);
    final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));

    return noteAsync.maybeWhen(
      data: (note) async {
        if (note == null) {
          // 노트를 찾지 못한 경우: 기존 캐시가 있으면 유지, 없으면 빈 맵
          return _cacheByPageId ?? <String, CustomScribbleNotifier>{};
        }

        // 증분 동기화: 삭제/추가만 적용
        final map = _cacheByPageId ?? <String, CustomScribbleNotifier>{};
        final currentIds = map.keys.toSet();
        final nextIds = note.pages.map((p) => p.pageId).toSet();

        // 삭제된 페이지 정리
        for (final removedId in currentIds.difference(nextIds)) {
          map.remove(removedId)?.dispose();
        }

        // 새 페이지 추가 생성
        for (final page in note.pages) {
          if (!map.containsKey(page.pageId)) {
            // 노트별 포인터 모드 상태에서 설정 가져오기
            final allowedMode = ref.read(allowedPointersModeProvider(noteId));

            final notifier = await CustomScribbleNotifier.create(
              pageId: int.parse(page.pageId),
              page: page,
              toolMode: toolSettings.toolMode,
              simulatePressure: simulatePressure,
              allowedPointersMode: allowedMode,
            );
            _applyToolSettings(notifier, toolSettings);

            map[page.pageId] = notifier;
          }
        }

        _cacheByPageId = map;

        // simulatePressure 변경을 기존 CSN 인스턴스에 주입하여 히스토리를 보존합니다.
        if (!_simulatePressureListenerAttached) {
          _simulatePressureListenerAttached = true;
          ref.listen<bool>(simulatePressureProvider, (prev, next) {
            final m = _cacheByPageId;
            if (m == null) {
              return;
            }
            for (final notifier in m.values) {
              notifier.setSimulatePressureEnabled(next);
            }
          });
        }

        // tool settings 변경 주입 (재생성 금지)
        if (!_toolSettingsListenerAttached) {
          _toolSettingsListenerAttached = true;
          ref.listen<ToolSettings>(
            toolSettingsNotifierProvider(noteId),
            (prev, next) {
              final m = _cacheByPageId;
              if (m == null) {
                return;
              }
              for (final notifier in m.values) {
                notifier.setTool(next.toolMode);
                switch (next.toolMode) {
                  case ToolMode.pen:
                    notifier
                      ..setColor(next.penColor)
                      ..setStrokeWidth(next.penWidth);
                    break;
                  case ToolMode.highlighter:
                    notifier
                      ..setColor(next.highlighterColor)
                      ..setStrokeWidth(next.highlighterWidth);
                    break;
                  case ToolMode.eraser:
                    // 지우개는 색상 없음: setColor를 호출하면 drawing 상태로 바뀌므로 금지
                    notifier.setStrokeWidth(next.eraserWidth);
                    break;
                  case ToolMode.linker:
                    // 링크 모드는 Scribble 상태 변경 없음
                    break;
                }
              }
            },
          );
        }

        ref.onDispose(() {
          if (_cacheByPageId != null) {
            for (final notifier in _cacheByPageId!.values) {
              notifier.dispose();
            }
            _cacheByPageId = null;
          }
        });

        return map;
      },
      orElse: () => Future.value(<String, CustomScribbleNotifier>{}),
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
  final notifiersAsync = ref.watch(customScribbleNotifiersProvider(noteId));
  final currentIndex = ref.watch(currentPageIndexProvider(noteId));
  final note = ref.watch(noteProvider(noteId)).value;

  return notifiersAsync.when(
    data: (notifiers) {
      if (note == null || note.pages.isEmpty || notifiers.isEmpty) {
        // 기존 캐시된 notifier에서 설정 가져오기 시도
        final cachedNotifiers = ref.read(customScribbleNotifiersProvider(noteId)).valueOrNull;
        final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
        return _createEmptyNotifier(ref, noteId, null, preservedMode);
      }
      final page = note.pages[currentIndex];
      final existing = notifiers[page.pageId];
      if (existing != null) {
        return existing;
      }
      // 다른 페이지의 설정을 참조하여 일관성 유지
      final preservedMode = notifiers.values.firstOrNull?.value.allowedPointersMode;
      return _createEmptyNotifier(ref, noteId, page, preservedMode);
    },
    loading: () {
      // 로딩 중에는 기존 캐시된 notifier를 최대한 활용
      final cachedNotifiers = ref.read(customScribbleNotifiersProvider(noteId)).valueOrNull;

      if (note != null && note.pages.isNotEmpty && cachedNotifiers != null) {
        final page = note.pages[currentIndex];
        final existing = cachedNotifiers[page.pageId];
        if (existing != null) {
          return existing; // 캐시된 notifier가 있으면 그대로 사용
        }
      }

      // 캐시된 notifier가 없으면 fallback 생성
      if (note == null || note.pages.isEmpty) {
        final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
        return _createEmptyNotifier(ref, noteId, null, preservedMode);
      }

      final page = note.pages[currentIndex];
      final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
      return _createEmptyNotifier(ref, noteId, page, preservedMode);
    },
    error: (err, stack) {
      // Handle error, maybe log it
      // 기존 캐시된 notifier에서 설정 가져오기 시도
      final cachedNotifiers = ref.read(customScribbleNotifiersProvider(noteId)).valueOrNull;
      final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
      return _createEmptyNotifier(ref, noteId, null, preservedMode);
    },
  );
}

@riverpod
CustomScribbleNotifier pageNotifier(
  Ref ref,
  String noteId,
  int pageIndex,
) {
  final notifiersAsync = ref.watch(customScribbleNotifiersProvider(noteId));
  final note = ref.watch(noteProvider(noteId)).value;

  return notifiersAsync.when(
    data: (notifiers) {
      if (note == null ||
          note.pages.length <= pageIndex ||
          notifiers.isEmpty) {
        // 기존 캐시된 notifier에서 설정 가져오기 시도
        final cachedNotifiers = ref.read(customScribbleNotifiersProvider(noteId)).valueOrNull;
        final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
        return _createEmptyNotifier(ref, noteId, null, preservedMode);
      }
      final page = note.pages[pageIndex];
      final existing = notifiers[page.pageId];
      if (existing != null) {
        return existing;
      }
      // 다른 페이지의 설정을 참조하여 일관성 유지
      final preservedMode = notifiers.values.firstOrNull?.value.allowedPointersMode;
      return _createEmptyNotifier(ref, noteId, page, preservedMode);
    },
    loading: () {
      // 로딩 중에는 기존 캐시된 notifier를 최대한 활용
      final cachedNotifiers = ref.read(customScribbleNotifiersProvider(noteId)).valueOrNull;

      if (note != null && note.pages.length > pageIndex && cachedNotifiers != null) {
        final page = note.pages[pageIndex];
        final existing = cachedNotifiers[page.pageId];
        if (existing != null) {
          return existing; // 캐시된 notifier가 있으면 그대로 사용
        }
      }

      // 캐시된 notifier가 없으면 fallback 생성
      if (note == null || note.pages.length <= pageIndex) {
        final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
        return _createEmptyNotifier(ref, noteId, null, preservedMode);
      }

      final page = note.pages[pageIndex];
      final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
      return _createEmptyNotifier(ref, noteId, page, preservedMode);
    },
    error: (err, stack) {
      // Handle error, maybe log it
      // 기존 캐시된 notifier에서 설정 가져오기 시도
      final cachedNotifiers = ref.read(customScribbleNotifiersProvider(noteId)).valueOrNull;
      final preservedMode = cachedNotifiers?.values.firstOrNull?.value.allowedPointersMode;
      return _createEmptyNotifier(ref, noteId, null, preservedMode);
    },
  );
}

/// Helper to create a fallback empty notifier.
CustomScribbleNotifier _createEmptyNotifier(
    Ref ref, String noteId, NotePageModel? page, [ScribblePointerMode? preservedPointerMode]) {
  final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));
  final simulatePressure = ref.read(simulatePressureProvider);

  // 기존 설정이 있으면 보존, 없으면 노트별 상태에서 가져오기
  final allowedPointersMode = preservedPointerMode ?? ref.read(allowedPointersModeProvider(noteId));

  return CustomScribbleNotifier.createEmpty(
    toolMode: toolSettings.toolMode,
    page: page,
    simulatePressure: simulatePressure,
    allowedPointersMode: allowedPointersMode ?? ScribblePointerMode.all,
    maxHistoryLength: NoteEditorConstants.maxHistoryLength,
  );
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
