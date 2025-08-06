import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/canvas/routing/canvas_routes.dart';
import 'features/home/routing/home_routes.dart';
import 'features/notes/routing/notes_routes.dart';
import 'design_system/routing/design_system_routes.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

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
    );
  }
}
