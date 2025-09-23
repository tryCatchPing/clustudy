import 'package:flutter/material.dart';

import '../../../design_system/components/organisms/bottom_actions_dock_fixed.dart';
import '../../../design_system/tokens/app_icons.dart';

/// Bottom primary actions for the note list area.
///
/// - When no vault is selected, shows a single "Vault 생성" action.
/// - When a vault is active, shows the three standard actions
///   (PDF 불러오기, 노트 만들기, 폴더 만들기).
class NoteListPrimaryActions extends StatelessWidget {
  const NoteListPrimaryActions({
    super.key,
    required this.hasActiveVault,
    required this.isImporting,
    required this.onImportPdf,
    required this.onCreateBlankNote,
    required this.onCreateFolder,
    required this.onCreateVault,
  });

  final bool hasActiveVault;
  final bool isImporting;
  final VoidCallback onImportPdf;
  final VoidCallback onCreateBlankNote;
  final VoidCallback onCreateFolder;
  final VoidCallback onCreateVault;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BottomActionsDockFixed(
        items: hasActiveVault
            ? [
                DockItem(
                  label: '폴더 만들기',
                  svgPath: AppIcons.folderAdd,
                  onTap: onCreateFolder,
                  tooltip: '폴더 생성',
                ),
                DockItem(
                  label: '노트 만들기',
                  svgPath: AppIcons.noteAdd,
                  onTap: onCreateBlankNote,
                  tooltip: '빈 노트 생성',
                ),
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
              ]
            : [
                DockItem(
                  label: 'vault 만들기',
                  svgPath: AppIcons.plus,
                  onTap: onCreateVault,
                  tooltip: '새 Vault 생성',
                ),
                DockItem(
                  label: '노트 만들기',
                  svgPath: AppIcons.noteAdd,
                  onTap: onCreateBlankNote,
                  tooltip: '빈 노트 생성',
                ),
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
              ],
      ),
    );
  }
}
