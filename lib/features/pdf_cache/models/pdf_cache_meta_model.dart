/// PDF 캐시 메타데이터 도메인 모델
class PdfCacheMetaModel {
  /// PDF 캐시의 고유 식별자. Null일 수 있습니다.
  final int? id;

  /// 연결된 노트의 ID입니다.
  final int noteId;

  /// PDF 페이지 인덱스입니다 (0부터 시작).
  final int pageIndex;

  /// 캐시된 PDF 파일의 경로입니다.
  final String cachePath;

  /// 캐시된 PDF의 DPI (Dots Per Inch) 입니다.
  final int dpi;

  /// 캐시된 PDF 파일의 크기 (바이트 단위) 입니다.
  final int sizeBytes;

  /// PDF가 렌더링된 시각입니다.
  final DateTime renderedAt;

  /// 마지막 접근 시각입니다.
  final DateTime lastAccessAt;

  /// [PdfCacheMetaModel]의 새 인스턴스를 생성합니다.
  ///
  /// [id]는 PDF 캐시의 고유 식별자입니다.
  /// [noteId]는 연결된 노트의 ID입니다.
  /// [pageIndex]는 PDF 페이지 인덱스입니다 (0부터 시작).
  /// [cachePath]는 캐시된 PDF 파일의 경로입니다.
  /// [dpi]는 캐시된 PDF의 DPI입니다.
  /// [sizeBytes]는 캐시된 PDF 파일의 크기 (바이트 단위) 입니다.
  /// [renderedAt]는 PDF가 렌더링된 시각입니다.
  /// [lastAccessAt]는 마지막 접근 시각입니다.
  PdfCacheMetaModel({
    this.id,
    required this.noteId,
    required this.pageIndex,
    required this.cachePath,
    required this.dpi,
    required this.sizeBytes,
    required this.renderedAt,
    required this.lastAccessAt,
  });

  /// 현재 [PdfCacheMetaModel] 인스턴스의 특정 필드를 새 값으로 교체하여 새 인스턴스를 생성합니다.
  ///
  /// 제공된 필드가 null이 아닌 경우, 해당 필드는 새로운 값으로 교체됩니다.
  /// null인 경우, 기존 인스턴스의 값이 유지됩니다.
  ///
  /// [id]는 새 ID입니다.
  /// [noteId]는 새 노트 ID입니다.
  /// [pageIndex]는 새 페이지 인덱스입니다.
  /// [cachePath]는 새 캐시 경로입니다.
  /// [dpi]는 새 DPI입니다.
  /// [sizeBytes]는 새 크기 (바이트 단위) 입니다.
  /// [renderedAt]는 새 렌더링 시각입니다.
  /// [lastAccessAt]는 새 마지막 접근 시각입니다.
  ///
  /// 반환 값은 업데이트된 필드를 포함하는 새 [PdfCacheMetaModel] 인스턴스입니다.
  PdfCacheMetaModel copyWith({
    int? id,
    int? noteId,
    int? pageIndex,
    String? cachePath,
    int? dpi,
    int? sizeBytes,
    DateTime? renderedAt,
    DateTime? lastAccessAt,
  }) {
    return PdfCacheMetaModel(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      pageIndex: pageIndex ?? this.pageIndex,
      cachePath: cachePath ?? this.cachePath,
      dpi: dpi ?? this.dpi,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      renderedAt: renderedAt ?? this.renderedAt,
      lastAccessAt: lastAccessAt ?? this.lastAccessAt,
    );
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
