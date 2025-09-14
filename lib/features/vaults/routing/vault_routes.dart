import 'package:go_router/go_router.dart';
import '../pages/vault_screen.dart';
import '../../../routing/route_names.dart';

List<GoRoute> vaultRoutes() => [
  GoRoute(
    path: RoutePaths.vault,
    name: RouteNames.vault,
    builder: (_, state) => VaultScreen(
      vaultId: state.pathParameters['id']!,
    ),
  ),
];

// 네비게이션 헬퍼(선택)
String vaultPath(String id) => '/vault/$id';
