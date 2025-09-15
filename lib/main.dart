import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/folder/data/folder_repository.dart';
// Folder (폴더 기능 쓰는 경우)
import 'features/folder/state/folder_store.dart';
import 'features/notes/data/note_repository.dart';
// Note (복수 폴더인 경우)
import 'features/notes/state/note_store.dart';
import 'features/vaults/data/vault_repository.dart';
// Vault
import 'features/vaults/state/vault_store.dart';
// Router
import 'routing/app_router.dart';

void main() {
  final appRouter = AppRouter();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VaultStore(VaultRepository())..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteStore(NoteRepository())..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => FolderStore(FolderRepository())..init(),
        ),
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
