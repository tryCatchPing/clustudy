import 'package:flutter/material.dart';

import '../../../design_system/components/atoms/app_button.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';

class NoteListActionBar extends StatelessWidget {
  const NoteListActionBar({
    super.key,
    required this.hasActiveVault,
    required this.onCreateVault,
    this.onCreateFolder,
    this.onGoUp,
    this.onGoToVaults,
  });

  final bool hasActiveVault;
  final VoidCallback onCreateVault;
  final VoidCallback? onCreateFolder;
  final VoidCallback? onGoUp;
  final VoidCallback? onGoToVaults;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (!hasActiveVault)
        AppButton.textIcon(
          text: 'Vault 생성',
          svgIconPath: AppIcons.plus,
          onPressed: onCreateVault,
          style: AppButtonStyle.primary,
          size: AppButtonSize.md,
        )
      else ...[
        if (onCreateFolder != null)
          AppButton.textIcon(
            text: '폴더 추가',
            svgIconPath: AppIcons.folderAdd,
            onPressed: onCreateFolder,
            style: AppButtonStyle.secondary,
            size: AppButtonSize.sm,
          ),
        if (onGoUp != null)
          AppButton.textIcon(
            text: '한 단계 위로',
            svgIconPath: AppIcons.chevronLeft,
            onPressed: onGoUp,
            style: AppButtonStyle.secondary,
            size: AppButtonSize.sm,
          ),
        if (onGoToVaults != null)
          AppButton.textIcon(
            text: 'Vault 목록으로',
            svgIconPath: AppIcons.folderVault,
            onPressed: onGoToVaults,
            style: AppButtonStyle.secondary,
            size: AppButtonSize.sm,
          ),
      ],
    ];

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: buttons,
    );
  }
}
