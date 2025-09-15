import 'package:isar/isar.dart';

part 'note_entities.g.dart';

/// Entity-side enum mirroring domain NoteSourceType.
enum NoteSourceTypeEntity { blank, pdfBased }

/// Entity-side enum mirroring domain PageBackgroundType.
enum PageBackgroundTypeEntity { blank, pdf }

/// Isar collection for Notes.
@collection
class NoteEntity {
  /// Auto-increment primary key for Isar
  Id id = Isar.autoIncrement;

  /// Stable business ID (UUID), unique across all notes
  @Index(unique: true, replace: false)
  late String noteId;

  /// Title with an index to support search/sort
  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  /// Source type: blank or PDF-based
  @Enumerated(EnumType.name)
  late NoteSourceTypeEntity sourceType;

  /// PDF source info (for PDF-based notes)
  String? sourcePdfPath;
  int? totalPdfPages;

  /// Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Relationship: Note -> Pages
  final pages = IsarLinks<NotePageEntity>();

  // Relationship to placement will be added in Task 2.5
}

/// Isar collection for Note pages.
@collection
class NotePageEntity {
  /// Auto-increment primary key for Isar
  Id id = Isar.autoIncrement;

  /// Stable business ID (UUID), unique across all pages
  @Index(unique: true, replace: false)
  late String pageId;

  /// Owning note id; composite index with pageNumber for fast ordering
  @Index(composite: [CompositeIndex('pageNumber')])
  late String noteId;

  /// 1-based page number
  late int pageNumber;

  /// Sketch JSON data
  late String jsonData;

  /// Background metadata
  @Enumerated(EnumType.name)
  late PageBackgroundTypeEntity backgroundType;
  String? backgroundPdfPath;
  int? backgroundPdfPageNumber;
  double? backgroundWidth;
  double? backgroundHeight;
  String? preRenderedImagePath;
  late bool showBackgroundImage;

  /// Relationship: Page -> Note (backlink)
  final note = IsarLink<NoteEntity>();

  // Outgoing links are modeled via LinkEntity.sourcePage link
}
