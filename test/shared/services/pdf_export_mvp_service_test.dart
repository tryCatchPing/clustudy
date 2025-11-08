import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clustudy/features/canvas/models/tool_mode.dart';
import 'package:clustudy/features/canvas/notifiers/custom_scribble_notifier.dart';
import 'package:clustudy/features/notes/models/note_model.dart';
import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/shared/services/pdf_export_mvp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfExportMvpService', () {
    late Directory tempDir;
    late PdfExportMvpService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('pdf_export_test');
      service = PdfExportMvpService(
        tempDirectoryResolver: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('exports single blank page into target directory', () async {
      final note = _buildNote();
      final notifier = _FakeScribbleNotifier();

      final result = await service.exportToDownloads(
        note: note,
        pageNotifiers: {note.pages.first.pageId: notifier},
        simulatePressure: true,
      );

      expect(result.pageCount, 1);
      final file = File(result.filePath);
      expect(file.existsSync(), isTrue);
      await service.deleteTempFile(result.filePath);
      expect(file.existsSync(), isFalse);
    });

    test('throws when pdf background path missing', () async {
      final note = _buildNote(withPdfBackground: true);
      final notifier = _FakeScribbleNotifier();

      expect(
        () => service.exportToDownloads(
          note: note,
          pageNotifiers: {note.pages.first.pageId: notifier},
        ),
        throwsA(isA<PdfExportException>()),
      );
    });
  });
}

NoteModel _buildNote({bool withPdfBackground = false}) {
  final page = NotePageModel(
    noteId: 'note-1',
    pageId: 'page-1',
    pageNumber: 1,
    jsonData: '{"lines":[]}',
    backgroundType: withPdfBackground
        ? PageBackgroundType.pdf
        : PageBackgroundType.blank,
  );
  return NoteModel(
    noteId: 'note-1',
    title: '테스트 노트',
    pages: [page],
  );
}

class _FakeScribbleNotifier extends CustomScribbleNotifier {
  _FakeScribbleNotifier()
    : super(
        toolMode: ToolMode.pen,
        simulatePressure: true,
      );

  @override
  Future<ByteData> renderCurrentSketchOffscreen({
    required ui.Size size,
    double? scaleFactor,
    bool simulatePressure = true,
    EdgeInsets padding = EdgeInsets.zero,
    ui.Color backgroundColor = const ui.Color(0xFFFFFFFF),
    double pixelRatio = 1.0,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint()..color = backgroundColor;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: format);
    picture.dispose();
    image.dispose();
    return byteData!;
  }
}
