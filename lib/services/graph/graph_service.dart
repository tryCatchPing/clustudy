import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:isar/isar.dart';

/// Graph operations on `GraphEdge` relations.
class GraphService {
  GraphService._();
  static final GraphService instance = GraphService._();

  /// Delete all edges between two notes within a vault.
  Future<void> deleteEdgesBetween({
    required int vaultId,
    required int fromNoteId,
    required int toNoteId,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final edges = await isar.collection<GraphEdge>()
          .filter()
          .vaultIdEqualTo(vaultId)
          .fromNoteIdEqualTo(fromNoteId)
          .toNoteIdEqualTo(toNoteId)
          .findAll();
      if (edges.isEmpty) {
        return;
      }
      await isar.collection<GraphEdge>().deleteAll(edges.map((e) => e.id).toList());
    });
  }
}
