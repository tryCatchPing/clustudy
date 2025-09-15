import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../folder/state/folder_store.dart';
import '../../notes/state/note_store.dart';
import '../../../routing/route_names.dart';
import 'package:go_router/go_router.dart';

Future<void> showFolderCreationSheet(
  BuildContext context, {
  required String vaultId,
  required String parentFolderId,
}) async {
  await showCreationSheet(
    context,
    CreationSheet(
      title: '여기에서 만들기',
      onBack: () => Navigator.pop(context),
      rightText: '닫기',
      onRightTap: () => Navigator.pop(context),
      actions: [
        CreationAction(
          label: '하위 폴더 생성',
          leading: SvgPicture.asset(AppIcons.folder, width: 28, height: 28),
          onTap: () async {
            await context.read<FolderStore>().createFolder(
              vaultId: vaultId,
              parentFolderId: parentFolderId,
              name: '새 폴더',
            );
            if (context.mounted) Navigator.pop(context);
          },
        ),
        CreationAction(
          label: '노트 생성',
          leading: SvgPicture.asset(AppIcons.noteAdd, width: 28, height: 28),
          onTap: () async {
            final note = await context.read<NoteStore>().createNote(
              vaultId: vaultId,
              folderId: parentFolderId,
              title: '새 노트',
            );
            if (context.mounted) {
              Navigator.pop(context);
              context.goNamed(RouteNames.note, pathParameters: {'id': note.id});
            }
          },
        ),
        CreationAction(
          label: 'PDF 가져오기',
          leading: SvgPicture.asset(AppIcons.download, width: 28, height: 28),
          onTap: () async {
            final picked = await FilePicker.platform.pickFiles(
              type: FileType.custom, allowedExtensions: ['pdf'],
            );
            if (picked == null || picked.files.isEmpty) return;
            final note = await context.read<NoteStore>().createPdfNote(
              vaultId: vaultId,
              folderId: parentFolderId,
              fileName: picked.files.single.name,
            );
            if (context.mounted) {
              Navigator.pop(context);
              context.goNamed(RouteNames.note, pathParameters: {'id': note.id});
            }
          },
        ),
      ],
    ),
  );
}
