class RouteNames {
  static const home = 'home';
  static const vault = 'vault';
  static const note = 'note';
  static const graph = 'graph';
  static const folder = 'folder';
}

class RoutePaths {
  static const home = '/';
  static const vault = '/vault/:id';
  static const note = '/note/:id';
  static const folder = '/vault/:vaultId/folder/:folderId';
}
