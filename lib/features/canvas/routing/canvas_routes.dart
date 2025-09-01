import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../pages/note_editor_screen.dart';
import '../providers/note_editor_provider.dart';

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
        debugPrint('📝 노트 편집 페이지: noteId = $noteId');
        return NoteEditorScreen(noteId: noteId);
      },
      onExit: (context, state) {
        // 라우트 탈출 시 세션 종료
        // onExit 콜백은 이 라우트를 벗어날 때 호출되므로 세션 정리에 이상적입니다.
        debugPrint('🏠 [CanvasRoutes] Exiting route, cleaning up session.');
        final container = ProviderScope.containerOf(context);
        container.read(noteSessionProvider.notifier).exitNote();
        return true; // onExit는 Future<bool>을 반환해야 함 (현재는 사용되지 않음)
      },
    ),
  ];
}
