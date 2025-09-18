import 'package:flutter/material.dart';

import '../../components/molecules/app_card.dart';
import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/folder_grid.dart';
import '../../components/organisms/item_actions.dart';
import '../../components/organisms/rename_dialog.dart';
import '../../components/organisms/top_toolbar.dart';
import '../../screens/folder/widgets/folder_creation_sheet.dart';
import '../../screens/notes/widgets/note_creation_sheet.dart';
import '../../screens/vault/widgets/vault_creation_sheet.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';
import 'widgets/home_creation_sheet.dart';

class DesignHomeScreen extends StatefulWidget {
  const DesignHomeScreen({super.key});

  @override
  State<DesignHomeScreen> createState() => _DesignHomeScreenState();
}

class _DesignHomeScreenState extends State<DesignHomeScreen> {
  late final List<_DemoVault> _vaults;

  @override
  void initState() {
    super.initState();
    _vaults = List<_DemoVault>.from(_demoVaults);
  }

  void _showVaultActions(_DemoVault vault, LongPressStartDetails details) {
    showItemActionsNear(
      context,
      anchorGlobal: details.globalPosition,
      handlers: ItemActionHandlers(
        onRename: () async {
          final name = await showRenameDialog(
            context,
            title: '이름 바꾸기',
            initial: vault.name,
          );
          if (name == null || name.trim().isEmpty) return;
          setState(() {
            final idx = _vaults.indexWhere((v) => v.id == vault.id);
            if (idx != -1) {
              _vaults[idx] = _vaults[idx].copyWith(name: name.trim());
            }
          });
        },
        onExport: () async => _showSnack('"${vault.name}" 내보내기'),
        onDuplicate: () async {
          setState(() {
            final copy = vault.copyWith(
              id: '${vault.id}-copy-${DateTime.now().millisecondsSinceEpoch}',
              name: '${vault.name} 복제',
              createdAt: DateTime.now(),
            );
            _vaults.insert(0, copy);
          });
          _showSnack('"${vault.name}" 복제 완료');
        },
        onDelete: () async {
          setState(() => _vaults.removeWhere((v) => v.id == vault.id));
          _showSnack('"${vault.name}" 삭제');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _vaults.map((vault) {
      return FolderGridItem(
        child: AppCard(
          svgIconPath: vault.isTemporary ? AppIcons.folderVault : AppIcons.folder,
          title: vault.name,
          date: vault.createdAt,
          onTap: () => _showSnack('Open ${vault.name}'),
          onLongPressStart:
              vault.isTemporary ? null : (d) => _showVaultActions(vault, d),
        ),
      );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.landing,
        title: 'Clustudy',
        actions: const [
          ToolbarAction(svgPath: AppIcons.search),
          ToolbarAction(svgPath: AppIcons.settings),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.large,
        ),
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
                  label: 'Vault 생성',
                  svgPath: AppIcons.folderVaultMedium,
                  onTap: () => showDesignVaultCreationSheet(
                    context,
                    onCreate: (name) async {
                      setState(() {
                        _vaults.insert(
                          0,
                          _DemoVault(
                            id: 'vault-${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            createdAt: DateTime.now(),
                          ),
                        );
                      });
                    },
                  ),
                ),
                DockItem(
                  label: '폴더 생성',
                  svgPath: AppIcons.folderAdd,
                  onTap: () => showDesignFolderCreationSheet(context),
                ),
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showDesignNoteCreationSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDesignHomeCreationSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('빠른 생성'),
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
    required this.createdAt,
    this.isTemporary = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final bool isTemporary;

  _DemoVault copyWith({String? id, String? name, DateTime? createdAt, bool? isTemporary}) {
    return _DemoVault(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }
}

const List<_DemoVault> _demoVaults = [
  _DemoVault(
    id: 'temp',
    name: '임시 Vault',
    createdAt: DateTime(2025, 9, 1, 9, 30),
    isTemporary: true,
  ),
  _DemoVault(
    id: 'math',
    name: '수학 노트',
    createdAt: DateTime(2025, 9, 2, 11, 10),
  ),
  _DemoVault(
    id: 'design',
    name: '디자인 자료',
    createdAt: DateTime(2025, 9, 3, 14, 45),
  ),
  _DemoVault(
    id: 'ref',
    name: '참고 문서',
    createdAt: DateTime(2025, 9, 4, 10, 5),
  ),
];
