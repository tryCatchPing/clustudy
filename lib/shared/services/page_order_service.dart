import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/models/note_page_model.dart';

/// 페이지 순서 변경 작업 정보를 담는 클래스입니다.
///
/// 순서 변경 실패 시 롤백을 위해 사용됩니다.
class PageReorderOperation {
  /// 대상 노트의 ID.
  final String noteId;

  /// 원본 인덱스 (드래그 시작 위치).
  final int fromIndex;

  /// 대상 인덱스 (드롭 위치).
  final int toIndex;

  /// 원본 페이지 목록.
  final List<NotePageModel> originalPages;

  /// 순서 변경된 페이지 목록.
  final List<NotePageModel> reorderedPages;

  /// [PageReorderOperation]의 생성자.
  const PageReorderOperation({
    required this.noteId,
    required this.fromIndex,
    required this.toIndex,
    required this.originalPages,
    required this.reorderedPages,
  });
}

/// 페이지 순서 변경 로직을 담당하는 서비스입니다.
///
/// 이 서비스는 순수한 비즈니스 로직을 담당하며, Repository를 통해 데이터를 영속화합니다.
/// 향후 Isar DB 도입 시에도 이 서비스의 로직은 변경되지 않습니다.
class PageOrderService {
  /// 페이지 순서를 변경합니다.
  ///
  /// [pages]는 원본 페이지 목록이고, [fromIndex]는 이동할 페이지의 현재 인덱스,
  /// [toIndex]는 이동할 대상 인덱스입니다.
  ///
  /// 반환값은 새로운 순서로 정렬된 페이지 목록입니다.
  static List<NotePageModel> reorderPages(
    List<NotePageModel> pages,
    int fromIndex,
    int toIndex,
  ) {
    // 입력 유효성 검사
    if (fromIndex < 0 || fromIndex >= pages.length) {
      throw ArgumentError('fromIndex is out of range: $fromIndex');
    }
    if (toIndex < 0 || toIndex >= pages.length) {
      throw ArgumentError('toIndex is out of range: $toIndex');
    }
    if (fromIndex == toIndex) {
      return List.from(pages); // 동일한 위치면 복사본만 반환
    }

    // 페이지 목록 복사
    final reorderedPages = List<NotePageModel>.from(pages);

    // 페이지 이동
    final movedPage = reorderedPages.removeAt(fromIndex);
    reorderedPages.insert(toIndex, movedPage);

    return reorderedPages;
  }

  /// 페이지 번호를 재매핑합니다.
  ///
  /// [pages]는 순서가 변경된 페이지 목록입니다.
  /// 각 페이지의 pageNumber를 새로운 순서에 맞게 1부터 시작하도록 재할당합니다.
  ///
  /// 반환값은 pageNumber가 재매핑된 페이지 목록입니다.
  static List<NotePageModel> remapPageNumbers(List<NotePageModel> pages) {
    final remappedPages = <NotePageModel>[];

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final newPageNumber = i + 1; // 1부터 시작

      // pageNumber가 이미 올바르면 그대로 사용
      if (page.pageNumber == newPageNumber) {
        remappedPages.add(page);
      } else {
        // pageNumber 업데이트를 위해 새 인스턴스 생성
        final remappedPage = NotePageModel(
          noteId: page.noteId,
          pageId: page.pageId,
          pageNumber: newPageNumber,
          jsonData: page.jsonData,
          backgroundType: page.backgroundType,
          backgroundPdfPath: page.backgroundPdfPath,
          backgroundPdfPageNumber: page.backgroundPdfPageNumber,
          backgroundWidth: page.backgroundWidth,
          backgroundHeight: page.backgroundHeight,
          preRenderedImagePath: page.preRenderedImagePath,
          showBackgroundImage: page.showBackgroundImage,
        );
        remappedPages.add(remappedPage);
      }
    }

    return remappedPages;
  }

  /// Repository를 통해 순서 변경된 페이지들을 저장합니다.
  ///
  /// [noteId]는 대상 노트의 ID이고, [reorderedPages]는 순서가 변경된 페이지 목록입니다.
  /// [repo]는 데이터를 영속화할 Repository 인스턴스입니다.
  ///
  /// 저장 실패 시 예외가 발생합니다.
  static Future<void> saveReorderedPages(
    String noteId,
    List<NotePageModel> reorderedPages,
    NotesRepository repo,
  ) async {
    try {
      await repo.reorderPages(noteId, reorderedPages);
    } catch (e) {
      // 저장 실패 시 예외를 다시 던져서 상위 레이어에서 처리하도록 함
      throw Exception('Failed to save reordered pages: $e');
    }
  }

  /// 순서 변경 유효성을 검사합니다.
  ///
  /// [pages]는 페이지 목록이고, [fromIndex]와 [toIndex]는 이동 인덱스입니다.
  ///
  /// 유효하면 true, 그렇지 않으면 false를 반환합니다.
  static bool validateReorder(
    List<NotePageModel> pages,
    int fromIndex,
    int toIndex,
  ) {
    // 빈 목록 검사
    if (pages.isEmpty) {
      return false;
    }

    // 인덱스 범위 검사
    if (fromIndex < 0 || fromIndex >= pages.length) {
      return false;
    }
    if (toIndex < 0 || toIndex >= pages.length) {
      return false;
    }

    // 페이지 목록의 무결성 검사
    final noteIds = pages.map((p) => p.noteId).toSet();
    if (noteIds.length != 1) {
      // 모든 페이지가 동일한 노트에 속해야 함
      return false;
    }

    // 페이지 ID 중복 검사
    final pageIds = pages.map((p) => p.pageId).toSet();
    if (pageIds.length != pages.length) {
      return false;
    }

    return true;
  }

  /// 전체 페이지 순서 변경 작업을 수행합니다.
  ///
  /// [noteId]는 대상 노트의 ID이고, [pages]는 현재 페이지 목록,
  /// [fromIndex]와 [toIndex]는 이동 인덱스, [repo]는 Repository 인스턴스입니다.
  ///
  /// 성공 시 [PageReorderOperation] 객체를 반환하고, 실패 시 예외가 발생합니다.
  static Future<PageReorderOperation> performReorder(
    String noteId,
    List<NotePageModel> pages,
    int fromIndex,
    int toIndex,
    NotesRepository repo,
  ) async {
    // 유효성 검사
    if (!validateReorder(pages, fromIndex, toIndex)) {
      throw ArgumentError('Invalid reorder parameters');
    }

    // 순서 변경
    final reorderedPages = reorderPages(pages, fromIndex, toIndex);

    // 페이지 번호 재매핑
    final remappedPages = remapPageNumbers(reorderedPages);

    // Repository를 통한 저장
    await saveReorderedPages(noteId, remappedPages, repo);

    // 작업 정보 반환 (롤백용)
    return PageReorderOperation(
      noteId: noteId,
      fromIndex: fromIndex,
      toIndex: toIndex,
      originalPages: pages,
      reorderedPages: remappedPages,
    );
  }

  /// 순서 변경 작업을 롤백합니다.
  ///
  /// [operation]은 롤백할 작업 정보이고, [repo]는 Repository 인스턴스입니다.
  ///
  /// 롤백 실패 시 예외가 발생합니다.
  static Future<void> rollbackReorder(
    PageReorderOperation operation,
    NotesRepository repo,
  ) async {
    try {
      await saveReorderedPages(
        operation.noteId,
        operation.originalPages,
        repo,
      );
    } catch (e) {
      throw Exception('Failed to rollback reorder operation: $e');
    }
  }

  /// 페이지 목록에서 특정 페이지의 인덱스를 찾습니다.
  ///
  /// [pages]는 페이지 목록이고, [pageId]는 찾을 페이지의 ID입니다.
  ///
  /// 페이지를 찾으면 인덱스를 반환하고, 찾지 못하면 -1을 반환합니다.
  static int findPageIndex(List<NotePageModel> pages, String pageId) {
    for (int i = 0; i < pages.length; i++) {
      if (pages[i].pageId == pageId) {
        return i;
      }
    }
    return -1;
  }

  /// 두 페이지 목록이 동일한 순서인지 확인합니다.
  ///
  /// [pages1]과 [pages2]는 비교할 페이지 목록입니다.
  ///
  /// 동일한 순서면 true, 그렇지 않으면 false를 반환합니다.
  static bool isSameOrder(
    List<NotePageModel> pages1,
    List<NotePageModel> pages2,
  ) {
    if (pages1.length != pages2.length) {
      return false;
    }

    for (int i = 0; i < pages1.length; i++) {
      if (pages1[i].pageId != pages2[i].pageId) {
        return false;
      }
    }

    return true;
  }
}
