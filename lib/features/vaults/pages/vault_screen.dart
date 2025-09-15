// features/vault/pages/vault_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../widgets/vault_creation_sheet.dart';
import '../../../utils/pickers/pick_pdf.dart';

import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';

import '../data/vault.dart'; // ← Vault 타입
import '../state/vault_store.dart'; // ← vaults → vault 로 수정
import '../../notes/state/note_store.dart';
import '../../../routing/route_names.dart';

class VaultScreen extends StatelessWidget {
  final String vaultId;
  const VaultScreen({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context) {
    final vault = context.select<VaultStore, Vault?>((s) => s.byId(vaultId));

    // 가드: 없으면 뒤로/에러 처리
    if (vault == null) {
      return const Scaffold(body: Center(child: Text('Vault not found')));
    }

    final actions = <ToolbarAction>[
      ToolbarAction(svgPath: AppIcons.search, onTap: () {}),
      // 임시 vault가 아니면 그래프뷰 버튼 노출
      if (!vault.isTemporary)
        ToolbarAction(
          svgPath: AppIcons.graphView, // ← 그래프 아이콘
          onTap: () {
            // 그래프 뷰로 이동 (예: /graph/:id)
            context.goNamed(RouteNames.graph, pathParameters: {'id': vault.id});
          },
        ),
      ToolbarAction(svgPath: AppIcons.settings, onTap: () {}),
    ];

    return Scaffold(
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: vault.name,
        actions: actions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(
          'Vault ID: ${vault.id}',
          style: const TextStyle(color: AppColors.gray50),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Center(
            child: BottomActionsDockFixed(
              items: [
                // 폴더 생성(있다면 연결 — 없으면 나중에 Store 메서드 붙이세요)
                DockItem(
                  label: '폴더 생성',
                  svgPath: AppIcons.folderAdd,
                  onTap: () => showVaultCreationSheet(context, vault.id),
                ),
                // 노트 생성
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showVaultCreationSheet(context, vault.id),
                ),
                // PDF 가져오기
                DockItem(
                  label: 'PDF 가져오기',
                  svgPath: AppIcons.download,
                  onTap: () async {
                    final file = await pickPdf();
                    if (file == null) return;
                    final note = await context.read<NoteStore>().createPdfNote(
                      vaultId: vault.id,
                      fileName: file.name,
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
