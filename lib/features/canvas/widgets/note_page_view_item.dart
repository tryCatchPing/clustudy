import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';
import '../constants/note_editor_constant.dart'; // NoteEditorConstants 정의 필요
import '../notifiers/custom_scribble_notifier.dart'; // CustomScribbleNotifier 정의 필요
import 'canvas_background_widget.dart'; // CanvasBackgroundWidget 정의 필요
import 'linker_gesture_layer.dart';
// import 'rectangle_linker_painter.dart'; // RectangleLinkerPainter는 LinkerGestureLayer 내부에서 사용되므로 직접 import는 불필요할 수 있음

/// Note 편집 화면의 단일 페이지 뷰 아이템입니다.
/// [pageController], [totalPages], [notifier], [transformationController],
/// [simulatePressure]를 통해 페이지, 필기, 확대/축소, 필압 시뮬레이션 등을
/// 제어합니다.
class NotePageViewItem extends StatefulWidget {
  /// 페이지 뷰를 제어하는 컨트롤러.
  final PageController pageController;

  /// 전체 페이지 수.
  final int totalPages;

  /// 스케치 상태를 관리하는 Notifier.
  final CustomScribbleNotifier notifier;

  /// 확대/축소 상태를 관리하는 컨트롤러.
  final TransformationController transformationController;

  /// 필압 시뮬레이션 여부.
  final bool simulatePressure;

  /// [NotePageViewItem]의 생성자.
  ///
  /// [pageController]는 페이지 뷰를 제어하는 컨트롤러입니다.
  /// [totalPages]는 전체 페이지 수입니다.
  /// [notifier]는 스케치 상태를 관리하는 Notifier입니다.
  /// [transformationController]는 확대/축소 상태를 관리하는 컨트롤러입니다.
  /// [simulatePressure]는 필압 시뮬레이션 여부입니다.
  const NotePageViewItem({
    super.key,
    required this.pageController,
    required this.totalPages,
    required this.notifier,
    required this.transformationController,
    required this.simulatePressure,
  });

  @override
  State<NotePageViewItem> createState() => _NotePageViewItemState();
}

class _NotePageViewItemState extends State<NotePageViewItem> {
  Timer? _debounceTimer;
  double _lastScale = 1.0;
  List<Rect> _currentLinkerRectangles = []; // LinkerGestureLayer로부터 받은 링커 목록

  @override
  void initState() {
    super.initState();
    widget.transformationController.addListener(_onScaleChanged);
    _updateScale(); // 초기 스케일 설정
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onScaleChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 포인트 간격 조정을 위한 스케일 동기화.
  void _onScaleChanged() {
    // 스케일 변경 감지 및 디바운스 로직 (구현 생략)
    final currentScale =
        widget.transformationController.value.getMaxScaleOnAxis();
    if ((currentScale - _lastScale).abs() < 0.01) {
      return;
    }
    _lastScale = currentScale;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 8), _updateScale);
  }

  /// 스케일을 업데이트합니다.
  void _updateScale() {
    // 실제 스케일 동기화 로직 (구현 생략)
    widget.notifier.syncWithViewerScale(
      widget.transformationController.value.getMaxScaleOnAxis(),
    );
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
                  Navigator.pop(bc); // 바텀 시트 닫기
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('링크 찾기 선택됨')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_link),
                title: const Text('링크 생성'),
                onTap: () {
                  Navigator.pop(bc); // 바텀 시트 닫기
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
    final drawingWidth = widget.notifier.page!.drawingAreaWidth;
    final drawingHeight = widget.notifier.page!.drawingAreaHeight;
    final isLinkerMode = widget.notifier.toolMode.isLinker;

    // -- NotePageViewItem의 build 메서드 내부--
    if (!isLinkerMode) {
      debugPrint('렌더링: Scribble 위젯');
    }
    if (isLinkerMode) {
      debugPrint(
        '렌더링: LinkerGestureLayer (CustomPaint + GestureDetector)');
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
            transformationController: widget.transformationController,
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
                    valueListenable: widget.notifier,
                    builder: (context, scribbleState, child) {
                      final currentToolMode = widget.notifier.toolMode; // notifier에서 직접 toolMode 가져오기
                      return Stack(
                        children: [
                          // 배경 레이어
                          CanvasBackgroundWidget(
                            page: widget.notifier.page!,
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
                                notifier: widget.notifier,
                                drawPen: !currentToolMode.isLinker,
                                simulatePressure: widget.simulatePressure,
                              ),
                            ),
                          ),
                          // 패닝은 InteractiveViewer가 처리
                          // 링커 제스처 및 그리기 레이어 (항상 존재하며, 내부적으로 toolMode에 따라 드래그/탭 처리)
                          Positioned.fill(
                            child: LinkerGestureLayer(
                              toolMode: currentToolMode,
                              allowMouseForLinker: scribbleState.allowedPointersMode == ScribblePointerMode.all,
                              onLinkerRectanglesChanged: (rects) {
                                setState(() {
                                  _currentLinkerRectangles = rects;
                                });
                              },
                              onLinkerTapped: (tappedRect) {
                                _showLinkerOptions(context, tappedRect);
                              },
                              minLinkerRectangleSize: 16.0,
                              linkerFillColor: Colors.pinkAccent.withAlpha((255 * 0.3).round()),
                              linkerBorderColor: Colors.pinkAccent,
                              linkerBorderWidth: 2.0,
                              currentLinkerFillColor: Colors.pinkAccent.withAlpha((255 * 0.15).round()),
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
