import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import 'pointer_policy_provider.dart';

/// 포인터 상태 스냅샷.
@immutable
class PointerSnapshot {
  const PointerSnapshot({
    this.totalPointers = 0,
    this.touchPointers = 0,
    this.stylusPointers = 0,
    this.mousePointers = 0,
    this.trackpadPointers = 0,
    this.linkerStylusActive = false,
  });

  final int totalPointers;
  final int touchPointers;
  final int stylusPointers;
  final int mousePointers;
  final int trackpadPointers;
  final bool linkerStylusActive;

  bool get hasStylus => stylusPointers > 0 || linkerStylusActive;
  bool get hasTouch => touchPointers > 0;
  bool get hasMultiplePointers => totalPointers >= 2;

  PointerSnapshot copyWith({
    int? totalPointers,
    int? touchPointers,
    int? stylusPointers,
    int? mousePointers,
    int? trackpadPointers,
    bool? linkerStylusActive,
  }) {
    return PointerSnapshot(
      totalPointers: totalPointers ?? this.totalPointers,
      touchPointers: touchPointers ?? this.touchPointers,
      stylusPointers: stylusPointers ?? this.stylusPointers,
      mousePointers: mousePointers ?? this.mousePointers,
      trackpadPointers: trackpadPointers ?? this.trackpadPointers,
      linkerStylusActive: linkerStylusActive ?? this.linkerStylusActive,
    );
  }
}

class PointerSnapshotNotifier extends StateNotifier<PointerSnapshot> {
  PointerSnapshotNotifier() : super(const PointerSnapshot());

  final Map<int, PointerDeviceKind> _pointerKinds =
      HashMap<int, PointerDeviceKind>();
  bool _linkerStylusActive = false;

  void registerPointerDown(PointerDownEvent event) {
    if (_pointerKinds.containsKey(event.pointer)) {
      return;
    }
    _pointerKinds[event.pointer] = event.kind;
    state = _increment(state, event.kind);
  }

  void registerPointerUp(PointerUpEvent event) {
    _removePointer(event.pointer);
  }

  void registerPointerCancel(PointerCancelEvent event) {
    _removePointer(event.pointer);
  }

  void setLinkerStylusActive(bool active) {
    if (_linkerStylusActive == active) {
      return;
    }
    _linkerStylusActive = active;
    state = state.copyWith(linkerStylusActive: active);
  }

  void reset() {
    _pointerKinds.clear();
    _linkerStylusActive = false;
    state = const PointerSnapshot();
  }

  void _removePointer(int pointer) {
    final kind = _pointerKinds.remove(pointer);
    if (kind == null) {
      return;
    }
    state = _decrement(state, kind);
  }

  PointerSnapshot _increment(PointerSnapshot snapshot, PointerDeviceKind kind) {
    return snapshot.copyWith(
      totalPointers: snapshot.totalPointers + 1,
      touchPointers:
          snapshot.touchPointers + (kind == PointerDeviceKind.touch ? 1 : 0),
      stylusPointers:
          snapshot.stylusPointers +
          ((kind == PointerDeviceKind.stylus ||
                  kind == PointerDeviceKind.invertedStylus)
              ? 1
              : 0),
      mousePointers:
          snapshot.mousePointers + (kind == PointerDeviceKind.mouse ? 1 : 0),
      trackpadPointers:
          snapshot.trackpadPointers +
          (kind == PointerDeviceKind.trackpad ? 1 : 0),
    );
  }

  PointerSnapshot _decrement(PointerSnapshot snapshot, PointerDeviceKind kind) {
    int dec(int value) => value > 0 ? value - 1 : 0;
    final isStylus =
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
    return snapshot.copyWith(
      totalPointers: dec(snapshot.totalPointers),
      touchPointers: kind == PointerDeviceKind.touch
          ? dec(snapshot.touchPointers)
          : snapshot.touchPointers,
      stylusPointers: isStylus
          ? dec(snapshot.stylusPointers)
          : snapshot.stylusPointers,
      mousePointers: kind == PointerDeviceKind.mouse
          ? dec(snapshot.mousePointers)
          : snapshot.mousePointers,
      trackpadPointers: kind == PointerDeviceKind.trackpad
          ? dec(snapshot.trackpadPointers)
          : snapshot.trackpadPointers,
    );
  }
}

final pointerSnapshotProvider = StateNotifierProvider.autoDispose
    .family<PointerSnapshotNotifier, PointerSnapshot, String>(
      (ref, noteId) {
        final notifier = PointerSnapshotNotifier();
        ref.onDispose(notifier.reset);
        return notifier;
      },
    );

bool computePageScrollLock(
  PointerSnapshot snapshot,
  ScribblePointerMode policy,
) {
  if (snapshot.linkerStylusActive) {
    return true;
  }
  switch (policy) {
    case ScribblePointerMode.all:
      return snapshot.totalPointers == 1;
    case ScribblePointerMode.penOnly:
      return snapshot.totalPointers == 1 && snapshot.stylusPointers == 1;
    case ScribblePointerMode.mouseOnly:
      final mouseLikePointers =
          snapshot.mousePointers + snapshot.trackpadPointers;
      return snapshot.totalPointers == 1 && mouseLikePointers == 1;
    case ScribblePointerMode.mouseAndPen:
      final drawingPointers =
          snapshot.stylusPointers +
          snapshot.mousePointers +
          snapshot.trackpadPointers;
      return snapshot.totalPointers == 1 && drawingPointers == 1;
  }
}

final pageScrollLockProvider = Provider.family<bool, String>((ref, noteId) {
  final snapshot = ref.watch(pointerSnapshotProvider(noteId));
  final policy = ref.watch(pointerPolicyProvider);
  return computePageScrollLock(snapshot, policy);
});
