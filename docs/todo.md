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

5. 컨트롤러/설정 Provider 도입

- [ ] `transformationControllerProvider(noteId)` family로 수명/해제 관리(`ref.onDispose`로 dispose)
- [ ] `simulatePressure` 정책 결정 및 반영
  - [ ] 전역 유지가 필요하면 `@Riverpod(keepAlive: true)`
  - [ ] 노트별이면 `simulatePressurePerNote(noteId)` family
  - [ ] `NoteEditorToolbar`는 값/세터를 provider로 직접 연결( prop 제거 )

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
