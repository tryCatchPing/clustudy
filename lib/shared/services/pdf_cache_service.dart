import 'dart:io';

import 'package:path/path.dart' as p;
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
}


