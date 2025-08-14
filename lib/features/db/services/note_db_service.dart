import 'dart:async';

import 'package:isar/isar.dart';

import '../isar_db.dart';
import '../models/vault_models.dart';

class NoteDbService {
  NoteDbService._();
  static final NoteDbService instance = NoteDbService._();

  Future<Note> createNote({
    required int vaultId,
    int? folderId,
    required String name,
    required String pageSize,
    required String pageOrientation,
    int sortIndex = 1000,
  }) async {
    final isar = await IsarDb.instance.open();
    final note = Note()
      ..vaultId = vaultId
      ..folderId = folderId
      ..name = name
      ..nameLowerForParentUnique = name.toLowerCase()
      ..pageSize = pageSize
      ..pageOrientation = pageOrientation
      ..sortIndex = sortIndex
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.notes.put(note);
    });
    return note;
  }

  Future<Page> createPage({
    required int noteId,
    required int index,
    int widthPx = 2480,
    int heightPx = 3508,
    int rotationDeg = 0,
  }) async {
    final isar = await IsarDb.instance.open();
    final page = Page()
      ..noteId = noteId
      ..index = index
      ..widthPx = widthPx
      ..heightPx = heightPx
      ..rotationDeg = rotationDeg
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.pages.put(page);
    });
    return page;
  }

  Future<LinkEntity> createLinkAndTargetNote({
    required int vaultId,
    required int sourceNoteId,
    required int sourcePageId,
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required String label,
    required String pageSize,
    required String pageOrientation,
    int initialPageIndex = 0,
  }) async {
    final isar = await IsarDb.instance.open();
    late final Note newNote;
    late final Page firstPage;
    late final LinkEntity link;
    await isar.writeTxn(() async {
      newNote = await createNote(
        vaultId: vaultId,
        name: label,
        pageSize: pageSize,
        pageOrientation: pageOrientation,
      );
      firstPage = await createPage(noteId: newNote.id, index: initialPageIndex);
      link = LinkEntity()
        ..vaultId = vaultId
        ..sourceNoteId = sourceNoteId
        ..sourcePageId = sourcePageId
        ..x0 = x0
        ..y0 = y0
        ..x1 = x1
        ..y1 = y1
        ..targetNoteId = newNote.id
        ..label = label
        ..dangling = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.linkEntitys.put(link);
      final edge = GraphEdge()
        ..vaultId = vaultId
        ..fromNoteId = sourceNoteId
        ..toNoteId = newNote.id
        ..createdAt = DateTime.now();
      await isar.graphEdges.put(edge);
    });
    return link;
  }

  Future<void> softDeleteNote(int noteId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final note = await isar.notes.get(noteId);
      if (note == null) return;
      note.deletedAt = now;
      note.updatedAt = now;
      await isar.notes.put(note);
      // mark dangling links
      final links = await isar.linkEntitys.filter().targetNoteIdEqualTo(noteId).findAll();
      for (final l in links) {
        l.dangling = true;
        l.updatedAt = now;
      }
      await isar.linkEntitys.putAll(links);
    });
  }

  Future<void> restoreNote(int noteId) async {
    final isar = await IsarDb.instance.open();
    final now = DateTime.now();
    await isar.writeTxn(() async {
      final note = await isar.notes.get(noteId);
      if (note == null) return;
      note.deletedAt = null;
      note.updatedAt = now;
      await isar.notes.put(note);
      // clear dangling on related links
      final links = await isar.linkEntitys.filter().targetNoteIdEqualTo(noteId).findAll();
      for (final l in links) {
        l.dangling = false;
        l.updatedAt = now;
      }
      await isar.linkEntitys.putAll(links);
    });
  }
}


