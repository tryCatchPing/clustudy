import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:scribble/scribble.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_page_model.dart';
import 'page_image_composer.dart';

/// PDF 내보내기를 담당하는 서비스입니다.
///
/// 이 서비스는 다음 기능을 제공합니다:
/// - 페이지 이미지들을 PDF 문서로 변환
/// - PDF 파일 저장 및 공유
/// - 진행상태 추적 및 에러 처리
/// - 메모리 효율적인 대용량 처리
class PdfExportService {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  PdfExportService._();

  /// PDF 문서 메타데이터
  static const String _pdfTitle = 'It Contest Note';
  static const String _pdfCreator = 'It Contest App';
  static const String _pdfSubject = 'Handwritten Note Export';

  /// 내보내기 품질 옵션
  static const Map<ExportQuality, double> _qualityPixelRatios = {
    ExportQuality.standard: 2.0,
    ExportQuality.high: 3.0,
    ExportQuality.ultra: 4.0,
  };

  /// 단일 페이지 이미지를 PDF 페이지로 변환합니다.
  ///
  /// [pageImageBytes]: 페이지 이미지 바이트 배열
  /// [pageWidth]: 페이지 너비 (포인트 단위)
  /// [pageHeight]: 페이지 높이 (포인트 단위)
  /// [pageNumber]: 페이지 번호 (메타데이터용)
  ///
  /// Returns: PDF 페이지 위젯
  static pw.Page createPdfPage(
    Uint8List pageImageBytes, {
    double? pageWidth,
    double? pageHeight,
    int? pageNumber,
  }) {
    try {
      debugPrint(
        '📄 PDF 페이지 생성: ${pageNumber ?? '알 수 없음'} (${pageWidth ?? 'A4'}x${pageHeight ?? 'A4'})',
      );

      // 페이지 크기가 지정된 경우 해당 크기로, 없으면 A4 기본값 사용
      final pageFormat = (pageWidth != null && pageHeight != null)
          ? PdfPageFormat(pageWidth, pageHeight)
          : PdfPageFormat.a4;

      return pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero, // 여백 없음으로 전체 페이지 활용
        build: (context) {
          return pw.Image(
            pw.MemoryImage(pageImageBytes),
            fit: pw.BoxFit.fill, // 페이지 전체를 채움 (비율은 이미 이미지에서 처리됨)
          );
        },
      );
    } catch (e) {
      debugPrint('❌ PDF 페이지 생성 실패: ${pageNumber ?? '알 수 없음'} - $e');
      rethrow;
    }
  }

  /// 전체 노트를 PDF 문서로 내보냅니다.
  ///
  /// [note]: 내보낼 노트 모델
  /// [pageNotifiers]: 페이지별 ScribbleNotifier 맵
  /// [quality]: 내보내기 품질 (기본: 고화질)
  /// [pageRange]: 내보낼 페이지 범위 (기본: 전체)
  /// [onProgress]: 진행률 콜백
  ///
  /// Returns: 생성된 PDF 파일 바이트 배열
  static Future<Uint8List> exportNoteToPdf(
    NoteModel note,
    Map<String, ScribbleNotifier> pageNotifiers, {
    ExportQuality quality = ExportQuality.high,
    ExportPageRange? pageRange,
    void Function(double progress, String message)? onProgress,
  }) async {
    try {
      debugPrint('📚 PDF 내보내기 시작: ${note.title}');
      onProgress?.call(0.0, 'PDF 내보내기 준비 중...');

      // 1. 내보낼 페이지 필터링
      final pagesToExport = _filterPagesForExport(note.pages, pageRange);
      final pixelRatio = _qualityPixelRatios[quality]!;

      debugPrint('📄 내보낼 페이지 수: ${pagesToExport.length}');
      debugPrint('🎯 품질 설정: $quality (pixelRatio: $pixelRatio)');

      // 2. 페이지별 이미지 생성
      onProgress?.call(0.1, '페이지 이미지 생성 중...');
      final pageImages = await PageImageComposer.compositeMultiplePages(
        pagesToExport,
        pageNotifiers,
        pixelRatio: pixelRatio,
        onProgress: (imageProgress, currentPageMsg) {
          final totalProgress = 0.1 + (imageProgress * 0.7); // 10% ~ 80%
          onProgress?.call(totalProgress, currentPageMsg);
        },
      );

      // 3. PDF 문서 생성
      onProgress?.call(0.8, 'PDF 문서 생성 중...');
      final pdf = pw.Document(
        title: note.title,
        creator: _pdfCreator,
        subject: _pdfSubject,
        keywords: 'handwritten, note, export',
        producer: _pdfCreator,
      );

      // 4. 페이지별 PDF 페이지 추가
      for (int i = 0; i < pageImages.length; i++) {
        final pageImage = pageImages[i];
        final originalPage = pagesToExport[i];

        debugPrint(
          '${'-' * 10} Adding Page ${originalPage.pageNumber} to PDF ${'-' * 10}',
        );
        try {
          final codec = await ui.instantiateImageCodec(pageImage);
          final frame = await codec.getNextFrame();
          debugPrint(
            '  - Pre-add Sanity Check: Page image is valid (${frame.image.width}x${frame.image.height})',
          );
          frame.image.dispose();
        } catch (e) {
          debugPrint(
            '  - 🚨 Pre-add Sanity Check FAILED: Page image is invalid! Error: $e',
          );
        }

        // 캔버스 크기를 PDF 포인트 단위로 변환 (1픽셀 = 0.75포인트)
        final pageWidthPoints = originalPage.drawingAreaWidth * 0.75;
        final pageHeightPoints = originalPage.drawingAreaHeight * 0.75;
        debugPrint(
          '  - PDF Page Dimensions: ${pageWidthPoints.toStringAsFixed(2)}x${pageHeightPoints.toStringAsFixed(2)} pt',
        );

        try {
          pdf.addPage(
            createPdfPage(
              pageImage,
              pageWidth: pageWidthPoints,
              pageHeight: pageHeightPoints,
              pageNumber: originalPage.pageNumber,
            ),
          );
        } catch (e) {
          debugPrint('  - ❌ pdf.addPage() FAILED. Error: $e');
        }

        final pageProgress = 0.8 + ((i + 1) / pageImages.length * 0.15);
        onProgress?.call(
          pageProgress,
          'PDF 페이지 추가 중... (${i + 1}/${pageImages.length})',
        );
      }

      // 5. PDF 바이트 배열 생성
      onProgress?.call(0.95, 'PDF 파일 생성 중...');
      final pdfBytes = await pdf.save();

      debugPrint('  - Final PDF Size: ${pdfBytes.length} bytes');
      onProgress?.call(1.0, 'PDF 내보내기 완료!');
      debugPrint('✅ PDF 내보내기 완료: ${pdfBytes.length} bytes');

      return pdfBytes;
    } catch (e) {
      debugPrint('❌ PDF 내보내기 실패: ${note.title} - $e');
      onProgress?.call(0.0, 'PDF 내보내기 실패: $e');
      rethrow;
    }
  }

  /// PDF 파일을 임시 디렉토리에 저장합니다.
  ///
  /// [pdfBytes]: PDF 파일 바이트 배열
  /// [fileName]: 저장할 파일명 (확장자 제외)
  ///
  /// Returns: 저장된 파일의 전체 경로
  static Future<String> savePdfToTemporary(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      debugPrint('💾 PDF 임시 파일 저장 시작: $fileName');

      // 임시 디렉토리 사용
      final directory = await getTemporaryDirectory();
      final filePath = path.join(directory.path, '$fileName.pdf');

      // 파일 저장
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      debugPrint('✅ PDF 임시 파일 저장 완료: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ PDF 임시 파일 저장 실패: $fileName - $e');
      rethrow;
    }
  }

  /// PDF 파일을 사용자가 선택한 위치에 저장합니다.
  ///
  /// [pdfBytes]: PDF 파일 바이트 배열
  /// [defaultFileName]: 기본 파일명 (확장자 포함)
  ///
  /// Returns: 저장된 파일의 전체 경로 또는 null (취소시)
  static Future<String?> savePdfToUserLocation(
    Uint8List pdfBytes,
    String defaultFileName,
  ) async {
    try {
      debugPrint('📁 사용자 선택 PDF 저장 시작: $defaultFileName');

      // 사용자에게 저장 위치 선택 요청
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'PDF 저장 위치를 선택하세요',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: pdfBytes, // Android/iOS에서 필수
        lockParentWindow: true,
      );

      if (outputPath == null) {
        debugPrint('ℹ️ 사용자가 PDF 저장을 취소했습니다');
        return null;
      }

      debugPrint('✅ 사용자 선택 PDF 저장 완료: $outputPath');
      return outputPath;
    } catch (e) {
      debugPrint('❌ 사용자 선택 PDF 저장 실패: $defaultFileName - $e');
      rethrow;
    }
  }

  /// PDF 파일을 공유합니다.
  ///
  /// [filePath]: 공유할 PDF 파일 경로
  /// [shareText]: 공유 시 함께 전송할 텍스트 (선택적)
  static Future<void> sharePdf(
    String filePath, {
    String? shareText,
  }) async {
    try {
      debugPrint('📤 PDF 파일 공유 시작: $filePath');

      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('공유할 PDF 파일이 존재하지 않습니다: $filePath');
      }

      await Share.shareXFiles(
        [XFile(filePath)],
        text: shareText ?? 'It Contest 노트를 공유합니다.',
        subject: 'It Contest Note PDF',
      );

      debugPrint('✅ PDF 파일 공유 완료');
    } catch (e) {
      debugPrint('❌ PDF 파일 공유 실패: $filePath - $e');
      rethrow;
    }
  }

  /// 임시 PDF 파일을 생성하고 공유한 후 정리합니다.
  ///
  /// [note]: 내보낼 노트
  /// [pageNotifiers]: 페이지별 ScribbleNotifier 맵
  /// [options]: 내보내기 옵션
  ///
  /// Returns: 내보내기 결과 정보
  static Future<PdfExportResult> exportAndShare(
    NoteModel note,
    Map<String, ScribbleNotifier> pageNotifiers, {
    PdfExportOptions? options,
  }) async {
    final exportOptions = options ?? const PdfExportOptions();
    final startTime = DateTime.now();

    try {
      debugPrint('🚀 PDF 내보내기 및 공유 시작: ${note.title}');

      // 1. PDF 생성
      final pdfBytes = await exportNoteToPdf(
        note,
        pageNotifiers,
        quality: exportOptions.quality,
        pageRange: exportOptions.pageRange,
        onProgress: exportOptions.onProgress,
      );

      // 2. 임시 파일로 저장
      final fileName = _generateFileName(note.title, exportOptions.quality);
      final filePath = await savePdfToTemporary(pdfBytes, fileName);

      // 3. 파일 공유
      if (exportOptions.autoShare) {
        await sharePdf(filePath, shareText: exportOptions.shareText);

        // 공유 후 임시 파일 삭제
        try {
          final tempFile = File(filePath);
          if (tempFile.existsSync()) {
            await tempFile.delete();
            debugPrint('🗑️ 임시 PDF 파일 삭제 완료: $filePath');
          }
        } catch (e) {
          debugPrint('⚠️ 임시 PDF 파일 삭제 실패: $e');
          // 삭제 실패는 치명적이지 않으므로 계속 진행
        }
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final result = PdfExportResult(
        success: true,
        filePath: exportOptions.autoShare ? null : filePath, // 공유 시에는 경로 제거
        fileSize: pdfBytes.length,
        pageCount: note.pages.length,
        duration: duration,
        quality: exportOptions.quality,
      );

      debugPrint('✅ PDF 내보내기 및 공유 완료: ${result.toString()}');
      return result;
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final result = PdfExportResult(
        success: false,
        error: e.toString(),
        pageCount: note.pages.length,
        duration: duration,
        quality: exportOptions.quality,
      );

      debugPrint('❌ PDF 내보내기 및 공유 실패: ${result.toString()}');
      return result;
    }
  }

  /// 노트를 PDF로 내보내고 사용자가 선택한 위치에 저장합니다.
  ///
  /// [note]: 내보낼 노트
  /// [pageNotifiers]: 페이지별 ScribbleNotifier 맵
  /// [options]: 내보내기 옵션
  ///
  /// Returns: 내보내기 결과 정보
  static Future<PdfExportResult> exportAndSave(
    NoteModel note,
    Map<String, ScribbleNotifier> pageNotifiers, {
    PdfExportOptions? options,
  }) async {
    final exportOptions = options ?? const PdfExportOptions();
    final startTime = DateTime.now();

    try {
      debugPrint('💾 PDF 내보내기 및 저장 시작: ${note.title}');

      // 1. PDF 생성
      final pdfBytes = await exportNoteToPdf(
        note,
        pageNotifiers,
        quality: exportOptions.quality,
        pageRange: exportOptions.pageRange,
        onProgress: exportOptions.onProgress,
      );

      // 2. 사용자 선택 위치에 저장
      final defaultFileName = '${_cleanFileName(note.title)}.pdf';
      final savedPath = await savePdfToUserLocation(pdfBytes, defaultFileName);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      if (savedPath != null) {
        final result = PdfExportResult(
          success: true,
          filePath: savedPath,
          fileSize: pdfBytes.length,
          pageCount: note.pages.length,
          duration: duration,
          quality: exportOptions.quality,
        );

        debugPrint('✅ PDF 내보내기 및 저장 완료: ${result.toString()}');
        return result;
      } else {
        // 사용자가 저장을 취소한 경우
        final result = PdfExportResult(
          success: false,
          error: '사용자가 저장을 취소했습니다.',
          pageCount: note.pages.length,
          duration: duration,
          quality: exportOptions.quality,
        );

        debugPrint('ℹ️ PDF 저장 취소: ${result.toString()}');
        return result;
      }
    } catch (e) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final result = PdfExportResult(
        success: false,
        error: e.toString(),
        pageCount: note.pages.length,
        duration: duration,
        quality: exportOptions.quality,
      );

      debugPrint('❌ PDF 내보내기 및 저장 실패: ${result.toString()}');
      return result;
    }
  }

  // ========================================================================
  // Private Helper Methods
  // ========================================================================

  /// 페이지 범위에 따라 내보낼 페이지를 필터링합니다.
  static List<NotePageModel> _filterPagesForExport(
    List<NotePageModel> allPages,
    ExportPageRange? pageRange,
  ) {
    if (pageRange == null || pageRange.type == ExportRangeType.all) {
      return allPages;
    }

    switch (pageRange.type) {
      case ExportRangeType.current:
        if (pageRange.currentPageIndex != null &&
            pageRange.currentPageIndex! >= 0 &&
            pageRange.currentPageIndex! < allPages.length) {
          return [allPages[pageRange.currentPageIndex!]];
        }
        return allPages;

      case ExportRangeType.range:
        final startIndex = (pageRange.startPage ?? 1) - 1;
        final endIndex = (pageRange.endPage ?? allPages.length) - 1;

        if (startIndex >= 0 &&
            endIndex < allPages.length &&
            startIndex <= endIndex) {
          return allPages.sublist(startIndex, endIndex + 1);
        }
        return allPages;

      case ExportRangeType.all:
      default:
        return allPages;
    }
  }

  /// 파일명을 생성합니다.
  static String _generateFileName(String noteTitle, ExportQuality quality) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qualitySuffix = quality == ExportQuality.ultra
        ? '_ultra'
        : quality == ExportQuality.high
        ? '_high'
        : '';

    final cleanTitle = _cleanFileName(noteTitle);
    return '${cleanTitle}_$timestamp$qualitySuffix';
  }

  /// 파일명에 사용할 수 없는 문자를 제거합니다.
  static String _cleanFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

// ========================================================================
// Supporting Classes and Enums
// ========================================================================

/// PDF 내보내기 품질 옵션
enum ExportQuality {
  standard('표준 화질', '빠른 처리, 작은 파일 크기'),
  high('고화질', '균형 잡힌 품질과 성능'),
  ultra('최고화질', '최고 품질, 큰 파일 크기');

  const ExportQuality(this.displayName, this.description);

  final String displayName;
  final String description;
}

/// 페이지 범위 타입
enum ExportRangeType {
  all,
  current,
  range,
}

/// 페이지 범위 설정
class ExportPageRange {
  const ExportPageRange({
    required this.type,
    this.currentPageIndex,
    this.startPage,
    this.endPage,
  });

  const ExportPageRange.all() : this(type: ExportRangeType.all);

  const ExportPageRange.current(int pageIndex)
    : this(type: ExportRangeType.current, currentPageIndex: pageIndex);

  const ExportPageRange.range(int start, int end)
    : this(type: ExportRangeType.range, startPage: start, endPage: end);

  final ExportRangeType type;
  final int? currentPageIndex;
  final int? startPage;
  final int? endPage;
}

/// PDF 내보내기 옵션
class PdfExportOptions {
  const PdfExportOptions({
    this.quality = ExportQuality.high,
    this.pageRange,
    this.autoShare = true,
    this.shareText,
    this.onProgress,
  });

  final ExportQuality quality;
  final ExportPageRange? pageRange;
  final bool autoShare;
  final String? shareText;
  final void Function(double progress, String message)? onProgress;
}

/// PDF 내보내기 결과
class PdfExportResult {
  const PdfExportResult({
    required this.success,
    this.filePath,
    this.fileSize,
    required this.pageCount,
    required this.duration,
    required this.quality,
    this.error,
  });

  final bool success;
  final String? filePath;
  final int? fileSize;
  final int pageCount;
  final Duration duration;
  final ExportQuality quality;
  final String? error;

  @override
  String toString() {
    if (success) {
      return 'PdfExportResult(성공: $pageCount페이지, '
          '크기: ${(fileSize! / 1024 / 1024).toStringAsFixed(2)}MB, '
          '소요시간: ${duration.inSeconds}초, 품질: ${quality.displayName})';
    } else {
      return 'PdfExportResult(실패: $error, 소요시간: ${duration.inSeconds}초)';
    }
  }
}
