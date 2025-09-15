import 'package:flutter/material.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../design_system/components/organisms/top_toolbar.dart';

class NoteScreen extends StatelessWidget {
  final String noteId;
  const NoteScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopToolbar(
        variant: TopToolbarVariant.folder, // 필요하면 note 전용 variant로 바꿔도 OK
        title: '노트',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text('Note ID: $noteId',
          style: const TextStyle(color: AppColors.gray50),
        ),
      ),
      backgroundColor: AppColors.background,
    );
  }
}
