# VaultNotesService Implementation Status & Plan

본 문서는 `docs/services/vault-notes-service.md` 명세를 바탕으로 현재 구현 현황, 남은 작업, 구현 계획, 유의점을 정리합니다.

## 구현 목표

- 생성/삭제/링크 작업을 VaultNotesService로 일원화하여 트리(Placement)와 콘텐츠의 일관성 보장
- cross‑vault 링크·조작 차단(필수)
- 브라우저(노트 목록/탐색)를 Placement(vault/folder) 기준으로 전환
- 기본 예외 처리(이름 정책/중복/미존재/교차 vault/IO) 적용
- tombstone/작업 로그/커밋 토큰/고급 트랜잭션은 추후 과제로 이관

## 지금까지 수행한 작업

- 서비스 경유 생성/삭제로 전환
  - `lib/features/notes/pages/note_list_screen.dart`
    - 빈 노트 생성 → `vaultNotesService.createBlankInFolder(vaultId, parentFolderId)`
    - PDF 노트 생성 → `vaultNotesService.createPdfInFolder(vaultId, parentFolderId)`
    - 삭제 → `vaultNotesService.deleteNote(noteId)`
- 링크 생성/편집 cross‑vault 차단 + 서비스 사용
  - `lib/features/canvas/providers/link_creation_controller.dart`
    - `getPlacement(sourceNoteId)`로 소스 vault 결정
    - 타깃 by ID: placement 확인 후 같은 vault인지 검증(불일치 시 예외)
    - 타깃 by 제목: 같은 vault의 Placement 이름에서만 일치 매칭, 없으면 서비스로 해당 vault 루트에 새 노트 생성
    - self‑link 차단
- NoteDeletionService 전면 교체
  - `CanvasBackgroundWidget`의 모든 삭제 흐름을 `VaultNotesService.deleteNote`로 교체
  - `PdfRecoveryService.deleteNoteCompletely`는 서비스에 위임하도록 시그니처 변경
- 브라우저(리스트) 데이터 소스 전환
  - `NoteListScreen`이 `vaultsProvider + currentVaultProvider + currentFolderProvider(vaultId) + vaultItemsProvider(FolderScope)` 기반으로 렌더링
  - 폴더 우선 → 노트 순으로 Placement 목록을 표시, 클릭 시 폴더 이동/에디터 진입
  - 생성/삭제는 현재 vault/folder 컨텍스트를 사용

## 앞으로 남은 작업(우선순위)

1. 브라우저 UX 보강

- 폴더 탐색 UX: 루트 이동 외에 상위 폴더로 한 단계씩 이동(간단 breadcrumb)
- 노트 카드에 페이지 수 표시(지연 콘텐츠 로드 또는 별도 메타 캐시)

2. Vault 선택 UX

- 다중 vault 대비: `vaultsProvider`로 선택 UI 제공, 선택 시 `currentVaultProvider` 갱신 및 `currentFolderProvider(vaultId)=null` 초기화

3. 간단 검색(후속)

- `VaultNotesService.searchNotesInVault(vaultId, query)`(Placement 기반, 케이스 비구분, 부분/정확 일치 옵션)
- 링크 서제스트·브라우저 필터 등에 재사용

4. 예외/메시지 정비(필수 최소)

- `FormatException`(이름 정책), 이름 중복/사이클/미존재/cross‑vault/IO를 사용자 메시지로 매핑
- 리스트/에디터/링크 UI에서 일관된 Snackbar/다이얼로그 노출

5. 동시성(차후)

- 간단 per‑vault 뮤텍스 도입(VaultNotesService 내부 래퍼)로 동일 vault 유스케이스 직렬화

6. 테스트 보강

- 서비스 유스케이스(생성/삭제/이름변경/이동/폴더 캐스케이드) 성공/실패 테스트
- cross‑vault 차단 테스트, Placement 기반 브라우저 업데이트 테스트

7. 정리 작업

- `lib/shared/services/note_deletion_service.dart`는 더 이상 사용하지 않음 → 추후 삭제/문서 업데이트

## 남은 작업 구현 상세 계획

1. 브라우저 UX 보강

- 상위 폴더 이동: `currentFolderProvider(vaultId)`를 현재 폴더의 `parentFolderId`로 갱신(필요 시 상위 탐색 유틸 추가)
- 노트 페이지 수 표시: 에디터 진입 전에는 표시 생략 또는 hover/디테일 패널에서 지연 조회(`notesRepo.getNoteById(noteId)`)

2. Vault 선택 UX

- 상단에 간단 드롭다운/버튼 그룹 추가 → `vaultsProvider`로 목록, 선택 시 `currentVaultProvider` 세팅 및 폴더 컨텍스트 초기화

3. 검색 API(Placement 기반)

- VaultNotesService에 `Future<List<NotePlacement>> searchNotesInVault(String vaultId, String query, {bool exact=false})`
- 구현: `watchFolderChildren(...).first`를 BFS로 순회, `NameNormalizer.compareKey`로 비교
- 링크 서제스트/타이틀 매칭로직을 서비스 API로 대체해 중복 제거

4. 예외/메시지 정비

- 서비스 public API에서 throw되는 예외를 일괄 래핑/변환(간단 enum+message 코드)
- UI: 공통 스낵바 헬퍼로 메시지 통일

5. per‑vault 뮤텍스(간단)

- `Map<String, Object>`의 락 오브젝트 + `Future` 큐로 직렬화
- VaultNotesService의 public 메서드 입구에서 vaultId 단위로 순차 실행 보장

6. 테스트

- 메모리 구현 기반 단위/위젯 테스트: 생성/삭제 흐름, 링크 cross‑vault 차단, 폴더 이동 시 목록 업데이트

## 유의점

- 표시명 소스는 항상 Placement.name이며, NoteModel.title은 미러(표시 편의)임
- 현재 Placement 검색은 BFS+`watchFolderChildren(...).first`로 충분(메모리 구현). 추후 Isar 도입 시 인덱스 최적화 필요
- `NoteListScreen`에서 최초 vault 자동 선택은 첫 vault로 지정(없을 경우 로딩 처리). 실제 앱에선 명시 선택 UI 권장
- `PdfRecoveryService.deleteNoteCompletely` 시그니처 변경: 호출부는 `VaultNotesService`를 주입해야 함
- `NoteDeletionService`는 더 이상 사용하지 않으며, 향후 삭제 시 문서/가이드도 함께 갱신 필요

---

문의/다음 단계 제안

- 브라우저 UX(상위 폴더 이동, vault 선택) 먼저 반영 후, 검색 API와 메시지 정비를 진행하는 순서를 권장합니다.

---

## 추가 과제: 폴더/Vault UI 및 이동 로직

요구사항

- 폴더 추가 버튼 제공(현재 폴더 컨텍스트에 새 폴더 생성)
- Vault 추가 버튼/선택 UI 제공(다중 vault 전환)
- 폴더/노트 이동 로직 UI (동일 vault 내 이동)
- “vault 간 이동”은 “현재 vault 전환”을 의미(엔티티의 cross‑vault 이동은 정책상 금지)

설계 원칙

- 생성/삭제/이동의 트리 조작은 Placement 기준(트리 레포 또는 서비스)으로 수행
- 이름 정책/중복은 트리에서 검증; 예외 메시지는 UI에서 사용자 친화적으로 노출
- cross‑vault 이동/링크는 차단(명시 메시지)

세부 구현 계획

- 폴더 생성 UI

  - 위치: NoteListScreen 상단 도구영역에 “폴더 추가” 버튼 배치(현재 vault/folder 컨텍스트 필요)
  - 플로우: 클릭 → 이름 입력 다이얼로그 → `vaultTree.createFolder(vaultId, parentFolderId: currentFolderId, name: input)` 호출 → 성공 시 현재 목록 자동 갱신
  - 예외 처리: 빈 이름/금지 문자/중복 시 다이얼로그 에러 표시(NameNormalizer/트리 예외 메시지 매핑)

- Vault 생성/선택 UI

  - 위치: NoteListScreen 상단에 드롭다운(또는 팝오버) + “Vault 추가” 버튼
  - 플로우(생성): 버튼 → 이름 입력 → `vaultTree.createVault(name)` → `currentVaultProvider`를 새 vaultId로 업데이트 + `currentFolderProvider(vaultId)=null`
  - 플로우(선택): 드롭다운에서 vault 선택 → `currentVaultProvider` 갱신 → 폴더 컨텍스트 초기화(null)
  - 예외 처리: 이름 정책/중복(동일 이름 허용은 정책 상 가능, 표시상 혼동 방지 위해 경고 메시지 선택 사항)

- 폴더/노트 이동 UI(동일 vault)

  - 위치: 각 카드의 more(⋯) 아이콘 → “이동” 항목
  - 폴더 선택기(FolderPicker) 다이얼로그
    - 구현: `watchFolderChildren(vaultId, parentFolderId)`를 BFS로 순회해 트리 구조를 리스트/트리뷰로 렌더
    - 선택 제약:
      - 노트 이동: 타깃은 동일 vault의 임의 폴더(또는 루트)
      - 폴더 이동: 자기 자신/자손 폴더로 이동 금지(트리 레포가 사이클 검증, UI에서도 현재 선택/하위는 disable 처리 권장)
  - 저장 로직:
    - 노트: `vaultNotesService.moveNote(noteId, newParentFolderId: pickedFolderId)`
    - 폴더: `vaultTree.moveFolder(folderId: id, newParentFolderId: pickedFolderId)`
  - 예외 처리: `Cycle detected`/`Folder not found`/`Different vault` 등 예외 메시지 스낵바 노출

- 상위 폴더로 이동(Up navigation)
  - 간단 버전: “한 단계 위로” 버튼 추가 → 현재 폴더의 parentFolderId로 이동
  - 필요한 API: `VaultTreeRepository.getFolder(folderId)`(부재 시 추가 권장) 또는 UI에 최근 클릭한 `VaultItem`로부터 parent를 저장
  - 장기: breadcrumb(루트→…→현재 폴더) 구현(폴더 rename 반영 위해 repo 조회가 바람직)

데이터/상태 변경 사항

- `VaultTreeRepository` 인터페이스 확장(권장)
  - `Future<FolderModel?> getFolder(String folderId)` 추가 → 상위 탐색과 breadcrumb 구성 용이
- 새 위젯/헬퍼
  - `FolderPickerDialog(vaultId, initialFolderId)`(공용): 이동/선택 다이얼로그
  - 공통 다이얼로그 유틸: 이름 입력, 에러 메시지 표준화

테스트 체크리스트

- 폴더 생성: 같은 폴더 경로에서 이름 충돌 시 차단 메시지 확인
- 노트 이동: 다른 폴더로 이동 후 두 폴더 목록이 즉시 갱신
- 폴더 이동: 자기/자손으로 이동 시도 시 차단, 정상 경로 이동 후 자식/노트가 함께 이동됨
- Vault 생성/전환: 전환 시 컨텍스트 초기화 및 목록 갱신 확인

유의점

- cross‑vault 이동은 지원하지 않음(정책). 사용자 요청 시 “다른 vault로는 이동할 수 없습니다” 명확히 안내
- FolderPicker는 대규모 트리에서 성능 이슈 가능(현 메모리 구현에선 문제 없음). 추후 Isar 도입 시 폴더 인덱스/지연 로드 고려
- 이름 입력 UX: 금지 문자/길이/예약어는 즉시 검증 피드백 제공
