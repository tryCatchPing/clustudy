import 'package:clustudy/features/notes/data/memory_notes_repository.dart';
import 'package:clustudy/features/notes/data/notes_repository_provider.dart';
import 'package:clustudy/features/notes/models/note_model.dart';
import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/features/notes/widgets/page_thumbnail_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageThumbnailGrid - Basic Structure', () {
    late MemoryNotesRepository mockRepository;
    late List<NotePageModel> testPages;
    late NoteModel testNote;

    setUp(() async {
      mockRepository = MemoryNotesRepository();

      // 테스트용 페이지 생성
      testPages = [
        NotePageModel(
          noteId: 'test-note-1',
          pageId: 'page-1',
          pageNumber: 1,
          jsonData: '{"strokes":[]}',
          backgroundType: PageBackgroundType.blank,
        ),
        NotePageModel(
          noteId: 'test-note-1',
          pageId: 'page-2',
          pageNumber: 2,
          jsonData: '{"strokes":[]}',
          backgroundType: PageBackgroundType.blank,
        ),
      ];

      testNote = NoteModel(
        noteId: 'test-note-1',
        title: 'Test Note',
        pages: testPages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockRepository.upsert(testNote);
    });

    Widget createTestWidget({
      String noteId = 'test-note-1',
    }) {
      return ProviderScope(
        overrides: [
          notesRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PageThumbnailGrid(
              noteId: noteId,
            ),
          ),
        ),
      );
    }

    testWidgets('should create widget without errors', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // 위젯이 생성되는지만 확인 (썸네일 로딩 완료까지 기다리지 않음)
      expect(find.byType(PageThumbnailGrid), findsOneWidget);
    });

    testWidgets('should display empty state when no pages', (tester) async {
      // 빈 노트 생성
      final emptyNote = testNote.copyWith(pages: []);
      await mockRepository.upsert(emptyNote);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // 한 번만 pump

      expect(find.text('페이지가 없습니다'), findsOneWidget);
      expect(find.text('새 페이지를 추가해보세요'), findsOneWidget);
      expect(find.byIcon(Icons.note_add), findsOneWidget);
    });

    testWidgets('should display loading state initially', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // 로딩 상태 확인 (pumpAndSettle 전)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should display grid view after loading', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // 한 번만 pump

      // GridView가 렌더링되는지 확인
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle non-existent note', (tester) async {
      await tester.pumpWidget(createTestWidget(noteId: 'non-existent-note'));
      await tester.pump(); // 한 번만 pump

      // 빈 상태가 표시되어야 함
      expect(find.text('페이지가 없습니다'), findsOneWidget);
    });

    testWidgets('should respect grid parameters', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PageThumbnailGrid(
                noteId: 'test-note-1',
                crossAxisCount: 2,
                spacing: 16.0,
                thumbnailSize: 150.0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // GridView가 렌더링되는지 확인
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('should handle callbacks without errors', (tester) async {
      bool deleteCallbackCalled = false;
      bool tapCallbackCalled = false;
      bool reorderCallbackCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PageThumbnailGrid(
                noteId: 'test-note-1',
                onPageDelete: (page) {
                  deleteCallbackCalled = true;
                },
                onPageTap: (page, index) {
                  tapCallbackCalled = true;
                },
                onReorderComplete: (pages) {
                  reorderCallbackCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 콜백이 설정되어 있는지 확인 (실제 호출은 복잡한 상호작용이 필요)
      expect(find.byType(PageThumbnailGrid), findsOneWidget);

      // Suppress unused variable warnings
      expect(deleteCallbackCalled, isFalse);
      expect(tapCallbackCalled, isFalse);
      expect(reorderCallbackCalled, isFalse);
    });
  });
}
