import 'package:it_contest/services/softdelete/soft_delete_service.dart';

// Frozen interface: Do not change signatures without contract update.
/// Soft delete the note by id.
Future<void> softDeleteNote(int noteId) {
  return SoftDeleteService.instance.softDeleteNote(noteId);
}

// Frozen interface: Do not change signatures without contract update.
/// Restore the note by id. Restores to root if original folder is missing.
Future<void> restoreNote(int noteId) {
  return SoftDeleteService.instance.restoreNote(noteId);
}
