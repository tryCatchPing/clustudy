import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import '../../../shared/data/canvas_settings_repository_provider.dart';
import 'canvas_settings_bootstrap_provider.dart';

/// Global pointer input policy for the app with persistence support.
///
/// Values map to Scribble's allowed pointer modes:
/// - all: finger/mouse/trackpad/stylus
/// - penOnly: stylus-only drawing (finger taps can still be used by UI)
final pointerPolicyProvider =
    StateNotifierProvider<PointerPolicyNotifier, ScribblePointerMode>(
      PointerPolicyNotifier.new,
    );

/// Manages the pointer policy state and persists updates.
class PointerPolicyNotifier extends StateNotifier<ScribblePointerMode> {
  PointerPolicyNotifier(this._ref)
    : super(
        _ref.read(canvasSettingsBootstrapProvider).pointerPolicy,
      );

  final Ref _ref;

  /// Updates the policy and persists the new configuration.
  void setPolicy(ScribblePointerMode mode) {
    if (mode == state) {
      return;
    }
    state = mode;

    final repository = _ref.read(canvasSettingsRepositoryProvider);
    unawaited(
      repository.update(pointerPolicy: mode).catchError((error, stackTrace) {
        debugPrint(
          '⚠️ [PointerPolicyNotifier] Failed to persist pointer policy: $error',
        );
      }),
    );
  }
}
