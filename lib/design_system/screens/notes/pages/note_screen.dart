// lib/features/notes/pages/note_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/components/organisms/note_top_toolbar.dart';
import '../../../design_system/components/organisms/note_toolbar_secondary.dart';
import '../../../design_system/components/atoms/tool_glow_icon.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/components/atoms/app_fab_icon.dart';

class NoteUiState extends ChangeNotifier {
  NoteUiState() {
    // 일반 모드에서 기본으로 bar 보이게
    secondaryOpen = true;
  }

  bool isFullscreen = false;
  bool secondaryOpen = false;
  NoteToolbarSecondaryVariant variant = NoteToolbarSecondaryVariant.bar;

  // 도구 상태
  ToolAccent activePenColor = ToolAccent.none;
  ToolAccent activeHighlighterColor = ToolAccent.none;
  bool eraserOn = false;
  bool linkPenOn = false;

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
  void onPen() {
    eraserOn = false;
    linkPenOn = false;
    // 예시: 이전 색 유지, 없으면 기본색 지정
    activePenColor = activePenColor == ToolAccent.none
        ? ToolAccent.blue
        : activePenColor;
    notifyListeners();
  }

  void onHighlighter() {
    eraserOn = false;
    linkPenOn = false;
    activeHighlighterColor = activeHighlighterColor == ToolAccent.none
        ? ToolAccent.yellow
        : activeHighlighterColor;
    notifyListeners();
  }

  void onEraser() {
    eraserOn = !eraserOn;
    linkPenOn = false;
    notifyListeners();
  }

  void onLinkPen() {
    linkPenOn = !linkPenOn;
    eraserOn = false;
    notifyListeners();
  }

  void onGraphView(BuildContext ctx) {
    // TODO: go_router로 그래프 화면 진입
    // ctx.goNamed(RouteNames.graph, pathParameters: {'id': ...});
  }
}

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key, required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NoteUiState(),
      child: Builder(
        builder: (context) {
          final ui = context.watch<NoteUiState>();

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
                      title: '노트 이름',
                      leftActions: [
                        ToolbarAction(
                          svgPath: AppIcons.chevronLeft,
                          onTap: () => context.pop(),
                          tooltip: '뒤로',
                        ),
                      ],
                      rightActions: [
                        ToolbarAction(
                          svgPath: AppIcons.scale, 
                          onTap: () =>
                              context.read<NoteUiState>().enterFullscreen(),
                          tooltip: '전체 화면',
                        ),
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
                        top: MediaQuery.of(context).padding.top + 8,  // 상태바 아래 8px
                        left: 0,
                        right: 0,
                        child: Center(
                          child: NoteToolbarSecondary(
                            onUndo: context.read<NoteUiState>().onUndo,
                            onRedo: context.read<NoteUiState>().onRedo,
                            onPen: context.read<NoteUiState>().onPen,
                            onHighlighter: context.read<NoteUiState>().onHighlighter,
                            onEraser: context.read<NoteUiState>().onEraser,
                            onLinkPen: context.read<NoteUiState>().onLinkPen,
                            onGraphView: () => context.read<NoteUiState>().onGraphView(context),
                            activePenColor: ui.activePenColor,
                            activeHighlighterColor: ui.activeHighlighterColor,
                            isEraserOn: ui.eraserOn,
                            isLinkPenOn: ui.linkPenOn,
                            iconSize: 28,
                            showBottomDivider: false,
                            variant: NoteToolbarSecondaryVariant.pill,
                          ),
                        ),
                      )
                    else
                      // 2) BAR 배치 (앱바 바로 아래)
                      Positioned(
                        top: ui.isFullscreen
                            ? MediaQuery.of(context).padding.top // 전체화면일 땐 상태바 아래
                            : 0,                     // 일반 모드에선 앱바 높이(=62)
                        left: 0,
                        right: 0,
                        child: NoteToolbarSecondary(
                          onUndo: context.read<NoteUiState>().onUndo,
                          onRedo: context.read<NoteUiState>().onRedo,
                          onPen: context.read<NoteUiState>().onPen,
                          onHighlighter: context.read<NoteUiState>().onHighlighter,
                          onEraser: context.read<NoteUiState>().onEraser,
                          onLinkPen: context.read<NoteUiState>().onLinkPen,
                          onGraphView: () => context.read<NoteUiState>().onGraphView(context),
                          activePenColor: ui.activePenColor,
                          activeHighlighterColor: ui.activeHighlighterColor,
                          isEraserOn: ui.eraserOn,
                          isLinkPenOn: ui.linkPenOn,
                          iconSize: 28,
                          showBottomDivider: true,
                          variant: NoteToolbarSecondaryVariant.bar,
                        ),
                      ),
                  ],

                  // 전체화면에서 “원래대로” 버튼(선택)
                  if (ui.isFullscreen)
                    Positioned(
                      right: 8,
                      top:
                          MediaQuery.of(context).padding.top + 16,
                      child: AppFabIcon(
                        svgPath: AppIcons.scale,
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
    final horizontalMargin = AppSpacing.xl * 2;
    final pageWidth = size.width - horizontalMargin * 2;

    return Center(
      child: Container(
        width: pageWidth.clamp(320, 820),
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
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
