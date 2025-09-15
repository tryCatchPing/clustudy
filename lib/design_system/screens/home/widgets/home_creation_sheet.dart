import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/organisms/creation_sheet.dart';
import '../../../tokens/app_icons.dart';

Future<void> showDesignHomeCreationSheet(BuildContext context) {
  return showCreationSheet(
    context,
    CreationSheet(
      title: '새로 만들기',
      onBack: () => Navigator.pop(context),
      rightText: '닫기',
      onRightTap: () => Navigator.pop(context),
      actions: [
        CreationAction(
          label: 'Vault 생성',
          desc: '새로운 작업 공간을 미리 살펴봐요',
          leading: SvgPicture.asset(AppIcons.folderVault, width: 28, height: 28),
          onTap: () async {
            Navigator.pop(context);
            _showSnack(context, '새 Vault 생성');
          },
        ),
        CreationAction(
          label: '노트 생성',
          desc: '임시 Vault에 바로 필기할 수 있어요',
          leading: SvgPicture.asset(AppIcons.noteAdd, width: 28, height: 28),
          onTap: () async {
            Navigator.pop(context);
            _showSnack(context, '새 노트 생성');
          },
        ),
        CreationAction(
          label: 'PDF 가져오기',
          desc: 'PDF를 불러와 주석을 추가해요',
          leading: SvgPicture.asset(AppIcons.download, width: 28, height: 28),
          onTap: () async {
            Navigator.pop(context);
            _showSnack(context, 'PDF 가져오기');
          },
        ),
      ],
    ),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(milliseconds: 800)),
  );
}
