import 'package:flutter/material.dart';

import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/folder_grid.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';

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
    // // 로딩 가드
    // final isLoaded = context.select<FolderStore, bool>((s) => s.isLoaded);
    // if (!isLoaded) {
    //   return const Scaffold(
    //     body: Center(child: CircularProgressIndicator()),
    //   );
    // }

    // // Store에서 폴더를 구독 (이름이 바뀌면 자동 리빌드)
    // final folder = context.select<FolderStore, Folder?>(
    //   (s) => s.byId(folderId),
    // );
    // // 로딩/미존재 가드
    // if (folder == null) {
    //   return const Scaffold(
    //     body: Center(child: Text('Folder not found')),
    //   );
    // }

    // final subFolders = context.select<FolderStore, List<Folder>>(
    //   (s) => s.byParent(vaultId: vaultId, parentFolderId: folder.id),
    // );
    // final notes = context.select<NoteStore, List<Note>>(
    //   (s) => s.byVault(vaultId).where((n) => n.folderId == folder.id).toList(),
    // );

    // 임시 Vault 화면과 동일: 검색/설정만, 그래프뷰 버튼 없음
    final actions = <ToolbarAction>[
      ToolbarAction(svgPath: AppIcons.search, onTap: () {}),
      ToolbarAction(svgPath: AppIcons.settings, onTap: () {}),
    ];

    return Scaffold(
      appBar: TopToolbar(
        variant: TopToolbarVariant.folder,
        // title: folder.name,
        title: 'Folder',
        actions: actions,
        backSvgPath: AppIcons.chevronLeft,
        onBack: () {
          // // go_router 사용 시 안전한 뒤로가기 처리
          // if (Navigator.of(context).canPop()) {
          //   context.pop();
          // } else {
          //   context.goNamed(RouteNames.home); // 루트면 홈으로
          // }
        },
        iconColor: AppColors.gray50, // 필요하면 색상 지정
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: FolderGrid(
          // items: items,
          items: [],
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
                  onTap: () async {
                    // await showCreationSheet(
                    //   context,
                    //   FolderCreationSheet(
                    //     onCreate: (name) async {
                    //       await context.read<FolderStore>().createFolder(
                    //         vaultId: vaultId,
                    //         parentFolderId: folderId, // 현재 폴더 아래에 생성
                    //         name: name,
                    //       );
                    //     },
                    //   ),
                    // );
                  },
                ),

                // 노트 생성
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () async {
                    // await showCreationSheet(
                    //   context,
                    //   NoteCreationSheet(
                    //     onCreate: (name) async {
                    //       final note = await context
                    //           .read<NoteStore>()
                    //           .createNote(
                    //             vaultId: vaultId,
                    //             folderId: folderId, // 현재 폴더에 생성
                    //             title: name,
                    //           );
                    //       if (!context.mounted) return;
                    //       context.pushNamed(
                    //         RouteNames.note,
                    //         pathParameters: {'id': note.id},
                    //         extra: {'title': note.title},
                    //       );
                    //     },
                    //   ),
                    // );
                  },
                ),
                // PDF 가져오기
                DockItem(
                  label: 'PDF 생성',
                  svgPath: AppIcons.download,
                  onTap: () async {
                    // final file = await pickPdf();
                    // if (file == null) return;

                    // final note = await context.read<NoteStore>().createPdfNote(
                    //   vaultId: vaultId, // ← 현재 스크린 파라미터
                    //   folderId: folderId, // ← 폴더 귀속
                    //   fileName: file.name,
                    // );

                    // if (!context.mounted) return;
                    // context.pushNamed(
                    //   RouteNames.note,
                    //   pathParameters: {'id': note.id},
                    //   extra: {'title': note.title},
                    // );
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
