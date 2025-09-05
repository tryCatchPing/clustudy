import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/repositories/link_repository.dart';
import '../../canvas/models/link_model.dart';

/// 간단한 인메모리 LinkRepository 구현.
///
/// - 앱 실행 중 메모리에만 유지됩니다.
/// - 키 단위(Stream per key)로 변화를 브로드캐스트합니다.
class MemoryLinkRepository implements LinkRepository {
  // 저장소
  final Map<String, LinkModel> _links = <String, LinkModel>{};

  // 인덱스: 소스 페이지별
  final Map<String, List<LinkModel>> _bySourcePage =
      <String, List<LinkModel>>{};

  // 인덱스: 타깃 노트별 백링크
  final Map<String, Set<String>> _byTargetNote =
      <String, Set<String>>{}; // linkIds

  // 스트림 컨트롤러: 페이지 Outgoing
  final Map<String, StreamController<List<LinkModel>>> _pageControllers =
      <String, StreamController<List<LinkModel>>>{};

  // 스트림 컨트롤러: 페이지 Backlinks
  final Map<String, StreamController<List<LinkModel>>>
  _backlinksPageControllers = <String, StreamController<List<LinkModel>>>{};

  // 스트림 컨트롤러: 노트 Backlinks
  final Map<String, StreamController<List<LinkModel>>>
  _backlinksNoteControllers = <String, StreamController<List<LinkModel>>>{};

  //////////////////////////////////////////////////////////////////////////////
  // Watchers
  //////////////////////////////////////////////////////////////////////////////
  @override
  Stream<List<LinkModel>> watchByPage(String pageId) async* {
    // 초깃값 방출
    yield List<LinkModel>.unmodifiable(
      _bySourcePage[pageId] ?? const <LinkModel>[],
    );
    // 이후 변경 스트림 연결
    yield* _ensurePageController(pageId).stream;
  }

  @override
  Stream<List<LinkModel>> watchBacklinksToNote(String noteId) async* {
    yield _collectByTargetNote(noteId);
    yield* _ensureBacklinksNoteController(noteId).stream;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Mutations
  //////////////////////////////////////////////////////////////////////////////
  @override
  Future<void> create(LinkModel link) async {
    // 삽입
    _links[link.id] = link;

    // 소스 페이지 인덱스 추가
    final pageList = _bySourcePage.putIfAbsent(
      link.sourcePageId,
      () => <LinkModel>[],
    );
    // 동일 id 중복 방지 후 추가
    pageList.removeWhere((e) => e.id == link.id);
    pageList.add(link);

    // 타깃 인덱스 추가
    _byTargetNote.putIfAbsent(link.targetNoteId, () => <String>{}).add(link.id);

    // 영향 받은 키들에 대해 방출
    _emitForSourcePage(link.sourcePageId);
    _emitForTargetNote(link.targetNoteId);
  }

  @override
  Future<void> update(LinkModel link) async {
    final old = _links[link.id];
    if (old == null) {
      // 없으면 create로 처리
      await create(link);
      return;
    }

    // 기존 인덱스에서 제거
    final oldList = _bySourcePage[old.sourcePageId];
    oldList?.removeWhere((e) => e.id == old.id);
    _byTargetNote[old.targetNoteId]?.remove(old.id);

    // 새로운 값으로 삽입
    _links[link.id] = link;
    final newList = _bySourcePage.putIfAbsent(
      link.sourcePageId,
      () => <LinkModel>[],
    );
    newList.removeWhere((e) => e.id == link.id);
    newList.add(link);
    _byTargetNote.putIfAbsent(link.targetNoteId, () => <String>{}).add(link.id);

    // 영향 받은 키들 방출 (old/new 모두)
    _emitForSourcePage(old.sourcePageId);
    _emitForTargetNote(old.targetNoteId);

    _emitForSourcePage(link.sourcePageId);
    _emitForTargetNote(link.targetNoteId);
  }

  @override
  Future<void> delete(String linkId) async {
    final old = _links.remove(linkId);
    if (old == null) return;

    _bySourcePage[old.sourcePageId]?.removeWhere((e) => e.id == linkId);
    _byTargetNote[old.targetNoteId]?.remove(linkId);

    _emitForSourcePage(old.sourcePageId);
    _emitForTargetNote(old.targetNoteId);
  }

  @override
  Future<int> deleteBySourcePage(String pageId) async {
    final list = _bySourcePage[pageId];
    if (list == null || list.isEmpty) {
      // Still emit to clear any stale consumers
      _emitForSourcePage(pageId);
      return 0;
    }
    final affectedTargets = <String>{};
    for (final link in List<LinkModel>.from(list)) {
      _links.remove(link.id);
      _byTargetNote[link.targetNoteId]?.remove(link.id);
      affectedTargets.add(link.targetNoteId);
    }
    _bySourcePage.remove(pageId);
    _emitForSourcePage(pageId);
    for (final t in affectedTargets) {
      _emitForTargetNote(t);
    }
    debugPrint(
      '🧹 [LinkRepo] deleteBySourcePage page=$pageId deleted=${list.length}',
    );
    return list.length;
  }

  @override
  Future<int> deleteByTargetNote(String noteId) async {
    final ids = _byTargetNote[noteId];
    if (ids == null || ids.isEmpty) {
      // Still emit to clear any stale consumers
      _emitForTargetNote(noteId);
      return 0;
    }
    final affectedSources = <String>{};
    for (final id in List<String>.from(ids)) {
      final link = _links.remove(id);
      if (link != null) {
        final pageList = _bySourcePage[link.sourcePageId];
        pageList?.removeWhere((e) => e.id == id);
        affectedSources.add(link.sourcePageId);
      }
    }
    _byTargetNote.remove(noteId);
    _emitForTargetNote(noteId);
    for (final s in affectedSources) {
      _emitForSourcePage(s);
    }
    debugPrint(
      '🧹 [LinkRepo] deleteByTargetNote note=$noteId deleted=${ids.length}',
    );
    return ids.length;
  }

  @override
  Future<int> deleteBySourcePages(List<String> pageIds) async {
    if (pageIds.isEmpty) return 0;
    final uniquePages = pageIds.toSet();
    final affectedTargets = <String>{};
    var total = 0;

    // Remove links from all source pages without emitting inside the loop
    for (final pageId in uniquePages) {
      final list = _bySourcePage[pageId];
      if (list == null || list.isEmpty) {
        continue;
      }
      total += list.length;
      for (final link in List<LinkModel>.from(list)) {
        _links.remove(link.id);
        _byTargetNote[link.targetNoteId]?.remove(link.id);
        affectedTargets.add(link.targetNoteId);
      }
      _bySourcePage.remove(pageId);
    }

    // Emit once per affected key
    for (final pageId in uniquePages) {
      _emitForSourcePage(pageId);
    }
    for (final t in affectedTargets) {
      _emitForTargetNote(t);
    }
    debugPrint(
      '🧹 [LinkRepo] deleteBySourcePages pages=${uniquePages.length} deleted=$total',
    );
    return total;
  }

  @override
  void dispose() {
    for (final c in _pageControllers.values) {
      if (!c.isClosed) c.close();
    }
    for (final c in _backlinksPageControllers.values) {
      if (!c.isClosed) c.close();
    }
    for (final c in _backlinksNoteControllers.values) {
      if (!c.isClosed) c.close();
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Helpers
  //////////////////////////////////////////////////////////////////////////////
  StreamController<List<LinkModel>> _ensurePageController(String pageId) {
    return _pageControllers.putIfAbsent(
      pageId,
      () => StreamController<List<LinkModel>>.broadcast(),
    );
  }

  StreamController<List<LinkModel>> _ensureBacklinksPageController(
    String pageId,
  ) {
    return _backlinksPageControllers.putIfAbsent(
      pageId,
      () => StreamController<List<LinkModel>>.broadcast(),
    );
  }

  StreamController<List<LinkModel>> _ensureBacklinksNoteController(
    String noteId,
  ) {
    return _backlinksNoteControllers.putIfAbsent(
      noteId,
      () => StreamController<List<LinkModel>>.broadcast(),
    );
  }

  void _emitForSourcePage(String pageId) {
    final list = List<LinkModel>.unmodifiable(
      _bySourcePage[pageId] ?? const <LinkModel>[],
    );
    // verbose log removed to reduce noise
    final c = _ensurePageController(pageId);
    if (!c.isClosed) c.add(list);
  }

  void _emitForTargetNote(String noteId) {
    final list = _collectByTargetNote(noteId);
    // verbose log removed to reduce noise
    final c = _ensureBacklinksNoteController(noteId);
    if (!c.isClosed) c.add(list);
  }

  List<LinkModel> _collectByTargetNote(String noteId) {
    final ids = _byTargetNote[noteId];
    if (ids == null || ids.isEmpty) return const <LinkModel>[];
    return List<LinkModel>.unmodifiable(
      ids
          .map((id) => _links[id])
          .where((e) => e != null)
          .cast<LinkModel>()
          .toList(),
    );
  }
}
