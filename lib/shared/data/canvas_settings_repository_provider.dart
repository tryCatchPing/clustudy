import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'isar_canvas_settings_repository.dart';
import '../repositories/canvas_settings_repository.dart';

/// Global provider exposing the persisted canvas settings repository.
final canvasSettingsRepositoryProvider = Provider<CanvasSettingsRepository>((
  ref,
) {
  final repo = IsarCanvasSettingsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
