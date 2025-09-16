import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design_system/components/molecules/app_card.dart';
import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/components/organisms/folder_grid.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../notes/state/note_store.dart';
import '../../vaults/state/vault_store.dart';
import '../../vaults/data/vault.dart';
import '../widgets/home_creation_sheet.dart';
import '../../../utils/pickers/pick_pdf.dart';
import '../../../routing/route_names.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoaded = context.select<VaultStore, bool>((s) => s.isLoaded);
    if (!isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vaults = context.select<VaultStore, List<Vault>>((s) => s.vaults);

    final items = vaults
        .map(
          (v) => FolderGridItem(
            svgIconPath: v.isTemporary
                ? AppIcons.folderVault
                : AppIcons.folderVault,
            title: v.name,
            date: v.createdAt,
            onTap: () => context.goNamed(
              RouteNames.vault,
              pathParameters: {'id': v.id},
            ),
            // onTitleChanged: (name) => context.read<VaultStore>().renameVault(v.id, name),
          ),
        )
        .toList();

    return Scaffold(
      appBar: TopToolbar(
        variant: TopToolbarVariant.landing,
        title: 'Clustudy',
        actions: [
          ToolbarAction(svgPath: AppIcons.search, onTap: () {}),
          ToolbarAction(svgPath: AppIcons.settings, onTap: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.large, // 적당한 상단 여백
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
                // 1) Vault 생성
                DockItem(
                  label: 'Vault 생성',
                  svgPath: AppIcons.folderVaultMedium,
                  onTap: () => showHomeCreationSheet(context),
                ),
                // 2) 노트 생성 (임시 vault로 바로)
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd, // 아이콘 경로 알맞게 교체
                  onTap: () => showHomeCreationSheet(context),
                ),
                // 3) PDF 가져오기 (임시 vault로)
                DockItem(
                  label: 'PDF 가져오기',
                  svgPath: AppIcons.download,
                  onTap: () async {
                    final file = await pickPdf();
                    if (file == null) return;

                    final vaultStore = context.read<VaultStore>();
                    final temp = vaultStore.vaults.firstWhere(
                      (v) => v.isTemporary,
                      orElse: () => vaultStore.vaults.first, // 가드
                    );

                    final note = await context.read<NoteStore>().createPdfNote(
                      vaultId: temp.id,
                      fileName: file.name, // 최소 구현: 파일명만 저장
                    );

                    if (!context.mounted) return;
                    context.goNamed(
                      RouteNames.note,
                      pathParameters: {'id': note.id},
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
