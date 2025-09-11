# Vault/Folder/Note Structure & Policies (v0)

본 문서는 Obsidian 유사 구조(vault → folder → note → note page)를 본 프로젝트에 도입하기 위한 모델/정책/운영 규칙을 명확히 합니다. 링크/그래프/검색/저장/이동의 단위는 항상 “하나의 vault”입니다.

## Goals

- 동일 vault 내 계층적 파일 구조(폴더/노트)와 링크를 안정적으로 관리
- 향후 Isar 도입 시 모델과 제약을 그대로 매핑 가능하도록 설계
- 현재 메모리 구현체에서도 동일 제약 하에 동작 보장

## Data Model (요약)

- 공통: 모든 엔티티는 `uuid v4`로 식별. `createdAt`, `updatedAt`를 가짐.

- Vault

  - 필수: `vaultId`, `name`, `createdAt`, `updatedAt`
  - 선택: `color`, `icon`, `settings(json)`

- Folder

  - 필수: `folderId`, `vaultId`, `name`, `parentFolderId?`, `createdAt`, `updatedAt`
  - 제약: `(vaultId, parentFolderId, name)` 케이스 비구분(unique)

- Note (콘텐츠)

  - 필수: `noteId`, `vaultId`, `title`, `pages<List<NotePage>>`, `sourceType`, `createdAt`, `updatedAt`
  - 선택: `folderId?`(루트면 null), `sourcePdfPath?`, `totalPdfPages?`

- NotePage (콘텐츠)

  - 필수: `noteId`, `pageId`, `pageNumber`, `jsonData`
  - 선택: PDF/배경 관련 필드(현행 유지)

- Link (페이지 내 앵커 → 노트)
  - 필수: `id`, `vaultId`, `sourceNoteId`, `sourcePageId`, `targetNoteId`, `bbox(좌표)`, `createdAt`, `updatedAt`
  - 선택: `label?`, `anchorText?`

## Invariants & Constraints

- 소유권
  - 모든 Folder/Note/Link는 정확히 하나의 Vault에 속함(`vaultId` 일치 필수).
- 링크 범위
  - cross-vault 링크 불가. 링크는 동일 vault 내에서만 생성/유지.
- 이동/복사
  - vault 간 이동 금지(추후 복사 플로우 고려). 동일 vault 내에서만 이동 허용.
- 사이클 방지
  - Folder의 `parentFolderId`는 자기 자신/자손을 가리킬 수 없음.
- 삭제 정책 (휴지통 없음)
  - Note 삭제: 관련 파일 삭제 + 해당 노트로의 incoming/해당 노트의 모든 page outgoing 링크 삭제.
  - Folder 삭제: 하위 전체(cascade) 삭제 + 관련 링크 정리. 삭제 전 확인 모달(영향 요약) 표시.
  - Vault 삭제: 전체 cascade(추후 필요 시)

## Naming & Normalization (정책 A)

- 제목=파일명(표시명과 파일명이 동일). 케이스는 보존하되, 비교는 케이스 비구분.
- 허용 문자(간소/안전 규칙)
  - 허용: 한글/영문/숫자/공백/하이픈(`-`)만 허용
  - 금지: 경로 분리 및 문제 소지 문자(`/ \\ : * ? " < > |`), 제어 문자 등 전부 금지
  - 길이: 1~128자
- 정규화
  - 앞뒤 공백 제거, 연속 공백 1칸으로 축약, 연속 하이픈 `-`은 1개로 축약
  - Unicode 정규화(NFC) 적용 권장
  - 케이스 비구분 비교(uniqueness 체크는 lowercased 기반), 표시는 원본 케이스 유지
- 중복 규칙
  - “동일 부모 폴더” 내에서만 중복 금지(케이스 비구분). 다른 폴더에 같은 이름 허용.
- 충돌 처리
  - 자동 접미사 부여는 하지 않음(괄호 등 비허용 문자 문제). 유효성 검사로 차단하고 사용자에게 수정 안내.

## Sorting

- 기본 정렬: 폴더 → 노트, 이름 오름차순(케이스 비구분).
- 생성/수정 시각은 모델에 보유(향후 정렬/필터 확장 대비).
- 수동 정렬(orderIndex)은 비활성(필드 예약은 가능).

## Creation & Import Location

- 일반 생성(브라우저에서): 현재 폴더에 생성
- 링크 생성 다이얼로그: “새 노트 만들기”는 해당 vault의 루트에 생성(정책 확정)
- PDF 가져오기(권장)
  - 브라우저 컨텍스트에서 실행 시: 현재 폴더에 생성
  - 홈 등 컨텍스트 외부에서 실행 시: vault 선택(필수) + 선택적으로 폴더 선택(없으면 루트)

> 브라우저: vault의 폴더/노트를 탐색·표시하는 화면(UI 컨텍스트)을 의미

## Repository & Provider (책임 분리)

- NotesRepository: 노트 “콘텐츠(페이지)” 전용(현행 유지)
- VaultTreeRepository(신규): Vault/Folder/Note 배치(트리) 관리(생성/이동/이름변경/삭제/조회)
- LinkRepository: 링크 영속/스트림. `vaultId` 필터·일괄 삭제 등 보조 API는 추후 확장
- Provider
  - `currentVaultProvider`, `currentFolderProvider`
  - `vaultsProvider`, `vaultItemsProvider(vaultId, parentFolderId?)`
  - 기존 `notesProvider`는 유지하되, 브라우저에서는 `vaultItemsProvider` 사용

## Validation Checklist (운영 규칙)

- 생성/이름변경 시
  - 허용 문자/길이/정규화 적용 후, 같은 부모 내 케이스 비구분 중복 검사
- 이동 시
  - 대상이 동일 vault인지 확인, Folder는 사이클 검사
- 링크 생성 시
  - source/target의 `vaultId` 일치 검증, bbox 유효성 검사
- 삭제 시
  - Note: 파일/링크 정리, Repo 삭제
  - Folder: 하위 항목 재귀 수집 → 노트/링크 정리 → Repo 삭제, 확인 모달 제공

## UI Impacts (우선 적용 범위)

- NoteList 화면 → Vault Browser: 루트/폴더 하위 항목(폴더/노트) 표시, 생성/이동/이름변경/삭제 지원
- 링크 생성 다이얼로그: “현 vault” 내 검색/선택 + “루트에 새 노트 만들기”
- 백링크 패널: 노트 타이틀 조회는 “현 vault 범위” 기준 최적화
- 라우팅: `/vaults/:vaultId/browse/:folderId?`(브라우저), `/notes/:noteId/edit` 유지(진입 시 해당 노트의 vault로 세션 동기화)

## Migration (메모리 → Isar, 기존 데이터 이관)

- “Default Vault”를 생성해 기존 노트를 루트로 이관(`note.vaultId=default`, `folderId=null`).
- 기존 링크는 `vaultId=default`로 설정. cross-vault 없음 보장.
- UI 최초 진입 시 vault 선택이 1개면 자동 진입.

## Future Work

- vault 간 복사(콘텐츠/링크 복사 정책 포함)
- 그래프 뷰/검색: vault 범위 필터 + 성능 인덱스 설계(Isar)
- 수동 정렬(DnD) + 즐겨찾기/핀 고정
- 다국어/자모 분해 처리 등 고급 정렬/검색 옵션

---

문의/변경 제안 시 본 문서 버전을 갱신하세요. (현재 v0)

## Responsibilities & Purpose (구조 재확인)

- 목적: “트리(배치)와 콘텐츠(노트)”를 분리해 책임을 명확히 하고, UI/성능/데이터 일관성을 균형 있게 달성한다.
- VaultTreeRepository(배치)
  - Vault/Folder/Note 배치(위치/표시명) 관리: 생성/이름변경/이동/삭제/정렬/중복·사이클 검사
  - 폴더 하위 아이템(폴더+노트) 관찰 스트림 제공, 기본 정렬 적용(폴더→노트, 케이스 비구분 이름 오름차순)
  - 비책임: 노트 콘텐츠 CRUD, 링크 영속, 파일 I/O
- NotesRepository(콘텐츠)
  - NoteModel 중심: 페이지/스케치 JSON/PDF 메타/썸네일, 편집/저장 흐름 전담
  - 비책임: 배치/정렬/중복/사이클/이동 검증(트리 책임)
- Application Service(오케스트레이션)
  - 두 레포를 하나의 유스케이스 단위로 묶는 상위 서비스(원자성/보상/검증/emit 타이밍 통제)
  - 예: 노트 생성/삭제/이름변경/이동, 폴더 캐스케이드 삭제

## Application Service (오케스트레이션)

- 서비스 이름(예시): VaultNotesService
- 책임
  - 원자성 보장(가능한 범위): per‑vault 직렬화, 실패 시 보상(Saga)로 일관성 회복
  - 교차‑레포 검증: cross‑vault 링크/이동 차단, 이름 정책 위반 사전 차단
  - emit 타이밍 통제: “최종 상태”만 스트림에 반영되도록 순서/타이밍 제어
- 주요 API (초안)
  - createBlankInFolder(vaultId, {parentFolderId?, name?}) → NoteModel
  - createPdfInFolder(vaultId, {parentFolderId?, name?}) → NoteModel
  - renameNote(noteId, newName)
  - moveNote(noteId, {newParentFolderId?})
  - deleteNote(noteId)
  - getPlacement(noteId) → NotePlacement 뷰(검증/표시용)
- ID 흐름 제안
  - 콘텐츠가 noteId 생성 → 트리에 “기존 noteId 등록(register)”(실패 시 등록 취소)
  - 대안(추후): 트리에서 ID 생성 → 콘텐츠가 해당 ID로 생성(생성자 오버로드 필요)

## Transactions & Consistency (일관성 전략)

- 단기(메모리 구현)
  - per‑vault Mutex로 유스케이스 직렬화
  - 보상(Saga) 절차: 실패 단계별 역연산 준비(등록 취소/원복/재시도 큐)
  - emit 타이밍: 성공 커밋 후에만 방출(가능하면 레포 내부 emit 지연/일괄 발행)
- 중기(Isar 도입 전)
  - 레포 내부 “변경 버퍼링” 후 커밋 시 일괄 emit
  - 오케스트레이션에서 예외/롤백 일괄 처리
- 장기(Isar 도입 시)
  - 하나의 DB 트랜잭션으로 VaultTree/Notes 변경을 커밋
  - 워처/스트림은 트랜잭션 커밋 시점에만 반영
- 유스케이스별 순서 가이드
  - 생성: (예약 등록) → 콘텐츠 생성 → 확정 등록(실패 시 예약 취소)
  - 삭제: (소프트 삭제/숨김) → 링크 정리 → 콘텐츠 삭제 → 배치 삭제(실패 시 재시도)
  - 이름변경: 배치 rename → 콘텐츠 title 동기화(실패 시 재시도 허용)
  - 이동: 배치에서만 처리(콘텐츠 불변)
  - 폴더 삭제: 하위 노트 수집 → 노트 삭제 시퀀스 반복(진행률/취소/재시도 고려)

## UI & Routing Impact (구현 단계)

- 브라우저(NoteList 대체/강화)
  - 목록 데이터 소스: vaultsProvider + vaultItemsProvider(FolderScope)
  - 컨텍스트 상태: currentVaultProvider, currentFolderProvider(vaultId)
  - 폴더/노트 동시 렌더(폴더 우선 정렬), 노트 클릭 시 /notes/:noteId/edit 진입
- 생성/삭제 버튼
  - 생성: VaultNotesService.createBlankInFolder / createPdfInFolder 호출
  - 삭제: VaultNotesService.deleteNote 호출(링크/콘텐츠/배치 일괄)
- 링크 생성/편집
  - 서제스트: “현 vault” 범위로 한정(트리에서 노트 집합 조회 후 제목 매칭)
  - cross‑vault 차단: source/target 배치의 vaultId 비교 후 불일치 에러
- 라우팅
  - 브라우저: /vaults/:vaultId/browse/:folderId?
  - 에디터: /notes/:noteId/edit (진입 시 해당 노트의 vault로 세션 동기화)

## Providers & State (권장 사용)

- currentVaultProvider: 현재 활성 vault
- currentFolderProvider(vaultId): 현재 폴더(null=루트)
- vaultsProvider: vault 목록 스트림
- vaultItemsProvider(FolderScope): 특정 폴더 하위의 폴더+노트 스트림
- 브라우저에서는 notesProvider 사용 금지(콘텐츠 무거움/경계 혼선 방지)

## Repository API 확장 제안(최소)

- VaultTreeRepository
  - getNotePlacement(noteId) → NotePlacement(뷰 모델; vaultId, parentFolderId, name…)
  - (선택) registerExistingNote(noteId, vaultId, {parentFolderId?, name}) — 콘텐츠가 선행 생성된 경우 트리에 등록
  - (선택) listNotesInVault(vaultId) / searchNotesInVault(vaultId, query)
- NotesRepository
  - 현 구조 유지(콘텐츠 전용). 브라우저가 필요로 하는 쿼리는 트리에서 해결

## Validation & Policies (추가/강화)

- 이름 정책 강화(트리): 허용 문자 화이트리스트 + NFC 권장(현 구현은 금지문자 제거/축약만 반영)
- 링크 정책: cross‑vault 금지(오케스트레이션에서 배치 조회로 검증)
- 삭제 정책: 폴더 캐스케이드 시, 영향 요약 모달 + 진행률/취소/재시도
- 정렬 정책: 폴더→노트, 케이스 비구분 이름 ASC(현행 유지)

## Testing & Verification

- 유스케이스별 성공/실패 시나리오(보상 동작) 테스트
- emit 타이밍 테스트: 중간 상태가 소비자에게 보이지 않는지 확인
- 링크 검증 테스트: cross‑vault 생성/수정 차단
- 폴더 캐스케이드: 대량 삭제·재시도 테스트

## Risks & Mitigations

- 중간 실패로 인한 불일치: 보상(Saga) 및 재시도 큐로 수습, 소프트 삭제/예약 등록 활용
- 이벤트 순서 혼선: 커밋 후 emit 원칙, 레포 내부 버퍼링 도입 검토
- 모델 동기화 비용: 표시명 소스는 트리의 name, 콘텐츠 title은 미러(필요 시 동기화; 실패 허용 후 재시도)

## Implementation Plan (Phase-by-Phase)

1. 브라우저 전환: NoteList를 vaultItemsProvider 기반으로 교체, currentVault/currentFolder 도입
2. 오케스트레이션 베이스: VaultNotesService 뼈대(생성/삭제 우선), per‑vault 직렬화 + 보상 최소 구현
3. 링크 범위 적용: 링크 UI를 현 vault 한정 검색 + cross‑vault 차단
4. 이름 정책 강화: 트리 정규화/화이트리스트/NFC(점진)
5. 폴더 캐스케이드: 영향 요약 모달 + 진행률/취소/재시도 구현
6. emit 개선: 메모리 구현에서 커밋 후 일괄 emit(가능 시)
7. Isar 전환: DB 트랜잭션 기반으로 서비스 트랜잭션 단순화
