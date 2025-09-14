import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design_system/components/molecules/app_card.dart';
import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../notes/state/note_store.dart';
import '../../vaults/state/vault_store.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Consumer<VaultStore>(
          builder: (_, store, __) {
            if (!store.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final raw = store.vaults;
            final items = [...raw]
              ..sort((a, b) {
                if (a.isTemporary != b.isTemporary) {
                  return a.isTemporary ? -1 : 1; // 임시 vault 먼저
                }
                final t = b.createdAt.compareTo(a.createdAt); // 최신 우선
                if (t != 0) return t;
                return a.name.compareTo(b.name); // tie-breaker: 이름
              });
            return LayoutBuilder(
              builder: (context, c) {
                const tileW = 144.0;
                const gap = 48.0;
                final cross = (c.maxWidth + gap) ~/ (tileW + gap);
                final crossCount = cross.clamp(1, 8);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                    crossAxisCount: crossCount, // ← 계산값 사용
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final v = items[i];
                    return AppCard(
                      svgIconPath: v.isTemporary
                          ? AppIcons.folderVault
                          : AppIcons.folder,
                      title: v.name,
                      date: v.createdAt,
                      onTap: () => context.go('/vault/${v.id}'),
                      onTitleChanged: (newTitle) => context
                          .read<VaultStore>()
                          .renameVault(v.id, newTitle),
                    );
                  },
                );
              },
            );
          },
        ),
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
                  svgPath: AppIcons.folderVault,
                  onTap: () async {
                    await context.read<VaultStore>().createVault('새 Vault');
                  },
                ),
                // 2) 노트 생성 (임시 vault로 바로)
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd, // 아이콘 경로 알맞게 교체
                  onTap: () async {
                    final vaultStore = context.read<VaultStore>();
                    final temp = vaultStore.vaults.firstWhere(
                      (v) => v.isTemporary,
                      orElse: () => vaultStore.vaults.first, // 가드
                    );
                    final note = await context.read<NoteStore>().createNote(
                      vaultId: temp.id,
                      title: '새 노트',
                    );
                    if (context.mounted) context.go('/note/${note.id}');
                  },
                ),
                // 3) PDF 가져오기 (임시 vault로)
                DockItem(
                  label: 'PDF 가져오기',
                  svgPath: AppIcons.download, // 아이콘 경로 알맞게 교체
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );
                    if (result == null || result.files.isEmpty) return;

                    final fileName = result.files.single.name;
                    final vaultStore = context.read<VaultStore>();
                    final temp = vaultStore.vaults.firstWhere(
                      (v) => v.isTemporary,
                      orElse: () => vaultStore.vaults.first,
                    );
                    final note = await context.read<NoteStore>().createPdfNote(
                      vaultId: temp.id,
                      fileName: fileName,
                    );

                    if (context.mounted) context.go('/note/${note.id}');
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
