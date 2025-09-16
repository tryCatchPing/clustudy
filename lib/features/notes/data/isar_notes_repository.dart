import 'dart:async';

import 'package:isar/isar.dart';

import '../../../shared/entities/note_entities.dart';
import '../../../shared/entities/thumbnail_metadata_entity.dart';
import '../../../shared/mappers/isar_note_mappers.dart';
import '../../../shared/mappers/isar_thumbnail_mappers.dart';
import '../../../shared/services/isar_database_service.dart';
import '../models/note_model.dart';
import '../models/note_page_model.dart';
import '../models/thumbnail_metadata.dart';
import 'notes_repository.dart';

/// Isar-backed implementation of [NotesRepository].
class IsarNotesRepository implements NotesRepository {
  IsarNotesRepository({Isar? isar}) : _providedIsar = isar;

  final Isar? _providedIsar;
  Isar? _isar;

  Future<Isar> _ensureIsar() async {
    final cached = _isar;
    if (cached != null && cached.isOpen) {
      return cached;
    }
    final resolved = _providedIsar ?? await IsarDatabaseService.getInstance();
    _isar = resolved;
    return resolved;
  }

  @override
  Stream<List<NoteModel>> watchNotes() {
    return Stream.multi((controller) async {
      final isar = await _ensureIsar();
      var emitting = false;
      var needsEmit = false;

      Future<void> emit() async {
        if (controller.isClosed) {
          return;
        }
        if (emitting) {
          needsEmit = true;
          return;
        }
        emitting = true;
        do {
          needsEmit = false;
          final models = await _loadAllNotes(isar);
          if (!controller.isClosed) {
            controller.add(models);
          }
        } while (needsEmit && !controller.isClosed);
        emitting = false;
      }

      void trigger() {
        // ignore: discarded_futures, intentionally fire-and-forget
        emit();
      }

      final noteSub = isar.noteEntitys
          .where()
          .anyId()
          .watchLazy()
          .listen((_) => trigger(), onError: controller.addError);

      final pageSub = isar.notePageEntitys
          .where()
          .anyId()
          .watchLazy()
          .listen((_) => trigger(), onError: controller.addError);

      trigger();

      controller.onCancel = () async {
        await noteSub.cancel();
        await pageSub.cancel();
      };
    });
  }

  @override
  Stream<NoteModel?> watchNoteById(String noteId) {
    return Stream.multi((controller) async {
      final isar = await _ensureIsar();
      var emitting = false;
      var needsEmit = false;

      Future<void> emit() async {
        if (controller.isClosed) {
          return;
        }
        if (emitting) {
          needsEmit = true;
          return;
        }
        emitting = true;
        do {
          needsEmit = false;
          final model = await _loadNote(isar, noteId);
          if (!controller.isClosed) {
            controller.add(model);
          }
        } while (needsEmit && !controller.isClosed);
        emitting = false;
      }

      void trigger() {
        // ignore: discarded_futures
        emit();
      }

      final noteSub = isar.noteEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .watchLazy()
          .listen((_) => trigger(), onError: controller.addError);

      final pageSub = isar.notePageEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .watchLazy()
          .listen((_) => trigger(), onError: controller.addError);

      trigger();

      controller.onCancel = () async {
        await noteSub.cancel();
        await pageSub.cancel();
      };
    });
  }

  @override
  Future<NoteModel?> getNoteById(String noteId) async {
    final isar = await _ensureIsar();
    return _loadNote(isar, noteId);
  }

  @override
  Future<void> upsert(NoteModel note) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final existing = await isar.noteEntitys.getByNoteId(note.noteId);
      final noteEntity = note.toEntity(existingId: existing?.id);
      await isar.noteEntitys.put(noteEntity);

      final existingPages = await isar.notePageEntitys
          .filter()
          .noteIdEqualTo(note.noteId)
          .findAll();
      final existingMap = {
        for (final page in existingPages) page.pageId: page,
      };

      final incomingIds = <String>{};
      for (final page in note.pages) {
        incomingIds.add(page.pageId);
        final existingPage = existingMap[page.pageId];
        final entity = page.toEntity(
          existingId: existingPage?.id,
          parentNoteId: note.noteId,
        );
        await isar.notePageEntitys.put(entity);
      }

      final toDelete = existingPages
          .where((page) => !incomingIds.contains(page.pageId))
          .map((page) => page.pageId)
          .toList(growable: false);
      if (toDelete.isNotEmpty) {
        await isar.notePageEntitys.deleteAllByPageId(toDelete);
        await isar.thumbnailMetadataEntitys.deleteAllByPageId(toDelete);
      }
    });
  }

  @override
  Future<void> delete(String noteId) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final pages = await isar.notePageEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .findAll();
      if (pages.isNotEmpty) {
        final pageIds = pages.map((p) => p.pageId).toList(growable: false);
        await isar.notePageEntitys.deleteAllByPageId(pageIds);
        await isar.thumbnailMetadataEntitys.deleteAllByPageId(pageIds);
      }
      await isar.noteEntitys.deleteByNoteId(noteId);
    });
  }

  @override
  Future<void> reorderPages(
    String noteId,
    List<NotePageModel> reorderedPages,
  ) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final note = await isar.noteEntitys.getByNoteId(noteId);
      if (note == null) {
        return;
      }

      for (var i = 0; i < reorderedPages.length; i += 1) {
        final model = reorderedPages[i];
        final existing = await isar.notePageEntitys.getByPageId(model.pageId);
        if (existing == null) {
          throw Exception('Page not found: ${model.pageId}');
        }
        final entity = model.toEntity(
          existingId: existing.id,
          parentNoteId: noteId,
        )
          ..pageNumber = i + 1;
        await isar.notePageEntitys.put(entity);
      }

      note.updatedAt = DateTime.now();
      await isar.noteEntitys.put(note);
    });
  }

  @override
  Future<void> addPage(
    String noteId,
    NotePageModel newPage, {
    int? insertIndex,
  }) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final note = await isar.noteEntitys.getByNoteId(noteId);
      if (note == null) {
        throw Exception('Note not found: $noteId');
      }
      final pages = await isar.notePageEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .sortByPageNumber()
          .findAll();
      final index = insertIndex == null
          ? pages.length
          : (insertIndex.clamp(0, pages.length) as int);

      pages.insert(index, newPage.toEntity(parentNoteId: noteId));
      for (var i = 0; i < pages.length; i += 1) {
        final entity = pages[i]
          ..pageNumber = i + 1;
        await isar.notePageEntitys.put(entity);
      }

      note.updatedAt = DateTime.now();
      await isar.noteEntitys.put(note);
    });
  }

  @override
  Future<void> deletePage(String noteId, String pageId) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final note = await isar.noteEntitys.getByNoteId(noteId);
      if (note == null) {
        throw Exception('Note not found: $noteId');
      }
      final pages = await isar.notePageEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .sortByPageNumber()
          .findAll();
      if (pages.length <= 1) {
        throw Exception('Cannot delete the last page of a note');
      }

      final removed = await isar.notePageEntitys.deleteByPageId(pageId);
      if (!removed) {
        throw Exception('Page not found: $pageId');
      }
      await isar.thumbnailMetadataEntitys.deleteByPageId(pageId);

      final remaining = await isar.notePageEntitys
          .filter()
          .noteIdEqualTo(noteId)
          .sortByPageNumber()
          .findAll();
      for (var i = 0; i < remaining.length; i += 1) {
        final entity = remaining[i]
          ..pageNumber = i + 1;
        await isar.notePageEntitys.put(entity);
      }

      note.updatedAt = DateTime.now();
      await isar.noteEntitys.put(note);
    });
  }

  @override
  Future<void> batchUpdatePages(
    String noteId,
    List<NotePageModel> pages,
  ) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final note = await isar.noteEntitys.getByNoteId(noteId);
      if (note == null) {
        throw Exception('Note not found: $noteId');
      }
      for (final model in pages) {
        final existing = await isar.notePageEntitys.getByPageId(model.pageId);
        if (existing == null) {
          throw Exception('Page not found: ${model.pageId}');
        }
        final entity = model.toEntity(
          existingId: existing.id,
          parentNoteId: noteId,
        );
        await isar.notePageEntitys.put(entity);
      }
      note.updatedAt = DateTime.now();
      await isar.noteEntitys.put(note);
    });
  }

  @override
  Future<void> updatePageJson(
    String noteId,
    String pageId,
    String json,
  ) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final page = await isar.notePageEntitys.getByPageId(pageId);
      if (page == null || page.noteId != noteId) {
        throw Exception('Page not found: $pageId');
      }
      page.jsonData = json;
      await isar.notePageEntitys.put(page);

      final note = await isar.noteEntitys.getByNoteId(noteId);
      if (note != null) {
        note.updatedAt = DateTime.now();
        await isar.noteEntitys.put(note);
      }
    });
  }

  @override
  Future<void> updateThumbnailMetadata(
    String pageId,
    ThumbnailMetadata metadata,
  ) async {
    final isar = await _ensureIsar();
    await isar.writeTxn(() async {
      final existing = await isar.thumbnailMetadataEntitys.getByPageId(pageId);
      final entity = metadata.toEntity(existingId: existing?.id);
      await isar.thumbnailMetadataEntitys.put(entity);
    });
  }

  @override
  Future<ThumbnailMetadata?> getThumbnailMetadata(String pageId) async {
    final isar = await _ensureIsar();
    final entity = await isar.thumbnailMetadataEntitys.getByPageId(pageId);
    return entity?.toDomainModel();
  }

  Future<List<NoteModel>> _loadAllNotes(Isar isar) async {
    final entities = await isar.noteEntitys.where().sortByCreatedAt().findAll();
    final pages = await isar.notePageEntitys
        .where()
        .sortByNoteId()
        .thenByPageNumber()
        .findAll();
    final grouped = <String, List<NotePageEntity>>{};
    for (final page in pages) {
      grouped.putIfAbsent(page.noteId, () => <NotePageEntity>[]).add(page);
    }
    return entities
        .map(
          (entity) => entity.toDomainModel(
            pageEntities: grouped[entity.noteId] ?? const <NotePageEntity>[],
          ),
        )
        .toList(growable: false);
  }

  Future<NoteModel?> _loadNote(Isar isar, String noteId) async {
    final entity = await isar.noteEntitys.getByNoteId(noteId);
    if (entity == null) {
      return null;
    }
    final pages = await isar.notePageEntitys
        .filter()
        .noteIdEqualTo(noteId)
        .sortByPageNumber()
        .findAll();
    return entity.toDomainModel(pageEntities: pages);
  }
}
