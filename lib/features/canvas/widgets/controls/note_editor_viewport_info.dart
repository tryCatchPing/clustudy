import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/note_editor_provider.dart';
import '../../providers/transformation_controller_provider.dart';

/// 캔버스와 뷰포트 정보를 표시하는 위젯
class NoteEditorViewportInfo extends ConsumerWidget {
  /// [NoteEditorViewportInfo]의 생성자.
  ///
  /// [canvasWidth]는 캔버스의 너비입니다.
  /// [canvasHeight]는 캔버스의 높이입니다.
  const NoteEditorViewportInfo({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.noteId,
    super.key,
  });

  /// 캔버스의 너비.
  final double canvasWidth;

  /// 캔버스의 높이.
  final double canvasHeight;

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎨 캔버스 정보
            Column(
              children: [
                Text(
                  '${canvasWidth.toInt()}×${canvasHeight.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // 🔍 확대 정보 (ValueListenableBuilder로 실시간 업데이트)
            ValueListenableBuilder<Matrix4>(
              valueListenable: ref.watch(
                transformationControllerProvider(noteId),
              ),
              builder: (context, matrix, child) {
                final scale = matrix.getMaxScaleOnAxis();
                return Column(
                  children: [
                    Text(
                      '확대율',
                      style: TextStyle(fontSize: 10, color: Colors.green[600]),
                    ),
                    Text(
                      '${(scale * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10, color: Colors.green[600]),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
