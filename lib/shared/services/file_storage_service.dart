import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// 앱 내부 파일 시스템을 관리하는 서비스
///
/// PDF 파일 복사, 이미지 사전 렌더링, 썸네일 캐시 관리 등을 담당합니다.
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
/// │   │   ├── thumbnails/
/// │   │   │   ├── thumb_{pageId}.jpg  # 페이지 썸네일 캐시
/// │   │   │   └── ...
/// │   │   └── metadata.json       # 노트 메타데이터 (향후 구현)
/// ```
class FileStorageService {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  FileStorageService._();

  static const String _notesDirectoryName = 'notes';
  static const String _pagesDirectoryName = 'pages';
  static const String _sketchesDirectoryName = 'sketches';
  static const String _thumbnailsDirectoryName = 'thumbnails';
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
  static Future<String> getPageImagesDirectoryPath(String noteId) async {
    final noteDir = await _getNoteDirectoryPath(noteId);
    return path.join(noteDir, _pagesDirectoryName);
  }

  /// 특정 노트의 썸네일 캐시 디렉토리 경로를 가져옵니다
  static Future<String> getThumbnailCacheDirectoryPath(String noteId) async {
    final noteDir = await _getNoteDirectoryPath(noteId);
    return path.join(noteDir, _thumbnailsDirectoryName);
  }

  /// 필요한 디렉토리 구조를 생성합니다
  static Future<void> ensureDirectoryStructure(String noteId) async {
    final noteDir = await _getNoteDirectoryPath(noteId);
    final pagesDir = await getPageImagesDirectoryPath(noteId);
    final sketchesDir = path.join(noteDir, _sketchesDirectoryName);
    final thumbnailsDir = await getThumbnailCacheDirectoryPath(noteId);

    await Directory(noteDir).create(recursive: true);
    await Directory(pagesDir).create(recursive: true);
    await Directory(sketchesDir).create(recursive: true);
    await Directory(thumbnailsDir).create(recursive: true);

    debugPrint('📁 노트 디렉토리 구조 생성 완료: $noteId');
  }

  /// 썸네일 캐시 디렉토리를 생성합니다
  static Future<void> ensureThumbnailCacheDirectory(String noteId) async {
    final thumbnailsDir = await getThumbnailCacheDirectoryPath(noteId);
    await Directory(thumbnailsDir).create(recursive: true);
    debugPrint('📁 썸네일 캐시 디렉토리 생성 완료: $noteId');
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
      debugPrint('📋 PDF 파일 복사 시작: $sourcePdfPath -> $noteId');

      // 디렉토리 구조 생성
      await ensureDirectoryStructure(noteId);

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

      debugPrint('✅ PDF 파일 복사 완료: $targetPath');
      return targetFile.path;
    } catch (e) {
      debugPrint('❌ PDF 파일 복사 실패: $e');
      rethrow;
    }
  }

  /// 특정 노트의 모든 파일을 삭제합니다
  ///
  /// [noteId]: 삭제할 노트의 고유 ID
  static Future<void> deleteNoteFiles(String noteId) async {
    try {
      debugPrint('🗑️ 노트 파일 삭제 시작: $noteId');

      final noteDir = await _getNoteDirectoryPath(noteId);
      final directory = Directory(noteDir);

      if (await directory.exists()) {
        await directory.delete(recursive: true);
        debugPrint('✅ 노트 파일 삭제 완료: $noteId');
      } else {
        debugPrint('ℹ️ 삭제할 노트 디렉토리가 존재하지 않음: $noteId');
      }
    } catch (e) {
      debugPrint('❌ 노트 파일 삭제 실패: $e');
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
      final pageImagesDir = await getPageImagesDirectoryPath(noteId);
      final imageFileName = 'page_$pageNumber.jpg';
      final imagePath = path.join(pageImagesDir, imageFileName);
      final imageFile = File(imagePath);

      if (await imageFile.exists()) {
        return imagePath;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ 페이지 이미지 경로 확인 실패: $e');
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
      debugPrint('❌ 노트 PDF 경로 확인 실패: $e');
      return null;
    }
  }

  /// 특정 페이지의 썸네일 파일 경로를 생성합니다
  ///
  /// [noteId]: 노트 고유 ID
  /// [pageId]: 페이지 고유 ID
  ///
  /// Returns: 썸네일 파일 경로
  static Future<String> getThumbnailPath({
    required String noteId,
    required String pageId,
  }) async {
    final thumbnailsDir = await getThumbnailCacheDirectoryPath(noteId);
    final thumbnailFileName = 'thumb_$pageId.jpg';
    return path.join(thumbnailsDir, thumbnailFileName);
  }

  /// 특정 페이지의 썸네일 파일이 존재하는지 확인합니다
  ///
  /// [noteId]: 노트 고유 ID
  /// [pageId]: 페이지 고유 ID
  ///
  /// Returns: 썸네일 파일 경로 (파일이 존재하지 않으면 null)
  static Future<String?> getExistingThumbnailPath({
    required String noteId,
    required String pageId,
  }) async {
    try {
      final thumbnailPath = await getThumbnailPath(
        noteId: noteId,
        pageId: pageId,
      );
      final thumbnailFile = File(thumbnailPath);

      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('❌ 썸네일 파일 경로 확인 실패: $e');
      return null;
    }
  }

  /// 특정 노트의 썸네일 캐시를 정리합니다
  ///
  /// [noteId]: 정리할 노트의 고유 ID
  static Future<void> clearThumbnailCache(String noteId) async {
    try {
      debugPrint('🧹 썸네일 캐시 정리 시작: $noteId');

      final thumbnailsDir = Directory(
        await getThumbnailCacheDirectoryPath(noteId),
      );

      if (await thumbnailsDir.exists()) {
        await thumbnailsDir.delete(recursive: true);
        debugPrint('✅ 썸네일 캐시 정리 완료: $noteId');
      } else {
        debugPrint('ℹ️ 정리할 썸네일 캐시가 존재하지 않음: $noteId');
      }
    } catch (e) {
      debugPrint('❌ 썸네일 캐시 정리 실패: $e');
      rethrow;
    }
  }

  /// 전체 썸네일 캐시를 정리합니다
  static Future<void> clearAllThumbnailCache() async {
    try {
      debugPrint('🧹 전체 썸네일 캐시 정리 시작...');

      final notesRootDir = Directory(await _notesRootPath);

      if (await notesRootDir.exists()) {
        await for (final entity in notesRootDir.list()) {
          if (entity is Directory) {
            final noteId = path.basename(entity.path);
            final thumbnailsDir = Directory(
              await getThumbnailCacheDirectoryPath(noteId),
            );

            if (await thumbnailsDir.exists()) {
              await thumbnailsDir.delete(recursive: true);
              debugPrint('✅ 썸네일 캐시 정리 완료: $noteId');
            }
          }
        }
        debugPrint('✅ 전체 썸네일 캐시 정리 완료');
      } else {
        debugPrint('ℹ️ 정리할 노트 저장소가 존재하지 않음');
      }
    } catch (e) {
      debugPrint('❌ 전체 썸네일 캐시 정리 실패: $e');
      rethrow;
    }
  }

  /// 특정 페이지의 썸네일 캐시를 삭제합니다
  ///
  /// [noteId]: 노트 고유 ID
  /// [pageId]: 페이지 고유 ID
  static Future<void> deleteThumbnailCache({
    required String noteId,
    required String pageId,
  }) async {
    try {
      final thumbnailPath = await getThumbnailPath(
        noteId: noteId,
        pageId: pageId,
      );
      final thumbnailFile = File(thumbnailPath);

      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
        debugPrint('✅ 썸네일 캐시 삭제 완료: $pageId');
      } else {
        debugPrint('ℹ️ 삭제할 썸네일 캐시가 존재하지 않음: $pageId');
      }
    } catch (e) {
      debugPrint('❌ 썸네일 캐시 삭제 실패: $e');
      rethrow;
    }
  }

  /// 특정 노트의 썸네일 캐시 크기를 확인합니다
  ///
  /// [noteId]: 노트 고유 ID
  ///
  /// Returns: 썸네일 캐시 크기 정보
  static Future<ThumbnailCacheInfo> getThumbnailCacheInfo(String noteId) async {
    try {
      final thumbnailsDir = Directory(
        await getThumbnailCacheDirectoryPath(noteId),
      );

      if (!await thumbnailsDir.exists()) {
        return const ThumbnailCacheInfo(
          totalFiles: 0,
          totalSizeBytes: 0,
        );
      }

      int totalFiles = 0;
      int totalSizeBytes = 0;

      await for (final entity in thumbnailsDir.list()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          final stat = await entity.stat();
          totalFiles++;
          totalSizeBytes += stat.size;
        }
      }

      return ThumbnailCacheInfo(
        totalFiles: totalFiles,
        totalSizeBytes: totalSizeBytes,
      );
    } catch (e) {
      debugPrint('❌ 썸네일 캐시 정보 확인 실패: $e');
      return const ThumbnailCacheInfo(
        totalFiles: 0,
        totalSizeBytes: 0,
      );
    }
  }

  /// 오래된 썸네일 캐시를 정리합니다
  ///
  /// [maxAge]: 최대 보관 기간 (기본값: 30일)
  static Future<void> cleanupOldThumbnailCache({
    Duration maxAge = const Duration(days: 30),
  }) async {
    try {
      debugPrint('🧹 오래된 썸네일 캐시 정리 시작 (${maxAge.inDays}일 이상)...');

      final notesRootDir = Directory(await _notesRootPath);
      final cutoffTime = DateTime.now().subtract(maxAge);
      int deletedFiles = 0;

      if (await notesRootDir.exists()) {
        await for (final entity in notesRootDir.list()) {
          if (entity is Directory) {
            final noteId = path.basename(entity.path);
            final thumbnailsDir = Directory(
              await getThumbnailCacheDirectoryPath(noteId),
            );

            if (await thumbnailsDir.exists()) {
              await for (final thumbnailEntity in thumbnailsDir.list()) {
                if (thumbnailEntity is File &&
                    thumbnailEntity.path.endsWith('.jpg')) {
                  final stat = await thumbnailEntity.stat();
                  if (stat.accessed.isBefore(cutoffTime)) {
                    await thumbnailEntity.delete();
                    deletedFiles++;
                  }
                }
              }
            }
          }
        }
        debugPrint('✅ 오래된 썸네일 캐시 정리 완료 ($deletedFiles개 파일 삭제)');
      }
    } catch (e) {
      debugPrint('❌ 오래된 썸네일 캐시 정리 실패: $e');
      rethrow;
    }
  }

  /// 저장 공간 사용량 정보를 가져옵니다
  static Future<StorageInfo> getStorageInfo() async {
    try {
      final notesRootDir = Directory(await _notesRootPath);

      if (!await notesRootDir.exists()) {
        return const StorageInfo(
          totalNotes: 0,
          totalSizeBytes: 0,
          pdfSizeBytes: 0,
          imagesSizeBytes: 0,
          thumbnailsSizeBytes: 0,
        );
      }

      int totalNotes = 0;
      int totalSizeBytes = 0;
      int pdfSizeBytes = 0;
      int imagesSizeBytes = 0;
      int thumbnailsSizeBytes = 0;

      await for (final entity in notesRootDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final fileSize = stat.size;
          totalSizeBytes += fileSize;

          final fileName = path.basename(entity.path);
          final parentDirName = path.basename(path.dirname(entity.path));

          if (fileName == _sourcePdfFileName) {
            pdfSizeBytes += fileSize;
          } else if (fileName.endsWith('.jpg')) {
            if (parentDirName == _thumbnailsDirectoryName) {
              thumbnailsSizeBytes += fileSize;
            } else {
              imagesSizeBytes += fileSize;
            }
          }
        } else if (entity is Directory) {
          final dirName = path.basename(entity.path);
          // 노트 ID 패턴인지 확인 (향후 더 정교한 검증 가능)
          if (!dirName.startsWith('.') &&
              !['pages', 'sketches', 'thumbnails'].contains(dirName)) {
            totalNotes++;
          }
        }
      }

      return StorageInfo(
        totalNotes: totalNotes,
        totalSizeBytes: totalSizeBytes,
        pdfSizeBytes: pdfSizeBytes,
        imagesSizeBytes: imagesSizeBytes,
        thumbnailsSizeBytes: thumbnailsSizeBytes,
      );
    } catch (e) {
      debugPrint('❌ 저장 공간 정보 확인 실패: $e');
      return const StorageInfo(
        totalNotes: 0,
        totalSizeBytes: 0,
        pdfSizeBytes: 0,
        imagesSizeBytes: 0,
        thumbnailsSizeBytes: 0,
      );
    }
  }

  /// 전체 노트 저장소를 정리합니다 (개발/디버깅 용도)
  static Future<void> cleanupAllNotes() async {
    try {
      debugPrint('🧹 전체 노트 저장소 정리 시작...');

      final notesRootDir = Directory(await _notesRootPath);

      if (await notesRootDir.exists()) {
        await notesRootDir.delete(recursive: true);
        debugPrint('✅ 전체 노트 저장소 정리 완료');
      } else {
        debugPrint('ℹ️ 정리할 노트 저장소가 존재하지 않음');
      }
    } catch (e) {
      debugPrint('❌ 노트 저장소 정리 실패: $e');
      rethrow;
    }
  }
}

/// 저장 공간 사용량 정보를 나타내는 클래스입니다.
class StorageInfo {
  /// [StorageInfo]의 생성자.
  ///
  /// [totalNotes]는 총 노트 수입니다.
  /// [totalSizeBytes]는 전체 저장 공간 사용량(바이트)입니다.
  /// [pdfSizeBytes]는 PDF 파일이 차지하는 공간(바이트)입니다.
  /// [imagesSizeBytes]는 이미지 파일이 차지하는 공간(바이트)입니다.
  /// [thumbnailsSizeBytes]는 썸네일 파일이 차지하는 공간(바이트)입니다.
  const StorageInfo({
    required this.totalNotes,
    required this.totalSizeBytes,
    required this.pdfSizeBytes,
    required this.imagesSizeBytes,
    required this.thumbnailsSizeBytes,
  });

  /// 총 노트 수.
  final int totalNotes;

  /// 전체 저장 공간 사용량(바이트).
  final int totalSizeBytes;

  /// PDF 파일이 차지하는 공간(바이트).
  final int pdfSizeBytes;

  /// 이미지 파일이 차지하는 공간(바이트).
  final int imagesSizeBytes;

  /// 썸네일 파일이 차지하는 공간(바이트).
  final int thumbnailsSizeBytes;

  /// 전체 저장 공간 사용량(MB).
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  /// PDF 파일이 차지하는 공간(MB).
  double get pdfSizeMB => pdfSizeBytes / (1024 * 1024);

  /// 이미지 파일이 차지하는 공간(MB).
  double get imagesSizeMB => imagesSizeBytes / (1024 * 1024);

  /// 썸네일 파일이 차지하는 공간(MB).
  double get thumbnailsSizeMB => thumbnailsSizeBytes / (1024 * 1024);

  @override
  String toString() {
    return 'StorageInfo('
        'totalNotes: $totalNotes, '
        'totalSize: ${totalSizeMB.toStringAsFixed(2)}MB, '
        'pdfSize: ${pdfSizeMB.toStringAsFixed(2)}MB, '
        'imagesSize: ${imagesSizeMB.toStringAsFixed(2)}MB, '
        'thumbnailsSize: ${thumbnailsSizeMB.toStringAsFixed(2)}MB'
        ')';
  }
}

/// 썸네일 캐시 정보를 나타내는 클래스입니다.
class ThumbnailCacheInfo {
  /// [ThumbnailCacheInfo]의 생성자.
  ///
  /// [totalFiles]는 총 썸네일 파일 수입니다.
  /// [totalSizeBytes]는 썸네일 캐시가 차지하는 공간(바이트)입니다.
  const ThumbnailCacheInfo({
    required this.totalFiles,
    required this.totalSizeBytes,
  });

  /// 총 썸네일 파일 수.
  final int totalFiles;

  /// 썸네일 캐시가 차지하는 공간(바이트).
  final int totalSizeBytes;

  /// 썸네일 캐시가 차지하는 공간(MB).
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  @override
  String toString() {
    return 'ThumbnailCacheInfo('
        'totalFiles: $totalFiles, '
        'totalSize: ${totalSizeMB.toStringAsFixed(2)}MB'
        ')';
  }
}
