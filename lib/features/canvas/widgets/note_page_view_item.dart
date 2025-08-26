import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scribble/scribble.dart';

import '../../notes/data/derived_note_providers.dart';
import '../constants/note_editor_constant.dart'; // NoteEditorConstants 정의 필요
import '../notifiers/custom_scribble_notifier.dart';
import '../providers/note_editor_provider.dart';
import '../providers/transformation_controller_provider.dart';
import 'canvas_background_widget.dart'; // CanvasBackgroundWidget 정의 필요
import 'linker_gesture_layer.dart';

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

  /// 링커 옵션 다이얼로그를 표시합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  /// [tappedRect]는 탭된 링커의 사각형 정보입니다.
  void _showLinkerOptions(BuildContext context, Rect tappedRect) {
    // 바텀 시트 표시 로직 (구현 생략)
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('링크 찾기'),
                onTap: () {
                  context.pop(); // 바텀 시트 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크 찾기 선택됨')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_link),
                title: const Text('링크 생성'),
                onTap: () {
                  context.pop(); // 바텀 시트 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크 생성 선택됨')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 노트/페이지가 유효하지 않으면 즉시 비표시 처리하여 삭제 직후 레이스를 방지
    final note = ref.watch(noteProvider(widget.noteId)).value;
    if (note == null || note.pages.length <= widget.pageIndex) {
      return const SizedBox.shrink();
    }

    final notifier = ref.watch(
      pageNotifierProvider(widget.noteId, widget.pageIndex),
    );

    // 화면 종료 과정에서 notifier가 비어있을 수 있으므로 null 체크 추가
    if (notifier.page == null) {
      return const SizedBox.shrink();
    }

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
            transformationController: ref.watch(
              transformationControllerProvider(widget.noteId),
            ),
            minScale: 0.3,
            maxScale: 3.0,
            constrained: false,
            // 패닝 활성화: 비-스타일러스 입력은 InteractiveViewer가 처리
            panEnabled: true,
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
                      final currentToolMode =
                          notifier.toolMode; // notifier에서 직접 toolMode 가져오기
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
                              toolMode: currentToolMode,
                              allowMouseForLinker:
                                  scribbleState.allowedPointersMode ==
                                  ScribblePointerMode.all,
                              onLinkerRectanglesChanged: (rects) {
                                setState(() {
                                  _currentLinkerRectangles = rects;
                                });
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
                              currentLinkerFillColor: Colors.pinkAccent
                                  .withAlpha((255 * 0.15).round()),
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
