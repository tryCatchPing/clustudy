import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/organisms/creation_sheet.dart';
import '../../../tokens/app_icons.dart';
import '../../../tokens/app_spacing.dart';
import '../../../tokens/app_typography.dart';
import '../../folder/widgets/folder_creation_sheet.dart';
import '../../vault/widgets/vault_creation_sheet.dart';
import '../../notes/widgets/note_creation_sheet.dart';

Future<void> showDesignHomeCreationSheet(BuildContext context) {
  return showCreationSheet(
    context,
    CreationBaseSheet(
      title: '새로 만들기',
      onBack: () => Navigator.pop(context),
      rightText: '닫기',
      onRightTap: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CreationActionTile(
            iconPath: AppIcons.folderVault,
            label: '새 Vault 생성',
            description: '프로젝트용 작업 공간을 준비합니다',
            onTap: () async {
              Navigator.pop(context);
              await showDesignVaultCreationSheet(context);
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          _CreationActionTile(
            iconPath: AppIcons.folder,
            label: '폴더 생성',
            description: 'Vault 안에서 노트를 묶어 관리합니다',
            onTap: () async {
              Navigator.pop(context);
              await showDesignFolderCreationSheet(context);
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          _CreationActionTile(
            iconPath: AppIcons.noteAdd,
            label: '노트 생성',
            description: '바로 필기할 수 있는 노트를 준비합니다',
            onTap: () async {
              Navigator.pop(context);
              await showDesignNoteCreationSheet(context);
            },
          ),
        ],
      ),
    ),
  );
}

class _CreationActionTile extends StatelessWidget {
  const _CreationActionTile({
    required this.iconPath,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SvgPicture.asset(iconPath, width: 28, height: 28),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body1.copyWith(color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
