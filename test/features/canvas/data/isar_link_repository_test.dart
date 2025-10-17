import 'package:async/async.dart';
import 'package:clustudy/features/canvas/data/isar_link_repository.dart';
import 'package:clustudy/features/canvas/models/link_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/utils/test_isar.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  late TestIsarContext isarContext;
  late IsarLinkRepository repository;

  setUp(() async {
    isarContext = await openTestIsar();
    repository = IsarLinkRepository(isar: isarContext.isar);
  });

  tearDown(() async {
    repository.dispose();
    await isarContext.dispose();
  });

  group('IsarLinkRepository', () {
    LinkModel buildLink(int index) {
      final timestamp = DateTime.utc(2024, 1, 1, 12, index);
      return LinkModel(
        id: 'link-$index',
        sourceNoteId: 'src-note-$index',
        sourcePageId: 'page-$index',
        targetNoteId: 'dest-note-${index % 2}',
        bboxLeft: 0,
        bboxTop: 0,
        bboxWidth: 10,
        bboxHeight: 10,
        label: 'L$index',
        anchorText: 'A$index',
        createdAt: timestamp,
        updatedAt: timestamp,
      );
    }

    test('watchByPage emits changes when creating links', () async {
      final link = buildLink(0);

      final queue = StreamQueue<List<LinkModel>>(
        repository.watchByPage(link.sourcePageId),
      );
      final initial = await queue.next;
      expect(initial, isEmpty);

      await repository.create(link);
      final updated = await queue.next.timeout(const Duration(seconds: 5));
      expect(updated.single.id, equals(link.id));

      await queue.cancel();
    });

    test('rejects links with invalid bounding boxes', () async {
      final invalid = LinkModel(
        id: 'bad',
        sourceNoteId: 'src-note',
        sourcePageId: 'page-1',
        targetNoteId: 'dest-note',
        bboxLeft: 0,
        bboxTop: 0,
        bboxWidth: 0,
        bboxHeight: 10,
        label: null,
        anchorText: null,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      );

      await expectLater(
        repository.create(invalid),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('batch operations support backlink queries and deletions', () async {
      final links = [buildLink(0), buildLink(1), buildLink(2)];

      await repository.createMultipleLinks(links);

      final backlinks = await repository.getBacklinksForNote('dest-note-0');
      expect(backlinks.length, equals(2));

      final counts = await repository.getBacklinkCountsForNotes(
        ['dest-note-0', 'dest-note-1', 'dest-note-42'],
      );
      expect(counts['dest-note-0'], equals(2));
      expect(counts['dest-note-1'], equals(1));
      expect(counts['dest-note-42'], equals(0));

      final deleted = await repository.deleteLinksForMultiplePages([
        'page-0',
        'page-2',
      ]);
      expect(deleted, equals(2));

      final remaining = await repository.getOutgoingLinksForPage('page-1');
      expect(remaining.map((l) => l.id), ['link-1']);
    });
  });
}
