import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../design_system/components/molecules/folder_card.dart';
import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/components/organisms/folder_grid.dart';
import '../../../design_system/components/organisms/item_actions.dart';
import '../../../design_system/components/organisms/rename_dialog.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../routing/route_names.dart';
import '../../../utils/pickers/pick_pdf.dart';
import '../../notes/data/note.dart';
import '../../notes/state/note_store.dart';
import '../../notes/widgets/note_creation_sheet.dart';
import '../data/folder.dart';
import '../state/folder_store.dart';
import '../widgets/folder_creation_sheet.dart';
import '../widgets/folder_creation_sheet.dart';

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
      ...subFolders.map(
        (f) => FolderGridItem(
          title: f.name,
          date: f.createdAt,
          child: FolderCard(
            type: FolderType.normal,
            title: f.name,
            date: f.createdAt,
            onTap: () => context.pushNamed(
              RouteNames.folder,
              pathParameters: {
                'vaultId': vaultId,
                'folderId': f.id,
              },
            ),
            onLongPressStart: (d) {
              showItemActionsNear(
                context,
                anchorGlobal: d.globalPosition,
                handlers: ItemActionHandlers(
                  onRename: () async {
                    final name = await showRenameDialog(
                      context,
                      initial: f.name,
                      title: '이름 바꾸기',
                    );
                    if (name != null && name.trim().isNotEmpty) {
                      await context.read<FolderStore>().renameFolder(
                        id: f.id,
                        newName: name.trim(),
                      );
                    }
                  },
                  onMove: () async {
                    /**이동 로직 추가 */
                  },
                  onExport: () async {
                    /* 내보내기 로직 추가 */
                  },
                  onDuplicate: () async {
                    /**복제 로직 추가 */
                  },
                  onDelete: () async {
                    /**삭제 로직 추가 */
                  },
                ),
              );
            },
          ),
        ),
      ),
      // 노트들
      ...notes.map(
        (n) => FolderGridItem(
          previewImage: null, // 썸네일(Uint8List) 있으면 넣기
          title: n.title,
          date: n.createdAt,
          onTap: () => context.pushNamed(
            RouteNames.note,
            pathParameters: {'id': n.id},
            extra: {'title': n.title},
          ),
          onTitleChanged: (t) =>
              context.read<NoteStore>().renameNote(id: n.id, newTitle: t),
        ),
      ),
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
        backSvgPath: AppIcons.chevronLeft,
        onBack: () {
          // go_router 사용 시 안전한 뒤로가기 처리
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.goNamed(RouteNames.home); // 루트면 홈으로
          }
        },
        iconColor: AppColors.gray50, // 필요하면 색상 지정
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: FolderGrid(
          items: items,
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
                    await showCreationSheet(
                      context,
                      FolderCreationSheet(
                        onCreate: (name) async {
                          await context.read<FolderStore>().createFolder(
                            vaultId: vaultId,
                            parentFolderId: folderId, // 현재 폴더 아래에 생성
                            name: name,
                          );
                        },
                      ),
                    );
                  },
                ),

                // 노트 생성
                DockItem(
                  label: '노트 생성',
                  svgPath: AppIcons.noteAdd,
                  onTap: () async {
                    await showCreationSheet(
                      context,
                      NoteCreationSheet(
                        onCreate: (name) async {
                          final note = await context
                              .read<NoteStore>()
                              .createNote(
                                vaultId: vaultId,
                                folderId: folderId, // 현재 폴더에 생성
                                title: name,
                              );
                          if (!context.mounted) return;
                          context.pushNamed(
                            RouteNames.note,
                            pathParameters: {'id': note.id},
                            extra: {'title': note.title},
                          );
                        },
                      ),
                    );
                  },
                ),
                // PDF 가져오기
                DockItem(
                  label: 'PDF 생성',
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
                    context.pushNamed(
                      RouteNames.note,
                      pathParameters: {'id': note.id},
                      extra: {'title': note.title},
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
