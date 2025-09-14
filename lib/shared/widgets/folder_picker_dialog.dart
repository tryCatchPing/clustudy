import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/vault_notes_service.dart';

/// 폴더 선택 다이얼로그
/// 반환: 선택한 folderId (루트 선택 시 null)
class FolderPickerDialog extends ConsumerStatefulWidget {
  const FolderPickerDialog({
    required this.vaultId,
    this.initialFolderId,
    this.disabledFolderSubtreeRootId,
    super.key,
  });

  final String vaultId;
  final String? initialFolderId;
  final String? disabledFolderSubtreeRootId;

  static Future<String?> show(
    BuildContext context, {
    required String vaultId,
    String? initialFolderId,
    String? disabledFolderSubtreeRootId,
  }) {
    return showDialog<String?>(
      context: context,
      builder: (context) => Dialog(
        child: FolderPickerDialog(
          vaultId: vaultId,
          initialFolderId: initialFolderId,
          disabledFolderSubtreeRootId: disabledFolderSubtreeRootId,
        ),
      ),
    );
  }

  @override
  ConsumerState<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends ConsumerState<FolderPickerDialog> {
  bool _loading = true;
  List<_FolderRow> _rows = const <_FolderRow>[];
  Set<String> _disabled = const <String>{};
  String? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(vaultNotesServiceProvider);
    final rows = <_FolderRow>[];
    // Root option
    rows.add(const _FolderRow(id: null, name: '루트', path: ''));

    final folders = await svc.listFoldersWithPath(widget.vaultId);
    for (final f in folders) {
      rows.add(_FolderRow(id: f.folderId, name: f.name, path: f.pathLabel));
    }

    // Disabled subtree (for folder move)
    final disabled = <String>{};
    if (widget.disabledFolderSubtreeRootId != null) {
      disabled.addAll(
        await svc.listFolderSubtreeIds(
          widget.vaultId,
          widget.disabledFolderSubtreeRootId!,
        ),
      );
    }

    setState(() {
      _rows = rows;
      _disabled = disabled;
      _selected = widget.initialFolderId;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '폴더 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _rows.length,
                      itemBuilder: (context, index) {
                        final r = _rows[index];
                        final disabled =
                            r.id != null && _disabled.contains(r.id);
                        return RadioListTile<String?>(
                          dense: true,
                          value: r.id,
                          groupValue: _selected,
                          onChanged: disabled
                              ? null
                              : (v) => setState(() => _selected = v),
                          title: Text(r.name),
                          subtitle: r.path.isEmpty ? null : Text(r.path),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('선택'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderRow {
  final String? id;
  final String name;
  final String path;
  const _FolderRow({required this.id, required this.name, required this.path});
}

// No-op placeholder removed
