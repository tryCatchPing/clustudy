import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/canvas/notifiers/custom_scribble_notifier.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_page_model.dart';

const _kPixelToPoint = 0.75; // PDF 포맷 환산 상수 (px -> pt)
const _kDefaultPixelRatio = 4.0;
const _kExportLogTag = '[pdf-export-mvp]';
const _kBlankBackgroundColor = ui.Color(0xFFFFFFFF);

final pdfExportMvpServiceProvider = Provider<PdfExportMvpService>((_) {
  return PdfExportMvpService();
});

/// PDF 내보내기(MVP) 결과.
class PdfExportResult {
  PdfExportResult({
    required this.filePath,
    required this.pageCount,
    required this.elapsed,
  });

  final String filePath;
  final int pageCount;
  final Duration elapsed;
}

/// PDF 내보내기 중 발생한 오류.
class PdfExportException implements Exception {
  PdfExportException(this.message);

  final String message;

  @override
  String toString() => 'PdfExportException($message)';
}

/// Android MVP PDF 내보내기 서비스.
class PdfExportMvpService {
  PdfExportMvpService({
    Future<Directory> Function()? downloadsDirectoryResolver,
  }) : _downloadsDirectoryResolver =
           downloadsDirectoryResolver ?? _resolveDownloadsDirectory;

  final Future<Directory> Function() _downloadsDirectoryResolver;

  Future<PdfExportResult> exportToDownloads({
    required NoteModel note,
    required Map<String, CustomScribbleNotifier> pageNotifiers,
    ui.Color blankBackgroundColor = _kBlankBackgroundColor,
    bool simulatePressure = true,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint(
      '$_kExportLogTag start note=${note.noteId} pages=${note.pages.length}',
    );

    if (note.pages.isEmpty) {
      throw PdfExportException('내보낼 페이지가 없습니다.');
    }

    final dir = await _downloadsDirectoryResolver();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = await _allocateFilePath(dir, note.title);
    final doc = pw.Document();

    for (var index = 0; index < note.pages.length; index += 1) {
      final page = note.pages[index];
      debugPrint(
        '$_kExportLogTag page ${index + 1}/${note.pages.length}'
        ' id=${page.pageId}',
      );

      final notifier = pageNotifiers[page.pageId];
      if (notifier == null) {
        throw PdfExportException('페이지 ${page.pageNumber}의 필기 정보가 없습니다.');
      }

      final sketchBytes = await _renderSketch(
        notifier: notifier,
        page: page,
        blankBackgroundColor: blankBackgroundColor,
        simulatePressure: simulatePressure,
      );
      final composedBytes = await _maybeCompositeWithBackground(
        page: page,
        sketchBytes: sketchBytes,
      );

      final widthPt = page.drawingAreaWidth * _kPixelToPoint;
      final heightPt = page.drawingAreaHeight * _kPixelToPoint;
      final pageFormat = PdfPageFormat(widthPt, heightPt);
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(pw.MemoryImage(composedBytes)),
          ),
        ),
      );
    }

    final bytes = await doc.save();
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    sw.stop();
    debugPrint(
      '$_kExportLogTag success path=$filePath '
      'duration=${sw.elapsed.inMilliseconds}ms',
    );

    return PdfExportResult(
      filePath: filePath,
      pageCount: note.pages.length,
      elapsed: sw.elapsed,
    );
  }

  Future<Uint8List> _renderSketch({
    required CustomScribbleNotifier notifier,
    required NotePageModel page,
    required ui.Color blankBackgroundColor,
    required bool simulatePressure,
  }) async {
    final size = ui.Size(page.drawingAreaWidth, page.drawingAreaHeight);
    notifier.setSimulatePressureEnabled(simulatePressure);
    final data = await notifier.renderCurrentSketchOffscreen(
      size: size,
      backgroundColor: page.hasPdfBackground
          ? const ui.Color(0x00000000)
          : blankBackgroundColor,
      simulatePressure: simulatePressure,
      pixelRatio: _kDefaultPixelRatio,
    );
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _maybeCompositeWithBackground({
    required NotePageModel page,
    required Uint8List sketchBytes,
  }) async {
    if (!page.hasPdfBackground) {
      return sketchBytes;
    }

    final backgroundPath = page.preRenderedImagePath;
    if (backgroundPath == null) {
      throw PdfExportException('PDF 배경 이미지가 없습니다. (page=${page.pageId})');
    }

    final backgroundFile = File(backgroundPath);
    if (!await backgroundFile.exists()) {
      throw PdfExportException('배경 파일을 찾을 수 없습니다: $backgroundPath');
    }

    final bgBytes = await backgroundFile.readAsBytes();
    final bgCodec = await ui.instantiateImageCodec(bgBytes);
    final bgFrame = await bgCodec.getNextFrame();

    final sketchCodec = await ui.instantiateImageCodec(sketchBytes);
    final sketchFrame = await sketchCodec.getNextFrame();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = ui.Size(page.drawingAreaWidth, page.drawingAreaHeight);

    canvas.drawImageRect(
      bgFrame.image,
      ui.Rect.fromLTWH(
        0,
        0,
        bgFrame.image.width.toDouble(),
        bgFrame.image.height.toDouble(),
      ),
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      ui.Paint(),
    );

    canvas.drawImageRect(
      sketchFrame.image,
      ui.Rect.fromLTWH(
        0,
        0,
        sketchFrame.image.width.toDouble(),
        sketchFrame.image.height.toDouble(),
      ),
      ui.Rect.fromLTWH(0, 0, size.width, size.height),
      ui.Paint(),
    );

    final picture = recorder.endRecording();
    final composedImage = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await composedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    bgFrame.image.dispose();
    sketchFrame.image.dispose();
    picture.dispose();
    composedImage.dispose();

    if (byteData == null) {
      throw PdfExportException('합성된 이미지를 생성하지 못했습니다.');
    }

    return byteData.buffer.asUint8List();
  }

  Future<String> _allocateFilePath(Directory dir, String title) async {
    final sanitized = _sanitizeTitle(title);
    final timestamp = DateTime.now();
    final baseName =
        '${sanitized}_${_twoDigits(timestamp.year)}${_twoDigits(timestamp.month)}${_twoDigits(timestamp.day)}'
        '_${_twoDigits(timestamp.hour)}${_twoDigits(timestamp.minute)}${_twoDigits(timestamp.second)}';

    var candidate = p.join(dir.path, '$baseName.pdf');
    if (!await File(candidate).exists()) {
      return candidate;
    }

    for (var i = 1; i < 1000; i += 1) {
      final path = p.join(dir.path, '${baseName}_$i.pdf');
      if (!await File(path).exists()) {
        return path;
      }
    }

    throw PdfExportException('파일 이름을 생성할 수 없습니다. (${dir.path})');
  }

  String _sanitizeTitle(String title) {
    final replaced = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return replaced.trim().isEmpty ? 'clustudy_note' : replaced.trim();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

Future<Directory> _resolveDownloadsDirectory() async {
  if (Platform.isAndroid) {
    final dirs = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    if (dirs != null && dirs.isNotEmpty) {
      final first = dirs.first;
      return Directory(p.join(first.path, 'Clustudy'));
    }
  }

  final fallback = await getApplicationDocumentsDirectory();
  return Directory(p.join(fallback.path, 'pdf_exports'));
}
