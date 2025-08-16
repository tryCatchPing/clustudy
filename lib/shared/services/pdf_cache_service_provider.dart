import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/pdf_cache/data/pdf_cache_repository_provider.dart';
import 'pdf_cache_service.dart';

/// PDF Cache Service Provider
///
/// Repository를 주입받는 PDF Cache Service 인스턴스를 제공합니다.
final pdfCacheServiceProvider = Provider<PdfCacheService>((ref) {
  final repository = ref.watch(pdfCacheRepositoryProvider);
  final service = PdfCacheService.withRepository(repository);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// PDF Cache 통계 Provider (Service를 통한 접근)
final pdfCacheServiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(pdfCacheServiceProvider);
  return await service.getCacheStats();
});

/// PDF Cache 파일 존재 여부 확인 Provider
final pdfCacheExistsProvider = FutureProvider.family<bool, Map<String, int>>((ref, params) async {
  final service = ref.watch(pdfCacheServiceProvider);
  final noteId = params['noteId']!;
  final pageIndex = params['pageIndex']!;
  final dpi = params['dpi'] ?? 144;

  return await service.isCached(
    noteId: noteId,
    pageIndex: pageIndex,
    dpi: dpi,
  );
});

/// PDF Cache 정리 액션 Provider
final pdfCacheCleanupProvider = FutureProvider.family<void, Duration?>((ref, olderThan) async {
  final service = ref.watch(pdfCacheServiceProvider);
  await service.cleanupOldCache(olderThan: olderThan);
});
