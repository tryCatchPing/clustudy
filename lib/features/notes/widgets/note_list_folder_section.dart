import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/navigation_card.dart';
import '../../vaults/models/vault_item.dart';

class NoteListFolderSection extends StatelessWidget {
  const NoteListFolderSection({
    super.key,
    required this.itemsAsync,
    required this.vaultId,
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
  final String vaultId;
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

        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onCreateFolder,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('폴더 추가'),
              ),
            ),
            const SizedBox(height: 8),
            if (currentFolderId != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onGoUp,
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('한 단계 위로'),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onReturnToVaultSelection,
                  icon: const Icon(Icons.folder_shared),
                  label: const Text('Vault 선택화면 이동'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (folders.isEmpty && notes.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('현재 위치에 항목이 없습니다.'),
              ),
            for (final folder in folders) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: NavigationCard(
                      icon: Icons.folder,
                      title: folder.name,
                      subtitle: '폴더',
                      color: Colors.amber[700]!,
                      onTap: () => onOpenFolder(folder),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '폴더 이동',
                    onPressed: () => onMoveFolder(folder),
                    icon: const Icon(Icons.drive_file_move_outline),
                  ),
                  IconButton(
                    tooltip: '폴더 이름 변경',
                    onPressed: () => onRenameFolder(folder),
                    icon: const Icon(Icons.drive_file_rename_outline),
                  ),
                  IconButton(
                    tooltip: '폴더 삭제',
                    onPressed: () => onDeleteFolder(folder),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            for (final note in notes) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: NavigationCard(
                      icon: Icons.brush,
                      title: note.name,
                      subtitle: '노트',
                      color: const Color(0xFF6750A4),
                      onTap: () => onOpenNote(note),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: '노트 이동',
                    onPressed: () => onMoveNote(note),
                    icon: const Icon(Icons.drive_file_move_outline),
                  ),
                  IconButton(
                    tooltip: '노트 이름 변경',
                    onPressed: () => onRenameNote(note),
                    icon: const Icon(Icons.drive_file_rename_outline),
                  ),
                  IconButton(
                    tooltip: '노트 삭제',
                    onPressed: () => onDeleteNote(note),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}
