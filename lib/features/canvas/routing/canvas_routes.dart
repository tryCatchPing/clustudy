import 'package:flutter/foundation.dart';
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
      builder: (context, state) {
        final noteId = state.pathParameters['noteId']!;
        final fullPath = state.uri.path;
        final queryParams = state.uri.queryParameters;
        final pathParams = state.pathParameters;

        debugPrint('🏠 [CanvasRoutes] Route builder called');
        debugPrint('🏠 [CanvasRoutes] Full URI: ${state.uri}');
        debugPrint('🏠 [CanvasRoutes] Path: $fullPath');
        debugPrint('🏠 [CanvasRoutes] Path parameters: $pathParams');
        debugPrint('🏠 [CanvasRoutes] Query parameters: $queryParams');
        debugPrint('📝 노트 편집 페이지: noteId = $noteId');

        debugPrint('🏠 [CanvasRoutes] Creating NoteEditorScreen...');
        final screen = NoteEditorScreen(noteId: noteId);
        debugPrint('🏠 [CanvasRoutes] NoteEditorScreen created successfully');

        return screen;
      },
    ),
  ];
}
