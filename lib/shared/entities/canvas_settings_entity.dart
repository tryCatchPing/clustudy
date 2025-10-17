import 'package:isar/isar.dart';

part 'canvas_settings_entity.g.dart';

/// Singleton collection storing global canvas-related settings.
@collection
class CanvasSettingsEntity {
  /// Fixed identifier because this collection stores a single row.
  Id id = CanvasSettingsEntity.singletonId;

  /// Whether simulated pressure sensitivity is enabled.
  bool simulatePressure = false;

  /// Index of [ScribblePointerMode]; stored as int for persistence.
  int pointerPolicyIndex = 0;

  /// Singleton row identifier used by the repository.
  static const int singletonId = 0;
}
