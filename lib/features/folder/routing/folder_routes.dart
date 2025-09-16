import 'package:go_router/go_router.dart';
import '../pages/folder_screen.dart';
import '../../../routing/route_names.dart';

class FolderRouteNames {
  static const folder = 'folder';
}

List<GoRoute> folderRoutes() => [
  GoRoute(
    path: RoutePaths.folder,
    name: FolderRouteNames.folder,
    builder: (_, s) => FolderScreen(
      vaultId: s.pathParameters['vaultId']!,
      folderId: s.pathParameters['folderId']!,
    ),
  ),
];
