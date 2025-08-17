import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:it_contest/features/canvas/routing/canvas_routes.dart';
import 'package:it_contest/features/db/migrations/migration_runner.dart';
import 'package:it_contest/features/db/seed/seed_runner.dart';
import 'package:it_contest/features/home/routing/home_routes.dart';
import 'package:it_contest/features/notes/data/notes_repository_provider.dart';
import 'package:it_contest/features/notes/routing/notes_routes.dart';
import 'package:it_contest/shared/services/backup_service.dart';
import 'package:it_contest/shared/services/maintenance_jobs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Provider를 통한 데이터베이스 관리로 대체
  // DB 초기화는 Provider에서 자동으로 처리됨

  runApp(const ProviderScope(child: MyApp()));
}

// 데이터베이스 초기화는 Provider에서 처리됨

final _router = GoRouter(
  routes: [
    // 홈 관련 라우트 (홈페이지, PDF 캔버스)
    ...HomeRoutes.routes,
    // 노트 관련 라우트 (노트 목록)
    ...NotesRoutes.routes,
    // 캔버스 관련 라우트 (노트 편집)
    ...CanvasRoutes.routes,
  ],
  debugLogDiagnostics: true,
);

/// 애플리케이션의 메인 위젯입니다.
class MyApp extends ConsumerWidget {
  /// [MyApp]의 생성자.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: _router,
      builder: (context, child) {
        // Provider를 통해 DB 초기화 보장
        return DatabaseInitializer(
          child: AppLifecycleManager(child: child),
        );
      },
    );
  }
}

/// 데이터베이스 초기화를 Provider를 통해 처리하는 위젯
class DatabaseInitializer extends ConsumerWidget {
  const DatabaseInitializer({super.key, required this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isar Provider를 watch하여 DB 인스턴스 초기화 (Future)
    final isarFuture = ref.watch(isarProvider);

    return FutureBuilder(
      future: isarFuture,
      builder: (context, isarSnapshot) {
        if (isarSnapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('데이터베이스 연결 중...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (isarSnapshot.hasError) {
          final error = isarSnapshot.error;
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('데이터베이스 초기화 실패: $error'),
                  ],
                ),
              ),
            ),
          );
        }

        // DB가 성공적으로 초기화된 경우 추가 초기 설정 수행
        return FutureBuilder<void>(
          future: _runInitialSetup(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return child ?? const SizedBox.shrink();
            }
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('데이터베이스 초기화 중...'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 마이그레이션과 시딩을 수행합니다
  Future<void> _runInitialSetup() async {
    await MigrationRunner.instance.runMigrationsIfNeeded();
    await SeedRunner.instance.ensureInitialSeed();
  }
}

/// 앱 생명주기를 관리하는 위젯 (Provider 기반)
class AppLifecycleManager extends ConsumerStatefulWidget {
  const AppLifecycleManager({super.key, required this.child});
  final Widget? child;

  @override
  ConsumerState<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends ConsumerState<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Start periodic backup scheduler
    BackupService.instance.startScheduler();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackupService.instance.stopScheduler();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Provider를 통해 DB 정리
      ref.invalidate(isarProvider);
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
