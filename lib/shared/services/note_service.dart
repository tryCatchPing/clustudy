import 'dart:developer' as developer;
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/shared/services/pdf_processed_data.dart';
import 'package:it_contest/shared/services/pdf_processor.dart';
import 'package:uuid/uuid.dart';

class NoteService {
  static final NoteService _instance = NoteService._();
  NoteService._();

  // Singleton 패턴
  static NoteService get instance => _instance;

  static const _uuid = Uuid();

  // 기본 빈 스케치 데이터
  static const _defaultJsonData = '{"lines":[]}';

  // ==================== 노트 생성 ====================

  /// 빈 노트 생성
  ///
  /// [title]: 노트 제목 (선택사항, 미제공시 자동 생성)
  /// [initialPageCount]: 초기 페이지 수 (기본값: 1)
  ///
  /// Returns: 생성된 NoteModel 또는 null (실패시)
  Future<NoteModel?> createBlankNote({
    String? title,
    int initialPageCount = 1,
  }) async {
    try {
      // 노트 ID 생성 (UUID로 고유성 보장)
      final noteId = _uuid.v4();

      // 노트 제목 생성
      final noteTitle = title ?? '새 노트 ${DateTime.now().toString().substring(0, 16)}';

      developer.log('🆔 노트 ID 생성: $noteId', name: 'NoteService');
      developer.log('📝 노트 제목: $noteTitle', name: 'NoteService');

      // 초기 빈 페이지 생성
      final pages = <NotePageModel>[];
      for (int i = 1; i <= initialPageCount; i++) {
        final page = await createBlankNotePage(
          noteId: noteId,
          pageNumber: i,
        );
        // TODO(jidam): 페이지 생성 실패 시 처리
        if (page != null) {
          pages.add(page);
        }
      }

      // 빈 노트 모델 생성
      final note = NoteModel(
        noteId: noteId,
        title: noteTitle,
        pages: pages,
        sourceType: NoteSourceType.blank,
      );

      developer.log('✅ 빈 노트 생성 완료: $noteTitle (${pages.length}페이지)', name: 'NoteService');
      return note;
    } on Exception catch (e, stack) {
      developer.log('❌ 빈 노트 생성 실패', name: 'NoteService', error: e, stackTrace: stack);
      return null;
    }
  }

  /*
    final String noteId;
    final String title;
    required List<NotePageModel> pages;
    required NoteSourceType sourceType;
    required String? sourcePdfPath;
    required int? totalPdfPages;
    required DateTime createdAt;
    required DateTime updatedAt;
  */

  /// PDF 노트 생성
  ///
  /// [title]: 노트 제목 (선택사항, 미제공시 PDF에서 추출한 제목 사용)
  ///
  /// Returns: 생성된 NoteModel 또는 null (실패시)
  Future<NoteModel?> createPdfNote({String? title}) async {
    try {
      // 1. PDF 처리 (PdfProcessor에 위임)
      final pdfData = await PdfProcessor.processFromSelection();
      if (pdfData == null) {
        developer.log('ℹ️ PDF 노트 생성 취소', name: 'NoteService');
        return null;
      }

      // 2. 노트 제목 결정
      final noteTitle = title ?? pdfData.extractedTitle;

      developer.log('🆔 노트 ID: ${pdfData.noteId}', name: 'NoteService');
      developer.log('📝 노트 제목: $noteTitle', name: 'NoteService');

      // 3. PDF 페이지들을 NotePageModel로 변환
      final pages = _createPagesFromPdfData(pdfData);

      // 4. PDF 노트 모델 생성 (순수 생성자 사용)
      final note = NoteModel(
        noteId: pdfData.noteId,
        title: noteTitle,
        pages: pages,
        sourceType: NoteSourceType.pdfBased,
        sourcePdfPath: pdfData.internalPdfPath,
        totalPdfPages: pdfData.totalPages,
      );

      developer.log('✅ PDF 노트 생성 완료: $noteTitle (${pages.length}페이지)', name: 'NoteService');
      return note;
    } on Exception catch (e, stack) {
      developer.log('❌ PDF 노트 생성 실패', name: 'NoteService', error: e, stackTrace: stack);
      return null;
    }
  }

  /// PDF 데이터를 NotePageModel 리스트로 변환
  List<NotePageModel> _createPagesFromPdfData(PdfProcessedData pdfData) {
    final pages = <NotePageModel>[];

    for (final pageData in pdfData.pages) {
      final page = NotePageModel(
        noteId: pdfData.noteId,
        pageId: _uuid.v4(),
        pageNumber: pageData.pageNumber,
        jsonData: _defaultJsonData,
        backgroundType: PageBackgroundType.pdf,
        backgroundPdfPath: pdfData.internalPdfPath,
        backgroundPdfPageNumber: pageData.pageNumber,
        backgroundWidth: pageData.width,
        backgroundHeight: pageData.height,
        preRenderedImagePath: pageData.preRenderedImagePath,
      );
      pages.add(page);
    }

    return pages;
  }

  // ==================== 노트 페이지 생성 ====================

  /// PDF 노트 페이지 생성
  ///
  /// [noteId]: 노트 고유 ID
  /// [pageNumber]: 페이지 번호 (1부터 시작)
  /// [backgroundPdfPath]: PDF 파일 경로
  /// [backgroundPdfPageNumber]: PDF의 페이지 번호
  /// [backgroundWidth]: PDF 페이지 너비
  /// [backgroundHeight]: PDF 페이지 높이
  /// [preRenderedImagePath]: 사전 렌더링된 이미지 경로 (선택사항)
  ///
  /// Returns: 생성된 NotePageModel 또는 null (실패시)
  Future<NotePageModel?> createPdfNotePage({
    required String noteId,
    required int pageNumber,
    required String backgroundPdfPath,
    required int backgroundPdfPageNumber,
    required double backgroundWidth,
    required double backgroundHeight,
    required String preRenderedImagePath,
  }) async {
    try {
      // 페이지 ID 생성 (UUID로 고유성 보장)
      final pageId = _uuid.v4();

      // PDF 배경이 있는 페이지 생성
      final page = NotePageModel(
        noteId: noteId,
        pageId: pageId,
        pageNumber: pageNumber,
        jsonData: _defaultJsonData,
        backgroundType: PageBackgroundType.pdf,
        backgroundPdfPath: backgroundPdfPath,
        backgroundPdfPageNumber: backgroundPdfPageNumber,
        backgroundWidth: backgroundWidth,
        backgroundHeight: backgroundHeight,
        preRenderedImagePath: preRenderedImagePath,
      );

      developer.log('✅ PDF 페이지 생성 완료: $pageId (PDF 페이지: $backgroundPdfPageNumber)', name: 'NoteService');
      return page;
    } on Exception catch (e, stack) {
      developer.log('❌ PDF 페이지 생성 실패', name: 'NoteService', error: e, stackTrace: stack);
      return null;
    }
  }

  /// 빈 노트 페이지 생성
  ///
  /// [noteId]: 노트 고유 ID
  /// [pageNumber]: 페이지 번호 (1부터 시작)
  ///
  /// Returns: 생성된 NotePageModel 또는 null (실패시)
  Future<NotePageModel?> createBlankNotePage({
    required String noteId,
    required int pageNumber,
  }) async {
    try {
      // 페이지 ID 생성 (UUID로 고유성 보장)
      final pageId = _uuid.v4();

      // 빈 노트 페이지 생성
      final page = NotePageModel(
        noteId: noteId,
        pageId: pageId,
        pageNumber: pageNumber,
        jsonData: _defaultJsonData,
        backgroundType: PageBackgroundType.blank,
      );

      developer.log('✅ 빈 노트 페이지 생성 완료: $pageId', name: 'NoteService');
      return page;
    } on Exception catch (e, stack) {
      developer.log('❌ 빈 노트 페이지 생성 실패', name: 'NoteService', error: e, stackTrace: stack);
      return null;
    }
  }
}
