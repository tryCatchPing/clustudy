import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clustudy/features/canvas/models/tool_mode.dart';
import 'package:clustudy/features/canvas/notifiers/custom_scribble_notifier.dart';
import 'package:clustudy/features/notes/models/note_model.dart';
import 'package:clustudy/features/notes/models/note_page_model.dart';
import 'package:clustudy/shared/services/pdf_export_mvp_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scribble/scribble.dart';

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

    test(
      'offscreen render scales strokes and background with pixelRatio',
      () async {
        // 100x100 페이지의 오른쪽 아래(70~90)에 굵은 검은 획을 하나 긋는다.
        final notifier = CustomScribbleNotifier(
          sketch: const Sketch(
            lines: [
              SketchLine(
                points: [Point(70, 80), Point(80, 80), Point(90, 80)],
                color: 0xFF000000,
                width: 4,
              ),
            ],
          ),
          toolMode: ToolMode.pen,
          simulatePressure: false,
        );

        final data = await notifier.renderCurrentSketchOffscreen(
          size: const ui.Size(100, 100),
          backgroundColor: const ui.Color(0xFFFFFFFF),
          simulatePressure: false,
          pixelRatio: 4,
        );
        final image = await _decode(data.buffer.asUint8List());

        expect(image.width, 400);
        expect(image.height, 400);
        // 획은 4배 좌표(x 280~360, y 320)에 있어야 한다.
        expect(await _pixel(image, 320, 320), 0xFF000000);
        // 배경은 이미지 전체를 채워야 한다(오른쪽 위 모서리도 불투명한 흰색).
        expect(await _pixel(image, 395, 5), 0xFFFFFFFF);
        // 1배 좌표(80, 80)에는 획이 없어야 한다.
        expect(await _pixel(image, 80, 80), 0xFFFFFFFF);
      },
    );
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

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Returns the pixel at ([x], [y]) as 0xAARRGGBB.
Future<int> _pixel(ui.Image image, int x, int y) async {
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final offset = (y * image.width + x) * 4;
  final r = data!.getUint8(offset);
  final g = data.getUint8(offset + 1);
  final b = data.getUint8(offset + 2);
  final a = data.getUint8(offset + 3);
  return (a << 24) | (r << 16) | (g << 8) | b;
}
