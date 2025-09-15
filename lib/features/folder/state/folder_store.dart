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

  bool get isLoaded => _loaded;

  Folder? byId(String id) {
    final i = _folders.indexWhere((f) => f.id == id);
    return i == -1 ? null : _folders[i];
  }
}
