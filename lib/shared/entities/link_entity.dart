import 'package:isar/isar.dart';

import 'note_entities.dart';

part 'link_entity.g.dart';

/// Isar collection for page-level links between notes.
@collection
class LinkEntity {
  /// Auto-increment primary key for Isar
  Id id = Isar.autoIncrement;

  /// Stable business ID (UUID), unique across all links
  @Index(unique: true, replace: false)
  late String linkId;

  /// Source identifiers
  @Index(composite: [CompositeIndex('targetNoteId')])
  late String sourceNoteId;
  @Index()
  late String sourcePageId;

  /// Target identifiers
  @Index()
  late String targetNoteId;

  /// Bounding box in page-local coordinates
  late double bboxLeft;
  late double bboxTop;
  late double bboxWidth;
  late double bboxHeight;

  /// Optional display/anchor metadata
  String? label;
  String? anchorText;

  /// Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Relationships
  final sourcePage = IsarLink<NotePageEntity>();
  final targetNote = IsarLink<NoteEntity>();
}
