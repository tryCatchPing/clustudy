import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:it_contest/features/pdf_cache/data/pdf_cache_repository.dart';
import 'package:it_contest/features/pdf_cache/models/pdf_cache_meta_model.dart';

/// Isar 기반 PDF 캐시 Repository 구현체
class IsarPdfCacheRepository implements PdfCacheRepository {
  Isar? _isar;

  /// Isar 인스턴스를 안전하게 가져옵니다
  Future<Isar> _open() async {
    _isar ??= await IsarDb.instance.open();
    return _isar!;
  }

  @override
  Future<void> upsertCacheMeta({
    required int noteId,
    required int pageIndex,
    required String cachePath,
    required int dpi,
    required int sizeBytes,
  }) async {
    final isar = await _open();
    final now = DateTime.now();

    await isar.writeTxn(() async {
      // 기존 메타데이터 조회
      final existing = await isar.pdfCacheMetas
          .filter()
          .noteIdEqualTo(noteId)
          .and()
          .pageIndexEqualTo(pageIndex)
          .findFirst();

      final meta = existing ?? PdfCacheMeta();

      if (existing == null) {
        meta
          ..noteId = noteId
          ..pageIndex = pageIndex;
      }

      meta
        ..cachePath = cachePath
        ..dpi = dpi
        ..renderedAt = now
        ..sizeBytes = sizeBytes
        ..lastAccessAt = now;

      // Unique constraint key 설정
      meta.setUniqueKey();

      await isar.pdfCacheMetas.put(meta);
    });
  }

  @override
  Future<void> deleteCacheMeta({
    required int noteId,
    int? pageIndex,
  }) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      if (pageIndex == null) {
        // 노트의 모든 캐시 메타데이터 삭제
        final metas = await isar.pdfCacheMetas.filter().noteIdEqualTo(noteId).findAll();

        if (metas.isNotEmpty) {
          await isar.pdfCacheMetas.deleteAll(metas.map((e) => e.id).toList());
        }
      } else {
        // 특정 페이지의 캐시 메타데이터 삭제
        final metas = await isar.pdfCacheMetas
            .filter()
            .noteIdEqualTo(noteId)
            .and()
            .pageIndexEqualTo(pageIndex)
            .findAll();

        if (metas.isNotEmpty) {
          await isar.pdfCacheMetas.deleteAll(metas.map((e) => e.id).toList());
        }
      }
    });
  }

  @override
  Future<PdfCacheMetaModel?> getCacheMeta({
    required int noteId,
    required int pageIndex,
  }) async {
    final isar = await _open();

    final meta = await isar.pdfCacheMetas
        .filter()
        .noteIdEqualTo(noteId)
        .and()
        .pageIndexEqualTo(pageIndex)
        .findFirst();

    if (meta == null) return null;

    return _mapToModel(meta);
  }

  @override
  Future<List<PdfCacheMetaModel>> getAllCacheMetaOrderByLastAccess() async {
    final isar = await _open();

    final metas = await isar.pdfCacheMetas.where().sortByLastAccessAt().findAll();

    return metas.map(_mapToModel).toList();
  }

  @override
  Future<int> getTotalCacheSize() async {
    final isar = await _open();

    final metas = await isar.pdfCacheMetas.where().findAll();

    return metas.fold<int>(0, (total, meta) => total + (meta.sizeBytes ?? 0));
  }

  @override
  Future<int> getMaxCacheSizeMB() async {
    final isar = await _open();

    final settings = await isar.settingsEntitys.where().findFirst();
    return settings?.pdfCacheMaxMB ?? 512; // 기본값 512MB
  }

  @override
  Future<void> updateLastAccessTime({
    required int noteId,
    required int pageIndex,
  }) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      final meta = await isar.pdfCacheMetas
          .filter()
          .noteIdEqualTo(noteId)
          .and()
          .pageIndexEqualTo(pageIndex)
          .findFirst();

      if (meta != null) {
        meta.lastAccessAt = DateTime.now();
        await isar.pdfCacheMetas.put(meta);
      }
    });
  }

  /// Isar PdfCacheMeta를 도메인 모델로 변환
  PdfCacheMetaModel _mapToModel(PdfCacheMeta meta) {
    return PdfCacheMetaModel(
      id: meta.id,
      noteId: meta.noteId,
      pageIndex: meta.pageIndex,
      cachePath: meta.cachePath,
      dpi: meta.dpi,
      sizeBytes: meta.sizeBytes ?? 0,
      renderedAt: meta.renderedAt,
      lastAccessAt: meta.lastAccessAt ?? meta.renderedAt,
    );
  }

  @override
  void dispose() {
    // Isar 인스턴스는 IsarDb에서 관리하므로 여기서는 참조만 해제
    _isar = null;
  }

  // ========================================
  // 추가 효율적 메서드들
  // ========================================

  /// 특정 크기 이상의 캐시 메타데이터들을 조회 (정리용)
  Future<List<PdfCacheMetaModel>> getCacheMetasOverSize(int maxSizeBytes) async {
    final isar = await _open();

    final metas = await isar.pdfCacheMetas
        .filter()
        .sizeBytesGreaterThan(maxSizeBytes)
        .sortByLastAccessAt()
        .findAll();

    return metas.map(_mapToModel).toList();
  }

  /// 특정 날짜 이전의 캐시 메타데이터들을 조회 (정리용)
  Future<List<PdfCacheMetaModel>> getCacheMetasOlderThan(DateTime cutoffDate) async {
    final isar = await _open();

    final metas = await isar.pdfCacheMetas
        .filter()
        .lastAccessAtLessThan(cutoffDate)
        .sortByLastAccessAt()
        .findAll();

    return metas.map(_mapToModel).toList();
  }

  /// 노트별 캐시 사용량 통계
  Future<Map<int, int>> getCacheSizeByNote() async {
    final isar = await _open();

    final metas = await isar.pdfCacheMetas.where().findAll();
    final sizeMap = <int, int>{};

    for (final meta in metas) {
      sizeMap[meta.noteId] = (sizeMap[meta.noteId] ?? 0) + (meta.sizeBytes ?? 0);
    }

    return sizeMap;
  }

  /// 배치 삭제 (LRU 정리용)
  Future<void> deleteCacheMetasBatch(List<int> metaIds) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      await isar.pdfCacheMetas.deleteAll(metaIds);
    });
  }
}
