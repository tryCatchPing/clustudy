import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/shared/services/page_order_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PageOrderService', () {
    late List<NotePageModel> testPages;
    // const uuid = Uuid();

    setUp(() {
      // 테스트용 페이지 목록 생성
      testPages = [
        NotePageModel(
          noteId: 'note1',
          pageId: 'page1',
          pageNumber: 1,
          jsonData: '{}',
        ),
        NotePageModel(
          noteId: 'note1',
          pageId: 'page2',
          pageNumber: 2,
          jsonData: '{}',
        ),
        NotePageModel(
          noteId: 'note1',
          pageId: 'page3',
          pageNumber: 3,
          jsonData: '{}',
        ),
      ];
    });

    group('reorderPages', () {
      test('should reorder pages correctly', () {
        // 첫 번째 페이지를 마지막으로 이동
        final result = PageOrderService.reorderPages(testPages, 0, 2);

        expect(result.length, equals(3));
        expect(result[0].pageId, equals('page2'));
        expect(result[1].pageId, equals('page3'));
        expect(result[2].pageId, equals('page1'));
      });

      test('should handle same index', () {
        final result = PageOrderService.reorderPages(testPages, 1, 1);

        expect(result.length, equals(3));
        expect(result[0].pageId, equals('page1'));
        expect(result[1].pageId, equals('page2'));
        expect(result[2].pageId, equals('page3'));
      });

      test('should throw on invalid fromIndex', () {
        expect(
          () => PageOrderService.reorderPages(testPages, -1, 1),
          throwsArgumentError,
        );
        expect(
          () => PageOrderService.reorderPages(testPages, 3, 1),
          throwsArgumentError,
        );
      });

      test('should throw on invalid toIndex', () {
        expect(
          () => PageOrderService.reorderPages(testPages, 0, -1),
          throwsArgumentError,
        );
        expect(
          () => PageOrderService.reorderPages(testPages, 0, 3),
          throwsArgumentError,
        );
      });
    });

    group('remapPageNumbers', () {
      test('should remap page numbers correctly', () {
        // 순서를 변경한 후 페이지 번호 재매핑
        final reordered = PageOrderService.reorderPages(testPages, 0, 2);
        final remapped = PageOrderService.remapPageNumbers(reordered);

        expect(remapped[0].pageNumber, equals(1)); // page2
        expect(remapped[1].pageNumber, equals(2)); // page3
        expect(remapped[2].pageNumber, equals(3)); // page1
      });

      test('should handle already correct page numbers', () {
        final remapped = PageOrderService.remapPageNumbers(testPages);

        expect(remapped[0].pageNumber, equals(1));
        expect(remapped[1].pageNumber, equals(2));
        expect(remapped[2].pageNumber, equals(3));
      });
    });

    group('validateReorder', () {
      test('should validate correct parameters', () {
        final result = PageOrderService.validateReorder(testPages, 0, 2);
        expect(result, isTrue);
      });

      test('should reject empty pages', () {
        final result = PageOrderService.validateReorder([], 0, 1);
        expect(result, isFalse);
      });

      test('should reject invalid fromIndex', () {
        expect(
          PageOrderService.validateReorder(testPages, -1, 1),
          isFalse,
        );
        expect(
          PageOrderService.validateReorder(testPages, 3, 1),
          isFalse,
        );
      });

      test('should reject invalid toIndex', () {
        expect(
          PageOrderService.validateReorder(testPages, 0, -1),
          isFalse,
        );
        expect(
          PageOrderService.validateReorder(testPages, 0, 3),
          isFalse,
        );
      });

      test('should reject mixed noteIds', () {
        final mixedPages = [
          testPages[0],
          NotePageModel(
            noteId: 'note2', // 다른 노트 ID
            pageId: 'page4',
            pageNumber: 2,
            jsonData: '{}',
          ),
        ];

        final result = PageOrderService.validateReorder(mixedPages, 0, 1);
        expect(result, isFalse);
      });

      test('should reject duplicate pageIds', () {
        final duplicatePages = [
          testPages[0],
          testPages[0], // 중복 페이지
        ];

        final result = PageOrderService.validateReorder(duplicatePages, 0, 1);
        expect(result, isFalse);
      });
    });

    group('findPageIndex', () {
      test('should find correct page index', () {
        final index = PageOrderService.findPageIndex(testPages, 'page2');
        expect(index, equals(1));
      });

      test('should return -1 for non-existent page', () {
        final index = PageOrderService.findPageIndex(testPages, 'nonexistent');
        expect(index, equals(-1));
      });
    });

    group('isSameOrder', () {
      test('should return true for same order', () {
        final pages2 = List<NotePageModel>.from(testPages);
        final result = PageOrderService.isSameOrder(testPages, pages2);
        expect(result, isTrue);
      });

      test('should return false for different order', () {
        final reordered = PageOrderService.reorderPages(testPages, 0, 2);
        final result = PageOrderService.isSameOrder(testPages, reordered);
        expect(result, isFalse);
      });

      test('should return false for different lengths', () {
        final shorterPages = [testPages[0], testPages[1]];
        final result = PageOrderService.isSameOrder(testPages, shorterPages);
        expect(result, isFalse);
      });
    });
  });
}
