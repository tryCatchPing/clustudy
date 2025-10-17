import 'dart:typed_data';

import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/features/notes/widgets/draggable_page_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DraggablePageThumbnail', () {
    late NotePageModel testPage;

    setUp(() {
      testPage = NotePageModel(
        noteId: 'test-note-id',
        pageId: 'test-page-id',
        pageNumber: 1,
        jsonData: '{"strokes":[]}',
        backgroundType: PageBackgroundType.blank,
      );
    });

    testWidgets('displays page number correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('shows placeholder when autoLoadThumbnail is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
                autoLoadThumbnail: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('페이지 1'), findsOneWidget);
      expect(find.byIcon(Icons.note), findsOneWidget);
    });

    testWidgets(
      'shows placeholder when thumbnail is null and autoLoad disabled',
      (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: DraggablePageThumbnail(
                  page: testPage,
                  thumbnail: null,
                  autoLoadThumbnail: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('페이지 1'), findsOneWidget);
        expect(find.byIcon(Icons.note), findsOneWidget);
      },
    );

    testWidgets('shows thumbnail image when provided', (
      WidgetTester tester,
    ) async {
      // Create a simple 1x1 pixel image
      final thumbnail = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x00,
        0x01, 0x00, 0x01, 0x5C, 0xC2, 0x8A, 0x8E, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, // IEND chunk
        0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
                thumbnail: thumbnail,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows delete button when showDeleteButton is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
                showDeleteButton: true,
                isDragging: true, // Delete button is visible during drag
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Allow animations to complete

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byType(DraggablePageThumbnail),
        warnIfMissed: false,
      );
      expect(tapped, isTrue);
    });

    testWidgets('shows delete button structure when isDragging is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
                showDeleteButton: true,
                isDragging: true, // Delete button is visible during drag
                autoLoadThumbnail: false, // Disable auto loading for test
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(); // Allow animations to complete

      // Verify the delete button structure exists
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('uses provided thumbnail when available', (
      WidgetTester tester,
    ) async {
      // Create a simple test thumbnail
      final testThumbnail = Uint8List.fromList([1, 2, 3, 4]);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: testPage,
                thumbnail: testThumbnail,
                autoLoadThumbnail: false,
              ),
            ),
          ),
        ),
      );

      // Should show the provided thumbnail (or error placeholder if invalid)
      await tester.pump();
    });

    testWidgets('shows PDF icon for PDF background type', (
      WidgetTester tester,
    ) async {
      final pdfPage = testPage.copyWith(
        backgroundType: PageBackgroundType.pdf,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DraggablePageThumbnail(
                page: pdfPage,
                thumbnail: null,
                autoLoadThumbnail: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    });
  });
}
