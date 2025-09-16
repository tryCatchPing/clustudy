import '../../features/notes/models/thumbnail_metadata.dart';
import '../entities/thumbnail_metadata_entity.dart';

/// Mapper helpers for thumbnail metadata persistence.
extension ThumbnailMetadataEntityMapper on ThumbnailMetadataEntity {
  /// Converts this [ThumbnailMetadataEntity] to a domain [ThumbnailMetadata].
  ThumbnailMetadata toDomainModel() {
    return ThumbnailMetadata(
      pageId: pageId,
      cachePath: cachePath,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt,
      fileSizeBytes: fileSizeBytes,
      checksum: checksum,
    );
  }
}

/// Mapper helpers for converting [ThumbnailMetadata] into Isar entities.
extension ThumbnailMetadataModelMapper on ThumbnailMetadata {
  /// Creates a [ThumbnailMetadataEntity] from this [ThumbnailMetadata].
  ThumbnailMetadataEntity toEntity({Id? existingId}) {
    final entity = ThumbnailMetadataEntity()
      ..pageId = pageId
      ..cachePath = cachePath
      ..createdAt = createdAt
      ..lastAccessedAt = lastAccessedAt
      ..fileSizeBytes = fileSizeBytes
      ..checksum = checksum;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }
}
