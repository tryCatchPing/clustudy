// lib/design_system/components/molecules/folder_card.dart
import 'package:flutter/material.dart';

import '../../tokens/app_icons.dart';
import 'app_card.dart';

enum FolderType { normal, vault }

class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.type,
    required this.title,
    required this.date,
    this.onTap,
    this.onTitleChanged,
    this.onLongPressStart,
  });

  final FolderType type;
  final String title;
  final DateTime date;
  final VoidCallback? onTap;
  final ValueChanged<String>? onTitleChanged;
  final void Function(LongPressStartDetails details)? onLongPressStart;

  @override
  Widget build(BuildContext context) {
    final iconPath = (type == FolderType.vault)
        ? AppIcons.folderVaultLarge
        : AppIcons.folderLarge;

    return AppCard(
      svgIconPath: iconPath,
      title: title,
      date: date,
      onTap: onTap,
      onTitleChanged: onTitleChanged,
      onLongPressStart: onLongPressStart,
    );
  }
}
