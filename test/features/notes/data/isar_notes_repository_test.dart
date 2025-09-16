import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:it_contest/features/notes/data/isar_notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/features/notes/models/thumbnail_metadata.dart';
import 'package:it_contest/shared/services/isar_database_service.dart';

class _MockPathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('isar_notes_repo_test');
    return dir.path;
  }
}

NoteModel _buildNote({required String id, int pageCount = 2}) {
  final pages = <NotePageModel>[];
  for (var i = 0; i < pageCount; i += 1) {
    pages.add(
      NotePageModel(
        noteId: id,
        pageId: 'page-$i',
        pageNumber: i + 1,
        jsonData: '{"strokes":$i}',
      ),
    );
  }
  final timestamp = DateTime.utc(2024, 1, 1, 12);
  return NoteModel(
    noteId: id,
    title: 'Note $id',
    pages: pages,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = _MockPathProvider();
  });

  tearDown(() async {
    await IsarDatabaseService.close();
  });

  group('IsarNotesRepository', () {
    test('watchNotes emits updates when notes change', () async {
      final repository = IsarNotesRepository();
      final queue = StreamQueue<List<NoteModel>>(repository.watchNotes());

      final initial = await queue.next.timeout(const Duration(seconds: 5));
      expect(initial, isEmpty);

      final note = _buildNote(id: 'note-1');
      await repository.upsert(note);
      final afterInsert = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterInsert, hasLength(1));
      expect(afterInsert.first.noteId, equals('note-1'));
      expect(afterInsert.first.pages, hasLength(2));

      await repository.updatePageJson('note-1', 'page-0', '{"strokes":42}');
      final afterUpdate = await queue.next.timeout(const Duration(seconds: 5));
      final updatedPage = afterUpdate.first.pages.firstWhere(
        (page) => page.pageId == 'page-0',
      );
      expect(updatedPage.jsonData, equals('{"strokes":42}'));

      await queue.cancel();
    });

    test('watchNoteById reacts to page add/delete operations', () async {
      final repository = IsarNotesRepository();
      final queue = StreamQueue<NoteModel?>(repository.watchNoteById('note-2'));

      final initial = await queue.next.timeout(const Duration(seconds: 5));
      expect(initial, isNull);

      final note = _buildNote(id: 'note-2');
      await repository.upsert(note);
      final afterInsert = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterInsert, isNotNull);
      expect(afterInsert!.pages, hasLength(2));

      final extraPage = NotePageModel(
        noteId: 'note-2',
        pageId: 'page-extra',
        pageNumber: 3,
        jsonData: '{}',
      );
      await repository.addPage('note-2', extraPage, insertIndex: 1);
      final afterAdd = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterAdd, isNotNull);
      expect(afterAdd!.pages, hasLength(3));
      expect(afterAdd.pages[1].pageId, equals('page-extra'));
      expect(afterAdd.pages[1].pageNumber, equals(2));

      await repository.deletePage('note-2', 'page-extra');
      final afterDelete = await queue.next.timeout(const Duration(seconds: 5));
      expect(afterDelete, isNotNull);
      expect(afterDelete!.pages, hasLength(2));

      await queue.cancel();
    });

    test('reorderPages updates page numbers sequentially', () async {
      final repository = IsarNotesRepository();
      final note = _buildNote(id: 'note-3', pageCount: 3);
      await repository.upsert(note);

      final reordered = [note.pages[2], note.pages[0], note.pages[1]];
      await repository.reorderPages('note-3', reordered);

      final fetched = await repository.getNoteById('note-3');
      expect(fetched, isNotNull);
      expect(fetched!.pages.map((p) => p.pageId), ['page-2', 'page-0', 'page-1']);
      expect(fetched.pages.map((p) => p.pageNumber), [1, 2, 3]);
    });

    test('delete removes note, pages, and thumbnail metadata', () async {
      final repository = IsarNotesRepository();
      final note = _buildNote(id: 'note-4');
      await repository.upsert(note);

      final metadata = ThumbnailMetadata(
        pageId: 'page-0',
        cachePath: '/tmp/thumb.png',
        createdAt: DateTime.utc(2024, 1, 1),
        lastAccessedAt: DateTime.utc(2024, 1, 2),
        fileSizeBytes: 1024,
        checksum: 'abc',
      );
      await repository.updateThumbnailMetadata('page-0', metadata);

      await repository.delete('note-4');
      expect(await repository.getNoteById('note-4'), isNull);
      expect(await repository.getThumbnailMetadata('page-0'), isNull);
    });

    test('batchUpdatePages writes all pages and bumps note timestamp', () async {
      final repository = IsarNotesRepository();
      final note = _buildNote(id: 'note-5');
      await repository.upsert(note);

      final before = await repository.getNoteById('note-5');
      expect(before, isNotNull);
      final updatedPages = before!.pages
          .map(
            (page) => page.copyWith(
              jsonData: '${page.jsonData}-updated',
            ),
          )
          .toList();
      await repository.batchUpdatePages('note-5', updatedPages);

      final after = await repository.getNoteById('note-5');
      expect(after, isNotNull);
      for (final page in after!.pages) {
        expect(page.jsonData, endsWith('-updated'));
      }
      expect(after.updatedAt.isAfter(before.updatedAt), isTrue);
    });

    test('thumbnail metadata roundtrip', () async {
      final repository = IsarNotesRepository();
      final metadata = ThumbnailMetadata(
        pageId: 'page-meta',
        cachePath: '/tmp/meta.png',
        createdAt: DateTime.utc(2024, 6, 1),
        lastAccessedAt: DateTime.utc(2024, 6, 2),
        fileSizeBytes: 2048,
        checksum: 'checksum',
      );

      await repository.updateThumbnailMetadata('page-meta', metadata);
      final fetched = await repository.getThumbnailMetadata('page-meta');
      expect(fetched, equals(metadata));
    });
  });
}
