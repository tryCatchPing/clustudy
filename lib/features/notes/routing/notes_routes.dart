import 'package:go_router/go_router.dart';
import '../pages/note_screen.dart';
import '../../../routing/route_names.dart';

List<GoRoute> noteRoutes() => [
  GoRoute(
    path: '/note/:id',
    name: RouteNames.note, // ← goNamed에서 쓰는 이름과 반드시 일치!
    builder: (_, state) => NoteScreen(
      noteId: state.pathParameters['id']!,
    ),
  ),
];
