/// 썸네일 메타데이터를 나타내는 모델입니다.
///
/// 썸네일 캐시의 생성 시간, 접근 시간, 파일 크기 등의 정보를 포함합니다.
/// 향후 Isar DB 도입 시 별도 컬렉션으로 관리될 예정입니다.
class ThumbnailMetadata {
  /// 페이지의 고유 ID.
  final String pageId;

  /// 썸네일 캐시 파일 경로.
  final String cachePath;

  /// 썸네일이 생성된 날짜 및 시간.
  final DateTime createdAt;

  /// 썸네일이 마지막으로 접근된 날짜 및 시간.
  final DateTime lastAccessedAt;

  /// 썸네일 파일 크기(바이트).
  final int fileSizeBytes;

  /// 페이지 내용 변경 감지용 체크섬.
  /// 페이지의 스케치 데이터와 배경 정보를 기반으로 생성됩니다.
  final String checksum;

  /// [ThumbnailMetadata]의 생성자.
  ///
  /// [pageId]는 페이지의 고유 ID입니다.
  /// [cachePath]는 썸네일 캐시 파일 경로입니다.
  /// [createdAt]은 썸네일이 생성된 날짜 및 시간입니다.
  /// [lastAccessedAt]은 썸네일이 마지막으로 접근된 날짜 및 시간입니다.
  /// [fileSizeBytes]는 썸네일 파일 크기(바이트)입니다.
  /// [checksum]은 페이지 내용 변경 감지용 체크섬입니다.
  const ThumbnailMetadata({
    required this.pageId,
    required this.cachePath,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.fileSizeBytes,
    required this.checksum,
  });

  /// 새 값으로 일부 필드를 교체한 복제본을 반환합니다.
  ThumbnailMetadata copyWith({
    String? pageId,
    String? cachePath,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    int? fileSizeBytes,
    String? checksum,
  }) {
    return ThumbnailMetadata(
      pageId: pageId ?? this.pageId,
      cachePath: cachePath ?? this.cachePath,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      checksum: checksum ?? this.checksum,
    );
  }

  /// 마지막 접근 시간을 현재 시간으로 업데이트한 복제본을 반환합니다.
  ThumbnailMetadata updateLastAccessed() {
    return copyWith(lastAccessedAt: DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThumbnailMetadata &&
        other.pageId == pageId &&
        other.cachePath == cachePath &&
        other.createdAt == createdAt &&
        other.lastAccessedAt == lastAccessedAt &&
        other.fileSizeBytes == fileSizeBytes &&
        other.checksum == checksum;
  }

  @override
  int get hashCode {
    return pageId.hashCode ^
        cachePath.hashCode ^
        createdAt.hashCode ^
        lastAccessedAt.hashCode ^
        fileSizeBytes.hashCode ^
        checksum.hashCode;
  }

  @override
  String toString() {
    return 'ThumbnailMetadata('
        'pageId: $pageId, '
        'cachePath: $cachePath, '
        'createdAt: $createdAt, '
        'lastAccessedAt: $lastAccessedAt, '
        'fileSizeBytes: $fileSizeBytes, '
        'checksum: $checksum'
        ')';
  }
}
