import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/models/note_model.dart';
import '../../notifiers/custom_scribble_notifier.dart';
import '../controls/note_editor_page_navigation.dart';
import '../controls/note_editor_pointer_mode.dart';
import '../controls/note_editor_pressure_toggle.dart';
import '../controls/note_editor_viewport_info.dart';
import 'note_editor_drawing_toolbar.dart';

/// 노트 편집기 하단에 표시되는 툴바 위젯입니다.
///
/// 그리기 도구, 페이지 네비게이션, 필압 토글, 캔버스 정보, 포인터 모드 등을 포함합니다.
class NoteEditorToolbar extends ConsumerWidget {
  /// [NoteEditorToolbar]의 생성자.
  ///
  /// [note]는 현재 편집중인 노트 모델입니다.
  /// [notifier]는 스케치 상태를 관리하는 Notifier입니다.
  /// [canvasWidth]는 캔버스의 너비입니다.
  /// [canvasHeight]는 캔버스의 높이입니다.
  /// [transformationController]는 캔버스의 변환을 제어하는 컨트롤러입니다.
  /// [simulatePressure]는 필압 시뮬레이션 여부입니다.
  /// [onPressureToggleChanged]는 필압 토글 변경 시 호출되는 콜백 함수입니다.
  /// ✅ 페이지 네비게이션 파라미터들은 제거됨 (Provider에서 직접 읽음)
  const NoteEditorToolbar({
    required this.note,
    required this.notifier,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.transformationController,
    required this.simulatePressure,
    required this.onPressureToggleChanged,
    super.key,
  });

  /// 현재 편집중인 노트 모델
  final NoteModel note;

  /// 스케치 상태를 관리하는 Notifier.
  final CustomScribbleNotifier notifier;

  /// 캔버스의 너비.
  final double canvasWidth;

  /// 캔버스의 높이.
  final double canvasHeight;

  /// 캔버스의 변환을 제어하는 컨트롤러.
  final TransformationController transformationController;

  /// 필압 시뮬레이션 여부.
  final bool simulatePressure;

  /// 필압 토글 변경 시 호출되는 콜백 함수.
  final void Function(bool) onPressureToggleChanged;

  // ✅ 페이지 네비게이션 관련 파라미터들은 제거됨 - Provider에서 직접 읽음

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = note.pages.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // 상단: 기존 그리기 도구들
          NoteEditorDrawingToolbar(notifier: notifier),

          // 하단: 페이지 네비게이션, 필압 토글, 캔버스 정보, 포인터 모드
          SizedBox(
            width: double.infinity,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (totalPages > 1)
                  NoteEditorPageNavigation(
                    note: note,
                  ),
                // 필압 토글 컨트롤
                // TODO(xodnd): notifier 에서 처리하는 것이 좋을 것 같음.
                // TODO(xodnd): simplify 0 으로 수정 필요
                NoteEditorPressureToggle(
                  simulatePressure: simulatePressure,
                  onChanged: onPressureToggleChanged,
                ),
                // 📊 캔버스와 뷰포트 정보를 표시하는 위젯
                NoteEditorViewportInfo(
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                  transformationController: transformationController,
                ),
                NoteEditorPointerMode(notifier: notifier),
              ],
            ),
          ),
        ],
      ),
    );
  }
}