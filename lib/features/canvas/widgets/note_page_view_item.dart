import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/scribble.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../shared/dialogs/design_sheet_helpers.dart';
import '../../../shared/errors/app_error_mapper.dart';
import '../../../shared/errors/app_error_spec.dart';
import '../../../shared/routing/app_routes.dart';
import '../../../shared/services/firebase_service_providers.dart';
import '../../../shared/services/sketch_persist_service.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../canvas/providers/pointer_policy_provider.dart';
import '../../notes/data/derived_note_providers.dart';
import '../constants/note_editor_constant.dart'; // NoteEditorConstants 정의 필요
import '../notifiers/custom_scribble_notifier.dart';
import '../providers/link_creation_controller.dart';
import '../providers/link_providers.dart';
import '../providers/note_editor_provider.dart';
import '../providers/pointer_snapshot_provider.dart';
import '../providers/tool_settings_provider.dart';
import '../providers/transformation_controller_provider.dart';
import 'canvas_background_widget.dart'; // CanvasBackgroundWidget 정의 필요
import 'dialogs/link_actions_sheet.dart';
import 'dialogs/link_creation_dialog.dart';
import 'linker_gesture_layer.dart';
import 'saved_links_layer.dart';

/// Note 편집 화면의 단일 페이지 뷰 아이템입니다.
class NotePageViewItem extends ConsumerStatefulWidget {
  final String noteId;
  final int pageIndex;

  /// [NotePageViewItem]의 생성자.
  ///
  const NotePageViewItem({
    required this.noteId,
    required this.pageIndex,
    super.key,
  });

  @override
  ConsumerState<NotePageViewItem> createState() => _NotePageViewItemState();
}

class _NotePageViewItemState extends ConsumerState<NotePageViewItem> {
  Timer? _debounceTimer;
  double _lastScale = 1.0;
  // 임시 드래그 상태는 LinkerGestureLayer 내부에서만 관리되므로 상태 제거
  final GlobalKey _linkerLayerKey = GlobalKey();

  // 비-build 컨텍스트에서 현재 노트의 notifier 접근용
  CustomScribbleNotifier get _currentNotifier =>
      ref.read(pageNotifierProvider(widget.noteId, widget.pageIndex));

  // dispose에서 ref.read 사용을 피하기 위해 캐시
  late final TransformationController _tc;

  @override
  void initState() {
    super.initState();
    _tc = ref.read(transformationControllerProvider(widget.noteId));
    _tc.addListener(_onScaleChanged);
    _updateScale(); // 초기 스케일 설정
  }

  @override
  void dispose() {
    _tc.removeListener(_onScaleChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 포인트 간격 조정을 위한 스케일 동기화.
  void _onScaleChanged() {
    if (!mounted) {
      return;
    }

    // 스케일 변경 감지 및 디바운스 로직 (구현 생략)
    final currentScale = _tc.value.getMaxScaleOnAxis();
    if ((currentScale - _lastScale).abs() < 0.01) {
      return;
    }
    _lastScale = currentScale;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 8), _updateScale);
  }

  /// 스케일을 업데이트합니다.
  void _updateScale() {
    if (!mounted) {
      return;
    }
    // Provider 준비 상태를 확인 후 안전하게 동기화
    final note = ref.read(noteProvider(widget.noteId)).value;
    if (note == null || note.pages.length <= widget.pageIndex) {
      return;
    }
    try {
      _currentNotifier.syncWithViewerScale(
        _tc.value.getMaxScaleOnAxis(),
      );
    } catch (_) {
      // 초기 프레임에서 Notifier가 아직 생성되지 않은 경우가 있어 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    // 노트/페이지가 유효하지 않으면 즉시 비표시 처리하여 삭제 직후 레이스를 방지
    final note = ref.watch(noteProvider(widget.noteId)).value;
    if (note == null || note.pages.length <= widget.pageIndex) {
      return const SizedBox.shrink();
    }

    final pointerPolicy = ref.watch(pointerPolicyProvider);
    final pointerSnapshot = ref.watch(pointerSnapshotProvider(widget.noteId));
    final notifier = ref.watch(
      pageNotifierProvider(widget.noteId, widget.pageIndex),
    );
    final pointerTracker = ref.read(
      pointerSnapshotProvider(widget.noteId).notifier,
    );

    // 화면 종료 과정에서 notifier가 비어있을 수 있으므로 null 체크 추가
    if (notifier.page == null) {
      return const SizedBox.shrink();
    }

    final drawingWidth = notifier.page!.drawingAreaWidth;
    final drawingHeight = notifier.page!.drawingAreaHeight;
    final isLinkerMode = notifier.toolMode.isLinker;

    debugPrint(
      '[NotePageViewItem] build: '
      'noteId=${widget.noteId}, pageId=${notifier.page!.pageId}, '
      'tool=${notifier.toolMode}, '
      'linkerMode=$isLinkerMode, '
      'drawing=${drawingWidth.toStringAsFixed(0)}x${drawingHeight.toStringAsFixed(0)}',
    );

    // -- NotePageViewItem의 build 메서드 내부--
    if (!isLinkerMode) {
      debugPrint('렌더링: Scribble 위젯');
    }
    if (isLinkerMode) {
      debugPrint('렌더링: LinkerGestureLayer (CustomPaint + GestureDetector)');
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: pointerTracker.registerPointerDown,
      onPointerUp: pointerTracker.registerPointerUp,
      onPointerCancel: pointerTracker.registerPointerCancel,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: ValueListenableBuilder<ScribbleState>(
            valueListenable: notifier,
            builder: (context, scribbleState, _) {
              final hasStylusDown = pointerSnapshot.hasStylus;
              final multiplePointersActive =
                  pointerSnapshot.hasMultiplePointers && !hasStylusDown;
              final allowSingleFingerPan =
                  pointerPolicy == ScribblePointerMode.penOnly &&
                  !hasStylusDown;
              final panEnabled =
                  (!isLinkerMode &&
                      (allowSingleFingerPan || multiplePointersActive)) ||
                  (isLinkerMode &&
                      pointerPolicy == ScribblePointerMode.penOnly &&
                      !hasStylusDown);

              return InteractiveViewer(
                transformationController: ref.watch(
                  transformationControllerProvider(widget.noteId),
                ),
                minScale: 0.3,
                maxScale: 3.0,
                constrained: false,
                panEnabled: panEnabled,
                scaleEnabled: true,
                onInteractionEnd: (details) {
                  _debounceTimer?.cancel();
                  _updateScale();
                },
                child: SizedBox(
                  width: drawingWidth * NoteEditorConstants.canvasScale,
                  height: drawingHeight * NoteEditorConstants.canvasScale,
                  child: Center(
                    child: SizedBox(
                      width: drawingWidth,
                      height: drawingHeight,
                      child: ValueListenableBuilder<ScribbleState>(
                        valueListenable: notifier,
                        builder: (context, scribbleState, child) {
                          final currentToolMode = ref
                              .read(toolSettingsNotifierProvider(widget.noteId))
                              .toolMode;
                          return Stack(
                            children: [
                              // 배경 레이어
                              CanvasBackgroundWidget(
                                page: notifier.page!,
                                width: drawingWidth,
                                height: drawingHeight,
                              ),
                              // 저장된 링크 레이어 (Provider 기반)
                              SavedLinksLayer(
                                pageId: notifier.page!.pageId,
                                fillColor: AppColors.linkerBlue.withAlpha(
                                  (255 * 0.15).round(),
                                ),
                                borderColor: AppColors.linkerBlue,
                                borderWidth: 2.0,
                              ),
                              // 필기 레이어 (링커 모드가 아닐 때만 활성화)
                              IgnorePointer(
                                ignoring: currentToolMode.isLinker,
                                child: ClipRect(
                                  child: Scribble(
                                    notifier: notifier,
                                    drawPen: !currentToolMode.isLinker,
                                    simulatePressure: ref.watch(
                                      simulatePressureProvider,
                                    ),
                                  ),
                                ),
                              ),
                              // 패닝은 InteractiveViewer가 처리
                              // 링커 제스처 및 그리기 레이어 (항상 존재하며, 내부적으로 toolMode에 따라 드래그/탭 처리)
                              Positioned.fill(
                                child: LinkerGestureLayer(
                                  key: _linkerLayerKey,
                                  toolMode: currentToolMode,
                                  pointerMode:
                                      pointerPolicy == ScribblePointerMode.all
                                      ? LinkerPointerMode.all
                                      : LinkerPointerMode.stylusOnly,
                                  onStylusInteractionChanged: (active) {
                                    ref
                                        .read(
                                          pointerSnapshotProvider(
                                            widget.noteId,
                                          ).notifier,
                                        )
                                        .setLinkerStylusActive(active);
                                  },
                                  onRectCompleted: (rect) async {
                                    final currentPage = notifier.page!;
                                    unawaited(
                                      ref
                                          .read(firebaseAnalyticsLoggerProvider)
                                          .logLinkDrawn(
                                            sourceNoteId: currentPage.noteId,
                                            sourcePageId: currentPage.pageId,
                                          ),
                                    );
                                    final res = await LinkCreationDialog.show(
                                      context,
                                      sourceNoteId: currentPage.noteId,
                                    );
                                    if (res == null) return; // 취소
                                    try {
                                      await ref
                                          .read(linkCreationControllerProvider)
                                          .createFromRect(
                                            sourceNoteId: currentPage.noteId,
                                            sourcePageId: currentPage.pageId,
                                            rect: rect,
                                            targetNoteId: res.targetNoteId,
                                            targetTitle: res.targetTitle,
                                          );
                                      if (!mounted) return;
                                      AppSnackBar.show(
                                        context,
                                        AppErrorSpec.success('링크를 생성했습니다.'),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      final spec = AppErrorMapper.toSpec(e);
                                      AppSnackBar.show(context, spec);
                                    }
                                  },
                                  // 링크 찾아서 모달 표시 (링크 이동 / 링크 수정 / 링크 삭제)
                                  onTapAt: (localPoint) async {
                                    // provider 로 수정필요
                                    final pageId = notifier.page!.pageId;
                                    final link = ref.read(
                                      linkAtPointProvider(pageId, localPoint),
                                    );
                                    if (link != null) {
                                      // 탭 지점의 글로벌 좌표 계산
                                      Offset anchorGlobal = localPoint;
                                      final box =
                                          _linkerLayerKey.currentContext
                                                  ?.findRenderObject()
                                              as RenderBox?;
                                      if (box != null) {
                                        anchorGlobal = box.localToGlobal(
                                          localPoint,
                                        );
                                      }
                                      final action =
                                          await LinkActionsSheet.show(
                                            context,
                                            link,
                                            anchorGlobal: anchorGlobal,
                                            displayTitle: link.label,
                                          );
                                      if (!mounted || action == null) return;
                                      switch (action) {
                                        case LinkAction.navigate:
                                          // Save current page before navigating to the target note
                                          await SketchPersistService.saveCurrentPage(
                                            ref,
                                            widget.noteId,
                                          );
                                          // Store per-route resume index for this editor instance
                                          final idx = ref.read(
                                            currentPageIndexProvider(
                                              widget.noteId,
                                            ),
                                          );
                                          final routeId = ref.read(
                                            noteRouteIdProvider(widget.noteId),
                                          );
                                          if (routeId != null) {
                                            ref
                                                .read(
                                                  resumePageIndexMapProvider(
                                                    widget.noteId,
                                                  ).notifier,
                                                )
                                                .save(routeId, idx);
                                          }
                                          // Update last known index as well
                                          ref
                                              .read(
                                                lastKnownPageIndexProvider(
                                                  widget.noteId,
                                                ).notifier,
                                              )
                                              .setValue(idx);
                                          unawaited(
                                            ref
                                                .read(
                                                  firebaseAnalyticsLoggerProvider,
                                                )
                                                .logLinkFollow(
                                                  entry: 'canvas_link',
                                                  sourceNoteId:
                                                      link.sourceNoteId,
                                                  targetNoteId:
                                                      link.targetNoteId,
                                                ),
                                          );
                                          context.pushNamed(
                                            AppRoutes.noteEditName,
                                            pathParameters: {
                                              'noteId': link.targetNoteId,
                                            },
                                          );
                                          break;
                                        case LinkAction.edit:
                                          // 링크 수정: 타깃 노트 선택(기존 생성 다이얼로그 재사용)
                                          final editRes =
                                              await LinkCreationDialog.show(
                                                context,
                                                sourceNoteId: link.sourceNoteId,
                                              );
                                          if (editRes == null) break;

                                          final prevLabel =
                                              (link.label?.trim().isNotEmpty ==
                                                  true)
                                              ? link.label!.trim()
                                              : '링크';

                                          try {
                                            final updatedLink = await ref
                                                .read(
                                                  linkCreationControllerProvider,
                                                )
                                                .updateTargetLink(
                                                  link,
                                                  targetNoteId:
                                                      editRes.targetNoteId,
                                                  targetTitle:
                                                      editRes.targetTitle,
                                                );
                                            if (!mounted) return;

                                            final newLabel =
                                                (updatedLink.label
                                                        ?.trim()
                                                        .isNotEmpty ==
                                                    true)
                                                ? updatedLink.label!.trim()
                                                : '링크';

                                            AppSnackBar.show(
                                              context,
                                              AppErrorSpec.success(
                                                '"$prevLabel" 링크를 "$newLabel"로 수정했습니다.',
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            final spec = AppErrorMapper.toSpec(
                                              e,
                                            );
                                            AppSnackBar.show(context, spec);
                                          }
                                          break;
                                        case LinkAction.delete:
                                          final delLabel =
                                              (link.label?.trim().isNotEmpty ==
                                                  true)
                                              ? link.label!.trim()
                                              : '링크';

                                          final shouldDelete =
                                              await showDesignConfirmDialog(
                                                context: context,
                                                title: '링크 삭제 확인',
                                                message:
                                                    '이 "$delLabel" 링크를 삭제할까요?\n이 작업은 되돌릴 수 없습니다.',
                                                confirmLabel: '삭제',
                                                destructive: true,
                                              );
                                          if (!shouldDelete) {
                                            AppSnackBar.show(
                                              context,
                                              AppErrorSpec.info('삭제를 취소했어요.'),
                                            );
                                            break;
                                          }
                                          try {
                                            debugPrint(
                                              '[LinkDelete/UI] delete linkId=${link.id} '
                                              'src=${link.sourceNoteId}/${link.sourcePageId} '
                                              'tgt=${link.targetNoteId}',
                                            );
                                            await ref
                                                .read(linkRepositoryProvider)
                                                .delete(link.id);
                                            if (!mounted) return;
                                            debugPrint(
                                              '[LinkDelete/UI] deleted linkId=${link.id}',
                                            );
                                            AppSnackBar.show(
                                              context,
                                              AppErrorSpec.success(
                                                '링크를 삭제했습니다.',
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            final spec = AppErrorMapper.toSpec(
                                              e,
                                            );
                                            AppSnackBar.show(context, spec);
                                          }
                                          break;
                                      }
                                    }
                                  },
                                  minLinkerRectangleSize: 16.0,
                                  currentLinkerFillColor: AppColors.linkerBlue
                                      .withAlpha(
                                        (255 * 0.15).round(),
                                      ),
                                  currentLinkerBorderColor:
                                      AppColors.linkerBlue,
                                  currentLinkerBorderWidth: 1.5,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
