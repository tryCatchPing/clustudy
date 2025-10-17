import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'design_system/tokens/app_colors.dart';
import 'features/canvas/providers/canvas_settings_bootstrap_provider.dart';
import 'features/canvas/routing/canvas_routes.dart';
import 'features/home/routing/home_routes.dart';
import 'features/notes/routing/notes_routes.dart';
import 'features/vaults/routing/vault_graph_routes.dart';
import 'firebase_options.dart';
import 'shared/data/canvas_settings_repository_provider.dart';
import 'shared/data/isar_canvas_settings_repository.dart';
import 'shared/models/canvas_settings.dart';
import 'shared/routing/route_observer.dart';
import 'shared/services/firebase_service_providers.dart';
import 'shared/services/install_attribution_service.dart';
import 'shared/services/isar_database_service.dart';

Future<void> main() async {
  var crashlyticsEnabled = false;
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FirebaseAnalyticsLogger? analyticsLogger;
      if (isFirebaseAnalyticsSupportedPlatform()) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        analyticsLogger = FirebaseAnalyticsLogger(
          FirebaseAnalytics.instance,
        );
        await analyticsLogger.logAppLaunch();

        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        PlatformDispatcher.instance.onError = (error, stackTrace) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            fatal: true,
          );
          return true;
        };
        crashlyticsEnabled = true;
      }

      late final IsarCanvasSettingsRepository settingsRepository;
      late final CanvasSettings initialCanvasSettings;
      InstallAttributionPayload? installAttribution;

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
            library: 'clustudy main',
          ),
        );
        rethrow;
      }

      if (analyticsLogger != null &&
          defaultTargetPlatform == TargetPlatform.android) {
        try {
          final attributionService = InstallAttributionService(
            analyticsLogger: analyticsLogger,
          );
          installAttribution = await attributionService.bootstrap();
        } catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              context: ErrorDescription(
                'while initializing install attribution',
              ),
              library: 'clustudy main',
            ),
          );
        }
      }

      runApp(
        ProviderScope(
          overrides: [
            installAttributionBootstrapProvider.overrideWithValue(
              installAttribution,
            ),
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
      if (crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final analyticsObserver = ref.watch(firebaseAnalyticsObserverProvider);
  return GoRouter(
    initialLocation: '/notes',
    routes: [
      ...HomeRoutes.routes,
      ...NotesRoutes.routes,
      ...CanvasRoutes.routes,
      ...VaultGraphRoutes.routes,
    ],
    observers: [
      appRouteObserver,
      if (analyticsObserver != null) analyticsObserver,
    ],
    debugLogDiagnostics: true,
  );
});

/// 애플리케이션의 메인 위젯입니다.
class MyApp extends ConsumerWidget {
  /// [MyApp]의 생성자.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🎯 [MyApp] Building MyApp...');
    final router = ref.watch(goRouterProvider);

    debugPrint('🎯 [MyApp] Creating MaterialApp.router...');
    final app = MaterialApp.router(
      routerConfig: router,
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
