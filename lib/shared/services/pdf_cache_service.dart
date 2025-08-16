import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../features/db/isar_db.dart';
import '../../features/db/models/vault_models.dart';
import '../../features/pdf_cache/data/isar_pdf_cache_repository.dart';
import '../../features/pdf_cache/data/pdf_cache_repository.dart';

class PdfCacheService {
  final PdfCacheRepository _repository;

  PdfCacheService({
    required PdfCacheRepository repository,
  }) : _repository = repository;

  // 기존 Singleton 패턴을 위한 기본 인스턴스 (호환성)
  static PdfCacheService? _instance;
  static PdfCacheService get instance {
    _instance ??= PdfCacheService(
      repository: IsarPdfCacheRepository(),
    );
    return _instance!;
  }

  // Repository 주입을 위한 팩토리 생성자
  factory PdfCacheService.withRepository(PdfCacheRepository repository) {
    return PdfCacheService(repository: repository);
  }

  Future<String> _baseDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'notes');
  }

  /// 캐시 파일의 상대 경로 반환 (기존 API와 호환)
  String path({required int noteId, required int pageIndex, int dpi = 144}) {
    return 'notes/$noteId/pdf_cache/${pageIndex}@${dpi}.png';
  }

  /// 캐시 파일의 절대 경로 반환
  Future<String> absolutePath({required int noteId, required int pageIndex, int dpi = 144}) async {
    final base = await _baseDir();
    final dir = p.join(base, '$noteId', 'pdf_cache');
    final name = '${pageIndex}@${dpi}.png';
    await Directory(dir).create(recursive: true);
    return p.join(dir, name);
  }

  Future<void> invalidate({required int noteId, int? pageIndex}) async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, '$noteId', 'pdf_cache'));
    if (!await dir.exists()) return;

    if (pageIndex == null) {
      // 전체 노트 캐시 삭제
      await dir.delete(recursive: true);
      await _repository.deleteCacheMeta(noteId: noteId);
      return;
    }

    // 특정 페이지 캐시 삭제
    final file = File(p.join(dir.path, '$pageIndex.png'));
    if (await file.exists()) {
      await file.delete();
    }
    await _repository.deleteCacheMeta(noteId: noteId, pageIndex: pageIndex);
  }

  /// PDF 페이지를 렌더링하여 캐시에 저장 (오버로드된 메서드)
  Future<File> renderAndCache({
    String? pdfPath,
    required int noteId,
    required int pageIndex,
    int dpi = 144,
  }) async {
    String? resolvedPdfPath = pdfPath;
    int pdfPageNumber = pageIndex + 1; // pdfx는 1-based

    // pdfPath가 제공되지 않은 경우, DB에서 조회
    if (resolvedPdfPath == null) {
      final isar = await IsarDb.instance.open();
      final page = await isar.pages
          .filter()
          .noteIdEqualTo(noteId)
          .and()
          .indexEqualTo(pageIndex)
          .and()
          .deletedAtIsNull()
          .findFirst();

      if (page == null) {
        throw StateError('Page not found for noteId=$noteId, pageIndex=$pageIndex');
      }

      resolvedPdfPath = page.pdfOriginalPath;
      if (resolvedPdfPath == null || !await File(resolvedPdfPath).exists()) {
        throw StateError('Original PDF not available for rendering');
      }

      pdfPageNumber = (page.pdfPageIndex ?? pageIndex) + 1;
    }

    // 캐시 디렉토리 및 파일 경로 준비
    final target = await absolutePath(noteId: noteId, pageIndex: pageIndex, dpi: dpi);

    // PDF 렌더링 및 캐시 파일 생성
    PdfDocument? doc;
    PdfPageImage? img;
    try {
      doc = await PdfDocument.openFile(resolvedPdfPath);
      final pdfPage = await doc.getPage(pdfPageNumber);

      final double scale = dpi / 72.0;
      final double width = pdfPage.width * scale;
      final double height = pdfPage.height * scale;

      img = await pdfPage.render(
        width: width,
        height: height,
        format: PdfPageImageFormat.png,
      );

      await pdfPage.close();

      if (img?.bytes == null) {
        throw StateError('Failed to render PDF page');
      }

      final file = File(target);
      await file.writeAsBytes(img!.bytes);

      // Repository를 통한 메타데이터 저장
      await _repository.upsertCacheMeta(
        noteId: noteId,
        pageIndex: pageIndex,
        cachePath: path(noteId: noteId, pageIndex: pageIndex, dpi: dpi),
        dpi: dpi,
        sizeBytes: img.bytes.length,
      );

      await _enforceGlobalSizeLimit();
      return file;

    } finally {
      try {
        await doc?.close();
      } catch (_) {}
    }
  }

  // _deleteMeta 메서드는 Repository로 대체되어 제거됨

  Future<void> _enforceGlobalSizeLimit() async {
    try {
      // Repository를 통해 최대 캐시 크기와 현재 사용량 확인
      final maxMB = await _repository.getMaxCacheSizeMB();
      if (maxMB <= 0) return;

      final maxBytes = maxMB * 1024 * 1024;
      final currentBytes = await _repository.getTotalCacheSize();

      if (currentBytes <= maxBytes) return;

      // Repository에서 LRU 순으로 캐시 메타데이터 조회
      final allMetas = await _repository.getAllCacheMetaOrderByLastAccess();

      int totalToDelete = currentBytes - maxBytes;
      final metaIdsToDelete = <int>[];
      final filesToDelete = <String>[];

      for (final meta in allMetas) {
        if (totalToDelete <= 0) break;

        // 절대 경로로 변환
        final docs = await getApplicationDocumentsDirectory();
        final absoluteFilePath = p.join(docs.path, meta.cachePath);

        filesToDelete.add(absoluteFilePath);
        metaIdsToDelete.add(meta.id!);
        totalToDelete -= meta.sizeBytes;
      }

      // 실제 파일들 삭제
      for (final filePath in filesToDelete) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // 개별 파일 삭제 실패는 무시
        }
      }

      // Repository에서 메타데이터 배치 삭제
      if (_repository is IsarPdfCacheRepository && metaIdsToDelete.isNotEmpty) {
        await (_repository as IsarPdfCacheRepository).deleteCacheMetasBatch(metaIdsToDelete);
      }
    } catch (e) {
      // 캐시 정리 실패는 로그만 남기고 계속 진행
      if (kDebugMode) {
        print('Cache cleanup failed: $e');
      }
    }
  }

  // _upsertMeta 메서드는 Repository로 대체되어 제거됨

  // ========================================
  // 추가 유틸리티 메서드들
  // ========================================

  /// 캐시된 파일의 존재 여부 확인
  Future<bool> isCached({
    required int noteId,
    required int pageIndex,
    int dpi = 144,
  }) async {
    final cachePath = await absolutePath(noteId: noteId, pageIndex: pageIndex, dpi: dpi);
    final file = File(cachePath);

    if (!await file.exists()) return false;

    // 메타데이터도 확인
    final meta = await _repository.getCacheMeta(noteId: noteId, pageIndex: pageIndex);
    return meta != null;
  }

  /// 캐시 접근 시간 업데이트 (LRU 정책용)
  Future<void> markAsAccessed({
    required int noteId,
    required int pageIndex,
  }) async {
    await _repository.updateLastAccessTime(noteId: noteId, pageIndex: pageIndex);
  }

  /// 캐시 통계 조회
  Future<Map<String, dynamic>> getCacheStats() async {
    final totalBytes = await _repository.getTotalCacheSize();
    final maxMB = await _repository.getMaxCacheSizeMB();
    final maxBytes = maxMB * 1024 * 1024;

    if (_repository is IsarPdfCacheRepository) {
      final sizeByNote = await (_repository as IsarPdfCacheRepository).getCacheSizeByNote();

      return {
        'totalSizeBytes': totalBytes,
        'totalSizeMB': (totalBytes / (1024 * 1024)).round(),
        'maxSizeMB': maxMB,
        'usagePercent': maxBytes > 0 ? ((totalBytes / maxBytes) * 100).round() : 0,
        'noteCount': sizeByNote.length,
        'averageSizePerNote': sizeByNote.isEmpty ? 0 : (totalBytes / sizeByNote.length).round(),
      };
    }

    return {
      'totalSizeBytes': totalBytes,
      'totalSizeMB': (totalBytes / (1024 * 1024)).round(),
      'maxSizeMB': maxMB,
      'usagePercent': maxBytes > 0 ? ((totalBytes / maxBytes) * 100).round() : 0,
      'noteCount': 0,
      'averageSizePerNote': 0,
    };
  }

  /// 오래된 캐시 정리
  Future<void> cleanupOldCache({Duration? olderThan}) async {
    olderThan ??= const Duration(days: 30);
    final cutoffDate = DateTime.now().subtract(olderThan);

    if (_repository is IsarPdfCacheRepository) {
      final oldMetas = await (_repository as IsarPdfCacheRepository)
          .getCacheMetasOlderThan(cutoffDate);

      // 파일 삭제
      for (final meta in oldMetas) {
        try {
          final file = File(meta.cachePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // 개별 파일 삭제 실패 무시
        }
      }

      // 메타데이터 배치 삭제
      final metaIds = oldMetas.map((meta) => meta.id!).toList();
      if (metaIds.isNotEmpty) {
        await (_repository as IsarPdfCacheRepository).deleteCacheMetasBatch(metaIds);
      }
    }
  }

  /// Repository 리소스 정리
  void dispose() {
    _repository.dispose();
  }
}


