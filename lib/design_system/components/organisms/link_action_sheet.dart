// lib/design_system/components/organisms/link_action_sheet.dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

/// 링크 컨텍스트 시트: '링크로 이동', '링크 수정', '링크 삭제'
Future<void> showLinkActionSheetNear(
  BuildContext context, {
  required Offset anchorGlobal,           // 전역 좌표 (앵커)
  double dx = 12,                         // 앵커 기준 x 오프셋
  double dy = 0,                          // 앵커 기준 y 오프셋
  required Future<void> Function() onGo,  // 링크로 이동
  required Future<void> Function() onEdit,// 링크 수정
  required Future<void> Function() onDelete,// 링크 삭제
  double? maxWidth,
  Color? deleteColor,                     // 삭제 문구 색상(토큰 연결용)
}) async {
  final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
  final overlaySize = overlayBox.size;

  const sheetMinWidth = 125.0;
  final wantRightX = anchorGlobal.dx + dx;
  final fitsRight = wantRightX + sheetMinWidth <= overlaySize.width;

  final position = Offset(
    fitsRight ? (anchorGlobal.dx + dx) : (anchorGlobal.dx - dx - sheetMinWidth),
    (anchorGlobal.dy + dy).clamp(0, overlaySize.height - 200),
  );

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'link-actions',
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) {
      return Stack(
        children: [
          // 바깥 클릭 시 닫힘
          Positioned.fill(
            child: GestureDetector(onTap: () => Navigator.of(context).pop()),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: _LinkActionSheet(
              maxWidth: maxWidth ?? 220,
              deleteColor: deleteColor ?? AppColors.penRed, // 기본: red-ish
              onGo: onGo,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ],
      );
    },
  );
}

class _LinkActionSheet extends StatelessWidget {
  const _LinkActionSheet({
    required this.maxWidth,
    required this.deleteColor,
    required this.onGo,
    required this.onEdit,
    required this.onDelete,
  });

  final double maxWidth;
  final Color deleteColor;
  final Future<void> Function() onGo;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(                 // ← 추가: 내용 폭에 맞춤
    child: Material(
      color: AppColors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // 좌우 동일
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,          // ← 최소폭/최소높이
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LinkActionRow(label: '링크로 이동', textStyle: AppTypography.body4, onTap: () async { /* ... */ }),
            const SizedBox(height: 16),
            _LinkActionRow(label: '링크 수정', textStyle: AppTypography.body4, onTap: () async { /* ... */ }),
            const SizedBox(height: 16),
            _LinkActionRow(
              label: '링크 삭제',
              textStyle: AppTypography.body4.copyWith(color: deleteColor),
              onTap: () async { /* ... */ },
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _LinkActionRow extends StatelessWidget {
  const _LinkActionRow({
    required this.label,
    required this.onTap,
    required this.textStyle,
  });

  final String label;
  final Future<void> Function() onTap;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textStyle,
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
