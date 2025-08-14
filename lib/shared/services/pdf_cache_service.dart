import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/db/isar_db.dart';
import '../../features/db/models/vault_models.dart';

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
        await _enforceGlobalSizeLimit();
        return file;
      } finally {
        await page.close();
      }
    } finally {
      await doc.close();
    }
  }

  Future<void> _enforceGlobalSizeLimit() async {
    final base = await _baseDir();
    final notesDir = Directory(base);
    if (!await notesDir.exists()) return;
    final isar = await IsarDb.instance.open();
    final settings = await isar.settingsEntitys.where().findFirst();
    final maxMB = settings?.pdfCacheMaxMB ?? 512;
    if (maxMB <= 0) return;
    final maxBytes = maxMB * 1024 * 1024;

    // Collect all cache files under notes/*/pdf_cache/*.png
    final files = <File>[];
    await for (final entity in notesDir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.contains('${Platform.pathSeparator}pdf_cache${Platform.pathSeparator}') && entity.path.endsWith('.png')) {
        files.add(entity);
      }
    }
    int total = 0;
    final sizes = <File, int>{};
    for (final f in files) {
      final s = await f.length();
      sizes[f] = s;
      total += s;
    }
    if (total <= maxBytes) return;
    // Sort by last modified ascending (oldest first)
    files.sort((a, b) {
      final ma = a.statSync().modified;
      final mb = b.statSync().modified;
      return ma.compareTo(mb);
    });
    for (final f in files) {
      try {
        final s = sizes[f] ?? await f.length();
        await f.delete();
        total -= s;
        if (total <= maxBytes) break;
      } catch (_) {
        // ignore individual delete failures
      }
    }
  }
}


