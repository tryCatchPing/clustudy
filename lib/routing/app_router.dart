import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/routing/home_routes.dart';
import '../features/vaults/routing/vault_routes.dart';
import '../features/notes/routing/notes_routes.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      ...homeRoutes(),
      ...vaultRoutes(),
      ...noteRoutes(),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
}
