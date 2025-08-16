import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scribble/scribble.dart';

import '../../features/notes/data/notes_repository.dart';
import '../../features/notes/models/note_page_model.dart';
import '../../features/notes/models/thumbnail_metadata.dart';
import 'file_storage_service.dart';

/// 페이지 썸네일 생성 및 캐싱을 담당하는 서비스입니다.
///
/// 이 서비스는 다음 기능을 제공합니다:
/// - PDF 배경과 스케치 오버레이를 포함한 썸네일 렌더링
/// - 파일 시스템 캐시 관리
/// - 썸네일 메타데이터 관리
/// - 기본 플레이스홀더 이미지 처리
class PageThumbnailService {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  PageThumbnailService._();

  /// 썸네일 기본 크기 설정
  static const double _thumbnailWidth = 200.0;
  static const double _thumbnailHeight = 200.0;

  /// 기본 플레이스홀더 색상
  static const Color _placeholderBackgroundColor = Color(0xFFF5F5F5);
  static const Color _placeholderBorderColor = Color(0xFFE0E0E0);
  static const Color _placeholderTextColor = Color(0xFF9E9E9E);

  /// 페이지 썸네일을 생성합니다.
  ///
  /// PDF 배경이 있는 경우 배경 이미지와 스케치를 합성하고,
  /// 빈 페이지인 경우 스케치만 렌더링합니다.
  ///
  /// [page]: 썸네일을 생성할 페이지 모델
  ///
  /// Returns: 생성된 썸네일 이미지 바이트 배열 또는 null (실패시)
  static Future<Uint8List?> generateThumbnail(NotePageModel page) async {
    try {
      debugPrint('🎨 썸네일 생성 시작: ${page.pageId}');

      // 스케치 데이터 파싱
      final sketch = page.toSketch();

      // 캔버스 크기 계산
      final canvasSize = _calculateCanvasSize(page);
      final scale = _calculateScale(canvasSize);

      // PictureRecorder로 캔버스 생성
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 배경 렌더링
      await _renderBackground(canvas, page, canvasSize);

      // 스케치 렌더링
      _renderSketch(canvas, sketch, scale);

      // Picture를 이미지로 변환
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        _thumbnailWidth.toInt(),
        _thumbnailHeight.toInt(),
      );

      // 이미지를 바이트 배열로 변환
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      picture.dispose();
      image.dispose();

      if (byteData != null) {
        debugPrint('✅ 썸네일 생성 완료: ${page.pageId}');
        return byteData.buffer.asUint8List();
      } else {
        debugPrint('❌ 썸네일 바이트 변환 실패: ${page.pageId}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 썸네일 생성 실패: ${page.pageId} - $e');
      return null;
    }
  }

  /// 캐시된 썸네일을 가져옵니다.
  ///
  /// [pageId]: 페이지 고유 ID
  /// [noteId]: 노트 고유 ID
  ///
  /// Returns: 캐시된 썸네일 바이트 배열 또는 null (캐시 없음)
  static Future<Uint8List?> getCachedThumbnail(
    String pageId,
    String noteId,
  ) async {
    try {
      final thumbnailPath = await FileStorageService.getExistingThumbnailPath(
        noteId: noteId,
        pageId: pageId,
      );

      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        final bytes = await thumbnailFile.readAsBytes();
        debugPrint('✅ 캐시된 썸네일 로드: $pageId');
        return bytes;
      } else {
        debugPrint('ℹ️ 캐시된 썸네일 없음: $pageId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ 캐시된 썸네일 로드 실패: $pageId - $e');
      return null;
    }
  }

  /// 썸네일을 파일 시스템에 캐시합니다.
  ///
  /// [pageId]: 페이지 고유 ID
  /// [noteId]: 노트 고유 ID
  /// [thumbnail]: 캐시할 썸네일 바이트 배열
  ///
  /// Returns: 캐시 성공 여부
  static Future<bool> cacheThumbnailToFile(
    String pageId,
    String noteId,
    Uint8List thumbnail,
  ) async {
    try {
      // 썸네일 캐시 디렉토리 생성
      await FileStorageService.ensureThumbnailCacheDirectory(noteId);

      // 썸네일 파일 경로 생성
      final thumbnailPath = await FileStorageService.getThumbnailPath(
        noteId: noteId,
        pageId: pageId,
      );

      // 파일에 썸네일 저장
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnail);

      debugPrint('✅ 썸네일 캐시 저장: $pageId');
      return true;
    } catch (e) {
      debugPrint('❌ 썸네일 캐시 저장 실패: $pageId - $e');
      return false;
    }
  }

  /// 썸네일 캐시를 무효화합니다.
  ///
  /// [pageId]: 페이지 고유 ID
  /// [noteId]: 노트 고유 ID
  static Future<void> invalidateFileCache(
    String pageId,
    String noteId,
  ) async {
    try {
      await FileStorageService.deleteThumbnailCache(
        noteId: noteId,
        pageId: pageId,
      );
      debugPrint('✅ 썸네일 캐시 무효화: $pageId');
    } catch (e) {
      debugPrint('❌ 썸네일 캐시 무효화 실패: $pageId - $e');
    }
  }

  /// 썸네일 메타데이터를 업데이트합니다.
  ///
  /// [pageId]: 페이지 고유 ID
  /// [noteId]: 노트 고유 ID
  /// [metadata]: 업데이트할 메타데이터
  /// [repo]: 노트 저장소
  static Future<void> updateThumbnailMetadata(
    String pageId,
    String noteId,
    ThumbnailMetadata metadata,
    NotesRepository repo,
  ) async {
    try {
      await repo.updateThumbnailMetadata(pageId, metadata);
      debugPrint('✅ 썸네일 메타데이터 업데이트: $pageId');
    } catch (e) {
      debugPrint('❌ 썸네일 메타데이터 업데이트 실패: $pageId - $e');
    }
  }

  /// 페이지 내용 변경 감지용 체크섬을 생성합니다.
  ///
  /// [page]: 체크섬을 생성할 페이지 모델
  ///
  /// Returns: 페이지 내용의 체크섬
  static String generatePageChecksum(NotePageModel page) {
    final content = StringBuffer();

    // 스케치 데이터 추가
    content.write(page.jsonData);

    // 배경 정보 추가
    content.write(page.backgroundType.toString());
    if (page.backgroundPdfPath != null) {
      content.write(page.backgroundPdfPath);
    }
    if (page.backgroundPdfPageNumber != null) {
      content.write(page.backgroundPdfPageNumber.toString());
    }
    content.write(page.showBackgroundImage.toString());

    // MD5 해시 생성
    final bytes = content.toString().codeUnits;
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 기본 플레이스홀더 썸네일을 생성합니다.
  ///
  /// [pageNumber]: 페이지 번호 (표시용)
  ///
  /// Returns: 플레이스홀더 썸네일 바이트 배열
  static Future<Uint8List> generatePlaceholderThumbnail(
    int pageNumber,
  ) async {
    try {
      debugPrint('🎨 플레이스홀더 썸네일 생성: 페이지 $pageNumber');

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 배경 그리기
      final backgroundPaint = Paint()..color = _placeholderBackgroundColor;
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, _thumbnailWidth, _thumbnailHeight),
        backgroundPaint,
      );

      // 테두리 그리기
      final borderPaint = Paint()
        ..color = _placeholderBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(
        const Rect.fromLTWH(1, 1, _thumbnailWidth - 2, _thumbnailHeight - 2),
        borderPaint,
      );

      // 페이지 번호 텍스트 그리기
      final textPainter = TextPainter(
        text: TextSpan(
          text: pageNumber.toString(),
          style: const TextStyle(
            color: _placeholderTextColor,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      final textOffset = Offset(
        (_thumbnailWidth - textPainter.width) / 2,
        (_thumbnailHeight - textPainter.height) / 2,
      );
      textPainter.paint(canvas, textOffset);

      // Picture를 이미지로 변환
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        _thumbnailWidth.toInt(),
        _thumbnailHeight.toInt(),
      );

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      picture.dispose();
      image.dispose();

      debugPrint('✅ 플레이스홀더 썸네일 생성 완료: 페이지 $pageNumber');
      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ 플레이스홀더 썸네일 생성 실패: 페이지 $pageNumber - $e');
      rethrow;
    }
  }

  /// 페이지와 썸네일을 함께 처리하는 통합 메서드입니다.
  ///
  /// 캐시된 썸네일이 있고 유효한 경우 캐시를 반환하고,
  /// 그렇지 않으면 새로 생성하여 캐시에 저장합니다.
  ///
  /// [page]: 처리할 페이지 모델
  /// [repo]: 노트 저장소 (메타데이터 저장용)
  ///
  /// Returns: 썸네일 바이트 배열 또는 null (실패시)
  static Future<Uint8List?> getOrGenerateThumbnail(
    NotePageModel page,
    NotesRepository repo,
  ) async {
    try {
      // 1. 캐시된 썸네일 확인
      final cachedThumbnail = await getCachedThumbnail(
        page.pageId,
        page.noteId,
      );

      if (cachedThumbnail != null) {
        // 2. 캐시된 메타데이터 확인
        final metadata = await repo.getThumbnailMetadata(page.pageId);
        if (metadata != null) {
          // 3. 체크섬 비교로 유효성 확인
          final currentChecksum = generatePageChecksum(page);
          if (metadata.checksum == currentChecksum) {
            // 4. 접근 시간 업데이트
            final updatedMetadata = metadata.updateLastAccessed();
            await updateThumbnailMetadata(
              page.pageId,
              page.noteId,
              updatedMetadata,
              repo,
            );
            debugPrint('✅ 유효한 캐시된 썸네일 반환: ${page.pageId}');
            return cachedThumbnail;
          } else {
            debugPrint('⚠️ 썸네일 캐시 무효화 (내용 변경): ${page.pageId}');
          }
        }
      }

      // 5. 새 썸네일 생성
      final newThumbnail = await generateThumbnail(page);
      if (newThumbnail == null) {
        debugPrint('❌ 썸네일 생성 실패, 플레이스홀더 사용: ${page.pageId}');
        return await generatePlaceholderThumbnail(page.pageNumber);
      }

      // 6. 캐시에 저장
      final cacheSuccess = await cacheThumbnailToFile(
        page.pageId,
        page.noteId,
        newThumbnail,
      );

      if (cacheSuccess) {
        // 7. 메타데이터 생성 및 저장
        final thumbnailPath = await FileStorageService.getThumbnailPath(
          noteId: page.noteId,
          pageId: page.pageId,
        );

        final now = DateTime.now();
        final metadata = ThumbnailMetadata(
          pageId: page.pageId,
          cachePath: thumbnailPath,
          createdAt: now,
          lastAccessedAt: now,
          fileSizeBytes: newThumbnail.length,
          checksum: generatePageChecksum(page),
        );

        await updateThumbnailMetadata(
          page.pageId,
          page.noteId,
          metadata,
          repo,
        );
      }

      return newThumbnail;
    } catch (e) {
      debugPrint('❌ 썸네일 처리 실패: ${page.pageId} - $e');
      // 실패 시 플레이스홀더 반환
      try {
        return await generatePlaceholderThumbnail(page.pageNumber);
      } catch (placeholderError) {
        debugPrint('❌ 플레이스홀더 생성도 실패: $placeholderError');
        return null;
      }
    }
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// 페이지의 캔버스 크기를 계산합니다.
  static Size _calculateCanvasSize(NotePageModel page) {
    return Size(
      page.drawingAreaWidth,
      page.drawingAreaHeight,
    );
  }

  /// 썸네일 크기에 맞는 스케일을 계산합니다.
  static double _calculateScale(Size canvasSize) {
    final scaleX = _thumbnailWidth / canvasSize.width;
    final scaleY = _thumbnailHeight / canvasSize.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  /// 배경을 렌더링합니다.
  static Future<void> _renderBackground(
    Canvas canvas,
    NotePageModel page,
    Size canvasSize,
  ) async {
    // 흰색 배경으로 초기화
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _thumbnailWidth, _thumbnailHeight),
      backgroundPaint,
    );

    // PDF 배경이 있는 경우 렌더링
    if (page.hasPdfBackground && page.hasPreRenderedImage) {
      await _renderPdfBackground(canvas, page, canvasSize);
    }
  }

  /// PDF 배경을 렌더링합니다.
  static Future<void> _renderPdfBackground(
    Canvas canvas,
    NotePageModel page,
    Size canvasSize,
  ) async {
    try {
      final imageFile = File(page.preRenderedImagePath!);
      if (!imageFile.existsSync()) {
        debugPrint('⚠️ PDF 배경 이미지 파일 없음: ${page.preRenderedImagePath}');
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // 이미지를 썸네일 크기에 맞게 그리기
      final srcRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      const dstRect = Rect.fromLTWH(
        0,
        0,
        _thumbnailWidth,
        _thumbnailHeight,
      );

      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      image.dispose();
    } catch (e) {
      debugPrint('❌ PDF 배경 렌더링 실패: ${page.pageId} - $e');
    }
  }

  /// 스케치를 렌더링합니다.
  static void _renderSketch(Canvas canvas, Sketch sketch, double scale) {
    try {
      // 캔버스 스케일 적용
      canvas.save();
      canvas.scale(scale);

      // 각 선을 그리기
      for (final line in sketch.lines) {
        _renderSketchLine(canvas, line);
      }

      canvas.restore();
    } catch (e) {
      debugPrint('❌ 스케치 렌더링 실패: $e');
    }
  }

  /// 개별 스케치 선을 렌더링합니다.
  static void _renderSketchLine(Canvas canvas, SketchLine line) {
    if (line.points.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = Color(line.color)
      ..strokeWidth = line.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (line.points.length == 1) {
      // 단일 점인 경우 원으로 그리기
      final point = line.points.first;
      canvas.drawCircle(
        Offset(point.x, point.y),
        line.width / 2,
        paint..style = PaintingStyle.fill,
      );
    } else {
      // 여러 점인 경우 경로로 그리기
      final path = Path();
      final firstPoint = line.points.first;
      path.moveTo(firstPoint.x, firstPoint.y);

      for (int i = 1; i < line.points.length; i++) {
        final point = line.points[i];
        path.lineTo(point.x, point.y);
      }

      canvas.drawPath(path, paint);
    }
  }
}
