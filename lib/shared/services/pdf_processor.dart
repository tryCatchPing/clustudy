import 'dart:io';
import 'dart:ui';
import 'dart:developer' as developer;

import 'package:it_contest/shared/services/file_picker_service.dart';
import 'package:it_contest/shared/services/file_storage_service.dart';
import 'package:it_contest/shared/services/pdf_processed_data.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

/// PDF 문서 전용 처리기
///
/// PDF 선택, 분석, 렌더링, 파일 복사를 통합 처리합니다.
/// 효율성을 위해 PDF 문서를 한 번만 열어서 모든 작업을 수행합니다.
class PdfProcessor {
  static const _uuid = Uuid();

  /// 표준 캔버스 크기 (긴 변 기준)
  static const double TARGET_LONG_EDGE = 2000.0;

  /// PDF 페이지 크기를 표준 크기로 정규화
  /// 종횡비를 유지하면서 긴 변을 TARGET_LONG_EDGE로 맞춤
  static Size _normalizePageSize(double originalWidth, double originalHeight) {
    final aspectRatio = originalWidth / originalHeight;

    if (originalWidth >= originalHeight) {
      // 가로가 더 긴 경우
      return Size(TARGET_LONG_EDGE, TARGET_LONG_EDGE / aspectRatio);
    } else {
      // 세로가 더 긴 경우
      return Size(TARGET_LONG_EDGE * aspectRatio, TARGET_LONG_EDGE);
    }
  }

  /// PDF 파일 선택부터 전체 처리까지 원스톱 처리
  ///
  /// Returns: 처리된 PDF 데이터 또는 null (선택 취소/실패시)
  static Future<PdfProcessedData?> processFromSelection() async {
    try {
      // 1. PDF 파일 선택
      final sourcePdfPath = await FilePickerService.pickPdfFile();
      if (sourcePdfPath == null) {
        developer.log('ℹ️ PDF 파일 선택 취소', name: 'PdfProcessor');
        return null;
      }

      developer.log('📁 선택된 PDF: $sourcePdfPath', name: 'PdfProcessor');

      // 2. 고유 ID 생성
      final noteId = _uuid.v4();

      // 3. PDF 문서 전체 처리 (한 번의 문서 열기로 모든 작업)
      return await _processDocument(
        sourcePdfPath: sourcePdfPath,
        noteId: noteId,
      );
    } on Exception catch (e, stack) {
      developer.log('❌ PDF 처리 실패', name: 'PdfProcessor', error: e, stackTrace: stack);
      return null;
    }
  }

  /// PDF 문서 통합 처리 (메타데이터 수집 + 렌더링 + 파일 복사)
  static Future<PdfProcessedData> _processDocument({
    required String sourcePdfPath,
    required String noteId,
  }) async {
    // PDF 문서 열기 (한 번만)
    final document = await PdfDocument.openFile(sourcePdfPath);
    final totalPages = document.pagesCount;

    developer.log('📄 PDF 총 페이지 수: $totalPages', name: 'PdfProcessor');

    if (totalPages == 0) {
      await document.close();
      throw Exception('PDF에 페이지가 없습니다.');
    }

    // 제목 추출
    final extractedTitle = _extractTitleFromPath(sourcePdfPath);

    // 디렉토리 구조 생성
    await FileStorageService.ensureDirectoryStructure(noteId);
    final pageImagesDir = await FileStorageService.getPageImagesDirectoryPath(
      noteId,
    );

    // 페이지별 처리 (메타데이터 수집 + 렌더링)
    final pages = <PdfPageData>[];

    for (int pageNumber = 1; pageNumber <= totalPages; pageNumber++) {
      developer.log('🎨 페이지 $pageNumber 처리 중...', name: 'PdfProcessor');

      final pdfPage = await document.getPage(pageNumber);

      // 1. 원본 크기 및 정규화된 크기 계산
      final originalWidth = pdfPage.width;
      final originalHeight = pdfPage.height;
      final normalizedSize = _normalizePageSize(originalWidth, originalHeight);

      developer.log(
        '📏 페이지 $pageNumber: 원본 ${originalWidth.toInt()}x${originalHeight.toInt()} → 정규화 ${normalizedSize.width.toInt()}x${normalizedSize.height.toInt()}',
        name: 'PdfProcessor',
      );

      // 2. 이미지 렌더링 (정규화된 크기로)
      String? preRenderedImagePath;
      try {
        final pageImage = await pdfPage.render(
          width: normalizedSize.width,
          height: normalizedSize.height,
          format: PdfPageImageFormat.jpeg,
        );

        if (pageImage?.bytes != null) {
          // 3. 이미지 파일 저장
          final imageFileName = 'page_$pageNumber.jpg';
          final imagePath = path.join(pageImagesDir, imageFileName);
          final imageFile = File(imagePath);

          await imageFile.writeAsBytes(pageImage!.bytes);
          preRenderedImagePath = imagePath;

          developer.log('✅ 페이지 $pageNumber 렌더링 완료', name: 'PdfProcessor');
        } else {
          developer.log('⚠️ 페이지 $pageNumber 렌더링 실패', name: 'PdfProcessor');
        }
      } on Exception catch (e, stack) {
        developer.log('❌ 페이지 $pageNumber 렌더링 오류', name: 'PdfProcessor', error: e, stackTrace: stack);
      }

      // 4. 페이지 데이터 생성 (정규화된 크기 사용)
      pages.add(
        PdfPageData(
          pageNumber: pageNumber,
          width: normalizedSize.width,
          height: normalizedSize.height,
          preRenderedImagePath: preRenderedImagePath,
        ),
      );

      await pdfPage.close();
    }

    // PDF 문서 닫기
    await document.close();

    // PDF 파일을 앱 내부로 복사
    final internalPdfPath = await FileStorageService.copyPdfToAppStorage(
      sourcePdfPath: sourcePdfPath,
      noteId: noteId,
    );

    developer.log('✅ PDF 처리 완료: $extractedTitle (${pages.length}페이지)', name: 'PdfProcessor');

    return PdfProcessedData(
      noteId: noteId,
      internalPdfPath: internalPdfPath,
      extractedTitle: extractedTitle,
      totalPages: totalPages,
      pages: pages,
    );
  }

  /// 파일 경로에서 제목을 추출합니다
  static String _extractTitleFromPath(String filePath) {
    final fileName = path.basename(filePath);
    final nameWithoutExtension = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;

    if (nameWithoutExtension.isEmpty) {
      return 'PDF 노트 ${DateTime.now().toString().substring(0, 16)}';
    }

    return nameWithoutExtension;
  }
}
