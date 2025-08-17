import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:it_contest/features/notes/data/isar_notes_repository.dart';
import 'package:it_contest/features/notes/data/notes_repository.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';
import 'package:it_contest/shared/services/file_storage_service.dart';
import 'package:it_contest/shared/services/note_deletion_service.dart';
import 'package:path/path.dart' as path;
import 'package:pdfx/pdfx.dart';

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

  /// 노트 전체의 손상된 페이지들을 효율적으로 감지합니다.
  ///
  /// [noteId]: 노트 고유 ID
  /// [repo]: Repository 인스턴스
  ///
  /// Returns: 손상된 페이지 정보 리스트
  static Future<List<Map<String, dynamic>>> detectAllCorruptedPages(
    String noteId, {
    required NotesRepository repo,
  }) async {
    try {
      debugPrint('🔍 노트 손상 감지 시작: $noteId');

      final intNoteId = int.tryParse(noteId);
      if (intNoteId == null) {
        throw Exception('유효하지 않은 노트 ID: $noteId');
      }

      // IsarNotesRepository의 효율적인 손상 감지 사용
      if (repo is IsarNotesRepository) {
        final corruptedPages = await repo.detectCorruptedPages(noteId: intNoteId);
        final result = corruptedPages
            .map(
              (page) => {
                'pageId': page.pageId.toString(),
                'pageIndex': page.pageIndex,
                'reason': page.reason,
                'pdfOriginalPath': page.pdfOriginalPath,
                'corruptionType': CorruptionType.sourcePdfMissing,
              },
            )
            .toList();

        debugPrint('✅ 손상 감지 완료 (최적화됨): ${result.length}개 페이지 손상');
        return result;
      }

      // 기본 Repository의 경우 기존 방식
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      final corruptedPages = <Map<String, dynamic>>[];
      for (final page in note.pages) {
        final corruptionType = await detectCorruption(page);
        if (corruptionType != CorruptionType.unknown) {
          corruptedPages.add({
            'pageId': page.pageId,
            'pageNumber': page.pageNumber,
            'reason': corruptionType.toString(),
            'corruptionType': corruptionType,
          });
        }
      }

      debugPrint('✅ 손상 감지 완료: ${corruptedPages.length}개 페이지 손상');
      return corruptedPages;
    } catch (e) {
      debugPrint('❌ 손상 감지 실패: $e');
      return [];
    }
  }

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
        imageExists = imageFile.existsSync();

        if (imageExists) {
          // 파일 크기도 확인 (0바이트 파일은 손상으로 간주)
          final stat = imageFile.statSync();
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
          imageExists = imageFile.existsSync();

          if (imageExists) {
            final stat = imageFile.statSync();
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
        sourcePdfExists = pdfFile.existsSync();

        if (sourcePdfExists) {
          // PDF 파일 크기 확인
          final stat = pdfFile.statSync();
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
  /// Returns: pageId를 키로 하는 필기 데이터 맵
  static Future<Map<int, String>> backupSketchData(
    String noteId, {
    required NotesRepository repo,
  }) async {
    try {
      debugPrint('💾 필기 데이터 백업 시작: $noteId');

      final intNoteId = int.tryParse(noteId);
      if (intNoteId == null) {
        throw Exception('유효하지 않은 노트 ID: $noteId');
      }

      // IsarNotesRepository의 효율적인 백업 메서드 사용
      if (repo is IsarNotesRepository) {
        final backupData = await repo.backupPageCanvasData(noteId: intNoteId);
        debugPrint('✅ 필기 데이터 백업 완료: ${backupData.length}개 페이지 (최적화됨)');
        return backupData;
      }

      // 기본 Repository의 경우 기존 방식 유지
      final stringBackupData = <String, String>{};
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      for (final page in note.pages) {
        stringBackupData[page.pageId] = page.jsonData;
      }

      // String pageId를 int로 변환
      final backupData = <int, String>{};
      for (final entry in stringBackupData.entries) {
        final pageId = int.tryParse(entry.key);
        if (pageId != null) {
          backupData[pageId] = entry.value;
        }
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
    Map<int, String> backupData, {
    required NotesRepository repo,
  }) async {
    try {
      debugPrint('🔄 필기 데이터 복원 시작: $noteId');

      if (backupData.isEmpty) {
        debugPrint('📝 복원할 필기 데이터가 없습니다');
        return;
      }

      // IsarNotesRepository의 효율적인 복원 메서드 사용
      if (repo is IsarNotesRepository) {
        await repo.restorePageCanvasData(backupData: backupData);
        debugPrint('✅ 필기 데이터 복원 완료 (최적화됨): ${backupData.length}개 페이지');
        return;
      }

      // 기본 Repository의 경우 기존 방식 유지
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      for (final page in note.pages) {
        final pageId = int.tryParse(page.pageId);
        if (pageId != null && backupData.containsKey(pageId)) {
          page.jsonData = backupData[pageId]!;
        }
      }

      await repo.upsert(note);

      debugPrint('✅ 필기 데이터 복원 완료');
    } catch (e) {
      debugPrint('❌ 필기 데이터 복원 실패: $e');
      rethrow;
    }
  }

  /// 필기만 보기 모드를 활성화합니다.
  ///
  /// [noteId]: 노트 고유 ID
  static Future<void> enableSketchOnlyMode(
    String noteId, {
    required NotesRepository repo,
  }) async {
    try {
      debugPrint('👁️ 필기만 보기 모드 활성화: $noteId');

      final intNoteId = int.tryParse(noteId);
      if (intNoteId == null) {
        throw Exception('유효하지 않은 노트 ID: $noteId');
      }

      // IsarNotesRepository의 효율적인 배경 표시 업데이트 사용
      if (repo is IsarNotesRepository) {
        await repo.updateBackgroundVisibility(
          noteId: intNoteId,
          showBackground: false,
        );
        debugPrint('✅ 필기만 보기 모드 활성화 완료 (최적화됨)');
        return;
      }

      // 기본 Repository의 경우 기존 방식 유지
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      for (final page in note.pages) {
        if (page.backgroundType == PageBackgroundType.pdf) {
          page.showBackgroundImage = false;
        }
      }

      await repo.upsert(note);

      debugPrint('✅ 필기만 보기 모드 활성화 완료');
    } catch (e) {
      debugPrint('❌ 필기만 보기 모드 활성화 실패: $e');
      rethrow;
    }
  }

  /// 노트를 완전히 삭제합니다. (NoteDeletionService로 위임)
  static Future<bool> deleteNoteCompletely(
    String noteId, {
    required NotesRepository repo,
  }) async {
    return NoteDeletionService.deleteNoteCompletely(noteId, repo: repo);
  }

  /// PDF 페이지들을 재렌더링합니다.
  ///
  /// [noteId]: 노트 고유 ID
  /// [onProgress]: 진행률 콜백 (progress, currentPage, totalPages)
  ///
  /// Returns: 재렌더링 성공 여부
  static Future<bool> rerenderNotePages(
    String noteId, {
    required NotesRepository repo,
    void Function(double progress, int currentPage, int totalPages)? onProgress,
  }) async {
    try {
      debugPrint('🔄 PDF 재렌더링 시작: $noteId');
      _shouldCancel = false;

      // 1. 필기 데이터 백업
      final sketchBackup = await backupSketchData(
        noteId,
        repo: repo,
      );

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

      final intNoteId = int.tryParse(noteId);
      if (intNoteId == null) {
        throw Exception('유효하지 않은 노트 ID: $noteId');
      }

      // IsarNotesRepository의 효율적인 PDF 페이지 정보 조회 사용
      List<Map<String, dynamic>> pagesInfo;
      if (repo is IsarNotesRepository) {
        final pdfPages = await repo.getPdfPagesInfo(noteId: intNoteId);
        pagesInfo = pdfPages
            .map(
              (page) => {
                'pageId': page.pageId.toString(),
                'pageNumber': page.pageIndex + 1, // pageIndex는 0부터 시작
                'width': page.width,
                'height': page.height,
              },
            )
            .toList();
        debugPrint('✅ PDF 페이지 정보 조회 완료 (최적화됨): ${pagesInfo.length}개 페이지');
      } else {
        // 기본 Repository의 경우 기존 방식
        final note = await repo.getNoteById(noteId);
        if (note == null) {
          throw Exception('노트를 찾을 수 없습니다: $noteId');
        }

        pagesInfo = note.pages
            .where((page) => page.backgroundType == PageBackgroundType.pdf)
            .map(
              (page) => {
                'pageId': page.pageId,
                'pageNumber': page.pageNumber,
                'width': page.backgroundWidth,
                'height': page.backgroundHeight,
              },
            )
            .toList();

        // pageNumber 오름차순 정렬
        pagesInfo.sort((a, b) => (a['pageNumber'] as int).compareTo(b['pageNumber'] as int));
      }

      for (final pageInfo in pagesInfo) {
        // 취소 체크
        if (_shouldCancel) {
          debugPrint('⏹️ 재렌더링 취소됨');
          await document.close();
          return false;
        }

        // 페이지 렌더링
        await _renderSinglePage(
          document,
          noteId,
          pageNumber: pageInfo['pageNumber'] as int,
          pageId: pageInfo['pageId'] as String,
          repo: repo,
        );

        // 진행률 업데이트
        final pageNumber = pageInfo['pageNumber'] as int;
        final progress = pageNumber / totalPages;
        onProgress?.call(progress, pageNumber, totalPages);

        debugPrint('✅ 페이지 $pageNumber/$totalPages 렌더링 완료');

        // UI 블로킹 방지
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await document.close();

      // 5. 필기 데이터 복원
      await restoreSketchData(
        noteId,
        sketchBackup,
        repo: repo,
      );

      // 6. 배경 이미지 표시 복원
      await _restoreBackgroundVisibility(
        noteId,
        repo: repo,
      );

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

      if (directory.existsSync()) {
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
    String noteId, {
    required int pageNumber,
    required String pageId,
    required NotesRepository repo,
  }) async {
    // pdfx
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
      await _updatePageImagePath(
        noteId,
        pageId,
        imagePath,
        repo: repo,
      );
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
    String pageId,
    String imagePath, {
    required NotesRepository repo,
  }) async {
    try {
      final intNoteId = int.tryParse(noteId);
      final intPageId = int.tryParse(pageId);

      if (intNoteId == null || intPageId == null) {
        throw Exception('유효하지 않은 ID: noteId=$noteId, pageId=$pageId');
      }

      // IsarNotesRepository의 효율적인 이미지 경로 업데이트 사용
      if (repo is IsarNotesRepository) {
        await repo.updatePageImagePath(
          noteId: intNoteId,
          pageId: intPageId,
          imagePath: imagePath,
        );
        debugPrint('✅ 페이지 이미지 경로 업데이트 완료 (최적화됨): $imagePath');
        return;
      }

      // 기본 Repository의 경우 기존 방식 유지
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      final idx = note.pages.indexWhere((p) => p.pageId == pageId);
      if (idx == -1) {
        return;
      }

      final updated = note.pages[idx].copyWith(
        preRenderedImagePath: imagePath,
      );
      final newPages = [...note.pages];
      newPages[idx] = updated;

      final newNote = note.copyWith(
        pages: newPages,
        updatedAt: DateTime.now(),
      );

      await repo.upsert(newNote);
    } catch (e) {
      debugPrint('⚠️ 페이지 이미지 경로 업데이트 실패: $e');
    }
  }

  /// 배경 이미지 표시를 복원합니다.
  static Future<void> _restoreBackgroundVisibility(
    String noteId, {
    required NotesRepository repo,
  }) async {
    try {
      debugPrint('👁️ 배경 이미지 표시 복원: $noteId');

      final intNoteId = int.tryParse(noteId);
      if (intNoteId == null) {
        throw Exception('유효하지 않은 노트 ID: $noteId');
      }

      // IsarNotesRepository의 효율적인 배경 표시 업데이트 사용
      if (repo is IsarNotesRepository) {
        await repo.updateBackgroundVisibility(
          noteId: intNoteId,
          showBackground: true,
        );
        debugPrint('✅ 배경 이미지 표시 복원 완료 (최적화됨)');
        return;
      }

      // 기본 Repository의 경우 기존 방식 유지
      final note = await repo.getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }

      for (final page in note.pages) {
        if (page.backgroundType == PageBackgroundType.pdf) {
          page.showBackgroundImage = true;
        }
      }

      await repo.upsert(note);

      debugPrint('✅ 배경 이미지 표시 복원 완료');
    } catch (e) {
      debugPrint('⚠️ 배경 이미지 표시 복원 실패: $e');
    }
  }
}
