import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/atoms/app_fab_icon.dart';
import '../../../design_system/components/organisms/note_top_toolbar.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../shared/routing/route_observer.dart';
import '../../../shared/services/firebase_service_providers.dart';
import '../../../shared/services/sketch_persist_service.dart';
import '../../notes/data/derived_note_providers.dart';
import '../../notes/pages/page_controller_screen.dart';
import '../constants/note_editor_constant.dart';
import '../providers/note_editor_provider.dart';
import '../providers/note_editor_ui_provider.dart';
import '../widgets/note_editor_canvas.dart';
import '../widgets/panels/backlinks_panel.dart';
import '../widgets/toolbar/toolbar.dart';

// 노트 편집 화면 - 로직 및 UI 모두 존재
// 이걸 베이스로 각 항목 교체해야.. 로직 분리 안하고 진행할게요

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
    required this.noteId,
    required this.routeId,
  });

  /// 편집할 노트 ID.
  final String noteId;

  /// 이 라우트 인스턴스를 구분하는 고유 routeId.
  final String routeId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with RouteAware {
  late final ProviderSubscription<NoteEditorUiState> _uiSubscription;
  String? _lastLoggedNoteId;
  bool _isRouteActive = false;
  bool _lastRequestedFullscreen = false;
  bool? _lastAppliedFullscreen;

  /// Sync the initial page index from per-route resume or lastKnown after
  /// route becomes current and note data is available.
  void _scheduleSyncInitialIndexFromResume({bool allowLastKnown = true}) {
    void attempt() {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route?.isCurrent != true) return;

      final note = ref.read(noteProvider(widget.noteId)).value;
      final pageCount = note?.pages.length ?? 0;
      if (pageCount == 0) {
        // Try again next frame until note pages are available
        WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
        return;
      }

      final resumeMap = ref.read(
        resumePageIndexMapProvider(widget.noteId).notifier,
      );
      final resume = resumeMap.peek(widget.routeId);
      int? idx = resume;
      if (idx == null && allowLastKnown) {
        final lastKnown = ref.read(lastKnownPageIndexProvider(widget.noteId));
        if (lastKnown != null) idx = lastKnown;
      }
      if (idx == null) return;

      if (idx < 0) idx = 0;
      if (idx >= pageCount) idx = pageCount - 1;

      final prev = ref.read(currentPageIndexProvider(widget.noteId));
      if (prev != idx) {
        ref.read(currentPageIndexProvider(widget.noteId).notifier).setPage(idx);
      }
      if (resume != null) {
        // Consume the resume entry (one-time)
        resumeMap.take(widget.routeId);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  @override
  void initState() {
    super.initState();
    _uiSubscription = ref.listenManual<NoteEditorUiState>(
      noteEditorUiStateProvider(widget.noteId),
      (previous, next) {
        _lastRequestedFullscreen = next.isFullscreen;
        if (!_isRouteActive) return;
        if (previous?.isFullscreen == next.isFullscreen &&
            _lastAppliedFullscreen == next.isFullscreen) {
          return;
        }
        _applySystemUiForEditor(fullscreen: next.isFullscreen);
      },
      fireImmediately: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
      debugPrint('🧭 [RouteAware] subscribe noteId=${widget.noteId}');
      _isRouteActive = route.isCurrent;
      if (_isRouteActive) {
        _scheduleApplySystemUi();
      }
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    debugPrint('🧭 [RouteAware] unsubscribe noteId=${widget.noteId}');
    _restoreSystemUiIfNeeded();
    _uiSubscription.close();
    super.dispose();
  }

  @override
  void didPush() {
    _isRouteActive = true;
    _scheduleApplySystemUi();
    debugPrint(
      '🧭 [RouteAware] didPush noteId=${widget.noteId} → schedule enter session',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
      ref
          .read(noteRouteIdProvider(widget.noteId).notifier)
          .enter(widget.routeId);
      // After entering, sync from resume/lastKnown
      WidgetsBinding.instance.addPostFrameCallback((__) {
        _scheduleSyncInitialIndexFromResume(allowLastKnown: true);
      });
    });
  }

  @override
  void didPopNext() {
    final route = ModalRoute.of(context);
    final isCurrent = route?.isCurrent ?? false;
    debugPrint(
      '🧭 [RouteAware] didPopNext noteId=${widget.noteId} (isCurrent=$isCurrent)',
    );
    if (!isCurrent) {
      debugPrint(
        '🧭 [RouteAware] didPopNext skipped re-enter (route not current)',
      );
      return;
    }
    _isRouteActive = true;
    _scheduleApplySystemUi();
    // Ensure re-enter runs one frame AFTER didPop's exit to avoid final null.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route2 = ModalRoute.of(context);
      if (route2?.isCurrent != true) {
        debugPrint('🧭 [RouteAware] re-enter skipped (route lost current)');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((__) {
        if (!mounted) return;
        final route3 = ModalRoute.of(context);
        if (route3?.isCurrent != true) {
          debugPrint(
            '🧭 [RouteAware] re-enter skipped (route lost current, 2nd frame)',
          );
          return;
        }
        debugPrint('🧭 [RouteAware] re-enter session noteId=${widget.noteId}');
        ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
        ref
            .read(noteRouteIdProvider(widget.noteId).notifier)
            .enter(widget.routeId);
        WidgetsBinding.instance.addPostFrameCallback((___) {
          _scheduleSyncInitialIndexFromResume(allowLastKnown: false);
        });
      });
    });
  }

  @override
  void didPushNext() {
    _isRouteActive = false;
    _restoreSystemUiIfNeeded();
    debugPrint(
      '🧭 [RouteAware] didPushNext noteId=${widget.noteId} (save & no-op)',
    );
    // Save current page sketch when another route is pushed above
    // Fire-and-forget; errors are logged inside the service
    SketchPersistService.saveCurrentPage(ref, widget.noteId);
    // Do not write per-route resume/lastKnown for transient overlays (e.g., dialogs)
  }

  @override
  void didPop() {
    _isRouteActive = false;
    _restoreSystemUiIfNeeded();
    debugPrint(
      '🧭 [RouteAware] didPop noteId=${widget.noteId} → schedule exit session',
    );
    // Save current page when leaving editor via back
    SketchPersistService.saveCurrentPage(ref, widget.noteId);
    // On pop: remember lastKnown for cold re-open and clear per-route resume
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idx = ref.read(currentPageIndexProvider(widget.noteId));
      ref
          .read(lastKnownPageIndexProvider(widget.noteId).notifier)
          .setValue(idx);
      ref
          .read(resumePageIndexMapProvider(widget.noteId).notifier)
          .remove(widget.routeId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(noteSessionProvider.notifier).exitNote();
      ref.read(noteRouteIdProvider(widget.noteId).notifier).exit();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📝 [NoteEditorScreen] Building for noteId: ${widget.noteId}');

    // Guard: When using maintainState=false, ensure session+routeId re-entry
    // on first visible frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      final isCurrent = route?.isCurrent ?? false;
      if (isCurrent && !_isRouteActive) {
        _isRouteActive = true;
        _scheduleApplySystemUi();
      }
      final active = ref.read(noteSessionProvider);
      if (isCurrent && active != widget.noteId) {
        debugPrint(
          '🧭 [RouteAware] build-guard enter session noteId=${widget.noteId}',
        );
        ref.read(noteSessionProvider.notifier).enterNote(widget.noteId);
        ref
            .read(noteRouteIdProvider(widget.noteId).notifier)
            .enter(widget.routeId);
        WidgetsBinding.instance.addPostFrameCallback((__) {
          _scheduleSyncInitialIndexFromResume(allowLastKnown: true);
        });
      }
    });

    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final note = noteAsync.value;
    final noteTitle = note?.title ?? widget.noteId;
    final notePagesCount = ref.watch(notePagesCountProvider(widget.noteId));
    final currentIndex = ref.watch(currentPageIndexProvider(widget.noteId));

    debugPrint('📝 [NoteEditorScreen] Note async value: $note');
    debugPrint('📝 [NoteEditorScreen] Note pages count: $notePagesCount');
    debugPrint('📝 [NoteEditorScreen] Current page index: $currentIndex');

    // 노트가 사라진 경우(삭제 직후 등) 즉시 빈 화면 처리하여 BadState 방지
    if (note == null || notePagesCount == 0) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    if (_lastLoggedNoteId != note.noteId) {
      _lastLoggedNoteId = note.noteId;
      unawaited(
        ref
            .read(firebaseAnalyticsLoggerProvider)
            .logNoteOpen(
              noteId: note.noteId,
              source: 'route',
            ),
      );
    }

    final uiState = ref.watch(noteEditorUiStateProvider(widget.noteId));
    final uiNotifier = ref.read(
      noteEditorUiStateProvider(widget.noteId).notifier,
    );

    final titleWithPage = '$noteTitle · ${currentIndex + 1}/$notePagesCount';

    // Design: standard toolbar sits flush under app bar (no extra top gap),
    // fullscreen pill sits just below the status bar.
    // SafeArea handles padding.top when fullscreen, so we only add extra spacing.
    final double toolbarTop = uiState.isFullscreen ? AppSpacing.small : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // backgroundColor: AppColors.gray10,
      appBar: uiState.isFullscreen
          ? null
          : NoteTopToolbar(
              title: titleWithPage,
              leftActions: [
                ToolbarAction(
                  svgPath: AppIcons.chevronLeft,
                  onTap: () => Navigator.of(context).maybePop(),
                  tooltip: '뒤로',
                ),
              ],
              rightActions: [
                ToolbarAction(
                  svgPath: AppIcons.scale,
                  onTap: uiNotifier.enterFullscreen,
                  tooltip: '전체 화면',
                ),
                ToolbarAction(
                  svgPath: AppIcons.linkList,
                  onTap: () => showBacklinksPanel(context, widget.noteId),
                  tooltip: '백링크',
                ),
                ToolbarAction(
                  svgPath: AppIcons.pageManage,
                  onTap: () =>
                      PageControllerScreen.show(context, widget.noteId),
                  tooltip: '페이지 관리',
                ),
              ],
            ),
      body: SafeArea(
        child: Stack(
          children: [
            // Fill entire body area with the canvas; outer paddings removed so
            // the drawing surface can expand edge-to-edge under the toolbar.
            Positioned.fill(
              child: NoteEditorCanvas(
                noteId: widget.noteId,
                routeId: widget.routeId,
              ),
            ),
            Positioned(
              top: toolbarTop,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.topCenter,
                child: NoteEditorToolbar(
                  noteId: widget.noteId,
                  canvasWidth: NoteEditorConstants.canvasWidth,
                  canvasHeight: NoteEditorConstants.canvasHeight,
                ),
              ),
            ),
            if (uiState.isFullscreen)
              Positioned(
                right: AppSpacing.screenPadding,
                top: AppSpacing.large,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppFabIcon(
                      svgPath: AppIcons.scaleReverse,
                      visualDiameter: 34,
                      minTapTarget: 44,
                      iconSize: 16,
                      tooltip: '닫기',
                      onPressed: uiNotifier.exitFullscreen,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    AppFabIcon(
                      svgPath: AppIcons.linkList,
                      visualDiameter: 34,
                      minTapTarget: 44,
                      iconSize: 16,
                      tooltip: '백링크',
                      onPressed: () =>
                          showBacklinksPanel(context, widget.noteId),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    AppFabIcon(
                      svgPath: AppIcons.pageManage,
                      visualDiameter: 34,
                      minTapTarget: 44,
                      iconSize: 16,
                      tooltip: '페이지 관리',
                      onPressed: () =>
                          PageControllerScreen.show(context, widget.noteId),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _supportsSystemUiOverrides =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _applySystemUiForEditor({required bool fullscreen}) {
    if (!_supportsSystemUiOverrides) return;
    if (_lastAppliedFullscreen == fullscreen) return;
    _lastAppliedFullscreen = fullscreen;
    final future = fullscreen
        ? SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)
        : SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: const [SystemUiOverlay.top],
          );
    unawaited(future);
  }

  void _restoreSystemUiIfNeeded() {
    if (!_supportsSystemUiOverrides) return;
    if (_lastAppliedFullscreen == null) return;
    _lastAppliedFullscreen = null;
    final future = SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    unawaited(future);
  }

  void _scheduleApplySystemUi() {
    if (!_isRouteActive) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isRouteActive) return;
      _applySystemUiForEditor(fullscreen: _lastRequestedFullscreen);
    });
  }
}
