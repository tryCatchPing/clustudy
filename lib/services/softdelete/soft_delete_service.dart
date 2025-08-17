import 'dart:async';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/vault_models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';

/// Service for soft delete and restore operations.
///
/// - Exposes required public APIs (frozen interface):
///   - `softDeleteNote(int noteId)`
///   - `restoreNote(int noteId)` (restores to root if original location is unavailable)
/// - Publishes restore events so other services (e.g., link/graph) can react.
class SoftDeleteService {
  SoftDeleteService._internal();

  static final SoftDeleteService _instance = SoftDeleteService._internal();
  static SoftDeleteService get instance => _instance;

  final StreamController<NoteRestoreEvent> _restoreEventController =
      StreamController<NoteRestoreEvent>.broadcast();

  /// Stream of note-restore events. Consumers may listen to update their own state.
  Stream<NoteRestoreEvent> get onNoteRestored => _restoreEventController.stream;

  /// Soft-delete the given note by id.
  Future<void> softDeleteNote(int noteId) async {
    await NoteDbService.instance.softDeleteNote(noteId);
  }

  /// Restore a note. If original folder is missing/deleted, restore to root.
  ///
  /// Emits [NoteRestoreEvent]. If a fallback to root occurs, the event contains
  /// the previous folder id in [previousFolderId] and [restoredToRoot] set to true.
  Future<void> restoreNote(int noteId) async {
    final isar = await IsarDb.instance.open();

    int? previousFolderId;
    final before = await isar.collection<Note>().get(noteId);
    previousFolderId = before?.folderId;

    await NoteDbService.instance.restoreNote(noteId);

    bool restoredToRoot = false;
    final after = await isar.collection<Note>().get(noteId);
    if ((after?.folderId == null)) {
      restoredToRoot = true;
    }

    _restoreEventController.add(
      NoteRestoreEvent(
        noteId: noteId,
        previousFolderId: previousFolderId,
        restoredToRoot: restoredToRoot,
        emittedAt: DateTime.now(),
      ),
    );
  }

  /// Dispose resources when the app shuts down.
  Future<void> dispose() async {
    await _restoreEventController.close();
  }
}

class NoteRestoreEvent {
  NoteRestoreEvent({
    required this.noteId,
    required this.emittedAt,
    this.previousFolderId,
    this.restoredToRoot = false,
  });

  final int noteId;
  final int? previousFolderId;
  final bool restoredToRoot;
  final DateTime emittedAt;
}
