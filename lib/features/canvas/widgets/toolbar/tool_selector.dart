// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_contest/features/canvas/models/tool_mode.dart';
import 'package:it_contest/features/canvas/providers/tool_settings_provider.dart';

/// 그리기 모드 툴바
///
/// 펜, 지우개, 하이라이터, 링커 모드를 선택할 수 있습니다.
class NoteEditorToolSelector extends ConsumerWidget {
  /// [NoteEditorToolSelector]의 생성자.
  ///
  const NoteEditorToolSelector({
    required this.noteId,
    super.key,
  });

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolSettings = ref.watch<ToolSettings>(toolSettingsNotifierProvider(noteId));

    return Row(
      children: [
        _buildToolButton(
          context,
          drawingMode: ToolMode.pen,
          tooltip: 'Pen',
          selected: toolSettings.toolMode == ToolMode.pen,
          onPressed: () =>
              ref.read(toolSettingsNotifierProvider(noteId).notifier).setToolMode(ToolMode.pen),
        ),
        _buildToolButton(
          context,
          drawingMode: ToolMode.eraser,
          tooltip: ToolMode.eraser.displayName,
          selected: toolSettings.toolMode == ToolMode.eraser,
          onPressed: () =>
              ref.read(toolSettingsNotifierProvider(noteId).notifier).setToolMode(ToolMode.eraser),
        ),
        _buildToolButton(
          context,
          drawingMode: ToolMode.highlighter,
          tooltip: ToolMode.highlighter.displayName,
          selected: toolSettings.toolMode == ToolMode.highlighter,
          onPressed: () => ref
              .read(toolSettingsNotifierProvider(noteId).notifier)
              .setToolMode(ToolMode.highlighter),
        ),
        _buildToolButton(
          context,
          drawingMode: ToolMode.linker,
          tooltip: ToolMode.linker.displayName,
          selected: toolSettings.toolMode == ToolMode.linker,
          onPressed: () =>
              ref.read(toolSettingsNotifierProvider(noteId).notifier).setToolMode(ToolMode.linker),
        ),
      ],
    );
  }

  /// 그리기 모드 버튼을 생성합니다.
  ///
  /// [context]는 빌드 컨텍스트입니다.
  /// [drawingMode]는 선택할 그리기 모드입니다.
  /// [tooltip]은 버튼에 표시할 텍스트입니다.
  Widget _buildToolButton(
    BuildContext context, {
    required ToolMode drawingMode,
    required String tooltip,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: selected ? Colors.blue : null,
          foregroundColor: selected ? Colors.white : null,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          textStyle: const TextStyle(fontSize: 12),
        ),
        onPressed: () {
          debugPrint('onPressed: $drawingMode');
          onPressed();
        },
        child: Text(tooltip),
      ),
    );
  }
}
