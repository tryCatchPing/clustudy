import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:it_contest/shared/services/pdf_cache_service.dart';

/// Simple thumbnail generator that ensures PDF base cache exists and returns its path.
/// Future work: composite canvas strokes over the PDF image.
/// Provides APIs for generating and resolving thumbnail paths.
class ThumbnailService {
  ThumbnailService._();
  static final ThumbnailService instance = ThumbnailService._();

  Future<String> generateThumbnail({
    required int noteId,
    required int pageIndex,
    int dpi = 144,
  }) async {
    await PdfCacheService.instance.renderAndCache(
      noteId: noteId,
      pageIndex: pageIndex,
      dpi: dpi,
    );
    final docs = await getApplicationDocumentsDirectory();
    final rel = PdfCacheService.instance.path(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
    final abs = p.join(docs.path, rel);
    if (!File(abs).existsSync()) {
      throw StateError('Thumbnail not created');
    }
    return abs;
  }
}
