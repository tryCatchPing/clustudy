import '../models/pdf_cache_meta_model.dart';

/// PDF 캐시 메타데이터 관리를 위한 Repository 인터페이스
abstract class PdfCacheRepository {
  /// PDF 캐시 메타데이터를 생성하거나 업데이트합니다
  Future<void> upsertCacheMeta({
    required int noteId,
    required int pageIndex,
    required String cachePath,
    required int dpi,
    required int sizeBytes,
  });

  /// 특정 노트의 캐시 메타데이터를 삭제합니다
  /// [pageIndex]가 null이면 해당 노트의 모든 캐시 메타데이터를 삭제
  Future<void> deleteCacheMeta({
    required int noteId,
    int? pageIndex,
  });

  /// 특정 노트와 페이지의 캐시 메타데이터를 조회합니다
  Future<PdfCacheMetaModel?> getCacheMeta({
    required int noteId,
    required int pageIndex,
  });

  /// 모든 캐시 메타데이터를 크기 순으로 조회합니다 (LRU 정책용)
  Future<List<PdfCacheMetaModel>> getAllCacheMetaOrderByLastAccess();

  /// 전체 캐시 크기를 계산합니다
  Future<int> getTotalCacheSize();

  /// 설정에서 최대 캐시 크기를 조회합니다
  Future<int> getMaxCacheSizeMB();

  /// 캐시 메타데이터의 마지막 접근 시간을 업데이트합니다
  Future<void> updateLastAccessTime({
    required int noteId,
    required int pageIndex,
  });

  /// Repository 리소스 정리
  void dispose();
}
