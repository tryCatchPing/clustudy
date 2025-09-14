import 'package:go_router/go_router.dart';
import '../pages/home_screen.dart';
import '../../../routing/route_names.dart';

List<GoRoute> homeRoutes() => [
  GoRoute(
    path: RoutePaths.home,
    name: RouteNames.home,
    builder: (_, __) => const HomeScreen(),
  ),
];
