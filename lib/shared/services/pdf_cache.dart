import 'package:it_contest/shared/services/pdf_cache_service.dart';

/// Pdf 캐시 퍼사드
///
/// - invalidate: 캐시 무효화 (노트 전체 또는 특정 페이지)
/// - path: 캐시 파일 상대 경로 조회
/// - renderAndCache: 페이지 렌더링 후 캐시에 저장
class PdfCache {
  /// 노트 캐시를 무효화합니다.
  /// pageIndex가 null이면 노트의 모든 페이지 캐시를 삭제합니다.
  static Future<void> invalidate({required int noteId, int? pageIndex}) {
    return PdfCacheService.instance.invalidate(noteId: noteId, pageIndex: pageIndex);
  }

  /// 캐시 파일의 상대 경로를 반환합니다.
  static String path({required int noteId, required int pageIndex, int dpi = 144}) {
    return PdfCacheService.instance.path(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
  }

  /// PDF 페이지를 렌더링하여 캐시에 저장합니다.
  static Future<void> renderAndCache({required int noteId, required int pageIndex, int dpi = 144}) {
    return PdfCacheService.instance.renderAndCache(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
  }
}
