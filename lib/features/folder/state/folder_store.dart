import 'package:flutter/foundation.dart';
import '../data/folder.dart';
import '../data/folder_repository.dart';

class FolderStore extends ChangeNotifier {
  final FolderRepository _repo;
  FolderStore(this._repo);

  List<Folder> _folders = [];
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    _folders = await _repo.load();
    _loaded = true;
    notifyListeners();
  }

  List<Folder> byParent({required String vaultId, String? parentFolderId}) =>
      _folders.where((f) => f.vaultId == vaultId && f.parentFolderId == parentFolderId).toList();

  Future<Folder> createFolder({
    required String vaultId,
    String? parentFolderId,
    String name = '새 폴더',
  }) async {
    final f = Folder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vaultId: vaultId,
      name: name,
      createdAt: DateTime.now(),
      parentFolderId: parentFolderId,
    );
    _folders.add(f);
    await _repo.save(_folders);
    notifyListeners();
    return f;
  }

  Future<void> renameFolder({
  required String id,
  required String newName,
  }) async {
    final i = _folders.indexWhere((f) => f.id == id);
    if (i == -1) return;
  final old = _folders[i];
  final updated = Folder(
    id: old.id,
    vaultId: old.vaultId,
    name: newName,
    createdAt: old.createdAt,
    parentFolderId: old.parentFolderId,
  );

  _folders = [
    ..._folders.sublist(0, i),
    updated,
    ..._folders.sublist(i + 1),
  ];

  await _repo.save(_folders);
  notifyListeners();
}

  bool get isLoaded => _loaded;

  Folder? byId(String id) {
    final i = _folders.indexWhere((f) => f.id == id);
    return i == -1 ? null : _folders[i];
  }
}
