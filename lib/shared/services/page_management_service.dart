import '../../features/notes/data/notes_repository.dart';
import '../repositories/link_repository.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_page_model.dart';
import 'note_service.dart';

/// 페이지 추가/삭제 관리를 담당하는 서비스입니다.
///
/// 이 서비스는 페이지 생성, 추가, 삭제에 대한 비즈니스 로직을 처리하며,
/// Repository 패턴을 통해 데이터 영속성을 관리합니다.
/// 향후 Isar DB 도입에 대비하여 확장 가능한 구조로 설계되었습니다.
class PageManagementService {
  /// 빈 페이지를 생성합니다.
  ///
  /// [noteId]는 노트의 고유 ID이고, [pageNumber]는 페이지 번호입니다.
  /// NoteService를 활용하여 페이지를 생성합니다.
  ///
  /// Returns: 생성된 NotePageModel 또는 null (실패시)
  static Future<NotePageModel?> createBlankPage(
    String noteId,
    int pageNumber,
  ) async {
    try {
      return await NoteService.instance.createBlankNotePage(
        noteId: noteId,
        pageNumber: pageNumber,
      );
    } catch (e) {
      print('❌ 빈 페이지 생성 실패: $e');
      return null;
    }
  }

  /// PDF 페이지를 생성합니다.
  ///
  /// [noteId]는 노트의 고유 ID이고, [pageNumber]는 페이지 번호입니다.
  /// [pdfPageNumber]는 PDF의 페이지 번호입니다.
  /// [backgroundPdfPath]는 PDF 파일 경로입니다.
  /// [backgroundWidth]와 [backgroundHeight]는 PDF 페이지 크기입니다.
  /// [preRenderedImagePath]는 사전 렌더링된 이미지 경로입니다.
  ///
  /// Returns: 생성된 NotePageModel 또는 null (실패시)
  static Future<NotePageModel?> createPdfPage(
    String noteId,
    int pageNumber,
    int pdfPageNumber,
    String backgroundPdfPath,
    double backgroundWidth,
    double backgroundHeight,
    String preRenderedImagePath,
  ) async {
    try {
      return await NoteService.instance.createPdfNotePage(
        noteId: noteId,
        pageNumber: pageNumber,
        backgroundPdfPath: backgroundPdfPath,
        backgroundPdfPageNumber: pdfPageNumber,
        backgroundWidth: backgroundWidth,
        backgroundHeight: backgroundHeight,
        preRenderedImagePath: preRenderedImagePath,
      );
    } catch (e) {
      print('❌ PDF 페이지 생성 실패: $e');
      return null;
    }
  }

  /// 노트에 페이지를 추가합니다.
  ///
  /// [noteId]는 대상 노트의 ID이고, [newPage]는 추가할 페이지입니다.
  /// [repo]는 데이터 영속성을 위한 Repository입니다.
  /// [insertIndex]가 지정되면 해당 위치에 삽입하고, 없으면 마지막에 추가합니다.
  ///
  /// 페이지 추가 후 자동으로 적절한 pageNumber를 할당합니다.
  static Future<void> addPage(
    String noteId,
    NotePageModel newPage,
    NotesRepository repo, {
    int? insertIndex,
  }) async {
    try {
      // 현재 노트 조회
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found: $noteId');
      }

      // 삽입 위치 결정
      final targetIndex = insertIndex ?? note.pages.length;

      // 페이지 번호 재할당을 위한 새로운 페이지 리스트 생성
      final pages = List<NotePageModel>.from(note.pages);

      // 새 페이지를 적절한 위치에 삽입
      pages.insert(targetIndex, newPage);

      // 모든 페이지의 pageNumber를 새로운 순서에 맞게 재매핑
      final reorderedPages = _remapPageNumbers(pages);

      // Repository를 통해 페이지 추가
      await repo.addPage(noteId, newPage, insertIndex: insertIndex);

      // 페이지 번호가 변경된 경우 배치 업데이트
      if (_needsPageNumberUpdate(note.pages, reorderedPages)) {
        await repo.batchUpdatePages(noteId, reorderedPages);
      }

      print('✅ 페이지 추가 완료: ${newPage.pageId} (위치: $targetIndex)');
    } catch (e) {
      print('❌ 페이지 추가 실패: $e');
      rethrow;
    }
  }

  /// 노트에서 페이지를 삭제합니다.
  ///
  /// [noteId]는 대상 노트의 ID이고, [pageId]는 삭제할 페이지의 ID입니다.
  /// [repo]는 데이터 영속성을 위한 Repository입니다.
  ///
  /// 마지막 페이지는 삭제할 수 없습니다.
  /// 페이지 삭제 후 남은 페이지들의 pageNumber를 재매핑합니다.
  static Future<void> deletePage(
    String noteId,
    String pageId,
    NotesRepository repo, {
    LinkRepository? linkRepo,
  }) async {
    try {
      // 현재 노트 조회
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('Note not found: $noteId');
      }

      // 삭제 가능 여부 검사
      if (!canDeletePage(note, pageId)) {
        throw Exception('Cannot delete the last page of a note');
      }

      // 먼저 해당 페이지에서 나가는 링크를 삭제 (있으면)
      if (linkRepo != null) {
        await linkRepo.deleteBySourcePage(pageId);
      }

      // Repository를 통해 페이지 삭제
      await repo.deletePage(noteId, pageId);

      // 삭제 후 남은 페이지들의 pageNumber 재매핑
      final updatedNote = await repo.getNoteById(noteId);
      if (updatedNote != null) {
        final reorderedPages = _remapPageNumbers(updatedNote.pages);
        if (_needsPageNumberUpdate(updatedNote.pages, reorderedPages)) {
          await repo.batchUpdatePages(noteId, reorderedPages);
        }
      }

      print('✅ 페이지 삭제 완료: $pageId');
    } catch (e) {
      print('❌ 페이지 삭제 실패: $e');
      rethrow;
    }
  }

  /// 페이지 삭제가 가능한지 검사합니다.
  ///
  /// [note]는 대상 노트이고, [pageId]는 삭제할 페이지의 ID입니다.
  /// 마지막 페이지는 삭제할 수 없습니다.
  ///
  /// Returns: 삭제 가능하면 true, 불가능하면 false
  static bool canDeletePage(NoteModel note, String pageId) {
    // 마지막 페이지 삭제 방지
    if (note.pages.length <= 1) {
      return false;
    }

    // 해당 페이지가 존재하는지 확인
    return note.pages.any((page) => page.pageId == pageId);
  }

  /// PDF 기반 노트에서 사용 가능한 PDF 페이지 목록을 반환합니다.
  ///
  /// [noteId]는 노트의 ID입니다.
  /// PDF 기반 노트가 아니거나 노트를 찾을 수 없으면 빈 리스트를 반환합니다.
  ///
  /// Returns: 사용 가능한 PDF 페이지 번호 리스트
  static Future<List<int>> getAvailablePdfPages(
    String noteId,
    NotesRepository repo,
  ) async {
    try {
      final note = await repo.getNoteById(noteId);
      if (note == null || !note.isPdfBased || note.totalPdfPages == null) {
        return [];
      }

      // 전체 PDF 페이지 범위
      final totalPages = note.totalPdfPages!;
      final allPages = List.generate(totalPages, (index) => index + 1);

      // 이미 사용 중인 PDF 페이지들
      final usedPages = note.pages
          .where((page) => page.backgroundPdfPageNumber != null)
          .map((page) => page.backgroundPdfPageNumber!)
          .toSet();

      // 사용 가능한 페이지들 (사용 중이지 않은 페이지들)
      return allPages.where((page) => !usedPages.contains(page)).toList();
    } catch (e) {
      print('❌ 사용 가능한 PDF 페이지 조회 실패: $e');
      return [];
    }
  }

  /// 페이지 번호를 순서대로 재매핑합니다.
  ///
  /// [pages]는 재매핑할 페이지 리스트입니다.
  /// 각 페이지의 pageNumber를 1부터 시작하는 연속된 번호로 설정합니다.
  ///
  /// Returns: pageNumber가 재매핑된 새로운 페이지 리스트
  static List<NotePageModel> _remapPageNumbers(List<NotePageModel> pages) {
    final remappedPages = <NotePageModel>[];

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final newPageNumber = i + 1;

      if (page.pageNumber != newPageNumber) {
        // pageNumber가 다르면 새로운 객체 생성
        remappedPages.add(
          NotePageModel(
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
          ),
        );
      } else {
        // pageNumber가 같으면 기존 객체 사용
        remappedPages.add(page);
      }
    }

    return remappedPages;
  }

  /// 페이지 번호 업데이트가 필요한지 확인합니다.
  ///
  /// [originalPages]는 원본 페이지 리스트이고, [newPages]는 새로운 페이지 리스트입니다.
  /// 두 리스트의 pageNumber가 다른 페이지가 있으면 업데이트가 필요합니다.
  ///
  /// Returns: 업데이트가 필요하면 true, 불필요하면 false
  static bool _needsPageNumberUpdate(
    List<NotePageModel> originalPages,
    List<NotePageModel> newPages,
  ) {
    if (originalPages.length != newPages.length) {
      return true;
    }

    for (int i = 0; i < originalPages.length; i++) {
      if (originalPages[i].pageNumber != newPages[i].pageNumber) {
        return true;
      }
    }

    return false;
  }
}
