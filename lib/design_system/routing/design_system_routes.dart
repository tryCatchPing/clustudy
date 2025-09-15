import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/vault/vault_screen.dart';
import '../screens/notes/note_screen.dart';
import '../screens/graph/graph_screen.dart';
import '../screens/folder/folder_screen.dart';

class DesignSystemRoutes {
  DesignSystemRoutes._();

  static const String root = '/design-system';
  static const String home = '/design-system/home';
  static const String vault = '/design-system/vault';
  static const String notes = '/design-system/notes';
  static const String graph = '/design-system/graph';
  static const String folder = '/design-system/folder';

  static const String homeName = 'designHome';
  static const String vaultName = 'designVault';
  static const String notesName = 'designNotes';
  static const String graphName = 'designGraph';
  static const String folderName = 'designFolder';

  static final List<RouteBase> routes = [
    GoRoute(
      path: home,
      name: homeName,
      builder: (context, state) => const DesignHomeScreen(),
    ),
    GoRoute(
      path: vault,
      name: vaultName,
      builder: (context, state) => const DesignVaultScreen(),
    ),
    GoRoute(
      path: notes,
      name: notesName,
      builder: (context, state) => const DesignNoteScreen(),
    ),
    GoRoute(
      path: graph,
      name: graphName,
      builder: (context, state) => const DesignGraphScreen(),
    ),
    GoRoute(
      path: folder,
      name: folderName,
      builder: (context, state) => const DesignFolderScreen(),
    ),
  ];
}
