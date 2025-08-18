// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';

import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.dart';

/// Thrown when there is no integer gap between prev and next indices.
class SortIndexGapExhausted implements Exception {
  final int? prev;
  final int? next;
  final String message;

  SortIndexGapExhausted({this.prev, this.next, this.message = 'No gap between sort indices'})
    : super();

  @override
  String toString() => 'SortIndexGapExhausted(prev: $prev, next: $next, message: $message)';
}

/// Compute a new sortIndex between [prev] and [next] using a spacing scheme.
///
/// Rules:
/// - If both null: returns [step]
/// - If only prev is provided: returns prev + step
/// - If only next is provided: returns next - step
/// - If both provided and gap > 1: returns midpoint
/// - If gap <= 1: throws [SortIndexGapExhausted]
int computeSortIndexBetween({int? prev, int? next, int step = 1000}) {
  if (prev == null && next == null) {
    return step;
  }
  if (prev != null && next == null) {
    // append after prev
    final int candidate = prev + step;
    // guard against overflow is unnecessary for practical app usage
    return candidate;
  }
  if (prev == null && next != null) {
    // insert before next
    final int candidate = next - step;
    if (candidate <= 0) {
      throw SortIndexGapExhausted(
        prev: prev,
        next: next,
        message: 'Insufficient headroom before next',
      );
    }
    return candidate;
  }
  // both provided
  final int p = prev!;
  final int n = next!;
  if (n - p > 1) {
    return (p + n) ~/ 2; // midpoint
  }
  throw SortIndexGapExhausted(prev: p, next: n);
}

/// Re-number all notes in the given folder with evenly spaced sort indices.
///
/// The sequence will start at 1000 and increase by 1000.
Future<void> compactSortIndexForFolder(int folderId, {int startAt = 1000, int step = 1000}) async {
  final isar = await IsarDb.instance.open();
  final folder = await isar.collection<Folder>().get(folderId);
  if (folder == null) {
    throw IsarError('Folder not found: $folderId');
  }
  await isar.writeTxn(() async {
    final notes = await isar.collection<Note>()
        .filter()
        .vaultIdEqualTo(folder.vaultId)
        .and()
        .folderIdEqualTo(folderId)
        .and()
        .deletedAtIsNull()
        .sortBySortIndex()
        .findAll();
    int current = startAt;
    final DateTime now = DateTime.now();
    for (final note in notes) {
      if (note.sortIndex != current) {
        note.sortIndex = current;
        note.updatedAt = now;
      }
      current += step;
    }
    if (notes.isNotEmpty) {
      await isar.collection<Note>().putAll(notes);
    }
  });
}

// Internal page utilities (not part of the public contract). These are helpers
// to ensure updatedAt is set when page attributes affecting order or rotation change.

// ignore: unused_element
Future<void> _setPageRotation({required int pageId, required int rotationDeg}) async {
  final isar = await IsarDb.instance.open();
  await isar.writeTxn(() async {
    final page = await isar.collection<Page>().get(pageId);
    if (page == null) {
      return;
    }
    page.rotationDeg = rotationDeg;
    page.updatedAt = DateTime.now();
    await isar.collection<Page>().put(page);
  });
}

// ignore: unused_element
Future<void> _reindexPagesForNote({required int noteId}) async {
  final isar = await IsarDb.instance.open();
  await isar.writeTxn(() async {
    final pages = await isar.collection<Page>()
        .filter()
        .noteIdEqualTo(noteId)
        .and()
        .deletedAtIsNull()
        .sortByIndex()
        .findAll();
    int idx = 0;
    final DateTime now = DateTime.now();
    for (final p in pages) {
      if (p.index != idx) {
        p.index = idx;
        p.updatedAt = now;
      }
      idx += 1;
    }
    if (pages.isNotEmpty) {
      await isar.collection<Page>().putAll(pages);
    }
  });
}
