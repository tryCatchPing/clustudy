import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/pdf_cache/data/pdf_cache_repository.dart';
import '../../features/pdf_cache/data/isar_pdf_cache_repository.dart';

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
        
        // Repository를 통한 메타데이터 저장
        await _repository.upsertCacheMeta(
          noteId: noteId,
          pageIndex: pageIndex,
          cachePath: target,
          dpi: dpi,
          sizeBytes: pageImage.bytes.length,
        );
        
        await _enforceGlobalSizeLimit();
        return file;
      } finally {
        await page.close();
      }
    } finally {
      await doc.close();
    }
  }

  // _deleteMeta 메서드는 Repository로 대체되어 제거됨

  Future<void> _enforceGlobalSizeLimit() async {
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
      
      // 파일 삭제 목록에 추가
      filesToDelete.add(meta.cachePath);
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
  }

  // _upsertMeta 메서드는 Repository로 대체되어 제거됨

  // ========================================
  // 추가 유틸리티 메서드들
  // ========================================

  /// 캐시된 파일의 존재 여부 확인
  Future<bool> isCached({
    required int noteId,
    required int pageIndex,
    int scale = 1,
  }) async {
    final cachePath = await path(noteId: noteId, pageIndex: pageIndex, scale: scale);
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


