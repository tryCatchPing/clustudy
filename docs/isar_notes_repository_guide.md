# IsarNotesRepository 사용 가이드

## 📋 개요

`IsarNotesRepository`는 `NotesRepository` 인터페이스를 만족하는 Isar 데이터베이스 구현체입니다. Repository 패턴을 통해 데이터 접근 로직을 캡슐화하고, UI 레이어와 데이터 레이어를 분리하여 테스트 용이성과 유지보수성을 크게 향상시킵니다.

## 🎯 Repository 패턴의 핵심 가치

### 1. **데이터 접근 로직 캡슐화**
- 복잡한 Isar 쿼리와 트랜잭션 로직을 숨김
- 비즈니스 로직에서 데이터베이스 세부사항 제거
- 일관된 데이터 접근 인터페이스 제공

### 2. **UI 레이어와 데이터 레이어 분리**
- UI는 Repository 인터페이스만 의존
- 데이터베이스 변경 시 UI 코드 영향 없음
- 관심사의 명확한 분리

### 3. **테스트 용이성**
- Mock Repository로 단위 테스트 가능
- 실제 데이터베이스 없이 로직 테스트
- 다양한 데이터 시나리오 시뮬레이션

### 4. **다양한 데이터 소스 교체 가능**
- Isar ↔ SQLite ↔ Memory 교체 용이
- 개발/테스트/프로덕션 환경별 구현체 사용
- 점진적 마이그레이션 지원

## 🏗️ 구현 특징

### **핵심 기능**
- ✅ **완전한 인터페이스 구현**: `NotesRepository` 의 모든 메서드 구현
- ✅ **실시간 스트림**: Isar의 `watchLazy()` 활용한 반응형 UI
- ✅ **성능 최적화**: 스트림 캐싱, 배치 작업, 복합 인덱스 활용
- ✅ **메모리 효율성**: 자동 리소스 정리, 브로드캐스트 스트림
- ✅ **일관성 보장**: `NoteDbService` 연동으로 비즈니스 로직 일관성

### **확장 기능**
- 🔍 **고급 필터링**: 볼트별, 폴더별, PDF 기반 노트 필터링
- 📊 **통계 정보**: 노트 개수, 타입별 분류, 최근 활동 추적
- ⚡ **배치 작업**: 여러 노트 동시 처리로 성능 향상
- 🔄 **캐시 관리**: 수동 무효화, 강제 새로고침

## 🚀 사용 예제

### **기본 CRUD 작업**

```dart
// Repository 초기화
final repository = IsarNotesRepository(defaultVaultId: 1);

// 노트 생성
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

await repository.upsert(newNote);

// 노트 조회
final note = await repository.getNoteById('123');
if (note != null) {
  print('노트 제목: ${note.title}');
}

// 노트 삭제
await repository.delete('123');
```

### **실시간 데이터 관찰**

```dart
// 전체 노트 목록 실시간 관찰
repository.watchNotes().listen((notes) {
  print('총 ${notes.length}개의 노트');
  for (final note in notes) {
    print('- ${note.title} (${note.updatedAt})');
  }
});

// 특정 노트 실시간 관찰
repository.watchNoteById('123').listen((note) {
  if (note != null) {
    print('노트 업데이트: ${note.title}');
  } else {
    print('노트가 삭제되거나 존재하지 않음');
  }
});
```

### **고급 필터링과 검색**

```dart
// 특정 볼트의 노트들만 관찰
repository.watchNotesByVault(1).listen((notes) {
  print('볼트 1의 노트: ${notes.length}개');
});

// 특정 폴더의 노트들 관찰
repository.watchNotesByFolder(1, 5).listen((notes) {
  print('폴더 5의 노트: ${notes.length}개');
});

// 제목으로 검색
repository.searchNotesByTitle('회의').listen((notes) {
  print('회의 관련 노트: ${notes.map((n) => n.title).join(', ')}');
});

// PDF 기반 노트만 필터링
repository.watchPdfNotes().listen((pdfNotes) {
  print('PDF 노트: ${pdfNotes.length}개');
});

// 최근 수정된 노트 (상위 5개)
repository.watchRecentNotes(limit: 5).listen((recentNotes) {
  print('최근 노트들:');
  for (final note in recentNotes) {
    print('- ${note.title} (${note.updatedAt})');
  }
});
```

### **배치 작업으로 성능 최적화**

```dart
// 여러 노트 동시 업데이트
final notesToUpdate = [
  note1.copyWith(title: '수정된 제목 1'),
  note2.copyWith(title: '수정된 제목 2'),
  note3.copyWith(title: '수정된 제목 3'),
];

await repository.upsertBatch(notesToUpdate);

// 여러 노트 동시 삭제
await repository.deleteBatch(['123', '456', '789']);
```

### **통계 정보 조회**

```dart
final stats = await repository.getStatistics();
print('전체 노트: ${stats['total']}개');
print('PDF 기반: ${stats['pdf_based']}개');
print('빈 노트: ${stats['blank']}개');
print('최근 1주일: ${stats['recent_week']}개');
```

### **캐시 관리**

```dart
// 강제 새로고침
await repository.invalidateCache();

// Repository 상태 확인
if (repository.isInitialized) {
  print('Repository 초기화 완료');
  print('활성 스트림: ${repository.activeStreamCount}개');
}

// 리소스 정리
repository.dispose();
```

## 🔄 Riverpod 통합 예제

### **Provider 설정**

```dart
@riverpod
NotesRepository notesRepository(NotesRepositoryRef ref) {
  final repository = IsarNotesRepository(defaultVaultId: 1);
  
  // Provider가 dispose될 때 repository도 정리
  ref.onDispose(() {
    repository.dispose();
  });
  
  return repository;
}

@riverpod
Stream<List<NoteModel>> notes(NotesRef ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchNotes();
}

@riverpod
family
Stream<NoteModel?> note(NoteRef ref, String noteId) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchNoteById(noteId);
}
```

### **UI에서 사용**

```dart
class NotesListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);
    
    return notesAsync.when(
      data: (notes) => ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            title: Text(note.title),
            subtitle: Text('${note.pages.length}페이지'),
            trailing: Text(
              DateFormat('MM/dd HH:mm').format(note.updatedAt),
            ),
            onTap: () => _openNote(context, note.noteId),
          );
        },
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('오류: $error'),
    );
  }
}

class NoteEditorScreen extends ConsumerWidget {
  final String noteId;
  
  const NoteEditorScreen({required this.noteId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(noteProvider(noteId));
    
    return noteAsync.when(
      data: (note) {
        if (note == null) {
          return const Scaffold(
            body: Center(child: Text('노트를 찾을 수 없습니다')),
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
            ],
          ),
          body: NoteEditorWidget(note: note),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('오류: $error')),
      ),
    );
  }
  
  Future<void> _saveNote(WidgetRef ref, NoteModel note) async {
    final repository = ref.read(notesRepositoryProvider);
    
    try {
      await repository.upsert(note);
      // 성공 메시지 표시
    } catch (e) {
      // 오류 처리
    }
  }
}
```

## 📊 성능 최적화 팁

### **1. 스트림 구독 최소화**
```dart
// ❌ 나쁜 예: 매번 새로운 스트림 생성
Widget build(BuildContext context) {
  return StreamBuilder<List<NoteModel>>(
    stream: IsarNotesRepository().watchNotes(), // 매번 새 인스턴스!
    builder: (context, snapshot) => ...,
  );
}

// ✅ 좋은 예: Provider를 통한 싱글톤 사용
Widget build(BuildContext context, WidgetRef ref) {
  final notesAsync = ref.watch(notesProvider); // 캐시된 스트림
  return notesAsync.when(...);
}
```

### **2. 배치 작업 활용**
```dart
// ❌ 나쁜 예: 개별 처리
for (final note in notes) {
  await repository.upsert(note); // N번의 트랜잭션
}

// ✅ 좋은 예: 배치 처리
await repository.upsertBatch(notes); // 1번의 트랜잭션
```

### **3. 필터링 최적화**
```dart
// ❌ 나쁜 예: 클라이언트 사이드 필터링
repository.watchNotes()
  .map((notes) => notes.where((n) => n.title.contains(query)).toList());

// ✅ 좋은 예: 서버 사이드 필터링 (가능한 경우)
repository.searchNotesByTitle(query);
```

## 🧪 테스트 전략

### **Mock Repository 구현**

```dart
class MockNotesRepository implements NotesRepository {
  final List<NoteModel> _notes = [];
  final StreamController<List<NoteModel>> _controller = 
      StreamController<List<NoteModel>>.broadcast();

  @override
  Stream<List<NoteModel>> watchNotes() => _controller.stream;

  @override
  Future<void> upsert(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.noteId == note.noteId);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note.copyWith(
        noteId: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    }
    _controller.add(List.from(_notes));
  }

  @override
  Future<void> delete(String noteId) async {
    _notes.removeWhere((n) => n.noteId == noteId);
    _controller.add(List.from(_notes));
  }

  // ... 기타 메서드들
}
```

### **단위 테스트**

```dart
void main() {
  group('NotesRepository', () {
    late MockNotesRepository repository;

    setUp(() {
      repository = MockNotesRepository();
    });

    testWidgets('노트 생성 후 목록에 포함되는지 확인', (tester) async {
      final note = NoteModel(
        noteId: '',
        title: '테스트 노트',
        pages: [],
      );

      await repository.upsert(note);
      
      final notes = await repository.watchNotes().first;
      expect(notes.length, 1);
      expect(notes.first.title, '테스트 노트');
    });

    testWidgets('노트 삭제 후 목록에서 제거되는지 확인', (tester) async {
      // 테스트 로직...
    });
  });
}
```

## 🔮 향후 개선 계획

### **1. 고급 쿼리 지원**
- 복합 조건 검색 (제목 + 내용 + 태그)
- 정렬 옵션 (제목, 생성일, 수정일, 크기)
- 페이지네이션 지원

### **2. 오프라인 동기화**
- 변경 사항 추적 (dirty flag)
- 충돌 해결 전략
- 백그라운드 동기화

### **3. 성능 모니터링**
- 쿼리 실행 시간 측정
- 메모리 사용량 추적
- 병목 지점 분석

### **4. 캐싱 전략**
- 자주 접근하는 노트 메모리 캐싱
- 썸네일 이미지 캐싱
- 검색 결과 캐싱

---

**🎉 결론**: `IsarNotesRepository`는 Repository 패턴의 모든 장점을 활용하여 견고하고 확장 가능한 데이터 접근 계층을 제공합니다. 실시간 반응성, 성능 최적화, 테스트 용이성을 모두 갖춘 엔터프라이즈급 구현체입니다.
