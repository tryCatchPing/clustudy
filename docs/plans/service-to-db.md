- VaultNotesService에서 여전히 담당하는 이름 충돌/트리 탐색 로직을 Isar 레이어로 끌어내릴
  수 있는 지점을 정리했습니다.

  - 아래 코드 블록에 상세 분석 Markdown 문서를 포함했으니 검토 후 Repository 인터페이스 확
    장을 우선 결정하세요.
  - 다음 단계로 제안한 저장소 API 스펙을 합의하고, 필요한 인덱스/엔터티 필드 추가 여부를 검
    증하는 방향이 자연스럽습니다.

# VaultNotesService → Isar 계층 이전 제안서

## 1. 큰 그림

- VaultNotesService는 노트/폴더/보관함의 생성·이동·삭제를 오케스트레이션하지만, 여전히
  서비스 내부에서 이름 충돌 해결이나 트리 탐색을 직접 수행합니다 (`lib/shared/services/
vault_notes_service.dart:77`, `130`, `181`, `339` 등).
- Isar 기반 `VaultTreeRepository`는 이미 고유성 검사, 조상/자손 탐색, 트랜잭션 실행을 지
  원합니다 (`lib/features/vaults/data/isar_vault_tree_repository.dart:410`, `463`, `489`
  등). 이 레이어를 확장하면 서비스 중복 코드를 제거하고 경쟁 상태를 DB 트랜잭션으로 봉인할
  수 있습니다.
- 목표는 “서비스는 유스케이스 흐름과 cross-repo 조율(노트 콘텐츠·링크·파일)”만 다루고,
  “트리·이름 정책·범위 질의”는 저장소가 책임지는 구조입니다.

## 2. 이름 충돌/자동 접미사 처리

### 현황

- `_generateUniqueName`과 `_collect*NameKeysInScope`가 서비스에 상주하며, 매번
  `watchFolderChildren(...).first`로 스트림을 열어 이름 집합을 만듭니다 (`lib/shared/
services/vault_notes_service.dart:691-753`).
- `createBlankInFolder`, `createPdfInFolder`, `renameNote`, `renameFolder`,
  `renameVault`, `createFolder`, `createVault`가 모두 이 헬퍼를 호출해 접미사 부여를 처리합
  니다 (`lib/shared/services/vault_notes_service.dart:97-100`, `321-335`, `370-377`, `382-
395`, `427-437`, `441-446`).

### 제안

1. `VaultTreeRepository`에 “사용 가능한 이름을 계산”하는 API를 추가합니다. 예시 시그니처: - `Future<String> allocateNoteName({required String vaultId, String? parentFolderId,
required String desiredName});` - `allocateFolderName`, `allocateVaultName`도 동일 패턴.
2. Isar에서는 `notePlacementEntitys.filter().vaultIdEqualTo(...)` 뒤에
   `parentFolderIdEqualTo/IsNull`과 `nameStartsWith`를 조합하여 기존 접미사를 파싱하고 최댓
   값을 계산할 수 있습니다. `splitMapJoin` 없이도 `where().sortByNameDesc().take(1)`으로 가
   장 큰 접미사를 찾을 수 있습니다.
3. 위 API 내부에서 `_ensureUnique...`를 유지하되, 충돌 시 바로 다음 접미사를 계
   산해 저장소 레벨에서 반환하도록 변경하면 서비스는 단순히 `final unique = await
vaultTree.allocateNoteName(...);` 형태로 호출만 하면 됩니다.
4. 동시에 `NotePlacementEntity`와 `FolderEntity`에 `nameKey`(정규화된 비교 키) 필드를 추
   가하고 `(vaultId, parentFolderId, nameKey)` 합성 인덱스를 두면 대·소문자/악센트 무시 정렬
   과 충돌 검출이 O(log n)으로 줄어듭니다. 서비스의 `NameNormalizer.compareKey` 호출은 엔터
   티 입력 시점에 1회 수행하면 됩니다.
5. `renameNote` 시 콘텐츠 제목 동기화는 그대로 서비스에서 `notesRepo.upsert`로 처리하되,
   충돌 해소는 저장소가 반환하는 최종 이름에 위임합니다.

### 기대 효과

- 스트림 생성/해제를 반복하지 않아도 되어 CPU·메모리 낭비가 줄고, Isar 내부 트랜잭션이 경
  쟁 상태를 자연스럽게 직렬화합니다.
- 같은 이름을 동시에 요청하는 케이스에서도 서비스 레벨에서 set을 읽고 충돌을 놓치는 race
  condition을 제거할 수 있습니다.
- 이름 정책이 단일 지점에 모이므로 향후 웹 동기화·CLI 도구 등 다른 진입점이 생겨도 일관성
  이 확보됩니다.

## 3. 트리 탐색/범위 확인 로직

### 현황

- `_containsFolder`, `getParentFolderId`, `listFolderSubtreeIds`,
  `_collectNotesRecursively`, `_collectAllNoteIdsInVault`, `listFoldersWithPath` 모두 BFS
  를 직접 돌리며 `watchFolderChildren(...).first`를 반복 호출합니다 (`lib/shared/services/
vault_notes_service.dart:543-684`, `760-833`).
- `moveFolderWithAutoRename`는 vaultId 탐색을 위해 전체 Vault를 구
  독하고 `_containsFolder`를 여러 번 호출합니다 (`lib/shared/services/
vault_notes_service.dart:187-215`).

### 제안

1. `VaultTreeRepository`가 이미 `getFolder`, `getFolderAncestors`, `getFolderDescendants`
   를 제공하므로 이를 활용하거나, 필요한 경우 `Future<FolderModel?> findFolder(String
folderId)`로 단건 조회를 노출해 vaultId·parentId를 즉시 얻도록 바꿉니다.
2. `Future<bool> existsFolderInVault(String vaultId, String folderId)`와
   `Future<List<String>> listNoteIdsInScope(String vaultId, {String? folderId})`
   같은 메서드를 저장소에 신설합니다. Isar 쿼리는 `parentFolderIdEqualTo`와
   `notePlacementEntitys.filter().vaultIdEqualTo(...).parentFolderIdEqualTo(...)`로 손쉽게
   구현됩니다.
3. `listFoldersWithPath`는 `getFolderDescendants` 결과와 `getFolderAncestors`를 조합하거
   나, 엔터티에 `pathCache` 필드를 추가해 저장소가 경로 문자열을 직접 구성하도록 만들면 서비
   스에서는 단순 변환만 수행하면 됩니다.
4. Vault 단위 노트 ID 수집도
   `notePlacementEntitys.filter().vaultIdEqualTo(vaultId).noteIdProperty().findAll()`로 한
   번에 가져올 수 있으므로 `_collectAllNoteIdsInVault`를 저장소 메서드로 교체합니다.

### 기대 효과

- 반복적인 스트림 초기화 없이 필요한 데이터만 즉시 조회할 수 있어 IO가 크게 줄어듭니다.
- 폴더 존재 여부 확인이나 조상 탐색이 저장소에 모이면 향후 CLI, 백그라운드 작업 등에서도
  재사용 가능합니다.
- 서비스 레벨 코드가 간결해지고, 테스트도 repository mock만으로 검증할 수 있습니다.

## 4. 이동 시 충돌 처리

### 현황

- `moveNoteWithAutoRename`와 `moveFolderWithAutoRename`는 충돌 시 임시 이름을 붙
  였다가 다시 원래 이름을 재배치하는 3단계 작업을 수행합니다 (`lib/shared/services/
vault_notes_service.dart:130-179`, `250-260`). 이동과 이름 변경이 서로 다른 트랜잭션으로
  실행되어 일시적인 UI 깜박임 위험도 존재합니다.

### 제안

1. `VaultTreeRepository`에 `moveNoteWithAutoRename`/`moveFolderWithAutoRename`를 추가하
   고, 단일 트랜잭션에서
   - 목표 폴더의 충돌 여부 검사,
   - 필요 시 접미사 계산,
   - parentFolderId와 name을 동시에 갱신하도록 합니다.
2. Isar에서는 동일 트랜잭션 내에서 `notePlacementEntity`의 `parentFolderId`와 `name`을 같
   이 업데이트할 수 있습니다. 이름 계산은 §2에서 제안한 `allocateNoteName`을 재사용하면 됩
   니다.
3. 사이클 검사 역시 저장소 레벨로 이동해 `_ensureNoCycle` 같은 내부 헬퍼로 캡슐화하면, 서
   비스는 `await vaultTree.moveFolderWithAutoRename(...)` 한 줄로 단순화됩니다.

### 기대 효과

- 임시 이름 노출이 사라져 UI에서 “(tmp …)”가 보일 가능성이 없어집니다.
- 이동+이름 변경이 하나의 트랜잭션으로 묶여 실패 시 자동 롤백되므로 보상 로직이 필요 없습
  니다.

## 5. 삭제 캐스케이드 & 영향도 계산

### 현황

- `computeFolderCascadeImpact`, `deleteFolderCascade`, `deleteVault`가 모두 서비스에서 트
  리를 순회하며 노트 ID를 수집합니다 (`lib/shared/services/vault_notes_service.dart:482-
540`, `400-419`).
- 반복 루프 중 `deleteNote`를 호출하면서 각각이 트랜잭션을 다시 열어 오버헤드가 큽니다.

### 제안

1. `VaultTreeRepository`에 `collectCascadeSummary(folderId)`(폴더·노
   트 수)와 `collectCascadeNoteIds(folderId)`를 추가합니다. Isar에서는
   `notePlacementEntitys.filter().parentFolderIdEqualToAnyOf(descendantIds)`로 한 번에 조회
   할 수 있습니다.
2. 삭제 자체는 여전히 콘텐츠/파일 삭제 때문에 서비스가 orchestration을 맡아야 하나, 대상
   ID 수집은 저장소에 위임하면 Stream 생성 없이 리스트만 받을 수 있습니다.
3. Vault 전체 삭제도
   `notePlacementEntitys.filter().vaultIdEqualTo(vaultId).noteIdProperty().findAll()`을 통해
   노트 리스트를 뽑고, 삭제 루프는 `dbTxn.writeWithSession` 하나로 감싸 batch 처리할 수 있습
   니다. 필요 시 `notesRepo`에 `deleteAll(List<String> ids)`를 추가해 트랜잭션 수를 줄일 수
   있습니다.

## 6. 검색 및 인덱스 확장

- `searchNotesInVault` 주석에 이미 `titleKey` 필드와 복합 인덱스를 도입하라는 TODO가 있습
  니다 (`lib/shared/services/vault_notes_service.dart:567-578`). Isar 엔터티에 `titleKey`를
  추가하고 `(vaultId, titleKey)` 인덱스를 구성하면 필터 없이 `where()` 체인으로 접두/부분
  일치를 훨씬 빠르게 수행할 수 있습니다.
- `excludeNoteIds` 필터는 현재 메모리에서 수행되는데, Isar 3의 `notEqualTo` 반복 또는
  `where().anyId().filter().not().idEqualTo(...)` 패턴을 활용하면 DB 레벨에서 제외 처리도
  가능해집니다.
- 검색 결과의 부모 폴더명 캐시는 서비스에서 유지해도 무방하지만, 조회가 잦
  다면 `NotePlacementEntity`에 denormalized `parentFolderName`을 저장하거나
  `IsarLink<FolderEntity>`를 활용해 `.parentFolder.value?.name`을 직접 로드하는 방식을 고려
  할 수 있습니다.

## 7. 구현 로드맵 제안

1. Repository 인터페이스에 필요한 메서드 시그니처 초안 작성 (`allocateName`,
   `moveWithAutoRename`, `listNoteIds` 등) → 팀 합의.
2. Isar 엔터티 필드/인덱스 수정 (`nameKey`, 필요 시 `pathCache`) → 마이그레이션 스크립트/
   테스트 준비.
3. Repository 구현(Isar + Memory)을 업데이트하고 단위/통합 테스트 작성.
4. VaultNotesService를 단계적으로 정리하며 새로운 저장소 API를 사용하도록 리팩터링.
5. 회귀 위험이 있는 유스케이스(노트 생성, 폴더 이동, 대량 삭제)에 대한 UI/통합 테스트
   보강.

## 8. 리스크 및 확인 사항

- 메모리 저장소(`memory_vault_tree_repository.dart`)도 동일한 API를 구현해야 하므로, 이름
  자동 할당 로직을 공통 유틸(예: `UniqueNameAllocator`)로 추출해 두 레이어에서 공유하면 테
  스트가 수월합니다.
- 엔터티 필드 추가 시 기존 데이터를 마이그레이션해야 하므로, 앱 최초 실행 때 `nameKey`를
  역산해 채우는 스크립트를 고려해야 합니다.
- `deleteFolderCascade`에서 노트가 많을 경우 파일 삭제 시간이 길어질 수 있으니, 저장소가
  반환한 ID 리스트를 기반으로 병렬 삭제(예: isolate/compute) 전략도 검토할 가치가 있습니다.
- 저장소 API 확장이 끝나면 `VaultNotesService`는 사실상 orchestration에 집중할 수 있으므
  로, 장기적으로는 기능별 usecase 클래스로 분할하는 것도 고려해볼 만합니다.
