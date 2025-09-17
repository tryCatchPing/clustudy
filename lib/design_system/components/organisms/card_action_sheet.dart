import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';


class CardSheetAction {
  final String label;
  final String svgPath;
  final VoidCallback onTap;
  const CardSheetAction({
    required this.label,
    required this.svgPath,
    required this.onTap,
  });
}

Future<void> showCardActionSheetNear(
  BuildContext context, {
  required Offset anchorGlobal,  // 화면 좌표 (global)
  double dx = 12,                // 앵커에서 x 오프셋(오른쪽으로)
  double dy = 0,                 // 앵커에서 y 오프셋
  required List<CardSheetAction> actions,
  double? maxWidth,              // 필요 시 제한 폭
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final overlaySize = overlay.size;

  // 기본 배치: anchor 오른쪽에 띄우되, 화면 밖으로 나가면 왼쪽으로 접기
  const sheetMinWidth = 125.0; // 예시 스샷 참고
  final wantRightX = anchorGlobal.dx + dx;
  final fitsRight = wantRightX + sheetMinWidth <= overlaySize.width;

  final position = Offset(
    fitsRight ? (anchorGlobal.dx + dx) : (anchorGlobal.dx - dx - sheetMinWidth),
    (anchorGlobal.dy + dy).clamp(0, overlaySize.height - 200),
  );

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) {
      return Stack(
        children: [
          // 탭하면 닫히도록 투명 레이어
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: _CardActionSheet(
              actions: actions,
              maxWidth: maxWidth ?? 220,
            ),
          ),
        ],
      );
    },
  );
}

class _CardActionSheet extends StatelessWidget {
  const _CardActionSheet({required this.actions, required this.maxWidth});
  final List<CardSheetAction> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 125,
        maxWidth: maxWidth,
      ),
      child: Material(
        color: AppColors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16), // 요구사항
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                _ActionRow(action: actions[i]),
                if (i != actions.length - 1) const SizedBox(height: 16), // 항목 간 16px
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});
  final CardSheetAction action;

  Widget build(BuildContext context) {
    return SizedBox(                      // ← 추가: 전체 폭 차지
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).maybePop();
          action.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start, // ← 명시(기본값이지만 안전)
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28, height: 28,
                child: Center(
                  child: SvgPicture.asset(
                  action.svgPath,
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gray50, // 아이콘 색 (필요 시 바꾸세요)
                    BlendMode.srcIn,
                  ),
                ),
              ),
              ),
              const SizedBox(width: 16),
              Expanded( // ← 텍스트가 왼쪽 정렬로 쭉
                child: Text(
                  action.label,
                  style: AppTypography.body4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
