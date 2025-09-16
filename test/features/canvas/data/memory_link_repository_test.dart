import 'package:flutter_test/flutter_test.dart';

import 'package:it_contest/features/canvas/data/memory_link_repository.dart';
import 'package:it_contest/features/canvas/models/link_model.dart';

void main() {
  group('MemoryLinkRepository', () {
    late MemoryLinkRepository repository;
    final now = DateTime.utc(2024, 1, 1, 12);

    LinkModel buildLink(int index) {
      return LinkModel(
        id: 'link-$index',
        sourceNoteId: 'note-src-$index',
        sourcePageId: 'page-$index',
        targetNoteId: 'note-dest-${index % 2}',
        bboxLeft: 0,
        bboxTop: 0,
        bboxWidth: 10,
        bboxHeight: 10,
        label: 'L$index',
        anchorText: 'A$index',
        createdAt: now.add(Duration(minutes: index)),
        updatedAt: now.add(Duration(minutes: index)),
      );
    }

    setUp(() {
      repository = MemoryLinkRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('create throws when bbox is invalid', () async {
      final invalid = LinkModel(
        id: 'bad',
        sourceNoteId: 'note-src',
        sourcePageId: 'page-src',
        targetNoteId: 'note-dest',
        bboxLeft: 0,
        bboxTop: 0,
        bboxWidth: 0,
        bboxHeight: 10,
        label: null,
        anchorText: null,
        createdAt: now,
        updatedAt: now,
      );

      await expectLater(
        repository.create(invalid),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getBacklinksForNote returns expected results', () async {
      final link = buildLink(0);
      await repository.create(link);

      final backlinks = await repository.getBacklinksForNote(link.targetNoteId);

      expect(backlinks, hasLength(1));
      expect(backlinks.first.id, equals(link.id));
    });

    test('getBacklinkCountsForNotes aggregates counts', () async {
      await repository.create(buildLink(0));
      await repository.create(buildLink(1));

      final counts = await repository.getBacklinkCountsForNotes(
        ['note-dest-0', 'note-dest-1', 'note-dest-42'],
      );

      expect(counts['note-dest-0'], equals(1));
      expect(counts['note-dest-1'], equals(1));
      expect(counts['note-dest-42'], equals(0));
    });

    test(
      'createMultipleLinks and deleteLinksForMultiplePages work in batch',
      () async {
        await repository.createMultipleLinks(
          [buildLink(0), buildLink(2), buildLink(4)],
        );

        final outgoing = await repository.getOutgoingLinksForPage('page-2');
        expect(outgoing, hasLength(1));

        final deleted = await repository.deleteLinksForMultiplePages([
          'page-0',
          'page-2',
        ]);

        expect(deleted, equals(2));
        final remaining = await repository.listBySourcePages(
          ['page-0', 'page-2', 'page-4'],
        );
        expect(remaining.map((l) => l.id), ['link-4']);
      },
    );
  });
}
