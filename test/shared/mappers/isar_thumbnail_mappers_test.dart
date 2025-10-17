import 'package:clustudy/features/notes/models/thumbnail_metadata.dart';
import 'package:clustudy/shared/entities/thumbnail_metadata_entity.dart';
import 'package:clustudy/shared/mappers/isar_thumbnail_mappers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  group('ThumbnailMetadata mappers', () {
    test('entity converts to domain model', () {
      final entity = ThumbnailMetadataEntity()
        ..id = 42
        ..pageId = 'page-1'
        ..cachePath = '/tmp/cache.png'
        ..createdAt = DateTime.utc(2024, 1, 1, 12)
        ..lastAccessedAt = DateTime.utc(2024, 1, 2, 8)
        ..fileSizeBytes = 4096
        ..checksum = 'checksum-123';

      final model = entity.toDomainModel();

      expect(model.pageId, equals('page-1'));
      expect(model.cachePath, equals('/tmp/cache.png'));
      expect(model.createdAt, equals(DateTime.utc(2024, 1, 1, 12)));
      expect(model.lastAccessedAt, equals(DateTime.utc(2024, 1, 2, 8)));
      expect(model.fileSizeBytes, equals(4096));
      expect(model.checksum, equals('checksum-123'));
    });

    test('model converts back to entity preserving optional id', () {
      final model = ThumbnailMetadata(
        pageId: 'page-1',
        cachePath: '/tmp/cache.png',
        createdAt: DateTime.utc(2024, 1, 1, 12),
        lastAccessedAt: DateTime.utc(2024, 1, 2, 8),
        fileSizeBytes: 4096,
        checksum: 'checksum-123',
      );

      final entity = model.toEntity(existingId: 99);

      expect(entity.id, equals(99));
      expect(entity.pageId, equals('page-1'));
      expect(entity.cachePath, equals('/tmp/cache.png'));
      expect(entity.createdAt, equals(DateTime.utc(2024, 1, 1, 12)));
      expect(entity.lastAccessedAt, equals(DateTime.utc(2024, 1, 2, 8)));
      expect(entity.fileSizeBytes, equals(4096));
      expect(entity.checksum, equals('checksum-123'));
    });

    test('toEntity defaults id when not provided', () {
      final model = ThumbnailMetadata(
        pageId: 'page-1',
        cachePath: '/tmp/cache.png',
        createdAt: DateTime.utc(2024, 1, 1, 12),
        lastAccessedAt: DateTime.utc(2024, 1, 2, 8),
        fileSizeBytes: 4096,
        checksum: 'checksum-123',
      );

      final entity = model.toEntity();

      expect(entity.id, equals(Isar.autoIncrement));
    });
  });
}
