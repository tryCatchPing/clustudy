import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/components/organisms/folder_grid.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/components/organisms/item_actions.dart';
import '../../../design_system/components/molecules/folder_card.dart';
import '../../../design_system/components/organisms/rename_dialog.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../notes/state/note_store.dart';
import '../../notes/widgets/note_creation_sheet.dart';
import '../../vaults/state/vault_store.dart';
import '../../vaults/widgets/vault_creation_sheet.dart';
import '../../vaults/data/vault.dart';
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

    final vaults = context.watch<VaultStore>().vaults;

    final items = vaults.map((v) {
      final isTemp = v.isTemporary == true;

      return FolderGridItem(
        title: v.name,
        date: v.createdAt,
        onTap: () => context.pushNamed(
          RouteNames.vault,
          pathParameters: {'id': v.id},
        ),
        child: FolderCard(
          key: ValueKey(v.id),
          type: FolderType.vault,
          title: v.name,
          date: v.createdAt,
          onTap: () => context.pushNamed(
            RouteNames.vault,
            pathParameters: {'id': v.id},
          ),
          onLongPressStart: isTemp
              ? null
              : (d) {
                  showItemActionsNear(
                    context,
                    anchorGlobal: d.globalPosition,
                    handlers: ItemActionHandlers(
                      onRename: () async {
                        final name = await showRenameDialog(
                          context,
                          initial: v.name,
                          title: '이름 바꾸기',
                        );
                        if (name != null && name.trim().isNotEmpty) {
                          await context.read<VaultStore>().renameVault(
                            v.id,
                            name.trim(),
                          );
                        }
                      },
                      onExport: () async {
                        /* 내보내기 로직 */
                      },
                      onDuplicate: () async {
                        /* 복제 로직 */
                      },
                      onDelete: () async {
                        /* 삭제 로직 */
                      },
                    ),
                  );
                },
        ),
      );
    }).toList();

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
                  onTap: () async {
                    await showCreationSheet(
                      context,
                      VaultCreationSheet(
                        onCreate: (name) async {
                          await context.read<VaultStore>().createVault(name);
                        },
                      ),
                    );
                  },
                ),
                // 2) 노트 생성 (임시 vault로 바로)
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd, // 아이콘 경로 알맞게 교체
                  onTap: () async {
                    await showCreationSheet(
                      context,
                      NoteCreationSheet(
                        onCreate: (name) async {
                          // 임시 vault에 생성 (없으면 첫 vault 사용)
                          final vaultStore = context.read<VaultStore>();
                          final temp = vaultStore.vaults.firstWhere(
                            (v) => v.isTemporary,
                            orElse: () => vaultStore.vaults.first,
                          );
                          final note = await context
                              .read<NoteStore>()
                              .createNote(
                                vaultId: temp.id,
                                title: name,
                              );
                          if (!context.mounted) return;
                          context.goNamed(
                            RouteNames.note,
                            pathParameters: {'id': note.id},
                          );
                        },
                      ),
                    );
                  },
                ),
                // 3) PDF 가져오기 (임시 vault로)
                DockItem(
                  label: 'PDF 생성',
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
