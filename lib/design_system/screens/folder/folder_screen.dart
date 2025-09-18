import 'package:flutter/material.dart';

import '../../components/molecules/app_card.dart';
import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/folder_grid.dart';
import '../../components/organisms/item_actions.dart';
import '../../components/organisms/rename_dialog.dart';
import '../../components/organisms/top_toolbar.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';
import '../folder/widgets/folder_creation_sheet.dart';
import '../notes/widgets/note_creation_sheet.dart';

class DesignFolderScreen extends StatefulWidget {
  const DesignFolderScreen({super.key});

  @override
  State<DesignFolderScreen> createState() => _DesignFolderScreenState();
}

class _DesignFolderScreenState extends State<DesignFolderScreen> {
  final _vaultId = 'vault-proj';
  final _folderId = 'folder-design';
  late final List<_FolderEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<_FolderEntry>.from(_seedEntries);
  }

  void _showEntryActions(_FolderEntry entry, LongPressStartDetails details) {
    showItemActionsNear(
      context,
      anchorGlobal: details.globalPosition,
      handlers: ItemActionHandlers(
        onRename: () async {
          final name = await showRenameDialog(
            context,
            title: '이름 바꾸기',
            initial: entry.name,
          );
          if (name == null || name.trim().isEmpty) return;
          setState(() {
            final idx = _entries.indexWhere((e) => e.id == entry.id);
            if (idx != -1) {
              _entries[idx] = _entries[idx].copyWith(name: name.trim());
            }
          });
        },
        onMove: () async => _showSnack('"${entry.name}" 이동'),
        onDelete: () async {
          setState(() => _entries.removeWhere((e) => e.id == entry.id));
          _showSnack('"${entry.name}" 삭제');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _entries.map((entry) {
      final icon = entry.kind == _FolderEntryKind.folder
          ? AppIcons.folder
          : AppIcons.noteAdd;
      return FolderGridItem(
        child: AppCard(
          svgIconPath: icon,
          title: entry.name,
          date: entry.createdAt,
          onTap: () => _showSnack('Open ${entry.name}'),
          onLongPressStart: (d) => _showEntryActions(entry, d),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: '디자인 폴더',
        actions: const [
          ToolbarAction(svgPath: AppIcons.search),
          ToolbarAction(svgPath: AppIcons.settings),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FolderGrid(items: items),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Center(
            child: BottomActionsDockFixed(
              items: [
                DockItem(
                  label: '하위 폴더 생성',
                  svgPath: AppIcons.folderAdd,
                  onTap: () => showDesignFolderCreationSheet(
                    context,
                    onCreate: (name) async {
                      setState(() {
                        _entries.insert(
                          0,
                          _FolderEntry(
                            id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            createdAt: DateTime.now(),
                            kind: _FolderEntryKind.folder,
                          ),
                        );
                      });
                    },
                  ),
                ),
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showDesignNoteCreationSheet(
                    context,
                    onCreate: (name) async {
                      setState(() {
                        _entries.insert(
                          0,
                          _FolderEntry(
                            id: 'note-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            createdAt: DateTime.now(),
                            kind: _FolderEntryKind.note,
                          ),
                        );
                      });
                    },
                  ),
                ),
                DockItem(
                  label: 'PDF 가져오기',
                  svgPath: AppIcons.download,
                  onTap: () => _showSnack('PDF 가져오기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 900)),
    );
  }
}

enum _FolderEntryKind { folder, note }

class _FolderEntry {
  const _FolderEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.kind,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final _FolderEntryKind kind;

  _FolderEntry copyWith({String? id, String? name, DateTime? createdAt, _FolderEntryKind? kind}) {
    return _FolderEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
    );
  }
}

const List<_FolderEntry> _seedEntries = [
  _FolderEntry(
    id: 'subfolder-wireframe',
    name: 'Wireframe',
    createdAt: DateTime(2025, 9, 4, 12, 30),
    kind: _FolderEntryKind.folder,
  ),
  _FolderEntry(
    id: 'subfolder-research',
    name: '리서치',
    createdAt: DateTime(2025, 9, 2, 15, 10),
    kind: _FolderEntryKind.folder,
  ),
  _FolderEntry(
    id: 'note-journey',
    name: '유저 여정 정리',
    createdAt: DateTime(2025, 9, 3, 9, 0),
    kind: _FolderEntryKind.note,
  ),
];
