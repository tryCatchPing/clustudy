import 'package:flutter/material.dart';

import '../../components/organisms/folder_grid.dart';
import '../../components/organisms/bottom_actions_dock_fixed.dart';
import '../../components/organisms/top_toolbar.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_icons.dart';
import '../../tokens/app_spacing.dart';
import 'widgets/home_creation_sheet.dart';

/// Home dashboard showcase that mirrors the feature implementation but runs on
/// deterministic mock data so the design system can render it without stores
/// or routers from the real app.
class DesignHomeScreen extends StatelessWidget {
  const DesignHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final demoItems = _demoVaults
        .map(
          (vault) => FolderGridItem(
            svgIconPath:
                vault.isTemporary ? AppIcons.folderVault : AppIcons.folder,
            title: vault.name,
            date: vault.createdAt,
            onTap: () => _showSnack(context, 'Open ${vault.name}'),
            onTitleChanged: (value) => _showSnack(
              context,
              'Rename ${vault.name} → $value',
            ),
          ),
        )
        .toList();

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
        child: FolderGrid(items: demoItems),
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
                  svgPath: AppIcons.folderVault,
                  onTap: () => showDesignHomeCreationSheet(context),
                ),
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showDesignHomeCreationSheet(context),
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
    required this.createdAt,
    this.isTemporary = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final bool isTemporary;
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
