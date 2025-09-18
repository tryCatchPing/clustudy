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
import 'widgets/vault_creation_sheet.dart';

class DesignVaultScreen extends StatefulWidget {
  const DesignVaultScreen({super.key});

  @override
  State<DesignVaultScreen> createState() => _DesignVaultScreenState();
}

class _DesignVaultScreenState extends State<DesignVaultScreen> {
  final _vault = _DemoVault(
    id: 'vault-proj',
    name: '프로젝트 Vault',
    isTemporary: false,
  );

  late final List<_VaultEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<_VaultEntry>.from(_seedEntries);
  }

  void _showEntryActions(_VaultEntry entry, LongPressStartDetails details) {
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
        onExport: () async => _showSnack('"${entry.name}" 내보내기'),
        onDuplicate: () async {
          setState(() {
            final copy = entry.copyWith(
              id: '${entry.id}-copy-${DateTime.now().millisecondsSinceEpoch}',
              name: '${entry.name} 복제',
              createdAt: DateTime.now(),
            );
            _entries.insert(0, copy);
          });
          _showSnack('"${entry.name}" 복제 완료');
        },
        onDelete: () async {
          setState(() => _entries.removeWhere((e) => e.id == entry.id));
          _showSnack('"${entry.name}" 삭제');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <ToolbarAction>[
      const ToolbarAction(svgPath: AppIcons.search),
      if (!_vault.isTemporary)
        ToolbarAction(
          svgPath: AppIcons.graphView,
          onTap: () => _showSnack('그래프 뷰 이동'),
        ),
      const ToolbarAction(svgPath: AppIcons.settings),
    ];

    final items = _entries.map((entry) {
      final icon = entry.kind == _EntryKind.folder
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
        title: _vault.name,
        actions: actions,
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
                  label: '폴더 생성',
                  svgPath: AppIcons.folderAdd,
                  onTap: () => showDesignFolderCreationSheet(
                    context,
                    onCreate: (name) async {
                      setState(() {
                        _entries.insert(
                          0,
                          _VaultEntry(
                            id: 'folder-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            createdAt: DateTime.now(),
                            kind: _EntryKind.folder,
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
                          _VaultEntry(
                            id: 'note-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            createdAt: DateTime.now(),
                            kind: _EntryKind.note,
                          ),
                        );
                      });
                    },
                  ),
                ),
                DockItem(
                  label: 'Vault 복제',
                  svgPath: AppIcons.copy,
                  onTap: () => showDesignVaultCreationSheet(context),
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

class _DemoVault {
  const _DemoVault({
    required this.id,
    required this.name,
    required this.isTemporary,
  });

  final String id;
  final String name;
  final bool isTemporary;
}

enum _EntryKind { folder, note }

class _VaultEntry {
  const _VaultEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.kind,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final _EntryKind kind;

  _VaultEntry copyWith({String? id, String? name, DateTime? createdAt, _EntryKind? kind}) {
    return _VaultEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      kind: kind ?? this.kind,
    );
  }
}

const List<_VaultEntry> _seedEntries = [
  _VaultEntry(
    id: 'folder-design-assets',
    name: '디자인 산출물',
    createdAt: DateTime(2025, 9, 2, 10, 12),
    kind: _EntryKind.folder,
  ),
  _VaultEntry(
    id: 'folder-meeting',
    name: '회의록',
    createdAt: DateTime(2025, 8, 31, 18, 20),
    kind: _EntryKind.folder,
  ),
  _VaultEntry(
    id: 'note-flow',
    name: '제품 플로우 정리',
    createdAt: DateTime(2025, 9, 3, 9, 45),
    kind: _EntryKind.note,
  ),
  _VaultEntry(
    id: 'note-tests',
    name: '테스트 케이스',
    createdAt: DateTime(2025, 9, 1, 15, 5),
    kind: _EntryKind.note,
  ),
];
