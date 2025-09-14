import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/pages/home_screen.dart';
import '../../features/vaults/pages/vault_screen.dart';
import '../../features/notes/pages/note_screen.dart';

// 필요 시 상태를 주입받아 redirect에 활용할 수도 있음.
class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/vault/:id',
        name: 'vault',
        builder: (context, state) =>
            VaultScreen(vaultId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/note/:id',
        name: 'note',
        builder: (context, state) =>
            NoteScreen(noteId: state.pathParameters['id']!),
      ),
    ],

    // 예: 첫 실행이면 온보딩으로 보내고 싶을 때 사용
    // redirect: (context, state) {
    //   final firstRun = context.read<AppCfg>().isFirstRun;
    //   if (firstRun && state.uri.toString() != '/onboarding') {
    //     return '/onboarding';
    //   }
    //   return null;
    // },

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
    debugLogDiagnostics: false,
  );
}
