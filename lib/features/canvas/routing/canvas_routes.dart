import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../pages/note_editor_screen.dart';

/// 🎨 캔버스 기능 관련 라우트 설정
///
/// 노트 편집 (캔버스) 관련 라우트를 여기서 관리합니다.
class CanvasRoutes {
  /// 캔버스 기능과 관련된 모든 라우트 정의.
  static List<RouteBase> routes = [
    // 특정 노트 편집 페이지 (/notes/:noteId/edit)
    GoRoute(
      path: AppRoutes.noteEdit,
      name: AppRoutes.noteEditName,
      pageBuilder: (context, state) {
        final noteId = state.pathParameters['noteId']!;
        debugPrint('📝 노트 편집 페이지: noteId = $noteId');
        // Use GoRouter-provided unique pageKey to avoid duplicate
        // keys when the same noteId is pushed multiple times.
        return MaterialPage(
          key: state.pageKey,
          name: AppRoutes.noteEditName,
          maintainState: false,
          child: NoteEditorScreen(
            noteId: noteId,
            routeId: (state.pageKey).value,
          ),
        );
      },
    ),
  ];
}
