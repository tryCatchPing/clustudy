import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// 앱 내부 파일 시스템을 관리하는 서비스
///
/// PDF 파일 복사, 이미지 사전 렌더링, 파일 정리 등을 담당합니다.
/// 파일 구조:
/// ```
/// /Application Documents/
/// ├── notes/
/// │   ├── {noteId}/
/// │   │   ├── source.pdf          # 원본 PDF 복사본
/// │   │   ├── pages/
/// │   │   │   ├── page_1.jpg      # 사전 렌더링된 이미지
/// │   │   │   ├── page_2.jpg
/// │   │   │   └── ...
/// │   │   ├── sketches/
/// │   │   │   ├── page_1.json     # 스케치 데이터 (향후 구현)
/// │   │   │   └── ...
/// │   │   └── metadata.json       # 노트 메타데이터 (향후 구현)
/// ```
class FileStorageService {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  FileStorageService._();

  static const String _notesDirectoryName = 'notes';
  static const String _pagesDirectoryName = 'pages';
  static const String _sketchesDirectoryName = 'sketches';
  static const String _sourcePdfFileName = 'source.pdf';

  /// 앱의 Documents 디렉토리 경로를 가져옵니다
  static Future<String> get _documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// 노트 폴더의 루트 경로를 가져옵니다
  static Future<String> get _notesRootPath async {
    final documentsPath = await _documentsPath;
    return path.join(documentsPath, _notesDirectoryName);
  }

  /// 특정 노트의 디렉토리 경로를 가져옵니다
  static Future<String> _getNoteDirectoryPath(String noteId) async {
    final notesRootPath = await _notesRootPath;
    return path.join(notesRootPath, noteId);
  }

  /// 특정 노트의 페이지 이미지 디렉토리 경로를 가져옵니다
  static Future<String> _getPageImagesDirectoryPath(String noteId) async {
    final noteDir = await _getNoteDirectoryPath(noteId);
    return path.join(noteDir, _pagesDirectoryName);
  }

  /// 필요한 디렉토리 구조를 생성합니다
  static Future<void> _ensureDirectoryStructure(String noteId) async {
    final noteDir = await _getNoteDirectoryPath(noteId);
    final pagesDir = await _getPageImagesDirectoryPath(noteId);
    final sketchesDir = path.join(noteDir, _sketchesDirectoryName);

    await Directory(noteDir).create(recursive: true);
    await Directory(pagesDir).create(recursive: true);
    await Directory(sketchesDir).create(recursive: true);

    print('📁 노트 디렉토리 구조 생성 완료: $noteId');
  }

  /// PDF 파일을 앱 내부로 복사합니다
  ///
  /// [sourcePdfPath]: 원본 PDF 파일 경로
  /// [noteId]: 노트 고유 ID
  /// 
  /// Returns: 복사된 PDF 파일의 앱 내부 경로
  static Future<String> copyPdfToAppStorage({
    required String sourcePdfPath,
    required String noteId,
  }) async {
    try {
      print('📋 PDF 파일 복사 시작: $sourcePdfPath -> $noteId');

      // 디렉토리 구조 생성
      await _ensureDirectoryStructure(noteId);

      // 원본 파일 확인
      final sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) {
        throw Exception('원본 PDF 파일을 찾을 수 없습니다: $sourcePdfPath');
      }

      // 대상 경로 설정
      final noteDir = await _getNoteDirectoryPath(noteId);
      final targetPath = path.join(noteDir, _sourcePdfFileName);

      // 파일 복사
      final targetFile = await sourceFile.copy(targetPath);
      
      print('✅ PDF 파일 복사 완료: $targetPath');
      return targetFile.path;
    } catch (e) {
      print('❌ PDF 파일 복사 실패: $e');
      rethrow;
    }
  }

  /// PDF의 모든 페이지를 이미지로 사전 렌더링합니다
  ///
  /// [pdfPath]: PDF 파일 경로 (앱 내부)
  /// [noteId]: 노트 고유 ID
  /// [scaleFactor]: 렌더링 배율 (기본값: 3.0)
  /// 
  /// Returns: 생성된 이미지 파일 경로들의 리스트
  static Future<List<String>> preRenderPdfPages({
    required String pdfPath,
    required String noteId,
    double scaleFactor = 3.0,
  }) async {
    try {
      print('🎨 PDF 페이지 사전 렌더링 시작: $noteId');

      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('PDF 파일을 찾을 수 없습니다: $pdfPath');
      }

      // PDF 문서 열기
      final document = await PdfDocument.openFile(pdfPath);
      final totalPages = document.pagesCount;
      final pageImagesDir = await _getPageImagesDirectoryPath(noteId);
      
      print('📄 렌더링할 페이지 수: $totalPages');

      final renderedImagePaths = <String>[];

      // 각 페이지를 이미지로 렌더링
      for (int pageNumber = 1; pageNumber <= totalPages; pageNumber++) {
        print('🎨 페이지 $pageNumber 렌더링 중...');

        final pdfPage = await document.getPage(pageNumber);
        
        // 고해상도로 렌더링
        final pageImage = await pdfPage.render(
          width: pdfPage.width * scaleFactor,
          height: pdfPage.height * scaleFactor,
          format: PdfPageImageFormat.jpeg,
        );

        if (pageImage?.bytes != null) {
          // 이미지 파일로 저장
          final imageFileName = 'page_$pageNumber.jpg';
          final imagePath = path.join(pageImagesDir, imageFileName);
          final imageFile = File(imagePath);
          
          await imageFile.writeAsBytes(pageImage!.bytes);
          renderedImagePaths.add(imagePath);
          
          print('✅ 페이지 $pageNumber 렌더링 완료: $imagePath');
        } else {
          print('⚠️ 페이지 $pageNumber 렌더링 실패');
        }

        await pdfPage.close();
      }

      await document.close();
      
      print('✅ 모든 페이지 렌더링 완료: ${renderedImagePaths.length}개');
      return renderedImagePaths;
    } catch (e) {
      print('❌ PDF 페이지 렌더링 실패: $e');
      rethrow;
    }
  }

  /// 특정 노트의 모든 파일을 삭제합니다
  ///
  /// [noteId]: 삭제할 노트의 고유 ID
  static Future<void> deleteNoteFiles(String noteId) async {
    try {
      print('🗑️ 노트 파일 삭제 시작: $noteId');

      final noteDir = await _getNoteDirectoryPath(noteId);
      final directory = Directory(noteDir);

      if (await directory.exists()) {
        await directory.delete(recursive: true);
        print('✅ 노트 파일 삭제 완료: $noteId');
      } else {
        print('ℹ️ 삭제할 노트 디렉토리가 존재하지 않음: $noteId');
      }
    } catch (e) {
      print('❌ 노트 파일 삭제 실패: $e');
      rethrow;
    }
  }

  /// 특정 페이지의 렌더링된 이미지 경로를 가져옵니다
  ///
  /// [noteId]: 노트 고유 ID
  /// [pageNumber]: 페이지 번호 (1부터 시작)
  /// 
  /// Returns: 이미지 파일 경로 (파일이 존재하지 않으면 null)
  static Future<String?> getPageImagePath({
    required String noteId,
    required int pageNumber,
  }) async {
    try {
      final pageImagesDir = await _getPageImagesDirectoryPath(noteId);
      final imageFileName = 'page_$pageNumber.jpg';
      final imagePath = path.join(pageImagesDir, imageFileName);
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        return imagePath;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ 페이지 이미지 경로 확인 실패: $e');
      return null;
    }
  }

  /// 노트의 PDF 파일 경로를 가져옵니다
  ///
  /// [noteId]: 노트 고유 ID
  /// 
  /// Returns: PDF 파일 경로 (파일이 존재하지 않으면 null)
  static Future<String?> getNotesPdfPath(String noteId) async {
    try {
      final noteDir = await _getNoteDirectoryPath(noteId);
      final pdfPath = path.join(noteDir, _sourcePdfFileName);
      final pdfFile = File(pdfPath);

      if (await pdfFile.exists()) {
        return pdfPath;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ 노트 PDF 경로 확인 실패: $e');
      return null;
    }
  }

  /// 저장 공간 사용량 정보를 가져옵니다
  static Future<StorageInfo> getStorageInfo() async {
    try {
      final notesRootDir = Directory(await _notesRootPath);
      
      if (!await notesRootDir.exists()) {
        return StorageInfo(
          totalNotes: 0,
          totalSizeBytes: 0,
          pdfSizeBytes: 0,
          imagesSizeBytes: 0,
        );
      }

      int totalNotes = 0;
      int totalSizeBytes = 0;
      int pdfSizeBytes = 0;
      int imagesSizeBytes = 0;

      await for (final entity in notesRootDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileSize = stat.size;
          totalSizeBytes += fileSize;

          final fileName = path.basename(entity.path);
          if (fileName == _sourcePdfFileName) {
            pdfSizeBytes += fileSize;
          } else if (fileName.endsWith('.jpg')) {
            imagesSizeBytes += fileSize;
          }
        } else if (entity is Directory) {
          final dirName = path.basename(entity.path);
          // 노트 ID 패턴인지 확인 (향후 더 정교한 검증 가능)
          if (!dirName.startsWith('.') && 
              !['pages', 'sketches'].contains(dirName)) {
            totalNotes++;
          }
        }
      }

      return StorageInfo(
        totalNotes: totalNotes,
        totalSizeBytes: totalSizeBytes,
        pdfSizeBytes: pdfSizeBytes,
        imagesSizeBytes: imagesSizeBytes,
      );
    } catch (e) {
      print('❌ 저장 공간 정보 확인 실패: $e');
      return StorageInfo(
        totalNotes: 0,
        totalSizeBytes: 0,
        pdfSizeBytes: 0,
        imagesSizeBytes: 0,
      );
    }
  }

  /// 전체 노트 저장소를 정리합니다 (개발/디버깅 용도)
  static Future<void> cleanupAllNotes() async {
    try {
      print('🧹 전체 노트 저장소 정리 시작...');

      final notesRootDir = Directory(await _notesRootPath);
      
      if (await notesRootDir.exists()) {
        await notesRootDir.delete(recursive: true);
        print('✅ 전체 노트 저장소 정리 완료');
      } else {
        print('ℹ️ 정리할 노트 저장소가 존재하지 않음');
      }
    } catch (e) {
      print('❌ 노트 저장소 정리 실패: $e');
      rethrow;
    }
  }
}

/// 저장 공간 사용량 정보
class StorageInfo {
  const StorageInfo({
    required this.totalNotes,
    required this.totalSizeBytes,
    required this.pdfSizeBytes,
    required this.imagesSizeBytes,
  });

  final int totalNotes;
  final int totalSizeBytes;
  final int pdfSizeBytes;
  final int imagesSizeBytes;

  double get totalSizeMB => totalSizeBytes / (1024 * 1024);
  double get pdfSizeMB => pdfSizeBytes / (1024 * 1024);
  double get imagesSizeMB => imagesSizeBytes / (1024 * 1024);

  @override
  String toString() {
    return 'StorageInfo('
        'totalNotes: $totalNotes, '
        'totalSize: ${totalSizeMB.toStringAsFixed(2)}MB, '
        'pdfSize: ${pdfSizeMB.toStringAsFixed(2)}MB, '
        'imagesSize: ${imagesSizeMB.toStringAsFixed(2)}MB'
        ')';
  }
}