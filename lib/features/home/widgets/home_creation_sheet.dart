import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/components/organisms/creation_sheet.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../vaults/state/vault_store.dart';
import '../../notes/state/note_store.dart';
import '../../../routing/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showHomeCreationSheet(BuildContext context) async {
  final vaultStore = context.read<VaultStore>();
  final temp = await vaultStore.ensureTempVault();

  await showCreationSheet(
    context,
    CreationSheet(
      title: '새로 만들기',
      onBack: () => Navigator.pop(context),
      rightText: '완료',
      onRightTap: () => Navigator.pop(context),
      actions: [
        CreationAction(
          label: 'Vault 생성',
          desc: '새로운 작업 공간을 만듭니다',
          leading: SvgPicture.asset(AppIcons.folderVault, width: 28, height: 28),
          onTap: () async {
            await vaultStore.createVault('새 Vault');
            if (context.mounted) Navigator.pop(context);
          },
        ),
        CreationAction(
          label: '노트 생성(임시 Vault)',
          desc: '바로 필기할 수 있는 빈 노트',
          leading: SvgPicture.asset(AppIcons.noteAdd, width: 28, height: 28),
          onTap: () async {
            final note = await context.read<NoteStore>()
                .createNote(vaultId: temp.id, title: '새 노트');
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
