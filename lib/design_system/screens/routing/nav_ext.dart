import 'package:go_router/go_router.dart';
import 'route_names.dart';

extension NavX on GoRouter {
  void goHome() => goNamed(RouteNames.home);
  // 계층 깊이 이동: push 사용 (히스토리에 쌓기)
  Future<void> pushVault(String id) =>
      pushNamed(RouteNames.vault, pathParameters: {'id': id});

  Future<void> pushFolder(String vaultId, String folderId) =>
      pushNamed(RouteNames.folder, pathParameters: {
        'vaultId': vaultId,
        'folderId': folderId,
      });

  Future<void> pushNote(String id, {String? initialTitle}) {
   final normalized = (initialTitle?.trim().isEmpty ?? true)
       ? null
       : {'title': initialTitle!.trim()};
          return pushNamed(
     RouteNames.note,
     pathParameters: {'id': id},
     extra: normalized, // null이면 전달 안 됨
   );
 }


  void goGraph(String id) =>
      goNamed(RouteNames.graph, pathParameters: {'id': id});
}
