import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/vault_repository.dart';

/// VaultRepository DI 지점.
///
/// 구현체는 런타임에서 override 하며, 기본값은 미구현 상태입니다.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  throw UnimplementedError(
    'vaultRepositoryProvider is not bound. Provide an implementation at runtime.',
  );
});
