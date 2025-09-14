import 'package:flutter/foundation.dart';
import '../data/note.dart';
import '../data/note_repository.dart';

class NoteStore extends ChangeNotifier {
  final NoteRepository _repo;
  NoteStore(this._repo);

  List<Note> _notes = [];
  bool _loaded = false;

  List<Note> byVault(String vaultId) =>
      _notes.where((n) => n.vaultId == vaultId).toList();

  Future<void> init() async {
    if (_loaded) return;
    _notes = await _repo.load();
    _loaded = true;
    notifyListeners();
  }

  Future<Note> createNote({required String vaultId, String? title}) async {
    final n = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vaultId: vaultId,
      title: title ?? '새 노트',
      createdAt: DateTime.now(),
    );
    _notes.add(n);
    await _repo.save(_notes);
    notifyListeners();
    return n;
  }

  Future<Note> createPdfNote({
    required String vaultId,
    required String fileName,
  }) async {
    final n = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vaultId: vaultId,
      title: fileName,
      createdAt: DateTime.now(),
      isPdf: true,
      pdfName: fileName,
    );
    _notes.add(n);
    await _repo.save(_notes);
    notifyListeners();
    return n;
  }
}
