import 'package:async/async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_contest/features/notes/data/isar_notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/features/notes/models/thumbnail_metadata.dart';

import '../../../shared/utils/test_isar.dart';

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

Future<NoteModel?> _nextNoteMatching(
  StreamQueue<NoteModel?> queue,
  bool Function(NoteModel? value) matcher,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (true) {
    final now = DateTime.now();
    if (now.isAfter(deadline)) {
      fail('Timed out waiting for matching note event');
    }
    final remaining = deadline.difference(now);
    final value = await queue.next.timeout(remaining);
    if (matcher(value)) {
      return value;
    }
  }
}

void main() {
  late TestIsarContext isarContext;
  late IsarNotesRepository repository;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    isarContext = await openTestIsar();
  });

  tearDownAll(() async {
    await isarContext.dispose();
  });

  setUp(() async {
    await isarContext.isar.writeTxn(() async {
      await isarContext.isar.clear();
    });
    repository = IsarNotesRepository(isar: isarContext.isar);
  });

  tearDown(() {
    repository.dispose();
  });

  group('IsarNotesRepository', () {
    test('watchNotes emits updates when notes change', () async {
      final expectation = expectLater(
        repository.watchNotes(),
        emitsInOrder(<Matcher>[
          isEmpty,
          predicate<List<NoteModel>>(
            (notes) =>
                notes.length == 1 &&
                notes.first.noteId == 'note-1' &&
                notes.first.pages.length == 2,
          ),
          predicate<List<NoteModel>>(
            (notes) =>
                notes.length == 1 &&
                notes.first.noteId == 'note-1' &&
                notes.first.pages.any(
                  (page) =>
                      page.pageId == 'page-0' &&
                      page.jsonData == '{"strokes":42}',
                ),
          ),
        ]),
      );

      final note = _buildNote(id: 'note-1');
      await repository.upsert(note);
      await repository.updatePageJson('note-1', 'page-0', '{"strokes":42}');

      await expectation.timeout(const Duration(seconds: 5));
    });

    test('watchNoteById reacts to page add/delete operations', () async {
      final queue = StreamQueue<NoteModel?>(
        repository.watchNoteById('note-2'),
      );

      final initial = await queue.next.timeout(const Duration(seconds: 5));
      expect(initial, isNull);

      final note = _buildNote(id: 'note-2');
      await repository.upsert(note);
      final afterInsert = await _nextNoteMatching(
        queue,
        (value) => value?.pages.length == 2,
      );
      expect(afterInsert, isNotNull);
      expect(afterInsert!.pages, hasLength(2));

      final extraPage = NotePageModel(
        noteId: 'note-2',
        pageId: 'page-extra',
        pageNumber: 3,
        jsonData: '{}',
      );
      await repository.addPage('note-2', extraPage, insertIndex: 1);
      final afterAdd = await _nextNoteMatching(
        queue,
        (value) => value?.pages.length == 3,
      );
      expect(afterAdd, isNotNull);
      expect(afterAdd!.pages, hasLength(3));
      expect(afterAdd.pages[1].pageId, equals('page-extra'));
      expect(afterAdd.pages[1].pageNumber, equals(2));

      await repository.deletePage('note-2', 'page-extra');
      final afterDelete = await _nextNoteMatching(
        queue,
        (value) => value?.pages.length == 2,
      );
      expect(afterDelete, isNotNull);
      expect(afterDelete!.pages, hasLength(2));

      await queue.cancel();
    });

    test('reorderPages updates page numbers sequentially', () async {
      final note = _buildNote(id: 'note-3', pageCount: 3);
      await repository.upsert(note);

      final reordered = [note.pages[2], note.pages[0], note.pages[1]];
      await repository.reorderPages('note-3', reordered);

      final fetched = await repository.getNoteById('note-3');
      expect(fetched, isNotNull);
      expect(fetched!.pages.map((p) => p.pageId), [
        'page-2',
        'page-0',
        'page-1',
      ]);
      expect(fetched.pages.map((p) => p.pageNumber), [1, 2, 3]);
    });

    test('delete removes note, pages, and thumbnail metadata', () async {
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

    test(
      'batchUpdatePages writes all pages and bumps note timestamp',
      () async {
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
      },
    );

    test('thumbnail metadata roundtrip', () async {
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
      expect(fetched, isNotNull);
      expect(fetched!.pageId, equals(metadata.pageId));
      expect(fetched.cachePath, equals(metadata.cachePath));
      expect(fetched.createdAt.toUtc(), equals(metadata.createdAt));
      expect(fetched.lastAccessedAt.toUtc(), equals(metadata.lastAccessedAt));
      expect(fetched.fileSizeBytes, equals(metadata.fileSizeBytes));
      expect(fetched.checksum, equals(metadata.checksum));
    });
  });
}
