import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'design_system/tokens/app_colors.dart';
import 'features/canvas/providers/canvas_settings_bootstrap_provider.dart';
import 'features/canvas/routing/canvas_routes.dart';
import 'features/home/routing/home_routes.dart';
import 'features/notes/routing/notes_routes.dart';
import 'features/vaults/routing/vault_graph_routes.dart';
import 'shared/data/canvas_settings_repository_provider.dart';
import 'shared/data/isar_canvas_settings_repository.dart';
import 'shared/models/canvas_settings.dart';
import 'shared/routing/route_observer.dart';
import 'shared/services/isar_database_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  };

  await runZonedGuarded(
    () async {
      late final IsarCanvasSettingsRepository settingsRepository;
      late final CanvasSettings initialCanvasSettings;

      try {
        debugPrint('🗄️ [main] Initializing Isar database...');
        final isar = await IsarDatabaseService.getInstance();
        debugPrint('🗄️ [main] Isar database initialized');

        settingsRepository = IsarCanvasSettingsRepository(isar: isar);
        initialCanvasSettings = await settingsRepository.load();
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            context: ErrorDescription('while initializing the Isar database'),
            library: 'it_contest main',
          ),
        );
        rethrow;
      }

      runApp(
        ProviderScope(
          overrides: [
            canvasSettingsRepositoryProvider.overrideWithValue(
              settingsRepository,
            ),
            canvasSettingsBootstrapProvider.overrideWithValue(
              initialCanvasSettings,
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        fatal: true,
      );
    },
  );
}

final _router = GoRouter(
  initialLocation: '/notes',
  routes: [
    // 홈 관련 라우트 (홈페이지, PDF 캔버스)
    ...HomeRoutes.routes,
    // 노트 관련 라우트 (노트 목록)
    ...NotesRoutes.routes,
    // 캔버스 관련 라우트 (노트 편집)
    ...CanvasRoutes.routes,
    // Vault 그래프 관련 라우트
    ...VaultGraphRoutes.routes,
  ],
  observers: [appRouteObserver],
  debugLogDiagnostics: true,
);

/// 전역 GoRouter 인스턴스 접근용 (Provider에서 사용)
GoRouter get globalRouter => _router;

/// 애플리케이션의 메인 위젯입니다.
class MyApp extends ConsumerWidget {
  /// [MyApp]의 생성자.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🎯 [MyApp] Building MyApp...');

    debugPrint('🎯 [MyApp] Creating MaterialApp.router...');
    final app = MaterialApp.router(
      routerConfig: _router,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        useMaterial3: true,
      ),
    );
    debugPrint('🎯 [MyApp] MaterialApp.router created successfully');

    return app;
  }
}
