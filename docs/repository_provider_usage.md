# Repository Provider 사용 가이드

## 📋 개요

`notes_repository_provider.dart`는 Repository 패턴과 Dependency Injection을 완벽하게 구현한 Riverpod Provider 시스템입니다. Isar 데이터베이스 관리부터 다양한 노트 관련 기능까지 모든 것을 제공합니다.

## 🏗️ Provider 구조

### **핵심 Infrastructure Providers**

```dart
// Isar 데이터베이스 인스턴스 관리
final isarProvider = Provider<Future<Isar>>;

// 기본 볼트 ID 설정
final defaultVaultIdProvider = Provider<int>;

// 메인 Repository (환경별 교체 가능)
final notesRepositoryProvider = Provider<NotesRepository>;

// 볼트별 Repository (멀티 볼트 지원)
final notesRepositoryForVaultProvider = Provider.family<NotesRepository, int>;
```

### **데이터 Access Providers**

```dart
// 전체 노트 목록 실시간 스트림
final notesProvider = StreamProvider<List<NoteModel>>;

// 개별 노트 실시간 스트림
final noteProvider = StreamProvider.family<NoteModel?, String>;

// 볼트별 노트 목록
final notesForVaultProvider = StreamProvider.family<List<NoteModel>, int>;

// 최근 노트 목록 (제한된 개수)
final recentNotesProvider = StreamProvider.family<List<NoteModel>, int>;

// PDF 기반 노트만 필터링
final pdfNotesProvider = StreamProvider<List<NoteModel>>;

// 제목 기반 검색
final searchNotesProvider = StreamProvider.family<List<NoteModel>, String>;

// 통계 정보
final notesStatisticsProvider = FutureProvider<Map<String, int>>;
```

## 🚀 실사용 예제

### **1. 기본 앱 설정**

```dart
void main() {
  runApp(
    ProviderScope(
      // 환경별 설정 오버라이드
      overrides: [
        // 개발 환경에서는 Memory Repository 사용
        if (kDebugMode)
          notesRepositoryProvider.overrideWith((ref) => MemoryNotesRepository()),

        // 기본 볼트 ID 설정
        defaultVaultIdProvider.overrideWith((ref) => 1),
      ],
      child: MyApp(),
    ),
  );
}
```

### **2. 노트 목록 화면**

```dart
class NotesListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 노트'),
        actions: [
          // 통계 정보 표시
          Consumer(
            builder: (context, ref, child) {
              final statsAsync = ref.watch(notesStatisticsProvider);
              return statsAsync.when(
                data: (stats) => Chip(
                  label: Text('${stats['total']}개'),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('노트가 없습니다\n새 노트를 만들어보세요!'),
            );
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(note: note);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48),
              const SizedBox(height: 16),
              Text('오류가 발생했습니다: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(notesProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNewNote(WidgetRef ref) async {
    final repository = ref.read(notesRepositoryProvider);

    final newNote = NoteModel(
      noteId: '', // 새 노트는 빈 ID
      title: '새로운 노트',
      pages: [
        NotePageModel(
          noteId: '',
          pageId: '',
          pageNumber: 1,
          jsonData: '{"lines":[]}',
          backgroundType: PageBackgroundType.blank,
          backgroundWidth: 794.0,
          backgroundHeight: 1123.0,
        ),
      ],
    );

    try {
      await repository.upsert(newNote);
      // 성공 시 자동으로 UI 업데이트됨 (스트림 연결)
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트 생성 실패: $e')),
      );
    }
  }
}
```

### **3. 노트 편집 화면**

```dart
class NoteEditorScreen extends ConsumerWidget {
  final String noteId;

  const NoteEditorScreen({required this.noteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(noteId));

    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('노트를 찾을 수 없음')),
            body: const Center(
              child: Text('노트가 존재하지 않거나 삭제되었습니다.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(note.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => _saveNote(ref, note),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteNote(ref, note.noteId),
              ),
            ],
          ),
          body: NoteEditorWidget(
            note: note,
            onChanged: (updatedNote) => _autoSave(ref, updatedNote),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(child: Text('노트 로딩 실패: $error')),
      ),
    );
  }

  Future<void> _saveNote(WidgetRef ref, NoteModel note) async {
    final repository = ref.read(notesRepositoryProvider);

    try {
      await repository.upsert(note);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트가 저장되었습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  Future<void> _deleteNote(WidgetRef ref, String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 삭제'),
        content: const Text('정말로 이 노트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repository = ref.read(notesRepositoryProvider);

      try {
        await repository.delete(noteId);
        Navigator.pop(context); // 편집 화면 닫기
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  // 자동 저장 (디바운싱)
  Timer? _autoSaveTimer;

  void _autoSave(WidgetRef ref, NoteModel note) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      final repository = ref.read(notesRepositoryProvider);
      repository.upsert(note);
    });
  }
}
```

### **4. 검색 화면**

```dart
class SearchNotesScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SearchNotesScreen> createState() => _SearchNotesScreenState();
}

class _SearchNotesScreenState extends ConsumerState<SearchNotesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = _query.isEmpty
        ? const AsyncValue.data(<NoteModel>[])
        : ref.watch(searchNotesProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '노트 검색...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value.trim();
            });
          },
        ),
      ),
      body: Column(
        children: [
          // 필터 탭
          TabBar(
            tabs: const [
              Tab(text: '전체'),
              Tab(text: 'PDF'),
              Tab(text: '최근'),
            ],
          ),

          // 검색 결과
          Expanded(
            child: searchResultsAsync.when(
              data: (notes) {
                if (_query.isEmpty) {
                  return const Center(
                    child: Text('검색어를 입력하세요'),
                  );
                }

                if (notes.isEmpty) {
                  return Center(
                    child: Text('\'$_query\'에 대한 검색 결과가 없습니다'),
                  );
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return SearchResultTile(
                      note: note,
                      query: _query,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Text('검색 실패: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### **5. 대시보드 위젯**

```dart
class DashboardWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // 통계 카드
        Consumer(
          builder: (context, ref, child) {
            final statsAsync = ref.watch(notesStatisticsProvider);

            return statsAsync.when(
              data: (stats) => Row(
                children: [
                  StatCard(
                    title: '전체 노트',
                    count: stats['total'] ?? 0,
                    icon: Icons.note,
                  ),
                  StatCard(
                    title: 'PDF 기반',
                    count: stats['pdf_based'] ?? 0,
                    icon: Icons.picture_as_pdf,
                  ),
                  StatCard(
                    title: '최근 활동',
                    count: stats['recent_week'] ?? 0,
                    icon: Icons.access_time,
                  ),
                ],
              ),
              loading: () => const Row(
                children: [
                  StatCard.loading(),
                  StatCard.loading(),
                  StatCard.loading(),
                ],
              ),
              error: (_, __) => const Text('통계 로딩 실패'),
            );
          },
        ),

        const SizedBox(height: 16),

        // 최근 노트 목록
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final recentNotesAsync = ref.watch(recentNotesProvider(5));

              return recentNotesAsync.when(
                data: (notes) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '최근 노트',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return RecentNoteTile(note: note);
                        },
                      ),
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text('최근 노트 로딩 실패: $error'),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## 🔧 고급 사용법

### **1. 환경별 Repository 교체**

```dart
// 개발 환경 설정
ProviderScope(
  overrides: [
    notesRepositoryProvider.overrideWith((ref) => MemoryNotesRepository()),
  ],
  child: MyApp(),
)

// 테스트 환경 설정
ProviderScope(
  overrides: [
    notesRepositoryProvider.overrideWith((ref) => MockNotesRepository()),
  ],
  child: TestApp(),
)

// 프로덕션 환경 (기본값)
ProviderScope(
  child: MyApp(), // 자동으로 IsarNotesRepository 사용
)
```

### **2. 멀티 볼트 애플리케이션**

```dart
class VaultSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButton<int>(
      value: ref.watch(defaultVaultIdProvider),
      onChanged: (vaultId) {
        if (vaultId != null) {
          // 볼트 변경 시 해당 볼트의 Repository로 전환
          ref.read(defaultVaultIdProvider.notifier).state = vaultId;
        }
      },
      items: [1, 2, 3].map((vaultId) =>
        DropdownMenuItem(
          value: vaultId,
          child: Text('볼트 $vaultId'),
        ),
      ).toList(),
    );
  }
}

class VaultSpecificNotesScreen extends ConsumerWidget {
  final int vaultId;

  const VaultSpecificNotesScreen({required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesForVaultProvider(vaultId));

    return notesAsync.when(
      data: (notes) => NotesListView(notes: notes),
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(error: error),
    );
  }
}
```

### **3. 배치 작업**

```dart
class BulkOperationsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _performBulkUpdate(ref),
          child: const Text('일괄 업데이트'),
        ),
        ElevatedButton(
          onPressed: () => _performBulkDelete(ref),
          child: const Text('일괄 삭제'),
        ),
      ],
    );
  }

  Future<void> _performBulkUpdate(WidgetRef ref) async {
    final repository = ref.read(notesRepositoryProvider);
    final notes = await ref.read(notesProvider.future);

    // 모든 노트 제목에 접두사 추가
    final updatedNotes = notes.map((note) =>
      note.copyWith(title: '[업데이트됨] ${note.title}')
    ).toList();

    if (repository is IsarNotesRepository) {
      // 배치 업데이트 사용
      await repository.upsertBatch(updatedNotes);
    } else {
      // 개별 업데이트
      for (final note in updatedNotes) {
        await repository.upsert(note);
      }
    }
  }

  Future<void> _performBulkDelete(WidgetRef ref) async {
    final repository = ref.read(notesRepositoryProvider);
    final notes = await ref.read(notesProvider.future);

    final noteIds = notes.map((note) => note.noteId).toList();

    if (repository is IsarNotesRepository) {
      // 배치 삭제 사용
      await repository.deleteBatch(noteIds);
    } else {
      // 개별 삭제
      for (final noteId in noteIds) {
        await repository.delete(noteId);
      }
    }
  }
}
```

## 🧪 테스트 예제

```dart
void main() {
  group('Notes Repository Provider Tests', () {
    testWidgets('노트 목록이 올바르게 표시되는지 확인', (tester) async {
      final mockRepo = MockNotesRepository();
      mockRepo.addTestNote(NoteModel(
        noteId: '1',
        title: '테스트 노트',
        pages: [],
      ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notesRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: NotesListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('테스트 노트'), findsOneWidget);
    });
  });
}
```

---

**🎉 결론**: 이 Provider 시스템은 Repository 패턴의 모든 장점을 Riverpod과 완벽하게 통합하여 타입 안전하고, 테스트 가능하며, 확장 가능한 상태 관리를 제공합니다!
