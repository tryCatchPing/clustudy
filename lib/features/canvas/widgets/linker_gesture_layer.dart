import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/tool_mode.dart';
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

  /// 스타일러스 드래그/탭이 진행 중인지 외부에 알립니다.
  final ValueChanged<bool>? onStylusInteractionChanged;

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
    this.onStylusInteractionChanged,
  });

  @override
  State<LinkerGestureLayer> createState() => _LinkerGestureLayerState();
}

class _LinkerGestureLayerState extends State<LinkerGestureLayer> {
  static const _tapMaxDistance = 4.0;
  static const _tapMaxDuration = Duration(milliseconds: 200);

  final Set<int> _pointersDown = <int>{};
  PointerDeviceKind? _activeKind;
  int? _activePointer;
  Offset? _pointerDownPosition;
  Offset? _currentPosition;
  late final Stopwatch _gestureStopwatch;
  bool _stylusActive = false;

  @override
  void initState() {
    super.initState();
    _gestureStopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _gestureStopwatch.stop();
    super.dispose();
  }

  bool get _isActive => _activePointer != null;

  bool get _isLinkerMode => widget.toolMode == ToolMode.linker;

  bool get _allowTouchDrag => widget.pointerMode == LinkerPointerMode.all;

  // 스타일러스 전용 모드에서도 손가락 탭을 허용해야 링크 액션을 열 수 있다.
  bool get _allowTouchTap => true;

  bool _isStylusKind(PointerDeviceKind? kind) {
    return kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  void _notifyStylusInteraction(bool active, {bool defer = false}) {
    if (_stylusActive == active) {
      return;
    }
    _stylusActive = active;
    final callback = widget.onStylusInteractionChanged;
    if (callback == null) {
      return;
    }
    if (defer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        callback(active);
      });
      return;
    }
    callback(active);
  }

  bool _supportsPointer(PointerDownEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.touch:
        return _allowTouchDrag || _allowTouchTap;
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.trackpad:
        return widget.pointerMode == LinkerPointerMode.all;
      default:
        return false;
    }
  }

  bool _shouldStartDrag(PointerEvent event) {
    switch (event.kind) {
      case PointerDeviceKind.stylus:
      case PointerDeviceKind.invertedStylus:
        return true;
      case PointerDeviceKind.touch:
        return _allowTouchDrag;
      case PointerDeviceKind.mouse:
      case PointerDeviceKind.trackpad:
        return widget.pointerMode == LinkerPointerMode.all;
      default:
        return false;
    }
  }

  void _resetGesture() {
    _notifyStylusInteraction(false, defer: true);
    _activePointer = null;
    _activeKind = null;
    _pointerDownPosition = null;
    _currentPosition = null;
    _gestureStopwatch
      ..reset()
      ..stop();
  }

  void _startGesture(PointerDownEvent event) {
    _activePointer = event.pointer;
    _activeKind = event.kind;
    _pointerDownPosition = event.localPosition;
    _currentPosition = event.localPosition;
    _gestureStopwatch
      ..reset()
      ..start();
    setState(() {});
  }

  bool _isTapGesture(Offset upPosition) {
    if (_pointerDownPosition == null) {
      return false;
    }
    final distance = (upPosition - _pointerDownPosition!).distance;
    final elapsed = _gestureStopwatch.elapsed;
    return distance <= _tapMaxDistance && elapsed <= _tapMaxDuration;
  }

  bool _isRectLargeEnough() {
    if (_pointerDownPosition == null || _currentPosition == null) {
      return false;
    }
    final width = (_currentPosition!.dx - _pointerDownPosition!.dx).abs();
    final height = (_currentPosition!.dy - _pointerDownPosition!.dy).abs();
    return width > widget.minLinkerRectangleSize &&
        height > widget.minLinkerRectangleSize;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!_isLinkerMode) {
      return;
    }
    if (!_supportsPointer(event)) {
      return;
    }
    _pointersDown.add(event.pointer);
    if (_pointersDown.length >= 2 && _isActive) {
      _resetGesture();
      setState(() {});
      return;
    }
    if (_isActive) {
      // 이미 다른 포인터를 추적 중이면 무시해서 InteractiveViewer가 멀티터치를 잡도록 함.
      return;
    }
    if (_isStylusKind(event.kind)) {
      _notifyStylusInteraction(true);
    }
    _startGesture(event);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isActive || event.pointer != _activePointer) {
      return;
    }
    // Stylus 전용 모드에서 터치 포인터는 드래그를 만들지 않는다.
    if (!_shouldStartDrag(event)) {
      // 드래그가 허용되지 않은 포인터라도 움직임은 기록해 탭 판정(거리)에 사용한다.
      _currentPosition = event.localPosition;
      return;
    }
    _currentPosition = event.localPosition;
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent event) {
    _pointersDown.remove(event.pointer);
    if (!_isActive || event.pointer != _activePointer) {
      return;
    }
    final upPosition = event.localPosition;
    final isTap = _isTapGesture(upPosition);
    final canPerformDrag = _isStylusKind(_activeKind) || _allowTouchDrag;
    final isStylusTap = isTap && _isStylusKind(_activeKind);
    final isDrag = canPerformDrag && !isTap && _isRectLargeEnough();

    if (isTap && (_allowTouchTap || isStylusTap)) {
      widget.onTapAt(upPosition);
    } else if (isDrag) {
      final rect = Rect.fromPoints(_pointerDownPosition!, upPosition);
      widget.onRectCompleted(rect);
    }
    _resetGesture();
    setState(() {});
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointersDown.remove(event.pointer);
    if (!_isActive || event.pointer != _activePointer) {
      return;
    }
    _resetGesture();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLinkerMode) {
      return const SizedBox.shrink();
    }

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      behavior: HitTestBehavior.translucent,
      child: CustomPaint(
        size: Size.infinite,
        painter: LinkDragOverlayPainter(
          currentDragStart: _pointerDownPosition,
          currentDragEnd: _currentPosition,
          currentFillColor: widget.currentLinkerFillColor,
          currentBorderColor: widget.currentLinkerBorderColor,
          currentBorderWidth: widget.currentLinkerBorderWidth,
        ),
      ),
    );
  }
}
