# F(features) 에 D(design) 을 결합 세부 명세

## D(design) 상황

`lib/design_system/screens/` 에 데모 페이지 존재
각 컴포넌트 일부 분리되어 `assets`, `components` 등 폴더에 존재
더미 데이터와 UI 동작을 위한 더미 모델, 더미 라우터가 존재
기능 연결 안되어있는 디자인 확인 용

## F(features) 상황

전체 기능 구현 완료
서비스, UI 분리 완료. 일부는 혼재 가능 (`note_list_screen` 등)
디자인 컴포넌트를 기능 페이지에 구현

## `note_list_screen` 적용

### F 구현 상황

`note_list_screen` 이 메인 화면
진입 시 `default_vault` 로 설정된 vault 내부 트리 요소 제공
기능 테스트를 위한 여러 기능이 UI 상으로 바로 노출
추후 세부 각 icon 클릭 시 기능으로 분리 필요한 상황

### D 요구 사항

첫 화면 `home_screen` 이 메인 화면
진입 시 vault 선택 화면 제공 (기본적으로 folder 선택과 동일)

#### 1. vault 선택 화면의 경우

클릭 시 해당 vault 로 이동하는 vault (folder 와 동일 아이콘) 아이콘
앱 전역 설정 아이콘 - 클릭 시 전역 설정 화면으로 이동
vault 추가 아이콘 - 클릭 시 vault 추가 창? 오픈
롱 탭 - vault 이름 변경

#### 2. vault 선택 이후 내부 tree 아이템 표현 화면의 경우

클릭 시 해당 folder 로 이동하는 folder 아이콘
클릭 시 note 편집 화면으로 이동하는 note 아이콘 (또는 저장된 미리보기 썸네일)
상위 폴더로 이동 (..) 이름을 가진 폴더 아이콘
빈 노트 추가 아이콘 - 클릭 시 노트 추가 (앞서 vault 추가 창과 동일) 창 오픈
폴더 추가 아이콘 - 클릭 시 폴더 추가
pdf 노트 추가 아이콘 - 클릭 시 pdf 불러오는 창 표시
노트 검색 아이콘 - 노트 검색 가능 창으로 이동
노트 아이콘 롱탭 - 이름 변경, 삭제, 이동
폴더 아이콘 롱탭 - 이름 변경, 삭제, 이동
이름 변경의 경우 '생성'과 동일한 모달 창 열림 (아마 그럴거같은데 세부 구현은 디자인 데모 코드 참고)
vault 의 루트일 경우 `vault` 선택 화면으로 이동하는 상위 폴더로 이동 아이콘 존재
그래프 뷰 아이콘 - 그래프 뷰 화면으로 이동 (vault 기반)

### 현재 구현 스냅샷 (2025-09-19)

- 진입 시 `currentVaultProvider` 가 `null` 이면 **Vault 선택 뷰**만 렌더링한다.
  - Vault 카드 목록 + `Vault 생성` 버튼.
  - 롱프레스 시 이름 변경/삭제를 모달 시트로 제공.
- Vault 선택 후에는 **Vault 내부 뷰**가 나타난다.
  - 상단 조작부는 `Vault 선택으로 이동`, `그래프 보기` 버튼만 보여준다(이름 변경/삭제 제거).
  - 루트 폴더일 때는 “Vault 선택으로 이동” 버튼을 노출, 하위 폴더에서는 “한 단계 위로”.
  - PDF/노트 생성 CTA, 폴더/노트 리스트는 선택된 상태에서만 활성화.
- `NoteListController` 는 Vault 미선택 상태에서 PDF/노트 생성 요청이 들어오면 안내 메시지를 반환하고 아무것도 생성하지 않는다.

### 결정 사항

1. **화면 구조**: 단일 위젯 내에서 `hasActiveVault` 플래그로 Vault 선택/내부 뷰를 토글하는 현 구조를 유지한다. 디자인 컴포넌트 도입 시 `VaultSelectorView` / `VaultContentView` 같은 프리젠테이션 위젯으로 분리하는 것을 최종 목표로 한다.
2. **Vault 액션 범위**: Vault 선택 화면(카드 목록)에서만 Vault 이름 변경/삭제를 허용한다. Vault 내부에서는 상단 버튼 제거.
3. **루트 탈출 경로**: 루트 폴더일 때 “Vault 선택으로 이동” 버튼을 노출해 빠져나오도록 한다.
4. **생성 CTA 범위**: Vault가 선택된 상태에서만 PDF/빈 노트 생성 버튼을 노출한다.

### 미해결/추가 정의 필요 항목

| 항목                     | 상태            | 메모                                                                                             |
| ------------------------ | --------------- | ------------------------------------------------------------------------------------------------ |
| TopToolbar / Bottom Dock | **미정**        | 디자인 `TopToolbar`, `BottomActionsDockFixed` 를 기능 화면에서 어떻게 재사용할지 구조 설계 필요. |
| PDF/노트 생성 위치       | **재확인 필요** | Vault 내부에서만 노출 중. 디자인 요구와 일치하는지 최종 확인.                                    |
| 전역 설정/검색 버튼      | **미정**        | 홈 툴바에 자리만 준비돼 있음. 실제 화면/라우트 정의 필요.                                        |
| 뷰 분리 전략             | **검토 예정**   | hasActiveVault 분기를 유지하되, 디자인 적용 시 두 개의 Stateless View로 나누는 리팩토링 계획.    |

### 다음 단계 제안

1. `VaultSelectorView`, `VaultContentView`(가칭) 같은 프리젠테이션 컴포넌트를 만들어 현재 조건 분기를 위젯 수준에서 분리.
2. 검색 전용 화면(라우트) 설계 및 기존 인라인 검색 필드 교체.
3. 디자인 시스템의 `TopToolbar`, `FolderGrid`, `BottomActionsDockFixed` 를 기능 화면에서 직접 사용하도록 props/콜백 정의.
4. Vault 내부 CTA(노트/폴더/PDF 생성, 상단 버튼)를 디자인 가이드에 맞춰 최종 정렬.
### 2025-03-?? 작업 정리

- note_list_screen( `lib/features/notes/pages/note_list_screen.dart` )에서 뷰 계층을 action bar + 리스트 패널로 재구성. 상단 `NoteListActionBar` (`lib/features/notes/widgets/note_list_action_bar.dart`)을 추가해 Vault/폴더 생성, 한 단계 위로, Vault 목록으로 이동을 한 레이어에서 처리함. 본문 컴포넌트는 순수 목록 역할만 담당하도록 분리.
- `lib/features/notes/widgets/note_list_vault_panel.dart`에 카드별 퀵 액션(이름 변경, 삭제)을 추가. Vault 개수가 1개일 때 삭제 아이콘은 비활성화하고 툴팁으로 안내. 기존 롱프레스 바텀시트 제거.
- `lib/features/notes/widgets/note_list_folder_section.dart`는 카드 그리드/아이콘만 유지하고 액션 버튼은 상단 바에서 처리하도록 간소화.
- 서비스/저장소 레벨 방어 로직 변경.
  * `lib/shared/services/vault_notes_service.dart`의 `deleteVault`가 전체 Vault 수를 검사해 마지막 Vault 삭제 시 `FormatException`을 던지도록 수정.
  * `lib/features/vaults/data/isar_vault_tree_repository.dart`의 `_ensureDefaultVault`는 DB가 완전히 비어 있을 때만 기본 Vault를 생성. rename/delete 후 “Default Vault”가 다시 생기는 현상 예방.
- UI guard도 동일 규칙 사용 (Vault 한 개일 때 삭제 버튼 비활성화)으로 일관성 확보.

#### 해결 배경/접근
- 기본 Vault가 이름 변경/삭제 상황에서 재생성되면서 UI 흐름을 깨뜨리는 문제가 있어, 저장소 초기화와 서비스 레벨에서 "최소 1개" 규칙만 유지하도록 재설계.
- 노트 목록 화면은 디자인 시스템 위젯을 그대로 가져다 쓰기 위해 액션과 뷰를 분리하고, 삭제/생성 버튼이 이중으로 보이던 문제를 해소.

#### 남은 이슈/추가 고려사항
1. Analyzer info 경고(문서화, deprecated withOpacity 등)가 프로젝트 전반에 남아 있음 → 추후 정리 필요.
2. `NoteListActionBar`/`VaultListPanel` 스타일을 디자인 시스템 토큰에 맞춰 세부 정리(색상, hover 등).
3. 마지막 Vault 삭제 거부 시 사용자 피드백을 더 명확히(별도 SnackBar 등) 제공할지 논의 필요.
4. 테스트 미보유 → 기본 vault 삭제/재생성 케이스에 대한 unit/integration test 추가 고려.
