import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Visual variants supported by the note editor's chrome/toolbar.
enum NoteEditorDesignToolbarVariant { standard, fullscreen }

/// Immutable UI slice describing how the editor chrome should render.
@immutable
class NoteEditorUiState {
  const NoteEditorUiState({
    this.toolbarVariant = NoteEditorDesignToolbarVariant.standard,
  });

  /// Toolbar styling / placement mode.
  final NoteEditorDesignToolbarVariant toolbarVariant;

  /// Convenience flag for fullscreen handling at the screen level.
  bool get isFullscreen =>
      toolbarVariant == NoteEditorDesignToolbarVariant.fullscreen;

  NoteEditorUiState copyWith({
    NoteEditorDesignToolbarVariant? toolbarVariant,
  }) => NoteEditorUiState(
    toolbarVariant: toolbarVariant ?? this.toolbarVariant,
  );
}

class NoteEditorUiStateNotifier extends StateNotifier<NoteEditorUiState> {
  NoteEditorUiStateNotifier() : super(const NoteEditorUiState());

  void setToolbarVariant(NoteEditorDesignToolbarVariant variant) {
    state = state.copyWith(toolbarVariant: variant);
  }

  void enterFullscreen() {
    setToolbarVariant(NoteEditorDesignToolbarVariant.fullscreen);
  }

  void exitFullscreen() {
    setToolbarVariant(NoteEditorDesignToolbarVariant.standard);
  }

  void toggleFullscreen() {
    state = state.copyWith(
      toolbarVariant: state.isFullscreen
          ? NoteEditorDesignToolbarVariant.standard
          : NoteEditorDesignToolbarVariant.fullscreen,
    );
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
