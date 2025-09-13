### 초기 출시 구현 이터레이션 정리 (2025-09-13)

#### 핵심 수정 및 개선

- 스트림 초기값 유실 버그 수정

  - `lib/features/vaults/data/memory_vault_tree_repository.dart`
    - `watchFolderChildren(...)` 초기 emit 방식을 `c.add(...)` → `yield _collectChildren(...)`로 변경.
    - 결과: 노트 목록/링크 다이얼로그 무한 로딩 해소, `.first` 호출 즉시 응답.

- Vault/폴더/노트 생성·이름 변경 UI 추가/보완

  - `lib/features/notes/pages/note_list_screen.dart`
    - Vault 생성/이름 변경 버튼 추가, 폴더 생성/이름 변경 버튼 추가, 노트 이름 변경 버튼 추가.
    - TextEditingController 생명주기 문제 해결: `_NameInputDialog`(Stateful)로 컨트롤러 내부화.
    - 빈 폴더/노트여도 항상 “폴더 추가”, “한 단계 위로” 노출.

- 폴더 삭제 캐스케이드 미리보기/오케스트레이션

  - 서비스 계층으로 오케스트레이션 이동: `lib/shared/services/vault_notes_service.dart`
    - `computeFolderCascadeImpact(vaultId, folderId)` 추가(폴더/노트 개수 요약).
    - `deleteFolderCascade(folderId)` 추가(노트 콘텐츠 삭제 → 트리 폴더 삭제).
  - UI에서 영향 범위 다이얼로그 노출 후 서비스 호출로 일원화.

- 이름 변경 서비스 일원화

  - `lib/shared/services/vault_notes_service.dart`
    - `renameNote(noteId, newName)`(기존): 트리 rename + `notesRepo.upsert`로 콘텐츠 제목 동기화(원자성).
    - `renameFolder(folderId, newName)`, `renameVault(vaultId, newName)` 추가.
  - UI 연결: `NoteListScreen`에서 노트/폴더/Vault 이름 변경 액션 연결.

- 백링크 패널 최신 제목 표시

  - `lib/features/canvas/widgets/panels/backlinks_panel.dart`
    - Outgoing 리스트는 항상 “라이브 노트 제목”을 표시(라벨은 표시 우선순위에서 제외).
    - 결과: 노트 이름 변경 시 즉시 반영.

- Vault 이름 전역 유일 강제
  - `lib/features/vaults/data/memory_vault_tree_repository.dart`
    - 생성/이름 변경 시 `NameNormalizer.compareKey` 기준 전역 중복 검사 `_ensureUniqueVaultName` 추가.
    - 중복 시 예외 throw.

#### 노트 검색 기능 추가

- 서비스 검색 API

  - `lib/shared/services/vault_notes_service.dart`
    - `class NoteSearchResult { noteId, title, parentFolderName? }`
    - `searchNotesInVault(vaultId, query, {exact=false, limit=50})`
      - BFS(Placement) 기반 수집 → 정규화 키 비교 → 랭킹(정확>접두>부분) 정렬 → limit 컷.

- 링크 타깃 서제스트 교체

  - `lib/features/canvas/providers/link_target_search.dart`
    - 기존 BFS 제거 → `vaultNotesService.searchNotesInVault` 호출로 변경.

- 링크 생성 다이얼로그 검색 교체

  - `lib/features/canvas/widgets/dialogs/link_creation_dialog.dart`
    - 초기 로드/필터 모두 서비스 검색으로 교체(동일 Vault 스코프).
    - 불필요 캐시 제거.

- 노트 목록 상단 검색바 추가
  - `NoteListScreen`
    - 250ms 디바운스, 서비스 검색 결과 카드 표시(제목/경로 라벨).
    - 검색 중 로딩/빈 결과 메시지 처리.

#### 정책 반영(요약)

- 이름 정책: 정규화, 금지문자, 길이(≤100), 유일성 범위(Vault: 전역 유일 / 폴더·노트: 동일 부모 내 유일).
- 검색: 현 Vault 스코프, 케이스/악센트 무시, 기본 부분 일치, `exact` 옵션, 결과 제한 50.
- 이동(예정): 동일 Vault만, 폴더 자기/자손 금지, 이름 충돌 시 자동 접미사(후속 구현).

#### 아키텍처 정리

- 서비스 계층(`VaultNotesService`)로 오케스트레이션 이동
  - 폴더 삭제 캐스케이드, 상위 폴더 탐색, 검색, 이름 변경(노트/폴더/Vault) 등 UI에서 분리.
  - UI는 입력/다이얼로그/스낵바만 담당 → 화면 단순화, 테스트 용이성 향상.

#### 다음 단계 제안

- 이동 with 자동 접미사

  - `moveNoteWithAutoRename`, `moveFolderWithAutoRename` 서비스 추가
  - UI FolderPicker 도입(자기/자손 비활성, 루트 허용)

- 예외/메시지 공통화

  - 예외 매퍼(중복/금지/사이클/cross-vault/IO) → 공통 스낵바 헬퍼 적용

- 테스트 보강
  - 서비스: 검색/이름 변경/삭제 캐스케이드/상위 탐색
  - 위젯: NoteList 검색/이름 변경/폴더 삭제 흐름, 링크 다이얼로그 검색
