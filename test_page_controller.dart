import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/features/canvas/providers/note_editor_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: PageControllerTestScreen(),
      ),
    ),
  );
}

class PageControllerTestScreen extends ConsumerWidget {
  const PageControllerTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const testNoteId = 'test-note-id';

    // 새로 추가한 페이지 컨트롤러 상태 확인
    final pageControllerState = ref.watch(
      pageControllerNotifierProvider(testNoteId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('페이지 컨트롤러 테스트')),
      body: Column(
        children: [
          Text('로딩 상태: ${pageControllerState.isLoading}'),
          Text('오류 메시지: ${pageControllerState.errorMessage ?? "없음"}'),
          Text('현재 작업: ${pageControllerState.currentOperation ?? "없음"}'),
          Text('드래그 상태: ${pageControllerState.dragDropState.isDragging}'),
          Text('썸네일 캐시 수: ${pageControllerState.thumbnailCache.length}'),

          ElevatedButton(
            onPressed: () {
              ref
                  .read(pageControllerNotifierProvider(testNoteId).notifier)
                  .setLoading(true, operation: '테스트 로딩');
            },
            child: const Text('로딩 상태 테스트'),
          ),

          ElevatedButton(
            onPressed: () {
              ref
                  .read(pageControllerNotifierProvider(testNoteId).notifier)
                  .setError('테스트 오류 메시지');
            },
            child: const Text('오류 상태 테스트'),
          ),

          ElevatedButton(
            onPressed: () {
              ref
                  .read(pageControllerNotifierProvider(testNoteId).notifier)
                  .startDrag('test-page-id', 0, [0, 1, 2]);
            },
            child: const Text('드래그 시작 테스트'),
          ),
        ],
      ),
    );
  }
}
