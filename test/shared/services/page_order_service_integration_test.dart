import 'package:flutter_test/flutter_test.dart';
import 'package:it_contest/features/notes/data/memory_notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/shared/services/page_order_service.dart';

void main() {
  group('PageOrderService Integration Tests', () {
    late MemoryNotesRepository repository;
    late NoteModel testNote;
    // const uuid = Uuid();

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
            jsonData: '{}',
          ),
          NotePageModel(
            noteId: 'test-note',
            pageId: 'page2',
            pageNumber: 2,
            jsonData: '{}',
          ),
          NotePageModel(
            noteId: 'test-note',
            pageId: 'page3',
            pageNumber: 3,
            jsonData: '{}',
          ),
        ],
      );

      await repository.upsert(testNote);
    });

    tearDown(() {
      repository.dispose();
    });

    test('should perform complete reorder operation', () async {
      // 첫 번째 페이지를 마지막으로 이동
      final operation = await PageOrderService.performReorder(
        'test-note',
        testNote.pages,
        0, // from index
        2, // to index
        repository,
      );

      // 작업 정보 검증
      expect(operation.noteId, equals('test-note'));
      expect(operation.fromIndex, equals(0));
      expect(operation.toIndex, equals(2));
      expect(operation.originalPages.length, equals(3));
      expect(operation.reorderedPages.length, equals(3));

      // 순서 변경 결과 검증
      expect(operation.reorderedPages[0].pageId, equals('page2'));
      expect(operation.reorderedPages[1].pageId, equals('page3'));
      expect(operation.reorderedPages[2].pageId, equals('page1'));

      // 페이지 번호 재매핑 검증
      expect(operation.reorderedPages[0].pageNumber, equals(1));
      expect(operation.reorderedPages[1].pageNumber, equals(2));
      expect(operation.reorderedPages[2].pageNumber, equals(3));

      // Repository에서 변경사항 확인
      final updatedNote = await repository.getNoteById('test-note');
      expect(updatedNote, isNotNull);
      expect(updatedNote!.pages.length, equals(3));
      expect(updatedNote.pages[0].pageId, equals('page2'));
      expect(updatedNote.pages[1].pageId, equals('page3'));
      expect(updatedNote.pages[2].pageId, equals('page1'));
    });

    test('should rollback on failure', () async {
      // 정상적인 순서 변경 수행
      final operation = await PageOrderService.performReorder(
        'test-note',
        testNote.pages,
        0,
        2,
        repository,
      );

      // 롤백 수행
      await PageOrderService.rollbackReorder(operation, repository);

      // 원래 상태로 복원되었는지 확인
      final restoredNote = await repository.getNoteById('test-note');
      expect(restoredNote, isNotNull);
      expect(restoredNote!.pages.length, equals(3));
      expect(restoredNote.pages[0].pageId, equals('page1'));
      expect(restoredNote.pages[1].pageId, equals('page2'));
      expect(restoredNote.pages[2].pageId, equals('page3'));
    });

    test('should handle validation errors', () async {
      // 잘못된 인덱스로 순서 변경 시도
      expect(
        () => PageOrderService.performReorder(
          'test-note',
          testNote.pages,
          -1, // 잘못된 fromIndex
          2,
          repository,
        ),
        throwsArgumentError,
      );

      expect(
        () => PageOrderService.performReorder(
          'test-note',
          testNote.pages,
          0,
          5, // 잘못된 toIndex
          repository,
        ),
        throwsArgumentError,
      );
    });

    test('should handle same index reorder', () async {
      // 동일한 인덱스로 순서 변경
      final operation = await PageOrderService.performReorder(
        'test-note',
        testNote.pages,
        1, // same index
        1, // same index
        repository,
      );

      // 순서가 변경되지 않았는지 확인
      expect(operation.reorderedPages[0].pageId, equals('page1'));
      expect(operation.reorderedPages[1].pageId, equals('page2'));
      expect(operation.reorderedPages[2].pageId, equals('page3'));

      // Repository 상태도 변경되지 않았는지 확인
      final unchangedNote = await repository.getNoteById('test-note');
      expect(unchangedNote!.pages[0].pageId, equals('page1'));
      expect(unchangedNote.pages[1].pageId, equals('page2'));
      expect(unchangedNote.pages[2].pageId, equals('page3'));
    });

    test('should handle repository save with nonexistent note', () async {
      // 존재하지 않는 노트 ID로 순서 변경 시도
      // 메모리 구현체는 존재하지 않는 노트에 대해 조용히 무시함
      final operation = await PageOrderService.performReorder(
        'nonexistent-note',
        testNote.pages,
        0,
        2,
        repository,
      );

      // 작업은 성공하지만 실제로는 저장되지 않음
      expect(operation.noteId, equals('nonexistent-note'));
      expect(operation.reorderedPages.length, equals(3));

      // 존재하지 않는 노트는 여전히 존재하지 않음
      final nonexistentNote = await repository.getNoteById('nonexistent-note');
      expect(nonexistentNote, isNull);
    });
  });
}
