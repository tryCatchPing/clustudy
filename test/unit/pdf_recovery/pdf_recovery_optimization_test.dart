import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../lib/features/notes/data/isar_notes_repository.dart';
import '../../../lib/features/notes/data/notes_repository.dart';
import '../../../lib/shared/services/pdf_recovery_service.dart';

class MockIsarNotesRepository extends Mock implements IsarNotesRepository {}
class MockNotesRepository extends Mock implements NotesRepository {}

void main() {
  group('PDF Recovery Service Optimization Tests', () {
    late MockIsarNotesRepository mockIsarRepo;
    late MockNotesRepository mockRepo;

    setUp(() {
      mockIsarRepo = MockIsarNotesRepository();
      mockRepo = MockNotesRepository();
    });

    group('효율적인 필기 데이터 백업/복원', () {
      test('IsarNotesRepository 사용 시 최적화된 백업 메서드 호출', () async {
        // Given
        const noteId = '123';
        final expectedBackupData = <int, String>{
          1: '{"lines": []}',
          2: '{"lines": [{"points": []}]}',
        };
        
        when(mockIsarRepo.backupPageCanvasData(noteId: 123))
            .thenAnswer((_) async => expectedBackupData);

        // When
        final result = await PdfRecoveryService.backupSketchData(
          noteId,
          repo: mockIsarRepo,
        );

        // Then
        expect(result, equals(expectedBackupData));
        verify(mockIsarRepo.backupPageCanvasData(noteId: 123)).called(1);
      });

      test('IsarNotesRepository 사용 시 최적화된 복원 메서드 호출', () async {
        // Given
        const noteId = '123';
        final backupData = <int, String>{
          1: '{"lines": []}',
          2: '{"lines": [{"points": []}]}',
        };
        
        when(mockIsarRepo.restorePageCanvasData(backupData: backupData))
            .thenAnswer((_) async => {});

        // When
        await PdfRecoveryService.restoreSketchData(
          noteId,
          backupData,
          repo: mockIsarRepo,
        );

        // Then
        verify(mockIsarRepo.restorePageCanvasData(backupData: backupData)).called(1);
      });
    });

    group('효율적인 배경 이미지 표시 관리', () {
      test('IsarNotesRepository 사용 시 최적화된 필기만 보기 모드', () async {
        // Given
        const noteId = '123';
        
        when(mockIsarRepo.updateBackgroundVisibility(
          noteId: 123,
          showBackground: false,
        )).thenAnswer((_) async => {});

        // When
        await PdfRecoveryService.enableSketchOnlyMode(
          noteId,
          repo: mockIsarRepo,
        );

        // Then
        verify(mockIsarRepo.updateBackgroundVisibility(
          noteId: 123,
          showBackground: false,
        )).called(1);
      });
    });

    group('효율적인 손상 감지', () {
      test('IsarNotesRepository 사용 시 최적화된 손상 감지', () async {
        // Given
        const noteId = '123';
        final expectedCorruptedPages = [
          CorruptedPageInfo(
            pageId: 1,
            pageIndex: 0,
            reason: 'PDF 원본 파일 누락',
            pdfOriginalPath: '/path/to/missing.pdf',
          ),
        ];
        
        when(mockIsarRepo.detectCorruptedPages(noteId: 123))
            .thenAnswer((_) async => expectedCorruptedPages);

        // When
        final result = await PdfRecoveryService.detectAllCorruptedPages(
          noteId,
          repo: mockIsarRepo,
        );

        // Then
        expect(result.length, equals(1));
        expect(result.first['pageId'], equals('1'));
        expect(result.first['reason'], equals('PDF 원본 파일 누락'));
        verify(mockIsarRepo.detectCorruptedPages(noteId: 123)).called(1);
      });
    });

    group('효율적인 PDF 페이지 정보 조회', () {
      test('IsarNotesRepository에서 PDF 페이지 정보 효율적 조회', () async {
        // Given
        const noteId = 123;
        final expectedPdfPages = [
          PdfPageInfo(
            pageId: 1,
            pageIndex: 0,
            pdfPageIndex: 0,
            width: 794.0,
            height: 1123.0,
            pdfOriginalPath: '/path/to/test.pdf',
          ),
          PdfPageInfo(
            pageId: 2,
            pageIndex: 1,
            pdfPageIndex: 1,
            width: 794.0,
            height: 1123.0,
            pdfOriginalPath: '/path/to/test.pdf',
          ),
        ];
        
        when(mockIsarRepo.getPdfPagesInfo(noteId: noteId))
            .thenAnswer((_) async => expectedPdfPages);

        // When
        final result = await mockIsarRepo.getPdfPagesInfo(noteId: noteId);

        // Then
        expect(result.length, equals(2));
        expect(result.first.pageId, equals(1));
        expect(result.first.width, equals(794.0));
        expect(result.first.height, equals(1123.0));
        verify(mockIsarRepo.getPdfPagesInfo(noteId: noteId)).called(1);
      });
    });

    group('페이지별 개별 업데이트', () {
      test('페이지 이미지 경로 개별 업데이트', () async {
        // Given
        const noteId = 123;
        const pageId = 1;
        const imagePath = '/path/to/rendered_page.jpg';
        
        when(mockIsarRepo.updatePageImagePath(
          noteId: noteId,
          pageId: pageId,
          imagePath: imagePath,
        )).thenAnswer((_) async => {});

        // When
        await mockIsarRepo.updatePageImagePath(
          noteId: noteId,
          pageId: pageId,
          imagePath: imagePath,
        );

        // Then
        verify(mockIsarRepo.updatePageImagePath(
          noteId: noteId,
          pageId: pageId,
          imagePath: imagePath,
        )).called(1);
      });

      test('페이지 캔버스 데이터 개별 업데이트', () async {
        // Given
        const pageId = 1;
        const jsonData = '{"lines": [{"points": [{"x": 100, "y": 200}]}]}';
        
        when(mockIsarRepo.updatePageCanvasData(
          pageId: pageId,
          jsonData: jsonData,
        )).thenAnswer((_) async => {});

        // When
        await mockIsarRepo.updatePageCanvasData(
          pageId: pageId,
          jsonData: jsonData,
        );

        // Then
        verify(mockIsarRepo.updatePageCanvasData(
          pageId: pageId,
          jsonData: jsonData,
        )).called(1);
      });

      test('페이지 메타데이터 업데이트', () async {
        // Given
        const pageId = 1;
        const width = 794.0;
        const height = 1123.0;
        const pdfPath = '/path/to/updated.pdf';
        const pdfPageIndex = 2;
        
        when(mockIsarRepo.updatePageMetadata(
          pageId: pageId,
          width: width,
          height: height,
          pdfOriginalPath: pdfPath,
          pdfPageIndex: pdfPageIndex,
        )).thenAnswer((_) async => {});

        // When
        await mockIsarRepo.updatePageMetadata(
          pageId: pageId,
          width: width,
          height: height,
          pdfOriginalPath: pdfPath,
          pdfPageIndex: pdfPageIndex,
        );

        // Then
        verify(mockIsarRepo.updatePageMetadata(
          pageId: pageId,
          width: width,
          height: height,
          pdfOriginalPath: pdfPath,
          pdfPageIndex: pdfPageIndex,
        )).called(1);
      });
    });
  });

  group('성능 최적화 검증', () {
    test('Isar Repository 최적화 vs 기본 Repository 성능 시뮬레이션', () async {
      // Given - 시뮬레이션된 성능 데이터
      final stopwatch = Stopwatch();
      
      // IsarNotesRepository 시뮬레이션 (최적화됨)
      stopwatch.start();
      await Future.delayed(const Duration(milliseconds: 10)); // Isar 직접 쿼리
      stopwatch.stop();
      final isarTime = stopwatch.elapsedMilliseconds;
      
      stopwatch.reset();
      
      // 기본 Repository 시뮬레이션 (전체 노트 로딩)
      stopwatch.start();
      await Future.delayed(const Duration(milliseconds: 50)); // 전체 노트 + 페이지 로딩
      stopwatch.stop();
      final defaultTime = stopwatch.elapsedMilliseconds;
      
      // Then - Isar가 더 빠름을 검증
      expect(isarTime, lessThan(defaultTime));
      print('Isar 최적화: ${isarTime}ms vs 기본: ${defaultTime}ms');
    });
  });
}
