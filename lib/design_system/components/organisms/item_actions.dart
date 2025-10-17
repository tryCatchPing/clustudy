import 'package:flutter/material.dart';
import '../../tokens/app_icons.dart';
import 'card_action_sheet.dart'; // ← 앞서 만든 28px/간격 16px 시트

enum ItemKind { vault, folder, note }

class ItemActionHandlers {
  final Future<void> Function()? onRename;
  final Future<void> Function()? onMove;
  final Future<void> Function()? onExport;
  final Future<void> Function()? onDuplicate;
  final Future<void> Function()? onDelete;
  const ItemActionHandlers({
    this.onRename,
    this.onMove,
    this.onExport,
    this.onDuplicate,
    this.onDelete,
  });
}

Future<void> showItemActionsNear(
  BuildContext context, {
  required Offset anchorGlobal,
  required ItemActionHandlers handlers,
  String? renameLabel,
  String? moveLabel,
  String? exportLabel,
  String? duplicateLabel,
  String? deleteLabel,
}) {
  final actions = <CardSheetAction>[];

  if (handlers.onMove != null) {
    actions.add(
      CardSheetAction(
        label: moveLabel ?? '이동',
        svgPath: AppIcons.move,
        onTap: () => handlers.onMove!(),
      ),
    );
  }
  if (handlers.onRename != null) {
    actions.add(
      CardSheetAction(
        label: renameLabel ?? '이름 변경',
        svgPath: AppIcons.rename,
        onTap: () => handlers.onRename!(),
      ),
    );
  }
  if (handlers.onExport != null) {
    actions.add(
      CardSheetAction(
        label: exportLabel ?? '내보내기',
        svgPath: AppIcons.export,
        onTap: () => handlers.onExport!(),
      ),
    );
  }
  if (handlers.onDuplicate != null) {
    actions.add(
      CardSheetAction(
        label: duplicateLabel ?? '복제',
        svgPath: AppIcons.copy,
        onTap: () => handlers.onDuplicate!(),
      ),
    );
  }
  if (handlers.onDelete != null) {
    actions.add(
      CardSheetAction(
        label: deleteLabel ?? '삭제',
        svgPath: AppIcons.trash,
        onTap: () => handlers.onDelete!(),
      ),
    );
  }

  return showCardActionSheetNear(
    context,
    anchorGlobal: anchorGlobal,
    actions: actions,
  );
}
