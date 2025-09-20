import 'package:flutter/material.dart';

import '../../../design_system/components/atoms/app_button.dart';
import '../../../design_system/tokens/app_icons.dart';

enum NoteLocationVariant { root, folder }

/// A minimal location crumb for navigation consistency.
/// - root: shows vault icon + "(...)" and navigates to vault list.
/// - folder: shows folder icon + "(...)" and navigates one level up.
class NoteListActionBar extends StatelessWidget {
  const NoteListActionBar({
    super.key,
    required this.variant,
    required this.onTap,
  });

  final NoteLocationVariant variant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String icon = variant == NoteLocationVariant.root
        ? AppIcons.folderVault
        : AppIcons.folder;
    final String label = variant == NoteLocationVariant.root
        ? '상위 Vault로 이동'
        : '상위 폴더로 이동';

    return Align(
      alignment: Alignment.centerLeft,
      child: AppButton.textIcon(
        text: label,
        svgIconPath: icon,
        onPressed: onTap,
        style: AppButtonStyle.secondary,
        size: AppButtonSize.sm,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        iconGap: 6,
        iconSize: 18,
      ),
    );
  }
}
