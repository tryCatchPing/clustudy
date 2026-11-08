# Isar DB 도입 가이드 (유의점/베스트 프랙티스)

본 문서는 메모리 구현에서 Isar 기반 영속 저장으로 전환 시 지켜야 할 유의점과 권장 패턴을 정리합니다. 목표는 “원자성(트랜잭션) + 일관성(워처 커밋 스냅샷) + 성능(인덱스/배치)”을 확보하는 것입니다.

## 목표/범위

- 대상: NotesRepository, VaultTreeRepository(배치 트리), LinkRepository(링크), 부가 메타(썸네일 등)
- 의존: `DbTxnRunner` 추상화 기반의 서비스 레벨 트랜잭션 경계
- 비범위: 파일 I/O(별도 서비스), UI 라우팅/위젯

## 트랜잭션/유닛 오브 워크

- 단일 writeTxn: 서비스에서 여러 레포 변경(노트/링크/트리)을 하나의 `isar.writeTxn`으로 묶음
- 중첩 금지: 레포 내부에서 추가 `writeTxn`을 열지 말고, 서비스가 전달한 경계 내에서만 변경 수행
- 파일 I/O 분리: 파일 삭제/이동은 트랜잭션 밖에서 처리(커밋 후). 무거운 I/O로 트랜잭션 시간을 늘리지 않기 위함
- 실행 시간: writeTxn 안에서는 CPU/I/O 무거운 작업(썸네일 생성, PDF 렌더 등) 금지 → 외부에서 준비/정리

### DbTxnRunner 패턴

- 인터페이스: `Future<T> write<T>(Future<T> Function() action)`
- 메모리: no-op 실행
- Isar: `isar.writeTxn(() async => await action())`
- 주입: Provider로 DI하고 Isar 도입 시 override

## 스키마 설계 가이드

- 컬렉션(권장)
  - Vault(vaultId, name, createdAt, updatedAt)
  - Folder(folderId, vaultId, name, parentFolderId?, timestamps)
  - NotePlacement(noteId, vaultId, parentFolderId?, name, timestamps)
  - Note(noteId, title, sourceType, sourcePdfPath?, totalPdfPages?, timestamps)
  - NotePage(pageId, noteId, pageNumber, jsonData, background*, thumbnails*)
  - Link(id, sourcePageId, targetNoteId, bbox\*, timestamps)
  - ThumbnailMetadata(pageId → metadata) [선택]
- 식별자
  - 현재 모델의 String ID(UUID)를 그대로 사용(플랫폼 간 직렬화/교체 용이)
  - Isar 내부 자동 id는 선택. 필요 시 보조 인덱스로 사용
- 인덱스/유일성
  - Folder: (vaultId, parentFolderId, nameKey) 복합 인덱스
  - NotePlacement: (vaultId, parentFolderId, nameKey) 복합 인덱스
  - Link: sourcePageId, targetNoteId 인덱스
  - 이름 비교 키(nameKey): `NameNormalizer.compareKey(name)` 저장 필드 추가 권장(케이스 비구분 정렬/중복 검사 용이)
  - 유일성은 트랜잭션 내부에서 선조회+검증으로 보장(충돌 시 도메인 예외)
- 페이지 모델링
  - 옵션 A: Note에 IsarList<Page> 임베딩 → 단일 노트 단위 CRUD는 간단, 개별 페이지 쿼리/인덱싱은 불리
  - 옵션 B: Page를 별도 컬렉션 → 페이지별 인덱싱/검색/배치 업데이트 유리(현재 `batchUpdatePages`와 상응)
  - 현재 인터페이스는 B에 친화적임(배치 업데이트/개별 페이지 JSON 업데이트 등)

## 워처/스트림 전략

- 커밋 기반 방출: Isar 워처는 커밋 시점에만 반영 → 중간 상태 비노출 자연 보장
- 쿼리 워처 사용: vaultId/parentFolderId 조건으로 Folder/NotePlacement 리스트를 watch
- 과도한 방출 방지: 동일 커밋 내 여러 변경이라도 단일 스냅샷이 전달됨. 추가 디바운스는 필요 시 적용

## 동시성/락

- 서비스 레벨 per‑vault 직렬화 권장(긴락 금지, 빠른 트랜잭션)
- Isar는 단일 writer 정책: writeTxn 경쟁을 어플리케이션 레벨에서 큐잉/재시도로 보완
- 재진입 방지: 서비스에서 하나의 트랜잭션 동안 동일 vault에 대한 추가 write 호출 금지(설계로 예방)

## 데이터 무결성(불변식)

- 동일 부모 범위 이름 유일성(케이스 비구분, `nameKey`)
- 폴더 사이클 금지
- cross‑vault 링크 금지
- NotePlacement ↔ NoteModel 존재 관계: 생성/삭제는 트랜잭션 한 번에 처리

## 삭제/캐스케이드

- 대량 삭제는 구간화: 너무 큰 캐스케이드는 여러 writeTxn으로 나누어 진행(UX로 진행률/취소 제공)
- 링크 정리: `deleteBySourcePages(pages)` + `deleteByTargetNote(noteId)` 조합, 인덱스로 O(n) 삭제
- 파일 삭제: 커밋 이후 별도 비동기로 처리(실패 시 재시도 가능 UI 제공)
- Tombstone(선택): 장시간 삭제 시 UI에 “삭제 중” 표시를 원하면 플래그 필드를 두고 커밋→파일 정리→최종 제거 순서 적용

## 성능/최적화

- 배치 쓰기: `isar.writeTxn(() async { collection.putAll(objs); })`
- 인덱스 설계: 목록 화면/검색/삭제 경로에 맞춘 인덱스만 유지(불필요한 인덱스는 쓰기 성능 저하)
- 읽기 경량화: 리스트 화면은 Folder/NotePlacement만 구독(콘텐츠는 필요 시 단건 조회)

## 오류 모델/예외 매핑

- 레포/DB 예외 → 서비스 도메인 예외로 변환: `NameConflict`, `CycleDetected`, `NotFound`, `ConcurrencyConflict` 등
- 재시도 가능 오류 분류: 락 경합/트랜잭션 충돌은 재시도 권장(백오프)
- 사용자 메시지 코드 부여(국제화/UX 표준화)

## 마이그레이션 전략(메모리 → Isar)

1. 스키마/엔티티 정의(@collection, 인덱스)
2. Isar 레포 구현 추가(`IsarNotesRepository`, `IsarVaultTreeRepository`, `IsarLinkRepository`)
3. `dbTxnRunnerProvider` override로 Isar 구현 주입
4. 앱 구성에서 providers override로 메모리 → Isar 스위칭(피처 플래그/환경설정)
5. 기능 단위 검증: 생성/이동/이름변경/삭제/캐스케이드/링크·백링크/워처 동작
6. 성능 점검: 대량 삭제/검색/리스트 정렬, 트랜잭션 시간/락 경합

## 테스트 체크리스트

- 트랜잭션 원자성: 생성/삭제/이름변경/이동이 부분 상태 없이 커밋됨
- 워처: 커밋 이후 단일 스냅샷만 방출(중간 상태 미노출)
- 동시성: 동일 폴더 동시 rename/move 충돌 시 한쪽 실패/재시도
- 링크 캐스케이드: 1k/10k 링크 삭제 시간/메모리
- 회귀: 이름 정규화 유틸과 nameKey 일치성(정렬/중복 검사)

## 샘플: DbTxnRunner(Isar) & Provider override (개요)

```dart
class IsarDbTxnRunner implements DbTxnRunner {
  IsarDbTxnRunner(this.isar);
  final Isar isar;
  @override
  Future<T> write<T>(Future<T> Function() action) => isar.writeTxn(action);
}

final dbTxnRunnerProvider = Provider<DbTxnRunner>((ref) {
  final isar = ref.watch(isarInstanceProvider);
  return IsarDbTxnRunner(isar);
});

// 앱 부트스트랩에서
runApp(ProviderScope(
  overrides: [
    notesRepositoryProvider.overrideWith((ref) => IsarNotesRepository(ref)),
    vaultTreeRepositoryProvider.overrideWith((ref) => IsarVaultTreeRepository(ref)),
    linkRepositoryProvider.overrideWith((ref) => IsarLinkRepository(ref)),
    dbTxnRunnerProvider.overrideWith((ref) => IsarDbTxnRunner(ref.watch(isarInstanceProvider))),
  ],
  child: App(),
));
```

## 요약 권고안

- 서비스 레벨 트랜잭션 경계(이미 `DbTxnRunner`로 준비)
- nameKey 필드/인덱스로 케이스 비구분 유일성·정렬 보장
- 링크 인덱스(sourcePageId/targetNoteId)와 배치 삭제 API 구현
- 파일 I/O는 커밋 이후 비동기 처리(장시간 작업 분리)
- 과도한 스키마/인덱스는 지양하고 실제 쿼리 경로 기준으로 최소화
