import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'features/vaults/state/vault_store.dart';
import 'features/vaults/data/vault_repository.dart';
import 'features/notes/state/note_store.dart';
import 'features/notes/data/note_repository.dart';

void main() {
  final appRouter = AppRouter();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VaultStore(VaultRepository())..init()),
        ChangeNotifierProvider(create: (_) => NoteStore(NoteRepository())..init()),
      ],
      child: MyApp(router: appRouter.router),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
