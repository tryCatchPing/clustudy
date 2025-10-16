import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/molecules/note_card.dart';
import '../../../design_system/components/organisms/item_actions.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../vaults/models/vault_item.dart';

class NoteListFolderSection extends StatelessWidget {
  const NoteListFolderSection({
    super.key,
    required this.itemsAsync,
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
            NoteCard(
              key: ValueKey('folder-${folder.id}'),
              iconPath: AppIcons.folderLarge,
              title: folder.name,
              date: folder.updatedAt,
              onTap: () => onOpenFolder(folder),
              onLongPressStart: (details) {
                showItemActionsNear(
                  context,
                  anchorGlobal: details.globalPosition,
                  handlers: ItemActionHandlers(
                    onMove: () async => onMoveFolder(folder),
                    onRename: () async => onRenameFolder(folder),
                    onDelete: () async => onDeleteFolder(folder),
                  ),
                );
              },
            ),
          for (final note in notes)
            NoteCard(
              key: ValueKey('note-${note.id}'),
              iconPath: AppIcons.noteAdd,
              title: note.name,
              date: note.updatedAt,
              onTap: () => onOpenNote(note),
              onLongPressStart: (details) {
                showItemActionsNear(
                  context,
                  anchorGlobal: details.globalPosition,
                  handlers: ItemActionHandlers(
                    onMove: () async => onMoveNote(note),
                    onRename: () async => onRenameNote(note),
                    onDelete: () async => onDeleteNote(note),
                  ),
                );
              },
            ),
        ];

        if (cards.isEmpty) {
          return Text(
            '현재 위치에 항목이 없습니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.gray40,
            ),
          );
        }

        return Wrap(
          spacing: AppSpacing.large,
          runSpacing: AppSpacing.large,
          children: cards,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}
