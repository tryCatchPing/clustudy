import 'package:isar/isar.dart';

part 'thumbnail_metadata_entity.g.dart';

/// Isar collection storing thumbnail metadata for note pages.
@collection
class ThumbnailMetadataEntity {
  /// Auto-increment primary key required by Isar.
  Id id = Isar.autoIncrement;

  /// Associated page id; unique so each page stores at most one metadata row.
  @Index(unique: true, replace: true)
  late String pageId;

  /// Cached file path for the rendered thumbnail.
  late String cachePath;

  /// Timestamp when the thumbnail file was generated.
  late DateTime createdAt;

  /// Timestamp when the thumbnail was last accessed.
  late DateTime lastAccessedAt;

  /// File size in bytes for cache management.
  late int fileSizeBytes;

  /// Content checksum allowing callers to detect stale thumbnails.
  late String checksum;
}
