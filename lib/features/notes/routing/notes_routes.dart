import 'package:go_router/go_router.dart';
import 'package:it_contest/features/notes/pages/note_list_screen.dart';
import 'package:it_contest/shared/routing/app_routes.dart';

/// 📝 노트 기능 관련 라우트 설정
///
/// 노트 목록 관련 라우트를 여기서 관리합니다.
class NotesRoutes {
  /// 노트 관련 라우트 목록을 반환합니다.
  static List<RouteBase> routes = [
    // 노트 목록 페이지 (/notes)
    GoRoute(
      path: AppRoutes.noteList,
      name: AppRoutes.noteListName,
      builder: (context, state) => const NoteListScreen(),
    ),
  ];
}
