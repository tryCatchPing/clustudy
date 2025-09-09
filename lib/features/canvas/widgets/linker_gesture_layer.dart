import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/tool_mode.dart'; // ToolMode 정의 필요
import 'link_drag_overlay_painter.dart';

/// 링커 입력 포인터 정책
enum LinkerPointerMode {
  /// 모든 입력 허용(손가락/펜/마우스/트랙패드)
  all,

  /// 펜(스타일러스)만 드래그 허용. 탭은 손가락/펜 모두 허용.
  stylusOnly,
}

/// 링커 생성 및 상호작용 제스처를 처리하고 링커 목록을 관리하는 위젯입니다.
/// [toolMode]에 따라 드래그 제스처 활성화 여부를 결정하며, 탭 제스처는 항상 활성화됩니다.
class LinkerGestureLayer extends StatefulWidget {
  /// 현재 도구 모드.
  final ToolMode toolMode;

  /// 포인터 정책(전체/펜 전용)
  final LinkerPointerMode pointerMode;

  /// 드래그 완료 시 사각형을 전달합니다.
  final ValueChanged<Rect> onRectCompleted;

  /// 탭 좌표를 부모로 전달합니다(저장된 링크에 대한 히트 테스트는 부모/Provider에서 수행).
  final ValueChanged<Offset> onTapAt;

  /// 유효한 링커로 인식될 최소 크기.
  final double minLinkerRectangleSize;

  /// 현재 드래그 중인 링커의 채우기 색상.
  final Color currentLinkerFillColor;

  /// 현재 드래그 중인 링커의 테두리 색상.
  final Color currentLinkerBorderColor;

  /// 현재 드래그 중인 링커의 테두리 두께.
  final double currentLinkerBorderWidth;

  /// [LinkerGestureLayer]의 생성자.
  ///
  /// [toolMode]는 현재 도구 모드입니다.
  /// [pointerMode]는 입력 포인터 정책입니다.
  /// [onRectCompleted]는 드래그 완료 시 바운딩 박스를 전달합니다.
  /// [onTapAt]은 탭 좌표를 부모로 전달합니다.
  /// [minLinkerRectangleSize]는 유효한 링커로 인식될 최소 크기입니다.
  /// [currentLinkerFillColor], [currentLinkerBorderColor], [currentLinkerBorderWidth]는 현재 드래그 중인 링커의 스타일을 정의합니다.
  const LinkerGestureLayer({
    super.key,
    required this.toolMode,
    required this.pointerMode,
    required this.onRectCompleted,
    required this.onTapAt,
    this.minLinkerRectangleSize = 5.0,
    this.currentLinkerFillColor = Colors.green,
    this.currentLinkerBorderColor = Colors.green,
    this.currentLinkerBorderWidth = 2.0,
  });

  @override
  State<LinkerGestureLayer> createState() => _LinkerGestureLayerState();
}

class _LinkerGestureLayerState extends State<LinkerGestureLayer> {
  Offset? _currentDragStart;
  Offset? _currentDragEnd;

  /// 드래그 시작 시 호출
  void _onDragStart(DragStartDetails details) {
    setState(() {
      _currentDragStart = details.localPosition;
      _currentDragEnd = details.localPosition;
    });
  }

  /// 드래그 중 호출
  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentDragEnd = details.localPosition;
    });
  }

  /// 드래그 종료 시 호출
  void _onDragEnd(DragEndDetails details) {
    debugPrint(
      '[LinkerGestureLayer] onDragEnd. '
      'start=$_currentDragStart end=$_currentDragEnd',
    );
    setState(() {
      if (_currentDragStart != null && _currentDragEnd != null) {
        final rect = Rect.fromPoints(_currentDragStart!, _currentDragEnd!);
        debugPrint(
          '[LinkerGestureLayer] completed rect '
          '(${rect.left.toStringAsFixed(1)},'
          '${rect.top.toStringAsFixed(1)},'
          '${rect.width.toStringAsFixed(1)}x'
          '${rect.height.toStringAsFixed(1)})',
        );
        if (rect.width.abs() > widget.minLinkerRectangleSize &&
            rect.height.abs() > widget.minLinkerRectangleSize) {
          widget.onRectCompleted(rect);
        }
      }
      _currentDragStart = null;
      _currentDragEnd = null;
    });
  }

  /// 탭 업(손가락 떼는) 시 호출
  void _onTapUp(TapUpDetails details) {
    debugPrint(
      '[LinkerGestureLayer] onTapUp at '
      '${details.localPosition.dx.toStringAsFixed(1)},'
      '${details.localPosition.dy.toStringAsFixed(1)}',
    );
    widget.onTapAt(details.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    // toolMode가 linker일 때만 GestureDetector를 활성화
    if (widget.toolMode != ToolMode.linker) {
      return Container(); // 링커 모드가 아니면 아무것도 렌더링하지 않음
    }

    // 드래그 허용 포인터
    final dragDevices = <ui.PointerDeviceKind>{
      ui.PointerDeviceKind.stylus,
      ui.PointerDeviceKind.invertedStylus,
    };
    if (widget.pointerMode == LinkerPointerMode.all) {
      dragDevices
        ..add(ui.PointerDeviceKind.touch)
        ..add(ui.PointerDeviceKind.mouse)
        ..add(ui.PointerDeviceKind.trackpad);
    }

    // 탭 허용 포인터(두 모드 모두 손가락 탭으로 링크 확인 허용)
    final tapDevices = <ui.PointerDeviceKind>{
      ui.PointerDeviceKind.stylus,
      ui.PointerDeviceKind.invertedStylus,
      ui.PointerDeviceKind.touch,
    };
    if (widget.pointerMode == LinkerPointerMode.all) {
      tapDevices
        ..add(ui.PointerDeviceKind.mouse)
        ..add(ui.PointerDeviceKind.trackpad);
    }

    // 탭과 드래그를 서로 다른 supportedDevices로 분리 처리
    return Listener(
      onPointerDown: (event) {
        debugPrint(
          '[LinkerGestureLayer] raw PointerDown kind=${event.kind} '
          'pos=${event.position.dx.toStringAsFixed(1)},'
          '${event.position.dy.toStringAsFixed(1)}',
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        supportedDevices: tapDevices,
        onTapUp: _onTapUp,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          supportedDevices: dragDevices,
          onPanDown: (details) {
            debugPrint(
              '[LinkerGestureLayer] onPanDown at '
              '${details.localPosition.dx.toStringAsFixed(1)},'
              '${details.localPosition.dy.toStringAsFixed(1)}',
            );
          },
          onPanStart: _onDragStart,
          onPanUpdate: _onDragUpdate,
          onPanEnd: _onDragEnd,
          child: CustomPaint(
            size: Size.infinite, // CustomPaint가 전체 영역을 차지하도록 설정
            painter: LinkDragOverlayPainter(
              currentDragStart: _currentDragStart,
              currentDragEnd: _currentDragEnd,
              currentFillColor: widget.currentLinkerFillColor,
              currentBorderColor: widget.currentLinkerBorderColor,
              currentBorderWidth: widget.currentLinkerBorderWidth,
            ),
            child: Container(), // GestureDetector가 전체 영역을 감지하도록 함
          ),
        ),
      ),
    );
  }
}
