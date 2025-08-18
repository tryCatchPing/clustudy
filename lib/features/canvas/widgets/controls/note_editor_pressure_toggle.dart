import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_contest/features/canvas/providers/note_editor_provider.dart';

/// 필압 시뮬레이션 토글 위젯입니다.
///
/// 사용자가 필압 시뮬레이션 기능을 켜고 끌 수 있도록 합니다.
class NoteEditorPressureToggle extends ConsumerWidget {
  /// [NoteEditorPressureToggle]의 생성자.
  ///
  const NoteEditorPressureToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulatePressure = ref.watch(simulatePressureProvider);

    return Transform.scale(
      scale: 0.75, // 전체 크기를 75%로 축소 (약 2/3)
      child: Switch.adaptive(
        value: simulatePressure,
        onChanged: (value) => ref.read(simulatePressureProvider.notifier).setValue(value),
        activeColor: Colors.orange[600],
        inactiveTrackColor: Colors.green[200],
      ),
    );
  }
}
