import 'package:flutter/foundation.dart';
import '../data/vault.dart';
import '../data/vault_repository.dart';

class VaultStore extends ChangeNotifier {
  Vault? byId(String id) {
  final i = _vaults.indexWhere((v) => v.id == id);
  return i == -1 ? null : _vaults[i];
  }

  Vault? get temporaryVault {
    final i = _vaults.indexWhere((v) => v.isTemporary);
    return i == -1 ? null : _vaults[i];
  }

  final VaultRepository _repo;
  VaultStore(this._repo);

  List<Vault> _vaults = [];
  List<Vault> get vaults => _vaults;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> init() async {
    if (_loaded) return;
    _vaults = await _repo.load();

    // 첫 실행 시 임시 vault 시드
    if (_vaults.isEmpty) {
      _vaults = [Vault.temp()];
      await _repo.save(_vaults);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> createVault(String name) async {
    _vaults.add(Vault(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    ));
    await _repo.save(_vaults);
    notifyListeners();
  }

  Future<void> renameVault(String id, String newName) async {
  final i = _vaults.indexWhere((v) => v.id == id);
  if (i == -1) return;
  _vaults[i] = Vault(
    id: _vaults[i].id,
    name: newName,
    createdAt: _vaults[i].createdAt,
    isTemporary: _vaults[i].isTemporary,
  );
  await _repo.save(_vaults);
  notifyListeners();
  }

  Future<Vault> ensureTempVault() async {
    final t = temporaryVault;
    if (t != null) return t;

    final temp = Vault.temp();
    _vaults.insert(0, temp);          
    await _repo.save(_vaults);
    notifyListeners();
    return temp;
  }
}
