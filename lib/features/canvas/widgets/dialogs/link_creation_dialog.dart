import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/errors/app_error_mapper.dart';
import '../../../../shared/errors/app_error_spec.dart';
import '../../../../shared/services/vault_notes_service.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../providers/link_target_search.dart';

/// 링크 생성 다이얼로그 결과
class LinkCreationResult {
  final String? targetNoteId; // 선택된 기존 노트
  final String? targetTitle; // 새 노트 생성용 제목

  const LinkCreationResult({
    this.targetNoteId,
    this.targetTitle,
  });
}

/// 링크 생성 다이얼로그
class LinkCreationDialog extends ConsumerStatefulWidget {
  const LinkCreationDialog({
    required this.sourceNoteId,
    super.key,
  });

  /// 링크를 생성/수정하는 "소스 노트"의 ID. 같은 vault 범위로 제안을 제한하기 위해 필요.
  final String sourceNoteId;

  static Future<LinkCreationResult?> show(
    BuildContext context, {
    required String sourceNoteId,
  }) {
    return showDialog<LinkCreationResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        child: LinkCreationDialog(sourceNoteId: sourceNoteId),
      ),
    );
  }

  @override
  ConsumerState<LinkCreationDialog> createState() => _LinkCreationDialogState();
}

class _LinkCreationDialogState extends ConsumerState<LinkCreationDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  String? _selectedNoteId;
  bool _loading = true;
  String? _vaultId;
  List<LinkSuggestion> _filtered = const <LinkSuggestion>[];

  @override
  void initState() {
    super.initState();
    _initVaultAndLoad();
  }

  Future<void> _initVaultAndLoad() async {
    try {
      final service = ref.read(vaultNotesServiceProvider);
      final placement = await service.getPlacement(widget.sourceNoteId);
      if (!mounted) return;
      if (placement == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      _vaultId = placement.vaultId;
      final results = await service.searchNotesInVault(
        _vaultId!,
        '',
        limit: 100,
      );
      final all = results
          .map(
            (r) => LinkSuggestion(
              noteId: r.noteId,
              title: r.title,
              parentFolderName: r.parentFolderName,
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _filtered = all;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final spec = AppErrorMapper.toSpec(e);
      AppSnackBar.show(context, spec);
    }
  }

  Future<void> _applyFilter(String text) async {
    _selectedNoteId = null; // 검색 시 기존 선택 해제
    final vaultId = _vaultId;
    if (vaultId == null) return;
    try {
      final service = ref.read(vaultNotesServiceProvider);
      final results = await service.searchNotesInVault(
        vaultId,
        text,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _filtered = results
            .map(
              (r) => LinkSuggestion(
                noteId: r.noteId,
                title: r.title,
                parentFolderName: r.parentFolderName,
              ),
            )
            .toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      final spec = AppErrorMapper.toSpec(e);
      AppSnackBar.show(context, spec);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '링크 생성',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 제목 입력
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '대상 노트 제목',
                hintText: '기존 노트 선택 또는 새 제목 입력',
                border: OutlineInputBorder(),
              ),
              onChanged: (t) => _applyFilter(t),
            ),

            const SizedBox(height: 8),

            // 제안 목록
            SizedBox(
              height: 160,
              child: Material(
                color: Colors.transparent,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final s = _filtered[index];
                          return ListTile(
                            dense: true,
                            title: Text(s.title),
                            subtitle: s.parentFolderName == null
                                ? null
                                : Text(s.parentFolderName!),
                            selected: _selectedNoteId == s.noteId,
                            onTap: () {
                              setState(() {
                                _selectedNoteId = s.noteId;
                                _titleCtrl.text = s.title;
                              });
                            },
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_selectedNoteId == null &&
                        _titleCtrl.text.trim().isEmpty) {
                      AppSnackBar.show(
                        context,
                        AppErrorSpec.info('제목을 입력하거나 노트를 선택하세요.'),
                      );
                      return;
                    }
                    Navigator.of(context).pop(
                      LinkCreationResult(
                        targetNoteId: _selectedNoteId,
                        targetTitle: _selectedNoteId == null
                            ? _titleCtrl.text.trim()
                            : null,
                      ),
                    );
                  },
                  child: const Text('생성'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
