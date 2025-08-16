import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/features/canvas/providers/note_editor_provider.dart';
import 'lib/features/notes/models/note_page_model.dart';
import 'lib/features/notes/widgets/draggable_page_thumbnail.dart';

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

          const SizedBox(height: 20),
          const Text('DraggablePageThumbnail 데모:'),
          const SizedBox(height: 10),

          // 드래그 앤 드롭 데모 영역
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text('드래그해서 순서를 바꿔보세요:'),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 드롭 타겟 1
                      DragTarget<NotePageModel>(
                        onAcceptWithDetails: (details) {
                          print('페이지 ${details.data.pageNumber}이 위치 1에 드롭됨');
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: candidateData.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: candidateData.isNotEmpty
                                ? const Center(child: Text('여기에 드롭'))
                                : DraggablePageThumbnail(
                                    page: NotePageModel(
                                      noteId: testNoteId,
                                      pageId: 'demo-page-1',
                                      pageNumber: 1,
                                      jsonData: '{"strokes":[]}',
                                      backgroundType: PageBackgroundType.blank,
                                    ),
                                    onTap: () => print('페이지 1 탭됨'),
                                    onDelete: () => print('페이지 1 삭제됨'),
                                    onDragStart: () => print('페이지 1 드래그 시작'),
                                    onDragEnd: () => print('페이지 1 드래그 종료'),
                                  ),
                          );
                        },
                      ),

                      // 드롭 타겟 2
                      DragTarget<NotePageModel>(
                        onAcceptWithDetails: (details) {
                          print('페이지 ${details.data.pageNumber}이 위치 2에 드롭됨');
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: candidateData.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: candidateData.isNotEmpty
                                ? const Center(child: Text('여기에 드롭'))
                                : DraggablePageThumbnail(
                                    page: NotePageModel(
                                      noteId: testNoteId,
                                      pageId: 'demo-page-2',
                                      pageNumber: 2,
                                      jsonData: '{"strokes":[]}',
                                      backgroundType: PageBackgroundType.pdf,
                                    ),
                                    onTap: () => print('페이지 2 탭됨'),
                                    onDelete: () => print('페이지 2 삭제됨'),
                                    onDragStart: () => print('페이지 2 드래그 시작'),
                                    onDragEnd: () => print('페이지 2 드래그 종료'),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
