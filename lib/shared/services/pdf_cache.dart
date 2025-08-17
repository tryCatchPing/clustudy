import 'package:it_contest/shared/services/pdf_cache_service.dart';

/// PdfCache public interface (contract).
class PdfCache {
  static Future<void> invalidate({required int noteId, int? pageIndex}) {
    return PdfCacheService.instance.invalidate(noteId: noteId, pageIndex: pageIndex);
  }

  static String path({required int noteId, required int pageIndex, int dpi = 144}) {
    return PdfCacheService.instance.path(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
  }

  static Future<void> renderAndCache({required int noteId, required int pageIndex, int dpi = 144}) {
    return PdfCacheService.instance.renderAndCache(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
  }
}
