import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../notes/state/note_store.dart';
import '../../../routing/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showVaultCreationSheet(BuildContext context, String vaultId) async {
  await showCreationSheet(
    context,
    CreationSheet(
      title: '이 Vault에서 만들기',
      onBack: () => Navigator.pop(context),
      rightText: '닫기',
      onRightTap: () => Navigator.pop(context),
      actions: [
        CreationAction(
          label: '폴더 생성',
          desc: '노트를 폴더로 정리',
          leading: SvgPicture.asset(AppIcons.folder, width: 32, height: 32),
          onTap: () async {
            // TODO: 폴더 생성 로직 연결
            Navigator.pop(context);
          },
        ),
        CreationAction(
          label: '노트 생성',
          leading: SvgPicture.asset(AppIcons.noteAdd, width: 32, height: 32),
          onTap: () async {
            final note = await context.read<NoteStore>()
                .createNote(vaultId: vaultId, title: '새 노트');
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
