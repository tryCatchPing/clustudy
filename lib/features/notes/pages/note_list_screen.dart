import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/routing/app_routes.dart';
import '../../../shared/services/vault_notes_service.dart';
import '../../../shared/widgets/navigation_card.dart';
import '../../vaults/data/derived_vault_providers.dart';
import '../../vaults/models/vault_item.dart';

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
  bool _isImporting = false;

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

    if (!shouldDelete) return;

    try {
      final service = ref.read(vaultNotesServiceProvider);
      await service.deleteNote(noteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$noteTitle" 노트를 삭제했습니다.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('노트 삭제 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// PDF 파일을 선택하고 노트로 가져옵니다.
  Future<void> _importPdfNote() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);

    try {
      final vaultId = ref.read(currentVaultProvider) ?? 'default';
      final folderId = ref.read(currentFolderProvider(vaultId));
      final service = ref.read(vaultNotesServiceProvider);
      final pdfNote = await service.createPdfInFolder(
        vaultId,
        parentFolderId: folderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 노트 "${pdfNote.title}"가 성공적으로 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 노트 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _createBlankNote() async {
    try {
      final vaultId = ref.read(currentVaultProvider) ?? 'default';
      final folderId = ref.read(currentFolderProvider(vaultId));
      final service = ref.read(vaultNotesServiceProvider);
      final blankNote = await service.createBlankInFolder(
        vaultId,
        parentFolderId: folderId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('빈 노트 "${blankNote.title}"가 생성되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('노트 생성 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultsAsync = ref.watch(vaultsProvider);
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
                      // Placement 기반 브라우저 (vault/folder 컨텍스트)
                      vaultsAsync.when(
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
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ref.read(currentVaultProvider.notifier).state =
                                  vaults.first.vaultId;
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
                              FolderScope(currentVaultId, currentFolderId),
                            ),
                          );

                          return itemsAsync.when(
                            data: (items) {
                              if (items.isEmpty) {
                                return const Text('현재 위치에 항목이 없습니다.');
                              }
                              final folders = items
                                  .where(
                                    (it) => it.type == VaultItemType.folder,
                                  )
                                  .toList();
                              final notes = items
                                  .where(
                                    (it) => it.type == VaultItemType.note,
                                  )
                                  .toList();

                              return Column(
                                children: [
                                  if (currentFolderId != null) ...[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          ref
                                                  .read(
                                                    currentFolderProvider(
                                                      currentVaultId,
                                                    ).notifier,
                                                  )
                                                  .state =
                                              null;
                                        },
                                        icon: const Icon(Icons.arrow_upward),
                                        label: const Text('루트로 이동'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

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
                                                      .state =
                                                  it.id;
                                            },
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
                                            color: const Color(0xFF6750A4),
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
                            error: (e, _) => Center(child: Text('오류: $e')),
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
                    onPressed: _isImporting ? null : _importPdfNote,
                    icon: _isImporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _isImporting ? 'PDF 가져오는 중...' : 'PDF 파일에서 노트 생성',
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
