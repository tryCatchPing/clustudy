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

  Future<Note> createNote({required String vaultId, String? folderId, String? title}) async {
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

  Future<void> renameNote({
  required String id,
  required String newTitle,
  }) async {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i == -1) return;

    final old = _notes[i];

    final updated = Note(
      id: old.id,
      vaultId: old.vaultId,
      title: newTitle,
      createdAt: old.createdAt,  
      isPdf: old.isPdf,
      pdfName: old.pdfName,
      // folderId 등 다른 필드가 있으면 그대로 복사
    );

  _notes = [
    ..._notes.sublist(0, i),
    updated,
    ..._notes.sublist(i + 1),
  ];

  await _repo.save(_notes);
  notifyListeners();
}

  Future<Note> createPdfNote({
    required String vaultId,
    String? folderId,
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
