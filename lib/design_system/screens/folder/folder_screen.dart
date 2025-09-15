import 'package:flutter/material.dart';

import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/top_toolbar.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Vault ID: $vaultId', style: TextStyle(color: AppColors.gray50)),
            SizedBox(height: 8),
            Text('Folder ID: $folderId', style: TextStyle(color: AppColors.gray50)),
            SizedBox(height: 24),
            Text(
              '폴더 안의 노트와 하위 폴더가 여기에 노출될 예정입니다. 디자인 시스템에서는 시각적인 프레임만 확인합니다.',
              style: TextStyle(color: AppColors.gray40, height: 1.4),
            ),
          ],
        ),
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
                  onTap: () => showDesignFolderCreationSheet(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
