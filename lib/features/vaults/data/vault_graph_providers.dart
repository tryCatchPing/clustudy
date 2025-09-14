import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/repositories/vault_tree_repository.dart';
import '../../../shared/services/name_normalizer.dart';
import '../../canvas/providers/link_providers.dart';
import '../../notes/data/notes_repository_provider.dart';
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
final vaultGraphDataProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, vaultId) async {
      final vaultTree = ref.watch(vaultTreeRepositoryProvider);
      final notesRepo = ref.watch(notesRepositoryProvider);
      final linkRepo = ref.watch(linkRepositoryProvider);

      // 1) Collect all note items (noteId + name) in this vault
      final placements = await _collectAllNoteItems(vaultTree, vaultId);
      if (placements.isEmpty) {
        return {
          'vertexes': const <Map<String, dynamic>>[],
          'edges': const <Map<String, dynamic>>[],
        };
      }

      // Prepare noteId set for filtering edges and map of placement names
      final noteIds = <String>{};
      final placementNames = <String, String>{};
      for (final it in placements) {
        noteIds.add(it.id);
        placementNames[it.id] = it.name;
      }

      // 2) pageId -> noteId map and source pages set, and noteId -> title map
      final pageToNote = <String, String>{};
      final sourcePages = <String>{};
      final noteTitles = <String, String>{};
      for (final nid in noteIds) {
        final note = await notesRepo.getNoteById(nid);
        if (note == null) continue;
        // Capture note title for vertex label
        noteTitles[nid] = note.title;
        for (final p in note.pages) {
          pageToNote[p.pageId] = nid;
          sourcePages.add(p.pageId);
        }
      }

      // Build vertex list using note titles (fallback to placement name or id)
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

      if (sourcePages.isEmpty) {
        return {
          'vertexes': vertexes,
          'edges': const <Map<String, dynamic>>[],
        };
      }

      // 3) Gather links from these pages and aggregate to note-level edges
      final links = await linkRepo.listBySourcePages(sourcePages.toList());
      final weights = <String, int>{}; // key: source|target
      for (final l in links) {
        final srcNote = pageToNote[l.sourcePageId];
        final dstNote = l.targetNoteId;
        if (srcNote == null) continue;
        if (!noteIds.contains(dstNote)) continue; // only intra-vault edges
        final key = '$srcNote|$dstNote';
        weights.update(key, (v) => v + 1, ifAbsent: () => 1);
      }

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

      return {
        'vertexes': vertexes,
        'edges': edges,
      };
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
