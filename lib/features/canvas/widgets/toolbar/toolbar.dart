import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scribble/scribble.dart';

import '../../../../design_system/components/atoms/tool_glow_icon.dart';
import '../../../../design_system/components/molecules/tool_color_picker_pill.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_icons.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../models/canvas_color.dart';
import '../../models/tool_mode.dart';
import '../../providers/note_editor_provider.dart';
import '../../providers/note_editor_ui_provider.dart';
import '../../providers/tool_settings_provider.dart';

extension on NoteEditorDesignToolbarVariant {
  bool get isFullscreen => this == NoteEditorDesignToolbarVariant.fullscreen;

  double get _iconSize => isFullscreen ? 28 : 32;

  EdgeInsets get _outerPadding => switch (this) {
    // Use full screen width: no outer horizontal padding in both modes
    NoteEditorDesignToolbarVariant.standard => EdgeInsets.zero,
    NoteEditorDesignToolbarVariant.fullscreen => EdgeInsets.zero,
  };
}

ToolAccent _penAccentFor(Color color) {
  if (color.value == AppColors.penBlack.value) return ToolAccent.black;
  if (color.value == AppColors.penRed.value) return ToolAccent.red;
  if (color.value == AppColors.penBlue.value) return ToolAccent.blue;
  if (color.value == AppColors.penGreen.value) return ToolAccent.green;
  if (color.value == AppColors.penYellow.value) return ToolAccent.yellow;
  return ToolAccent.none;
}

ToolAccent _highlighterAccentFor(Color color) {
  if (color.value == AppColors.highlighterBlack.value) {
    return ToolAccent.black;
  }
  if (color.value == AppColors.highlighterRed.value) return ToolAccent.red;
  if (color.value == AppColors.highlighterBlue.value) return ToolAccent.blue;
  if (color.value == AppColors.highlighterGreen.value) return ToolAccent.green;
  if (color.value == AppColors.highlighterYellow.value)
    return ToolAccent.yellow;
  return ToolAccent.none;
}

Color? _glowFor(Color color, bool isActive, {double opacity = 0.4}) {
  if (!isActive) return null;
  final constrained = opacity.clamp(0, 1).toDouble();
  return color.withOpacity(constrained);
}

Color? _solidGlow(Color base, bool isActive, {double alpha = 0.35}) {
  if (!isActive) return null;
  final constrained = alpha.clamp(0, 1).toDouble();
  return base.withOpacity(constrained);
}

Color _iconColor({required bool enabled}) =>
    enabled ? AppColors.gray50 : AppColors.gray30;

/// Design-system aligned toolbar prototype.
///
/// Keeps the functional surface provided by the legacy toolbar while mimicking
/// the styling demonstrated inside the design system note screen. The widget is
/// not yet wired into the editor screen; it will be swapped in after we finish
/// polishing the remaining layout and behaviour.
class NoteEditorDesignToolbar extends ConsumerWidget {
  const NoteEditorDesignToolbar({
    required this.noteId,
    required this.canvasWidth,
    required this.canvasHeight,
    this.variant = NoteEditorDesignToolbarVariant.standard,
    this.paletteKind = NoteEditorPaletteKind.none,
    super.key,
  });

  final String noteId;
  final double canvasWidth;
  final double canvasHeight;
  final NoteEditorDesignToolbarVariant variant;
  final NoteEditorPaletteKind paletteKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[
      _NoteEditorToolbarMainRow(
        noteId: noteId,
        variant: variant,
      ),
      if (paletteKind != NoteEditorPaletteKind.none) ...[
        const SizedBox(height: AppSpacing.medium),
        _NoteEditorPaletteSheet(
          noteId: noteId,
          paletteKind: paletteKind,
        ),
      ],
    ];

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: variant._outerPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// 상단 아이콘 스트립(undo/redo + 도구 버튼)을 렌더링합니다.
///
/// 펜/하이라이터 더블 탭 시 팔레트 시트를 열고, 다른 도구를 고르면 팔레트를
/// 닫도록 UI 상태를 조정합니다.
class _NoteEditorToolbarMainRow extends ConsumerWidget {
  const _NoteEditorToolbarMainRow({
    required this.noteId,
    required this.variant,
  });

  final String noteId;
  final NoteEditorDesignToolbarVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolSettings = ref.watch(toolSettingsNotifierProvider(noteId));
    final notifier = ref.watch(currentNotifierProvider(noteId));
    final toolNotifier = ref.read(
      toolSettingsNotifierProvider(noteId).notifier,
    );
    final uiNotifier = ref.read(noteEditorUiStateProvider(noteId).notifier);

    return ValueListenableBuilder<ScribbleState>(
      valueListenable: notifier,
      builder: (context, _, __) {
        final bool canUndo = notifier.canUndo;
        final bool canRedo = notifier.canRedo;

        final bool penActive = toolSettings.toolMode == ToolMode.pen;
        final bool highlighterActive =
            toolSettings.toolMode == ToolMode.highlighter;
        final bool eraserActive = toolSettings.toolMode == ToolMode.eraser;
        final bool linkActive = toolSettings.toolMode == ToolMode.linker;

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarIconButton(
              svgPath: AppIcons.undo,
              iconSize: variant._iconSize,
              onTap: canUndo ? notifier.undo : null,
              glowColor: _glowFor(AppColors.primary, canUndo),
              iconColor: _iconColor(enabled: canUndo),
            ),

            const SizedBox(width: AppSpacing.small * 2),

            _ToolbarIconButton(
              svgPath: AppIcons.redo,
              iconSize: variant._iconSize,
              onTap: canRedo ? notifier.redo : null,
              glowColor: _glowFor(AppColors.primary, canRedo),
              iconColor: _iconColor(enabled: canRedo),
            ),

            _ToolbarDivider(
              isPill: variant.isFullscreen,
              iconSize: variant._iconSize,
            ),

            _ToolbarIconButton(
              svgPath: AppIcons.pen,
              iconSize: variant._iconSize,
              onTap: () {
                // If pen already active → toggle its palette. Otherwise
                // activate pen and close other palettes.
                if (toolSettings.toolMode == ToolMode.pen) {
                  uiNotifier.togglePalette(NoteEditorPaletteKind.pen);
                } else {
                  toolNotifier.setToolMode(ToolMode.pen);
                  uiNotifier.hidePalette();
                }
              },
              glowColor: _glowFor(toolSettings.penColor, penActive),
              accent: _penAccentFor(toolSettings.penColor),
            ),

            const SizedBox(width: AppSpacing.small * 2),

            _ToolbarIconButton(
              svgPath: AppIcons.highlighter,
              iconSize: variant._iconSize,
              onTap: () {
                if (toolSettings.toolMode == ToolMode.highlighter) {
                  uiNotifier.togglePalette(NoteEditorPaletteKind.highlighter);
                } else {
                  toolNotifier.setToolMode(ToolMode.highlighter);
                  uiNotifier.hidePalette();
                }
              },
              glowColor: _glowFor(
                toolSettings.highlighterColor,
                highlighterActive,
              ),
              accent: _highlighterAccentFor(toolSettings.highlighterColor),
            ),

            const SizedBox(width: AppSpacing.small * 2),

            _ToolbarIconButton(
              svgPath: AppIcons.eraser,
              iconSize: variant._iconSize,
              onTap: () {
                if (toolSettings.toolMode == ToolMode.eraser) {
                  uiNotifier.togglePalette(NoteEditorPaletteKind.eraser);
                } else {
                  toolNotifier.setToolMode(ToolMode.eraser);
                  uiNotifier.hidePalette();
                }
              },
              glowColor: _solidGlow(AppColors.primary, eraserActive),
            ),

            const SizedBox(width: AppSpacing.small * 2),

            _ToolbarIconButton(
              svgPath: AppIcons.linkPen,
              iconSize: variant._iconSize,
              onTap: () {
                uiNotifier.hidePalette();
                toolNotifier.setToolMode(ToolMode.linker);
              },
              glowColor: _solidGlow(AppColors.primary, linkActive),
            ),
          ],
        );

        // Bar: take full width. We wrap with SizedBox.expand so the main row
        // occupies the available width while keeping its contents centered.
        // Pill (fullscreen): pass raw row so the pill sizes to content.
        final Widget forSurface = variant.isFullscreen
            ? row
            : SizedBox(
                width: double.infinity,
                child: Center(child: row),
              );
        final surface = _ToolbarSurface(
          variant: variant,
          child: forSurface,
        );

        if (variant.isFullscreen) {
          return Center(child: surface);
        }
        // Ensure the bar stretches across the entire screen width
        return SizedBox(width: double.infinity, child: surface);
      },
    );
  }
}

class _ToolbarSurface extends StatelessWidget {
  const _ToolbarSurface({
    required this.variant,
    required this.child,
  });

  final NoteEditorDesignToolbarVariant variant;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isPill = variant.isFullscreen;
    final decoration = isPill
        ? BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.gray50, width: 1.5),
          )
        : const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.gray20, width: 1),
            ),
          );

    final padding = isPill
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: 15,
          );

    return Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.svgPath,
    required this.iconSize,
    this.onTap,
    this.glowColor,
    this.accent = ToolAccent.none,
    this.iconColor,
  });

  final String svgPath;
  final double iconSize;
  final VoidCallback? onTap;
  final Color? glowColor;
  final ToolAccent accent;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ToolGlowIcon(
      svgPath: svgPath,
      onTap: onTap,
      size: iconSize,
      glowColor: glowColor,
      accent: accent,
      iconColor: iconColor ?? _iconColor(enabled: enabled),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider({
    required this.isPill,
    required this.iconSize,
  });

  final bool isPill;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small * 1.5),
      child: SizedBox(
        height: iconSize * 0.75,
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: isPill ? AppColors.gray50 : AppColors.gray20,
        ),
      ),
    );
  }
}

class _StrokeOptionChip extends StatelessWidget {
  const _StrokeOptionChip({
    required this.diameter,
    required this.selected,
    required this.fillColor,
    required this.showInnerBorder,
    required this.onTap,
  });

  final double diameter;
  final bool selected;
  final Color fillColor;
  final bool showInnerBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const double outer = AppSpacing.touchTargetSm;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: outer,
          height: outer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: showInnerBorder
                    ? Border.all(color: AppColors.gray30)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 노트 편집기에 필요한 드로잉 도구와 스타일 제어를 제공하는 메인 액션 바입니다.
///
/// 캔버스 근처에 떠 있는 secondary toolbar 패턴으로, 디자인 시스템 시각 언어와
/// 기존 기능(도구 선택/팔레트 토글)을 연결하는 진입점입니다.
class NoteEditorToolbar extends ConsumerWidget {
  /// [NoteEditorToolbar]의 생성자.
  ///
  /// [noteId]는 현재 편집중인 노트 ID입니다.
  /// [canvasWidth]는 캔버스의 너비입니다.
  /// [canvasHeight]는 캔버스의 높이입니다.
  /// ✅ 페이지 네비게이션 파라미터들은 제거됨 (Provider에서 직접 읽음)
  const NoteEditorToolbar({
    required this.noteId,
    required this.canvasWidth,
    required this.canvasHeight,
    super.key,
  });

  /// 현재 편집중인 노트 모델
  final String noteId;

  /// 캔버스의 너비.
  final double canvasWidth;

  /// 캔버스의 높이.
  final double canvasHeight;

  // ✅ 페이지 네비게이션 관련 파라미터들은 제거됨 - Provider에서 직접 읽음

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalPages = ref.watch(notePagesCountProvider(noteId));
    if (totalPages == 0) {
      return const SizedBox.shrink();
    }

    final uiState = ref.watch(noteEditorUiStateProvider(noteId));

    return NoteEditorDesignToolbar(
      noteId: noteId,
      canvasWidth: canvasWidth,
      canvasHeight: canvasHeight,
      variant: uiState.toolbarVariant,
      paletteKind: uiState.paletteKind,
    );
  }
}

/// 펜/하이라이터용 팔레트 시트를 렌더링합니다.
///
/// 현재 선택된 도구에 맞춰 색상과 스트로크 옵션만 표시하며, 선택 후에는
/// 자동으로 팔레트를 닫아 main row로 초점을 돌려줍니다.
class _NoteEditorPaletteSheet extends ConsumerWidget {
  const _NoteEditorPaletteSheet({
    required this.noteId,
    required this.paletteKind,
  });

  final String noteId;
  final NoteEditorPaletteKind paletteKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(toolSettingsNotifierProvider(noteId));
    final toolNotifier = ref.read(
      toolSettingsNotifierProvider(noteId).notifier,
    );

    final isPen = paletteKind == NoteEditorPaletteKind.pen;
    final isHighlighter = paletteKind == NoteEditorPaletteKind.highlighter;
    final isEraser = paletteKind == NoteEditorPaletteKind.eraser;
    final toolMode = isPen
        ? ToolMode.pen
        : isHighlighter
        ? ToolMode.highlighter
        : ToolMode.eraser;

    final colors = isEraser
        ? <Color>[]
        : CanvasColor.all
              .map((c) => isPen ? c.color : c.highlighterColor)
              .toList(growable: false);
    final Color selectedColor = isPen
        ? settings.penColor
        : settings.highlighterColor;

    final widths = toolMode.widths;
    final double selectedWidth = isPen
        ? settings.penWidth
        : isHighlighter
        ? settings.highlighterWidth
        : settings.eraserWidth;

    double visualSize(double width) {
      final minWidth = widths.reduce((a, b) => a < b ? a : b);
      final maxWidth = widths.reduce((a, b) => a > b ? a : b);
      if ((maxWidth - minWidth).abs() < 1e-6) {
        return 18;
      }
      final t = (width - minWidth) / (maxWidth - minWidth);
      return 12 + t * 16;
    }

    final Color fillColor = isPen
        ? settings.penColor
        : isHighlighter
        ? settings.highlighterColor
        : Colors.transparent;

    // Keep sheet as small as possible around its content
    return UnconstrainedBox(
      alignment: Alignment.topCenter,
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(minWidth: 0),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray20.withOpacity(0.6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEraser)
                ToolColorPickerPill(
                  colors: colors,
                  selected: selectedColor,
                  onSelect: (color) {
                    toolNotifier.setToolMode(toolMode);
                    if (isPen) {
                      toolNotifier.setPenColor(color);
                    } else {
                      toolNotifier.setHighlighterColor(color);
                    }
                    // Keep sheet open until user taps outside or selects width.
                  },
                ),
              if (!isEraser) const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                children: [
                  for (final width in widths)
                    _StrokeOptionChip(
                      diameter: visualSize(width),
                      selected: width == selectedWidth,
                      fillColor: fillColor,
                      showInnerBorder: toolMode != ToolMode.pen,
                      onTap: () {
                        toolNotifier.setToolMode(toolMode);
                        if (toolMode == ToolMode.pen) {
                          toolNotifier.setPenWidth(width);
                        } else if (toolMode == ToolMode.highlighter) {
                          toolNotifier.setHighlighterWidth(width);
                        } else {
                          toolNotifier.setEraserWidth(width);
                        }
                        // Do not auto-close on eraser/width select; let user
                        // tap outside to dismiss, matching design expectations.
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
