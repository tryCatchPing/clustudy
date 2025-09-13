import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/vault_notes_service.dart';

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
  final service = ref.watch(vaultNotesServiceProvider);
  return _PlacementLinkTargetSearch(service);
});

class _PlacementLinkTargetSearch implements LinkTargetSearch {
  final VaultNotesService service;
  const _PlacementLinkTargetSearch(this.service);

  @override
  Future<List<LinkSuggestion>> listAllInVault(String vaultId) async {
    final results = await service.searchNotesInVault(vaultId, '', limit: 100);
    return results
        .map(
          (r) => LinkSuggestion(
            noteId: r.noteId,
            title: r.title,
            parentFolderName: r.parentFolderName,
          ),
        )
        .toList(growable: false);
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
