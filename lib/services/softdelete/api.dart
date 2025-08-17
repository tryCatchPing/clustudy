import 'package:it_contest/services/softdelete/soft_delete_service.dart';

// Frozen interface: Do not change signatures without contract update.
Future<void> softDeleteNote(int noteId) {
  return SoftDeleteService.instance.softDeleteNote(noteId);
}

// Frozen interface: Do not change signatures without contract update.
Future<void> restoreNote(int noteId) {
  return SoftDeleteService.instance.restoreNote(noteId);
}
