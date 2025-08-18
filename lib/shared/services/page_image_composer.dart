import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../features/notes/models/note_page_model.dart';

/// 페이지별 이미지 합성을 담당하는 서비스입니다.
///
/// 이 서비스는 다음 기능을 제공합니다:
/// - ScribbleNotifier에서 고해상도 스케치 이미지 추출
/// - PDF 배경 이미지 로드 및 처리
/// - 배경과 스케치를 합성한 최종 페이지 이미지 생성
class PageImageComposer {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  PageImageComposer._();

  /// 기본 해상도 설정
  static const double _defaultPixelRatio = 4.0; // 고해상도 (4배)
  
  /// 표준 페이지 크기 (A4 기준, DPI 300)
  static const double _pageWidth = 2480.0; // 8.27" * 300 DPI
  static const double _pageHeight = 3508.0; // 11.69" * 300 DPI

  /// ScribbleNotifier에서 고해상도 스케치 이미지를 추출합니다.
  ///
  /// [notifier]: 스케치 데이터를 포함한 ScribbleNotifier
  /// [pixelRatio]: 출력 해상도 배율 (기본: 4.0)
  ///
  /// Returns: 투명 배경의 스케치 이미지 바이트 배열 또는 null (실패시)
  static Future<Uint8List?> extractSketchImage(
    ScribbleNotifier notifier, {
    double pixelRatio = _defaultPixelRatio,
  }) async {
    try {
      debugPrint('🎨 스케치 이미지 추출 시작 (pixelRatio: $pixelRatio)');

      // ScribbleNotifier의 renderImage 메서드를 사용하여 고해상도 이미지 생성
      final imageData = await notifier.renderImage(
        pixelRatio: pixelRatio,
        format: ui.ImageByteFormat.png, // 투명도 지원을 위해 PNG 사용
      );

      final bytes = imageData.buffer.asUint8List();
      debugPrint('✅ 스케치 이미지 추출 완료 (크기: ${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      debugPrint('❌ 스케치 이미지 추출 실패: $e');
      return null;
    }
  }

  /// PDF 배경 이미지를 로드하고 지정된 크기로 리사이징합니다.
  ///
  /// [page]: 페이지 모델 (배경 이미지 정보 포함)
  /// [targetWidth]: 목표 너비
  /// [targetHeight]: 목표 높이
  ///
  /// Returns: 처리된 배경 이미지 또는 null (배경 없음 또는 실패시)
  static Future<ui.Image?> loadPdfBackground(
    NotePageModel page, {
    double targetWidth = _pageWidth,
    double targetHeight = _pageHeight,
  }) async {
    try {
      // PDF 배경이 없는 경우
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

      // 이미지 파일 읽기
      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: targetWidth.toInt(),
        targetHeight: targetHeight.toInt(),
      );
      final frame = await codec.getNextFrame();

      debugPrint('✅ PDF 배경 로드 완료: ${frame.image.width}x${frame.image.height}');
      return frame.image;
    } catch (e) {
      debugPrint('❌ PDF 배경 로드 실패: ${page.pageId} - $e');
      return null;
    }
  }

  /// 배경 이미지와 스케치 이미지를 합성하여 최종 페이지 이미지를 생성합니다.
  ///
  /// [page]: 페이지 모델
  /// [notifier]: 스케치 데이터를 포함한 ScribbleNotifier
  /// [pixelRatio]: 출력 해상도 배율
  ///
  /// Returns: 합성된 최종 페이지 이미지 바이트 배열
  static Future<Uint8List> compositePageImage(
    NotePageModel page,
    ScribbleNotifier notifier, {
    double pixelRatio = _defaultPixelRatio,
  }) async {
    try {
      debugPrint('🎭 페이지 이미지 합성 시작: ${page.pageId}');

      // 최종 이미지 크기 계산
      final finalWidth = (_pageWidth * pixelRatio / _defaultPixelRatio).toInt();
      final finalHeight = (_pageHeight * pixelRatio / _defaultPixelRatio).toInt();

      // PictureRecorder로 캔버스 생성
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final canvasSize = Size(finalWidth.toDouble(), finalHeight.toDouble());

      // 1. 배경 렌더링
      await _renderBackground(canvas, page, canvasSize);

      // 2. 스케치 오버레이
      await _renderSketchOverlay(canvas, notifier, canvasSize, pixelRatio);

      // 3. Picture를 이미지로 변환
      final picture = recorder.endRecording();
      final image = await picture.toImage(finalWidth, finalHeight);

      // 4. 이미지를 바이트 배열로 변환
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // 5. 리소스 정리
      picture.dispose();
      image.dispose();

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        debugPrint('✅ 페이지 이미지 합성 완료: ${page.pageId} (크기: ${bytes.length} bytes)');
        return bytes;
      } else {
        throw Exception('이미지 바이트 변환 실패');
      }
    } catch (e) {
      debugPrint('❌ 페이지 이미지 합성 실패: ${page.pageId} - $e');
      // 실패 시 플레이스홀더 이미지 반환
      return await _generateErrorPlaceholder(page.pageNumber);
    }
  }

  /// 여러 페이지를 배치로 처리하여 메모리 효율성을 높입니다.
  ///
  /// [pages]: 처리할 페이지 목록
  /// [notifiers]: 페이지별 ScribbleNotifier 맵
  /// [onProgress]: 진행률 콜백 (선택적)
  /// [pixelRatio]: 출력 해상도 배율
  ///
  /// Returns: 페이지별 이미지 바이트 배열 목록
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
      
      if (notifier == null) {
        debugPrint('⚠️ ScribbleNotifier 없음: ${page.pageId}');
        results.add(await _generateErrorPlaceholder(page.pageNumber));
        continue;
      }

      // 진행률 업데이트
      onProgress?.call((i / pages.length), '페이지 ${page.pageNumber} 처리 중...');

      // 페이지 이미지 합성
      final pageImage = await compositePageImage(page, notifier, pixelRatio: pixelRatio);
      results.add(pageImage);

      // 메모리 정리 (GC 힌트)
      if (i % 5 == 4) {
        // 5페이지마다 가비지 컬렉션 힌트
        debugPrint('🗑️ 메모리 정리 힌트 (페이지 ${i + 1}/${pages.length})');
      }
    }

    onProgress?.call(1.0, '모든 페이지 처리 완료');
    return results;
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// 배경을 렌더링합니다.
  static Future<void> _renderBackground(
    Canvas canvas,
    NotePageModel page,
    Size canvasSize,
  ) async {
    // 흰색 배경으로 초기화
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      backgroundPaint,
    );

    // PDF 배경이 있는 경우 렌더링
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

  /// 스케치를 오버레이로 렌더링합니다.
  static Future<void> _renderSketchOverlay(
    Canvas canvas,
    ScribbleNotifier notifier,
    Size canvasSize,
    double pixelRatio,
  ) async {
    try {
      // ScribbleNotifier에서 고해상도 스케치 추출
      final sketchBytes = await extractSketchImage(notifier, pixelRatio: pixelRatio);
      
      if (sketchBytes != null) {
        // 스케치 이미지를 Canvas에 오버레이
        final codec = await ui.instantiateImageCodec(sketchBytes);
        final frame = await codec.getNextFrame();
        final sketchImage = frame.image;

        // 스케치 이미지를 캔버스 크기에 맞게 스케일링
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
      } else {
        debugPrint('⚠️ 스케치 이미지 추출 실패, 빈 스케치로 처리');
      }
    } catch (e) {
      debugPrint('❌ 스케치 오버레이 실패: $e');
    }
  }

  /// 오류 발생 시 플레이스홀더 이미지를 생성합니다.
  static Future<Uint8List> _generateErrorPlaceholder(int pageNumber) async {
    try {
      debugPrint('🔧 오류 플레이스홀더 생성: 페이지 $pageNumber');

      const width = _pageWidth;
      const height = _pageHeight;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 연한 회색 배경
      final backgroundPaint = Paint()..color = const Color(0xFFF5F5F5);
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), backgroundPaint);

      // 테두리
      final borderPaint = Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
        const Rect.fromLTWH(1, 1, width - 2, height - 2),
        borderPaint,
      );

      // 오류 메시지
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

      // Picture를 이미지로 변환
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