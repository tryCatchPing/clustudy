import 'package:flutter/material.dart';

import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/top_toolbar.dart';
import '../../components/organisms/folder_grid.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';
import 'widgets/vault_creation_sheet.dart';

/// Vault detail showcase. Mirrors the feature UI but stays self-contained with
/// mock data so the design playground does not depend on providers or routing.
class DesignVaultScreen extends StatelessWidget {
  const DesignVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const vault = _DemoVault(
      id: 'vault-proj',
      name: '프로젝트 Vault',
      isTemporary: false,
    );

    final toolbarActions = <ToolbarAction>[
      const ToolbarAction(svgPath: AppIcons.search),
      if (!vault.isTemporary)
        ToolbarAction(
          svgPath: AppIcons.graphView,
          onTap: () => _showSnack(context, '그래프 뷰 이동'),
        ),
      const ToolbarAction(svgPath: AppIcons.settings),
    ];

    final items = <FolderGridItem>[
      FolderGridItem(
        svgIconPath: AppIcons.folder,
        title: '디자인 산출물',
        date: DateTime(2025, 9, 2, 10, 12),
        onTap: () => _showSnack(context, '디자인 산출물 폴더 열기'),
      ),
      FolderGridItem(
        svgIconPath: AppIcons.folder,
        title: '회의록',
        date: DateTime(2025, 8, 31, 18, 20),
        onTap: () => _showSnack(context, '회의록 폴더 열기'),
      ),
      FolderGridItem(
        svgIconPath: AppIcons.noteAdd,
        title: '제품 플로우 정리',
        date: DateTime(2025, 9, 3, 9, 45),
        onTap: () => _showSnack(context, '노트 열기'),
      ),
      FolderGridItem(
        svgIconPath: AppIcons.noteAdd,
        title: '테스트 케이스',
        date: DateTime(2025, 9, 1, 15, 5),
        onTap: () => _showSnack(context, '노트 열기'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: vault.name,
        actions: toolbarActions,
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
                  onTap: () => showDesignVaultCreationSheet(context),
                ),
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showDesignVaultCreationSheet(context),
                ),
                DockItem(
                  label: 'PDF 가져오기',
                  svgPath: AppIcons.download,
                  onTap: () => _showSnack(context, 'PDF 가져오기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(milliseconds: 800)),
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
