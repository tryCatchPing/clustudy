import 'package:flutter/material.dart';
import '../models/tool_mode.dart'; // ToolMode 정의 필요
import 'rectangle_linker_painter.dart';
import 'dart:ui' as ui;

/// 링커 생성 및 상호작용 제스처를 처리하고 링커 목록을 관리하는 위젯입니다.
/// [toolMode]에 따라 드래그 제스처 활성화 여부를 결정하며, 탭 제스처는 항상 활성화됩니다.
class LinkerGestureLayer extends StatefulWidget {
  /// 현재 도구 모드.
  final ToolMode toolMode;

  /// 링커 목록이 변경될 때 호출되는 콜백 함수.
  final ValueChanged<List<Rect>> onLinkerRectanglesChanged;

  /// 링커가 탭될 때 호출되는 콜백 함수.
  final ValueChanged<Rect> onLinkerTapped;

  /// 유효한 링커로 인식될 최소 크기.
  final double minLinkerRectangleSize;

  /// 기존 링커의 채우기 색상.
  final Color linkerFillColor;

  /// 기존 링커의 테두리 색상.
  final Color linkerBorderColor;

  /// 기존 링커의 테두리 두께.
  final double linkerBorderWidth;

  /// 현재 드래그 중인 링커의 채우기 색상.
  final Color currentLinkerFillColor;

  /// 현재 드래그 중인 링커의 테두리 색상.
  final Color currentLinkerBorderColor;

  /// 현재 드래그 중인 링커의 테두리 두께.
  final double currentLinkerBorderWidth;

  /// all 모드에서 마우스로도 링커 드래그를 허용할지 여부
  final bool allowMouseForLinker;

  /// [LinkerGestureLayer]의 생성자.
  ///
  /// [toolMode]는 현재 도구 모드입니다.
  /// [onLinkerRectanglesChanged]는 링커 목록이 변경될 때 호출됩니다.
  /// [onLinkerTapped]는 링커가 탭될 때 호출됩니다.
  /// [minLinkerRectangleSize]는 유효한 링커로 인식될 최소 크기입니다.
  /// [linkerFillColor], [linkerBorderColor], [linkerBorderWidth]는 기존 링커의 스타일을 정의합니다.
  /// [currentLinkerFillColor], [currentLinkerBorderColor], [currentLinkerBorderWidth]는 현재 드래그 중인 링커의 스타일을 정의합니다.
  const LinkerGestureLayer({
    super.key,
    required this.toolMode,
    required this.onLinkerRectanglesChanged,
    required this.onLinkerTapped,
    this.minLinkerRectangleSize = 5.0,
    this.linkerFillColor = Colors.pinkAccent,
    this.linkerBorderColor = Colors.pinkAccent,
    this.linkerBorderWidth = 2.0,
    this.currentLinkerFillColor = Colors.green,
    this.currentLinkerBorderColor = Colors.green,
    this.currentLinkerBorderWidth = 2.0,
    this.allowMouseForLinker = false,
  });

  @override
  State<LinkerGestureLayer> createState() => _LinkerGestureLayerState();
}

class _LinkerGestureLayerState extends State<LinkerGestureLayer> {
  Offset? _currentDragStart;
  Offset? _currentDragEnd;
  final List<Rect> _linkerRectangles = []; // 내부적으로 링커 목록 관리

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
    setState(() {
      if (_currentDragStart != null && _currentDragEnd != null) {
        final rect = Rect.fromPoints(_currentDragStart!, _currentDragEnd!);
        if (rect.width.abs() > widget.minLinkerRectangleSize &&
            rect.height.abs() > widget.minLinkerRectangleSize) {
          _linkerRectangles.add(rect);
          widget.onLinkerRectanglesChanged(_linkerRectangles); // 콜백 호출
        }
      }
      _currentDragStart = null;
      _currentDragEnd = null;
    });
  }

  /// 탭 업(손가락 떼는) 시 호출
  void _onTapUp(TapUpDetails details) {
    final tapPosition = details.localPosition;
    for (final rect in _linkerRectangles) {
      if (rect.contains(tapPosition)) {
        widget.onLinkerTapped(rect); // 탭된 링커의 위치를 전달
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // toolMode가 linker일 때만 GestureDetector를 활성화
    if (widget.toolMode != ToolMode.linker) {
      return Container(); // 링커 모드가 아니면 아무것도 렌더링하지 않음
    }

    final devices = <ui.PointerDeviceKind>{
      ui.PointerDeviceKind.stylus,
      ui.PointerDeviceKind.invertedStylus,
    };
    if (widget.allowMouseForLinker) {
      devices.add(ui.PointerDeviceKind.mouse);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      supportedDevices: devices,
      onPanDown: (_) {}, // 제스처 선점 도움
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onTapUp: _onTapUp,
      child: CustomPaint(
        size: Size.infinite, // CustomPaint가 전체 영역을 차지하도록 설정
        painter: RectangleLinkerPainter(
          currentDragStart: _currentDragStart,
          currentDragEnd: _currentDragEnd,
          existingRectangles: _linkerRectangles,
          fillColor: widget.linkerFillColor,
          borderColor: widget.linkerBorderColor,
          borderWidth: widget.linkerBorderWidth,
          currentFillColor: widget.currentLinkerFillColor,
          currentBorderColor: widget.currentLinkerBorderColor,
          currentBorderWidth: widget.currentLinkerBorderWidth,
        ),
        child: Container(), // GestureDetector가 전체 영역을 감지하도록 함
      ),
    );
  }
}
