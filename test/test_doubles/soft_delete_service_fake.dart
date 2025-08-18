import 'dart:async';

// The test needs this event class, so we import the real service file
// to get the definition for NoteRestoreEvent.
import 'package:it_contest/services/softdelete/soft_delete_service.dart';

/// A fake implementation of [SoftDeleteService] for testing purposes.
///
/// This class mimics the behavior of soft-deleting and restoring notes
/// by maintaining an in-memory set of deleted note IDs. It allows tests
/// to control and inspect the state without depending on the real database implementation.
class FakeSoftDeleteService {
  final Set<int> deletedNoteIds = {};

  final StreamController<NoteRestoreEvent> _restoreEventController =
      StreamController<NoteRestoreEvent>.broadcast();

  /// A stream that emits an event when a note is restored.
  Stream<NoteRestoreEvent> get onNoteRestored => _restoreEventController.stream;

  /// Marks a note as soft-deleted.
  Future<void> softDeleteNote(int noteId) async {
    deletedNoteIds.add(noteId);
  }

  /// Restores a soft-deleted note.
  ///
  /// If the note was previously marked as deleted, it is removed from the
  /// deleted set, and a [NoteRestoreEvent] is emitted.
  Future<void> restoreNote(int noteId) async {
    if (deletedNoteIds.contains(noteId)) {
      deletedNoteIds.remove(noteId);
      _restoreEventController.add(
        NoteRestoreEvent(
          noteId: noteId,
          emittedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Cleans up resources used by the fake service.
  void dispose() {
    _restoreEventController.close();
  }
}
