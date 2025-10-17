import 'package:clustudy/features/notes/data/memory_notes_repository.dart';
import 'package:clustudy/features/notes/models/note_model.dart';
import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/shared/services/page_management_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageManagementService', () {
    late MemoryNotesRepository repository;
    late NoteModel testNote;

    setUp(() {
      repository = MemoryNotesRepository();

      // 테스트용 노트 생성 (3개 페이지)
      testNote = NoteModel(
        noteId: 'test-note-1',
        title: 'Test Note',
        pages: [
          NotePageModel(
            noteId: 'test-note-1',
            pageId: 'page-1',
            pageNumber: 1,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
          NotePageModel(
            noteId: 'test-note-1',
            pageId: 'page-2',
            pageNumber: 2,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
          NotePageModel(
            noteId: 'test-note-1',
            pageId: 'page-3',
            pageNumber: 3,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
        ],
        sourceType: NoteSourceType.blank,
      );
    });

    group('createBlankPage', () {
      test('should create a blank page successfully', () async {
        // Act
        final page = await PageManagementService.createBlankPage(
          'test-note-1',
          4,
        );

        // Assert
        expect(page, isNotNull);
        expect(page!.noteId, equals('test-note-1'));
        expect(page.pageNumber, equals(4));
        expect(page.backgroundType, equals(PageBackgroundType.blank));
        expect(page.jsonData, equals('{"lines":[]}'));
      });
    });

    group('addPage', () {
      test(
        'should add page to the end when no insertIndex is provided',
        () async {
          // Arrange
          await repository.upsert(testNote);
          final newPage = NotePageModel(
            noteId: 'test-note-1',
            pageId: 'page-4',
            pageNumber: 4,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          );

          // Act
          await PageManagementService.addPage(
            'test-note-1',
            newPage,
            repository,
          );

          // Assert
          final updatedNote = await repository.getNoteById('test-note-1');
          expect(updatedNote, isNotNull);
          expect(updatedNote!.pages.length, equals(4));
          expect(updatedNote.pages.last.pageId, equals('page-4'));
          expect(updatedNote.pages.last.pageNumber, equals(4));
        },
      );

      test('should add page at specified index', () async {
        // Arrange
        await repository.upsert(testNote);
        final newPage = NotePageModel(
          noteId: 'test-note-1',
          pageId: 'page-new',
          pageNumber: 2, // This will be remapped
          jsonData: '{"lines":[]}',
          backgroundType: PageBackgroundType.blank,
        );

        // Act
        await PageManagementService.addPage(
          'test-note-1',
          newPage,
          repository,
          insertIndex: 1, // Insert at position 1 (second position)
        );

        // Assert
        final updatedNote = await repository.getNoteById('test-note-1');
        expect(updatedNote, isNotNull);
        expect(updatedNote!.pages.length, equals(4));
        expect(updatedNote.pages[1].pageId, equals('page-new'));
        expect(updatedNote.pages[1].pageNumber, equals(2));

        // Check that page numbers are correctly remapped
        for (int i = 0; i < updatedNote.pages.length; i++) {
          expect(updatedNote.pages[i].pageNumber, equals(i + 1));
        }
      });

      test('should throw exception when note is not found', () async {
        // Arrange
        final newPage = NotePageModel(
          noteId: 'non-existent-note',
          pageId: 'page-new',
          pageNumber: 1,
          jsonData: '{"lines":[]}',
          backgroundType: PageBackgroundType.blank,
        );

        // Act & Assert
        expect(
          () => PageManagementService.addPage(
            'non-existent-note',
            newPage,
            repository,
          ),
          throwsException,
        );
      });
    });

    group('deletePage', () {
      test('should delete page successfully', () async {
        // Arrange
        await repository.upsert(testNote);

        // Act
        await PageManagementService.deletePage(
          'test-note-1',
          'page-2',
          repository,
        );

        // Assert
        final updatedNote = await repository.getNoteById('test-note-1');
        expect(updatedNote, isNotNull);
        expect(updatedNote!.pages.length, equals(2));
        expect(updatedNote.pages.any((p) => p.pageId == 'page-2'), isFalse);

        // Check that page numbers are correctly remapped
        expect(updatedNote.pages[0].pageNumber, equals(1));
        expect(updatedNote.pages[1].pageNumber, equals(2));
      });

      test('should throw exception when trying to delete last page', () async {
        // Arrange
        final singlePageNote = NoteModel(
          noteId: 'single-page-note',
          title: 'Single Page Note',
          pages: [
            NotePageModel(
              noteId: 'single-page-note',
              pageId: 'only-page',
              pageNumber: 1,
              jsonData: '{"lines":[]}',
              backgroundType: PageBackgroundType.blank,
            ),
          ],
          sourceType: NoteSourceType.blank,
        );
        await repository.upsert(singlePageNote);

        // Act & Assert
        expect(
          () => PageManagementService.deletePage(
            'single-page-note',
            'only-page',
            repository,
          ),
          throwsException,
        );
      });

      test('should throw exception when note is not found', () async {
        // Act & Assert
        expect(
          () => PageManagementService.deletePage(
            'non-existent-note',
            'page-1',
            repository,
          ),
          throwsException,
        );
      });
    });

    group('canDeletePage', () {
      test('should return false for last page', () {
        // Arrange
        final singlePageNote = NoteModel(
          noteId: 'single-page-note',
          title: 'Single Page Note',
          pages: [
            NotePageModel(
              noteId: 'single-page-note',
              pageId: 'only-page',
              pageNumber: 1,
              jsonData: '{"lines":[]}',
              backgroundType: PageBackgroundType.blank,
            ),
          ],
          sourceType: NoteSourceType.blank,
        );

        // Act
        final canDelete = PageManagementService.canDeletePage(
          singlePageNote,
          'only-page',
        );

        // Assert
        expect(canDelete, isFalse);
      });

      test('should return true for non-last page', () {
        // Act
        final canDelete = PageManagementService.canDeletePage(
          testNote,
          'page-2',
        );

        // Assert
        expect(canDelete, isTrue);
      });

      test('should return false for non-existent page', () {
        // Act
        final canDelete = PageManagementService.canDeletePage(
          testNote,
          'non-existent-page',
        );

        // Assert
        expect(canDelete, isFalse);
      });
    });

    group('getAvailablePdfPages', () {
      test('should return empty list for blank note', () async {
        // Arrange
        await repository.upsert(testNote);

        // Act
        final availablePages = await PageManagementService.getAvailablePdfPages(
          'test-note-1',
          repository,
        );

        // Assert
        expect(availablePages, isEmpty);
      });

      test('should return available PDF pages for PDF-based note', () async {
        // Arrange
        final pdfNote = NoteModel(
          noteId: 'pdf-note-1',
          title: 'PDF Note',
          pages: [
            NotePageModel(
              noteId: 'pdf-note-1',
              pageId: 'pdf-page-1',
              pageNumber: 1,
              jsonData: '{"lines":[]}',
              backgroundType: PageBackgroundType.pdf,
              backgroundPdfPageNumber: 1,
            ),
            NotePageModel(
              noteId: 'pdf-note-1',
              pageId: 'pdf-page-3',
              pageNumber: 2,
              jsonData: '{"lines":[]}',
              backgroundType: PageBackgroundType.pdf,
              backgroundPdfPageNumber: 3,
            ),
          ],
          sourceType: NoteSourceType.pdfBased,
          totalPdfPages: 5,
        );
        await repository.upsert(pdfNote);

        // Act
        final availablePages = await PageManagementService.getAvailablePdfPages(
          'pdf-note-1',
          repository,
        );

        // Assert
        expect(availablePages, equals([2, 4, 5])); // Pages 1 and 3 are used
      });

      test('should return empty list for non-existent note', () async {
        // Act
        final availablePages = await PageManagementService.getAvailablePdfPages(
          'non-existent-note',
          repository,
        );

        // Assert
        expect(availablePages, isEmpty);
      });
    });
  });
}
