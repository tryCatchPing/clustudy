import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:it_contest/features/db/isar_db.dart';
import 'package:it_contest/features/notes/data/isar_notes_repository.dart';
import 'package:it_contest/features/notes/data/memory_notes_repository.dart';
import 'package:it_contest/features/notes/data/notes_repository.dart';
import 'package:it_contest/features/notes/models/note_model.dart';

/// Isar 데이터베이스 인스턴스 Provider
///
/// - 앱 전역에서 단일 Isar 인스턴스를 관리
/// - 자동으로 데이터베이스를 열고 Provider dispose 시 정리
final isarProvider = Provider<Future<Isar>>((ref) async {
  final isar = await IsarDb.instance.open();

  ref.onDispose(() async {
    // Provider가 dispose될 때 Isar 인스턴스 정리
    await IsarDb.instance.close();
  });

  return isar;
});

/// 기본 볼트 ID Provider (설정 가능)
final defaultVaultIdProvider = Provider<int>((ref) {
  // 환경 변수나 설정에서 읽어올 수 있음
  return const int.fromEnvironment('DEFAULT_VAULT_ID', defaultValue: 1);
});

/// 앱 전역에서 사용할 `NotesRepository` Provider
///
/// Repository 패턴의 핵심 DI 지점:
/// - 프로덕션: IsarNotesRepository (실제 데이터베이스)
/// - 테스트: MemoryNotesRepository (메모리 기반)
/// - 환경별 교체: USE_ISAR_REPO 환경 변수로 제어
final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  const useIsarRepo = bool.fromEnvironment('USE_ISAR_REPO', defaultValue: true);

  if (useIsarRepo) {
    // Isar Repository 사용
    final defaultVaultId = ref.watch(defaultVaultIdProvider);
    final repo = IsarNotesRepository(defaultVaultId: defaultVaultId);

    // Repository dispose 시 리소스 정리
    ref.onDispose(() {
      repo.dispose();
    });

    return repo;
  } else {
    // Memory Repository 사용 (테스트/개발용)
    final repo = MemoryNotesRepository();
    ref.onDispose(() {
      repo.dispose();
    });

    return repo;
  }
});

/// 특정 볼트용 NotesRepository Provider
///
/// 멀티 볼트 환경에서 각 볼트별로 독립적인 Repository 인스턴스 제공
final notesRepositoryForVaultProvider = Provider.family<NotesRepository, int>((ref, vaultId) {
  const useIsarRepo = bool.fromEnvironment('USE_ISAR_REPO', defaultValue: true);

  if (useIsarRepo) {
    final repo = IsarNotesRepository(defaultVaultId: vaultId);
    ref.onDispose(() {
      repo.dispose();
    });
    return repo;
  } else {
    final repo = MemoryNotesRepository();
    ref.onDispose(() {
      repo.dispose();
    });
    return repo;
  }
});

/// 전체 노트 목록 Provider
///
/// Repository의 watchNotes() 스트림을 Riverpod Provider로 래핑
final notesProvider = StreamProvider<List<NoteModel>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchNotes();
});

/// 특정 노트 Provider
///
/// 개별 노트 조회 및 실시간 업데이트를 위한 Family Provider
final noteProvider = StreamProvider.family<NoteModel?, String>((ref, noteId) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchNoteById(noteId);
});

/// 특정 볼트의 노트 목록 Provider
final notesForVaultProvider = StreamProvider.family<List<NoteModel>, int>((ref, vaultId) {
  final repository = ref.watch(notesRepositoryForVaultProvider(vaultId));
  return repository.watchNotes();
});

/// 최근 노트 목록 Provider
final recentNotesProvider = StreamProvider.family<List<NoteModel>, int>((ref, limit) {
  final repository = ref.watch(notesRepositoryProvider);

  // IsarNotesRepository인 경우 최적화된 메서드 사용
  if (repository is IsarNotesRepository) {
    return repository.watchRecentNotes(limit: limit);
  }

  // 다른 Repository는 기본 스트림에서 필터링
  return repository.watchNotes().map((notes) {
    final sortedNotes = List<NoteModel>.from(notes);
    sortedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sortedNotes.take(limit).toList();
  });
});

/// PDF 기반 노트 목록 Provider
final pdfNotesProvider = StreamProvider<List<NoteModel>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);

  if (repository is IsarNotesRepository) {
    return repository.watchPdfNotes();
  }

  return repository.watchNotes().map((notes) => notes.where((note) => note.isPdfBased).toList());
});

/// 노트 검색 Provider
final searchNotesProvider = StreamProvider.family<List<NoteModel>, String>((ref, query) {
  final repository = ref.watch(notesRepositoryProvider);

  if (repository is IsarNotesRepository) {
    return repository.searchNotesByTitle(query);
  }

  return repository.watchNotes().map(
    (notes) =>
        notes.where((note) => note.title.toLowerCase().contains(query.toLowerCase())).toList(),
  );
});

/// 노트 통계 Provider
final notesStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(notesRepositoryProvider);

  if (repository is IsarNotesRepository) {
    return await repository.getStatistics();
  }

  // Memory Repository의 경우 기본 통계 계산
  final notes = await repository.watchNotes().first;
  return {
    'total': notes.length,
    'pdf_based': notes.where((n) => n.isPdfBased).length,
    'blank': notes.where((n) => n.isBlank).length,
    'recent_week': notes.where((n) => DateTime.now().difference(n.updatedAt).inDays <= 7).length,
  };
});
