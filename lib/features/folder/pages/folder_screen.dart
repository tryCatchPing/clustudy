import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/folder_grid.dart';

import '../widgets/folder_creation_sheet.dart';
import '../../notes/state/note_store.dart';
import '../../notes/data/note.dart';
import '../../../routing/route_names.dart';
import '../data/folder.dart';
import '../state/folder_store.dart';
import '../../../utils/pickers/pick_pdf.dart';

import 'package:provider/provider.dart';

class FolderScreen extends StatelessWidget {
  final String vaultId;
  final String folderId;
  const FolderScreen({
    super.key,
    required this.vaultId,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 가드
    final isLoaded = context.select<FolderStore, bool>((s) => s.isLoaded);
    if (!isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Store에서 폴더를 구독 (이름이 바뀌면 자동 리빌드)
    final folder = context.select<FolderStore, Folder?>(
      (s) => s.byId(folderId),
    );
    // 로딩/미존재 가드
    if (folder == null) {
      return const Scaffold(
        body: Center(child: Text('Folder not found')),
      );
    }

    final subFolders = context.select<FolderStore, List<Folder>>(
      (s) => s.byParent(vaultId: vaultId, parentFolderId: folder.id),
    );
    final notes = context.select<NoteStore, List<Note>>(
      (s) => s.byVault(vaultId).where((n) => n.folderId == folder.id).toList(),
    );

    final items = <FolderGridItem>[
      // 폴더들
      ...subFolders.map((f) => FolderGridItem(
            svgIconPath: AppIcons.folder,           // 폴더는 SVG 아이콘
            title: f.name,
            date: f.createdAt,
            onTap: () => context.goNamed(
              RouteNames.folder,
              pathParameters: {'vaultId': vaultId, 'folderId': f.id},
            ),
            // onTitleChanged: (name) => context.read<FolderStore>().renameFolder(f.id, name),
          )),
      // 노트들
      ...notes.map((n) => FolderGridItem(
            previewImage: null,                     // 썸네일(Uint8List) 있으면 넣기
            title: n.title,
            date: n.createdAt,
            onTap: () => context.goNamed(
              RouteNames.note,
              pathParameters: {'id': n.id},
            ),
            // onTitleChanged: (t) => context.read<NoteStore>().renameNote(n.id, t),
          )),
    ];

    // 임시 Vault 화면과 동일: 검색/설정만, 그래프뷰 버튼 없음
    final actions = <ToolbarAction>[
      ToolbarAction(svgPath: AppIcons.search, onTap: () {}),
      ToolbarAction(svgPath: AppIcons.settings, onTap: () {}),
    ];

    return Scaffold(
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        title: folder.name,
        actions: actions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FolderGrid(
          items:items,
        ),
      ),
      // 하단 Dock: 임시 Vault처럼 “만들기” → 시트 열기
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
                  onTap: () => showFolderCreationSheet(
                    context,
                    vaultId: vaultId, // ← 이름 있는 인자
                    parentFolderId: folderId, // ← 이름 있는 인자
                  ),
                ),
                // 노트 생성
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () => showFolderCreationSheet(
                    context,
                    vaultId: vaultId, // ← 이름 있는 인자
                    parentFolderId: folderId, // ← 이름 있는 인자
                  ),
                ),
                // PDF 가져오기
                DockItem(
                  label: 'PDF 가져오기',
                  svgPath: AppIcons.download,
                  onTap: () async {
                    final file = await pickPdf();
                    if (file == null) return;

                    final note = await context.read<NoteStore>().createPdfNote(
                      vaultId: vaultId, // ← 현재 스크린 파라미터
                      folderId: folderId, // ← 폴더 귀속
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
