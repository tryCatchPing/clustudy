import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/vault_tree_repository.dart';
import 'isar_vault_tree_repository.dart';

/// VaultTreeRepository DI 지점.
///
/// 기본 구현은 Isar 기반 저장소이며, 런타임/테스트에서 override 가능.
final vaultTreeRepositoryProvider = Provider<VaultTreeRepository>((ref) {
  final repo = IsarVaultTreeRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
