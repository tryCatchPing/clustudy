import 'package:isar/isar.dart';

part 'pdf_cache_meta_model.g.dart';

/// PDF 캐시 메타데이터 도메인 모델
@collection
class PdfCacheMetaModel {
  /// 데이터베이스 ID.
  Id id = Isar.autoIncrement;
  /// 연결된 노트의 ID입니다.
  @Index()
  late int noteId;

  /// PDF 페이지 인덱스입니다 (0부터 시작).
  @Index()
  late int pageIndex;

  /// 캐시된 PDF 파일의 경로입니다.
  late String cachePath;

  /// 캐시된 PDF의 DPI (Dots Per Inch) 입니다.
  late int dpi;

  /// 캐시된 PDF 파일의 크기 (바이트 단위) 입니다.
  late int sizeBytes;

  /// PDF가 렌더링된 시각입니다.
  late DateTime renderedAt;

  /// 마지막 접근 시각입니다.
  @Index()
  late DateTime lastAccessAt;

  /// 중복 캐시 방지를 위한 유니크 제약조건: (noteId, pageIndex)
  @Index(composite: [CompositeIndex('noteId'), CompositeIndex('pageIndex')], unique: true)
  late String uniqueCacheKey;

  /// [PdfCacheMetaModel]의 기본 생성자.
  PdfCacheMetaModel();

  /// uniqueCacheKey를 설정합니다.
  void setUniqueKey() {
    uniqueCacheKey = '${noteId}_$pageIndex';
  }

  /// 현재 [PdfCacheMetaModel] 인스턴스의 특정 필드를 새 값으로 교체하여 새 인스턴스를 생성합니다.
  PdfCacheMetaModel copyWith({
    int? noteId,
    int? pageIndex,
    String? cachePath,
    int? dpi,
    int? sizeBytes,
    DateTime? renderedAt,
    DateTime? lastAccessAt,
  }) {
    final copy = PdfCacheMetaModel();
    copy.id = id;
    copy.noteId = noteId ?? this.noteId;
    copy.pageIndex = pageIndex ?? this.pageIndex;
    copy.cachePath = cachePath ?? this.cachePath;
    copy.dpi = dpi ?? this.dpi;
    copy.sizeBytes = sizeBytes ?? this.sizeBytes;
    copy.renderedAt = renderedAt ?? this.renderedAt;
    copy.lastAccessAt = lastAccessAt ?? this.lastAccessAt;
    copy.setUniqueKey();
    return copy;
  }

  @override
  String toString() {
    return 'PdfCacheMetaModel('
        'id: $id, '
        'noteId: $noteId, '
        'pageIndex: $pageIndex, '
        'cachePath: $cachePath, '
        'dpi: $dpi, '
        'sizeBytes: $sizeBytes, '
        'renderedAt: $renderedAt, '
        'lastAccessAt: $lastAccessAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PdfCacheMetaModel &&
        other.id == id &&
        other.noteId == noteId &&
        other.pageIndex == pageIndex &&
        other.cachePath == cachePath &&
        other.dpi == dpi &&
        other.sizeBytes == sizeBytes &&
        other.renderedAt == renderedAt &&
        other.lastAccessAt == lastAccessAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      noteId,
      pageIndex,
      cachePath,
      dpi,
      sizeBytes,
      renderedAt,
      lastAccessAt,
    );
  }
}
