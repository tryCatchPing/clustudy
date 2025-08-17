import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_page_model.dart';
import 'page_thumbnail_grid.dart';

/// PageThumbnailGrid 사용 예제를 보여주는 데모 화면입니다.
class PageThumbnailGridDemo extends ConsumerWidget {
  /// 데모에 사용할 노트 ID.
  final String noteId;

  /// [PageThumbnailGridDemo]의 생성자.
  const PageThumbnailGridDemo({
    super.key,
    required this.noteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('페이지 썸네일 그리드 데모'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명 텍스트
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '페이지 썸네일 그리드',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 드래그 앤 드롭으로 페이지 순서 변경\n'
                      '• 썸네일 탭으로 페이지 선택\n'
                      '• 삭제 버튼으로 페이지 제거\n'
                      '• 반응형 그리드 레이아웃',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 그리드 제목
            Text(
              '페이지 목록',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // 페이지 썸네일 그리드
            Expanded(
              child: PageThumbnailGrid(
                noteId: noteId,
                crossAxisCount: 3,
                spacing: 12.0,
                thumbnailSize: 120.0,
                onPageTap: (page, index) {
                  _showPageTapDialog(context, page, index);
                },
                onPageDelete: (page) {
                  _showDeleteConfirmDialog(context, page);
                },
                onReorderComplete: (reorderedPages) {
                  _showReorderCompleteSnackBar(context, reorderedPages);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPageDialog(context);
        },
        tooltip: '페이지 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 페이지 탭 다이얼로그를 표시합니다.
  void _showPageTapDialog(
    BuildContext context,
    NotePageModel page,
    int index,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 선택됨'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('페이지 ID: ${page.pageId}'),
            Text('페이지 번호: ${page.pageNumber}'),
            Text('인덱스: $index'),
            Text('배경 타입: ${page.backgroundType.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 페이지 삭제 확인 다이얼로그를 표시합니다.
  void _showDeleteConfirmDialog(
    BuildContext context,
    NotePageModel page,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 삭제'),
        content: Text('페이지 ${page.pageNumber}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 실제 삭제 로직은 여기에 구현
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('페이지 ${page.pageNumber} 삭제됨 (데모)'),
                ),
              );
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 순서 변경 완료 스낵바를 표시합니다.
  void _showReorderCompleteSnackBar(
    BuildContext context,
    List<NotePageModel> reorderedPages,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('페이지 순서가 변경되었습니다 (${reorderedPages.length}개 페이지)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 페이지 추가 다이얼로그를 표시합니다.
  void _showAddPageDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('페이지 추가'),
        content: const Text('새 페이지를 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 실제 페이지 추가 로직은 여기에 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('새 페이지 추가됨 (데모)'),
                ),
              );
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
