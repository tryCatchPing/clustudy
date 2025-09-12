# VaultNotesService 설계 (오케스트레이션 서비스)

본 문서는 VaultTreeRepository(트리/배치)와 NotesRepository(콘텐츠), LinkRepository(링크)를 하나의 유스케이스로 묶어 일관성 있게 처리하는 상위 서비스(VaultNotesService)의 기능, 내부 로직, 근거/예상 결과를 정의합니다.

- 목적: 트리/콘텐츠 분리를 유지하면서도 생성/이동/이름변경/삭제를 원자적으로 처리하고, 중간 상태 노출을 방지
- 범위: 노트 생성/삭제/이동/이름변경, 폴더 캐스케이드 삭제, 배치 조회 유틸
- 비범위: UI, 라우팅, 위젯. 서비스는 레포지토리를 호출하는 애플리케이션 계층입니다.

## 의존성

- VaultTreeRepository: Vault/Folder/NotePlacement(배치) 관리
- NotesRepository: NoteModel(콘텐츠) CRUD, 페이지 추가/삭제/재정렬/JSON 업데이트
- LinkRepository: 링크 생성/수정/삭제, 페이지별/노트별 스트림
- NoteService: NoteModel 생성 유틸(빈/PDF)
- FileStorageService: 파일(I/O) 삭제/정리

## 트랜잭션/일관성 전략

- 단기(메모리 구현):
  - per-vault 직렬화(Mutex)로 동시 변경 충돌 방지. 서비스 진입 시
    단일 락을 획득하고, 서비스 종료(성공/실패/보상 완료) 시 해제.
    레포 내부에서 재진입하지 않도록 설계(재귀/중첩 호출 금지).
  - 보상(Saga)로 실패 시 역연산 수행(예: 등록 취소/원복/재시도 큐).
    각 단계는 멱등적으로 설계하고, 영속 작업 로그에 기록.
  - emit 타이밍: 모든 단계가 성공해 ‘커밋’된 이후에만 단일 커밋 이벤트를
    방출. 서비스는 이벤트를 버퍼링하고 커밋 토큰과 함께 일괄 방출.
- 장기(Isar 도입 후):
  - 두 레포(트리/콘텐츠/링크)가 동일 트랜잭션(Unit of Work)으로 커밋.
    파일 I/O는 트랜잭션 밖에서 tombstone을 활용한 지연/확정 삭제로 처리.
  - 워처는 커밋 훅에서 단일 스냅샷을 생성해 반영(커밋 토큰 기반).

### 이벤트 배치/커밋 모델

- 서비스는 변경 중간 상태를 방출하지 않음. 각 레포 변경은 내부 버퍼에
  축적 후, 모든 변경이 성공하면 `commitToken`을 생성하고 단일 이벤트로
  방출.
- 구독자는 `commitToken` 경계만 관찰하여 중간 상태 노출을 방지.

### 운영 내구성(작업 로그)

- 영속 작업 로그(Job Log) 저장: `operationId`, `vaultId`, `type`,
  `status(pending|running|compensating|done|failed)`, `step`, `retryCount`,
  `lastError`, `nextAttemptAt`, `startedAt/endedAt`.
- 앱 시작 시 미완 작업을 재개/정리. 모든 단계는 멱등적이어야 함.

## 이름/중복/표시명 정책

- 표시명의 소스: 트리(배치)의 `name`이 진실값. 콘텐츠 `NoteModel.title`은
  미러(표시 편의).
- 정규화/중복 검사: 트리 책임. 동일 부모 폴더 내 케이스 비구분 중복 금지
  (현재 구현: `_ensureUniqueNoteName`).
- 이름 정규화 스펙(공통 유틸):
  - Unicode NFKC 정규화, 앞뒤 공백 제거, 연속 공백 단일화.
  - 로케일 독립 casefold(케이스 비구분 비교 일관화).
  - 금지 문자/예약어 차단(`/:\\?*"<>|`, 제어문자, `.`/`..`, 플랫폼 예약어).
  - 최대 길이 제한(예: 120자, UI/파일시스템 고려).
  - 빈 이름 방지: 기본 이름 생성 규칙 적용.
  - 모든 생성/이름변경/이동에 동일 유틸 적용(테스트 포함).

## 공개 API (초안)

서명은 가이드이며, 필요 시 파라미터/반환 타입을 조정할 수 있습니다.

### createBlankInFolder(vaultId, {parentFolderId?, name?}) → Future<NoteModel>

- 목적: 현재 폴더에 빈 노트 생성(콘텐츠+배치 동시 생성)
- 내부 로직(권장 순서: 이름 확정 → 콘텐츠 → 배치 등록 → 업서트 → 커밋)
  1. 입력 검증: vault/folder 존재 및 동일 vault 확인(VaultTree).
  2. 이름 결정: 입력값을 이름 정규화 유틸로 확정. 없으면 기본 제목 생성.
  3. 콘텐츠 생성: `NoteService.createBlankNote(title?, initialPageCount=1)`
     → NoteModel(Notes).
  4. 배치 등록: `vaultTree.registerExistingNote(noteId, vaultId,
parentFolderId, normalizedName)`. - 이유: noteId는 콘텐츠가 생성, “기존 ID 등록”이 자연스러움. - 실패 시 보상: 멱등 `NotesRepository.delete(noteId)` 및 임시 파일 정리.
  5. 콘텐츠 업서트: `NotesRepository.upsert(note)`.
  6. 커밋 이벤트: 서비스가 단일 커밋 이벤트를 방출.
- 근거/이유: 트리 이름 정책을 적용한 후 ID 충돌/중복을 트리에서 차단, 콘텐츠와 배치를 분명히 구분
- 예상 결과: 폴더 목록에 새 노트가 나타나고, 에디터로 즉시 진입 가능

### createPdfInFolder(vaultId, {parentFolderId?, name?}) → Future<NoteModel>

- 목적: PDF에서 노트 생성(사전 렌더링/메타 포함)
- 내부 로직(백그라운드/취소/임시 디렉터리 고려)
  1. 입력 검증: vault/folder 일치 확인(VaultTree), 이름 정규화.
  2. PDF 처리: 백그라운드 isolate에서 `NoteService.createPdfNote(title?)`
     → NoteModel(페이지/메타 포함). 진행률/취소 토큰 지원.
     - 산출물은 임시 디렉터리에 생성, 커밋 시 최종 위치로 이동.
  3. 배치 등록: `vaultTree.registerExistingNote(noteId, vaultId,
parentFolderId, normalizedName or note.title)`.
  4. 콘텐츠 업서트: `NotesRepository.upsert(note)`.
  5. 실패 보상: 임시 산출물 정리, 노트 삭제 멱등 처리.
  6. 커밋 이벤트: 단일 커밋 이벤트 방출.
- 예상 결과: PDF 페이지 이미지/메타가 포함된 노트가 생성되어 브라우저/에디터에 반영

### renameNote(noteId, newName) → Future<void>

- 목적: 노트 표시명 변경(트리) + 콘텐츠 제목 동기화
- 내부 로직
  1. 이름 정규화: 새 이름을 공통 유틸로 정규화.
  2. 트리 변경: `vaultTree.renameNote(noteId, normalizedName)`
     - 동일 부모 폴더 스코프의 중복 차단.
  3. 콘텐츠 동기화: `NotesRepository.getNoteById(noteId)` → 존재 시
     `upsert(note.copyWith(title: normalizedName))`.
     - 실패 시 작업 로그에 등록 후 백그라운드 재시도. UI는 트리 이름 우선.
  4. 커밋 이벤트 방출.
- 이유: 표시명 진실값은 트리, 콘텐츠 제목은 미러이므로 트리 성공 후 콘텐츠를 동기화
- 예상 결과: 브라우저/에디터 제목 모두 변경, 트리 기준 정렬 반영

### moveNote(noteId, {newParentFolderId?}) → Future<void>

- 목적: 노트를 동일 vault 내 다른 폴더로 이동
- 내부 로직(적용 직전 재검증 포함)
  1. 이동 검증: 사이클/동일 vault 확인 및 대상 폴더 존재 확인(VaultTree).
  2. 중복 검사: 대상 폴더 스코프에서 현재 이름 중복 금지.
  3. 적용 직전 재검증: 레이스 조건 방지 위해 한 번 더 중복/존재 검증.
  4. 이동 수행: `vaultTree.moveNote(noteId, newParentFolderId)`.
  5. 콘텐츠 변경 없음. 커밋 이벤트 방출.
- 이유: 배치 책임만 변경. 콘텐츠는 폴더 경로에 의존하지 않음
- 예상 결과: 브라우저 목록 재정렬/재배치, 에디터 URL/세션은 영향 없음

### deleteNote(noteId) → Future<void>

- 목적: 노트를 완전히 제거(링크/파일/콘텐츠/배치 순)
- 내부 로직(권장 순서: tombstone → 링크 → 파일 → 콘텐츠 → 배치 → 커밋) 0. tombstone: `vaultTree.markNoteDeleting(noteId)`로 삭제 진행 상태 표시.
  - UI는 선택/편집을 차단하고 ‘삭제 중’으로 표시.
  1. 배치 조회: `getPlacement(noteId)`로 컨텍스트 확보(VaultTree).
  2. 링크 정리: 대량 처리를 위해
     - Outgoing: `LinkRepository.deleteBySourceNote(noteId)` 권장.
       (없다면 `deleteBySourcePages(pageIds)`를 배치/스트리밍으로 처리)
     - Incoming: `LinkRepository.deleteByTargetNote(noteId)`.
  3. 파일 정리: `FileStorageService.deleteNoteFiles(noteId)`.
  4. 콘텐츠 삭제: `NotesRepository.delete(noteId)`.
  5. 배치 삭제: `vaultTree.deleteNote(noteId)`.
  6. 커밋 이벤트 방출.
  7. 실패 보상: 작업 로그에 기록하고 단계별 재시도. tombstone은 완료 시 제거.
- 이유: 링크/파일 dangling 방지, UI에는 트리 삭제가 마지막이므로 중간상태 노출 최소화
- 예상 결과: 브라우저/백링크 패널/에디터에서 해당 노트가 사라짐

### deleteFolderCascade(folderId) → Future<void>

- 목적: 폴더와 그 하위 모든 노트/폴더를 안전하게 삭제
- 내부 로직(대규모 vault를 고려한 배치/스트리밍)
  1. 하위 노트 수집: VaultTree에서 스트리밍 DFS/페이지네이션으로 수집.
     메모리 폭주 방지. 중간 체크포인트 기록.
  2. 영향 요약: 노트/링크 개수/추정 용량 등 UI 확인 모달용 데이터 생성.
  3. 노트 삭제: `deleteNote`를 배치로 실행(진행률/취소 지원, 재개 가능).
  4. 폴더 삭제: 모든 하위 노트 삭제 후 `vaultTree.deleteFolder(folderId)`.
  5. 커밋 이벤트 방출.
- 이유: 먼저 배치 삭제를 호출하면 콘텐츠/링크 dangling 위험. 콘텐츠→배치 순으로 정리해야 안전
- 예상 결과: 폴더 트리 및 관련 데이터가 일관되게 제거됨

### getPlacement(noteId) → Future<NotePlacement?>

- 목적: 배치 컨텍스트 조회(검증/표시/링크 정책에 활용)
- 내부 로직: `vaultTree.getNotePlacement(noteId)` 그대로 위임
- 활용 예: 링크 생성 시 source/target의 vaultId 비교로 cross‑vault 차단

### (옵션) searchNotesInVault(vaultId, query) → Future<List<NotePlacement>>

- 목적: 링크 다이얼로그에서 “현 vault 내” 제목 검색
- 내부 로직: 트리에서 노트만 필터링 후 이름 매칭(케이스 비구분)
- 이유: 브라우저/링크 UI는 트리 기준으로 동작해야 경계가 명확

## 보상(Saga) 시나리오 요약

- 생성(create): 배치 등록 실패 → 생성된 NoteModel 삭제(멱등). 콘텐츠 실패
  → 배치 예약 취소. 작업 로그에 상태/오류 기록.
- 삭제(delete): 링크/파일/콘텐츠 중간 실패 → 작업 로그 기반 재시도.
  최종적으로 배치 삭제까지 완료. tombstone으로 UI 중간 상태 관리.
- 이름변경(rename): 트리 성공 후 콘텐츠 동기화 실패 → 작업 로그로 백그라운드
  재시도. 트리 이름을 우선 표시.
- 모든 단계는 멱등키(노트 ID/스텝)로 중복 실행 안전.

## 에러 처리/락 범위

- 락 정책: per‑vault Mutex로 직렬화(전역 락 금지). 서비스 진입~종료까지
  단일 락 보유, 재진입 금지. 획득 타임아웃/대기열 정책 정의.
- 오류 모델: 도메인 예외/결과 타입 정의(예: `NameConflict`,
  `CycleDetected`, `NotFound`, `CrossVaultViolation`, `IOFailure`,
  `ConcurrencyConflict`, `Timeout`). 각 예외는 사용자 메시지 코드와
  `isRetryable` 메타를 포함.
- 반환 계약: 장시간 작업은 `OperationHandle`을 반환해 진행률/취소를 지원.
- 예외 변환: 레포/IO 예외를 서비스에서 도메인 예외로 변환.
- 로깅/관측성: 유스케이스별 trace span, 단계별 타이머/카운터, 삭제/링크
  영향 수치(건수/용량) 기록. `operationId`로 상관관계 유지.

## 예상 부작용/주의사항

- 이벤트 순서: 서비스 레벨 배치/커밋으로 단일 스냅샷만 방출.
- 모델 동기화: 표시명 소스는 항상 트리, 콘텐츠 제목은 미러. 서비스에서
  “한 번”에 처리.
- 파일 I/O: 복구 어려우므로 tombstone 후 지연/확정 삭제. 임시 디렉터리→
  커밋 이동으로 원자성 향상.
- 대용량 처리: 링크/캐스케이드 삭제는 배치/스트리밍/체크포인트를 사용.

## 테스트 전략

- 유스케이스 단위 성공/실패/보상 테스트(생성/삭제/이름변경/이동/폴더 캐스케이드).
- 실패 주입 테스트: 각 단계 임의 실패/예외 주입 → 보상/재시도/멱등 확인.
- 동시성 테스트: 동일 노트 rename×2, move+rename 경쟁, 대량 생성 경쟁.
- 크래시 내구성: 각 단계 직후 프로세스 강제 종료→재기동 회복 확인.
- 링크 정책 테스트: cross‑vault 생성/수정 차단.
- 이벤트/커밋 테스트: 워처가 중간 상태를 보지 않음(커밋 토큰 기준).
- 성능 테스트: 1k/10k 링크 노트 삭제, 대규모 폴더 캐스케이드.

## 구현 메모(향후)

- NoteListScreen: 데이터 소스 전환(vaultsProvider + vaultItemsProvider) 및
  삭제/생성 호출을 서비스로 교체.
- LinkCreation: 서제스트를 현 vault로 제한, cross‑vault 검증을 getPlacement
  기반으로 적용.
- VaultTreeRepository 확장: `getNotePlacement`/`registerExistingNote`는 이미
  추가됨(메모리 구현 완료). `markNoteDeleting`/`deleteFolderCascade` 보조 API
  검토.
- LinkRepository 확장: `deleteBySourceNote(noteId)` 추가, noteId→pageIds 역인덱스
  도입으로 대량 삭제 성능 향상.
- 이름 유틸: 정규화/검증 공용 모듈 추가 및 전 API에서 사용.
- 이벤트 커밋: 서비스 레벨 버퍼/커밋 토큰 구현 후 구독자 전환.

## 마이그레이션(메모리→Isar) 가이드

- 트랜잭션: 트리/콘텐츠/링크/작업로그/tombstone 컬렉션을 단일 트랜잭션으로
  변경. 커밋 훅에서 단일 이벤트 방출.
- 파일 I/O: 트랜잭션 커밋 후 tombstone 기반으로 비동기 삭제/이동 수행.
- 작업 로그: Isar 컬렉션으로 영속화. 재시작 시 재개 로직 포함.
- 인덱스: 링크 컬렉션에 `sourceNoteId`, `targetNoteId` 인덱스 추가.
- API: 레포 인터페이스가 트랜잭션 컨텍스트를 선택적으로 수신하도록 확장.

## 원자적 커밋 (트랜잭션)

- 공용 트랜잭션 레이어 추가 후 메모리 구현, 이후 isar 도입 시 writeTxn 같은 명시적 트랜잭션 사용
