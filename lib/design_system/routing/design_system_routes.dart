import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/vault/vault_screen.dart';
import '../screens/notes/note_screen.dart';

class DesignSystemRoutes {
  DesignSystemRoutes._();

  static const String root = '/design-system';
  static const String home = '/design-system/home';
  static const String vault = '/design-system/vault';
  static const String notes = '/design-system/notes';

  static const String homeName = 'designHome';
  static const String vaultName = 'designVault';
  static const String notesName = 'designNotes';

  /// Routes that expose the design-only showcase screens. These routes are
  /// consumed from the main router so the design artifacts remain accessible in
  /// builds without touching real feature code.
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
  ];
}
