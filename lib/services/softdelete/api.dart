import 'package:it_contest/services/softdelete/soft_delete_service.dart';
import 'package:it_contest/features/notes/models/note_model.dart';

// Frozen interface: Do not change signatures without contract update.
/// Soft delete the note by id.
Future<void> softDeleteNote(NoteModel note) {
  return SoftDeleteService.instance.softDeleteNote(note);
}

// Frozen interface: Do not change signatures without contract update.
/// Restore the note by id. Restores to root if original folder is missing.
Future<void> restoreNote(NoteModel note) {
  return SoftDeleteService.instance.restoreNote(note);
}
