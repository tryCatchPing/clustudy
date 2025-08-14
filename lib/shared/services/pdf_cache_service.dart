import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';

class PdfCacheService {
  PdfCacheService._();
  static final PdfCacheService instance = PdfCacheService._();

  Future<String> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'notes');
  }

  Future<String> path({required int noteId, required int pageIndex, int scale = 1}) async {
    final base = await _baseDir();
    final dir = p.join(base, '$noteId', 'pdf_cache');
    final name = '${pageIndex}.png';
    // scaleX144 DPI 규약을 파일명에 반영하고 싶다면 `${pageIndex}@${scale}x.png` 로 변경 가능
    await Directory(dir).create(recursive: true);
    return p.join(dir, name);
  }

  Future<void> invalidate({required int noteId, int? pageIndex}) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, '$noteId', 'pdf_cache'));
    if (!await dir.exists()) return;
    if (pageIndex == null) {
      await dir.delete(recursive: true);
      return;
    }
    final file = File(p.join(dir.path, '$pageIndex.png'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Render and write PNG cache at 144DPI * scale
  Future<File> renderAndCache({
    required String pdfPath,
    required int noteId,
    required int pageIndex,
    int scale = 1,
  }) async {
    // TODO: enforce LRU/size limit from Settings.pdfCacheMaxMB
    final target = await path(noteId: noteId, pageIndex: pageIndex, scale: scale);
    final doc = await PdfDocument.openFile(pdfPath);
    try {
      final page = await doc.getPage(pageIndex + 1); // pdfx 1-based
      try {
        final dpi = 144 * scale;
        final pageImage = await page.render(width: page.width * scale, height: page.height * scale);
        final file = File(target);
        await file.writeAsBytes(pageImage!.bytes);
        return file;
      } finally {
        await page.close();
      }
    } finally {
      await doc.close();
    }
  }
}


