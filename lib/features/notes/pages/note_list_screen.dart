import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../shared/errors/app_error_mapper.dart';
import '../../../shared/errors/app_error_spec.dart';
import '../../../shared/routing/app_routes.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/folder_picker_dialog.dart';
import '../../vaults/data/derived_vault_providers.dart';
import '../../vaults/models/vault_item.dart';
import '../../vaults/models/vault_model.dart';
import '../providers/note_list_controller.dart';
import '../widgets/name_input_dialog.dart';
import '../widgets/note_list_folder_section.dart';
import '../widgets/note_list_primary_actions.dart';
import '../widgets/note_list_vault_panel.dart';

// UI 전체 타임 라인: 현재는 FolderCascadeImpact와 연계

/// 노트 목록을 표시하고 새로운 노트를 생성하는 화면입니다.
///
/// 사용 경로 예시:
/// MyApp
/// └ HomeScreen
///   └ NavigationCard 로 노트 목록 이동 (/notes)
class NoteListScreen extends ConsumerStatefulWidget {
  /// [NoteListScreen]의 생성자.
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen> {
  NoteListController get _actions =>
      ref.read(noteListControllerProvider.notifier);

  void _onVaultSelected(String vaultId) {
    _actions.selectVault(vaultId);
  }

  void _onFolderSelected(String vaultId, String folderId) {
    _actions.selectFolder(vaultId, folderId);
  }

  Future<void> _goUpOneLevel(String vaultId, String currentFolderId) async {
    await _actions.goUpOneLevel(vaultId, currentFolderId);
  }

  Future<void> _confirmAndDeleteNote({
    required String noteId,
    required String noteTitle,
  }) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('노트 삭제 확인'),
            content: Text(
              '정말로 "$noteTitle" 노트를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        AppErrorSpec.info('삭제를 취소했어요.'),
      );
      return;
    }

    final spec = await _actions.deleteNote(
      noteId: noteId,
      noteTitle: noteTitle,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _importPdfNote() async {
    final spec = await _actions.importPdfNote();
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _createBlankNote() async {
    final spec = await _actions.createBlankNote();
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _showVaultActions(VaultModel vault) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('이름 변경'),
              onTap: () => Navigator.of(context).pop('rename'),
            ),
            if (vault.vaultId != 'default')
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                title: const Text('Vault 삭제'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result == 'rename') {
      final name = await showNameInputDialog(
        context: context,
        title: 'Vault 이름 변경',
        hintText: '새 이름',
        confirmLabel: '변경',
      );
      final trimmed = name?.trim() ?? '';
      if (trimmed.isEmpty) return;
      final spec = await _actions.renameVault(vault.vaultId, trimmed);
      if (!mounted) return;
      AppSnackBar.show(context, spec);
      return;
    }

    if (result == 'delete') {
      await _confirmAndDeleteVault(
        vaultId: vault.vaultId,
        vaultName: vault.name,
      );
    }
  }

  Future<void> _confirmAndDeleteFolder({
    required String vaultId,
    required String folderId,
    required String folderName,
  }) async {
    try {
      final impact = await _actions.computeCascadeImpact(vaultId, folderId);
      final shouldDelete =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('폴더 삭제 확인'),
              content: Text(
                '폴더 "$folderName"를 삭제하면\n'
                '하위 폴더 ${impact.folderCount}개, 노트 ${impact.noteCount}개가 사라집니다.\n\n'
                '이 작업은 되돌릴 수 없어요. 진행할까요?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('삭제'),
                ),
              ],
            ),
          ) ??
          false;
      if (!shouldDelete) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          AppErrorSpec.info('삭제를 취소했어요.'),
        );
        return;
      }

      final spec = await _actions.deleteFolder(
        vaultId: vaultId,
        folderId: folderId,
      );
      if (!mounted) return;
      AppSnackBar.show(context, spec);
    } catch (error) {
      if (!mounted) return;
      final spec = AppErrorMapper.toSpec(error);
      AppSnackBar.show(context, spec);
    }
  }

  Future<void> _confirmAndDeleteVault({
    required String vaultId,
    required String vaultName,
  }) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vault 삭제 확인'),
            content: Text(
              'Vault "$vaultName"를 삭제하면 모든 폴더와 노트가 함께 삭제됩니다.\n'
              '이 작업은 되돌릴 수 없어요. 진행할까요?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        AppErrorSpec.info('삭제를 취소했어요.'),
      );
      return;
    }

    final spec = await _actions.deleteVault(
      vaultId: vaultId,
      vaultName: vaultName,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _showCreateVaultDialog() async {
    final name = await showNameInputDialog(
      context: context,
      title: 'Vault 생성',
      hintText: 'Vault 이름',
      confirmLabel: '생성',
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final spec = await _actions.createVault(trimmed);
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _showCreateFolderDialog(
    String vaultId,
    String? parentFolderId,
  ) async {
    final name = await showNameInputDialog(
      context: context,
      title: '폴더 생성',
      hintText: '폴더 이름',
      confirmLabel: '생성',
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final spec = await _actions.createFolder(
      vaultId,
      parentFolderId,
      trimmed,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _moveFolder({
    required String vaultId,
    required String? currentFolderId,
    required VaultItem folder,
  }) async {
    final picked = await FolderPickerDialog.show(
      context,
      vaultId: vaultId,
      initialFolderId: currentFolderId,
      disabledFolderSubtreeRootId: folder.id,
    );
    if (!mounted) return;
    final spec = await _actions.moveFolder(
      folderId: folder.id,
      newParentFolderId: picked,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _renameFolder(VaultItem folder) async {
    final name = await showNameInputDialog(
      context: context,
      title: '폴더 이름 변경',
      hintText: '새 이름',
      confirmLabel: '변경',
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    final spec = await _actions.renameFolder(
      folder.id,
      trimmed,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _moveNote({
    required String vaultId,
    required String? currentFolderId,
    required VaultItem note,
  }) async {
    final picked = await FolderPickerDialog.show(
      context,
      vaultId: vaultId,
      initialFolderId: currentFolderId,
    );
    if (!mounted) return;
    final spec = await _actions.moveNote(
      noteId: note.id,
      newParentFolderId: picked,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _renameNote(VaultItem note) async {
    final name = await showNameInputDialog(
      context: context,
      title: '노트 이름 변경',
      hintText: '새 이름',
      confirmLabel: '변경',
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;
    final spec = await _actions.renameNote(
      note.id,
      trimmed,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  void _openNote(VaultItem note) {
    context.pushNamed(
      AppRoutes.noteEditName,
      pathParameters: {
        'noteId': note.id,
      },
    );
  }

  void _goToNoteSearch() {
    context.pushNamed(AppRoutes.noteSearchName);
  }

  void _goToVaultGraph() {
    context.pushNamed(AppRoutes.vaultGraphName);
  }

  @override
  @override
  Widget build(BuildContext context) {
    final vaultsAsync = ref.watch(vaultsProvider);
    final noteListState = ref.watch(noteListControllerProvider);
    final String? currentVaultId = ref.watch(currentVaultProvider);
    final bool hasActiveVault = currentVaultId != null;

    String? currentFolderId;
    AsyncValue<List<VaultItem>>? itemsAsync;
    if (hasActiveVault) {
      currentFolderId = ref.watch(currentFolderProvider(currentVaultId));
      itemsAsync = ref.watch(
        vaultItemsProvider(
          FolderScope(
            currentVaultId,
            currentFolderId,
          ),
        ),
      );
    }

    VaultModel? activeVault;
    final vaultsValue = vaultsAsync.valueOrNull;
    if (hasActiveVault && vaultsValue != null) {
      for (final vault in vaultsValue) {
        if (vault.vaultId == currentVaultId) {
          activeVault = vault;
          break;
        }
      }
    }

    final bool isFolderSelected = hasActiveVault && currentFolderId != null;
    final folderAsync = isFolderSelected
        ? ref.watch(folderByIdProvider(currentFolderId))
        : null;

    final folderTitle =
        folderAsync?.maybeWhen(
          data: (folder) => folder?.name,
          orElse: () => null,
        ) ??
        (isFolderSelected ? '폴더 불러오는 중...' : null);

    final toolbarTitle = !hasActiveVault
        ? 'Clustudy'
        : isFolderSelected
        ? (folderTitle ?? '폴더')
        : (activeVault?.name ?? '노트');

    final toolbarVariant = !hasActiveVault
        ? TopToolbarVariant.landing
        : TopToolbarVariant.folder;

    final toolbarActions = !hasActiveVault
        ? [
            ToolbarAction(
              svgPath: AppIcons.settings,
              onTap: () {},
              tooltip: '설정',
            ),
          ]
        : [
            ToolbarAction(
              svgPath: AppIcons.search,
              onTap: _goToNoteSearch,
              tooltip: '노트 검색',
            ),
            ToolbarAction(
              svgPath: AppIcons.graphView,
              onTap: _goToVaultGraph,
              tooltip: '그래프 보기',
            ),
          ];

    VoidCallback? onBack;
    String? backSvgPath;
    if (isFolderSelected) {
      onBack = () {
        final folderId = currentFolderId;
        final vaultId = currentVaultId;
        if (folderId == null) {
          return;
        }
        _goUpOneLevel(vaultId, folderId);
      };
      backSvgPath = AppIcons.chevronLeft;
    } else if (hasActiveVault) {
      onBack = () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).maybePop();
        } else {
          _actions.clearVaultSelection();
        }
      };
      backSvgPath = AppIcons.chevronLeft;
    }

    return WillPopScope(
      onWillPop: () async {
        if (hasActiveVault && currentFolderId != null) {
          await _goUpOneLevel(currentVaultId, currentFolderId);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: TopToolbar(
          variant: toolbarVariant,
          title: toolbarTitle,
          onBack: onBack,
          backSvgPath: backSvgPath,
          actions: toolbarActions,
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '작업할 노트들',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                VaultListPanel(
                  vaultsAsync: vaultsAsync,
                  hasActiveVault: hasActiveVault,
                  onCreateVault: _showCreateVaultDialog,
                  onVaultSelected: _onVaultSelected,
                  onShowVaultActions: _showVaultActions,
                  onGoToSearch: _goToNoteSearch,
                  onClearSelection: _actions.clearVaultSelection,
                  onGoToGraph: _goToVaultGraph,
                ),
                if (hasActiveVault && itemsAsync != null) ...[
                  const SizedBox(height: AppSpacing.large),
                  NoteListFolderSection(
                    itemsAsync: itemsAsync,
                    currentFolderId: currentFolderId,
                    onCreateFolder: () {
                      _showCreateFolderDialog(
                        currentVaultId,
                        currentFolderId,
                      );
                    },
                    onGoUp: currentFolderId == null
                        ? null
                        : () {
                            _goUpOneLevel(
                              currentVaultId,
                              currentFolderId!,
                            );
                          },
                    onReturnToVaultSelection: _actions.clearVaultSelection,
                    onOpenFolder: (folder) {
                      _onFolderSelected(currentVaultId, folder.id);
                    },
                    onMoveFolder: (folder) {
                      _moveFolder(
                        vaultId: currentVaultId,
                        currentFolderId: currentFolderId,
                        folder: folder,
                      );
                    },
                    onRenameFolder: (folder) {
                      _renameFolder(folder);
                    },
                    onDeleteFolder: (folder) {
                      _confirmAndDeleteFolder(
                        vaultId: currentVaultId,
                        folderId: folder.id,
                        folderName: folder.name,
                      );
                    },
                    onOpenNote: _openNote,
                    onMoveNote: (note) {
                      _moveNote(
                        vaultId: currentVaultId,
                        currentFolderId: currentFolderId,
                        note: note,
                      );
                    },
                    onRenameNote: (note) {
                      _renameNote(note);
                    },
                    onDeleteNote: (note) {
                      _confirmAndDeleteNote(
                        noteId: note.id,
                        noteTitle: note.name,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: hasActiveVault
            ? SafeArea(
                top: false,
                minimum: const EdgeInsets.only(
                  left: AppSpacing.large,
                  right: AppSpacing.large,
                  bottom: AppSpacing.large,
                ),
                child: NoteListPrimaryActions(
                  isImporting: noteListState.isImporting,
                  onImportPdf: () {
                    _importPdfNote();
                  },
                  onCreateBlankNote: () {
                    _createBlankNote();
                  },
                  onCreateFolder: () {
                    _showCreateFolderDialog(
                      currentVaultId,
                      currentFolderId,
                    );
                  },
                ),
              )
            : null,
      ),
    );
  }
}
