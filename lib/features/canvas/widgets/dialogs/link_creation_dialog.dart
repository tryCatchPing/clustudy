import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/vault_notes_service.dart';
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
  List<LinkSuggestion> _all = const <LinkSuggestion>[];
  List<LinkSuggestion> _filtered = const <LinkSuggestion>[];

  @override
  void initState() {
    super.initState();
    _initVaultAndLoad();
  }

  Future<void> _initVaultAndLoad() async {
    final service = ref.read(vaultNotesServiceProvider);
    final placement = await service.getPlacement(widget.sourceNoteId);
    if (!mounted) return;
    if (placement == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final search = ref.read(linkTargetSearchProvider);
    final all = await search.listAllInVault(placement.vaultId);
    if (!mounted) return;
    setState(() {
      _all = all;
      _filtered = all;
      _loading = false;
    });
  }

  void _applyFilter(String text) {
    final search = ref.read(linkTargetSearchProvider);
    setState(() {
      _selectedNoteId = null; // 검색 시 기존 선택 해제
      _filtered = search.filterByQuery(_all, text);
    });
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
              onChanged: _applyFilter,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목을 입력하거나 노트를 선택하세요.')),
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
