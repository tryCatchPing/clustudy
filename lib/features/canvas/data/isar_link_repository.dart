import 'dart:async';

import 'package:isar/isar.dart';

import '../../../shared/entities/link_entity.dart';
import '../../../shared/mappers/isar_link_mappers.dart';
import '../../../shared/repositories/link_repository.dart';
import '../../../shared/services/db_txn_runner.dart';
import '../../../shared/services/isar_database_service.dart';
import '../../../shared/services/isar_db_txn_runner.dart';
import '../../canvas/models/link_model.dart';

/// Isar-backed implementation of [LinkRepository].
class IsarLinkRepository implements LinkRepository {
  IsarLinkRepository({Isar? isar}) : _providedIsar = isar;

  final Isar? _providedIsar;
  Isar? _isar;

  Future<Isar> _ensureIsar() async {
    final cached = _isar;
    if (cached != null && cached.isOpen) {
      return cached;
    }
    final resolved = _providedIsar ?? await IsarDatabaseService.getInstance();
    _isar = resolved;
    return resolved;
  }

  Future<T> _executeWrite<T>({
    DbWriteSession? session,
    required Future<T> Function(Isar isar) action,
  }) async {
    if (session is IsarDbWriteSession) {
      return await action(session.isar);
    }
    final isar = await _ensureIsar();
    return await isar.writeTxn(() async {
      return await action(isar);
    });
  }

  @override
  Stream<List<LinkModel>> watchByPage(String pageId) {
    return Stream.multi((controller) async {
      final isar = await _ensureIsar();
      final query = isar.linkEntitys.filter().sourcePageIdEqualTo(pageId);
      final sub = query.watch(fireImmediately: true).listen(
        (entities) {
          final sorted = entities.toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          controller.add(
            sorted.map((e) => e.toDomainModel()).toList(growable: false),
          );
        },
        onError: controller.addError,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<List<LinkModel>> watchBacklinksToNote(String noteId) {
    return Stream.multi((controller) async {
      final isar = await _ensureIsar();
      final query = isar.linkEntitys.filter().targetNoteIdEqualTo(noteId);
      final sub = query.watch(fireImmediately: true).listen(
        (entities) {
          final sorted = entities.toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          controller.add(
            sorted.map((e) => e.toDomainModel()).toList(growable: false),
          );
        },
        onError: controller.addError,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> create(
    LinkModel link, {
    DbWriteSession? session,
  }) async {
    _validateLink(link);
    await _executeWrite(
      session: session,
      action: (isar) async {
        final entity = link.toEntity();
        await isar.linkEntitys.putByLinkId(entity);
      },
    );
  }

  @override
  Future<void> update(
    LinkModel link, {
    DbWriteSession? session,
  }) async {
    _validateLink(link);
    await _executeWrite(
      session: session,
      action: (isar) async {
        final existing = await isar.linkEntitys.getByLinkId(link.id);
        if (existing == null) {
          final entity = link.toEntity();
          await isar.linkEntitys.putByLinkId(entity);
          return;
        }

        existing
          ..sourceNoteId = link.sourceNoteId
          ..sourcePageId = link.sourcePageId
          ..targetNoteId = link.targetNoteId
          ..bboxLeft = link.bboxLeft
          ..bboxTop = link.bboxTop
          ..bboxWidth = link.bboxWidth
          ..bboxHeight = link.bboxHeight
          ..label = link.label
          ..anchorText = link.anchorText
          ..createdAt = link.createdAt
          ..updatedAt = link.updatedAt;

        await isar.linkEntitys.put(existing);
      },
    );
  }

  @override
  Future<void> delete(String linkId, {DbWriteSession? session}) async {
    await _executeWrite(
      session: session,
      action: (isar) async {
        await isar.linkEntitys.deleteByLinkId(linkId);
      },
    );
  }

  @override
  Future<int> deleteBySourcePage(
    String pageId, {
    DbWriteSession? session,
  }) async {
    return await _executeWrite<int>(
      session: session,
      action: (isar) async {
        return await isar.linkEntitys
            .filter()
            .sourcePageIdEqualTo(pageId)
            .deleteAll();
      },
    );
  }

  @override
  Future<int> deleteByTargetNote(
    String noteId, {
    DbWriteSession? session,
  }) async {
    return await _executeWrite<int>(
      session: session,
      action: (isar) async {
        return await isar.linkEntitys
            .filter()
            .targetNoteIdEqualTo(noteId)
            .deleteAll();
      },
    );
  }

  @override
  Future<int> deleteBySourcePages(
    List<String> pageIds, {
    DbWriteSession? session,
  }) async {
    return deleteLinksForMultiplePages(pageIds, session: session);
  }

  @override
  Future<int> deleteLinksForMultiplePages(
    List<String> pageIds, {
    DbWriteSession? session,
  }) async {
    if (pageIds.isEmpty) {
      return 0;
    }
    return await _executeWrite<int>(
      session: session,
      action: (isar) async {
        var total = 0;
        for (final pageId in pageIds.toSet()) {
          total += await isar.linkEntitys
              .filter()
              .sourcePageIdEqualTo(pageId)
              .deleteAll();
        }
        return total;
      },
    );
  }

  @override
  Future<List<LinkModel>> listBySourcePages(List<String> pageIds) async {
    if (pageIds.isEmpty) {
      return const <LinkModel>[];
    }
    final isar = await _ensureIsar();
    final entities = <LinkEntity>[];
    for (final pageId in pageIds.toSet()) {
      final result = await isar.linkEntitys
          .filter()
          .sourcePageIdEqualTo(pageId)
          .findAll();
      entities.addAll(result);
    }
    entities.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entities.map((e) => e.toDomainModel()).toList(growable: false);
  }

  @override
  Future<List<LinkModel>> getBacklinksForNote(String noteId) async {
    final isar = await _ensureIsar();
    final entities = await isar.linkEntitys
        .filter()
        .targetNoteIdEqualTo(noteId)
        .findAll();
    entities.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entities.map((e) => e.toDomainModel()).toList(growable: false);
  }

  @override
  Future<List<LinkModel>> getOutgoingLinksForPage(String pageId) async {
    final isar = await _ensureIsar();
    final entities = await isar.linkEntitys
        .filter()
        .sourcePageIdEqualTo(pageId)
        .findAll();
    entities.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entities.map((e) => e.toDomainModel()).toList(growable: false);
  }

  @override
  Future<Map<String, int>> getBacklinkCountsForNotes(
    List<String> noteIds,
  ) async {
    final isar = await _ensureIsar();
    final counts = <String, int>{};
    for (final noteId in noteIds) {
      final count = await isar.linkEntitys
          .filter()
          .targetNoteIdEqualTo(noteId)
          .count();
      counts[noteId] = count;
    }
    return counts;
  }

  @override
  Future<void> createMultipleLinks(
    List<LinkModel> links, {
    DbWriteSession? session,
  }) async {
    if (links.isEmpty) {
      return;
    }
    for (final link in links) {
      _validateLink(link);
    }
    await _executeWrite(
      session: session,
      action: (isar) async {
        for (final link in links) {
          final entity = link.toEntity();
          await isar.linkEntitys.putByLinkId(entity);
        }
      },
    );
  }

  @override
  void dispose() {}

  void _validateLink(LinkModel link) {
    if (!link.isValidBbox) {
      throw ArgumentError(
        'Link ${link.id} has invalid bounding box dimensions.',
      );
    }
  }
}
