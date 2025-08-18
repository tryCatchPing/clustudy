// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';

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
      // Use indexed where on vaultId, then filter remaining fields for better performance
      final edges = await isar
          .collection<GraphEdge>()
          .where()
          .vaultIdEqualTo(vaultId)
          .filter()
          .fromNoteIdEqualTo(fromNoteId)
          .and()
          .toNoteIdEqualTo(toNoteId)
          .findAll();
      if (edges.isEmpty) {
        return;
      }
      await isar.collection<GraphEdge>().deleteAll(edges.map((e) => e.id).toList());
    });
  }
}
