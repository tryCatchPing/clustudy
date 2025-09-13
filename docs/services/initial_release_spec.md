### 초기 출시 사양: 이름 변경, 검색, 이동 정책 및 구현 계획

본 문서는 초기 출시를 위한 핵심 기능(이름 변경, 노트 검색, 이동)의 정책, 구현 목표, 구현 방식, 이유를 정리합니다. 코드 구현 전에 기준 문서로 사용합니다.

### 정책 요약

- 이름 정책(노트/폴더/Vault 공통)

  - 정규화: 입력 trim → `NameNormalizer.normalize` 적용(케이스/공백/특수문자 정리, NFC 권장).
  - 유일성 범위:
    - Vault: 전역 유일(중복 불가).
    - 폴더/노트: “동일 부모 폴더” 내 유일.
  - 금지: 제어문자 및 경로 예약문자(`/ \ : * ? " < > |`). 선행/후행 공백 금지.
  - 길이: 최소 1, 최대 100.
  - 충돌 처리: 이름 변경 시 충돌이면 실패(명시적 수정 유도). 이동 시 충돌이면 자동 접미사 부여(아래 규칙).

- 검색(노트)

  - 스코프: “현재 Vault” 내에서만.
  - 매칭: 케이스/악센트 무시. 기본 부분 일치, `exact=true` 옵션.
  - 정렬: 정확 일치 > 접두사 > 부분 일치, 같은 그룹 내 이름 ASC.
  - 결과 제한: 최대 50(기본). 빈 검색 시 상위 N(기본 정렬) 반환.
  - 링크 서제스트: 동일 검색 API 사용(현 `link_target_search`는 서비스 호출로 교체).

- 이동(폴더/노트)
  - 스코프: 동일 Vault 내에서만 허용.
  - 금지: 폴더의 자기/자손으로 이동 금지(사이클 차단). 노트는 제한 없음(동일 Vault만).
  - 충돌: 대상 폴더 내 이름 충돌 시 자동 접미사 부여(" 이름 (2)", " 이름 (3)" …). 최대 길이 초과 시 본문을 잘라 접미사 포함.
  - 타깃: 루트 선택 허용 유지. 트리 탐색은 BFS로 충분.

### 구현 목표

- 이름 변경

  - 노트/폴더/Vault에 대해 일관된 이름 정규화/검증/중복 정책 적용.
  - 노트 이름 변경 시 콘텐츠 제목 동기화(원자성 보장).

- 노트 검색

  - `VaultNotesService.searchNotesInVault(vaultId, query, {exact=false, limit=50})` 제공.
  - 링크 서제스트/브라우저 필터에서 동일 API 사용.

- 이동(자동 접미사)
  - 폴더/노트 이동 시 대상 폴더에서 이름 충돌 자동 해소(접미사) 후 이동.
  - UI는 FolderPicker 다이얼로그로 타깃 선택, 불가 타깃은 disabled.

### 구현 방식(서비스/레포 역할 분리)

- 서비스(VaultNotesService)

  - 이름 변경
    - renameNote(noteId, newName): 이미 구현(트리+콘텐츠 동기화).
    - renameFolder(folderId, newName): 추가(정규화/중복 검사/에러 매핑).
    - renameVault(vaultId, newName): 추가(전역 유일 검사/에러 매핑).
  - 검색
    - searchNotesInVault(vaultId, query, {exact=false, limit=50}):
      1. BFS로 모든 Placement 수집(현재 인메모리 기준 `.watchFolderChildren(...).first`).
      2. `NameNormalizer.compareKey`로 비교.
      3. 정확/접두/부분 가중치로 정렬 후 `limit` 컷.
  - 이동(자동 접미사)
    - moveNoteWithAutoRename(noteId, {newParentFolderId}):
      1. 타깃 폴더의 동명 여부 검사 → 충돌 시 접미사 후보 생성.
      2. 이름 확정 후 `vaultTree.moveNote(...)` 실행.
    - moveFolderWithAutoRename({folderId, newParentFolderId}):
      1. 사이클 금지/동일 Vault 검증.
      2. 동명 검사 → 접미사 후보 생성.
      3. `vaultTree.moveFolder(...)` 실행.
  - 보조 기능(이미 구현 또는 완료됨)
    - computeFolderCascadeImpact(vaultId, folderId): 폴더/노트 개수 요약.
    - deleteFolderCascade(folderId): 노트 콘텐츠 삭제 → 트리 폴더 삭제.
    - getParentFolderId(vaultId, folderId): Up Navigation 지원.

- 레포(VaultTreeRepository)
  - 단일 동작(생성/이름변경/이동/삭제)과 정렬/유일성 규칙 준수.
  - 이름 충돌/사이클 검증은 여전히 레포에서 1차 보장.
  - 서비스는 오케스트레이션/자동 접미사/검색 집계 같은 유스케이스 담당.

### 자동 접미사 규칙(이동 전용)

- 기본 포맷: `"이름 (n)"`, n은 2부터 시작.
- 충돌 검사: 타깃 폴더 스코프에서 `이름`, `이름 (2)`, `이름 (3)` … 순차 검사.
- 길이 제한: 최대 100 미만으로 자르되, 접미사가 항상 포함되도록 본문을 자름(`본문 ... + " (n)"`).
- 정규화: 접미사 전/후 모두 `NameNormalizer.normalize` 적용.

### 예외/메시지 정비 가이드

- 공통 매퍼: 내부 예외 → 사용자 메시지로 매핑.
  - 중복 이름: "같은 위치에 이미 존재합니다"
  - 금지 문자: "허용되지 않는 문자가 포함되어 있습니다"
  - 사이클: "자기 자신/하위로는 이동할 수 없습니다"
  - cross‑vault: "다른 Vault로 이동/링크할 수 없습니다"
  - IO/기타: "요청을 처리하는 중 문제가 발생했습니다"
- UI: 파괴적 작업은 다이얼로그, 그 외는 스낵바. 한국어 존칭 톤 유지.

### API 설계(요약 시그니처)

- VaultNotesService
  - renameNote(String noteId, String newName) — 기존
  - renameFolder(String folderId, String newName) — 신규
  - renameVault(String vaultId, String newName) — 신규
  - searchNotesInVault(String vaultId, String query, {bool exact=false, int limit=50}) — 신규
  - moveNoteWithAutoRename(String noteId, {String? newParentFolderId}) — 신규
  - moveFolderWithAutoRename({required String folderId, String? newParentFolderId}) — 신규
  - computeFolderCascadeImpact(String vaultId, String folderId) — 완료
  - deleteFolderCascade(String folderId) — 완료
  - getParentFolderId(String vaultId, String folderId) — 완료

### UI 반영 계획(요약)

- NoteListScreen
  - 이름 변경: 카드 more(⋯)에 “이름 변경” 추가 → 서비스 rename 호출.
  - 검색: 상단 검색 입력 → 서비스 search 호출(디바운스 250ms). 빈 검색 시 상위 N 표시.
  - 이동: “이동” → FolderPicker 다이얼로그 → 서비스 moveWithAutoRename 호출.
  - 삭제: 폴더 삭제 전 영향 미리보기(서비스 compute 호출) 유지.
- 링크 다이얼로그
  - 추천/검색을 서비스 search로 교체. cross‑vault 금지 유지.

### 테스트 체크리스트(요약)

- 이름 변경: 중복/금지/길이/정규화 케이스.
- 검색: 정확/접두/부분/빈 검색/limit 컷.
- 이동: 사이클 금지/동일 Vault 강제/자동 접미사/길이 제한.
- 삭제: 영향 범위 요약 정확성, 캐스케이드 일관성.

### 선택/이유 요약

- 인메모리 단계에선 BFS가 단순·안정적이며 구현/테스트 비용이 낮음.
- 자동 접미사는 이동 UX 마찰을 줄이고, 이름 변경은 명시적 수정으로 혼선을 방지.
- 검색/이동/이름 변경을 서비스로 집약하면 타 화면 재사용 및 교체(예: Isar 도입) 시 UI 변경이 최소화됨.
