import 'dart:async';
import 'dart:io';
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
// 필기 이미지 해상도 배율(캔버스 논리 크기 대비 픽셀 수).
// 4배는 2000x2000 페이지가 8000x8000 PNG가 되어 느리고 메모리를 많이 쓰며,
// 페이지가 1500pt로 커서 2배로도 A4 인쇄 기준 400dpi 이상이 나온다.
const _kExportPixelRatio = 2.0;
const _kExportLogTag = '[pdf-export-mvp]';
const _kBlankBackgroundColor = ui.Color(0xFFFFFFFF);
const _kTransparent = ui.Color(0x00000000);

/// Provides the singleton [PdfExportMvpService].
final pdfExportMvpServiceProvider = Provider<PdfExportMvpService>((_) {
  return PdfExportMvpService();
});

/// Result returned after a PDF export completes.
class PdfExportResult {
  /// Creates a [PdfExportResult].
  PdfExportResult({
    required this.filePath,
    required this.pageCount,
    required this.elapsed,
  });

  /// Absolute path to the generated PDF.
  final String filePath;

  /// Number of note pages included.
  final int pageCount;

  /// Total export duration.
  final Duration elapsed;
}

/// Thrown when the MVP exporter fails and the error should surface to UI.
class PdfExportException implements Exception {
  /// Creates an exception with the provided [message].
  PdfExportException(this.message);

  /// Description of the failure.
  final String message;

  @override
  String toString() => 'PdfExportException($message)';
}

/// Android-specific PDF export implementation used for the MVP flow.
class PdfExportMvpService {
  /// Creates a service that writes PDF exports into an app temp directory.
  PdfExportMvpService({
    Future<Directory> Function()? tempDirectoryResolver,
  }) : _tempDirectoryResolver = tempDirectoryResolver ?? _resolveTempDirectory;

  final Future<Directory> Function() _tempDirectoryResolver;

  /// Renders every page and writes the PDF into a temp directory.
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

    final resolvedPath = await _prepareTempPath(note.title);
    final file = File(resolvedPath);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
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
      // 배경 파일이 없으면 렌더링 전에 바로 실패시킨다.
      final backgroundBytes = page.hasPdfBackground
          ? await _loadPdfBackground(page)
          : null;
      final sketchBytes = await _renderSketch(
        notifier: notifier,
        page: page,
        blankBackgroundColor: blankBackgroundColor,
        simulatePressure: simulatePressure,
      );

      doc.addPage(
        _buildPage(
          page: page,
          sketchBytes: sketchBytes,
          backgroundBytes: backgroundBytes,
        ),
      );
    }

    final bytes = await doc.save();
    await file.writeAsBytes(bytes, flush: true);

    sw.stop();
    debugPrint(
      '$_kExportLogTag success path=$resolvedPath '
      'duration=${sw.elapsed.inMilliseconds}ms',
    );

    return PdfExportResult(
      filePath: resolvedPath,
      pageCount: note.pages.length,
      elapsed: sw.elapsed,
    );
  }

  /// Deletes a temp PDF if it still exists.
  Future<void> deleteTempFile(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
      debugPrint('$_kExportLogTag deleted temp file $path');
    }
  }

  /// Renders the page's strokes at [_kExportPixelRatio].
  ///
  /// PDF-backed pages are rendered on a transparent background so the
  /// original background image can sit underneath in the PDF page.
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
          ? _kTransparent
          : blankBackgroundColor,
      simulatePressure: simulatePressure,
      pixelRatio: _kExportPixelRatio,
    );
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _loadPdfBackground(NotePageModel page) async {
    final backgroundPath = page.preRenderedImagePath;
    if (backgroundPath == null) {
      throw PdfExportException('PDF 배경 이미지가 없습니다. (page=${page.pageId})');
    }

    final backgroundFile = File(backgroundPath);
    if (!backgroundFile.existsSync()) {
      throw PdfExportException('배경 파일을 찾을 수 없습니다: $backgroundPath');
    }
    return backgroundFile.readAsBytes();
  }

  /// Builds a PDF page the size of the canvas with the background image (if
  /// any) and the sketch stretched over the whole page.
  pw.Page _buildPage({
    required NotePageModel page,
    required Uint8List sketchBytes,
    Uint8List? backgroundBytes,
  }) {
    final pageFormat = PdfPageFormat(
      page.drawingAreaWidth * _kPixelToPoint,
      page.drawingAreaHeight * _kPixelToPoint,
    );
    return pw.Page(
      pageFormat: pageFormat,
      build: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Stack(
          fit: pw.StackFit.expand,
          children: [
            if (backgroundBytes != null)
              pw.Image(pw.MemoryImage(backgroundBytes), fit: pw.BoxFit.fill),
            pw.Image(pw.MemoryImage(sketchBytes), fit: pw.BoxFit.fill),
          ],
        ),
      ),
    );
  }

  Future<String> _prepareTempPath(String title) async {
    final baseDir = await _tempDirectoryResolver();
    final dir = Directory(p.join(baseDir.path, 'pdf_exports'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final suggestion = PdfExportMvpService.buildSuggestedFileName(title);
    return _ensureUniquePath(dir, suggestion);
  }

  String _ensureUniquePath(Directory dir, String baseName) {
    final candidate = p.join(dir.path, '$baseName.pdf');
    if (!File(candidate).existsSync()) {
      return candidate;
    }

    for (var i = 1; i < 1000; i += 1) {
      final path = p.join(dir.path, '${baseName}_$i.pdf');
      if (!File(path).existsSync()) {
        return path;
      }
    }

    throw PdfExportException('파일 이름을 생성할 수 없습니다. (${dir.path})');
  }

  /// Builds the default `<note>_yyyyMMdd_HHmmss` PDF filename.
  static String buildSuggestedFileName(
    String title, {
    DateTime? timestamp,
  }) {
    final sanitized = _sanitizeTitle(title);
    final now = timestamp ?? DateTime.now();
    return '${sanitized}_${_twoDigits(now.year)}${_twoDigits(now.month)}'
        '${_twoDigits(now.day)}_${_twoDigits(now.hour)}'
        '${_twoDigits(now.minute)}${_twoDigits(now.second)}';
  }

  static String _sanitizeTitle(String title) {
    final replaced = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return replaced.trim().isEmpty ? 'clustudy_note' : replaced.trim();
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

Future<Directory> _resolveTempDirectory() async {
  if (Platform.isAndroid) {
    final base = await getTemporaryDirectory();
    return base;
  }
  final fallback = await getApplicationDocumentsDirectory();
  return fallback;
}
