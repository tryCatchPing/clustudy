import 'package:isar/isar.dart';

import '../../features/db/isar_db.dart';
import '../../features/db/models/vault_models.dart';

class GraphService {
  GraphService._();
  static final GraphService instance = GraphService._();

  Future<void> deleteEdgesBetween({
    required int vaultId,
    required int fromNoteId,
    required int toNoteId,
  }) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final edges = await isar.graphEdges
          .filter()
          .vaultIdEqualTo(vaultId)
          .and()
          .fromNoteIdEqualTo(fromNoteId)
          .and()
          .toNoteIdEqualTo(toNoteId)
          .findAll();
      if (edges.isEmpty) return;
      await isar.graphEdges.deleteAll(edges.map((e) => e.id).toList());
    });
  }
}


