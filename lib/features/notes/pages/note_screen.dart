// lib/features/notes/pages/note_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design_system/components/atoms/app_fab_icon.dart';
import '../../../design_system/components/atoms/tool_glow_icon.dart';
import '../../../design_system/components/molecules/tool_color_picker_pill.dart';
import '../../../design_system/components/organisms/note_toolbar_secondary.dart';
import '../../../design_system/components/organisms/note_top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../state/note_store.dart';
import '../widgets/note_links_sheet.dart';

enum ToolPicker { none, pen, highlighter }

enum ActiveTool { none, pen, highlighter, eraser, linkPen }

class NoteUiState extends ChangeNotifier {
  NoteUiState() {
    secondaryOpen = true;
  }

  ActiveTool activeTool = ActiveTool.none;
  bool isFullscreen = false;
  bool secondaryOpen = false;
  NoteToolbarSecondaryVariant variant = NoteToolbarSecondaryVariant.bar;
  ToolPicker picker = ToolPicker.none;

  static const double _eraserGlowAlpha = 0.50;
  static const double _linkPenGlowAlpha = 0.50;

  bool penColorChosen = false;
  bool highlighterColorChosen = false;

  // 도구 상태
  bool get eraserOn => activeTool == ActiveTool.eraser;
  bool get linkPenOn => activeTool == ActiveTool.linkPen;

  Color? get eraserUiGlowColor =>
      eraserOn ? AppColors.primary.withOpacity(_eraserGlowAlpha) : null;
  Color? get linkPenUiGlowColor =>
      linkPenOn ? AppColors.primary.withOpacity(_linkPenGlowAlpha) : null;

  final List<Color> penPalette = [
    AppColors.penBlack,
    AppColors.penRed,
    AppColors.penBlue,
    AppColors.penGreen,
    AppColors.penYellow,
  ];
  final List<Color> hlPalette = [
    AppColors.highlighterBlack,
    AppColors.highlighterRed,
    AppColors.highlighterBlue,
    AppColors.highlighterGreen,
    AppColors.highlighterYellow,
  ];

  Color penColor = AppColors.penBlack; // 기본 펜색
  Color highlighterBase = AppColors.highlighterBlue;

  Color? get penUiGlowColor =>
      (activeTool == ActiveTool.pen) ? penColor.withOpacity(0.5) : null;

  Color? get highlighterUiGlowColor => (activeTool == ActiveTool.highlighter)
      ? highlighterBase.withOpacity(0.5)
      : null;

  Color get highlighterStrokeColor => highlighterBase.withOpacity(0.5);

  // ToolGlowIcon이 쓰는 enum → 색 매핑 (필요 시 확장)
  ToolAccent get activePenAccent =>
      penColorChosen ? _accentFromColor(penColor) : ToolAccent.none;
  ToolAccent get activeHighlighterAccent => highlighterColorChosen
      ? _accentFromColorHL(highlighterBase)
      : ToolAccent.none;

  ToolAccent _accentFromColor(Color c) {
    if (c == AppColors.penBlack) return ToolAccent.black;
    if (c == AppColors.penRed) return ToolAccent.red;
    if (c == AppColors.penBlue) return ToolAccent.blue;
    if (c == AppColors.penGreen) return ToolAccent.green;
    if (c == AppColors.penYellow) return ToolAccent.yellow;
    return ToolAccent.none;
  }

  ToolAccent _accentFromColorHL(Color c) {
    if (c == AppColors.highlighterBlack) return ToolAccent.black;
    if (c == AppColors.highlighterRed) return ToolAccent.red;
    if (c == AppColors.highlighterBlue) return ToolAccent.blue;
    if (c == AppColors.highlighterGreen) return ToolAccent.green;
    if (c == AppColors.highlighterYellow) return ToolAccent.yellow;
    return ToolAccent.none;
  }

  // 더블탭 → 피커 토글
  void togglePenPicker() {
    picker = (picker == ToolPicker.pen) ? ToolPicker.none : ToolPicker.pen;
    notifyListeners();
  }

  void toggleHighlighterPicker() {
    picker = (picker == ToolPicker.highlighter)
        ? ToolPicker.none
        : ToolPicker.highlighter;
    notifyListeners();
  }

  // 선택 처리
  void selectPenColor(Color c) {
    penColorChosen = true;
    penColor = c;
    picker = ToolPicker.none;
    notifyListeners();
  }

  void selectHighlighterColor(Color c) {
    highlighterColorChosen = true;
    highlighterBase = c;
    picker = ToolPicker.none;
    notifyListeners();
  }

  // onPen/onHighlighter는 기존처럼 도구 전환만 담당
  void onPen() {
    activeTool = (activeTool == ActiveTool.pen)
        ? ActiveTool.none
        : ActiveTool.pen;
    notifyListeners();
  }

  void onHighlighter() {
    activeTool = (activeTool == ActiveTool.highlighter)
        ? ActiveTool.none
        : ActiveTool.highlighter;
    notifyListeners();
  }

  // 토글/전환
  void toggleSecondary([bool? v]) {
    secondaryOpen = v ?? !secondaryOpen;
    notifyListeners();
  }

  void setVariant(NoteToolbarSecondaryVariant v) {
    variant = v;
    notifyListeners();
  }

  void enterFullscreen() {
    isFullscreen = true;
    secondaryOpen = true;
    variant = NoteToolbarSecondaryVariant.pill;
    notifyListeners();
  }

  void exitFullscreen() {
    isFullscreen = false;
    // 전체화면을 나가면 bar 형태로 복귀(원하면 유지해도 됨)
    variant = NoteToolbarSecondaryVariant.bar;
    // secondary는 닫고 시작하고 싶으면 false로
    secondaryOpen = true;
    notifyListeners();
  }

  // ---- 콜백 바인딩용 메서드(임시) ----
  void onUndo() {
    /* TODO: canvas.undo() */
  }
  void onRedo() {
    /* TODO: canvas.redo() */
  }

  void onEraser() {
    activeTool = (activeTool == ActiveTool.eraser)
        ? ActiveTool.none
        : ActiveTool.eraser;
    notifyListeners();
  }

  void onLinkPen() {
    activeTool = (activeTool == ActiveTool.linkPen)
        ? ActiveTool.none
        : ActiveTool.linkPen;
    notifyListeners();
  }

  void onGraphView(BuildContext ctx) {
    // TODO: go_router로 그래프 화면 진입
    // ctx.goNamed(RouteNames.graph, pathParameters: {'id': ...});
  }

  void showPenPicker() {
  if (activeTool != ActiveTool.pen) activeTool = ActiveTool.pen;
  picker = ToolPicker.pen;
  notifyListeners();
}

void showHighlighterPicker() {
  if (activeTool != ActiveTool.highlighter) activeTool = ActiveTool.highlighter;
  picker = ToolPicker.highlighter;
  notifyListeners();
}
}

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key, required this.noteId, this.initialTitle});
  final String noteId;
  final String? initialTitle;

  @override
  Widget build(BuildContext context) {
    context.read<NoteStore>().init();
    return ChangeNotifierProvider(
      create: (_) => NoteUiState(),
      child: Builder(
        builder: (context) {
          final ui = context.watch<NoteUiState>();
          final noteTitle = context.select<NoteStore, String?>(
            (s) => s.titleOf(noteId),
          );
          final displayTitle = noteTitle ?? initialTitle ?? '제목 없는 노트';
          return WillPopScope(
            onWillPop: () async {
              if (ui.isFullscreen) {
                context.read<NoteUiState>().exitFullscreen();
                return false;
              }
              return true;
            },
            child: Scaffold(
              backgroundColor: AppColors.gray10,

              // 전체화면이면 TopToolbar 제거
              appBar: ui.isFullscreen
                  ? null
                  : NoteTopToolbar(
                      title: displayTitle,
                      leftActions: [
                        ToolbarAction(
                          svgPath: AppIcons.chevronLeft,
                          onTap: () => context.pop(),
                          tooltip: '뒤로',
                        ),
                        ToolbarAction(
                          svgPath: AppIcons.pageManage,
                          tooltip: '페이지 관리',
                          onTap: () {
                            context.push(
                              '/note-pages/$noteId',
                              extra: noteTitle,
                            );
                          },
                        ),
                      ],
                      rightActions: [
                        ToolbarAction(
                          svgPath: AppIcons.scale,
                          onTap: () =>
                              context.read<NoteUiState>().enterFullscreen(),
                          tooltip: '전체 화면',
                        ),
                        ToolbarAction(svgPath: AppIcons.linkList, onTap: () {}),
                        ToolbarAction(
                          svgPath: AppIcons.search,
                          onTap: () {
                            /* TODO */
                          },
                          tooltip: '검색',
                        ),
                        ToolbarAction(
                          svgPath: AppIcons.settings,
                          onTap: () {
                            /* TODO */
                          },
                          tooltip: '설정',
                        ),
                      ],
                    ),

              body: Stack(
                children: [
                  const _NoteCanvasPage(),
                  // 캔버스
                  if (ui.secondaryOpen) ...[
                    // 1) PILL 배치 (변형 기준)
                    if (ui.variant == NoteToolbarSecondaryVariant.pill)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NoteToolbarSecondary(
                                onUndo: context.read<NoteUiState>().onUndo,
                                onRedo: context.read<NoteUiState>().onRedo,
                                onPen: context.read<NoteUiState>().onPen,
                                onHighlighter: context.read<NoteUiState>().onHighlighter,
                                onEraser: context.read<NoteUiState>().onEraser,
                                onLinkPen: context.read<NoteUiState>().onLinkPen,
                                onGraphView: () => context.read<NoteUiState>().onGraphView(context),
                                activePenColor: ui.activePenAccent,
                                activeHighlighterColor: ui.activeHighlighterAccent,
                                penGlowColor: ui.penUiGlowColor,
                                highlighterGlowColor: ui.highlighterUiGlowColor,
                                isEraserOn: ui.eraserOn,
                                isLinkPenOn: ui.linkPenOn,
                                eraserGlowColor: ui.eraserUiGlowColor,
                                linkPenGlowColor: ui.linkPenUiGlowColor,
                                iconSize: 28,
                                showBottomDivider: false,
                                variant: NoteToolbarSecondaryVariant.pill,
                                onPenDoubleTap: () => context.read<NoteUiState>().showPenPicker(),
                                onHighlighterDoubleTap: () => context.read<NoteUiState>().showHighlighterPicker(),
                              ),
                              if (ui.picker != ToolPicker.none) ...[
                                const SizedBox(height: 8), // ← 원하는 간격 8px
                                ToolColorPickerPill(
                                  colors: ui.picker == ToolPicker.pen ? ui.penPalette : ui.hlPalette,
                                  selected: ui.picker == ToolPicker.pen ? ui.penColor : ui.highlighterBase,
                                  onSelect: (c) {
                                    if (ui.picker == ToolPicker.pen) {
                                      ui.selectPenColor(c);
                                    } else {
                                      ui.selectHighlighterColor(c);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      // 2) BAR 배치 (앱바 바로 아래)
                      Positioned(
                        top: ui.isFullscreen ? MediaQuery.of(context).padding.top : 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              NoteToolbarSecondary(
                                onUndo: context.read<NoteUiState>().onUndo,
                                onRedo: context.read<NoteUiState>().onRedo,
                                onPen: context.read<NoteUiState>().onPen,
                                onHighlighter: context.read<NoteUiState>().onHighlighter,
                                onEraser: context.read<NoteUiState>().onEraser,
                                onLinkPen: context.read<NoteUiState>().onLinkPen,
                                onGraphView: () => context.read<NoteUiState>().onGraphView(context),
                                activePenColor: ui.activePenAccent,
                                activeHighlighterColor: ui.activeHighlighterAccent,
                                penGlowColor: ui.penUiGlowColor,
                                highlighterGlowColor: ui.highlighterUiGlowColor,
                                isEraserOn: ui.eraserOn,
                                isLinkPenOn: ui.linkPenOn,
                                eraserGlowColor: ui.eraserUiGlowColor,
                                linkPenGlowColor: ui.linkPenUiGlowColor,
                                iconSize: 28,
                                showBottomDivider: true,
                                variant: NoteToolbarSecondaryVariant.bar,
                                onPenDoubleTap: () => context.read<NoteUiState>().showPenPicker(),
                                onHighlighterDoubleTap: () => context.read<NoteUiState>().showHighlighterPicker(),
                              ),
                              if (ui.picker != ToolPicker.none) ...[
                                const SizedBox(height: 8), // ← 원하는 간격 8px
                                ToolColorPickerPill(
                                  colors: ui.picker == ToolPicker.pen ? ui.penPalette : ui.hlPalette,
                                  selected: ui.picker == ToolPicker.pen ? ui.penColor : ui.highlighterBase,
                                  onSelect: (c) {
                                    if (ui.picker == ToolPicker.pen) {
                                      ui.selectPenColor(c);
                                    } else {
                                      ui.selectHighlighterColor(c);
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],


                  // 전체화면에서 “원래대로” 버튼(선택)
                  if (ui.isFullscreen)
                    Positioned(
                      right: 8,
                      top: MediaQuery.of(context).padding.top + 16,
                      child: AppFabIcon(
                        svgPath: AppIcons.scaleReverse,
                        visualDiameter: 34,
                        minTapTarget: 44,
                        iconSize: 16,
                        backgroundColor: AppColors.gray10,
                        iconColor: AppColors.gray50,
                        tooltip: '닫기',
                        onPressed: () {
                          context.read<NoteUiState>().exitFullscreen();
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoteCanvasPage extends StatelessWidget {
  const _NoteCanvasPage();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const horizontalMargin = AppSpacing.xl * 2;
    final pageWidth = size.width - horizontalMargin * 2;

    return Center(
      child: Container(
        width: pageWidth.clamp(320, 820),
        margin: const EdgeInsets.symmetric(horizontal: horizontalMargin),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 2),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: const SizedBox.expand(), // TODO: Scribble 캔버스
      ),
    );
  }
}
