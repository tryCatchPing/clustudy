import 'package:flutter/material.dart';

import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/top_toolbar.dart';
import '../../components/organisms/folder_grid.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_icons.dart';
import 'widgets/folder_creation_sheet.dart';

class DesignFolderScreen extends StatelessWidget {
  const DesignFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const vaultId = 'vault-proj';
    const folderId = 'folder-design';

    final items = <FolderGridItem>[
      FolderGridItem(
        svgIconPath: AppIcons.folder,
        title: 'Wireframe',
        date: DateTime(2025, 9, 4, 12, 30),
        onTap: () => _showSnack(context, 'Wireframe 폴더 열기'),
      ),
      FolderGridItem(
        svgIconPath: AppIcons.folder,
        title: '리서치',
        date: DateTime(2025, 9, 2, 15, 10),
        onTap: () => _showSnack(context, '리서치 폴더 열기'),
      ),
      FolderGridItem(
        svgIconPath: AppIcons.noteAdd,
        title: '유저 여정 정리',
        date: DateTime(2025, 9, 3, 9, 0),
        onTap: () => _showSnack(context, '노트 열기'),
      ),
    ];

    final actions = <ToolbarAction>[
      const ToolbarAction(svgPath: AppIcons.search),
      const ToolbarAction(svgPath: AppIcons.settings),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: '디자인 폴더',
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
                  onTap: () => showDesignFolderCreationSheet(context),
                ),
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showDesignFolderCreationSheet(context),
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
