## 해야 할 일

### 목표 개요

- noteId 기반 단방향 데이터 흐름 확립(화면/라우팅은 noteId만 전달)
- Repository 도입으로 데이터 접근 추상화 (메모리 → Isar 교체 용이)
- Riverpod 완전 도입(노트/컨트롤러/설정값 등 상태 공급자화)

### 우선순위/의존성 정리(위에서부터 순차 진행 권장)

1. Repository 인터페이스 정의 [최우선]

- [x] `NotesRepository` 설계: `watchNotes()`, `watchNoteById(id)`, `getNoteById(id)`, `upsert(note)`, `delete(id)`
- [ ] 단위 테스트 초안(선택)

2. 메모리 구현 + Provider 배선

- [x] `MemoryNotesRepository` 구현(임시 저장소)
- [x] `notesRepositoryProvider` (keepAlive)
- [x] 파생 Provider 구성
  - [x] `notesProvider`: `Stream<List<NoteModel>>`
  - [x] `noteProvider(noteId)`: `Stream<NoteModel?>`
  - [x] `noteOnceProvider(noteId)`: `Future<NoteModel?>` (선택)
  - [ ] 기존 `fakeNotes` 참조 제거 작업 항목 추가 (아래 7번과 연결)

3. 라우팅/화면을 noteId 중심으로 리팩토링

- [x] `CanvasRoutes`: builder는 noteId만 받고, 화면 내부에서 provider로 Note 구독(가능하면 `extra`는 선택사항)
- [x] `NoteEditorScreen`: noteId만 입력 → `noteProvider(noteId)` watch로 로딩/에러 처리 포함 (AppBar 타이틀 provider 적용)

4. 캔버스 상태 리팩토링(Provider 완전 도입)

- [x] `CustomScribbleNotifiers`: `noteProvider(noteId)`(AsyncValue) 의존으로 페이지 변화 시 notifier 맵 재생성/정리
- [x] `NoteEditorCanvas`: 내부에서 필요한 provider 직접 watch(불필요 prop 제거)
- [x] `NotePageViewItem`: 현재 형태 유지(필요 시 최소한 변경) 및 provider 의존으로 self-contained 처리
  - [x] per-page 위젯은 `pageNotifierProvider(noteId, pageIndex)` 사용, 상위(툴바 등)는 `currentNotifierProvider(noteId)` 사용
  - [x] dispose 단계에서 `ref.read` 호출 금지 → `TransformationController`를 `initState`에서 캐싱하여 리스너 등록/해제 처리
- [ ] `totalPages == 0`인 경우 캔버스/툴바 렌더링 차단하여 null 접근/범위 초과 방지

5. 컨트롤러/설정 Provider 도입

- [x] `transformationControllerProvider(noteId)` family로 수명/해제 관리(`ref.onDispose`로 dispose)
- [x] `simulatePressure` 정책 결정 및 반영
  - [x] 전역 유지가 필요하면 `@Riverpod(keepAlive: true)`
  - [x] 노트별이면 `simulatePressurePerNote(noteId)` family
  - [x] `NoteEditorToolbar`는 값/세터를 provider로 직접 연결( prop 제거 )

### 10. 툴바 전역 상태 및 링커 관리 설계

- [ ] 툴바 전역 상태 공유 설계/구현

  - [ ] `ToolSettings` 모델 정의: `selectedTool`(펜/지우개/링커…), `selectedColor`, `selectedWidth`, `eraserWidth`, `pointerMode`
  - [ ] Provider 선택: 전역 공유(`@Riverpod(keepAlive: true) toolSettingsProvider`) 또는 노트별 공유(`toolSettingsProvider(noteId)`) 정책 결정
  - [ ] Toolbar ←→ Provider 양방향 연결: UI에서 변경 시 Provider 업데이트, Provider 변경 시 `CustomScribbleNotifier`들에 반영
  - [ ] `CustomScribbleNotifiers`와의 동기화 전략: 현재/모든 페이지에 일괄 반영 여부 정의(성능 고려)
  - [ ] 앱 재진입 시 상태 복원 필요 여부 결정 및 영속화 방안(선택: Repository/Prefs)

- [ ] 링커 데이터 관리 및 영속화 방안

  - [ ] `LinkerRect` 모델 정의: `id`, `noteId`, `pageIndex`, `rectNormalized`(left/top/width/height; 캔버스 크기 대비 정규화), `style`
  - [ ] 편집 상태 Provider: `linkerRectsProvider(noteId, pageIndex)`에서 추가/수정/삭제 및 선택 상태 관리
  - [ ] 저장 지점 결정: 페이지 이탈/주기적 자동 저장/명시적 저장 트리거 등
  - [ ] 영속화 위치: `NotePageModel.linkers` 추가 또는 별도 `LinkRepository`로 분리(양자 택일; 마이그레이션 영향 검토)
  - [ ] 탭 시 동작: 링크 탐색/링크 생성/삭제/속성 편집 등 바텀시트 옵션 연결(현 `LinkerGestureLayer` 이벤트 연계)
  - [ ] 표시 옵션: 링커 레이어 on/off 토글(툴바에 스위치 배치)
  - [ ] 좌표 정규화/복원 유닛테스트 추가(확대/축소/패닝과 무관하게 동일 구역 유지 확인)

- [ ] 성능/안정성
  - [ ] 링커 사각형 변경 시 디바운스/스로틀 적용(불필요 리빌드/저장 방지)
  - [ ] 대량 링커 시 페인팅/히트테스트 비용 점검 및 최적화(예: 간단한 R-Tree/그리드 파티셔닝)

6. 서비스 계층 연동 정리

- [ ] `PdfRecoveryService`: 호출부에서 provider로 Note를 조회한 뒤 전달(또는 추후 Repository 기반 업데이트로 리팩토링)
- [ ] 삭제 흐름: 파일 정리 후 `repository.delete(noteId)` 호출(트랜잭션 고려는 DB 도입 시)

7. Fake 데이터 완전 제거

- [ ] `lib/features/notes/data/fake_notes.dart` 및 전 참조 제거
  - [ ] `lib/features/notes/pages/note_list_screen.dart`의 `fakeNotes.add` → `notesRepositoryProvider.upsert`
  - [ ] `lib/features/canvas/providers/note_editor_provider.dart`의 `fakeNotes` 접근 제거 → `noteProvider(noteId)` 사용
  - [ ] `lib/shared/services/pdf_recovery_service.dart`의 `fakeNotes` 접근 제거 → 리포지토리 경유로 변경
- [ ] 관련 문서의 예시 코드 업데이트

8. 테스트/검증

- [ ] `dart analyze` 무오류 확인
- [ ] 수동 회귀 검증: 페이지 네비게이션/필기/링커/PDF 복구 흐름

9. Isar DB 도입(별도 담당 개발자)

- [ ] `IsarNotesRepository` 구현(스키마/매핑 포함)
- [ ] `ProviderScope`에서 `notesRepositoryProvider`를 Isar 구현으로 override(런타임 교체)

### 후속 개선 아이디어

- [ ] `currentNoteProvider(noteId)` 등 파생 상태(제목, 페이지 수 등) 노출
- [ ] `simulatePressure`를 노트별로 DB에 영속화(사용자 경험 유지)
