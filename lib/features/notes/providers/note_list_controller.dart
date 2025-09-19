import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/errors/app_error_mapper.dart';
import '../../../shared/errors/app_error_spec.dart';
import '../../../shared/services/vault_notes_service.dart';
import '../../vaults/data/derived_vault_providers.dart';
import '../../vaults/data/vault_tree_repository_provider.dart';
import '../../vaults/models/vault_model.dart';

class NoteListState {
  const NoteListState({
    this.isImporting = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.searchResults = const <NoteSearchResult>[],
  });

  final bool isImporting;
  final bool isSearching;
  final String searchQuery;
  final List<NoteSearchResult> searchResults;

  NoteListState copyWith({
    bool? isImporting,
    bool? isSearching,
    String? searchQuery,
    List<NoteSearchResult>? searchResults,
  }) {
    return NoteListState(
      isImporting: isImporting ?? this.isImporting,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
    );
  }
}

final noteListControllerProvider =
    StateNotifierProvider<NoteListController, NoteListState>((ref) {
      return NoteListController(ref);
    });

class NoteListController extends StateNotifier<NoteListState> {
  NoteListController(this.ref) : super(const NoteListState());

  final Ref ref;
  Timer? _searchDebounce;

  VaultNotesService get _service => ref.read(vaultNotesServiceProvider);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void selectVault(String vaultId) {
    ref.read(currentVaultProvider.notifier).state = vaultId;
    ref.read(currentFolderProvider(vaultId).notifier).state = null;
  }

  Future<void> goUpOneLevel(String vaultId, String currentFolderId) async {
    final parent = await _service.getParentFolderId(vaultId, currentFolderId);
    ref.read(currentFolderProvider(vaultId).notifier).state = parent;
  }

  Future<AppErrorSpec> deleteNote({
    required String noteId,
    required String noteTitle,
  }) async {
    try {
      await _service.deleteNote(noteId);
      return AppErrorSpec.success('"$noteTitle" 노트를 삭제했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> importPdfNote() async {
    if (state.isImporting) {
      return const AppErrorSpec(
        severity: AppErrorSeverity.info,
        message: 'PDF를 이미 가져오고 있어요.',
      );
    }

    state = state.copyWith(isImporting: true);
    try {
      final vaultId = ref.read(currentVaultProvider) ?? 'default';
      final folderId = ref.read(currentFolderProvider(vaultId));
      final pdfNote = await _service.createPdfInFolder(
        vaultId,
        parentFolderId: folderId,
      );
      return AppErrorSpec.success('PDF 노트 "${pdfNote.title}"가 생성되었습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    } finally {
      state = state.copyWith(isImporting: false);
    }
  }

  Future<AppErrorSpec> createBlankNote() async {
    try {
      final vaultId = ref.read(currentVaultProvider) ?? 'default';
      final folderId = ref.read(currentFolderProvider(vaultId));
      final blankNote = await _service.createBlankInFolder(
        vaultId,
        parentFolderId: folderId,
      );
      return AppErrorSpec.success('빈 노트 "${blankNote.title}"가 생성되었습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  void updateSearchQuery(String query) {
    final trimmed = query.trim();
    state = state.copyWith(searchQuery: trimmed);
    _searchDebounce?.cancel();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        searchResults: const <NoteSearchResult>[],
        isSearching: false,
      );
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      await _runSearch(trimmed);
    });
  }

  Future<void> _runSearch(String query) async {
    final vaultId = ref.read(currentVaultProvider);
    if (vaultId == null) return;
    state = state.copyWith(isSearching: true);
    try {
      final results = await _service.searchNotesInVault(
        vaultId,
        query,
        limit: 50,
      );
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (_) {
      state = state.copyWith(isSearching: false);
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      searchQuery: '',
      searchResults: const <NoteSearchResult>[],
      isSearching: false,
    );
  }

  Future<FolderCascadeImpact> computeCascadeImpact(
    String vaultId,
    String rootFolderId,
  ) {
    return _service.computeFolderCascadeImpact(vaultId, rootFolderId);
  }

  Future<AppErrorSpec> deleteFolder({
    required String vaultId,
    required String folderId,
  }) async {
    try {
      await _service.deleteFolderCascade(folderId);
      ref.read(currentFolderProvider(vaultId).notifier).state = null;
      return const AppErrorSpec(
        severity: AppErrorSeverity.success,
        message: '폴더와 하위 항목이 삭제되었습니다.',
        duration: AppErrorDuration.short,
      );
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> deleteVault({
    required String vaultId,
    required String vaultName,
  }) async {
    try {
      await _service.deleteVault(vaultId);
      final repo = ref.read(vaultTreeRepositoryProvider);
      final List<VaultModel> remainingVaults = await repo.watchVaults().first;

      ref.read(currentFolderProvider(vaultId).notifier).state = null;

      if (remainingVaults.isEmpty) {
        ref.read(currentVaultProvider.notifier).state = null;
      } else {
        final nextVault = remainingVaults.first;
        ref.read(currentVaultProvider.notifier).state = nextVault.vaultId;
        ref.read(currentFolderProvider(nextVault.vaultId).notifier).state =
            null;
      }

      clearSearch();

      return AppErrorSpec.success('Vault "$vaultName"를 삭제했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> createVault(String name) async {
    try {
      final vault = await _service.createVault(name);
      ref.read(currentVaultProvider.notifier).state = vault.vaultId;
      ref.read(currentFolderProvider(vault.vaultId).notifier).state = null;
      return AppErrorSpec.success('Vault "${vault.name}"가 생성되었습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> createFolder(
    String vaultId,
    String? parentFolderId,
    String name,
  ) async {
    try {
      final folder = await _service.createFolder(
        vaultId,
        parentFolderId: parentFolderId,
        name: name,
      );
      return AppErrorSpec.success('폴더 "${folder.name}"가 생성되었습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> renameVault(String vaultId, String newName) async {
    try {
      await _service.renameVault(vaultId, newName);
      return AppErrorSpec.success('Vault 이름을 변경했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> renameFolder(String folderId, String newName) async {
    try {
      await _service.renameFolder(folderId, newName);
      return AppErrorSpec.success('폴더 이름을 변경했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> moveFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    try {
      await _service.moveFolderWithAutoRename(
        folderId: folderId,
        newParentFolderId: newParentFolderId,
      );
      return AppErrorSpec.success('폴더를 이동했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> renameNote(String noteId, String newName) async {
    try {
      await _service.renameNote(noteId, newName);
      return AppErrorSpec.success('노트 이름을 변경했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }

  Future<AppErrorSpec> moveNote({
    required String noteId,
    String? newParentFolderId,
  }) async {
    try {
      await _service.moveNoteWithAutoRename(
        noteId,
        newParentFolderId: newParentFolderId,
      );
      return AppErrorSpec.success('노트를 이동했습니다.');
    } catch (error) {
      return AppErrorMapper.toSpec(error);
    }
  }
}
