import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/organisms/top_toolbar.dart';
import '../../../design_system/tokens/app_colors.dart';
import '../../../design_system/tokens/app_icons.dart';
import '../../../design_system/tokens/app_spacing.dart';
import '../../../shared/dialogs/design_sheet_helpers.dart';
import '../../../shared/errors/app_error_mapper.dart';
import '../../../shared/errors/app_error_spec.dart';
import '../../../shared/routing/app_routes.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/folder_picker_dialog.dart';
import '../../vaults/data/derived_vault_providers.dart';
import '../../vaults/models/vault_item.dart';
import '../../vaults/models/vault_model.dart';
import '../providers/note_list_controller.dart';
import '../widgets/note_list_action_bar.dart';
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
    final shouldDelete = await showDesignConfirmDialog(
      context: context,
      title: '노트 삭제 확인',
      message: '정말로 "$noteTitle" 노트를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      confirmLabel: '삭제',
      destructive: true,
    );

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
    await showDesignNoteCreationFlow(
      context: context,
      onSubmit: (name) => _actions.createBlankNote(name: name),
    );
  }

  Future<void> _renameVaultPrompt(VaultModel vault) async {
    final newName = await showDesignRenameDialogTrimmed(
      context: context,
      title: 'Vault 이름 변경',
      initial: vault.name,
    );
    if (newName == null) return;
    final spec = await _actions.renameVault(vault.vaultId, newName);
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _confirmAndDeleteFolder({
    required String vaultId,
    required String folderId,
    required String folderName,
  }) async {
    try {
      final impact = await _actions.computeCascadeImpact(vaultId, folderId);
      final shouldDelete = await showDesignConfirmDialog(
        context: context,
        title: '폴더 삭제 확인',
        message:
            '폴더 "$folderName"를 삭제하면\n하위 폴더 ${impact.folderCount}개, 노트 ${impact.noteCount}개가 함께 삭제됩니다.\n\n이 작업은 되돌릴 수 없어요. 진행할까요?',
        confirmLabel: '삭제',
        destructive: true,
      );
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
    final shouldDelete = await showDesignConfirmDialog(
      context: context,
      title: 'Vault 삭제 확인',
      message:
          'Vault "$vaultName"를 삭제하면 모든 폴더와 노트가 함께 삭제됩니다.\n이 작업은 되돌릴 수 없어요. 진행할까요?',
      confirmLabel: '삭제',
      destructive: true,
    );

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
    await showDesignVaultCreationFlow(
      context: context,
      onSubmit: (name) => _actions.createVault(name),
    );
  }

  Future<void> _showCreateFolderDialog(
    String vaultId,
    String? parentFolderId,
  ) async {
    await showDesignFolderCreationFlow(
      context: context,
      onSubmit: (name) => _actions.createFolder(
        vaultId,
        parentFolderId,
        name,
      ),
    );
  }

  Future<void> _moveFolder({
    required String vaultId,
    required String? currentFolderId,
    required VaultItem folder,
  }) async {
    // TODO(design): 폴더 이동 전용 디자인 시트 요청 필요.
    //  - 입력: vaultId, currentFolderId, disabledFolderSubtreeRootId(folder.id)
    //  - 데이터: listFoldersWithPath(vaultId) → [folderId, name, pathLabel]
    //  - UI: 라디오 선택 + 루트 옵션, 선택/취소 버튼, 로딩/에러 상태 반영
    //  - 반환: 선택한 folderId (null = 루트)
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
    final newName = await showDesignRenameDialogTrimmed(
      context: context,
      title: '폴더 이름 변경',
      initial: folder.name,
    );
    if (newName == null) return;
    final spec = await _actions.renameFolder(
      folder.id,
      newName,
    );
    if (!mounted) return;
    AppSnackBar.show(context, spec);
  }

  Future<void> _moveNote({
    required String vaultId,
    required String? currentFolderId,
    required VaultItem note,
  }) async {
    // TODO(design): 노트 이동 시에도 동일한 디자인 시트 사용 예정.
    //  - 입력: vaultId, currentFolderId
    //  - 데이터: listFoldersWithPath(vaultId)
    //  - 반환: 선택한 folderId (null = 루트)
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
    final newName = await showDesignRenameDialogTrimmed(
      context: context,
      title: '노트 이름 변경',
      initial: note.name,
    );
    if (newName == null) return;
    final spec = await _actions.renameNote(
      note.id,
      newName,
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
  Widget build(BuildContext context) {
    final vaultsAsync = ref.watch(vaultsProvider);
    final noteListState = ref.watch(noteListControllerProvider);
    final String? currentVaultId = ref.watch(currentVaultProvider);
    final bool hasActiveVault = currentVaultId != null;
    debugPrint(
      '📄 NoteListScreen.build: hasActiveVault=$hasActiveVault vaultId=${currentVaultId ?? 'NONE'}',
    );

    String? currentFolderId;
    AsyncValue<List<VaultItem>>? itemsAsync;
    if (hasActiveVault) {
      currentFolderId = ref.watch(currentFolderProvider(currentVaultId));
      debugPrint(
        '📂 currentFolderId=${currentFolderId ?? 'ROOT'} for vault=$currentVaultId',
      );
      itemsAsync = ref.watch(
        vaultItemsProvider(
          FolderScope(
            currentVaultId,
            currentFolderId,
          ),
        ),
      );
      debugPrint(
        '👀 itemsAsync watched for scope: vault=$currentVaultId parent=${currentFolderId ?? 'ROOT'}',
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
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _actions.clearVaultSelection();
              }
            });
          }
        }
      };
      backSvgPath = AppIcons.chevronLeft;
    }

    // Removed createFolderAction from toolbar (location crumb takes over minimal nav)

    final VoidCallback? goUpAction = hasActiveVault && currentFolderId != null
        ? () {
            _goUpOneLevel(
              currentVaultId,
              currentFolderId!,
            );
          }
        : null;

    final VoidCallback? goToVaultsAction = hasActiveVault
        ? () {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _actions.clearVaultSelection();
                }
              });
            }
          }
        : null;

    return WillPopScope(
      onWillPop: () async {
        if (hasActiveVault && currentFolderId != null) {
          await _goUpOneLevel(currentVaultId, currentFolderId);
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              debugPrint('📐 NoteListScreen.body constraints: $constraints');
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.large,
                ),
                children: [
                  if (hasActiveVault)
                    NoteListActionBar(
                      variant: currentFolderId == null
                          ? NoteLocationVariant.root
                          : NoteLocationVariant.folder,
                      onTap: currentFolderId == null
                          ? goToVaultsAction!
                          : goUpAction!,
                    ),
                  if (!hasActiveVault) ...[
                    const SizedBox(height: AppSpacing.large),
                    VaultListPanel(
                      vaultsAsync: vaultsAsync,
                      onVaultSelected: _onVaultSelected,
                      onRenameVault: _renameVaultPrompt,
                      onDeleteVault: (vault) {
                        _confirmAndDeleteVault(
                          vaultId: vault.vaultId,
                          vaultName: vault.name,
                        );
                      },
                    ),
                  ] else if (itemsAsync != null) ...[
                    const SizedBox(height: AppSpacing.large),
                    // LayoutBuilder(
                    //   builder: (context, c) {
                    //     debugPrint(
                    //       '📐 NoteListFolderSection parent constraints: $c',
                    //     );
                    //     WidgetsBinding.instance.addPostFrameCallback((_) {
                    //       final size = context.size;
                    //       debugPrint(
                    //         '📏 NoteListFolderSection parent size: ${size?.width}x${size?.height}',
                    //       );
                    //     });
                    //     return const SizedBox.shrink();
                    //   },
                    // ),
                    NoteListFolderSection(
                      itemsAsync: itemsAsync,
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
                    const SizedBox(height: AppSpacing.xxl),
                  ] else ...[
                    const Text('No items'),
                  ],
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.large,
              right: AppSpacing.large,
              bottom: AppSpacing.large,
            ),
            child: SizedBox(
              height: 60,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: NoteListPrimaryActions(
                    hasActiveVault: hasActiveVault,
                    isImporting: noteListState.isImporting,
                    onImportPdf: () {
                      _importPdfNote();
                    },
                    onCreateBlankNote: () {
                      _createBlankNote();
                    },
                    onCreateFolder: () {
                      _showCreateFolderDialog(
                        currentVaultId!,
                        currentFolderId,
                      );
                    },
                    onCreateVault: _showCreateVaultDialog,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
