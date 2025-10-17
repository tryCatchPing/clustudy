import 'package:scribble/scribble.dart';

/// Immutable representation of persisted canvas settings.
class CanvasSettings {
  /// Creates a new configuration.
  const CanvasSettings({
    required this.simulatePressure,
    required this.pointerPolicy,
  });

  /// Default configuration used when no persisted value exists.
  const CanvasSettings.defaults()
    : simulatePressure = false,
      pointerPolicy = ScribblePointerMode.all;

  /// Whether simulated pressure sensitivity is enabled.
  final bool simulatePressure;

  /// Pointer policy applied to the canvas.
  final ScribblePointerMode pointerPolicy;

  /// Convenience helper for producing modified copies.
  CanvasSettings copyWith({
    bool? simulatePressure,
    ScribblePointerMode? pointerPolicy,
  }) {
    return CanvasSettings(
      simulatePressure: simulatePressure ?? this.simulatePressure,
      pointerPolicy: pointerPolicy ?? this.pointerPolicy,
    );
  }
}
