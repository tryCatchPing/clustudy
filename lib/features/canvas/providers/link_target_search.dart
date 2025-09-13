import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/vault_tree_repository.dart';
import '../../vaults/data/vault_tree_repository_provider.dart';
import '../../vaults/models/vault_item.dart';

/// 링크 타깃 서제스트 항목(동일 vault 내 노트만 포함)
class LinkSuggestion {
  final String noteId;
  final String title;
  final String? parentFolderName; // 루트면 '루트'

  const LinkSuggestion({
    required this.noteId,
    required this.title,
    this.parentFolderName,
  });
}

/// 링크 타깃 검색 추상화. 초기에는 Placement BFS 기반 구현만 제공.
/// 추후 VaultNotesService.searchNotesInVault 로 교체 가능하도록 분리.
abstract class LinkTargetSearch {
  /// 지정한 vault 내의 모든 노트 서제스트를 일회성으로 수집합니다.
  Future<List<LinkSuggestion>> listAllInVault(String vaultId);

  /// 간단한 부분 일치 필터(케이스 비구분).
  List<LinkSuggestion> filterByQuery(List<LinkSuggestion> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) => s.title.toLowerCase().contains(q))
        .toList(growable: false);
  }
}

final linkTargetSearchProvider = Provider<LinkTargetSearch>((ref) {
  final vaultTree = ref.watch(vaultTreeRepositoryProvider);
  return _PlacementLinkTargetSearch(vaultTree);
});

class _PlacementLinkTargetSearch implements LinkTargetSearch {
  final VaultTreeRepository vaultTree;
  const _PlacementLinkTargetSearch(this.vaultTree);

  @override
  Future<List<LinkSuggestion>> listAllInVault(String vaultId) async {
    // BFS: (parentFolderId, parentFolderName)
    final queue = <_FolderCtx>[const _FolderCtx(null, '루트')];
    final suggestions = <LinkSuggestion>[];

    while (queue.isNotEmpty) {
      final parent = queue.removeAt(0);
      final items = await vaultTree
          .watchFolderChildren(vaultId, parentFolderId: parent.id)
          .first;
      for (final it in items) {
        if (it.type == VaultItemType.folder) {
          queue.add(_FolderCtx(it.id, it.name));
        } else {
          suggestions.add(
            LinkSuggestion(
              noteId: it.id,
              title: it.name,
              parentFolderName: parent.name,
            ),
          );
        }
      }
    }
    return suggestions;
  }

  @override
  List<LinkSuggestion> filterByQuery(List<LinkSuggestion> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) => s.title.toLowerCase().contains(q))
        .toList(growable: false);
  }
}

class _FolderCtx {
  final String? id;
  final String? name;
  const _FolderCtx(this.id, this.name);
}
