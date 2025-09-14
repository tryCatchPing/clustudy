import 'package:flutter/material.dart';

import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/top_toolbar.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';

/// Vault detail showcase. Mirrors the feature UI but stays self-contained with
/// mock data so the design playground does not depend on providers or routing.
class DesignVaultScreen extends StatelessWidget {
  const DesignVaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const vault = _DemoVault(
      id: 'vault-proj',
      name: '프로젝트 Vault',
      description: '디자인 산출물과 회의록을 모아둔 공간입니다.',
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: vault.name,
        actions: toolbarActions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vault ID: ${vault.id}',
              style: const TextStyle(color: AppColors.gray50),
            ),
            const SizedBox(height: 24),
            const Text(
              'Vault 소개',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              vault.description,
              style: const TextStyle(color: AppColors.gray40, height: 1.4),
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
                  onTap: () => _showSnack(context, '폴더 생성'),
                ),
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => _showSnack(context, '노트 생성'),
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
    required this.description,
    this.isTemporary = false,
  });

  final String id;
  final String name;
  final String description;
  final bool isTemporary;
}
