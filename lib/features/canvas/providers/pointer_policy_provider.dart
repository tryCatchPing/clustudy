import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

/// Global pointer input policy for the app.
///
/// Values map to Scribble's allowed pointer modes:
/// - all: finger/mouse/trackpad/stylus
/// - penOnly: stylus-only drawing (finger taps can still be used by UI)
final pointerPolicyProvider = StateProvider<ScribblePointerMode>(
  (ref) => ScribblePointerMode.all,
);
