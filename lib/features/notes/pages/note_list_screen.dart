import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/errors/app_error_mapper.dart';
import '../../../shared/errors/app_error_spec.dart';
import '../../../shared/routing/app_routes.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/folder_picker_dialog.dart';
import '../../../shared/widgets/navigation_card.dart';
import '../../vaults/data/derived_vault_providers.dart';
import '../../vaults/models/vault_item.dart';
import '../providers/note_list_controller.dart';

// UI 전용 타입 제거: 서비스의 FolderCascadeImpact로 대체

/// 노트 목록을 표시하고 새로운 노트를 생성하는 화면입니다.
///
/// 위젯 계층 구조:
/// MyApp
/// ㄴ HomeScreen
///   ㄴ NavigationCard → 라우트 이동 (/notes) → (현 위젯)
class NoteListScreen extends ConsumerStatefulWidget {
  /// [NoteListScreen]의 생성자.
  const NoteListScreen({super.key});

  @override
  ConsumerState<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends ConsumerState<NoteListScreen> {
  late final TextEditingController _searchCtrl;

  NoteListController get _actions =>
      ref.read(noteListControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onVaultSelected(String vaultId) {
    _actions.selectVault(vaultId);
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

  void _onSearchChanged(String text) {
    _actions.updateSearchQuery(text);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _actions.clearSearch();
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
                '하위 포함 폴더 ${impact.folderCount}개, 노트 ${impact.noteCount}개가 삭제됩니다.\n\n'
                '이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?',
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
              'Vault "$vaultName"를 삭제하면 모든 폴더와 노트가 영구적으로 제거됩니다.\n'
              '이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?',
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
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NameInputDialog(
        title: 'Vault 생성',
        hintText: 'Vault 이름',
        confirmLabel: '생성',
      ),
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
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _NameInputDialog(
        title: '폴더 생성',
        hintText: '폴더 이름',
        confirmLabel: '생성',
      ),
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

  @override
  Widget build(BuildContext context) {
    ref.listen<NoteListState>(
      noteListControllerProvider,
      (previous, next) {
        if (_searchCtrl.text == next.searchQuery) return;
        _searchCtrl
          ..text = next.searchQuery
          ..selection = TextSelection.collapsed(
            offset: next.searchQuery.length,
          );
      },
    );
    final vaultsAsync = ref.watch(vaultsProvider);
    final noteListState = ref.watch(noteListControllerProvider);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '노트 목록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6750A4),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎯 노트 목록 영역
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.1).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '저장된 노트들',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1C1B1F),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Vault 선택 드롭다운
                      vaultsAsync.when(
                        data: (vaults) {
                          if (vaults.isEmpty) {
                            return const Text('생성된 Vault가 없습니다.');
                          }
                          final currentVaultId = ref.watch(
                            currentVaultProvider,
                          );
                          final selectedVault = vaults.firstWhere(
                            (v) =>
                                v.vaultId ==
                                (currentVaultId ?? vaults.first.vaultId),
                            orElse: () => vaults.first,
                          );
                          final targetVaultId =
                              currentVaultId ?? selectedVault.vaultId;
                          final disableDelete = targetVaultId == 'default';
                          final items = vaults
                              .map(
                                (v) => DropdownMenuItem<String>(
                                  value: v.vaultId,
                                  child: Text(v.name),
                                ),
                              )
                              .toList(growable: false);
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const Text(
                                  'Vault: ',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value:
                                      currentVaultId ??
                                      (vaults.isNotEmpty
                                          ? vaults.first.vaultId
                                          : null),
                                  items: items,
                                  onChanged: (val) {
                                    if (val != null) _onVaultSelected(val);
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _showCreateVaultDialog,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Vault 추가'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    if (currentVaultId == null) return;
                                    final name = await showDialog<String>(
                                      context: context,
                                      builder: (context) =>
                                          const _NameInputDialog(
                                            title: 'Vault 이름 변경',
                                            hintText: '새 이름',
                                            confirmLabel: '변경',
                                          ),
                                    );
                                    final trimmed = name?.trim() ?? '';
                                    if (trimmed.isEmpty) return;
                                    final spec = await _actions.renameVault(
                                      currentVaultId,
                                      trimmed,
                                    );
                                    if (!mounted) return;
                                    AppSnackBar.show(context, spec);
                                  },
                                  icon: const Icon(
                                    Icons.drive_file_rename_outline,
                                  ),
                                  label: const Text('이름 변경'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: currentVaultId == null
                                      ? null
                                      : () {
                                          context.pushNamed(
                                            AppRoutes.vaultGraphName,
                                          );
                                        },
                                  icon: const Icon(Icons.hub),
                                  label: const Text('그래프 보기'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: disableDelete
                                      ? null
                                      : () => _confirmAndDeleteVault(
                                          vaultId: targetVaultId,
                                          vaultName: selectedVault.name,
                                        ),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Vault 삭제'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 12),

                      // 노트 검색
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          labelText: '노트 검색',
                          hintText: '제목으로 검색',
                          border: const OutlineInputBorder(),
                          suffixIcon: noteListState.searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.clear),
                                ),
                        ),
                        onChanged: _onSearchChanged,
                      ),

                      const SizedBox(height: 12),

                      // 검색 결과 또는 Placement 기반 브라우저
                      noteListState.searchQuery.isNotEmpty
                          ? Builder(
                              builder: (_) {
                                final currentVaultId = ref.watch(
                                  currentVaultProvider,
                                );
                                if (currentVaultId == null) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (noteListState.isSearching) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (noteListState.searchResults.isEmpty) {
                                  return const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text('검색 결과가 없습니다.'),
                                  );
                                }
                                return Column(
                                  children: [
                                    for (final r
                                        in noteListState.searchResults) ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: NavigationCard(
                                              icon: Icons.brush,
                                              title: r.title,
                                              subtitle:
                                                  r.parentFolderName ?? '루트',
                                              color: const Color(0xFF6750A4),
                                              onTap: () {
                                                context.pushNamed(
                                                  AppRoutes.noteEditName,
                                                  pathParameters: {
                                                    'noteId': r.noteId,
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              },
                            )
                          : vaultsAsync.when(
                              data: (vaults) {
                                if (vaults.isEmpty) {
                                  return const Text('생성된 Vault가 없습니다.');
                                }
                                // Ensure current vault is set
                                final currentVaultId = ref.watch(
                                  currentVaultProvider,
                                );
                                if (currentVaultId == null) {
                                  // pick the first vault
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    ref
                                            .read(currentVaultProvider.notifier)
                                            .state =
                                        vaults.first.vaultId;
                                    // Also reset folder scope for the selected vault
                                    ref
                                            .read(
                                              currentFolderProvider(
                                                vaults.first.vaultId,
                                              ).notifier,
                                            )
                                            .state =
                                        null;
                                  });
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final currentFolderId = ref.watch(
                                  currentFolderProvider(currentVaultId),
                                );
                                final itemsAsync = ref.watch(
                                  vaultItemsProvider(
                                    FolderScope(
                                      currentVaultId,
                                      currentFolderId,
                                    ),
                                  ),
                                );

                                return itemsAsync.when(
                                  data: (items) {
                                    final folders = items
                                        .where(
                                          (it) =>
                                              it.type == VaultItemType.folder,
                                        )
                                        .toList();
                                    final notes = items
                                        .where(
                                          (it) => it.type == VaultItemType.note,
                                        )
                                        .toList();

                                    return Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _showCreateFolderDialog(
                                                  currentVaultId,
                                                  currentFolderId,
                                                ),
                                            icon: const Icon(
                                              Icons.create_new_folder,
                                            ),
                                            label: const Text('폴더 추가'),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (currentFolderId != null) ...[
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: () async {
                                                await _goUpOneLevel(
                                                  currentVaultId,
                                                  currentFolderId,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.arrow_upward,
                                              ),
                                              label: const Text('한 단계 위로'),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],

                                        if (folders.isEmpty && notes.isEmpty)
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text('현재 위치에 항목이 없습니다.'),
                                          ),

                                        // Folders
                                        for (final it in folders) ...[
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: NavigationCard(
                                                  icon: Icons.folder,
                                                  title: it.name,
                                                  subtitle: '폴더',
                                                  color: Colors.amber[700]!,
                                                  onTap: () {
                                                    ref
                                                        .read(
                                                          currentFolderProvider(
                                                            currentVaultId,
                                                          ).notifier,
                                                        )
                                                        .state = it
                                                        .id;
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: '폴더 이동',
                                                onPressed: () async {
                                                  final picked =
                                                      await FolderPickerDialog.show(
                                                        context,
                                                        vaultId: currentVaultId,
                                                        initialFolderId:
                                                            currentFolderId,
                                                        disabledFolderSubtreeRootId:
                                                            it.id,
                                                      );
                                                  if (!mounted) return;
                                                  final spec = await _actions
                                                      .moveFolder(
                                                        folderId: it.id,
                                                        newParentFolderId:
                                                            picked,
                                                      );
                                                  if (!mounted) return;
                                                  AppSnackBar.show(
                                                    context,
                                                    spec,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.drive_file_move_outline,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: '폴더 이름 변경',
                                                onPressed: () async {
                                                  final name =
                                                      await showDialog<String>(
                                                        context: context,
                                                        builder: (context) =>
                                                            const _NameInputDialog(
                                                              title: '폴더 이름 변경',
                                                              hintText: '새 이름',
                                                              confirmLabel:
                                                                  '변경',
                                                            ),
                                                      );
                                                  final trimmed =
                                                      name?.trim() ?? '';
                                                  if (trimmed.isEmpty) return;
                                                  final spec = await _actions
                                                      .renameFolder(
                                                        it.id,
                                                        trimmed,
                                                      );
                                                  if (!mounted) return;
                                                  AppSnackBar.show(
                                                    context,
                                                    spec,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons
                                                      .drive_file_rename_outline,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: '폴더 삭제',
                                                onPressed: () =>
                                                    _confirmAndDeleteFolder(
                                                      vaultId: currentVaultId,
                                                      folderId: it.id,
                                                      folderName: it.name,
                                                    ),
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                        ],

                                        // Notes
                                        for (final it in notes) ...[
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: NavigationCard(
                                                  icon: Icons.brush,
                                                  title: it.name,
                                                  subtitle: '노트',
                                                  color: const Color(
                                                    0xFF6750A4,
                                                  ),
                                                  onTap: () {
                                                    context.pushNamed(
                                                      AppRoutes.noteEditName,
                                                      pathParameters: {
                                                        'noteId': it.id,
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: '노트 이동',
                                                onPressed: () async {
                                                  final picked =
                                                      await FolderPickerDialog.show(
                                                        context,
                                                        vaultId: currentVaultId,
                                                        initialFolderId:
                                                            currentFolderId,
                                                      );
                                                  if (!mounted) return;
                                                  final spec = await _actions
                                                      .moveNote(
                                                        noteId: it.id,
                                                        newParentFolderId:
                                                            picked,
                                                      );
                                                  if (!mounted) return;
                                                  AppSnackBar.show(
                                                    context,
                                                    spec,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.drive_file_move_outline,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: '노트 이름 변경',
                                                onPressed: () async {
                                                  final name =
                                                      await showDialog<String>(
                                                        context: context,
                                                        builder: (context) =>
                                                            const _NameInputDialog(
                                                              title: '노트 이름 변경',
                                                              hintText: '새 이름',
                                                              confirmLabel:
                                                                  '변경',
                                                            ),
                                                      );
                                                  final trimmed =
                                                      name?.trim() ?? '';
                                                  if (trimmed.isEmpty) return;
                                                  final spec = await _actions
                                                      .renameNote(
                                                        it.id,
                                                        trimmed,
                                                      );
                                                  if (!mounted) return;
                                                  AppSnackBar.show(
                                                    context,
                                                    spec,
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons
                                                      .drive_file_rename_outline,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: '노트 삭제',
                                                onPressed: () =>
                                                    _confirmAndDeleteNote(
                                                      noteId: it.id,
                                                      noteTitle: it.name,
                                                    ),
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ],
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (e, _) =>
                                      Center(child: Text('오류: $e')),
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (e, _) => Center(child: Text('오류: $e')),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // PDF 가져오기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: noteListState.isImporting
                        ? null
                        : _importPdfNote,
                    icon: noteListState.isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      noteListState.isImporting
                          ? 'PDF 가져오는 중...'
                          : 'PDF 파일에서 노트 생성',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 노트 생성 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF6750A4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFF6750A4),
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () => _createBlankNote(),
                    child: const Text('노트 생성'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameInputDialog extends StatefulWidget {
  final String title;
  final String hintText;
  final String confirmLabel;
  const _NameInputDialog({
    required this.title,
    required this.hintText,
    required this.confirmLabel,
  });

  @override
  State<_NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<_NameInputDialog> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    _submitted = true;
    final input = _controller.text.trim();
    if (input.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(input);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: widget.hintText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
