import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:it_contest/features/pdf_cache/data/isar_pdf_cache_repository.dart';
import 'package:it_contest/features/pdf_cache/data/pdf_cache_repository.dart';

/// PDF 캐시 Repository Provider
///
/// - 기본: IsarPdfCacheRepository 사용
/// - 테스트 환경에서 Mock Repository로 교체 가능
final pdfCacheRepositoryProvider = Provider<PdfCacheRepository>((ref) {
  const useIsarRepo = bool.fromEnvironment('USE_ISAR_REPO', defaultValue: true);

  if (useIsarRepo) {
    final repo = IsarPdfCacheRepository();

    ref.onDispose(() {
      repo.dispose();
    });

    return repo;
  } else {
    // 테스트용 메모리 Repository (필요시 구현)
    throw UnimplementedError('Memory PDF Cache Repository not implemented');
  }
});

/// PDF 캐시 통계 Provider
final pdfCacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(pdfCacheRepositoryProvider);

  if (repository is IsarPdfCacheRepository) {
    final totalSize = await repository.getTotalCacheSize();
    final maxSizeMB = await repository.getMaxCacheSizeMB();
    final sizeByNote = await repository.getCacheSizeByNote();

    return {
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).round(),
      'maxSizeMB': maxSizeMB,
      'usagePercent': ((totalSize / (maxSizeMB * 1024 * 1024)) * 100).round(),
      'noteCount': sizeByNote.length,
      'averageSizePerNote': sizeByNote.isEmpty ? 0 : (totalSize / sizeByNote.length).round(),
    };
  }

  return {
    'totalSizeBytes': 0,
    'totalSizeMB': 0,
    'maxSizeMB': 512,
    'usagePercent': 0,
    'noteCount': 0,
    'averageSizePerNote': 0,
  };
});

/// 특정 노트의 캐시 메타데이터 Provider
final noteCacheMetaProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((
  ref,
  noteId,
) async {
  final repository = ref.watch(pdfCacheRepositoryProvider);

  if (repository is IsarPdfCacheRepository) {
    final allMetas = await repository.getAllCacheMetaOrderByLastAccess();
    final noteMetas = allMetas.where((meta) => meta.noteId == noteId).toList();

    return noteMetas
        .map(
          (meta) => {
            'pageIndex': meta.pageIndex,
            'cachePath': meta.cachePath,
            'dpi': meta.dpi,
            'sizeBytes': meta.sizeBytes,
            'sizeMB': (meta.sizeBytes / (1024 * 1024)).round(),
            'renderedAt': meta.renderedAt,
            'lastAccessAt': meta.lastAccessAt,
          },
        )
        .toList();
  }

  return [];
});
