import 'package:clustudy/features/canvas/models/link_model.dart';
import 'package:clustudy/shared/entities/link_entity.dart';
import 'package:clustudy/shared/mappers/isar_link_mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinkEntityMapper', () {
    test('should convert entity to domain model', () {
      final entity = LinkEntity()
        ..id = 1
        ..linkId = 'link-1'
        ..sourceNoteId = 'note-1'
        ..sourcePageId = 'page-1'
        ..targetNoteId = 'note-2'
        ..bboxLeft = 1.0
        ..bboxTop = 2.0
        ..bboxWidth = 3.0
        ..bboxHeight = 4.0
        ..label = 'Label'
        ..anchorText = 'Anchor'
        ..createdAt = DateTime.parse('2024-05-01T10:00:00Z')
        ..updatedAt = DateTime.parse('2024-05-02T10:00:00Z');

      final model = entity.toDomainModel();

      expect(model.id, equals('link-1'));
      expect(model.sourceNoteId, equals('note-1'));
      expect(model.targetNoteId, equals('note-2'));
      expect(model.label, equals('Label'));
      expect(model.anchorText, equals('Anchor'));
    });

    test('should convert domain model to entity preserving id', () {
      final model = LinkModel(
        id: 'link-1',
        sourceNoteId: 'note-1',
        sourcePageId: 'page-1',
        targetNoteId: 'note-2',
        bboxLeft: 1.0,
        bboxTop: 2.0,
        bboxWidth: 3.0,
        bboxHeight: 4.0,
        label: 'Label',
        anchorText: 'Anchor',
        createdAt: DateTime.parse('2024-05-01T10:00:00Z'),
        updatedAt: DateTime.parse('2024-05-02T10:00:00Z'),
      );

      final entity = model.toEntity(existingId: 9);

      expect(entity.id, equals(9));
      expect(entity.linkId, equals('link-1'));
      expect(entity.sourcePageId, equals('page-1'));
      expect(entity.targetNoteId, equals('note-2'));
      expect(entity.label, equals('Label'));
    });
  });
}
