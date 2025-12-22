import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:scribble/scribble.dart';

import '../../features/canvas/notifiers/custom_scribble_notifier.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_page_model.dart';

const _kPixelToPoint = 0.75; // PDF 포맷 환산 상수 (px -> pt)
const _kDefaultPixelRatio = 4.0;
const _kExportLogTag = '[pdf-export-mvp]';
const _kBlankBackgroundColor = ui.Color(0xFFFFFFFF);
const bool _kEnableExportDiagnostics = true;

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
      _logSketchSummary(notifier, page, index);

      final sketchBytes = await _renderSketch(
        notifier: notifier,
        page: page,
        blankBackgroundColor: blankBackgroundColor,
        simulatePressure: simulatePressure,
      );
      await _logImageMetrics(sketchBytes, page, index, label: 'scribble-only');
      final composedBytes = await _maybeCompositeWithBackground(
        page: page,
        sketchBytes: sketchBytes,
      );
      await _logImageMetrics(composedBytes, page, index, label: 'composed');
      final pdfBitmap = await _prepareBitmapForPdf(
        bytes: composedBytes,
        page: page,
        pageIndex: index,
      );

      final widthPt = page.drawingAreaWidth * _kPixelToPoint;
      final heightPt = page.drawingAreaHeight * _kPixelToPoint;
      final pageFormat = PdfPageFormat(widthPt, heightPt);
      if (_kEnableExportDiagnostics) {
        debugPrint(
          '$_kExportLogTag page=${page.pageNumber} '
          'format=${widthPt.toStringAsFixed(2)}pt x '
          '${heightPt.toStringAsFixed(2)}pt '
          '(logical=${page.drawingAreaWidth}x${page.drawingAreaHeight}, '
          'pixelRatio=$_kDefaultPixelRatio)',
        );
      }
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(
              pw.MemoryImage(
                pdfBitmap.bytes,
                dpi: _computeImageDpi(pdfBitmap.pixelRatio),
              ),
            ),
          ),
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

  Future<Uint8List> _renderSketch({
    required CustomScribbleNotifier notifier,
    required NotePageModel page,
    required ui.Color blankBackgroundColor,
    required bool simulatePressure,
  }) async {
    final size = ui.Size(page.drawingAreaWidth, page.drawingAreaHeight);

    debugPrint('📐$_kExportLogTag renderSketch size=$size');

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
    if (!backgroundFile.existsSync()) {
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

  static double _computeImageDpi(double pixelRatio) {
    return pixelRatio * PdfPageFormat.inch / _kPixelToPoint;
  }

  /// Exposes the DPI calculation for unit tests.
  @visibleForTesting
  static double computeImageDpiForTest({double? pixelRatio}) {
    return _computeImageDpi(pixelRatio ?? _kDefaultPixelRatio);
  }

  void _logSketchSummary(
    CustomScribbleNotifier notifier,
    NotePageModel page,
    int pageIndex,
  ) {
    if (!_kEnableExportDiagnostics) {
      return;
    }
    final sketch = notifier.value.sketch;
    if (sketch.lines.isEmpty) {
      debugPrint(
        '$_kExportLogTag page=${page.pageNumber} lines=0 '
        'drawingArea=${page.drawingAreaWidth}x${page.drawingAreaHeight}',
      );
      return;
    }
    final bounds = _computeSketchBounds(sketch);
    debugPrint(
      '$_kExportLogTag page=${page.pageNumber} '
      'lines=${sketch.lines.length} '
      'bounds=(${bounds.minX.toStringAsFixed(1)},'
      '${bounds.minY.toStringAsFixed(1)})→'
      '(${bounds.maxX.toStringAsFixed(1)},'
      '${bounds.maxY.toStringAsFixed(1)}) '
      'drawingArea=${page.drawingAreaWidth}x${page.drawingAreaHeight} '
      'index=$pageIndex',
    );
  }

  Future<void> _logImageMetrics(
    Uint8List bytes,
    NotePageModel page,
    int pageIndex, {
    required String label,
  }) async {
    if (!_kEnableExportDiagnostics) {
      return;
    }
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      debugPrint(
        '$_kExportLogTag page=${page.pageNumber} [$label] '
        'bitmap=${image.width}x${image.height} '
        'pageLogical=${page.drawingAreaWidth}x${page.drawingAreaHeight} '
        'index=$pageIndex',
      );
      image.dispose();
      codec.dispose();
    } catch (error) {
      debugPrint(
        '$_kExportLogTag failed to decode $label bitmap for page '
        '${page.pageNumber}: $error',
      );
    }
  }

  _SketchBounds _computeSketchBounds(Sketch sketch) {
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final line in sketch.lines) {
      for (final point in line.points) {
        if (point.x < minX) minX = point.x;
        if (point.y < minY) minY = point.y;
        if (point.x > maxX) maxX = point.x;
        if (point.y > maxY) maxY = point.y;
      }
    }
    if (minX == double.infinity) {
      minX = minY = maxX = maxY = 0;
    }
    return _SketchBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  Future<_PdfBitmap> _prepareBitmapForPdf({
    required Uint8List bytes,
    required NotePageModel page,
    required int pageIndex,
  }) async {
    final logicalWidth = page.drawingAreaWidth;
    final logicalHeight = page.drawingAreaHeight;
    if (logicalWidth <= 0 || logicalHeight <= 0) {
      return _PdfBitmap(bytes: bytes, pixelRatio: 1.0);
    }
    var targetWidth = (logicalWidth * _kPixelToPoint).round();
    var targetHeight = (logicalHeight * _kPixelToPoint).round();
    if (targetWidth <= 0) {
      targetWidth = 1;
    }
    if (targetHeight <= 0) {
      targetHeight = 1;
    }
    ui.Codec? codec;
    ui.Image? image;
    ui.Image? scaledImage;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      image = frame.image;
      final originalWidth = image.width;
      final originalHeight = image.height;
      final originalRatio =
          targetWidth == 0 ? 1.0 : originalWidth / targetWidth;

      if (originalWidth == targetWidth && originalHeight == targetHeight) {
        if (_kEnableExportDiagnostics) {
          debugPrint(
            '$_kExportLogTag page=${page.pageNumber} [pdf-ready] '
            'bitmap=${originalWidth}x$originalHeight (no scale) '
            'target=${targetWidth}x${targetHeight} index=$pageIndex',
          );
        }
        return _PdfBitmap(bytes: bytes, pixelRatio: originalRatio);
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        image,
        ui.Rect.fromLTWH(
          0,
          0,
          originalWidth.toDouble(),
          originalHeight.toDouble(),
        ),
        ui.Rect.fromLTWH(
          0,
          0,
          targetWidth.toDouble(),
          targetHeight.toDouble(),
        ),
        ui.Paint(),
      );

      scaledImage = await recorder.endRecording().toImage(
        targetWidth,
        targetHeight,
      );
      final byteData = await scaledImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        return _PdfBitmap(bytes: bytes, pixelRatio: originalRatio);
      }
      if (_kEnableExportDiagnostics) {
        debugPrint(
          '$_kExportLogTag page=${page.pageNumber} [pdf-ready] '
          'bitmap=${scaledImage.width}x${scaledImage.height} '
          'target=${targetWidth}x${targetHeight} index=$pageIndex',
        );
      }
      return _PdfBitmap(
        bytes: byteData.buffer.asUint8List(),
        pixelRatio: 1.0,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '$_kExportLogTag failed to scale bitmap for page ${page.pageNumber}: '
        '$error\n$stackTrace',
      );
      return _PdfBitmap(bytes: bytes, pixelRatio: _kDefaultPixelRatio);
    } finally {
      image?.dispose();
      scaledImage?.dispose();
      codec?.dispose();
    }
  }
}

Future<Directory> _resolveTempDirectory() async {
  if (Platform.isAndroid) {
    final base = await getTemporaryDirectory();
    return base;
  }
  final fallback = await getApplicationDocumentsDirectory();
  return fallback;
}

class _SketchBounds {
  const _SketchBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
}

class _PdfBitmap {
  const _PdfBitmap({
    required this.bytes,
    required this.pixelRatio,
  });

  final Uint8List bytes;
  final double pixelRatio;
}
