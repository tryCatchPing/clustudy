import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';

import '../../features/notes/data/fake_notes.dart';
import '../../features/notes/models/note_page_model.dart';
import 'file_storage_service.dart';

/// PDF 파일 손상 유형을 정의합니다.
enum CorruptionType {
  /// 이미지 파일이 없거나 접근할 수 없음.
  imageFileMissing,

  /// 이미지 파일이 손상됨.
  imageFileCorrupted,

  /// 원본 PDF 파일이 없거나 접근할 수 없음.
  sourcePdfMissing,

  /// 이미지와 PDF 모두 문제가 있음.
  bothMissing,

  /// 파일은 정상이지만 다른 오류.
  unknown,
}

/// PDF 복구를 담당하는 서비스
///
/// 손상된 PDF 노트의 감지, 복구, 필기 데이터 보존을 관리합니다.
class PdfRecoveryService {
  // 인스턴스 생성 방지 (유틸리티 클래스)
  PdfRecoveryService._();

  static bool _shouldCancel = false;

  /// 손상 감지를 수행합니다.
  ///
  /// [page]: 검사할 노트 페이지 모델
  ///
  /// Returns: 감지된 손상 유형
  static Future<CorruptionType> detectCorruption(NotePageModel page) async {
    try {
      debugPrint('🔍 손상 감지 시작: ${page.noteId} - 페이지 ${page.pageNumber}');

      bool imageExists = false;
      bool sourcePdfExists = false;

      // 1. 사전 렌더링된 이미지 파일 확인
      if (page.preRenderedImagePath != null) {
        final imageFile = File(page.preRenderedImagePath!);
        imageExists = await imageFile.exists();

        if (imageExists) {
          // 파일 크기도 확인 (0바이트 파일은 손상으로 간주)
          final stat = await imageFile.stat();
          if (stat.size == 0) {
            debugPrint('⚠️ 이미지 파일 크기가 0바이트: ${page.preRenderedImagePath}');
            imageExists = false;
          }
        }
      }

      // FileStorageService를 통해서도 이미지 확인
      if (!imageExists) {
        final imagePath = await FileStorageService.getPageImagePath(
          noteId: page.noteId,
          pageNumber: page.pageNumber,
        );
        if (imagePath != null) {
          final imageFile = File(imagePath);
          imageExists = await imageFile.exists();

          if (imageExists) {
            final stat = await imageFile.stat();
            if (stat.size == 0) {
              imageExists = false;
            }
          }
        }
      }

      // 2. 원본 PDF 파일 확인
      final pdfPath = await FileStorageService.getNotesPdfPath(page.noteId);
      if (pdfPath != null) {
        final pdfFile = File(pdfPath);
        sourcePdfExists = await pdfFile.exists();

        if (sourcePdfExists) {
          // PDF 파일 크기 확인
          final stat = await pdfFile.stat();
          if (stat.size == 0) {
            sourcePdfExists = false;
          }
        }
      }

      // 3. 손상 유형 결정
      if (!imageExists && !sourcePdfExists) {
        debugPrint('❌ 이미지와 PDF 모두 누락');
        return CorruptionType.bothMissing;
      } else if (!imageExists && sourcePdfExists) {
        debugPrint('⚠️ 이미지 파일 누락, PDF는 존재');
        return CorruptionType.imageFileMissing;
      } else if (imageExists && !sourcePdfExists) {
        debugPrint('⚠️ PDF 파일 누락, 이미지는 존재');
        return CorruptionType.sourcePdfMissing;
      } else {
        debugPrint('ℹ️ 파일은 존재하지만 다른 문제 발생');
        return CorruptionType.unknown;
      }
    } catch (e) {
      debugPrint('❌ 손상 감지 중 오류 발생: $e');
      return CorruptionType.unknown;
    }
  }

  /// 필기 데이터를 백업합니다.
  ///
  /// [noteId]: 노트 고유 ID
  ///
  /// Returns: 페이지 번호를 키로 하는 필기 데이터 맵
  static Future<Map<int, String>> backupSketchData(String noteId) async {
    try {
      debugPrint('💾 필기 데이터 백업 시작: $noteId');

      final backupData = <int, String>{};

      // TODO(xodnd): 실제 DB 연동 시 수정 필요
      final note = fakeNotes.firstWhere(
        (note) => note.noteId == noteId,
        orElse: () => throw Exception('노트를 찾을 수 없습니다: $noteId'),
      );

      for (final page in note.pages) {
        backupData[page.pageNumber] = page.jsonData;
      }

      debugPrint('✅ 필기 데이터 백업 완료: ${backupData.length}개 페이지');
      return backupData;
    } catch (e) {
      debugPrint('❌ 필기 데이터 백업 실패: $e');
      return <int, String>{};
    }
  }

  /// 필기 데이터를 복원합니다.
  ///
  /// [noteId]: 노트 고유 ID
  /// [backupData]: 백업된 필기 데이터
  static Future<void> restoreSketchData(
    String noteId,
    Map<int, String> backupData,
  ) async {
    try {
      debugPrint('🔄 필기 데이터 복원 시작: $noteId');

      // TODO(xodnd): 실제 DB 연동 시 수정 필요
      final noteIndex = fakeNotes.indexWhere((note) => note.noteId == noteId);
      if (noteIndex == -1) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      final note = fakeNotes[noteIndex];

      for (final page in note.pages) {
        if (backupData.containsKey(page.pageNumber)) {
          page.jsonData = backupData[page.pageNumber]!;
        }
      }

      debugPrint('✅ 필기 데이터 복원 완료');
    } catch (e) {
      debugPrint('❌ 필기 데이터 복원 실패: $e');
      rethrow;
    }
  }

  /// 필기만 보기 모드를 활성화합니다.
  ///
  /// [noteId]: 노트 고유 ID
  static Future<void> enableSketchOnlyMode(String noteId) async {
    try {
      debugPrint('👁️ 필기만 보기 모드 활성화: $noteId');

      // TODO(xodnd): 실제 DB 연동 시 수정 필요
      final noteIndex = fakeNotes.indexWhere((note) => note.noteId == noteId);
      if (noteIndex == -1) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      final note = fakeNotes[noteIndex];

      for (final page in note.pages) {
        if (page.backgroundType == PageBackgroundType.pdf) {
          page.showBackgroundImage = false;
        }
      }

      // TODO(xodnd): DB 업데이트

      debugPrint('✅ 필기만 보기 모드 활성화 완료');
    } catch (e) {
      debugPrint('❌ 필기만 보기 모드 활성화 실패: $e');
      rethrow;
    }
  }

  /// 노트를 완전히 삭제합니다.
  ///
  /// [noteId]: 삭제할 노트의 고유 ID
  ///
  /// Returns: 삭제 성공 여부
  static Future<bool> deleteNoteCompletely(String noteId) async {
    try {
      debugPrint('🗑️ 노트 완전 삭제 시작: $noteId');

      // 1. 파일 시스템 정리
      await FileStorageService.deleteNoteFiles(noteId);

      // 2. 메모리에서 제거 (현재는 fakeNotes, 향후 DB 연동)
      fakeNotes.removeWhere((note) => note.noteId == noteId);

      // TODO(xodnd): 실제 DB에서도 제거

      debugPrint('✅ 노트 완전 삭제 완료: $noteId');
      return true;
    } catch (e) {
      debugPrint('❌ 노트 삭제 실패: $e');
      return false;
    }
  }

  /// PDF 페이지들을 재렌더링합니다.
  ///
  /// [noteId]: 노트 고유 ID
  /// [onProgress]: 진행률 콜백 (progress, currentPage, totalPages)
  ///
  /// Returns: 재렌더링 성공 여부
  static Future<bool> rerenderNotePages(
    String noteId, {
    void Function(double progress, int currentPage, int totalPages)? onProgress,
  }) async {
    try {
      debugPrint('🔄 PDF 재렌더링 시작: $noteId');
      _shouldCancel = false;

      // 1. 필기 데이터 백업
      final sketchBackup = await backupSketchData(noteId);

      // 2. 원본 PDF 경로 확인
      final pdfPath = await FileStorageService.getNotesPdfPath(noteId);
      if (pdfPath == null) {
        throw Exception('원본 PDF 파일을 찾을 수 없습니다');
      }

      // 3. 기존 이미지 파일들 삭제
      await _deleteExistingImages(noteId);

      // 4. PDF 재렌더링
      final document = await PdfDocument.openFile(pdfPath);
      final totalPages = document.pagesCount;

      debugPrint('📄 재렌더링할 총 페이지 수: $totalPages');

      for (int pageNum = 1; pageNum <= totalPages; pageNum++) {
        // 취소 체크
        if (_shouldCancel) {
          debugPrint('⏹️ 재렌더링 취소됨');
          await document.close();
          return false;
        }

        // 페이지 렌더링
        await _renderSinglePage(document, noteId, pageNum);

        // 진행률 업데이트
        final progress = pageNum / totalPages;
        onProgress?.call(progress, pageNum, totalPages);

        debugPrint('✅ 페이지 $pageNum/$totalPages 렌더링 완료');

        // UI 블로킹 방지
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await document.close();

      // 5. 필기 데이터 복원
      await restoreSketchData(noteId, sketchBackup);

      // 6. 배경 이미지 표시 복원
      await _restoreBackgroundVisibility(noteId);

      debugPrint('✅ PDF 재렌더링 완료: $noteId');
      return true;
    } catch (e) {
      debugPrint('❌ PDF 재렌더링 실패: $e');
      return false;
    }
  }

  /// 재렌더링을 취소합니다.
  static void cancelRerendering() {
    debugPrint('⏹️ 재렌더링 취소 요청');
    _shouldCancel = true;
  }

  /// 기존 이미지 파일들을 삭제합니다.
  static Future<void> _deleteExistingImages(String noteId) async {
    try {
      final pageImagesDir = await FileStorageService.getPageImagesDirectoryPath(
        noteId,
      );
      final directory = Directory(pageImagesDir);

      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is File && entity.path.endsWith('.jpg')) {
            await entity.delete();
            debugPrint('🗑️ 기존 이미지 삭제: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 기존 이미지 삭제 중 오류: $e');
    }
  }

  /// 단일 페이지를 렌더링합니다.
  static Future<void> _renderSinglePage(
    PdfDocument document,
    String noteId,
    int pageNumber,
  ) async {
    final pdfPage = await document.getPage(pageNumber);

    // 정규화된 크기 계산 (PdfProcessor와 동일한 로직)
    final originalWidth = pdfPage.width;
    final originalHeight = pdfPage.height;
    final normalizedSize = _normalizePageSize(originalWidth, originalHeight);

    // 이미지 렌더링
    final pageImage = await pdfPage.render(
      width: normalizedSize.width,
      height: normalizedSize.height,
      format: PdfPageImageFormat.jpeg,
    );

    if (pageImage?.bytes != null) {
      // 이미지 파일 저장
      final pageImagesDir = await FileStorageService.getPageImagesDirectoryPath(
        noteId,
      );
      final imageFileName = 'page_$pageNumber.jpg';
      final imagePath = path.join(pageImagesDir, imageFileName);
      final imageFile = File(imagePath);

      await imageFile.writeAsBytes(pageImage!.bytes);

      // 노트 페이지 모델의 이미지 경로 업데이트
      await _updatePageImagePath(noteId, pageNumber, imagePath);
    }

    await pdfPage.close();
  }

  /// 페이지 크기를 정규화합니다.
  static Size _normalizePageSize(double originalWidth, double originalHeight) {
    const double targetLongEdge = 2000.0;
    final aspectRatio = originalWidth / originalHeight;

    if (originalWidth >= originalHeight) {
      return Size(targetLongEdge, targetLongEdge / aspectRatio);
    } else {
      return Size(targetLongEdge * aspectRatio, targetLongEdge);
    }
  }

  /// 페이지의 이미지 경로를 업데이트합니다.
  static Future<void> _updatePageImagePath(
    String noteId,
    int pageNumber,
    String imagePath,
  ) async {
    try {
      // TODO(xodnd): 실제 DB 연동 시 수정 필요
      final noteIndex = fakeNotes.indexWhere((note) => note.noteId == noteId);
      if (noteIndex != -1) {
        final note = fakeNotes[noteIndex];
        final pageIndex = note.pages.indexWhere(
          (page) => page.pageNumber == pageNumber,
        );
        if (pageIndex != -1) {
          // preRenderedImagePath 업데이트는 NotePageModel이 immutable하므로
          // 새로운 페이지 객체 생성이 필요할 수 있음
          // 현재는 mutable 필드로 되어 있어 직접 수정 가능
          // note.pages[pageIndex].preRenderedImagePath = imagePath;
        }
      }
    } catch (e) {
      debugPrint('⚠️ 페이지 이미지 경로 업데이트 실패: $e');
    }
  }

  /// 배경 이미지 표시를 복원합니다.
  static Future<void> _restoreBackgroundVisibility(String noteId) async {
    try {
      debugPrint('👁️ 배경 이미지 표시 복원: $noteId');

      final noteIndex = fakeNotes.indexWhere((note) => note.noteId == noteId);
      if (noteIndex != -1) {
        final note = fakeNotes[noteIndex];

        for (final page in note.pages) {
          if (page.backgroundType == PageBackgroundType.pdf) {
            page.showBackgroundImage = true;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ 배경 이미지 표시 복원 실패: $e');
    }
  }
}
