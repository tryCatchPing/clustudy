### 노트 이동(자동 접미사 포함) 구현 기록 — 2025-09-14

이 문서는 `moveNoteWithAutoRename`를 중심으로 노트/폴더 이동 기능의 목표, 정책, 내부 구현, UI 연결, 그리고 문제 해결 과정을 정리합니다.

---

### 목표

- **노트 이동**: 동일 Vault 내에서 노트를 다른 폴더(또는 루트)로 이동한다.
- **이름 충돌 자동 해결(AutoRename)**: 타깃 폴더에 같은 이름의 항목이 있으면 자동으로 `(2)`, `(3)` 등의 접미사를 부여한다.
- **정합성 보장**: 이동은 트랜잭션 경계 안에서 안전하게 수행되며, 스트림을 통해 UI에 즉시 반영된다.

---

### 정책 개요

- **동일 Vault 내 이동만 허용**: 크로스 Vault 이동은 금지.
- **이름 정책**: 케이스/악센트는 비구분 비교(`NameNormalizer.compareKey`). 최대 길이 제한(100) 내부 준수.
- **충돌 처리**: `base`, `base (2)`, `base (3)`... 식으로 가용 이름을 탐색.
- **폴더 이동 제약(참고)**: 자기 자신/자손으로의 이동은 금지(사이클 방지). 루트 이동 가능.

---

### 내부 구현(서비스 레이어)

- 위치: `lib/shared/services/vault_notes_service.dart`

- **핵심 메서드**

  - `Future<void> moveNoteWithAutoRename(String noteId, {String? newParentFolderId})`
    - 현재 배치(`getPlacement`) 조회 → 동일 부모면 no-op.
    - 타깃 폴더가 같은 Vault인지 검증(`_containsFolder`).
    - 타깃 스코프의 노트 이름 키 수집(`_collectNoteNameKeysInScope`).
    - 충돌 없으면 단순 이동(`vaultTree.moveNote`)을 트랜잭션으로 수행.
    - 충돌 있으면 "임시 이름 → 이동 → 최종 이름 재적용" 순으로 처리.
  - 참고: `moveFolderWithAutoRename`도 동일한 철학으로 구현. 추가로 사이클 검증 및 폴더 이름 충돌 검사 수행.

- **보조 로직**
  - `_collectNoteNameKeysInScope(vaultId, parentFolderId)`: 타깃 스코프에서 이름 키 집합 수집.
  - `_generateUniqueName(base, existingKeys)`: 자동 접미사로 가용 이름 생성.
  - `_generateTemporaryName(base)`: 충돌 해소를 위한 임시 이름 생성.
  - `_containsFolder(vaultId, folderId)`: BFS로 해당 Vault 내 폴더 존재 확인.
  - `DbTxnRunner.write`: 메모리에서는 no-op, 향후 DB 전환 시 트랜잭션 경계 보장.

---

### 저장소(Repository) 층과의 역할 분리

- 위치: `lib/features/vaults/data/memory_vault_tree_repository.dart`
- 역할: Vault/Folder/Note의 "배치 트리" 관리(생성/이름변경/이동/삭제), `watchFolderChildren` 스트림 제공.
- 이름 중복/정렬 정책은 저장소가 보장하며, 서비스는 유스케이스 오케스트레이션(트랜잭션, AutoRename, 링크/콘텐츠 정리 등)을 담당.

---

### UI 연결(브라우저/피커)

- 위치: `lib/features/notes/pages/note_list_screen.dart`

  - 노트 카드의 "이동" 아이콘 → `FolderPickerDialog` 표시 → 선택 결과로 `vaultNotesService.moveNoteWithAutoRename` 호출.
  - 폴더 이동도 유사하게 `moveFolderWithAutoRename` 사용.

- 위치: `lib/shared/widgets/folder_picker_dialog.dart`
  - 폴더 선택 다이얼로그. 루트 선택을 안전하게 전달하기 위해 루트는 내부 sentinel(`__ROOT__`)로 표시하고, 확인 시에만 null로 변환하여 반환.
  - 자기/자손 폴더 비활성화 지원(`disabledFolderSubtreeRootId`).

---

### 문제 해결 과정(트러블슈팅 연대기)

- 1. 초기 스트림 문제로 인해 폴더/노트 목록이 가끔 초기 이벤트를 놓쳤음

  - 조치: `watchFolderChildren`에서 초기 스냅샷을 `yield`하고, 이후 브로드캐스트 스트림을 `yield*`하도록 수정(초기 이벤트 유실 방지).
  - 왜/어떻게: `StreamController.broadcast()`에 구독을 붙이기 전에 `add`로 초기 스냅샷을 흘리면 첫 프레임을 구독자가 받지 못할 수 있음. `async*`에서 `yield`는 구독 이후 전달되므로 안전하게 초기 상태를 보장한다.

- 2. 링크 패널에서 변경된 노트 제목 반영 문제

  - 조치: Outgoing 링크에서는 항상 live `targetTitle`을 표시하도록 단순화하여 stale 라벨 문제 제거.
  - 왜/어떻게: 링크 생성 시 저장된 `label`은 이후 제목 변경 시 갱신되지 않아 오래된 표시가 남았다. 비교 로직으로 자동/수동 라벨을 구분하는 접근은 edge case가 존재. 단일 원천(live title)만 사용하도록 바꾸면 일관성이 생기고 스트림 갱신을 그대로 반영할 수 있다.

- 3. 폴더 이동 시 루트로 이동이 반영되지 않는 문제
  - 현상: 저장소 로그는 `to=root`가 찍히지만, 실제로는 `a/b`의 `b`가 루트로 보이지 않음.
  - **근본 원인**: 모델 `copyWith` 구현이 `parentFolderId ?? this.parentFolderId` 패턴이라 명시적 null 설정(루트)이 무시됨.
  - **해결**: `FolderModel.copyWith`, `NotePlacement.copyWith`를 sentinel 파라미터로 변경하여 "미지정"과 "명시적 null"을 구분. 이제 루트 이동이 정확히 반영됨.
  - 진단 편의 로그/재발행(마이크로태스크) 등 임시 방어 코드는 근본 원인 해결 후 정리.
  - 왜/어떻게: 기존 패턴은 "값을 주지 않음"과 "null로 설정"을 동일하게 취급한다. 루트 이동은 parent를 null로 만들어야 하므로 구분이 필수. sentinel(예: `_unset`)을 기본값으로 쓰면, 호출자가 인자를 생략한 경우와 null을 명시한 경우를 구분할 수 있어, 의도대로 null을 모델에 반영할 수 있다. 이후 `watchFolderChildren(..., parentFolderId: null)` 스코프에서 해당 항목이 나타나며, 이전 부모 스코프에서는 사라진다.

---

### 검증 시나리오

- 노트 이동 기본 흐름

  1. `a`, `a/b` 생성.
  2. 노트 `n`을 `a/b`에 생성.
  3. `n`을 루트로 이동.
  4. 루트 스코프 목록에서 `n` 확인, `a/b` 스코프에서는 `n`이 제거됨.

- 이름 충돌 흐름

  1. 루트에 `n`, `n (2)`가 이미 존재.
  2. `n`을 가진 다른 폴더에서 노트를 루트로 이동.
  3. 서비스가 임시 이름 → 이동 → 최종 이름 재적용(자동 접미사)로 충돌 해소.

- 폴더 이동(참고)
  - 자기/자손으로 이동 시 예외 발생(사이클 방지).
  - 루트 이동 시 정상 반영(모델 sentinel 수정으로 해결).

---

### 향후 보강

- **UX**: 이동 완료 후 현재 뷰 스코프 자동 전환(옵션) 및 "변경 없음" 스낵바 표준화.
- **테스트**: AutoRename 경계/검색/캐스케이드/브라우저 흐름 테스트 추가.
- **오케스트레이션 확장**: 링크/콘텐츠 관련 side-effect를 포함하는 복합 시나리오 테스트.

---

### 관련 파일/지점

- 서비스: `lib/shared/services/vault_notes_service.dart`
- 저장소: `lib/features/vaults/data/memory_vault_tree_repository.dart`
- 모델: `lib/features/vaults/models/folder_model.dart`, `lib/features/vaults/models/note_placement.dart`
- UI: `lib/features/notes/pages/note_list_screen.dart`, `lib/shared/widgets/folder_picker_dialog.dart`
