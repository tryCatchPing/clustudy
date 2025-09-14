import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';

/// 🔗 Vault 그래프 보기 라우트 설정
class VaultGraphRoutes {
  /// 라우트 목록
  static List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.vaultGraph,
      name: AppRoutes.vaultGraphName,
      builder: (context, state) => const _VaultGraphPlaceholderScreen(),
    ),
  ];
}

/// 임시 플레이스홀더 화면 (UI 별도 작업 전까지 빌드 유지용)
class _VaultGraphPlaceholderScreen extends StatelessWidget {
  const _VaultGraphPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Vault Graph View (준비 중)'),
      ),
    );
  }
}
