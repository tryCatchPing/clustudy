import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import '../../notes/models/note_page_model.dart' as page_model;
import '../mixins/auto_save_mixin.dart';
import '../mixins/tool_management_mixin.dart';
import '../models/tool_mode.dart';
import '../providers/note_editor_provider.dart';

/// 캔버스에서 스케치 및 도구 관리를 담당하는 Notifier.
/// [ScribbleNotifier], [AutoSaveMixin], [ToolManagementMixin]을 조합하여 사용합니다.
class CustomScribbleNotifier extends ScribbleNotifier
    with AutoSaveMixin, ToolManagementMixin {
  /// [CustomScribbleNotifier]의 생성자.
  ///
  /// [sketch]는 초기 스케치 데이터입니다.
  /// [allowedPointersMode]는 허용되는 포인터 모드입니다.
  /// [maxHistoryLength]는 되돌리기/다시 실행 기록의 최대 길이입니다.
  /// [widths]는 사용 가능한 선 굵기 목록입니다.
  /// [simplifier]는 스케치 단순화에 사용되는 객체입니다.
  /// [simplificationTolerance]는 스케치 단순화 허용 오차입니다.
  /// [toolMode]는 현재 선택된 도구 모드입니다.
  /// [page]는 현재 노트 페이지 모델입니다.
  CustomScribbleNotifier({
    super.sketch,
    super.allowedPointersMode,
    super.maxHistoryLength,
    super.widths = const [1, 3, 5, 7],
    super.simplifier,
    super.simplificationTolerance,
    required Ref ref,
    required this.toolMode,
    this.page,
  }) : ref = ref,
       super(
         pressureCurve: ref.read(simulatePressureProvider)
             ? const _DefaultPressureCurve()
             : const _ConstantPressureCurve(),
       );

  final Ref ref;

  /// 현재 선택된 도구 모드.
  @override
  ToolMode toolMode;

  /// 현재 노트 페이지 모델.
  @override
  final page_model.NotePageModel? page;

  /// 뷰어 스케일과 동기화하여 획 굵기 일관성을 보장합니다.
  /// [viewerScale]은 현재 뷰어의 스케일 값입니다.
  void syncWithViewerScale(double viewerScale) {
    // scaleFactor를 1.0으로 고정해서 획 굵기가 항상 동일하게 저장되도록 함
    // InteractiveViewer의 Transform이 시각적 확대/축소 담당
    setScaleFactor(1.0);

    // 포인트 간격은 별도로 조정 (필요시 _customScaleFactor 변수 사용)
    _currentViewerScale = viewerScale;
  }

  double _currentViewerScale = 1.0;

  /// 포인터 다운 이벤트를 처리합니다.
  /// 링커 모드일 때는 아무것도 하지 않습니다.
  @override
  void onPointerDown(PointerDownEvent event) {
    if (toolMode.isLinker) return; // 링커 모드일 때는 아무것도 하지 않음
    debugPrint(
      'CustomScribbleNotifier: onPointerDown called. '
      'ToolMode: $toolMode, PointerKind: ${event.kind}, '
      'SupportedPointers: ${value.supportedPointerKinds}',
    ); // DEBUG
    if (!value.supportedPointerKinds.contains(event.kind)) {
      return;
    }
    var s = value;

    // 기존 로직과 동일하지만 선 굵기는 scaleFactor 적용 안함
    if (value.activePointerIds.isNotEmpty) {
      s = value.map(
        drawing: (s) =>
            (s.activeLine != null && s.activeLine!.points.length > 2)
            ? _finishLineForState(s)
            : s.copyWith(activeLine: null),
        erasing: (s) => s,
      );
    } else if (value is Drawing) {
      s = (value as Drawing).copyWith(
        pointerPosition: _getPointFromEvent(event),
        activeLine: SketchLine(
          points: [_getPointFromEvent(event)],
          color: (value as Drawing).selectedColor,
          // 🎯 핵심 수정: scaleFactor를 1.0으로 고정했으므로 원본 굵기 사용
          width: value.selectedWidth,
        ),
      );
    }
    temporaryValue = s.copyWith(
      activePointerIds: [...value.activePointerIds, event.pointer],
    );
  }

  /// 포인터 업데이트 이벤트를 처리합니다.
  /// 링커 모드일 때는 아무것도 하지 않습니다.
  @override
  void onPointerUpdate(PointerMoveEvent event) {
    if (toolMode.isLinker) return; // 링커 모드일 때는 아무것도 하지 않음
    debugPrint(
      'CustomScribbleNotifier: onPointerUpdate called. '
      'ToolMode: $toolMode, PointerKind: ${event.kind}',
    ); // DEBUG
    if (!value.supportedPointerKinds.contains(event.kind)) {
      return;
    }
    if (!value.active) {
      temporaryValue = value.copyWith(pointerPosition: null);
      return;
    }
    if (value is Drawing) {
      temporaryValue = _addPointWithCustomSpacing(event, value).copyWith(
        pointerPosition: _getPointFromEvent(event),
      );
    } else if (value is Erasing) {
      final erasedState = _erasePoint(event);
      if (erasedState != null) {
        value = erasedState.copyWith(
          pointerPosition: _getPointFromEvent(event),
        );
      } else {
        temporaryValue = value.copyWith(
          pointerPosition: _getPointFromEvent(event),
        );
      }
    }
  }

  // 🎯 포인트 간격 조정 (scaleFactor 적용)
  ScribbleState _addPointWithCustomSpacing(
    PointerEvent event,
    ScribbleState s,
  ) {
    if (s is Erasing || !s.active) {
      return s;
    }
    if (s is Drawing && s.activeLine == null) {
      return s;
    }

    final currentLine = (s as Drawing).activeLine!;
    final distanceToLast = currentLine.points.isEmpty
        ? double.infinity
        : (_pointToOffset(currentLine.points.last) - event.localPosition)
              .distance;

    // 🔧 포인트 간격에는 실제 뷰어 스케일 적용 (필기감 개선)
    final threshold = kPrecisePointerPanSlop / _currentViewerScale;

    if (distanceToLast <= threshold) {
      return s;
    }

    return s.copyWith(
      activeLine: currentLine.copyWith(
        points: [
          ...currentLine.points,
          _getPointFromEvent(event),
        ],
      ),
    );
  }

  // 🔧 지우개도 원본 굵기 사용
  ScribbleState? _erasePoint(PointerEvent event) {
    final eraserWidth = value.selectedWidth;
    final filteredLines = value.sketch.lines
        .where(
          (l) => l.points.every(
            (p) =>
                (event.localPosition - _pointToOffset(p)).distance >
                l.width + eraserWidth, // 원본 굵기 기준 지우기
          ),
        )
        .toList();

    if (filteredLines.length == value.sketch.lines.length) {
      return null;
    }

    return value.copyWith(
      sketch: value.sketch.copyWith(lines: filteredLines),
    );
  }

  // 🔧 Point를 Offset으로 변환하는 헬퍼 메서드
  Offset _pointToOffset(Point point) => Offset(point.x, point.y);

  // ========================================================================
  // 🚨 COPIED PRIVATE METHODS FROM SCRIBBLE PACKAGE
  // ========================================================================
  // Source: scribble package (https://pub.dev/packages/scribble)
  // Original file: lib/src/scribble_notifier.dart
  //
  // These private methods were copied from the original ScribbleNotifier
  // because we need to override pointer handling behavior to prevent
  // scaleFactor from affecting stroke width.
  //
  // ⚠️  MAINTENANCE WARNING:
  // - These methods must be manually updated when the scribble package
  //   is updated
  // - Check for changes in the original implementation
  // - Current scribble package version: Check pubspec.yaml for version
  // ========================================================================

  /// Extracts Point from PointerEvent with pressure information
  ///
  /// 📋 Original: ScribbleNotifier._getPointFromEvent()
  /// 🔧 Modification: None - copied as-is from original implementation
  Point _getPointFromEvent(PointerEvent event) {
    final p = event.pressureMin == event.pressureMax
        ? 0.5
        : (event.pressure - event.pressureMin) /
              (event.pressureMax - event.pressureMin);
    return Point(
      event.localPosition.dx,
      event.localPosition.dy,
      pressure: pressureCurve.transform(p),
    );
  }

  /// Finalizes the current active line and adds it to the sketch
  ///
  /// 📋 Original: ScribbleNotifier._finishLineForState()
  /// 🔧 Modification: None - copied as-is from original implementation
  ScribbleState _finishLineForState(ScribbleState s) {
    if (s case Drawing(activeLine: final activeLine?)) {
      return s.copyWith(
        activeLine: null,
        sketch: s.sketch.copyWith(
          lines: [
            ...s.sketch.lines,
            simplifier.simplify(
              activeLine,
              pixelTolerance: s.simplificationTolerance,
            ),
          ],
        ),
      );
    }
    return s;
  }
}

/// 기본 필압 곡선 (입력 t를 그대로 반환하여 필압 반영)
class _DefaultPressureCurve extends Curve {
  /// 기본 필압 곡선 생성자
  const _DefaultPressureCurve();

  @override
  double transform(double t) => t; // 입력 t를 그대로 반환하여 필압 반영
}

/// 상수 필압 곡선 (항상 0.5를 반환)
class _ConstantPressureCurve extends Curve {
  /// 상수 필압 곡선 생성자
  const _ConstantPressureCurve();

  @override
  double transform(double t) => 0.5;
}
