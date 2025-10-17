import 'package:clustudy/features/vaults/models/folder_model.dart';
import 'package:clustudy/features/vaults/models/note_placement.dart';
import 'package:clustudy/features/vaults/models/vault_model.dart';
import 'package:clustudy/shared/entities/note_placement_entity.dart';
import 'package:clustudy/shared/entities/vault_entity.dart';
import 'package:clustudy/shared/mappers/isar_vault_mappers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

void main() {
  group('VaultEntityMapper', () {
    test('should convert entity to domain model', () {
      final entity = VaultEntity()
        ..id = 5
        ..vaultId = 'vault-1'
        ..name = 'Vault'
        ..createdAt = DateTime.parse('2024-01-01T12:00:00Z')
        ..updatedAt = DateTime.parse('2024-01-02T12:00:00Z');

      final model = entity.toDomainModel();

      expect(model.vaultId, equals('vault-1'));
      expect(model.name, equals('Vault'));
      expect(model.createdAt, equals(DateTime.parse('2024-01-01T12:00:00Z')));
      expect(model.updatedAt, equals(DateTime.parse('2024-01-02T12:00:00Z')));
    });

    test('should convert domain model to entity preserving optional id', () {
      final model = VaultModel(
        vaultId: 'vault-1',
        name: 'Vault',
        createdAt: DateTime.parse('2024-01-01T12:00:00Z'),
        updatedAt: DateTime.parse('2024-01-02T12:00:00Z'),
      );

      final entity = model.toEntity(existingId: 10);

      expect(entity.id, equals(10));
      expect(entity.vaultId, equals(model.vaultId));
      expect(entity.name, equals(model.name));
      expect(entity.createdAt, equals(model.createdAt));
      expect(entity.updatedAt, equals(model.updatedAt));
    });
  });

  group('FolderEntityMapper', () {
    test('should convert entity to domain model', () {
      final entity = FolderEntity()
        ..id = 1
        ..folderId = 'folder-1'
        ..vaultId = 'vault-1'
        ..name = 'Docs'
        ..parentFolderId = 'root'
        ..createdAt = DateTime.parse('2024-02-01T12:00:00Z')
        ..updatedAt = DateTime.parse('2024-02-02T12:00:00Z');

      final model = entity.toDomainModel();

      expect(model.folderId, equals('folder-1'));
      expect(model.vaultId, equals('vault-1'));
      expect(model.name, equals('Docs'));
      expect(model.parentFolderId, equals('root'));
      expect(model.createdAt, equals(DateTime.parse('2024-02-01T12:00:00Z')));
      expect(model.updatedAt, equals(DateTime.parse('2024-02-02T12:00:00Z')));
    });

    test('should convert domain model to entity preserving id', () {
      final model = FolderModel(
        folderId: 'folder-1',
        vaultId: 'vault-1',
        name: 'Docs',
        parentFolderId: null,
        createdAt: DateTime.parse('2024-02-01T12:00:00Z'),
        updatedAt: DateTime.parse('2024-02-02T12:00:00Z'),
      );

      final entity = model.toEntity(existingId: 42);

      expect(entity.id, equals(42));
      expect(entity.folderId, equals(model.folderId));
      expect(entity.vaultId, equals(model.vaultId));
      expect(entity.name, equals(model.name));
      expect(entity.parentFolderId, isNull);
    });
  });

  group('NotePlacementEntityMapper', () {
    test('should convert entity to domain model', () {
      final entity = NotePlacementEntity()
        ..id = Isar.autoIncrement
        ..noteId = 'note-1'
        ..vaultId = 'vault-1'
        ..parentFolderId = 'folder-1'
        ..name = 'Note'
        ..createdAt = DateTime.parse('2024-03-01T12:00:00Z')
        ..updatedAt = DateTime.parse('2024-03-02T12:00:00Z');

      final model = entity.toDomainModel();

      expect(model.noteId, equals('note-1'));
      expect(model.vaultId, equals('vault-1'));
      expect(model.parentFolderId, equals('folder-1'));
      expect(model.name, equals('Note'));
      expect(model.createdAt, equals(DateTime.parse('2024-03-01T12:00:00Z')));
      expect(model.updatedAt, equals(DateTime.parse('2024-03-02T12:00:00Z')));
    });

    test(
      'should convert domain model to entity preserving id when provided',
      () {
        final model = NotePlacement(
          noteId: 'note-1',
          vaultId: 'vault-1',
          parentFolderId: null,
          name: 'Note',
          createdAt: DateTime.parse('2024-03-01T12:00:00Z'),
          updatedAt: DateTime.parse('2024-03-02T12:00:00Z'),
        );

        final entity = model.toEntity(existingId: 88);

        expect(entity.id, equals(88));
        expect(entity.noteId, equals(model.noteId));
        expect(entity.vaultId, equals(model.vaultId));
        expect(entity.parentFolderId, isNull);
        expect(entity.name, equals('Note'));
      },
    );
  });
}
