import 'package:isar/isar.dart';

import '../../features/canvas/models/link_model.dart';
import '../entities/link_entity.dart';

/// Mapper helpers for link entities.
extension LinkEntityMapper on LinkEntity {
  /// Converts this [LinkEntity] into a domain [LinkModel].
  LinkModel toDomainModel() {
    return LinkModel(
      id: linkId,
      sourceNoteId: sourceNoteId,
      sourcePageId: sourcePageId,
      targetNoteId: targetNoteId,
      bboxLeft: bboxLeft,
      bboxTop: bboxTop,
      bboxWidth: bboxWidth,
      bboxHeight: bboxHeight,
      label: label,
      anchorText: anchorText,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper utilities for converting [LinkModel] instances.
extension LinkModelMapper on LinkModel {
  /// Creates an [LinkEntity] from this [LinkModel].
  LinkEntity toEntity({Id? existingId}) {
    final entity = LinkEntity()
      ..linkId = id
      ..sourceNoteId = sourceNoteId
      ..sourcePageId = sourcePageId
      ..targetNoteId = targetNoteId
      ..bboxLeft = bboxLeft
      ..bboxTop = bboxTop
      ..bboxWidth = bboxWidth
      ..bboxHeight = bboxHeight
      ..label = label
      ..anchorText = anchorText
      ..createdAt = createdAt
      ..updatedAt = updatedAt;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }
}
