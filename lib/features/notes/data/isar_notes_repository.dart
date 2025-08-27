// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'dart:io'; // TODO(web): Replace File API usage with platform-appropriate implementation

import 'package:isar/isar.dart';



import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/db/models/models.dart';
import 'package:it_contest/features/db/services/note_db_service.dart';
import 'package:it_contest/features/notes/data/notes_repository.dart';

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
  });
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
      (notes) => notes.where((note) => note.vaultId == vaultId).toList(),
    );
  }

  /// 특정 폴더의 노트들만 관찰
  Stream<List<NoteModel>> watchNotesByFolder(int vaultId, int? folderId) {
    return watchNotes().map(
      (notes) =>
          notes.where((note) => note.vaultId == vaultId && note.folderId == folderId).toList(),
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
      if (!_notesController.isClosed) {
        _notesController.add(notes);
      }
    }

    _notesWatch = isar.noteModels.watchLazy(fireImmediately: true).listen((_) => emitAll());
    _pagesWatch = isar.pages.watchLazy().listen((_) => emitAll());
    _canvasWatch = isar.canvasDatas.watchLazy().listen((_) => emitAll());

    // 컨트롤러 구독 상태에 따라 워치 해제
    _notesController.onCancel = () async {
      await _notesWatch?.cancel();
      await _pagesWatch?.cancel();
      await _canvasWatch?.cancel();
      _notesWatch = null;
      _pagesWatch = null;
      _canvasWatch = null;
    };
  }

  Future<List<NoteModel>> _loadAllNotes(Isar isar) async {
    final rawNotes = await isar.noteModels.filter().deletedAtIsNull().findAll();
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
    if (_noteStreams.containsKey(noteId)) {
      return _noteStreams[noteId]!.stream;
    }

    final controller = StreamController<NoteModel?>.broadcast();
    _noteStreams[noteId] = controller;

    _initializeNoteWatch(noteId, controller);

    return controller.stream;
  }

  /// 개별 노트에 대한 변경 감지 스트림 초기화
  Future<void> _initializeNoteWatch(
      String noteId, StreamController<NoteModel?> controller) async {
    final isar = await _open();

    Future<void> emitNote() async {
      if (controller.isClosed) return;
      try {
        final note = await isar.noteModels.filter().noteIdEqualTo(noteId).findFirst();
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

    final noteQuery = isar.noteModels.filter().noteIdEqualTo(noteId);
    final pageQuery = isar.pages.filter().noteIdEqualTo(noteId);
    final canvasQuery = isar.canvasDatas.filter().noteIdEqualTo(noteId);

    final subscriptions = <StreamSubscription<void>>[
      noteQuery.watchLazy(fireImmediately: true).listen((_) => emitNote()),
      pageQuery.watchLazy().listen((_) => emitNote()),
      canvasQuery.watchLazy().listen((_) => emitNote()),
    ];

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
    final n = await isar.noteModels.filter().noteIdEqualTo(noteId).findFirst();
    if (n == null || n.deletedAt != null) {
      return null;
    }
    return _mapNote(isar, n);
  }

  @override
  Future<void> upsert(NoteModel note) async {
    final isar = await _open();
    final existingNote = await isar.noteModels.filter().noteIdEqualTo(note.noteId).findFirst();

    if (existingNote != null) {
      await _updateExistingNote(existingNote, note);
    } else {
      await _createNewNote(note, vaultId: note.vaultId, folderId: note.folderId);
    }
  }

  /// 기존 노트 업데이트
  Future<void> _updateExistingNote(NoteModel existingNote, NoteModel updatedNote) async {
    await NoteDbService.instance.renameNote(
      noteId: existingNote.id,
      newName: updatedNote.title,
    );
    await _updateNotePages(existingNote.noteId, updatedNote.pages);
  }

  /// 새 노트 생성
  Future<NoteModel> _createNewNote(NoteModel noteModel,
      {required int vaultId, int? folderId}) async {
    final note = await NoteDbService.instance.createNote(
      vaultId: vaultId,
      folderId: folderId,
      name: noteModel.title,
      pageOrientation: 'portrait',
      pageSize: 'A4',
    );

    await _updateNotePages(note.noteId, noteModel.pages);
    return (await _mapNote(await _open(), note))!;
  }

  /// 노트의 페이지들 업데이트
  Future<void> _updateNotePages(String noteId, List<NotePageModel> pages) async {
    final isar = await _open();

    await isar.writeTxn(() async {
      final existingPages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();
      final existingPageMap = <String, Page>{for (final p in existingPages) p.pageId: p};

      for (final pageModel in pages) {
        final pageId = pageModel.pageId;
        Page page;

        if (existingPageMap.containsKey(pageId)) {
          page = existingPageMap[pageId]!
            ..widthPx = (pageModel.backgroundWidth ?? 0).round()
            ..heightPx = (pageModel.backgroundHeight ?? 0).round()
            ..updatedAt = DateTime.now();

          if (pageModel.backgroundType == PageBackgroundType.pdf) {
            page
              ..pdfOriginalPath = pageModel.backgroundPdfPath
              ..pdfPageIndex = pageModel.backgroundPdfPageNumber;
          }
        } else {
          page = Page()
            ..noteId = noteId
            ..pageId = pageId
            ..index = pageModel.pageNumber - 1
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
        await isar.pages.put(page);
        await _updateCanvasData(noteId, pageId, pageModel.toExtendedJson());
        existingPageMap.remove(pageId);
      }

      final pagesToDelete = existingPageMap.values.map((p) => p.id).toList();
      if (pagesToDelete.isNotEmpty) {
        await isar.pages.deleteAll(pagesToDelete);
        final pageIdsToDelete = existingPageMap.values.map((p) => p.pageId).toList();
                final canvasToDelete = await isar.canvasDatas.filter().anyOf<String, QueryBuilder<CanvasData, CanvasData, QAfterFilterCondition>>(pageIdsToDelete, (q, String pageId) => q.pageIdEqualTo(pageId)).findAll();
        await isar.canvasDatas.deleteAll(canvasToDelete.map((c) => c.id).toList());
      }
    });
  }

  /// 캔버스 데이터 업데이트
  Future<void> _updateCanvasData(String noteId, String pageId, String jsonData) async {
    final isar = await _open();
    await isar.writeTxn(() async {
      var existingCanvas = await isar.canvasDatas.filter().pageIdEqualTo(pageId).findFirst();

      if (existingCanvas != null) {
        existingCanvas
          ..json = jsonData
          ..updatedAt = DateTime.now();
        await isar.canvasDatas.put(existingCanvas);
      } else {
        final canvasData = CanvasData()
          ..noteId = noteId
          ..pageId = pageId
          ..schemaVersion = '1.1.0'
          ..json = jsonData
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
        await isar.canvasDatas.put(canvasData);
      }
    });
  }

  @override
  Future<void> delete(String noteId) async {
    final isar = await _open();
    await isar.writeTxn(() async {
      final note = await isar.noteModels.filter().noteIdEqualTo(noteId).findFirst();
      if (note != null) {
        note.deletedAt = DateTime.now();
        note.updatedAt = DateTime.now();
        await isar.noteModels.put(note);
      }
    });
  }

  Future<NoteModel?> _mapNote(Isar isar, NoteModel note) async {
    final pages =
        await isar.pages.filter().equalTo(r'noteId', note.noteId).and().deletedAtIsNull().sortByIndex().findAll();

    final pageModels = <NotePageModel>[];
    for (final p in pages) {
      final cd = await isar.canvasDatas.filter().pageIdEqualTo(p.pageId).findFirst();
      final json = cd?.json ?? '{"shapes":[],"lines":[]}';
      final isPdf = p.pdfOriginalPath != null;

      final pageModel = NotePageModel.create(
        noteId: note.noteId,
        pageId: p.pageId,
        pageNumber: p.index + 1,
        jsonData: json,
        backgroundType: isPdf ? PageBackgroundType.pdf : PageBackgroundType.blank,
        backgroundPdfPath: p.pdfOriginalPath,
        backgroundPdfPageNumber: p.pdfPageIndex,
        backgroundWidth: p.widthPx.toDouble(),
        backgroundHeight: p.heightPx.toDouble(),
        preRenderedImagePath: null,
      );

      try {
        pageModel.updateFromExtendedJson(json);
      } catch (e) {
        pageModel.jsonData = json;
      }
      pageModels.add(pageModel);
    }

    note.pages = pageModels;
    return note;
  }

  Future<void> upsertBatch(List<NoteModel> notes) async {
    final isar = await _open();
    await isar.writeTxn(() async {
      for (final note in notes) {
        await upsert(note);
      }
    });
  }

  Future<void> deleteBatch(List<String> noteIds) async {
    final isar = await _open();
    if (noteIds.isEmpty) return;

    await isar.writeTxn(() async {
      final notes = await isar.noteModels.filter().anyOf(noteIds, (q, String id) => q.noteIdEqualTo(id)).findAll();
      final now = DateTime.now();
      for (final note in notes) {
        note
          ..deletedAt = now
          ..updatedAt = now;
      }
      await isar.noteModels.putAll(notes);
    });
  }

  Future<Map<String, int>> getStatistics() async {
    final isar = await _open();
    final allNotes = isar.noteModels.filter().deletedAtIsNull();
    final totalCount = await allNotes.count();
    final pdfCount = await allNotes.sourceTypeEqualTo(NoteSourceType.pdfBased).count();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentCount = await allNotes.updatedAtGreaterThan(weekAgo).count();

    return {
      'total': totalCount,
      'pdf_based': pdfCount,
      'recent_week': recentCount,
      'blank': totalCount - pdfCount,
    };
  }

  Future<void> invalidateCache() async {
    final isar = await _open();
    final notes = await _loadAllNotes(isar);
    if (!_notesController.isClosed) {
      _notesController.add(notes);
    }

    for (final entry in _noteStreams.entries) {
      final noteId = entry.key;
      final controller = entry.value;
      if (controller.isClosed) continue;

      final note = await isar.noteModels.filter().noteIdEqualTo(noteId).findFirst();
      if (note != null && note.deletedAt == null) {
        final noteModel = await _mapNote(isar, note);
        controller.add(noteModel);
      } else {
        controller.add(null);
      }
    }
  }

  bool get isInitialized => _isar != null;

  int get activeStreamCount => _noteStreams.length;

  Future<void> updatePageImagePath({
    required String noteId,
    required String pageId,
    required String imagePath,
  }) async {
    final isar = await _open();
    await isar.writeTxn(() async {
      final page = await isar.pages.filter().pageIdEqualTo(pageId).findFirst();
      if (page != null && page.noteId == noteId) {
        page
          ..pdfOriginalPath = imagePath
          ..updatedAt = DateTime.now();
        await isar.pages.put(page);
      }
    });
  }

  Future<void> updatePageCanvasData({
    required String pageId,
    required String jsonData,
  }) async {
    final isar = await _open();
    await isar.writeTxn(() async {
      final canvasData = await isar.canvasDatas.filter().pageIdEqualTo(pageId).findFirst();
      if (canvasData != null) {
        canvasData
          ..json = jsonData
          ..updatedAt = DateTime.now();
        await isar.canvasDatas.put(canvasData);
      }
    });
  }

  Future<void> updateBackgroundVisibility({
    required String noteId,
    required bool showBackground,
  }) async {
    // This feature seems to be tied to NotePageModel's state, which is transient.
    // A persistent implementation would require adding a 'showBackground' field
    // to the Isar 'Page' collection, which is beyond the current scope.
    // For now, this method will be a no-op.
  }

  Future<Map<String, String>> backupPageCanvasData({required String noteId}) async {
    final isar = await _open();
    final backupData = <String, String>{};
    final pages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();
    final pageIds = pages.map((p) => p.pageId).toList();

    if (pageIds.isEmpty) return backupData;

    final canvasDataList = await isar.canvasDatas.filter().anyOf(pageIds, (q, String pageId) => q.pageIdEqualTo(pageId)).findAll();
    for (final canvasData in canvasDataList) {
      backupData[canvasData.pageId] = canvasData.json;
    }
    return backupData;
  }

  Future<void> restorePageCanvasData({required Map<String, String> backupData}) async {
    if (backupData.isEmpty) return;
    final isar = await _open();
    await isar.writeTxn(() async {
      final pageIds = backupData.keys.toList();
      final canvasDataList = await isar.canvasDatas.filter().anyOf(pageIds, (q, String pageId) => q.pageIdEqualTo(pageId)).findAll();
      
      for (final canvasData in canvasDataList) {
        if (backupData.containsKey(canvasData.pageId)) {
          canvasData
            ..json = backupData[canvasData.pageId]!
            ..updatedAt = DateTime.now();
        }
      }
      await isar.canvasDatas.putAll(canvasDataList);
    });
  }

  Future<void> updatePageMetadata({
    required String pageId,
    required double width,
    required double height,
    String? pdfOriginalPath,
    int? pdfPageIndex,
  }) async {
    final isar = await _open();
    await isar.writeTxn(() async {
      final page = await isar.pages.filter().pageIdEqualTo(pageId).findFirst();
      if (page != null) {
        page
          ..widthPx = width.toInt()
          ..heightPx = height.toInt()
          ..updatedAt = DateTime.now();
        if (pdfOriginalPath != null) page.pdfOriginalPath = pdfOriginalPath;
        if (pdfPageIndex != null) page.pdfPageIndex = pdfPageIndex;
        await isar.pages.put(page);
      }
    });
  }

  Future<List<PdfPageInfo>> getPdfPagesInfo({required String noteId}) async {
    final isar = await _open();
    final pages = await isar.pages.filter().noteIdEqualTo(noteId).and().pdfOriginalPathIsNotNull().sortByIndex().findAll();
    return pages
        .map((p) => PdfPageInfo(
              pageId: p.pageId,
              pageIndex: p.index,
              pdfPageIndex: p.pdfPageIndex ?? 0,
              width: p.widthPx.toDouble(),
              height: p.heightPx.toDouble(),
              pdfOriginalPath: p.pdfOriginalPath,
            ))
        .toList();
  }

  Future<List<CorruptedPageInfo>> detectCorruptedPages({required String noteId}) async {
    final isar = await _open();
    final pages = await isar.pages.filter().noteIdEqualTo(noteId).findAll();
    final corruptedPages = <CorruptedPageInfo>[];

    for (final page in pages) {
      if (page.pdfOriginalPath != null && page.pdfOriginalPath!.isNotEmpty) {
        final file = File(page.pdfOriginalPath!);
        if (!await file.exists()) {
          corruptedPages.add(CorruptedPageInfo(
            pageId: page.pageId,
            pageIndex: page.index,
            reason: 'PDF 원본 파일 누락',
            pdfOriginalPath: page.pdfOriginalPath,
          ));
        }
      }
    }
    return corruptedPages;
  }

  @override
  void dispose() {
    _notesWatch?.cancel();
    _pagesWatch?.cancel();
    _canvasWatch?.cancel();
    _notesController.close();
    for (final controller in _noteStreams.values) {
      controller.close();
    }
    _noteStreams.clear();
  }
}

/// PDF 페이지 정보
class PdfPageInfo {
  final String pageId;
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
  final String pageId;
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
