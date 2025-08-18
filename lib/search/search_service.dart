// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

/// 통합 검색 서비스
///
/// 모든 검색 관련 기능을 통합 관리하며, 성능 최적화된 쿼리를 제공합니다.
/// - 노트, 폴더, 볼트 검색
/// - startsWith, contains 검색 지원
/// - 고급 필터링 옵션
/// - 전역 및 범위 지정 검색
class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  /// 검색 결과 타입 정의
  ///
  /// 검색 결과를 타입별로 식별하기 위한 상수입니다.
  /// UI 또는 호출부에서 결과를 구분할 때 사용됩니다.
  ///
  /// - [typeVault]: 볼트 결과 키
  /// - [typeFolder]: 폴더 결과 키
  /// - [typeNote]: 노트 결과 키
  static const String typeVault = 'vaults';
  static const String typeFolder = 'folders';
  static const String typeNote = 'notes';

  /// 빠른 노트 검색 (기본: startsWith)
  Future<List<Note>> quickSearchNotes({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase().trim();

    var builder = isar.collection<Note>().filter().vaultIdEqualTo(vaultId).deletedAtIsNull();

    if (folderId == null) {
      builder = builder.folderIdIsNull();
    } else {
      builder = builder.folderIdEqualTo(folderId);
    }

    return builder.nameLowerForSearchStartsWith(q).limit(limit).findAll();
  }

  /// 전체 텍스트 검색 (contains)
  Future<List<Note>> fullTextSearchNotes({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase().trim();

    var builder = isar.collection<Note>().filter().vaultIdEqualTo(vaultId).deletedAtIsNull();

    if (folderId == null) {
      builder = builder.folderIdIsNull();
    } else {
      builder = builder.folderIdEqualTo(folderId);
    }

    return builder.nameLowerForSearchContains(q).limit(limit).findAll();
  }

  /// 전역 검색 (모든 볼트)
  Future<List<Note>> globalSearchNotes({
    required String query,
    bool useContains = true,
    int limit = 100,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase().trim();

    if (useContains) {
      return isar.collection<Note>()
          .filter()
          .deletedAtIsNull()
          .nameLowerForSearchContains(q)
          .limit(limit)
          .findAll();
    } else {
      return isar.collection<Note>()
          .filter()
          .deletedAtIsNull()
          .nameLowerForSearchStartsWith(q)
          .limit(limit)
          .findAll();
    }
  }

  /// 최근 수정된 노트 우선 검색
  Future<List<Note>> searchNotesByRecentlyModified({
    required int vaultId,
    int? folderId,
    required String query,
    bool useContains = true,
    int limit = 30,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase().trim();

    var builder = isar.collection<Note>().filter().vaultIdEqualTo(vaultId).deletedAtIsNull();

    if (folderId == null) {
      builder = builder.folderIdIsNull();
    } else {
      builder = builder.folderIdEqualTo(folderId);
    }

    if (useContains) {
      builder = builder.nameLowerForSearchContains(q);
    } else {
      builder = builder.nameLowerForSearchStartsWith(q);
    }

    return builder.sortByUpdatedAtDesc().limit(limit).findAll();
  }

  /// 날짜 범위 검색
  Future<List<Note>> searchNotesByDateRange({
    required int vaultId,
    int? folderId,
    String? query,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? updatedAfter,
    DateTime? updatedBefore,
    bool useContains = true,
    int limit = 50,
  }) async {
    final isar = await IsarDb.instance.open();

    var builder = isar.collection<Note>().filter().vaultIdEqualTo(vaultId).deletedAtIsNull();

    if (folderId == null) {
      builder = builder.folderIdIsNull();
    } else {
      builder = builder.folderIdEqualTo(folderId);
    }

    // 날짜 필터
    if (createdAfter != null) {
      builder = builder.createdAtGreaterThan(createdAfter);
    }
    if (createdBefore != null) {
      builder = builder.createdAtLessThan(createdBefore);
    }
    if (updatedAfter != null) {
      builder = builder.updatedAtGreaterThan(updatedAfter);
    }
    if (updatedBefore != null) {
      builder = builder.updatedAtLessThan(updatedBefore);
    }

    // 텍스트 검색
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      if (useContains) {
        builder = builder.nameLowerForSearchContains(q);
      } else {
        builder = builder.nameLowerForSearchStartsWith(q);
      }
    }

    return builder.sortByUpdatedAtDesc().limit(limit).findAll();
  }

  /// 폴더 검색
  Future<List<Folder>> searchFolders({
    required int vaultId,
    required String query,
    bool useContains = true,
    int limit = 30,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase().trim();

    if (useContains) {
      return isar.collection<Folder>()
          .filter()
          .vaultIdEqualTo(vaultId)
          .deletedAtIsNull()
          .nameContains(q, caseSensitive: false)
          .sortBySortIndex()
          .limit(limit)
          .findAll();
    } else {
      return isar.collection<Folder>()
          .filter()
          .vaultIdEqualTo(vaultId)
          .deletedAtIsNull()
          .nameStartsWith(q, caseSensitive: false)
          .sortBySortIndex()
          .limit(limit)
          .findAll();
    }
  }

  /// 볼트 검색
  Future<List<Vault>> searchVaults({
    required String query,
    bool useContains = true,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final isar = await IsarDb.instance.open();
    final q = query.toLowerCase().trim();

    if (useContains) {
      return isar.collection<Vault>()
          .filter()
          .deletedAtIsNull()
          .nameContains(q, caseSensitive: false)
          .sortByUpdatedAtDesc()
          .limit(limit)
          .findAll();
    } else {
      return isar.collection<Vault>()
          .filter()
          .deletedAtIsNull()
          .nameStartsWith(q, caseSensitive: false)
          .sortByUpdatedAtDesc()
          .limit(limit)
          .findAll();
    }
  }

  /// 통합 검색 (모든 엔티티 타입)
  Future<SearchResults> searchAll({
    int? vaultId,
    int? folderId,
    required String query,
    bool useContains = true,
    int limitPerType = 20,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResults.empty();
    }

    final futures = <Future<void>>[];
    final results = SearchResults();

    // 볼트 검색 (vaultId가 지정되지 않은 경우)
    if (vaultId == null) {
      futures.add(
        searchVaults(
          query: query,
          useContains: useContains,
          limit: limitPerType,
        ).then((vaults) => results.vaults = vaults),
      );
    }

    // 폴더 검색
    if (vaultId != null) {
      futures.add(
        searchFolders(
          vaultId: vaultId,
          query: query,
          useContains: useContains,
          limit: limitPerType,
        ).then((folders) => results.folders = folders),
      );
    }

    // 노트 검색
    if (vaultId != null) {
      if (useContains) {
        futures.add(
          fullTextSearchNotes(
            vaultId: vaultId,
            folderId: folderId,
            query: query,
            limit: limitPerType,
          ).then((notes) => results.notes = notes),
        );
      } else {
        futures.add(
          quickSearchNotes(
            vaultId: vaultId,
            folderId: folderId,
            query: query,
            limit: limitPerType,
          ).then((notes) => results.notes = notes),
        );
      }
    } else {
      futures.add(
        globalSearchNotes(
          query: query,
          useContains: useContains,
          limit: limitPerType,
        ).then((notes) => results.notes = notes),
      );
    }

    await Future.wait(futures);
    return results;
  }

  /// 검색 제안 (자동완성용)
  Future<List<String>> getSearchSuggestions({
    required int vaultId,
    int? folderId,
    required String query,
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final notes = await quickSearchNotes(
      vaultId: vaultId,
      folderId: folderId,
      query: query,
      limit: limit,
    );

    return notes.map((note) => note.name).toList();
  }
}

/// 검색 결과를 담는 클래스
///
/// 통합 검색 시 엔티티 타입별로 결과를 보관합니다. 각 리스트는 비어있을 수 있습니다.
class SearchResults {
  /// 검색된 볼트 목록
  List<Vault> vaults = [];
  /// 검색된 폴더 목록
  List<Folder> folders = [];
  /// 검색된 노트 목록
  List<Note> notes = [];

  SearchResults();

  SearchResults.empty();

  /// 전체 결과 개수
  int get totalCount => vaults.length + folders.length + notes.length;

  /// 결과가 있는지 확인
  bool get hasResults => totalCount > 0;

  /// 타입별 결과를 Map으로 반환
  ///
  /// 반환되는 맵의 키는 [SearchService.typeVault], [SearchService.typeFolder],
  /// [SearchService.typeNote] 입니다. 값은 각 타입의 결과 리스트입니다.
  Map<String, List<dynamic>> toMap() {
    return {
      SearchService.typeVault: vaults,
      SearchService.typeFolder: folders,
      SearchService.typeNote: notes,
    };
  }
}
