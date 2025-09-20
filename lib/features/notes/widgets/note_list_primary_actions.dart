import 'package:flutter/material.dart';

import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/tokens/app_icons.dart';

class NoteListPrimaryActions extends StatelessWidget {
  const NoteListPrimaryActions({
    super.key,
    required this.isImporting,
    required this.onImportPdf,
    required this.onCreateBlankNote,
    required this.onCreateFolder,
  });

  final bool isImporting;
  final VoidCallback onImportPdf;
  final VoidCallback onCreateBlankNote;
  final VoidCallback onCreateFolder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BottomActionsDockFixed(
        items: [
          DockItem(
            label: 'PDF 불러오기',
            svgPath: AppIcons.download,
            onTap: () {
              if (isImporting) return;
              onImportPdf();
            },
            tooltip: 'PDF 파일로 노트 생성',
            loading: isImporting,
          ),
          DockItem(
            label: '노트 만들기',
            svgPath: AppIcons.noteAdd,
            onTap: onCreateBlankNote,
            tooltip: '빈 노트 생성',
          ),
          DockItem(
            label: '폴더 만들기',
            svgPath: AppIcons.folderAdd,
            onTap: onCreateFolder,
            tooltip: '폴더 생성',
          ),
        ],
      ),
    );
  }
}
