/// PDF 캐시 메타데이터 도메인 모델
class PdfCacheMetaModel {
  final int? id;
  final int noteId;
  final int pageIndex;
  final String cachePath;
  final int dpi;
  final int sizeBytes;
  final DateTime renderedAt;
  final DateTime lastAccessAt;

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
    if (identical(this, other)) return true;
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
