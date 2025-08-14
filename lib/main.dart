import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/canvas/routing/canvas_routes.dart';
import 'features/db/isar_db.dart';
import 'shared/services/backup_service.dart';
import 'shared/services/maintenance_jobs.dart';
import 'shared/services/crypto_key_service.dart';
import 'features/home/routing/home_routes.dart';
import 'features/notes/routing/notes_routes.dart';
import 'design_system/routing/design_system_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load encryption key if available; don't block app on failure
  List<int>? key;
  try {
    key = await CryptoKeyService.instance.loadKey();
  } catch (_) {}
  await IsarDb.instance.open(encryptionKey: key);
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  routes: [
    // 홈 관련 라우트 (홈페이지, PDF 캔버스)
    ...HomeRoutes.routes,
    // 노트 관련 라우트 (노트 목록)
    ...NotesRoutes.routes,
    // 캔버스 관련 라우트 (노트 편집)
    ...CanvasRoutes.routes,
    // 디자인 시스템 데모 라우트 (컴포넌트 쇼케이스, Figma 재현)
    ...DesignSystemRoutes.routes,
  ],
  debugLogDiagnostics: true,
);

/// 애플리케이션의 메인 위젯입니다.
class MyApp extends StatelessWidget {
  /// [MyApp]의 생성자.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      builder: (context, child) => DBLifecycle(child: child),
    );
  }
}

class DBLifecycle extends StatefulWidget {
  const DBLifecycle({super.key, required this.child});
  final Widget? child;

  @override
  State<DBLifecycle> createState() => _DBLifecycleState();
}

class _DBLifecycleState extends State<DBLifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Close DB when app is detached to avoid file descriptor leaks
      IsarDb.instance.close();
    } else if (state == AppLifecycleState.resumed) {
      // Run due backup and maintenance when app comes to foreground
      BackupService.instance.runIfDue();
      MaintenanceJobs.instance.purgeRecycleBin();
      MaintenanceJobs.instance.trimSnapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
