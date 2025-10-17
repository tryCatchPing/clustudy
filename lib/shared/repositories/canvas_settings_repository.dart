import 'package:scribble/scribble.dart';

import '../models/canvas_settings.dart';

/// Repository abstraction for persisting global canvas settings.
abstract class CanvasSettingsRepository {
  /// Loads the persisted settings, falling back to defaults when absent.
  Future<CanvasSettings> load();

  /// Persists the provided settings changes while preserving unspecified fields.
  Future<void> update({
    bool? simulatePressure,
    ScribblePointerMode? pointerPolicy,
  });

  /// Allows implementations to release resources when no longer needed.
  void dispose() {}
}
