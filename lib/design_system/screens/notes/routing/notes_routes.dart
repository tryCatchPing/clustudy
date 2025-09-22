import 'package:go_router/go_router.dart';

import '../../../routing/route_names.dart';
import '../pages/note_screen.dart';

List<GoRoute> noteRoutes() => [
  GoRoute(
    path: '/note/:id',
    name: RouteNames.note, 
    builder: (_, state) => NoteScreen(
      noteId: state.pathParameters['id']!,
    ),
  ),
];
