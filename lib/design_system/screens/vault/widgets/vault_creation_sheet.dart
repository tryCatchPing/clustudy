import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/organisms/creation_sheet.dart';
import '../../../tokens/app_icons.dart';

Future<void> showDesignVaultCreationSheet(BuildContext context) {
  return showCreationSheet(
    context,
    CreationSheet(
      title: '이 Vault에서 만들기',
      onBack: () => Navigator.pop(context),
      rightText: '닫기',
      onRightTap: () => Navigator.pop(context),
      actions: [
        CreationAction(
          label: '폴더 생성',
          desc: '노트를 폴더로 정리해요',
          leading: SvgPicture.asset(AppIcons.folder, width: 32, height: 32),
          onTap: () async {
            Navigator.pop(context);
            _showSnack(context, '폴더 생성');
          },
        ),
        CreationAction(
          label: '노트 생성',
          leading: SvgPicture.asset(AppIcons.noteAdd, width: 32, height: 32),
          onTap: () async {
            Navigator.pop(context);
            _showSnack(context, '노트 생성');
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
