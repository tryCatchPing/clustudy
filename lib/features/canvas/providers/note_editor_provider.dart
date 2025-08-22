import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../main.dart';
import '../../../shared/services/page_thumbnail_service.dart';
import '../../notes/data/derived_note_providers.dart';
import '../../notes/data/notes_repository_provider.dart';
import '../../notes/models/note_model.dart';
import '../../notes/models/note_page_model.dart';
import '../constants/note_editor_constant.dart';
import '../models/tool_mode.dart';
import '../notifiers/custom_scribble_notifier.dart';
import 'tool_settings_provider.dart';

part 'note_editor_provider.g.dart';

// fvm dart run build_runner watch 명령어로 코드 변경 시 자동으로 빌드됨

// ========================================================================
// GoRouter 기반 자동 세션 관리 Provider들
// ========================================================================

/// 노트 세션 상태 관리 (기존 CanvasSession에서 개명)
@riverpod
class NoteSession extends _$NoteSession {
  @override
  String? build() => null; // 현재 활성 noteId
  
  void enterNote(String noteId) => state = noteId;
  void exitNote() => state = null;
}

/// GoRouter 인스턴스 접근을 위한 Provider
@riverpod
GoRouter goRouter(Ref ref) {
  return globalRouter;
}

/// 현재 라우트 경로를 감지하는 Provider
@riverpod
class CurrentPath extends _$CurrentPath {
  @override
  String? build() {
    final router = ref.read(goRouterProvider);
    
    // 현재 경로 가져오기
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
    
    // GoRouter delegate에 listener 추가하여 경로 변경 감지
    router.routerDelegate.addListener(_onRouteChanged);
    
    // Provider dispose시 listener 제거
    ref.onDispose(() {
      router.routerDelegate.removeListener(_onRouteChanged);
    });
    
    return currentLocation;
  }
  
  void _onRouteChanged() {
    final router = ref.read(goRouterProvider);
    final newLocation = router.routerDelegate.currentConfiguration.uri.path;
    // 경로가 실제로 변경된 경우에만 state 업데이트
    if (state != newLocation) {
      // Widget tree building 중 provider 수정을 방지하기 위해 Future로 지연
      Future(() {
        state = newLocation;
      });
    }
  }
}

/// 핵심 세션 관리 Observer - 경로 변경을 감지하여 자동 세션 관리
@riverpod
void noteSessionObserver(Ref ref) {
  // 현재 경로 변경을 감지
  final currentPath = ref.watch(currentPathProvider);
  
  if (currentPath == null) return;
  
  // /notes/{noteId}/edit 패턴 매칭
  final noteEditPattern = RegExp(r'^/notes/([^/]+)/edit$');
  final match = noteEditPattern.firstMatch(currentPath);
  
  if (match != null) {
    // 노트 편집 화면 진입 - 세션 시작
    final noteId = match.group(1)!;
    // 다른 provider를 수정하기 전에 현재 상태 확인
    final currentSession = ref.read(noteSessionProvider);
    if (currentSession != noteId) {
      ref.read(noteSessionProvider.notifier).enterNote(noteId);
    }
  } else {
    // 다른 화면 이동 - 세션 종료
    final currentSession = ref.read(noteSessionProvider);
    if (currentSession != null) {
      ref.read(noteSessionProvider.notifier).exitNote();
    }
  }
}

// ========================================================================
// 기존 Canvas 관련 Provider들 (noteSessionProvider 참조로 수정)
// ========================================================================

/// 기존 CanvasSession Provider 호환성을 위한 alias
@Deprecated('Use noteSessionProvider instead')
final canvasSessionProvider = noteSessionProvider;

/// 현재 페이지 인덱스 관리
/// noteId(String)로 노트별 독립 관리 (family provider)
@riverpod
class CurrentPageIndex extends _$CurrentPageIndex {
  @override
  int build(String noteId) => 0; // 노트별로 독립적인 현재 페이지 인덱스

  /// 페이지 인덱스를 설정합니다.
  void setPage(int newIndex) => state = newIndex;
}

/// 필압 시뮬레이션 상태 관리
/// 파라미터 없으므로 싱글톤, 전역 상태 관리 (모든 노트 적용)
@Riverpod(keepAlive: true)
class SimulatePressure extends _$SimulatePressure {
  @override
  bool build() => false;

  /// 필압 시뮬레이션을 토글합니다.
  void toggle() => state = !state;

  /// 필압 시뮬레이션 값을 설정합니다.
  void setValue(bool value) => state = value;
}

/// 세션 기반 페이지별 CustomScribbleNotifier 관리
@riverpod
CustomScribbleNotifier canvasPageNotifier(Ref ref, String pageId) {
  // 세션 확인 - 활성 노트가 없으면 에러
  final activeNoteId = ref.watch(noteSessionProvider);
  if (activeNoteId == null) {
    throw StateError('No note session for pageId: $pageId');
  }
  
  // 세션 내에서 영구 보존
  ref.keepAlive();
  
  // 페이지 정보 조회
  final allNotesAsync = ref.watch(notesProvider);
  
  NotePageModel? targetPage;
  
  allNotesAsync.whenData((List<NoteModel> notes) {
    for (final note in notes) {
      if (note.noteId == activeNoteId) {
        for (final page in note.pages) {
          if (page.pageId == pageId) {
            targetPage = page;
            return;
          }
        }
      }
    }
  });
  
  if (targetPage == null) {
      // 페이지를 찾을 수 없는 경우 no-op notifier
      return CustomScribbleNotifier(
        toolMode: ToolMode.pen,
        page: null,
        simulatePressure: false,
        maxHistoryLength: NoteEditorConstants.maxHistoryLength,
      );
    }
    
  // 도구 설정 및 필압 시뮬레이션 상태 가져오기
  final toolSettings = ref.read(toolSettingsNotifierProvider(activeNoteId));
    final simulatePressure = ref.read(simulatePressureProvider);
    
    // CustomScribbleNotifier 생성
    final notifier = CustomScribbleNotifier(
      toolMode: toolSettings.toolMode,
      page: targetPage,
      simulatePressure: simulatePressure,
      maxHistoryLength: NoteEditorConstants.maxHistoryLength,
    )
      ..setSimulatePressureEnabled(simulatePressure)
      ..setSketch(
        sketch: targetPage!.toSketch(),
        addToUndoHistory: false,
      );
    
    // 초기 도구 설정 적용
    _applyToolSettings(notifier, toolSettings);
    
  // 도구 설정 변경 리스너
  ref.listen<ToolSettings>(
    toolSettingsNotifierProvider(activeNoteId),
    (ToolSettings? prev, ToolSettings next) {
      _applyToolSettings(notifier, next);
    },
  );
    
    // 필압 시뮬레이션 변경 리스너
    ref.listen<bool>(simulatePressureProvider, (bool? prev, bool next) {
      notifier.setSimulatePressureEnabled(next);
    });
    
    // dispose 시 정리
    ref.onDispose(() {
      notifier.dispose();
    });
    
  return notifier;
}
  
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
        notifier.setStrokeWidth(settings.eraserWidth);
        break;
      case ToolMode.linker:
        break;
    }
}

/// 특정 노트의 페이지 ID 목록을 반환
@riverpod
List<String> notePageIds(Ref ref, String noteId) {
  final noteAsync = ref.watch(noteProvider(noteId));
  return noteAsync.when(
    data: (note) => note?.pages.map((p) => p.pageId).toList() ?? [],
    error: (_, __) => [],
    loading: () => [],
  );
}

/// 노트의 모든 페이지 notifier들을 맵으로 반환 (기존 API 호환성)
@riverpod
Map<String, CustomScribbleNotifier> notePageNotifiers(Ref ref, String noteId) {
  final pageIds = ref.watch(notePageIdsProvider(noteId));
  final result = <String, CustomScribbleNotifier>{};
  
  for (final pageId in pageIds) {
    final notifier = ref.watch(canvasPageNotifierProvider(pageId));
    result[pageId] = notifier;
  }
  
  return result;
}

/// 현재 페이지 인덱스에 해당하는 CustomScribbleNotifier 반환
@riverpod
CustomScribbleNotifier currentNotifier(
  Ref ref,
  String noteId,
) {
  final currentIndex = ref.watch(currentPageIndexProvider(noteId));
  final note = ref.watch(noteProvider(noteId)).value;
  final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));
  final simulatePressure = ref.read(simulatePressureProvider);

  if (note == null || note.pages.isEmpty || currentIndex >= note.pages.length) {
    // 노트가 없거나 페이지가 없는 경우에는 no-op Notifier를 반환
    return CustomScribbleNotifier(
      toolMode: toolSettings.toolMode,
      page: null,
      simulatePressure: simulatePressure,
      maxHistoryLength: NoteEditorConstants.maxHistoryLength,
    );
  }

  final page = note.pages[currentIndex];
  return ref.watch(canvasPageNotifierProvider(page.pageId));
}

@riverpod
CustomScribbleNotifier pageNotifier(
  Ref ref,
  String noteId,
  int pageIndex,
) {
  final note = ref.watch(noteProvider(noteId)).value;
  final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));
  final simulatePressure = ref.read(simulatePressureProvider);

  if (note == null || note.pages.length <= pageIndex || pageIndex < 0) {
    // 유효하지 않은 페이지 접근에도 no-op Notifier 반환
    return CustomScribbleNotifier(
      toolMode: toolSettings.toolMode,
      page: null,
      simulatePressure: simulatePressure,
      maxHistoryLength: NoteEditorConstants.maxHistoryLength,
    );
  }

  final page = note.pages[pageIndex];
  return ref.watch(canvasPageNotifierProvider(page.pageId));
}

/// 기존 API 호환성을 위한 customScribbleNotifiers provider
@riverpod
Map<String, CustomScribbleNotifier> customScribbleNotifiers(
  Ref ref,
  String noteId,
) {
  return ref.watch(notePageNotifiersProvider(noteId));
}

/// PageController
/// 노트별로 독립적으로 관리 (family provider)
/// 화면 이탈 시 해제되어 재입장 시 0페이지부터 시작
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

// ========================================================================
// 페이지 컨트롤러 상태 관리
// ========================================================================

/// 페이지 컨트롤러의 전반적인 상태를 나타내는 클래스입니다.
class PageControllerState {
  /// 페이지 컨트롤러가 로딩 중인지 여부.
  final bool isLoading;

  /// 썸네일 로딩 상태 맵 (pageId -> 로딩 여부).
  final Map<String, bool> thumbnailLoadingStates;

  /// 썸네일 캐시 맵 (pageId -> 썸네일 바이트).
  final Map<String, Uint8List?> thumbnailCache;

  /// 드래그 앤 드롭 상태.
  final DragDropState dragDropState;

  /// 오류 메시지 (있는 경우).
  final String? errorMessage;

  /// 현재 진행 중인 작업 (있는 경우).
  final String? currentOperation;

  /// [PageControllerState]의 생성자.
  const PageControllerState({
    this.isLoading = false,
    this.thumbnailLoadingStates = const {},
    this.thumbnailCache = const {},
    this.dragDropState = const DragDropState(),
    this.errorMessage,
    this.currentOperation,
  });

  /// 새 값으로 일부 필드를 교체한 복제본을 반환합니다.
  PageControllerState copyWith({
    bool? isLoading,
    Map<String, bool>? thumbnailLoadingStates,
    Map<String, Uint8List?>? thumbnailCache,
    DragDropState? dragDropState,
    String? errorMessage,
    String? currentOperation,
  }) {
    return PageControllerState(
      isLoading: isLoading ?? this.isLoading,
      thumbnailLoadingStates:
          thumbnailLoadingStates ?? this.thumbnailLoadingStates,
      thumbnailCache: thumbnailCache ?? this.thumbnailCache,
      dragDropState: dragDropState ?? this.dragDropState,
      errorMessage: errorMessage,
      currentOperation: currentOperation,
    );
  }

  /// 오류 상태를 클리어한 복제본을 반환합니다.
  PageControllerState clearError() {
    return copyWith(
      errorMessage: null,
      currentOperation: null,
    );
  }

  /// 특정 페이지의 썸네일이 로딩 중인지 확인합니다.
  bool isThumbnailLoading(String pageId) {
    return thumbnailLoadingStates[pageId] ?? false;
  }

  /// 특정 페이지의 썸네일을 가져옵니다.
  Uint8List? getThumbnail(String pageId) {
    return thumbnailCache[pageId];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PageControllerState &&
        other.isLoading == isLoading &&
        _mapEquals(other.thumbnailLoadingStates, thumbnailLoadingStates) &&
        _mapEquals(other.thumbnailCache, thumbnailCache) &&
        other.dragDropState == dragDropState &&
        other.errorMessage == errorMessage &&
        other.currentOperation == currentOperation;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        thumbnailLoadingStates.hashCode ^
        thumbnailCache.hashCode ^
        dragDropState.hashCode ^
        errorMessage.hashCode ^
        currentOperation.hashCode;
  }

  /// 맵 동등성 비교 헬퍼 메서드.
  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }
}

/// 드래그 앤 드롭 상태를 나타내는 클래스입니다.
class DragDropState {
  /// 드래그가 활성화되어 있는지 여부.
  final bool isDragging;

  /// 드래그 중인 페이지의 ID (있는 경우).
  final String? draggingPageId;

  /// 드래그 시작 인덱스.
  final int? dragStartIndex;

  /// 현재 드래그 위치 인덱스.
  final int? currentDragIndex;

  /// 드롭 가능한 위치들.
  final List<int> validDropIndices;

  /// [DragDropState]의 생성자.
  const DragDropState({
    this.isDragging = false,
    this.draggingPageId,
    this.dragStartIndex,
    this.currentDragIndex,
    this.validDropIndices = const [],
  });

  /// 새 값으로 일부 필드를 교체한 복제본을 반환합니다.
  DragDropState copyWith({
    bool? isDragging,
    String? draggingPageId,
    int? dragStartIndex,
    int? currentDragIndex,
    List<int>? validDropIndices,
  }) {
    return DragDropState(
      isDragging: isDragging ?? this.isDragging,
      draggingPageId: draggingPageId,
      dragStartIndex: dragStartIndex,
      currentDragIndex: currentDragIndex,
      validDropIndices: validDropIndices ?? this.validDropIndices,
    );
  }

  /// 드래그 상태를 초기화한 복제본을 반환합니다.
  DragDropState reset() {
    return const DragDropState();
  }

  /// 특정 인덱스가 드롭 가능한지 확인합니다.
  bool isValidDropIndex(int index) {
    return validDropIndices.contains(index);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DragDropState &&
        other.isDragging == isDragging &&
        other.draggingPageId == draggingPageId &&
        other.dragStartIndex == dragStartIndex &&
        other.currentDragIndex == currentDragIndex &&
        _listEquals(other.validDropIndices, validDropIndices);
  }

  @override
  int get hashCode {
    return isDragging.hashCode ^
        draggingPageId.hashCode ^
        dragStartIndex.hashCode ^
        currentDragIndex.hashCode ^
        validDropIndices.hashCode;
  }

  /// 리스트 동등성 비교 헬퍼 메서드.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// 페이지 컨트롤러 상태를 관리하는 Notifier입니다.
@riverpod
class PageControllerNotifier extends _$PageControllerNotifier {
  @override
  PageControllerState build(String noteId) {
    return const PageControllerState();
  }

  /// 전체 로딩 상태를 설정합니다.
  void setLoading(bool isLoading, {String? operation}) {
    state = state.copyWith(
      isLoading: isLoading,
      currentOperation: operation,
    );
  }

  /// 오류 상태를 설정합니다.
  void setError(String errorMessage) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: errorMessage,
      currentOperation: null,
    );
  }

  /// 오류 상태를 클리어합니다.
  void clearError() {
    state = state.clearError();
  }

  /// 특정 페이지의 썸네일 로딩 상태를 설정합니다.
  void setThumbnailLoading(String pageId, bool isLoading) {
    final newLoadingStates = Map<String, bool>.from(
      state.thumbnailLoadingStates,
    );
    if (isLoading) {
      newLoadingStates[pageId] = true;
    } else {
      newLoadingStates.remove(pageId);
    }

    state = state.copyWith(thumbnailLoadingStates: newLoadingStates);
  }

  /// 썸네일을 캐시에 저장합니다.
  void cacheThumbnail(String pageId, Uint8List? thumbnail) {
    final newCache = Map<String, Uint8List?>.from(state.thumbnailCache);
    newCache[pageId] = thumbnail;

    state = state.copyWith(thumbnailCache: newCache);
  }

  /// 특정 페이지의 썸네일 캐시를 무효화합니다.
  void invalidateThumbnail(String pageId) {
    final newCache = Map<String, Uint8List?>.from(state.thumbnailCache);
    newCache.remove(pageId);

    state = state.copyWith(thumbnailCache: newCache);
  }

  /// 모든 썸네일 캐시를 클리어합니다.
  void clearThumbnailCache() {
    state = state.copyWith(
      thumbnailCache: {},
      thumbnailLoadingStates: {},
    );
  }

  /// 드래그를 시작합니다.
  void startDrag(
    String pageId,
    int startIndex,
    List<int> validDropIndices,
  ) {
    final newDragState = state.dragDropState.copyWith(
      isDragging: true,
      draggingPageId: pageId,
      dragStartIndex: startIndex,
      currentDragIndex: startIndex,
      validDropIndices: validDropIndices,
    );

    state = state.copyWith(dragDropState: newDragState);
  }

  /// 드래그 위치를 업데이트합니다.
  void updateDragPosition(int currentIndex) {
    if (!state.dragDropState.isDragging) {
      return;
    }

    final newDragState = state.dragDropState.copyWith(
      currentDragIndex: currentIndex,
    );

    state = state.copyWith(dragDropState: newDragState);
  }

  /// 드래그를 종료합니다.
  void endDrag() {
    state = state.copyWith(dragDropState: state.dragDropState.reset());
  }

  /// 드래그를 취소합니다.
  void cancelDrag() {
    state = state.copyWith(dragDropState: state.dragDropState.reset());
  }
}

/// 특정 페이지의 썸네일을 가져오는 provider입니다.
@riverpod
Future<Uint8List?> pageThumbnail(
  Ref ref,
  String noteId,
  String pageId,
) async {
  final pageControllerNotifier = ref.read(
    pageControllerNotifierProvider(noteId).notifier,
  );
  final repository = ref.read(notesRepositoryProvider);

  // 캐시된 썸네일이 있는지 확인
  final cachedThumbnail = ref
      .read(pageControllerNotifierProvider(noteId))
      .getThumbnail(pageId);
  if (cachedThumbnail != null) {
    return cachedThumbnail;
  }

  // 로딩 상태 설정
  pageControllerNotifier.setThumbnailLoading(pageId, true);

  try {
    // 페이지 정보 가져오기
    final note = await repository.getNoteById(noteId);
    if (note == null) {
      throw Exception('Note not found: $noteId');
    }

    final page = note.pages.firstWhere(
      (p) => p.pageId == pageId,
      orElse: () => throw Exception('Page not found: $pageId'),
    );

    // 썸네일 생성 또는 캐시에서 가져오기
    final thumbnail = await PageThumbnailService.getOrGenerateThumbnail(
      page,
      repository,
    );

    // 캐시에 저장
    pageControllerNotifier.cacheThumbnail(pageId, thumbnail);

    return thumbnail;
  } catch (e) {
    // 오류 발생 시 플레이스홀더 생성
    try {
      final note = await repository.getNoteById(noteId);
      if (note != null) {
        final page = note.pages.firstWhere((p) => p.pageId == pageId);
        final placeholder =
            await PageThumbnailService.generatePlaceholderThumbnail(
              page.pageNumber,
            );
        pageControllerNotifier.cacheThumbnail(pageId, placeholder);
        return placeholder;
      }
    } catch (_) {
      // 플레이스홀더 생성도 실패한 경우
    }

    pageControllerNotifier.setError('썸네일 로드 실패: $e');
    return null;
  } finally {
    // 로딩 상태 해제
    pageControllerNotifier.setThumbnailLoading(pageId, false);
  }
}

/// 노트의 모든 페이지 썸네일을 미리 로드하는 provider입니다.
@riverpod
Future<void> preloadThumbnails(
  Ref ref,
  String noteId,
) async {
  final pageControllerNotifier = ref.read(
    pageControllerNotifierProvider(noteId).notifier,
  );
  final repository = ref.read(notesRepositoryProvider);

  try {
    pageControllerNotifier.setLoading(true, operation: '썸네일 로딩 중...');

    final note = await repository.getNoteById(noteId);
    if (note == null) {
      throw Exception('Note not found: $noteId');
    }

    // 모든 페이지의 썸네일을 병렬로 로드
    final futures = note.pages.map((page) async {
      try {
        final thumbnail = await PageThumbnailService.getOrGenerateThumbnail(
          page,
          repository,
        );
        pageControllerNotifier.cacheThumbnail(page.pageId, thumbnail);
      } catch (e) {
        // 개별 페이지 실패는 무시하고 플레이스홀더 사용
        try {
          final placeholder =
              await PageThumbnailService.generatePlaceholderThumbnail(
                page.pageNumber,
              );
          pageControllerNotifier.cacheThumbnail(page.pageId, placeholder);
        } catch (_) {
          // 플레이스홀더도 실패하면 null로 설정
          pageControllerNotifier.cacheThumbnail(page.pageId, null);
        }
      }
    });

    await Future.wait(futures);
  } catch (e) {
    pageControllerNotifier.setError('썸네일 미리 로드 실패: $e');
  } finally {
    pageControllerNotifier.setLoading(false);
  }
}
