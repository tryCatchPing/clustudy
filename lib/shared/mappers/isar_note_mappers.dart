import 'package:isar/isar.dart';

import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_page_model.dart';
import '../entities/note_entities.dart';

NoteSourceType _mapNoteSourceType(NoteSourceTypeEntity sourceType) {
  switch (sourceType) {
    case NoteSourceTypeEntity.blank:
      return NoteSourceType.blank;
    case NoteSourceTypeEntity.pdfBased:
      return NoteSourceType.pdfBased;
  }
}

NoteSourceTypeEntity _mapNoteSourceTypeEntity(NoteSourceType sourceType) {
  switch (sourceType) {
    case NoteSourceType.blank:
      return NoteSourceTypeEntity.blank;
    case NoteSourceType.pdfBased:
      return NoteSourceTypeEntity.pdfBased;
  }
}

PageBackgroundType _mapBackgroundType(PageBackgroundTypeEntity type) {
  switch (type) {
    case PageBackgroundTypeEntity.blank:
      return PageBackgroundType.blank;
    case PageBackgroundTypeEntity.pdf:
      return PageBackgroundType.pdf;
  }
}

PageBackgroundTypeEntity _mapBackgroundTypeEntity(PageBackgroundType type) {
  switch (type) {
    case PageBackgroundType.blank:
      return PageBackgroundTypeEntity.blank;
    case PageBackgroundType.pdf:
      return PageBackgroundTypeEntity.pdf;
  }
}

/// Mapper helpers for note entities.
extension NoteEntityMapper on NoteEntity {
  /// Converts this [NoteEntity] into a [NoteModel].
  ///
  /// [pageEntities] must contain the note’s pages in any order. They will be
  /// converted to domain models and sorted by [NotePageModel.pageNumber].
  NoteModel toDomainModel({Iterable<NotePageEntity>? pageEntities}) {
    final pageModels = (pageEntities ?? const <NotePageEntity>[])
        .map((page) => page.toDomainModel())
        .toList(growable: false);

    pageModels.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return NoteModel(
      noteId: noteId,
      title: title,
      pages: pageModels,
      sourceType: _mapNoteSourceType(sourceType),
      sourcePdfPath: sourcePdfPath,
      totalPdfPages: totalPdfPages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Mapper utilities for converting [NoteModel] instances.
extension NoteModelMapper on NoteModel {
  /// Creates a [NoteEntity] from this [NoteModel].
  NoteEntity toEntity({Id? existingId}) {
    final entity = NoteEntity()
      ..noteId = noteId
      ..title = title
      ..sourceType = _mapNoteSourceTypeEntity(sourceType)
      ..sourcePdfPath = sourcePdfPath
      ..totalPdfPages = totalPdfPages
      ..createdAt = createdAt
      ..updatedAt = updatedAt;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }

  /// Converts the note pages into [NotePageEntity] instances.
  List<NotePageEntity> toPageEntities() {
    return pages
        .map((page) => page.toEntity(parentNoteId: noteId))
        .toList(growable: false);
  }
}

/// Mapper helpers for note page entities.
extension NotePageEntityMapper on NotePageEntity {
  /// Converts this [NotePageEntity] into a [NotePageModel].
  NotePageModel toDomainModel() {
    return NotePageModel(
      noteId: noteId,
      pageId: pageId,
      pageNumber: pageNumber,
      jsonData: jsonData,
      backgroundType: _mapBackgroundType(backgroundType),
      backgroundPdfPath: backgroundPdfPath,
      backgroundPdfPageNumber: backgroundPdfPageNumber,
      backgroundWidth: backgroundWidth,
      backgroundHeight: backgroundHeight,
      preRenderedImagePath: preRenderedImagePath,
      showBackgroundImage: showBackgroundImage,
    );
  }
}

/// Mapper utilities for converting [NotePageModel] instances.
extension NotePageModelMapper on NotePageModel {
  /// Creates a [NotePageEntity] from this [NotePageModel].
  NotePageEntity toEntity({Id? existingId, String? parentNoteId}) {
    final entity = NotePageEntity()
      ..pageId = pageId
      ..noteId = parentNoteId ?? noteId
      ..pageNumber = pageNumber
      ..jsonData = jsonData
      ..backgroundType = _mapBackgroundTypeEntity(backgroundType)
      ..backgroundPdfPath = backgroundPdfPath
      ..backgroundPdfPageNumber = backgroundPdfPageNumber
      ..backgroundWidth = backgroundWidth
      ..backgroundHeight = backgroundHeight
      ..preRenderedImagePath = preRenderedImagePath
      ..showBackgroundImage = showBackgroundImage;

    if (existingId != null) {
      entity.id = existingId;
    }

    return entity;
  }
}
