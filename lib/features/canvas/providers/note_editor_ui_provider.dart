import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visual variants supported by the note editor's chrome/toolbar.
enum NoteEditorDesignToolbarVariant { standard, fullscreen }

/// Palette overlays that can be displayed from the toolbar.
enum NoteEditorPaletteKind { none, pen, highlighter }

/// Immutable UI slice describing how the editor chrome should render.
@immutable
class NoteEditorUiState {
  const NoteEditorUiState({
    this.toolbarVariant = NoteEditorDesignToolbarVariant.standard,
    this.paletteKind = NoteEditorPaletteKind.none,
  });

  /// Toolbar styling / placement mode.
  final NoteEditorDesignToolbarVariant toolbarVariant;

  /// Convenience flag for fullscreen handling at the screen level.
  bool get isFullscreen =>
      toolbarVariant == NoteEditorDesignToolbarVariant.fullscreen;

  /// Currently opened palette sheet (if any).
  final NoteEditorPaletteKind paletteKind;

  bool get showPalette => paletteKind != NoteEditorPaletteKind.none;

  NoteEditorUiState copyWith({
    NoteEditorDesignToolbarVariant? toolbarVariant,
    NoteEditorPaletteKind? paletteKind,
  }) => NoteEditorUiState(
    toolbarVariant: toolbarVariant ?? this.toolbarVariant,
    paletteKind: paletteKind ?? this.paletteKind,
  );
}

class NoteEditorUiStateNotifier extends StateNotifier<NoteEditorUiState> {
  NoteEditorUiStateNotifier() : super(const NoteEditorUiState());

  void setToolbarVariant(NoteEditorDesignToolbarVariant variant) {
    state = state.copyWith(
      toolbarVariant: variant,
      paletteKind: NoteEditorPaletteKind.none,
    );
  }

  void enterFullscreen() {
    setToolbarVariant(NoteEditorDesignToolbarVariant.fullscreen);
  }

  void exitFullscreen() {
    setToolbarVariant(NoteEditorDesignToolbarVariant.standard);
  }

  void toggleFullscreen() {
    final nextVariant = state.isFullscreen
        ? NoteEditorDesignToolbarVariant.standard
        : NoteEditorDesignToolbarVariant.fullscreen;
    setToolbarVariant(nextVariant);
  }

  void showPalette(NoteEditorPaletteKind kind) {
    state = state.copyWith(paletteKind: kind);
  }

  void hidePalette() {
    if (!state.showPalette) return;
    state = state.copyWith(paletteKind: NoteEditorPaletteKind.none);
  }

  void togglePalette(NoteEditorPaletteKind kind) {
    if (state.paletteKind == kind) {
      hidePalette();
    } else {
      showPalette(kind);
    }
  }
}

/// UI state scoped to each note editor instance.
final noteEditorUiStateProvider =
    StateNotifierProvider.family<
      NoteEditorUiStateNotifier,
      NoteEditorUiState,
      String
    >(
      (ref, noteId) => NoteEditorUiStateNotifier(),
    );
