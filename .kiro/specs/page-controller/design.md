# Design Document

## Overview

페이지 컨트롤러는 노트 내부에서 페이지를 시각적으로 관리할 수 있는 기능입니다. 사용자는 페이지 썸네일을 통해 페이지를 식별하고, 드래그 앤 드롭으로 순서를 변경하며, 페이지를 추가하거나 삭제할 수 있습니다.

이 기능은 현재의 Repository 패턴을 유지하면서 향후 Isar DB 도입에 대비한 확장 가능한 구조로 설계됩니다. 기존의 `FileStorageService`, `NoteService` 패턴을 따라 새로운 서비스들을 추가하여 기능을 구현합니다.

## Architecture

### Repository 패턴 확장 전략

현재 `NotesRepository`는 기본적인 CRUD 작업만 담당하고 있습니다. 페이지 컨트롤러 기능을 위해 Repository를 확장할 때, 다음 원칙을 따릅니다:

**Repository에 추가할 메서드들 (데이터 영속성 관련):**

- 페이지 순서 변경 (배치 업데이트)
- 페이지 추가/삭제 (트랜잭션 처리)
- 썸네일 메타데이터 저장/조회

**Service 레이어에서 처리할 기능들 (비즈니스 로직):**

- 썸네일 이미지 생성 및 렌더링
- 파일 시스템 캐시 관리
- UI 상태 관리

### 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
├─────────────────────────────────────────────────────────────┤
│ PageControllerScreen (Modal/Dialog)                         │
│ ├── PageThumbnailGrid                                       │
│ ├── DraggablePageThumbnail                                  │
│ ├── PageControllerAppBar                                    │
│ └── PageActionButtons                                       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
├─────────────────────────────────────────────────────────────┤
│ PageControllerProvider (Riverpod)                           │
│ ├── PageThumbnailService (렌더링 + 파일 캐시)                │
│ ├── PageOrderService (비즈니스 로직)                         │
│ └── PageManagementService (비즈니스 로직)                    │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
├─────────────────────────────────────────────────────────────┤
│ NotesRepository (확장) ← 페이지 관리 메서드 추가              │
│ ├── 기존: watchNotes, getNoteById, upsert, delete          │
│ └── 신규: batchUpdatePages, reorderPages, 썸네일 메타데이터  │
│                                                             │
│ FileStorageService (기존) ← 썸네일 캐시 디렉토리 관리        │
│ NoteService (기존)                                           │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Repository 확장

기존 `NotesRepository`에 페이지 관리 메서드들을 추가합니다:

```dart
abstract class NotesRepository {
  // 기존 메서드들...
  Stream<List<NoteModel>> watchNotes();
  Stream<NoteModel?> watchNoteById(String noteId);
  Future<NoteModel?> getNoteById(String noteId);
  Future<void> upsert(NoteModel note);
  Future<void> delete(String noteId);

  // 페이지 컨트롤러를 위한 새로운 메서드들

  /// 페이지 순서를 변경합니다 (배치 업데이트)
  Future<void> reorderPages(String noteId, List<NotePageModel> reorderedPages);

  /// 페이지를 추가합니다
  Future<void> addPage(String noteId, NotePageModel newPage, {int? insertIndex});

  /// 페이지를 삭제합니다
  Future<void> deletePage(String noteId, String pageId);

  /// 여러 페이지를 배치로 업데이트합니다 (Isar DB 최적화용)
  Future<void> batchUpdatePages(String noteId, List<NotePageModel> pages);

  /// 썸네일 메타데이터를 저장합니다 (향후 Isar DB에서 활용)
  Future<void> updateThumbnailMetadata(String pageId, ThumbnailMetadata metadata);

  /// 썸네일 메타데이터를 조회합니다
  Future<ThumbnailMetadata?> getThumbnailMetadata(String pageId);
}
```

**메모리 구현체 vs Isar DB 구현체:**

- **메모리 구현체**: 단순히 리스트 조작 후 전체 노트 업데이트
- **Isar DB 구현체**: 트랜잭션과 인덱스를 활용한 최적화된 배치 처리

### 2. PageThumbnailService (비즈니스 로직)

썸네일 렌더링과 파일 캐시를 담당하는 서비스입니다:

```dart
class PageThumbnailService {
  // 썸네일 렌더링 (순수 비즈니스 로직)
  static Future<Uint8List?> generateThumbnail(NotePageModel page);

  // 파일 시스템 캐시 관리
  static Future<Uint8List?> getCachedThumbnail(String pageId);
  static Future<void> cacheThumbnailToFile(String pageId, Uint8List thumbnail);
  static Future<void> invalidateFileCache(String pageId);

  // Repository를 통한 메타데이터 관리
  static Future<void> updateThumbnailMetadata(
    String pageId,
    ThumbnailMetadata metadata,
    NotesRepository repo
  );
}
```

**구현 세부사항:**

- 썸네일 렌더링: Service에서 처리 (구현체 무관)
- 파일 캐시: FileStorageService 활용 (구현체 무관)
- 메타데이터: Repository를 통해 저장 (구현체별 최적화)

### 3. PageOrderService (비즈니스 로직)

페이지 순서 변경 로직을 담당합니다:

```dart
class PageOrderService {
  // 순서 변경 비즈니스 로직
  static List<NotePageModel> reorderPages(
    List<NotePageModel> pages,
    int fromIndex,
    int toIndex
  );

  // 페이지 번호 재매핑
  static List<NotePageModel> remapPageNumbers(List<NotePageModel> pages);

  // Repository를 통한 영속화
  static Future<void> saveReorderedPages(
    String noteId,
    List<NotePageModel> reorderedPages,
    NotesRepository repo
  );

  // 유효성 검사
  static bool validateReorder(List<NotePageModel> pages, int from, int to);
}
```

### 4. PageManagementService (비즈니스 로직)

페이지 추가/삭제 로직을 담당합니다:

```dart
class PageManagementService {
  // 페이지 생성 로직 (NoteService 활용)
  static Future<NotePageModel> createBlankPage(String noteId, int pageNumber);
  static Future<NotePageModel> createPdfPage(String noteId, int pageNumber, int pdfPageNumber);

  // Repository를 통한 페이지 추가/삭제
  static Future<void> addPage(
    String noteId,
    NotePageModel newPage,
    NotesRepository repo,
    {int? insertIndex}
  );

  static Future<void> deletePage(
    String noteId,
    String pageId,
    NotesRepository repo
  );

  // 비즈니스 로직
  static bool canDeletePage(NoteModel note, String pageId);
  static Future<List<int>> getAvailablePdfPages(String noteId);
  static Future<List<int>> getAvailablePdfPages(String noteId);

  // 페이지 삭제 유효성 검사 (마지막 페이지 보호)
  static bool canDeletePage(NoteModel note, String pageId);
}
```

**구현 세부사항:**

- 페이지 추가 시 자동으로 적절한 `pageNumber` 할당
- 페이지 삭제 시 관련 썸네일 캐시 정리
- 마지막 페이지 삭제 방지 로직

### 4. ThumbnailCacheService

썸네일 캐시 관리를 담당하는 서비스입니다.

```dart
class ThumbnailCacheService {
  // 캐시 디렉토리 경로 관리
  static Future<String> getThumbnailCacheDir(String noteId);

  // 캐시 파일 경로 생성
  static Future<String> getThumbnailPath(String noteId, String pageId);

  // 캐시 정리 (특정 노트)
  static Future<void> clearNoteCache(String noteId);

  // 캐시 정리 (전체)
  static Future<void> clearAllCache();

  // 캐시 크기 확인
  static Future<int> getCacheSize(String noteId);

  // 오래된 캐시 정리
  static Future<void> cleanupOldCache({Duration maxAge = const Duration(days: 30)});
}
```

### 5. UI Components

#### PageControllerScreen

```dart
class PageControllerScreen extends ConsumerWidget {
  final String noteId;

  // 모달 다이얼로그로 표시
  static Future<void> show(BuildContext context, String noteId);
}
```

#### PageThumbnailGrid

```dart
class PageThumbnailGrid extends ConsumerWidget {
  // 그리드 형태로 썸네일 표시
  // 드래그 앤 드롭 지원
  // 지연 로딩 지원
}
```

#### DraggablePageThumbnail

```dart
class DraggablePageThumbnail extends StatefulWidget {
  final NotePageModel page;
  final Uint8List? thumbnail;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  // 드래그 가능한 썸네일 위젯
  // 길게 누르기로 드래그 모드 활성화
  // 삭제 버튼 오버레이
}
```

## Data Models

### ThumbnailMetadata

```dart
class ThumbnailMetadata {
  final String pageId;
  final String cachePath;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int fileSizeBytes;
  final String checksum; // 페이지 내용 변경 감지용

  // 썸네일 메타데이터 (Repository에 저장)
}
```

### PageReorderOperation

```dart
class PageReorderOperation {
  final String noteId;
  final int fromIndex;
  final int toIndex;
  final List<NotePageModel> originalPages;
  final List<NotePageModel> reorderedPages;

  // 순서 변경 작업 정보 (롤백용)
}
```

## Error Handling

### 1. 썸네일 생성 실패

- 기본 플레이스홀더 이미지 표시
- 백그라운드에서 재시도 메커니즘
- 사용자에게 오류 상태 표시

### 2. 페이지 순서 변경 실패

- 이전 상태로 즉시 롤백
- 사용자에게 명확한 오류 메시지 표시
- 재시도 옵션 제공

### 3. 페이지 추가/삭제 실패

- 트랜잭션 롤백
- 파일 시스템 정합성 확인
- 오류 로그 기록

### 4. 캐시 관련 오류

- 캐시 실패 시 실시간 생성으로 대체
- 디스크 공간 부족 시 오래된 캐시 정리
- 메모리 부족 시 우아한 성능 저하

## Testing Strategy

### 1. Unit Tests

- **PageThumbnailService**: 썸네일 생성 로직
- **PageOrderService**: 순서 변경 및 인덱스 재매핑
- **PageManagementService**: 페이지 추가/삭제 로직
- **ThumbnailCacheService**: 캐시 관리 로직

### 2. Widget Tests

- **PageControllerScreen**: 모달 표시 및 기본 UI
- **PageThumbnailGrid**: 그리드 레이아웃 및 스크롤
- **DraggablePageThumbnail**: 드래그 앤 드롭 동작

### 3. Integration Tests

- 전체 페이지 컨트롤러 워크플로우
- 대량 페이지 처리 성능
- 메모리 사용량 모니터링

### 4. Performance Tests

- 썸네일 생성 속도 측정
- 캐시 효율성 검증
- UI 반응성 테스트

## Isar DB 대비 확장성 고려사항

### 1. Repository 패턴 확장 전략

**현재 메모리 구현체에서의 처리:**

```dart
class MemoryNotesRepository implements NotesRepository {
  // 페이지 순서 변경 - 단순 리스트 조작
  Future<void> reorderPages(String noteId, List<NotePageModel> reorderedPages) async {
    final note = await getNoteById(noteId);
    if (note != null) {
      final updatedNote = note.copyWith(pages: reorderedPages);
      await upsert(updatedNote);
    }
  }

  // 썸네일 메타데이터 - 메모리 맵에 저장
  final Map<String, ThumbnailMetadata> _thumbnailMetadata = {};

  Future<void> updateThumbnailMetadata(String pageId, ThumbnailMetadata metadata) async {
    _thumbnailMetadata[pageId] = metadata;
  }
}
```

**향후 Isar DB 구현체에서의 최적화:**

```dart
class IsarNotesRepository implements NotesRepository {
  // 페이지 순서 변경 - 트랜잭션과 배치 업데이트
  Future<void> reorderPages(String noteId, List<NotePageModel> reorderedPages) async {
    await isar.writeTxn(() async {
      // 기존 페이지들 삭제
      await isar.notePageModels.filter().noteIdEqualTo(noteId).deleteAll();
      // 새 순서로 배치 삽입
      await isar.notePageModels.putAll(reorderedPages);
    });
  }

  // 썸네일 메타데이터 - 별도 컬렉션으로 관리
  Future<void> updateThumbnailMetadata(String pageId, ThumbnailMetadata metadata) async {
    await isar.writeTxn(() async {
      await isar.thumbnailMetadatas.put(metadata);
    });
  }
}
```

### 2. 데이터 모델 확장 준비

**현재 모델에 Isar 어노테이션 준비:**

```dart
// 향후 Isar DB 도입 시 활용할 어노테이션들
class NotePageModel {
  @Index()
  final String noteId;

  @Index()
  final int pageNumber;

  @Index()
  final DateTime updatedAt;

  // 현재는 무시되지만 향후 활용
}

// 새로운 썸네일 메타데이터 모델
@Collection()
class ThumbnailMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final String pageId;

  final String cachePath;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int fileSizeBytes;
  final String checksum;
}
```

### 3. 성능 최적화 전략

**배치 처리 지원:**

```dart
// 현재 (메모리 기반) - 단건 처리
for (final page in pages) {
  await repo.updateThumbnailMetadata(page.pageId, metadata);
}

// 향후 (Isar DB) - 배치 처리
await repo.batchUpdateThumbnailMetadata(metadataList);
```

**쿼리 최적화:**

```dart
// 현재 - 전체 노트 로드 후 필터링
final note = await repo.getNoteById(noteId);
final pdfPages = note.pages.where((p) => p.backgroundType == PageBackgroundType.pdf);

// 향후 - 인덱스 활용한 직접 쿼리
final pdfPages = await repo.getPdfPagesByNoteId(noteId);
```

## Performance Optimizations

### 1. 썸네일 생성 최적화

- 백그라운드 스레드에서 생성
- 지연 로딩으로 필요한 썸네일만 생성
- 적응형 품질 조정 (메모리 상황에 따라)

### 2. 캐시 전략

- LRU 캐시로 메모리 사용량 제한
- 디스크 캐시와 메모리 캐시 이중 구조
- 캐시 워밍업 (자주 사용되는 썸네일 미리 로드)

### 3. UI 최적화

- 가상화된 그리드 뷰 (대량 페이지 지원)
- 썸네일 로딩 중 스켈레톤 UI
- 드래그 앤 드롭 시 하드웨어 가속 활용

### 4. 메모리 관리

- 썸네일 이미지 자동 해제
- 백그라운드 앱 전환 시 캐시 정리
- 메모리 압박 상황 감지 및 대응

## Security Considerations

### 1. 파일 시스템 보안

- 앱 내부 디렉토리만 사용
- 파일 권한 적절히 설정
- 임시 파일 자동 정리

### 2. 데이터 무결성

- 페이지 순서 변경 시 원자적 업데이트
- 파일 시스템과 데이터베이스 동기화
- 손상된 썸네일 감지 및 복구

### 3. 리소스 보호

- 썸네일 생성 시 메모리 제한
- 동시 작업 수 제한
- 무한 루프 방지 메커니즘
