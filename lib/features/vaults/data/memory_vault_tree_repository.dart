import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/repositories/vault_tree_repository.dart';
import '../../../shared/services/name_normalizer.dart';
import '../models/folder_model.dart';
import '../models/note_placement.dart';
import '../models/vault_item.dart';
import '../models/vault_model.dart';

/// 간단한 인메모리 VaultTreeRepository 구현.
///
/// - 앱 실행 중 메모리에만 유지됩니다.
/// - 성능/동시성 최적화는 고려하지 않습니다.
class MemoryVaultTreeRepository implements VaultTreeRepository {
  final Map<String, VaultModel> _vaults = <String, VaultModel>{};
  final Map<String, FolderModel> _folders = <String, FolderModel>{};

  /// 노트 배치(트리)용 경량 메타 저장소 (퍼블릭 NotePlacement 사용)
  final Map<String, NotePlacement> _notes = <String, NotePlacement>{};

  final _vaultsController = StreamController<List<VaultModel>>.broadcast();

  /// 폴더 자식(폴더+노트) 스트림 컨트롤러
  final Map<String, StreamController<List<VaultItem>>> _childrenControllers =
      <String, StreamController<List<VaultItem>>>{};

  static const _uuid = Uuid();

  MemoryVaultTreeRepository() {
    _ensureDefaultVault();
    _emitVaults();
  }

  //////////////////////////////////////////////////////////////////////////////
  // Vault
  //////////////////////////////////////////////////////////////////////////////
  @override
  Stream<List<VaultModel>> watchVaults() async* {
    yield _currentVaults();
    yield* _vaultsController.stream;
  }

  @override
  Future<VaultModel?> getVault(String vaultId) async => _vaults[vaultId];

  @override
  Future<FolderModel?> getFolder(String folderId) async => _folders[folderId];

  @override
  Future<VaultModel> createVault(String name) async {
    final normalized = NameNormalizer.normalize(name);
    _ensureUniqueVaultName(normalized);
    final id = _uuid.v4();
    final now = DateTime.now();
    final v = VaultModel(
      vaultId: id,
      name: normalized,
      createdAt: now,
      updatedAt: now,
    );
    _vaults[id] = v;
    _emitVaults();
    debugPrint('🗃️ [VaultRepo] createVault id=$id name=$normalized');
    return v;
  }

  @override
  Future<void> renameVault(String vaultId, String newName) async {
    final v = _vaults[vaultId];
    if (v == null) throw Exception('Vault not found: $vaultId');
    final normalized = NameNormalizer.normalize(newName);
    _ensureUniqueVaultName(normalized, excludeVaultId: vaultId);
    _vaults[vaultId] = v.copyWith(name: normalized, updatedAt: DateTime.now());
    _emitVaults();
  }

  @override
  Future<void> deleteVault(String vaultId) async {
    final v = _vaults.remove(vaultId);
    if (v == null) return;
    // cascade: remove folders and notes placement
    _folders.removeWhere((_, f) => f.vaultId == vaultId);
    _notes.removeWhere((_, n) => n.vaultId == vaultId);
    _emitVaults();
    // Clear children streams for this vault scopes (emit empty once)
    final scopes = _allScopesForVault(vaultId);
    for (final k in scopes) {
      _emitChildren(vaultId, k);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Folder
  //////////////////////////////////////////////////////////////////////////////
  @override
  Stream<List<VaultItem>> watchFolderChildren(
    String vaultId, {
    String? parentFolderId,
  }) async* {
    final key = _scopeKey(vaultId, parentFolderId);
    final c = _ensureChildrenController(key);
    // initial (emit after subscription to avoid losing first event)
    yield _collectChildren(vaultId, parentFolderId);
    yield* c.stream;
  }

  @override
  Future<FolderModel> createFolder(
    String vaultId, {
    String? parentFolderId,
    required String name,
  }) async {
    _assertVaultExists(vaultId);
    if (parentFolderId != null) {
      _assertFolderExists(parentFolderId);
      _assertSameVaultFolder(parentFolderId, vaultId);
    }
    final normalized = NameNormalizer.normalize(name);
    _ensureUniqueFolderName(vaultId, parentFolderId, normalized);
    final id = _uuid.v4();
    final now = DateTime.now();
    final f = FolderModel(
      folderId: id,
      vaultId: vaultId,
      name: normalized,
      parentFolderId: parentFolderId,
      createdAt: now,
      updatedAt: now,
    );
    _folders[id] = f;
    _emitChildren(vaultId, parentFolderId);
    debugPrint('📁 [VaultRepo] createFolder id=$id name=$normalized');
    return f;
  }

  @override
  Future<void> renameFolder(String folderId, String newName) async {
    final f = _folders[folderId];
    if (f == null) throw Exception('Folder not found: $folderId');
    final normalized = NameNormalizer.normalize(newName);
    _ensureUniqueFolderName(
      f.vaultId,
      f.parentFolderId,
      normalized,
      excludeFolderId: folderId,
    );
    final updated = f.copyWith(name: normalized, updatedAt: DateTime.now());
    _folders[folderId] = updated;
    _emitChildren(updated.vaultId, updated.parentFolderId);
  }

  @override
  Future<void> moveFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    final f = _folders[folderId];
    if (f == null) throw Exception('Folder not found: $folderId');

    final oldParent = f.parentFolderId;
    if (newParentFolderId == oldParent) return; // no-op

    if (newParentFolderId != null) {
      _assertFolderExists(newParentFolderId);
      _assertSameVaultFolder(newParentFolderId, f.vaultId);
      // cycle check: new parent cannot be self or descendant of self
      if (newParentFolderId == folderId ||
          _isDescendant(newParentFolderId, folderId)) {
        throw Exception('Cycle detected: cannot move into self/descendant');
      }
    }

    // name uniqueness in new parent scope
    _ensureUniqueFolderName(
      f.vaultId,
      newParentFolderId,
      f.name,
      excludeFolderId: folderId,
    );

    final updated = f.copyWith(
      parentFolderId: newParentFolderId,
      updatedAt: DateTime.now(),
    );
    _folders[folderId] = updated;
    _emitChildren(updated.vaultId, oldParent);
    _emitChildren(updated.vaultId, newParentFolderId);
  }

  @override
  Future<void> deleteFolder(String folderId) async {
    final f = _folders[folderId];
    if (f == null) return;
    final vaultId = f.vaultId;
    final parent = f.parentFolderId;

    // collect subtree
    final toDeleteFolders = <String>{};
    void dfs(String id) {
      toDeleteFolders.add(id);
      for (final child in _folders.values) {
        if (child.vaultId == vaultId && child.parentFolderId == id) {
          dfs(child.folderId);
        }
      }
    }

    dfs(folderId);

    // collect notes under these folders
    final noteIds = _notes.entries
        .where(
          (e) =>
              e.value.vaultId == vaultId &&
              toDeleteFolders.contains(e.value.parentFolderId),
        )
        .map((e) => e.key)
        .toList();

    for (final id in toDeleteFolders) {
      _folders.remove(id);
    }
    for (final nid in noteIds) {
      _notes.remove(nid);
    }

    // emit for affected scopes: parent of deleted folder and all ancestors
    _emitChildren(vaultId, parent);
    // Also emit children for each deleted folder scope (now empty)
    for (final id in toDeleteFolders) {
      _emitChildren(vaultId, id);
    }
  }

  @override
  Future<List<FolderModel>> getFolderAncestors(String folderId) async {
    final ancestors = <FolderModel>[];
    var current = _folders[folderId];
    while (current != null) {
      ancestors.add(current);
      final parentId = current.parentFolderId;
      current = parentId != null ? _folders[parentId] : null;
    }
    return ancestors.reversed.toList(growable: false);
  }

  @override
  Future<List<FolderModel>> getFolderDescendants(String folderId) async {
    final descendants = <FolderModel>[];
    final queue = <String>[folderId];
    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final children = _folders.values.where(
        (f) => f.parentFolderId == currentId,
      );
      for (final child in children) {
        descendants.add(child);
        queue.add(child.folderId);
      }
    }
    return List<FolderModel>.unmodifiable(descendants);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Note (tree-level)
  //////////////////////////////////////////////////////////////////////////////
  @override
  Future<String> createNote(
    String vaultId, {
    String? parentFolderId,
    required String name,
  }) async {
    _assertVaultExists(vaultId);
    if (parentFolderId != null) {
      _assertFolderExists(parentFolderId);
      _assertSameVaultFolder(parentFolderId, vaultId);
    }
    final normalized = NameNormalizer.normalize(name);
    _ensureUniqueNoteName(vaultId, parentFolderId, normalized);
    final id = _uuid.v4();
    final now = DateTime.now();
    _notes[id] = NotePlacement(
      noteId: id,
      vaultId: vaultId,
      parentFolderId: parentFolderId,
      name: normalized,
      createdAt: now,
      updatedAt: now,
    );
    _emitChildren(vaultId, parentFolderId);
    debugPrint('📝 [VaultRepo] createNote id=$id name=$normalized');
    return id;
  }

  @override
  Future<void> renameNote(String noteId, String newName) async {
    final n = _notes[noteId];
    if (n == null) throw Exception('Note not found: $noteId');
    final normalized = NameNormalizer.normalize(newName);
    _ensureUniqueNoteName(
      n.vaultId,
      n.parentFolderId,
      normalized,
      excludeNoteId: noteId,
    );
    _notes[noteId] = n.copyWith(name: normalized, updatedAt: DateTime.now());
    _emitChildren(n.vaultId, n.parentFolderId);
  }

  @override
  Future<void> moveNote({
    required String noteId,
    String? newParentFolderId,
  }) async {
    final n = _notes[noteId];
    if (n == null) throw Exception('Note not found: $noteId');
    final oldParent = n.parentFolderId;
    if (newParentFolderId == oldParent) return;
    if (newParentFolderId != null) {
      _assertFolderExists(newParentFolderId);
      _assertSameVaultFolder(newParentFolderId, n.vaultId);
    }
    // uniqueness in target scope
    _ensureUniqueNoteName(
      n.vaultId,
      newParentFolderId,
      n.name,
      excludeNoteId: noteId,
    );
    _notes[noteId] = n.copyWith(
      parentFolderId: newParentFolderId,
      updatedAt: DateTime.now(),
    );
    _emitChildren(n.vaultId, oldParent);
    _emitChildren(n.vaultId, newParentFolderId);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    final n = _notes.remove(noteId);
    if (n == null) return;
    _emitChildren(n.vaultId, n.parentFolderId);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Placement 조회/등록
  //////////////////////////////////////////////////////////////////////////////
  @override
  Future<NotePlacement?> getNotePlacement(String noteId) async {
    return _notes[noteId];
  }

  @override
  Future<void> registerExistingNote({
    required String noteId,
    required String vaultId,
    String? parentFolderId,
    required String name,
  }) async {
    _assertVaultExists(vaultId);
    if (parentFolderId != null) {
      _assertFolderExists(parentFolderId);
      _assertSameVaultFolder(parentFolderId, vaultId);
    }
    if (_notes.containsKey(noteId)) {
      throw Exception('Note already exists: $noteId');
    }
    final normalized = NameNormalizer.normalize(name);
    _ensureUniqueNoteName(vaultId, parentFolderId, normalized);
    final now = DateTime.now();
    _notes[noteId] = NotePlacement(
      noteId: noteId,
      vaultId: vaultId,
      parentFolderId: parentFolderId,
      name: normalized,
      createdAt: now,
      updatedAt: now,
    );
    _emitChildren(vaultId, parentFolderId);
    debugPrint(
      '📝 [VaultRepo] registerExistingNote id=$noteId name=$normalized',
    );
  }

  @override
  Future<List<NotePlacement>> searchNotes(
    String vaultId,
    String query, {
    bool exact = false,
    int limit = 50,
    Set<String>? excludeNoteIds,
  }) async {
    final normalizedQuery = NameNormalizer.compareKey(query.trim());
    final excludes = excludeNoteIds ?? const <String>{};
    final scored = <_ScoredPlacement>[];

    for (final placement in _notes.values) {
      if (placement.vaultId != vaultId) {
        continue;
      }
      if (excludes.contains(placement.noteId)) {
        continue;
      }

      final key = NameNormalizer.compareKey(placement.name);
      int score;
      if (normalizedQuery.isEmpty) {
        score = 0;
      } else if (exact) {
        if (key == normalizedQuery) {
          score = 3;
        } else {
          continue;
        }
      } else {
        if (key == normalizedQuery) {
          score = 3;
        } else if (key.startsWith(normalizedQuery)) {
          score = 2;
        } else if (key.contains(normalizedQuery)) {
          score = 1;
        } else {
          continue;
        }
      }

      scored.add(_ScoredPlacement(score: score, placement: placement));
    }

    if (normalizedQuery.isEmpty) {
      scored.sort(
        (a, b) => NameNormalizer.compareKey(
          a.placement.name,
        ).compareTo(NameNormalizer.compareKey(b.placement.name)),
      );
    } else {
      scored.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return NameNormalizer.compareKey(
          a.placement.name,
        ).compareTo(NameNormalizer.compareKey(b.placement.name));
      });
    }

    final iterable = limit > 0 ? scored.take(limit) : scored;
    return iterable.map((e) => e.placement).toList(growable: false);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Utilities
  //////////////////////////////////////////////////////////////////////////////
  @override
  void dispose() {
    if (!_vaultsController.isClosed) _vaultsController.close();
    for (final c in _childrenControllers.values) {
      if (!c.isClosed) c.close();
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Helpers
  //////////////////////////////////////////////////////////////////////////////
  void _ensureDefaultVault() {
    if (_vaults.isNotEmpty) return;
    final now = DateTime.now();
    final v = VaultModel(
      vaultId: 'default',
      name: 'Default Vault',
      createdAt: now,
      updatedAt: now,
    );
    _vaults[v.vaultId] = v;
  }

  void _emitVaults() {
    _vaultsController.add(_currentVaults());
  }

  List<VaultModel> _currentVaults() {
    final list = _vaults.values.toList();
    // 이름 오름차순
    list.sort(
      (a, b) => NameNormalizer.compareKey(
        a.name,
      ).compareTo(NameNormalizer.compareKey(b.name)),
    );
    return List<VaultModel>.unmodifiable(list);
  }

  void _ensureUniqueVaultName(String name, {String? excludeVaultId}) {
    final lower = NameNormalizer.compareKey(name);
    final exists = _vaults.values.any(
      (v) =>
          v.vaultId != excludeVaultId &&
          NameNormalizer.compareKey(v.name) == lower,
    );
    if (exists) {
      throw Exception('Vault name already exists');
    }
  }

  StreamController<List<VaultItem>> _ensureChildrenController(String key) {
    return _childrenControllers.putIfAbsent(
      key,
      () => StreamController<List<VaultItem>>.broadcast(),
    );
  }

  String _scopeKey(String vaultId, String? parentFolderId) =>
      '$vaultId::${parentFolderId ?? 'root'}';

  void _emitChildren(String vaultId, String? parentFolderId) {
    final key = _scopeKey(vaultId, parentFolderId);
    final c = _ensureChildrenController(key);
    if (!c.isClosed) c.add(_collectChildren(vaultId, parentFolderId));
  }

  List<VaultItem> _collectChildren(String vaultId, String? parentFolderId) {
    final items = <VaultItem>[];
    final nowFolders = _folders.values.where(
      (f) => f.vaultId == vaultId && f.parentFolderId == parentFolderId,
    );
    for (final f in nowFolders) {
      items.add(
        VaultItem(
          type: VaultItemType.folder,
          vaultId: vaultId,
          id: f.folderId,
          name: f.name,
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
        ),
      );
    }
    final nowNotes = _notes.values.where(
      (n) => n.vaultId == vaultId && n.parentFolderId == parentFolderId,
    );
    for (final n in nowNotes) {
      items.add(
        VaultItem(
          type: VaultItemType.note,
          vaultId: vaultId,
          id: n.noteId,
          name: n.name,
          createdAt: n.createdAt,
          updatedAt: n.updatedAt,
        ),
      );
    }
    // sort: folder first, then note; by name asc (case-insensitive)
    items.sort((a, b) {
      final int typeA = a.type == VaultItemType.folder ? 0 : 1;
      final int typeB = b.type == VaultItemType.folder ? 0 : 1;
      if (typeA != typeB) return typeA - typeB;
      return NameNormalizer.compareKey(
        a.name,
      ).compareTo(NameNormalizer.compareKey(b.name));
    });
    return List<VaultItem>.unmodifiable(items);
  }

  Set<String?> _allScopesForVault(String vaultId) {
    final scopes = <String?>{null};
    for (final f in _folders.values) {
      if (f.vaultId == vaultId) scopes.add(f.parentFolderId);
    }
    for (final n in _notes.values) {
      if (n.vaultId == vaultId) scopes.add(n.parentFolderId);
    }
    return scopes;
  }

  void _assertVaultExists(String vaultId) {
    if (!_vaults.containsKey(vaultId)) {
      throw Exception('Vault not found: $vaultId');
    }
  }

  void _assertFolderExists(String folderId) {
    if (!_folders.containsKey(folderId)) {
      throw Exception('Folder not found: $folderId');
    }
  }

  void _assertSameVaultFolder(String folderId, String vaultId) {
    final f = _folders[folderId]!;
    if (f.vaultId != vaultId) {
      throw Exception('Folder belongs to different vault');
    }
  }

  bool _isDescendant(String nodeId, String potentialAncestorId) {
    // DFS upwards from nodeId to root and check if we hit potentialAncestorId
    String? current = nodeId;
    while (current != null) {
      if (current == potentialAncestorId) return true;
      final f = _folders[current];
      current = f?.parentFolderId;
    }
    return false;
  }

  void _ensureUniqueFolderName(
    String vaultId,
    String? parentFolderId,
    String name, {
    String? excludeFolderId,
  }) {
    final lower = NameNormalizer.compareKey(name);
    final exists = _folders.values.any(
      (f) =>
          f.vaultId == vaultId &&
          f.parentFolderId == parentFolderId &&
          f.folderId != excludeFolderId &&
          NameNormalizer.compareKey(f.name) == lower,
    );
    if (exists) {
      throw Exception('Folder name already exists in this location');
    }
  }

  void _ensureUniqueNoteName(
    String vaultId,
    String? parentFolderId,
    String name, {
    String? excludeNoteId,
  }) {
    final lower = NameNormalizer.compareKey(name);
    final exists = _notes.values.any(
      (n) =>
          n.vaultId == vaultId &&
          n.parentFolderId == parentFolderId &&
          n.noteId != excludeNoteId &&
          NameNormalizer.compareKey(n.name) == lower,
    );
    if (exists) {
      throw Exception('Note name already exists in this location');
    }
  }

  // Name normalization moved to NameNormalizer (shared service).
}

class _ScoredPlacement {
  final int score;
  final NotePlacement placement;

  const _ScoredPlacement({required this.score, required this.placement});
}
