import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/services/graph/graph_service.dart';
import 'package:it_contest/shared/models/rect_norm.dart';

/// 링크 생성/삭제와 그래프 간선 동기화를 담당하는 서비스.
class LinkService {
  LinkService._();
  static final LinkService instance = LinkService._();

  /// 링크 영역에서 새 노트를 생성하고 Link + GraphEdge 를 동기화합니다.
  ///
  /// 계약: 시그니처 변경 금지.
  Future<Note> createLinkedNoteFromRegion({
    required int vaultId,
    required int sourceNoteId,
    required int sourcePageId,
    required RectNorm region,
    String? label,
  }) async {
    final normalized = region.normalized();
    normalized.assertValid();

    final isar = await IsarDb.instance.open();
    final effectiveLabel = await _ensureUniqueLabelWithinSource(
      isar: isar,
      vaultId: vaultId,
      sourceNoteId: sourceNoteId,
      sourcePageId: sourcePageId,
      desired: label?.trim().isEmpty ?? true ? '링크' : label!.trim(),
    );

    // 기본 페이지 설정은 도메인 기본값 사용(A4/portrait, pageIndex 0)
    final link = await NoteDbService.instance.createLinkAndTargetNote(
      vaultId: vaultId,
      sourceNoteId: sourceNoteId,
      sourcePageId: sourcePageId,
      x0: normalized.x0,
      y0: normalized.y0,
      x1: normalized.x1,
      y1: normalized.y1,
      label: effectiveLabel,
      pageSize: 'A4',
      pageOrientation: 'portrait',
      initialPageIndex: 0,
    );

    final created = await isar.collection<Note>().get(link.targetNoteId!);
    if (created == null) {
      throw IsarError('Linked note not found after creation');
    }
    return created;
  }

  /// Link 삭제 + 대응 GraphEdge 동기 삭제
  Future<void> deleteLink(int linkId) async {
    final isar = await IsarDb.instance.open();
    await isar.writeTxn(() async {
      final link = await isar.collection<LinkEntity>().get(linkId);
      if (link == null) {
        return;
      }

      final int? toNoteId = link.targetNoteId;
      if (toNoteId != null) {
        await GraphService.instance.deleteEdgesBetween(
          vaultId: link.vaultId,
          fromNoteId: link.sourceNoteId,
          toNoteId: toNoteId,
        );
      }

      await isar.collection<LinkEntity>().delete(linkId);
    });
  }

  Future<String> _ensureUniqueLabelWithinSource({
    required Isar isar,
    required int vaultId,
    required int sourceNoteId,
    required int sourcePageId,
    required String desired,
  }) async {
    // 동일 sourceNoteId+sourcePageId 내 라벨 유니크 보장
    final existing = await isar
        .collection<LinkEntity>()
        .where()
        .vaultIdEqualTo(vaultId)
        .filter()
        .sourceNoteIdEqualTo(sourceNoteId)
        .and()
        .sourcePageIdEqualTo(sourcePageId)
        .findAll();
    final existingLabels = existing.map((e) => (e.label ?? '').trim()).toSet();
    if (!existingLabels.contains(desired)) {
      return desired;
    }

    // suffix 증가 방식: "desired (2)", "desired (3)" ...
    int n = 2;
    while (true) {
      final candidate = '$desired ($n)';
      if (!existingLabels.contains(candidate)) {
        return candidate;
      }
      n += 1;
    }
  }
}
