// features/graph/routing/graph_routes.dart
import 'package:go_router/go_router.dart';
import '../pages/graph_screen.dart';
import '../../../routing/route_names.dart';

List<GoRoute> graphRoutes() => [
  GoRoute(
    path: '/graph/:id',
    name: RouteNames.graph,
    builder: (_, s) => GraphScreen(vaultId: s.pathParameters['id']!),
  ),
];
