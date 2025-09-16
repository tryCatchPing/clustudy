import 'package:flutter_test/flutter_test.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/shared/entities/note_entities.dart';
import 'package:it_contest/shared/mappers/isar_note_mappers.dart';

void main() {
  group('NoteEntityMapper', () {
    test('should convert entity to domain model with sorted pages', () {
      final entity = NoteEntity()
        ..noteId = 'note-1'
        ..title = 'Sample'
        ..sourceType = NoteSourceTypeEntity.pdfBased
        ..sourcePdfPath = '/tmp/file.pdf'
        ..totalPdfPages = 4
        ..createdAt = DateTime.parse('2024-04-01T10:00:00Z')
        ..updatedAt = DateTime.parse('2024-04-02T10:00:00Z');

      final pages = [
        NotePageEntity()
          ..pageId = 'page-2'
          ..noteId = 'note-1'
          ..pageNumber = 2
          ..jsonData = '{}'
          ..backgroundType = PageBackgroundTypeEntity.pdf
          ..backgroundPdfPageNumber = 2
          ..backgroundPdfPath = '/tmp/file.pdf'
          ..backgroundWidth = 1024
          ..backgroundHeight = 768
          ..preRenderedImagePath = null
          ..showBackgroundImage = true,
        NotePageEntity()
          ..pageId = 'page-1'
          ..noteId = 'note-1'
          ..pageNumber = 1
          ..jsonData = '{}'
          ..backgroundType = PageBackgroundTypeEntity.blank
          ..backgroundPdfPageNumber = null
          ..backgroundPdfPath = null
          ..backgroundWidth = null
          ..backgroundHeight = null
          ..preRenderedImagePath = null
          ..showBackgroundImage = true,
      ];

      final model = entity.toDomainModel(pageEntities: pages);

      expect(model.noteId, equals('note-1'));
      expect(model.title, equals('Sample'));
      expect(model.sourceType, equals(NoteSourceType.pdfBased));
      expect(model.sourcePdfPath, equals('/tmp/file.pdf'));
      expect(model.pages, hasLength(2));
      expect(model.pages.first.pageNumber, equals(1));
      expect(model.pages.last.pageNumber, equals(2));
    });

    test('should convert domain model to entity', () {
      final model = NoteModel(
        noteId: 'note-1',
        title: 'Sample',
        pages: <NotePageModel>[],
        sourceType: NoteSourceType.blank,
        createdAt: DateTime.parse('2024-04-01T10:00:00Z'),
        updatedAt: DateTime.parse('2024-04-02T10:00:00Z'),
      );

      final entity = model.toEntity(existingId: 7);

      expect(entity.id, equals(7));
      expect(entity.noteId, equals(model.noteId));
      expect(entity.title, equals(model.title));
      expect(entity.sourceType, equals(NoteSourceTypeEntity.blank));
    });

    test('should convert note pages to entities', () {
      final pageModels = <NotePageModel>[
        NotePageModel(
          noteId: 'note-1',
          pageId: 'page-1',
          pageNumber: 1,
          jsonData: '{}',
          backgroundType: PageBackgroundType.blank,
        ),
      ];

      final model = NoteModel(
        noteId: 'note-1',
        title: 'Sample',
        pages: pageModels,
        sourceType: NoteSourceType.blank,
        createdAt: DateTime.parse('2024-04-01T10:00:00Z'),
        updatedAt: DateTime.parse('2024-04-02T10:00:00Z'),
      );

      final entities = model.toPageEntities();

      expect(entities, hasLength(1));
      expect(entities.first.noteId, equals('note-1'));
      expect(entities.first.pageId, equals('page-1'));
      expect(
        entities.first.backgroundType,
        equals(PageBackgroundTypeEntity.blank),
      );
    });
  });

  group('NotePageModelMapper', () {
    test('should convert model to entity overriding noteId when provided', () {
      final model = NotePageModel(
        noteId: 'incorrect',
        pageId: 'page-1',
        pageNumber: 1,
        jsonData: '{}',
        backgroundType: PageBackgroundType.pdf,
        backgroundPdfPath: '/tmp/file.pdf',
        backgroundPdfPageNumber: 1,
        backgroundWidth: 800,
        backgroundHeight: 600,
        preRenderedImagePath: '/tmp/image.png',
        showBackgroundImage: false,
      );

      final entity = model.toEntity(existingId: 11, parentNoteId: 'note-1');

      expect(entity.id, equals(11));
      expect(entity.noteId, equals('note-1'));
      expect(entity.backgroundType, equals(PageBackgroundTypeEntity.pdf));
      expect(entity.showBackgroundImage, isFalse);
    });

    test('should convert entity back to model', () {
      final entity = NotePageEntity()
        ..id = 3
        ..noteId = 'note-1'
        ..pageId = 'page-1'
        ..pageNumber = 1
        ..jsonData = '{}'
        ..backgroundType = PageBackgroundTypeEntity.blank
        ..backgroundPdfPath = null
        ..backgroundPdfPageNumber = null
        ..backgroundWidth = null
        ..backgroundHeight = null
        ..preRenderedImagePath = null
        ..showBackgroundImage = true;

      final model = entity.toDomainModel();

      expect(model.pageId, equals('page-1'));
      expect(model.backgroundType, equals(PageBackgroundType.blank));
      expect(model.showBackgroundImage, isTrue);
    });
  });
}
