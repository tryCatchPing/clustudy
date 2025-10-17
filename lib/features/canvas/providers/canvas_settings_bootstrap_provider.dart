import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/canvas_settings.dart';

/// Provides the initial canvas settings loaded during app bootstrap.
///
/// Defaults to [CanvasSettings.defaults] and is overridden during app startup
/// with the persisted values from storage.
final canvasSettingsBootstrapProvider = Provider<CanvasSettings>((ref) {
  return const CanvasSettings.defaults();
});
