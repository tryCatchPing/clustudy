import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/vault_tree_repository.dart';
import '../../../shared/services/name_normalizer.dart';
import '../../canvas/models/link_model.dart';
import '../../canvas/providers/link_providers.dart';
import '../../notes/data/notes_repository_provider.dart';
import '../../notes/models/note_model.dart';
import '../data/vault_tree_repository_provider.dart';
import '../models/vault_item.dart';

/// Builds widget-ready graph data for a vault:
/// { vertexes: [...], edges: [...] }.
///
/// Usage with FlutterGraphWidget:
///
/// ```dart
/// final dataAsync = ref.watch(vaultGraphDataProvider(vaultId));
/// return dataAsync.when(
///   data: (data) => FlutterGraphWidget(
///     data: data,
///     algorithm: ForceDirected(),
///     convertor: MapConvertor(),
///     options: Options()
///       ..enableHit = false,
///     // ..onVertexTap = (node) { /* handle tap */ },
///   ),
///   loading: () => const Center(child: CircularProgressIndicator()),
///   error: (e, _) => Text('Graph error: $e'),
/// );
/// ```
///
/// Provided data shape:
/// - vertexes: [{ 'id': noteId, 'name': noteName, 'tag': noteName, 'tags': [noteName] }]
/// - edges: [{ 'srcId': sourceNoteId, 'dstId': targetNoteId, 'edgeName': 'link', 'ranking': weight }]
///
/// Notes
/// - Only intra-vault edges are included.
/// - 'ranking' aggregates number of page-level links between two notes.
final vaultGraphDataProvider = StreamProvider.family<Map<String, dynamic>, String>((
  ref,
  vaultId,
) {
  final vaultTree = ref.watch(vaultTreeRepositoryProvider);
  final notesRepo = ref.watch(notesRepositoryProvider);
  final linkRepo = ref.watch(linkRepositoryProvider);

  final controller = StreamController<Map<String, dynamic>>.broadcast();

  // Dynamic state
  List<NoteModel> notes = const <NoteModel>[];
  final Map<String, NoteModel> noteIndex = <String, NoteModel>{};
  final Map<String, String> placementNames = <String, String>{};
  final Set<String> noteIds = <String>{};
  final Map<String, String> pageToNote = <String, String>{};
  final Set<String> sourcePages = <String>{};
  final Map<String, String> noteTitles = <String, String>{};
  final Map<String, List<LinkModel>> pageLinks = <String, List<LinkModel>>{};
  final Map<String, StreamSubscription<List<LinkModel>>> pageSubs =
      <String, StreamSubscription<List<LinkModel>>>{};

  void emit() {
    // Build vertex list
    final vertexes = <Map<String, dynamic>>[];
    for (final nid in noteIds) {
      final rawTitle = noteTitles[nid] ?? placementNames[nid] ?? nid;
      final label = NameNormalizer.normalize(rawTitle);
      vertexes.add({
        'id': nid,
        'name': label,
        'tag': label,
        'tags': [label],
      });
    }

    // Aggregate edges from latest link snapshots
    final weights = <String, int>{};
    pageLinks.forEach((pid, links) {
      for (final l in links) {
        final srcNote = pageToNote[pid];
        final dstNote = l.targetNoteId;
        if (srcNote == null) continue;
        if (!noteIds.contains(dstNote)) continue; // only intra-vault edges
        final key = '$srcNote|$dstNote';
        weights.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    });
    final edges = <Map<String, dynamic>>[];
    weights.forEach((k, w) {
      final parts = k.split('|');
      edges.add({
        'srcId': parts[0],
        'dstId': parts[1],
        'edgeName': 'link',
        'ranking': w,
      });
    });

    controller.add({
      'vertexes': vertexes,
      'edges': edges,
    });
  }

  Future<void> rebuildPlacementsAndSubscriptions({
    bool snapshotLinks = true,
  }) async {
    // Collect placements across the vault
    final placements = await _collectAllNoteItems(vaultTree, vaultId);
    noteIds
      ..clear()
      ..addAll(placements.map((e) => e.id));
    placementNames
      ..clear()
      ..addEntries(placements.map((e) => MapEntry(e.id, e.name)));

    // Build note index
    noteIndex
      ..clear()
      ..addEntries(notes.map((n) => MapEntry(n.noteId, n)));

    // Build page mapping and titles
    pageToNote.clear();
    sourcePages.clear();
    noteTitles.clear();
    for (final nid in noteIds) {
      final note = noteIndex[nid];
      if (note == null) continue;
      noteTitles[nid] = note.title;
      for (final p in note.pages) {
        pageToNote[p.pageId] = nid;
        sourcePages.add(p.pageId);
      }
    }

    // Update page link subscriptions
    final newPages = sourcePages.toSet();
    final toRemove = pageSubs.keys
        .where((pid) => !newPages.contains(pid))
        .toList();
    for (final pid in toRemove) {
      await pageSubs.remove(pid)?.cancel();
      pageLinks.remove(pid);
    }
    final toAdd = newPages.where((pid) => !pageSubs.containsKey(pid)).toList();
    for (final pid in toAdd) {
      final sub = linkRepo.watchByPage(pid).listen((links) {
        pageLinks[pid] = links;
        emit();
      });
      pageSubs[pid] = sub;
    }

    if (snapshotLinks && newPages.isNotEmpty) {
      // Prime link snapshots so first paint has edges
      final all = await linkRepo.listBySourcePages(newPages.toList());
      pageLinks
        ..clear()
        ..addEntries(newPages.map((e) => MapEntry(e, const <LinkModel>[])));
      for (final l in all) {
        final list = pageLinks[l.sourcePageId];
        if (list != null) {
          pageLinks[l.sourcePageId] = List<LinkModel>.from(list)..add(l);
        }
      }
    }

    emit();
  }

  // Subscribe to notes repository to react to title/page changes and new/removed notes
  final notesSub = notesRepo.watchNotes().listen((list) async {
    notes = list;
    await rebuildPlacementsAndSubscriptions(snapshotLinks: true);
  });

  // Initial boot: wait for first notes snapshot and then build
  () async {
    notes = await notesRepo.watchNotes().first;
    await rebuildPlacementsAndSubscriptions(snapshotLinks: true);
  }();

  ref.onDispose(() async {
    await notesSub.cancel();
    for (final s in pageSubs.values) {
      await s.cancel();
    }
    await controller.close();
  });

  return controller.stream;
});

Future<List<VaultItem>> _collectAllNoteItems(
  VaultTreeRepository vaultTree,
  String vaultId,
) async {
  final out = <VaultItem>[];
  final queue = <String?>[null];
  final seen = <String?>{};
  while (queue.isNotEmpty) {
    final parent = queue.removeAt(0);
    if (!seen.add(parent)) continue;
    final items = await vaultTree
        .watchFolderChildren(vaultId, parentFolderId: parent)
        .first;
    for (final it in items) {
      if (it.type == VaultItemType.folder) {
        queue.add(it.id);
      } else {
        out.add(it);
      }
    }
  }
  return out;
}
