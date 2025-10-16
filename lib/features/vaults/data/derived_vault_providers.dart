import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/folder_model.dart';
import '../models/vault_item.dart';
import '../models/vault_model.dart';
import 'vault_tree_repository_provider.dart';

/// 현재 활성 Vault (라우트/브라우저 컨텍스트)
final currentVaultProvider = StateProvider<String?>((ref) => null);

/// 현재 폴더 (루트면 null). Vault 별 family 상태.
final currentFolderProvider = StateProvider.family<String?, String>(
  (ref, vaultId) => null,
);

/// Vault 목록 관찰
final vaultsProvider = StreamProvider<List<VaultModel>>((ref) {
  final repo = ref.watch(vaultTreeRepositoryProvider);
  return repo.watchVaults();
});

/// provider 키로 사용할 단순 스코프 타입
class FolderScope {
  final String vaultId;
  final String? parentFolderId;
  const FolderScope(this.vaultId, this.parentFolderId);

  @override
  bool operator ==(Object other) {
    return other is FolderScope &&
        other.vaultId == vaultId &&
        other.parentFolderId == parentFolderId;
  }

  @override
  int get hashCode => Object.hash(vaultId, parentFolderId);
}

/// 특정 폴더 하위 아이템(폴더+노트) 관찰. parentFolderId가 null이면 루트.
final vaultItemsProvider = StreamProvider.family<List<VaultItem>, FolderScope>(
  (ref, scope) {
    final repo = ref.watch(vaultTreeRepositoryProvider);
    return repo.watchFolderChildren(
      scope.vaultId,
      parentFolderId: scope.parentFolderId,
    );
  },
);

/// 특정 Vault 정보를 조회합니다.
final vaultByIdProvider = FutureProvider.family<VaultModel?, String>((
  ref,
  vaultId,
) {
  final repo = ref.watch(vaultTreeRepositoryProvider);
  return repo.getVault(vaultId);
});

/// 특정 폴더 정보를 조회합니다.
final folderByIdProvider = FutureProvider.family<FolderModel?, String>((
  ref,
  folderId,
) {
  final repo = ref.watch(vaultTreeRepositoryProvider);
  return repo.getFolder(folderId);
});
