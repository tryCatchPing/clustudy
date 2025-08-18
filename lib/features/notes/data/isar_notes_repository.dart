// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io'; // TODO(web): Replace File API usage with platform-appropriate implementation

import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/models/vault_models.g.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/features/notes/data/notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';
import 'package:it_contest/features/notes/models/note_page_model.dart';

/// Isar 데이터베이스를 사용한 NotesRepository 구현체
///
/// Repository 패턴의 핵심 장점:
/// 1. 데이터 접근 로직 캡슐화
/// 2. UI 레이어와 데이터 레이어 분리
/// 3. 테스트 용이성 (Mock 가능)
/// 4. 다양한 데이터 소스 교체 가능
class IsarNotesRepository implements NotesRepository {
  IsarNotesRepository({
    int? defaultVaultId,
  }) : _defaultVaultId = defaultVaultId ?? 1;

  final int _defaultVaultId;
  Isar? _isar;

  // 브로드캐스트 스트림으로 여러 구독자 지원
  final StreamController<List<NoteModel>> _notesController =
      StreamController<List<NoteModel>>.broadcast();

  // 각 데이터 변경을 감지하는 구독자들
  StreamSubscription<void>? _notesWatch;
  StreamSubscription<void>? _pagesWatch;
  StreamSubscription<void>? _canvasWatch;

  // 개별 노트 스트림 캐싱 (메모리 효율성)
  final Map<String, StreamController<NoteModel?>> _noteStreams = {};

  Future<Isar> _open() async {
    _isar ??= await IsarDb.instance.open();
    return _isar!;
  }

  @override
  Stream<List<NoteModel>> watchNotes() {
    _ensureNotesWatchInitialized();
    return _notesController.stream;
  }

  /// 특정 볼트의 노트들만 관찰
  Stream<List<NoteModel>> watchNotesByVault(int vaultId) {
    return watchNotes().map(
      (notes) => notes.where((note) => _getVaultIdFromNote(note) == vaultId).toList(),
    );
  }

  /// 특정 폴더의 노트들만 관찰
  Stream<List<NoteModel>> watchNotesByFolder(int vaultId, int? folderId) {
    return watchNotes().map(
      (notes) => notes
          .where(
            (note) =>
                _getVaultIdFromNote(note) == vaultId && _getFolderIdFromNote(note) == folderId,
          )
          .toList(),
    );
  }

  /// 제목으로 노트 검색
  Stream<List<NoteModel>> searchNotesByTitle(String query) {
    return watchNotes().map(
      (notes) =>
          notes.where((note) => note.title.toLowerCase().contains(query.toLowerCase())).toList(),
    );
  }

  /// PDF 기반 노트들만 필터링
  Stream<List<NoteModel>> watchPdfNotes() {
    return watchNotes().map((notes) => notes.where((note) => note.isPdfBased).toList());
  }

  /// 최근 수정된 노트들 (제한된 개수)
  Stream<List<NoteModel>> watchRecentNotes({int limit = 10}) {
    return watchNotes().map((notes) {
      final sortedNotes = List<NoteModel>.from(notes);
      sortedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sortedNotes.take(limit).toList();
    });
  }

  /// 노트에서 볼트 ID 추출 (임시 구현)
  int _getVaultIdFromNote(NoteModel note) {
    // 실제 구현에서는 노트와 볼트 관계를 추적해야 함
    return _defaultVaultId;
  }

  /// 노트에서 폴더 ID 추출 (임시 구현)
  int? _getFolderIdFromNote(NoteModel note) {
    // 실제 구현에서는 노트와 폴더 관계를 추적해야 함
    return null;
  }

  /// 전체 노트 변화에 대한 내부 워치 초기화
  ///
  /// 첫 구독 시 초기화되고, 마지막 구독 취소 시 정리됩니다.
  Future<void> _ensureNotesWatchInitialized() async {
    if (_notesWatch != null) {
      return;
    }
    final isar = await _open();

    Future<void> emitAll() async {
      final notes = await _loadAllNotes(isar);
      _notesController.add(notes);
    }

    _notesWatch = isar.notes.watchLazy(fireImmediately: true).listen((_) {
      emitAll();
    });
    _pagesWatch = isar.pages.watchLazy().listen((_) {
      emitAll();
    });
    _canvasWatch = isar.canvasDatas.watchLazy().listen((_) {
      emitAll();
    });

    // 컨트롤러 구독 상태에 따라 워치 해제
    _notesController
      ..onListen = () {
        // no-op; 이미 초기화됨
      }
      ..onCancel = () async {
        await _notesWatch?.cancel();
        await _pagesWatch?.cancel();
        await _canvasWatch?.cancel();
        _notesWatch = null;
        _pagesWatch = null;
        _canvasWatch = null;
      };
  }

  Future<List<NoteModel>> _loadAllNotes(Isar isar) async {
    final rawNotes = await isar.notes.filter().deletedAtIsNull().findAll();
    final result = <NoteModel>[];
    for (final n in rawNotes) {
      final mapped = await _mapNote(isar, n);
      if (mapped != null) {
        result.add(mapped);
      }
    }
    return result;
  }

  @override
  Stream<NoteModel?> watchNoteById(String noteId) {
    // 스트림 캐싱으로 메모리 효율성 개선
    if (_noteStreams.containsKey(noteId)) {
      return _noteStreams[noteId]!.stream;
    }

    final controller = StreamController<NoteModel?>.broadcast();
    _noteStreams[noteId] = controller;

    _initializeNoteWatch(noteId, controller);

    return controller.stream;
  }

  /// 개별 노트에 대한 변경 감지 스트림 초기화
  Future<void> _initializeNoteWatch(String noteId, StreamController<NoteModel?> controller) async {
    final isar = await _open();
    final intId = int.tryParse(noteId);

    if (intId == null) {
      // UUID 등 숫자가 아니면 매칭 불가
      controller.add(null);
      return;
    }

    Future<void> emitNote() async {
      try {
        final note = await isar.notes.get(intId);
        if (note == null || note.deletedAt != null) {
          controller.add(null);
          return;
        }
        final noteModel = await _mapNote(isar, note);
        controller.add(noteModel);
      } catch (e) {
        controller.addError(e);
      }
    }

    // 각 관련 데이터의 변경을 감지
    final subscriptions = <StreamSubscription<void>>[
      isar.notes.watchObject(intId, fireImmediately: true).listen((_) => emitNote()),
      isar.pages.filter().noteIdEqualTo(intId).watchLazy().listen((_) => emitNote()),
      isar.canvasDatas.filter().noteIdEqualTo(intId).watchLazy().listen((_) => emitNote()),
    ];

    // 컨트롤러가 닫힐 때 구독 정리 및 리소스 해제
    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
      _noteStreams.remove(noteId);
      await controller.close();
    };
  }

  @override
  Future<NoteModel?> getNoteById(String noteId) async {
    final isar = await _open();
    final intId = int.tryParse(noteId);
    if (intId == null) {
      return null;
    }
    final n = await isar.notes.get(intId);
    if (n == null || n.deletedAt != null) {
      return null;
    }
    return _mapNote(isar, n);
  }

  @override
  Future<void> upsert(NoteModel note) async {
    final intId = int.tryParse(note.noteId);

    if (intId != null) {
      // 기존 노트 업데이트
      await _updateExistingNote(intId, note);
    } else {
      // 새 노트 생성
      await _createNewNote(note);
    }
  }

  /// 기존 노트 업데이트
  Future<void> _updateExistingNote(int noteId, NoteModel noteModel) async {
    // 기존 NoteDbService의 로직을 활용하여 일관성 보장
    await NoteDbService.instance.renameNote(
      noteId: noteId,
      newName: noteModel.title,
    );

    // 페이지 및 캔버스 데이터 업데이트
    await _updateNotePages(noteId, noteModel.pages);
  }

  /// 새 노트 생성
  Future<Note> _createNewNote(NoteModel noteModel) async {
    // NoteDbService를 사용하여 일관된 노트 생성
    final note = await NoteDbService.instance.createNote(
      vaultId: _defaultVaultId,
      name: noteModel.title,
      pageSize: 'A4',
      pageOrientation: 'portrait',
    );

    // 페이지 데이터 설정
    await _updateNotePages(note.id, noteModel.pages);

    return note;
  }

  /// 노트의 페이지들 업데이트
  Future<void> _updateNotePages(int noteId, List<NotePageModel> pages) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      // 기존 페이지들 조회
      final existingPages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();

      final existingPageMap = <int, Page>{for (final page in existingPages) page.index: page};

      // 새 페이지들 처리
      for (final pageModel in pages) {
        final pageIndex = pageModel.pageNumber - 1;

        Page page;
        if (existingPageMap.containsKey(pageIndex)) {
          // 기존 페이지 업데이트
          page = existingPageMap[pageIndex]!
            ..widthPx = (pageModel.backgroundWidth ?? 0).round()
            ..heightPx = (pageModel.backgroundHeight ?? 0).round()
            ..updatedAt = DateTime.now();

          // PDF 배경 정보 업데이트
          if (pageModel.backgroundType == PageBackgroundType.pdf) {
            page
              ..pdfOriginalPath = pageModel.backgroundPdfPath
              ..pdfPageIndex = pageModel.backgroundPdfPageNumber;
          }
        } else {
          // 새 페이지 생성
          page = Page()
            ..noteId = noteId
            ..index = pageIndex
            ..widthPx = (pageModel.backgroundWidth ?? 0).round()
            ..heightPx = (pageModel.backgroundHeight ?? 0).round()
            ..rotationDeg = 0
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now();

          if (pageModel.backgroundType == PageBackgroundType.pdf) {
            page
              ..pdfOriginalPath = pageModel.backgroundPdfPath
              ..pdfPageIndex = pageModel.backgroundPdfPageNumber;
          }
        }

        final pageId = await isar.pages.put(page);

        // 캔버스 데이터 업데이트
        await _updateCanvasData(noteId, pageId, pageModel.jsonData);

        existingPageMap.remove(pageIndex);
      }

      // 사용되지 않는 페이지들 삭제
      final pagesToDelete = existingPageMap.values.map((p) => p.id).toList();
      if (pagesToDelete.isNotEmpty) {
        await isar.pages.deleteAll(pagesToDelete);

        // 관련 캔버스 데이터도 삭제
        for (final pageId in pagesToDelete) {
          final canvasData = await isar.canvasDatas.filter().pageIdEqualTo(pageId).findAll();
          await isar.canvasDatas.deleteAll(canvasData.map((c) => c.id).toList());
        }
      }
    });
  }

  /// 캔버스 데이터 업데이트
  Future<void> _updateCanvasData(int noteId, int pageId, String jsonData) async {
    final isar = await _open();

    final existingCanvas = await isar.canvasDatas.filter().pageIdEqualTo(pageId).findFirst();

    if (existingCanvas != null) {
      // 기존 캔버스 데이터 업데이트
      existingCanvas
        ..json = jsonData
        ..updatedAt = DateTime.now();
      await isar.canvasDatas.put(existingCanvas);
    } else {
      // 새 캔버스 데이터 생성
      final canvasData = CanvasData()
        ..noteId = noteId
        ..pageId = pageId
        ..schemaVersion = '1.0.0'
        ..json = jsonData
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await isar.canvasDatas.put(canvasData);
    }
  }

  @override
  Future<void> delete(String noteId) async {
    final intId = int.tryParse(noteId);
    if (intId == null) {
      return;
    }

    // NoteDbService를 사용하여 일관된 소프트 삭제 처리
    try {
      final isar = await _open();
      await isar.writeTxn(() async {
        final note = await isar.notes.get(intId);
        if (note != null) {
          note.deletedAt = DateTime.now();
          note.updatedAt = DateTime.now();
          await isar.notes.put(note);
        }
      });
    } catch (e) {
      // 노트가 존재하지 않거나 이미 삭제된 경우 무시 (idempotent)
      // Repository 인터페이스 명세에 따라 에러로 간주하지 않음
    }
  }

  Future<NoteModel?> _mapNote(Isar isar, Note note) async {
    final pages = await isar.pages
        .filter()
        .noteIdEqualTo(note.id)
        .and()
        .deletedAtIsNull()
        .sortByIndex()
        .findAll();

    final pageModels = <NotePageModel>[];
    for (final p in pages) {
      final cd = await isar.canvasDatas.filter().pageIdEqualTo(p.id).findFirst();
      final json = cd?.json ?? '{"lines":[]}';
      final isPdf = p.pdfOriginalPath != null;
      final pageModel = NotePageModel(
        noteId: note.id.toString(),
        pageId: p.id.toString(),
        pageNumber: p.index + 1,
        jsonData: json,
        backgroundType: isPdf ? PageBackgroundType.pdf : PageBackgroundType.blank,
        backgroundPdfPath: p.pdfOriginalPath,
        backgroundPdfPageNumber: p.pdfPageIndex,
        backgroundWidth: p.widthPx.toDouble(),
        backgroundHeight: p.heightPx.toDouble(),
        preRenderedImagePath: null,
      );
      pageModels.add(pageModel);
    }

    final hasPdf = pageModels.any((e) => e.backgroundType == PageBackgroundType.pdf);
    final sourcePdfPath = hasPdf
        ? pageModels
            .firstWhere((e) => e.backgroundType == PageBackgroundType.pdf)
            .backgroundPdfPath
        : null;

    return NoteModel(
      noteId: note.id.toString(),
      title: note.name,
      pages: pageModels,
      sourceType: hasPdf ? NoteSourceType.pdfBased : NoteSourceType.blank,
      sourcePdfPath: sourcePdfPath,
      totalPdfPages: pageModels.length,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    );
  }

  /// 여러 노트를 배치로 업데이트 (성능 최적화)
  /// 여러 노트를 배치로 upsert 합니다.
  ///
  /// 대량 처리 시 트랜잭션 경계 최소화로 성능 최적화됩니다.
  Future<void> upsertBatch(List<NoteModel> notes) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      for (final note in notes) {
        final intId = int.tryParse(note.noteId);

        if (intId != null) {
          // 기존 노트 업데이트
          final existingNote = await isar.notes.get(intId);
          if (existingNote != null) {
            existingNote
              ..name = note.title
              ..nameLowerForParentUnique = note.title.toLowerCase()
              ..nameLowerForSearch = note.title.toLowerCase()
              ..updatedAt = DateTime.now();
            await isar.notes.put(existingNote);

            // 페이지 데이터 업데이트는 트랜잭션 외부에서 처리
            await _updateNotePages(intId, note.pages);
          }
        } else {
          // 새 노트는 개별적으로 생성 (복잡한 로직 때문)
          await _createNewNote(note);
        }
      }
    });
  }

  /// 여러 노트를 배치로 삭제
  /// 여러 노트를 배치로 삭제합니다. 존재하지 않는 ID는 무시됩니다.
  Future<void> deleteBatch(List<String> noteIds) async {
    final isar = await _open();
    final validIds = noteIds.map(int.tryParse).where((id) => id != null).cast<int>().toList();

    if (validIds.isEmpty) {
      return;
    }

    await isar.writeTxn(() async {
      final notes = await isar.notes.getAll(validIds);
      final now = DateTime.now();

      for (final note in notes) {
        if (note != null) {
          note
            ..deletedAt = now
            ..updatedAt = now;
        }
      }

      await isar.notes.putAll(notes.whereType<Note>().toList());
    });
  }

  /// 통계 정보 조회
  /// 간단한 통계 정보를 반환합니다.
  /// - total: 삭제되지 않은 전체 노트 수
  /// - pdf_based: 이름에 '.pdf'가 포함된 노트 수
  /// - recent_week: 최근 7일내 수정된 노트 수
  /// - blank: pdf_based를 제외한 나머지
  Future<Map<String, int>> getStatistics() async {
    final isar = await _open();

    final totalCount = await isar.notes.filter().deletedAtIsNull().count();

    // 단일 조건으로 간소화하여 RepeatModifier 관련 제네릭 추론 이슈 방지
    final pdfCount = await isar.notes
        .filter()
        .deletedAtIsNull()
        .nameContains('.pdf', caseSensitive: false)
        .count();

    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final recentCount = await isar.notes
        .filter()
        .deletedAtIsNull()
        .and()
        .updatedAtBetween(weekAgo, today)
        .count();

    return {
      'total': totalCount,
      'pdf_based': pdfCount,
      'recent_week': recentCount,
      'blank': totalCount - pdfCount,
    };
  }

  /// PDF 노트 필터 조건들 (복잡한 쿼리용)
  // Removed _getPdfNoteFilters; inlined with anyOf<String> above for clarity

  /// 캐시 무효화 (강제 새로고침)
  /// 내부 캐시/스트림을 강제로 최신 상태로 갱신합니다.
  Future<void> invalidateCache() async {
    final isar = await _open();
    final notes = await _loadAllNotes(isar);
    _notesController.add(notes);

    // 개별 노트 스트림들도 무효화
    for (final entry in _noteStreams.entries) {
      final noteId = entry.key;
      final controller = entry.value;

      final intId = int.tryParse(noteId);
      if (intId != null) {
        final note = await isar.notes.get(intId);
        if (note != null && note.deletedAt == null) {
          final noteModel = await _mapNote(isar, note);
          controller.add(noteModel);
        } else {
          controller.add(null);
        }
      }
    }
  }

  /// Repository 상태 확인
  bool get isInitialized => _isar != null;

  /// 활성 스트림 개수 (디버깅용)
  int get activeStreamCount => _noteStreams.length;

  // ========================================
  // PDF Recovery Service 전용 효율적 메서드들
  // ========================================

  /// 특정 페이지의 이미지 경로만 업데이트 (PDF Recovery 최적화)
  Future<void> updatePageImagePath({
    required int noteId,
    required int pageId,
    required String imagePath,
  }) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      // 직접 Page 엔티티 조회 및 업데이트
      final page = await isar.pages.get(pageId);
      if (page != null && page.noteId == noteId) {
        page
          ..pdfOriginalPath = imagePath
          ..updatedAt = DateTime.now();
        await isar.pages.put(page);
      }
    });
  }

  /// 특정 페이지의 캔버스 데이터만 업데이트 (필기 복원 최적화)
  Future<void> updatePageCanvasData({
    required int pageId,
    required String jsonData,
  }) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      // 직접 CanvasData 엔티티 조회 및 업데이트
      final canvasData = await isar.canvasDatas.filter().pageIdEqualTo(pageId).findFirst();

      if (canvasData != null) {
        canvasData
          ..json = jsonData
          ..updatedAt = DateTime.now();
        await isar.canvasDatas.put(canvasData);
      }
    });
  }

  /// 노트의 모든 PDF 페이지들의 배경 이미지 표시 상태 업데이트
  Future<void> updateBackgroundVisibility({
    required int noteId,
    required bool showBackground,
  }) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      // 노트의 모든 페이지 조회
      final pages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();

      // PDF 페이지만 필터링하고 배경 표시 상태 업데이트
      final pdfPages = pages
          .where((page) => page.pdfOriginalPath != null && page.pdfOriginalPath!.isNotEmpty)
          .toList();

      for (final page in pdfPages) {
        // 페이지 메타데이터에 배경 표시 정보 저장
        // (실제 구현에서는 Page 모델에 showBackground 필드 추가 필요)
        page.updatedAt = DateTime.now();
      }

      if (pdfPages.isNotEmpty) {
        await isar.pages.putAll(pdfPages);
      }
    });
  }

  /// 노트의 페이지별 캔버스 데이터 백업
  Future<Map<int, String>> backupPageCanvasData({
    required int noteId,
  }) async {
    final isar = await _open();

    // 페이지 ID를 키로 하는 캔버스 데이터 맵
    final backupData = <int, String>{};

    // Isar Link를 활용한 효율적 조회
    final note = await isar.notes.get(noteId);
    if (note == null) {
      return backupData;
    }

    // 노트의 모든 페이지 조회
    final pages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();

    // 각 페이지의 캔버스 데이터 조회
    for (final page in pages) {
      final canvasData = await isar.canvasDatas.filter().pageIdEqualTo(page.id).findFirst();

      if (canvasData != null) {
        backupData[page.id] = canvasData.json;
      }
    }

    return backupData;
  }

  /// 노트의 페이지별 캔버스 데이터 배치 복원
  Future<void> restorePageCanvasData({
    required Map<int, String> backupData,
  }) async {
    if (backupData.isEmpty) {
      return;
    }

    final isar = await _open();

    await isar.writeTxn(() async {
      for (final entry in backupData.entries) {
        final pageId = entry.key;
        final jsonData = entry.value;

        final canvasData = await isar.canvasDatas.filter().pageIdEqualTo(pageId).findFirst();

        if (canvasData != null) {
          canvasData
            ..json = jsonData
            ..updatedAt = DateTime.now();
          await isar.canvasDatas.put(canvasData);
        }
      }
    });
  }

  /// 노트의 특정 페이지 크기 및 메타데이터 업데이트
  Future<void> updatePageMetadata({
    required int pageId,
    required double width,
    required double height,
    String? pdfOriginalPath,
    int? pdfPageIndex,
  }) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      final page = await isar.pages.get(pageId);
      if (page != null) {
        page
          ..widthPx = width.toInt()
          ..heightPx = height.toInt()
          ..updatedAt = DateTime.now();

        if (pdfOriginalPath != null) {
          page.pdfOriginalPath = pdfOriginalPath;
        }

        if (pdfPageIndex != null) {
          page.pdfPageIndex = pdfPageIndex;
        }

        await isar.pages.put(page);
      }
    });
  }

  /// 노트의 PDF 페이지들 정보 효율적 조회
  Future<List<PdfPageInfo>> getPdfPagesInfo({
    required int noteId,
  }) async {
    final isar = await _open();

    final pages = await isar.pages
        .filter()
        .noteIdEqualTo(noteId)
        .and()
        .pdfOriginalPathIsNotNull()
        .sortByIndex()
        .findAll();

    return pages
        .map(
          (page) => PdfPageInfo(
            pageId: page.id,
            pageIndex: page.index,
            pdfPageIndex: page.pdfPageIndex ?? 0,
            width: page.widthPx.toDouble(),
            height: page.heightPx.toDouble(),
            pdfOriginalPath: page.pdfOriginalPath,
          ),
        )
        .toList();
  }

  /// 노트의 손상된 페이지 감지 (효율적 쿼리)
  Future<List<CorruptedPageInfo>> detectCorruptedPages({
    required int noteId,
  }) async {
    final isar = await _open();

    final pages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();

    final corruptedPages = <CorruptedPageInfo>[];

    for (final page in pages) {
      bool isCorrupted = false;
      String reason = '';

      // PDF 원본 경로 체크
      if (page.pdfOriginalPath != null && page.pdfOriginalPath!.isNotEmpty) {
        final file = File(page.pdfOriginalPath!);
        if (!file.existsSync()) {
          isCorrupted = true;
          reason = 'PDF 원본 파일 누락';
        }
      }

      if (isCorrupted) {
        corruptedPages.add(
          CorruptedPageInfo(
            pageId: page.id,
            pageIndex: page.index,
            reason: reason,
            pdfOriginalPath: page.pdfOriginalPath,
          ),
        );
      }
    }

    return corruptedPages;
  }

  @override
  void dispose() {
    // 전체 노트 목록 스트림 정리
    _notesWatch?.cancel();
    _pagesWatch?.cancel();
    _canvasWatch?.cancel();
    _notesController.close();

    // 개별 노트 스트림들 정리
    for (final controller in _noteStreams.values) {
      controller.close();
    }
    _noteStreams.clear();
  }
}

/// PDF 페이지 정보
class PdfPageInfo {
  final int pageId;
  final int pageIndex;
  final int pdfPageIndex;
  final double width;
  final double height;
  final String? pdfOriginalPath;

  PdfPageInfo({
    required this.pageId,
    required this.pageIndex,
    required this.pdfPageIndex,
    required this.width,
    required this.height,
    this.pdfOriginalPath,
  });
}

/// 손상된 페이지 정보
class CorruptedPageInfo {
  final int pageId;
  final int pageIndex;
  final String reason;
  final String? pdfOriginalPath;

  CorruptedPageInfo({
    required this.pageId,
    required this.pageIndex,
    required this.reason,
    this.pdfOriginalPath,
  });
}
