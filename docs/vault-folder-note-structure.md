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
- VaultRepository(신규): Vault/Folder/Note 트리 관리(생성/이동/이름변경/삭제/조회)
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
