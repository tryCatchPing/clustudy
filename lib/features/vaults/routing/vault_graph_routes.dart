import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../pages/vault_graph_screen.dart';

/// 🔗 Vault 그래프 보기 라우트 설정
class VaultGraphRoutes {
  /// 라우트 목록
  static List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.vaultGraph,
      name: AppRoutes.vaultGraphName,
      builder: (context, state) => const VaultGraphScreen(),
    ),
  ];
}
