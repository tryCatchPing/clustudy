import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../features/notes/models/note_page_model.dart';

/// 페이지별 이미지 합성을 담당하는 서비스입니다.
class PageImageComposer {
  PageImageComposer._();

  static const double _defaultPixelRatio = 4.0;

  static Future<Uint8List?> extractSketchImage(
    ScribbleNotifier notifier, {
    double pixelRatio = _defaultPixelRatio,
  }) async {
    try {
      debugPrint('🎨 스케치 이미지 추출 시작 (pixelRatio: $pixelRatio)');
      final imageData = await notifier.renderImage(
        pixelRatio: pixelRatio,
        format: ui.ImageByteFormat.png,
      );
      debugPrint('  - ✅ renderImage() Succeeded (pixelRatio: $pixelRatio)');
      final bytes = imageData.buffer.asUint8List();
      debugPrint('✅ 스케치 이미지 추출 완료 (크기: ${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      debugPrint(
        '  - ❌ renderImage() FAILED (pixelRatio: $pixelRatio). Error: $e',
      );
      debugPrint('❌ 스케치 이미지 추출 실패: $e');
      return null;
    }
  }

  static Future<ui.Image?> loadPdfBackground(
    NotePageModel page, {
    double? targetWidth,
    double? targetHeight,
  }) async {
    try {
      if (!page.hasPdfBackground || !page.hasPreRenderedImage) {
        debugPrint('ℹ️ PDF 배경 없음: ${page.pageId}');
        return null;
      }

      debugPrint('📄 PDF 배경 로드 시작: ${page.preRenderedImagePath}');
      final imageFile = File(page.preRenderedImagePath!);
      if (!imageFile.existsSync()) {
        debugPrint('⚠️ PDF 배경 파일 없음: ${page.preRenderedImagePath}');
        return null;
      }

      final fileBytes = imageFile.lengthSync();
      debugPrint(
        '  - BG File Exists: ${page.preRenderedImagePath} (${fileBytes} bytes)',
      );

      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: targetWidth?.toInt(),
        targetHeight: targetHeight?.toInt(),
      );
      final frame = await codec.getNextFrame();
      debugPrint(
        '  - BG Decode Success: ${frame.image.width}x${frame.image.height}',
      );
      debugPrint('✅ PDF 배경 로드 완료: ${frame.image.width}x${frame.image.height}');
      return frame.image;
    } catch (e) {
      debugPrint('❌ PDF 배경 로드 실패: ${page.pageId} - $e');
      return null;
    }
  }

  static Future<Uint8List> compositePageImage(
    NotePageModel page,
    ScribbleNotifier notifier, {
    double pixelRatio = _defaultPixelRatio,
  }) async {
    try {
      debugPrint('🎭 페이지 이미지 합성 시작: ${page.pageId}');
      final pageWidth = page.drawingAreaWidth;
      final pageHeight = page.drawingAreaHeight;
      final finalWidth = (pageWidth * pixelRatio / _defaultPixelRatio).toInt();
      final finalHeight = (pageHeight * pixelRatio / _defaultPixelRatio)
          .toInt();

      debugPrint(
        '📐 캔버스 크기: ${pageWidth}x$pageHeight, 출력 크기: ${finalWidth}x$finalHeight',
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final canvasSize = Size(finalWidth.toDouble(), finalHeight.toDouble());

      await _renderBackground(canvas, page, canvasSize);
      await _renderSketchOverlay(canvas, notifier, canvasSize, pixelRatio);

      final picture = recorder.endRecording();
      final image = await picture.toImage(finalWidth, finalHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      picture.dispose();
      image.dispose();

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        debugPrint(
          '✅ 페이지 이미지 합성 완료: ${page.pageId} (크기: ${bytes.length} bytes)',
        );
        try {
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          debugPrint(
            '  - Sanity Check: Composed PNG is valid (${frame.image.width}x${frame.image.height})',
          );
          frame.image.dispose();
        } catch (e) {
          debugPrint(
            '  - 🚨 Sanity Check FAILED: Composed PNG is invalid! Error: $e',
          );
        }
        return bytes;
      } else {
        throw Exception('이미지 바이트 변환 실패');
      }
    } catch (e) {
      debugPrint('❌ 페이지 이미지 합성 실패: ${page.pageId} - $e');
      return _generateErrorPlaceholder(
        page.pageNumber,
        width: page.drawingAreaWidth,
        height: page.drawingAreaHeight,
      );
    }
  }

  static Future<List<Uint8List>> compositeMultiplePages(
    List<NotePageModel> pages,
    Map<String, ScribbleNotifier> notifiers, {
    void Function(double progress, String currentPage)? onProgress,
    double pixelRatio = _defaultPixelRatio,
  }) async {
    final results = <Uint8List>[];
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final notifier = notifiers[page.pageId];

      debugPrint(
        '==================== Processing Page ${page.pageNumber} ====================',
      );
      debugPrint('  - Page ID: ${page.pageId}');
      debugPrint(
        '  - Drawing Area: ${page.drawingAreaWidth}x${page.drawingAreaHeight}',
      );
      debugPrint('  - Has PDF BG: ${page.hasPdfBackground}');
      debugPrint('  - Has Prerendered: ${page.hasPreRenderedImage}');
      debugPrint('  - Prerendered Path: ${page.preRenderedImagePath}');

      if (notifier == null) {
        debugPrint('⚠️ ScribbleNotifier 없음: ${page.pageId}');
        results.add(
          await _generateErrorPlaceholder(
            page.pageNumber,
            width: page.drawingAreaWidth,
            height: page.drawingAreaHeight,
          ),
        );
        continue;
      }

      onProgress?.call((i / pages.length), '페이지 ${page.pageNumber} 처리 중...');

      final pageImage = await compositePageImage(
        page,
        notifier,
        pixelRatio: pixelRatio,
      );
      results.add(pageImage);

      if (i % 5 == 4) {
        debugPrint('🗑️ 메모리 정리 힌트 (페이지 ${i + 1}/${pages.length})');
      }
    }

    onProgress?.call(1.0, '모든 페이지 처리 완료');
    return results;
  }

  static Future<void> _renderBackground(
    Canvas canvas,
    NotePageModel page,
    Size canvasSize,
  ) async {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      backgroundPaint,
    );

    if (page.hasPdfBackground && page.hasPreRenderedImage) {
      final backgroundImage = await loadPdfBackground(
        page,
        targetWidth: canvasSize.width,
        targetHeight: canvasSize.height,
      );

      if (backgroundImage != null) {
        final srcRect = Rect.fromLTWH(
          0,
          0,
          backgroundImage.width.toDouble(),
          backgroundImage.height.toDouble(),
        );
        final dstRect = Rect.fromLTWH(
          0,
          0,
          canvasSize.width,
          canvasSize.height,
        );

        canvas.drawImageRect(backgroundImage, srcRect, dstRect, Paint());
        backgroundImage.dispose();
        debugPrint('✅ PDF 배경 렌더링 완료');
      }
    }
  }

  static Future<void> _renderSketchOverlay(
    Canvas canvas,
    ScribbleNotifier notifier,
    Size canvasSize,
    double pixelRatio,
  ) async {
    try {
      final sketchBytes = await extractSketchImage(
        notifier,
        pixelRatio: pixelRatio,
      );

      if (sketchBytes != null) {
        try {
          final codec = await ui.instantiateImageCodec(sketchBytes);
          final frame = await codec.getNextFrame();
          final sketchImage = frame.image;

          final srcRect = Rect.fromLTWH(
            0,
            0,
            sketchImage.width.toDouble(),
            sketchImage.height.toDouble(),
          );
          final dstRect = Rect.fromLTWH(
            0,
            0,
            canvasSize.width,
            canvasSize.height,
          );

          canvas.drawImageRect(sketchImage, srcRect, dstRect, Paint());
          sketchImage.dispose();
          debugPrint('✅ 스케치 오버레이 완료');
        } catch (imageError) {
          debugPrint('❌ 스케치 이미지 렌더링 실패: $imageError');
        }
      } else {
        debugPrint('⚠️ 스케치 이미지 추출 실패, 배경만 처리');
      }
    } catch (e) {
      debugPrint('❌ 스케치 오버레이 실패: $e');
    }
  }

  static Future<Uint8List> _generateErrorPlaceholder(
    int pageNumber, {
    double width = 2000.0,
    double height = 2000.0,
  }) async {
    try {
      debugPrint('🔧 오류 플레이스홀더 생성: 페이지 $pageNumber (${width}x$height)');
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final backgroundPaint = Paint()..color = const Color(0xFFF5F5F5);
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
      final borderPaint = Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
        Rect.fromLTWH(1, 1, width - 2, height - 2),
        borderPaint,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '페이지 $pageNumber\n이미지 생성 오류',
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 48,
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      image.dispose();
      debugPrint('✅ 오류 플레이스홀더 생성 완료');
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ 오류 플레이스홀더 생성 실패: $e');
      rethrow;
    }
  }
}
