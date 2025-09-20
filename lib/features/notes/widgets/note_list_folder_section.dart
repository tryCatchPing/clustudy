import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../design_system/components/atoms/app_button.dart';
import '../../../design_system/components/molecules/app_card.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../vaults/models/vault_item.dart';

class NoteListFolderSection extends StatelessWidget {
  const NoteListFolderSection({
    super.key,
    required this.itemsAsync,
    required this.currentFolderId,
    required this.onCreateFolder,
    required this.onGoUp,
    required this.onReturnToVaultSelection,
    required this.onOpenFolder,
    required this.onMoveFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onOpenNote,
    required this.onMoveNote,
    required this.onRenameNote,
    required this.onDeleteNote,
  });

  final AsyncValue<List<VaultItem>> itemsAsync;
  final String? currentFolderId;
  final VoidCallback onCreateFolder;
  final VoidCallback? onGoUp;
  final VoidCallback onReturnToVaultSelection;
  final ValueChanged<VaultItem> onOpenFolder;
  final ValueChanged<VaultItem> onMoveFolder;
  final ValueChanged<VaultItem> onRenameFolder;
  final ValueChanged<VaultItem> onDeleteFolder;
  final ValueChanged<VaultItem> onOpenNote;
  final ValueChanged<VaultItem> onMoveNote;
  final ValueChanged<VaultItem> onRenameNote;
  final ValueChanged<VaultItem> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return itemsAsync.when(
      data: (items) {
        final folders = items
            .where((it) => it.type == VaultItemType.folder)
            .toList();
        final notes = items
            .where((it) => it.type == VaultItemType.note)
            .toList();

        final cards = <Widget>[
          for (final folder in folders)
            _NoteListCard(
              key: ValueKey('folder-${folder.id}'),
              iconPath: AppIcons.folderLarge,
              title: folder.name,
              date: folder.updatedAt,
              onTap: () => onOpenFolder(folder),
              onMove: () => onMoveFolder(folder),
              onRename: () => onRenameFolder(folder),
              onDelete: () => onDeleteFolder(folder),
            ),
          for (final note in notes)
            _NoteListCard(
              key: ValueKey('note-${note.id}'),
              iconPath: AppIcons.noteAdd,
              title: note.name,
              date: note.updatedAt,
              onTap: () => onOpenNote(note),
              onMove: () => onMoveNote(note),
              onRename: () => onRenameNote(note),
              onDelete: () => onDeleteNote(note),
            ),
        ];

        final actionButtons = <Widget>[
          if (onGoUp != null)
            AppButton.textIcon(
              text: '한 단계 위로',
              svgIconPath: AppIcons.chevronLeft,
              onPressed: onGoUp,
              style: AppButtonStyle.secondary,
              size: AppButtonSize.sm,
            )
          else
            AppButton.textIcon(
              text: 'Vault 목록으로',
              svgIconPath: AppIcons.folderVault,
              onPressed: onReturnToVaultSelection,
              style: AppButtonStyle.secondary,
              size: AppButtonSize.sm,
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: actionButtons,
            ),
            const SizedBox(height: AppSpacing.medium),
            if (cards.isEmpty)
              Text(
                '현재 위치에 항목이 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray40,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.large,
                runSpacing: AppSpacing.large,
                children: cards,
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _NoteListCard extends StatelessWidget {
  const _NoteListCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.date,
    required this.onTap,
    required this.onMove,
    required this.onRename,
    required this.onDelete,
  });

  final String iconPath;
  final String title;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onMove;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            svgIconPath: iconPath,
            title: title,
            date: date,
            onTap: onTap,
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CardActionButton(
                iconPath: AppIcons.move,
                tooltip: '이동',
                onPressed: onMove,
              ),
              const SizedBox(width: AppSpacing.small),
              _CardActionButton(
                iconPath: AppIcons.rename,
                tooltip: '이름 변경',
                onPressed: onRename,
              ),
              const SizedBox(width: AppSpacing.small),
              _CardActionButton(
                iconPath: AppIcons.trash,
                tooltip: '삭제',
                onPressed: onDelete,
                color: AppColors.penRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.iconPath,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final String iconPath;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: SvgPicture.asset(
        iconPath,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          color ?? AppColors.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
