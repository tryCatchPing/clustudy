import 'package:go_router/go_router.dart';
import 'route_names.dart';

extension NavX on GoRouter {
  void goHome() => goNamed(RouteNames.home);
  void goVault(String id) => goNamed(RouteNames.vault, pathParameters: {'id': id});
  void goNote(String id)  => goNamed(RouteNames.note,  pathParameters: {'id': id});
}
