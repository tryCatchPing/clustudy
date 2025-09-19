import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/graph/routing/graph_routes.dart';
import '../features/home/routing/home_routes.dart';
import '../features/notes/routing/notes_routes.dart';
import '../features/vaults/routing/vault_routes.dart';
import '../features/folder/routing/folder_routes.dart';
import '../features/notes/pages/note_pages_screen.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      ...homeRoutes(),
      ...vaultRoutes(),
      ...noteRoutes(),
      ...graphRoutes(),
      ...folderRoutes(),
      GoRoute(
  path: '/note-pages/:noteId',
  builder: (context, state) {
    final noteId = state.pathParameters['noteId']!;
    final noteTitle = state.extra is String ? state.extra as String : null;
    return NotePagesScreen(
      title: noteTitle ?? '노트',
      noteId: noteId,
      initialPages: const [], // TODO: noteId 기반으로 불러오기
    );
  },
),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
