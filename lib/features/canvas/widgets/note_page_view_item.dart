// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/scribble.dart';

import 'package:it_contest/features/canvas/constants/note_editor_constant.dart';
import 'package:it_contest/features/canvas/notifiers/custom_scribble_notifier.dart';
import 'package:it_contest/features/canvas/providers/note_editor_providers.dart';
import 'package:it_contest/features/canvas/widgets/canvas_background_widget.dart';
import 'package:it_contest/features/canvas/widgets/linker_gesture_layer.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/notes/data/derived_note_providers.dart';
import 'package:it_contest/services/link/link_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';
import 'package:it_contest/shared/routing/app_routes.dart';

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
  List<Rect> _currentLinkerRectangles = []; // LinkerGestureLayer로부터 받은 링커 목록
  List<LinkEntity> _currentLinks = []; // 실제 링크 데이터

  // 비-build 컨텍스트에서 현재 노트의 notifier 접근용
  CustomScribbleNotifier get _currentNotifier =>
      ref.read(pageNotifierProvider(widget.noteId, widget.pageIndex));

  // dispose에서 ref.read 사용을 피하기 위해 캐시
  late final TransformationController _tc;

  @override
  void initState() {
    super.initState();
    _tc = ref.read<TransformationController>(transformationControllerProvider(widget.noteId));
    _tc.addListener(_onScaleChanged);
    _updateScale(); // 초기 스케일 설정
    _loadLinkerRectangles(); // 기존 링커 로드
  }

  /// 저장된 링커 직사각형을 로드합니다.
  Future<void> _loadLinkerRectangles() async {
    try {
      final links = await LinkService.instance.getLinksForPage(
        sourceNoteId: int.parse(widget.noteId),
        sourcePageId: widget.pageIndex,
      );
      setState(() {
        _currentLinks = links; // 실제 링크 데이터 저장
        _currentLinkerRectangles = links.map((link) {
          final canvasWidth = _currentNotifier.page!.drawingAreaWidth;
          final canvasHeight = _currentNotifier.page!.drawingAreaHeight;
          return Rect.fromLTWH(
            link.x0 * canvasWidth,
            link.y0 * canvasHeight,
            (link.x1 - link.x0) * canvasWidth,
            (link.y1 - link.y0) * canvasHeight,
          );
        }).toList();
      });

    } catch (e, s) {
      // 링커 사각형 로드 실패 시 빈 상태 유지
    }
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

  /// 탭된 사각형에서 해당하는 링크 데이터를 찾습니다.
  LinkEntity? _findLinkByRect(Rect tappedRect) {
    for (int i = 0; i < _currentLinkerRectangles.length; i++) {
      final rect = _currentLinkerRectangles[i];
      if (rect == tappedRect && i < _currentLinks.length) {
        return _currentLinks[i];
      }
    }
    return null;
  }

    /// 기존 링커 탭 시 옵션 다이얼로그를 표시합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  /// [tappedRect]는 탭된 링커의 사각형 정보입니다.
  void _showLinkerOptions(BuildContext context, Rect tappedRect) {
    final link = _findLinkByRect(tappedRect);
    if (link == null) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('링크로 이동'),
                onTap: () {
                  context.pop(); // 바텀 시트 닫기
                  if (link.targetNoteId != null) {
                    context.pushNamed(
                      AppRoutes.noteEditName,
                      pathParameters: {
                        'noteId': link.targetNoteId.toString(),
                      },
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('링크 삭제'),
                onTap: () {
                  context.pop(); // 바텀 시트 닫기
                  _deleteLink(link);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 새로운 링커 생성 시 옵션 다이얼로그를 표시합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  /// [newRect]는 새로 생성된 링커의 사각형 정보입니다.
  void _showNewLinkerOptions(BuildContext context, Rect newRect) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false, // 바깥 영역 탭으로 닫기 방지
      enableDrag: false, // 드래그로 닫기 방지
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('링크 찾기'),
                onTap: () {
                  context.pop(); // 바텀 시트 닫기
                  _removeTemporaryRect(newRect);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크 찾기 선택됨')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_link),
                title: const Text('링크 생성'),
                onTap: () async {
                  context.pop(); // 바텀 시트 닫기
                  await _createLinkFromRect(newRect);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('취소'),
                onTap: () {
                  context.pop(); // 바텀 시트 닫기
                  _removeTemporaryRect(newRect);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 임시 사각형을 제거합니다.
  void _removeTemporaryRect(Rect rect) {
    setState(() {
      _currentLinkerRectangles.remove(rect);
    });
  }

  /// 사각형에서 링크를 생성합니다.
  Future<void> _createLinkFromRect(Rect rect) async {
    try {
      final currentNote = ref.read(noteProvider(widget.noteId)).value;
      if (currentNote == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('노트를 찾을 수 없습니다')),
          );
        }
        return;
      }

      final canvasWidth = _currentNotifier.page!.drawingAreaWidth;
      final canvasHeight = _currentNotifier.page!.drawingAreaHeight;

      final rectNorm = RectNorm(
        x0: rect.left / canvasWidth,
        y0: rect.top / canvasHeight,
        x1: rect.right / canvasWidth,
        y1: rect.bottom / canvasHeight,
      );

      await LinkService.instance.createLinkedNoteFromRegion(
        vaultId: currentNote.vaultId,
        sourceNoteId: int.parse(widget.noteId),
        sourcePageId: widget.pageIndex,
        region: rectNorm,
        label: '링크', // 기본 라벨
      );

      // 링크 생성 후 링커 목록 새로고침
      await _loadLinkerRectangles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크가 생성되었습니다')),
        );
      }
    } catch (e, s) {
      // 링크 생성 실패
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크 생성에 실패했습니다')),
        );
      }
    }
  }

  /// 링크를 삭제합니다.
  Future<void> _deleteLink(LinkEntity link) async {
    try {
      await LinkService.instance.deleteLink(link.id);
      // UI 업데이트: 해당 링크를 목록에서 제거
      setState(() {
        final index = _currentLinks.indexWhere((l) => l.id == link.id);
        if (index != -1) {
          _currentLinks.removeAt(index);
          _currentLinkerRectangles.removeAt(index);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크가 삭제되었습니다')),
        );
      }
    } catch (e, s) {
      // 링크 삭제 실패
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크 삭제에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 노트/페이지가 유효하지 않으면 즉시 비표시 처리하여 삭제 직후 레이스를 방지
    final note = ref.watch(noteProvider(widget.noteId)).value;
    if (note == null || note.pages.length <= widget.pageIndex) {
      return const SizedBox.shrink();
    }

    final notifier = ref.watch<CustomScribbleNotifier>(
      pageNotifierProvider(widget.noteId, widget.pageIndex),
    );
    final toolSettings = ref.watch(toolSettingsNotifierProvider(widget.noteId)); // Get tool settings

    final drawingWidth = notifier.page!.drawingAreaWidth;
    final drawingHeight = notifier.page!.drawingAreaHeight;
    final isLinkerMode = notifier.toolMode.isLinker;

    // -- NotePageViewItem의 build 메서드 내부--
    if (!isLinkerMode) {
      debugPrint('렌더링: Scribble 위젯');
    }
    if (isLinkerMode) {
      debugPrint('렌더링: LinkerGestureLayer (CustomPaint + GestureDetector)');
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black26,
        surfaceTintColor: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: InteractiveViewer(
            transformationController: ref.watch<TransformationController>(
              transformationControllerProvider(widget.noteId),
            ),
            minScale: 0.3,
            maxScale: 3.0,
            constrained: false,
            // 패닝 활성화: 비-스타일러스 입력은 InteractiveViewer가 처리
            panEnabled: !toolSettings.onlyPenMode, // Adjust panEnabled based on onlyPenMode
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
                      final currentToolMode = notifier.toolMode; // notifier에서 직접 toolMode 가져오기
                      return Stack(
                        children: [
                          // 배경 레이어
                          CanvasBackgroundWidget(
                            page: notifier.page!,
                            width: drawingWidth,
                            height: drawingHeight,
                          ),
                          // 링커 직사각형을 항상 그리는 레이어 추가
                          CustomPaint(
                            painter: _LinkerRectanglePainter(
                              _currentLinkerRectangles,
                              fillColor: Colors.pinkAccent.withAlpha(
                                (255 * 0.3).round(),
                              ),
                              borderColor: Colors.pinkAccent,
                              borderWidth: 2.0,
                            ),
                            child: Container(),
                          ),
                          // 필기 레이어 (링커 모드가 아닐 때만 활성화)
                          GestureDetector(
                            onTapUp: (details) {
                              // penOnly 모드이고 비-펜 입력인 경우 링커 다이얼로그 표시
                              if (scribbleState.allowedPointersMode == ScribblePointerMode.penOnly &&
                                  (details.kind == PointerDeviceKind.mouse ||
                                      details.kind == PointerDeviceKind.touch)) {
                                final tappedPosition = details.localPosition;
                                // 링커 사각형 체크
                                for (int i = 0; i < _currentLinkerRectangles.length; i++) {
                                  final rect = _currentLinkerRectangles[i];
                                  if (rect.contains(tappedPosition)) {
                                    _showLinkerOptions(context, rect);
                                    return;
                                  }
                                }
                              }
                              // 기존 로직: toolSettings.onlyPenMode 체크 (호환성 유지)
                              else if (toolSettings.onlyPenMode &&
                                  (details.kind == PointerDeviceKind.mouse ||
                                      details.kind == PointerDeviceKind.touch)) {
                                final tappedPosition = details.localPosition;
                                // 기존 로직: notifier.page!.links 체크 (호환성 유지)
                                for (final link in notifier.page!.links) {
                                  // Assuming link.boundingBox is in canvas coordinates
                                  if (link.boundingBox.contains(tappedPosition)) {
                                    context.pushNamed(
                                      AppRoutes.noteEditName,
                                      pathParameters: {
                                        'noteId': link.targetNoteId,
                                      },
                                    );
                                    return;
                                  }
                                }
                              }
                            },
                            child: IgnorePointer(
                              ignoring: currentToolMode.isLinker ||
                                  (toolSettings.onlyPenMode &&
                                      (scribbleState.allowedPointersMode == ScribblePointerMode.mouseOnly ||
                                      scribbleState.allowedPointersMode == ScribblePointerMode.mouseAndPen ||
                                      scribbleState.allowedPointersMode == ScribblePointerMode.all)),
                              child: ClipRect(
                                child: Scribble(
                                  notifier: notifier,
                                  drawPen: !currentToolMode.isLinker &&
                                      (!toolSettings.onlyPenMode ||
                                          scribbleState.allowedPointersMode == ScribblePointerMode.penOnly ||
                                          scribbleState.allowedPointersMode == ScribblePointerMode.mouseAndPen ||
                                          scribbleState.allowedPointersMode == ScribblePointerMode.all), // Adjust drawPen
                                  simulatePressure: ref.watch(
                                    simulatePressureProvider,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 패닝은 InteractiveViewer가 처리
                          // 링커 제스처 및 그리기 레이어 (항상 존재하며, 내부적으로 toolMode에 따라 드래그/탭 처리)
                          Positioned.fill(
                            child: LinkerGestureLayer(
                              toolMode: currentToolMode,
                              existingLinkerRectangles: _currentLinkerRectangles,
                              allowMouseForLinker:
                                  scribbleState.allowedPointersMode == ScribblePointerMode.all,
                              onLinkerRectanglesChanged: (rects) {
                                setState(() {
                                  _currentLinkerRectangles = rects;
                                });
                              },
                              onNewLinkerRectangleCreated: (newRect) async {
                                // 새로운 링커 생성 시 다이얼로그 표시
                                _showNewLinkerOptions(context, newRect);
                              },
                              onLinkerTapped: (tappedRect) {
                                _showLinkerOptions(context, tappedRect);
                              },
                              minLinkerRectangleSize: 16.0,
                              linkerFillColor: Colors.pinkAccent.withAlpha(
                                (255 * 0.3).round(),
                              ),
                              linkerBorderColor: Colors.pinkAccent,
                              linkerBorderWidth: 2.0,
                              currentLinkerFillColor: Colors.pinkAccent.withAlpha(
                                (255 * 0.15).round(),
                              ),
                              currentLinkerBorderColor: Colors.pinkAccent,
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
          ),
        ),
      ),
    );
  }
}

/// 링커 직사각형을 그리는 CustomPainter
class _LinkerRectanglePainter extends CustomPainter {
  /// [rectangles]는 그릴 사각형 목록입니다.
  final List<Rect> rectangles;

  /// 채우기 색상.
  final Color fillColor;

  /// 테두리 색상.
  final Color borderColor;

  /// 테두리 두께.
  final double borderWidth;

  /// [_LinkerRectanglePainter]의 생성자.
  ///
  /// [rectangles]는 그릴 사각형 목록입니다.
  /// [fillColor]는 채우기 색상입니다.
  /// [borderColor]는 테두리 색상입니다.
  /// [borderWidth]는 테두리 두께입니다.
  _LinkerRectanglePainter(
    this.rectangles, {
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    for (final rect in rectangles) {
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinkerRectanglePainter oldDelegate) {
    return oldDelegate.rectangles != rectangles ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
