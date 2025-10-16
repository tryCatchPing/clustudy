import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../pages/home_screen.dart';

/// 🏠 홈 기능 관련 라우트 설정
///
/// 홈페이지와 PDF 캔버스 관련 라우트를 관리합니다.
class HomeRoutes {
  /// 홈 기능 관련 라우트 목록을 반환합니다.
  static List<RouteBase> routes = [
    // Root 경로 - /notes로 redirect
    GoRoute(
      path: '/',
      redirect: (context, state) => AppRoutes.noteList,
    ),
    // 홈 페이지 (코드 보존용)
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.homeName,
      builder: (context, state) => const HomeScreen(),
    ),
  ];
}
