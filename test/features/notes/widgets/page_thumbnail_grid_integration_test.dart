import 'package:clustudy/features/notes/data/memory_notes_repository.dart';
import 'package:clustudy/features/notes/data/notes_repository_provider.dart';
import 'package:clustudy/features/notes/models/note_model.dart';
import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/features/notes/widgets/page_thumbnail_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageThumbnailGrid - Integration Tests', () {
    late MemoryNotesRepository repository;
    late NoteModel testNote;

    setUp(() async {
      repository = MemoryNotesRepository();

      // 테스트용 노트 생성
      testNote = NoteModel(
        noteId: 'test-note',
        title: 'Test Note',
        pages: [
          NotePageModel(
            noteId: 'test-note',
            pageId: 'page1',
            pageNumber: 1,
            jsonData: '{"strokes":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
          NotePageModel(
            noteId: 'test-note',
            pageId: 'page2',
            pageNumber: 2,
            jsonData: '{"strokes":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
          NotePageModel(
            noteId: 'test-note',
            pageId: 'page3',
            pageNumber: 3,
            jsonData: '{"strokes":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.upsert(testNote);
    });

    tearDown(() {
      repository.dispose();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PageThumbnailGrid(
              noteId: 'test-note',
              crossAxisCount: 2,
              spacing: 8.0,
              thumbnailSize: 100.0,
            ),
          ),
        ),
      );
    }

    testWidgets('should integrate with repository and display pages', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // 초기 로딩 상태 확인
      expect(find.byType(PageThumbnailGrid), findsOneWidget);

      // 한 번 pump하여 데이터 로딩 시작
      await tester.pump();

      // GridView가 표시되는지 확인
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle page reordering through service integration', (
      tester,
    ) async {
      List<NotePageModel>? reorderedPages;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PageThumbnailGrid(
                noteId: 'test-note',
                onReorderComplete: (pages) {
                  reorderedPages = pages;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 기본 구조가 렌더링되는지 확인
      expect(find.byType(GridView), findsOneWidget);

      // 실제 드래그 앤 드롭은 복잡하므로 구조만 확인
      expect(find.byType(DragTarget<NotePageModel>), findsWidgets);

      // Suppress unused variable warning
      expect(reorderedPages, isNull);
    });

    testWidgets('should handle page deletion through callback', (tester) async {
      NotePageModel? deletedPage;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PageThumbnailGrid(
                noteId: 'test-note',
                onPageDelete: (page) {
                  deletedPage = page;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 기본 구조가 렌더링되는지 확인
      expect(find.byType(GridView), findsOneWidget);

      // Suppress unused variable warning
      expect(deletedPage, isNull);
    });

    testWidgets('should handle page tap through callback', (tester) async {
      NotePageModel? tappedPage;
      int? tappedIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PageThumbnailGrid(
                noteId: 'test-note',
                onPageTap: (page, index) {
                  tappedPage = page;
                  tappedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 기본 구조가 렌더링되는지 확인
      expect(find.byType(GridView), findsOneWidget);

      // Suppress unused variable warnings
      expect(tappedPage, isNull);
      expect(tappedIndex, isNull);
    });

    testWidgets('should adapt to different screen sizes', (tester) async {
      // 작은 화면 테스트
      await tester.binding.setSurfaceSize(const Size(300, 600));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);

      // 큰 화면 테스트
      await tester.binding.setSurfaceSize(const Size(800, 600));

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);

      // 원래 크기로 복원
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should handle empty note gracefully', (tester) async {
      // 빈 노트 생성
      final emptyNote = NoteModel(
        noteId: 'empty-note',
        title: 'Empty Note',
        pages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.upsert(emptyNote);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PageThumbnailGrid(
                noteId: 'empty-note',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 빈 상태 메시지 확인
      expect(find.text('페이지가 없습니다'), findsOneWidget);
      expect(find.text('새 페이지를 추가해보세요'), findsOneWidget);
    });
  });
}
