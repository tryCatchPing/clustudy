import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../notes/data/derived_note_providers.dart';
import '../../../notes/models/note_model.dart';

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
  const LinkCreationDialog({super.key});

  static Future<LinkCreationResult?> show(BuildContext context) {
    return showDialog<LinkCreationResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const Dialog(
        child: LinkCreationDialog(),
      ),
    );
  }

  @override
  ConsumerState<LinkCreationDialog> createState() => _LinkCreationDialogState();
}

class _LinkCreationDialogState extends ConsumerState<LinkCreationDialog> {
  final TextEditingController _titleCtrl = TextEditingController();
  String? _selectedNoteId;
  // 페이지 선택은 현재 정책상 사용하지 않음 (페이지→노트 링크)

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final notes = notesAsync.value ?? const <NoteModel>[];

    final suggestions = (_titleCtrl.text.trim().isEmpty)
        ? notes
        : notes
              .where(
                (n) => n.title.toLowerCase().contains(
                  _titleCtrl.text.trim().toLowerCase(),
                ),
              )
              .toList();

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
              onChanged: (_) {
                setState(() {
                  _selectedNoteId = null; // 직접 입력 시 기존 선택 해제
                });
              },
            ),

            const SizedBox(height: 8),

            // 제안 목록
            SizedBox(
              height: 160,
              child: Material(
                color: Colors.transparent,
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final n = suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(n.title),
                      subtitle: Text('페이지 ${n.pages.length}개'),
                      selected: _selectedNoteId == n.noteId,
                      onTap: () {
                        setState(() {
                          _selectedNoteId = n.noteId;
                          _titleCtrl.text = n.title;
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
