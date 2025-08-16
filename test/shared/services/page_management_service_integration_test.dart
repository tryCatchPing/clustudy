import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/notes/data/memory_notes_repository.dart';
import '../../../lib/features/notes/models/note_model.dart';
import '../../../lib/features/notes/models/note_page_model.dart';
import '../../../lib/shared/services/page_management_service.dart';

void main() {
  group('PageManagementService Integration Tests', () {
    late MemoryNotesRepository repository;

    setUp(() {
      repository = MemoryNotesRepository();
    });

    test('should handle complete page management workflow', () async {
      // 1. 초기 노트 생성
      final initialNote = NoteModel(
        noteId: 'workflow-test',
        title: 'Workflow Test Note',
        pages: [
          NotePageModel(
            noteId: 'workflow-test',
            pageId: 'initial-page',
            pageNumber: 1,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
        ],
        sourceType: NoteSourceType.blank,
      );
      await repository.upsert(initialNote);

      // 2. 페이지 추가 (마지막에)
      final newPage1 = await PageManagementService.createBlankPage(
        'workflow-test',
        2,
      );
      expect(newPage1, isNotNull);

      await PageManagementService.addPage(
        'workflow-test',
        newPage1!,
        repository,
      );

      var note = await repository.getNoteById('workflow-test');
      expect(note!.pages.length, equals(2));
      expect(note.pages[1].pageNumber, equals(2));

      // 3. 페이지 추가 (중간에)
      final newPage2 = await PageManagementService.createBlankPage(
        'workflow-test',
        2, // This will be remapped
      );
      expect(newPage2, isNotNull);

      await PageManagementService.addPage(
        'workflow-test',
        newPage2!,
        repository,
        insertIndex: 1, // Insert at position 1
      );

      note = await repository.getNoteById('workflow-test');
      expect(note!.pages.length, equals(3));

      // 페이지 번호가 올바르게 재매핑되었는지 확인
      for (int i = 0; i < note.pages.length; i++) {
        expect(note.pages[i].pageNumber, equals(i + 1));
      }

      // 4. 페이지 삭제 가능 여부 확인
      expect(
        PageManagementService.canDeletePage(note, note.pages[1].pageId),
        isTrue,
      );

      // 5. 페이지 삭제
      await PageManagementService.deletePage(
        'workflow-test',
        note.pages[1].pageId,
        repository,
      );

      note = await repository.getNoteById('workflow-test');
      expect(note!.pages.length, equals(2));

      // 페이지 번호가 올바르게 재매핑되었는지 확인
      expect(note.pages[0].pageNumber, equals(1));
      expect(note.pages[1].pageNumber, equals(2));

      // 6. 마지막 페이지까지 삭제 시도 (실패해야 함)
      await PageManagementService.deletePage(
        'workflow-test',
        note.pages[1].pageId,
        repository,
      );

      note = await repository.getNoteById('workflow-test');
      expect(note!.pages.length, equals(1));

      // 마지막 페이지 삭제 시도 (예외 발생해야 함)
      expect(
        () => PageManagementService.deletePage(
          'workflow-test',
          note!.pages[0].pageId,
          repository,
        ),
        throwsException,
      );
    });

    test('should handle PDF-based note page management', () async {
      // PDF 기반 노트 생성
      final pdfNote = NoteModel(
        noteId: 'pdf-workflow-test',
        title: 'PDF Workflow Test',
        pages: [
          NotePageModel(
            noteId: 'pdf-workflow-test',
            pageId: 'pdf-page-1',
            pageNumber: 1,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.pdf,
            backgroundPdfPath: '/path/to/test.pdf',
            backgroundPdfPageNumber: 1,
            backgroundWidth: 595.0,
            backgroundHeight: 842.0,
          ),
          NotePageModel(
            noteId: 'pdf-workflow-test',
            pageId: 'pdf-page-3',
            pageNumber: 2,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.pdf,
            backgroundPdfPath: '/path/to/test.pdf',
            backgroundPdfPageNumber: 3,
            backgroundWidth: 595.0,
            backgroundHeight: 842.0,
          ),
        ],
        sourceType: NoteSourceType.pdfBased,
        sourcePdfPath: '/path/to/test.pdf',
        totalPdfPages: 5,
      );
      await repository.upsert(pdfNote);

      // 사용 가능한 PDF 페이지 확인
      final availablePages = await PageManagementService.getAvailablePdfPages(
        'pdf-workflow-test',
        repository,
      );
      expect(availablePages, equals([2, 4, 5]));

      // 새 PDF 페이지 추가
      final newPdfPage = await PageManagementService.createPdfPage(
        'pdf-workflow-test',
        3, // This will be remapped
        2, // PDF page 2
        '/path/to/test.pdf',
        595.0,
        842.0,
        '/path/to/rendered/page2.png',
      );
      expect(newPdfPage, isNotNull);
      expect(newPdfPage!.backgroundPdfPageNumber, equals(2));

      await PageManagementService.addPage(
        'pdf-workflow-test',
        newPdfPage,
        repository,
      );

      final updatedNote = await repository.getNoteById('pdf-workflow-test');
      expect(updatedNote!.pages.length, equals(3));
      expect(updatedNote.pages[2].backgroundPdfPageNumber, equals(2));

      // 업데이트된 사용 가능한 PDF 페이지 확인
      final updatedAvailablePages = await PageManagementService.getAvailablePdfPages(
        'pdf-workflow-test',
        repository,
      );
      expect(updatedAvailablePages, equals([4, 5]));
    });

    test('should handle concurrent page operations correctly', () async {
      // 초기 노트 생성
      final note = NoteModel(
        noteId: 'concurrent-test',
        title: 'Concurrent Test Note',
        pages: [
          NotePageModel(
            noteId: 'concurrent-test',
            pageId: 'page-1',
            pageNumber: 1,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
          NotePageModel(
            noteId: 'concurrent-test',
            pageId: 'page-2',
            pageNumber: 2,
            jsonData: '{"lines":[]}',
            backgroundType: PageBackgroundType.blank,
          ),
        ],
        sourceType: NoteSourceType.blank,
      );
      await repository.upsert(note);

      // 여러 페이지를 동시에 추가
      final futures = <Future<void>>[];

      for (int i = 3; i <= 5; i++) {
        final newPage = await PageManagementService.createBlankPage(
          'concurrent-test',
          i,
        );
        if (newPage != null) {
          futures.add(
            PageManagementService.addPage(
              'concurrent-test',
              newPage,
              repository,
            ),
          );
        }
      }

      await Future.wait(futures);

      final finalNote = await repository.getNoteById('concurrent-test');
      expect(finalNote!.pages.length, equals(5));

      // 페이지 번호가 올바르게 설정되었는지 확인
      for (int i = 0; i < finalNote.pages.length; i++) {
        expect(finalNote.pages[i].pageNumber, equals(i + 1));
      }
    });
  });
}
