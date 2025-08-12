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
- [x] `totalPages == 0`인 경우 캔버스/툴바 렌더링 차단하여 null 접근/범위 초과 방지 (툴바는 숨김 처리, 캔버스는 0 아이템 안전)

5. 컨트롤러/설정 Provider 도입

- [x] `transformationControllerProvider(noteId)` family로 수명/해제 관리(`ref.onDispose`로 dispose)
- [x] `simulatePressure` 정책 결정 및 반영
  - [x] 전역 유지가 필요하면 `@Riverpod(keepAlive: true)`
  - [x] 노트별이면 `simulatePressurePerNote(noteId)` family
  - [x] `NoteEditorToolbar`는 값/세터를 provider로 직접 연결( prop 제거 )
  - [x] 재생성 없이 반영: `ref.listen(simulatePressureProvider)`로 기존 CSN에 런타임 주입(`setSimulatePressureEnabled`)하여 히스토리 보존

### 10. 툴바 전역 상태 및 링커 관리 설계

- [x] 툴바 전역 상태 공유 설계/구현 (노트별 공유)

  - [x] `ToolSettings` 모델 정의: `selectedTool`(펜/지우개/링커), `penColor/penWidth`, `highlighterColor/highlighterWidth`, `eraserWidth`, `linkerColor` (pointerMode는 ScribbleState로 유지)
  - [x] Provider 선택: 노트별 공유(`toolSettingsNotifierProvider(noteId)`)
  - [x] Toolbar ←→ Provider 양방향 연결: UI에서 변경 시 Provider 업데이트, Provider 변경 시 모든 페이지 `CustomScribbleNotifier`에 반영
  - [x] 동기화 전략: `ref.listen(toolSettingsNotifierProvider(noteId))`로 모든 페이지 CSN에 일괄 주입 (재생성 금지, 히스토리 보존)
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

10. 전반 구조 개선

11. 페이지 컨트롤러 확장(추가/삭제/순서 변경)

- [ ] 데이터 모델/리포지토리
  - [ ] 노트의 페이지 컬렉션에 대한 추가/삭제/재정렬 기본 연산 정의(원자적 업데이트, 인덱스 재매핑 포함)
  - [ ] 업데이트 시 현재 페이지 인덱스 보정(삭제/이동 후 범위 내로 클램프)
  - [ ] 연산 단위 트랜잭션 처리(메모리/DB 공통 정책) 및 변경 이벤트 스트림 발행
- [ ] 상태/컨트롤러
  - [ ] 페이지 컨트롤러는 리포지토리 변화에 동기화(페이지 수/순서 변경 시 애니메이션 반영)
  - [x] 페이지별 그리기 상태 캐시/노티파이어 재구성 및 안전한 dispose 처리 (pageId 기반 캐시, 증분 동기화)
  - [ ] 작업 중 UI 잠금/로딩 표기(대량 재정렬/일괄 삭제 대비)
- [ ] UI/동작
  - [ ] 추가: 현재 페이지 기준 위치에 빈 페이지 삽입(배경 기본값/초기 스타일 적용), 완료 후 해당 페이지로 포커스 이동
  - [ ] 삭제: 확인 다이얼로그 → 삭제 후 인덱스 보정(마지막 1장 정책: 빈 페이지 자동 생성 또는 0장 허용 정책 결정)
  - [ ] 순서 변경: 재정렬 가능한 리스트/그리드 제공, 커밋 시 리포지토리 일괄 반영(취소/되돌리기 정책은 추후)
  - [ ] 오류/경합: 동시 편집 대비 낙관적 업데이트 + 실패 시 롤백/토스트 안내

12. 노트 삭제 흐름 정리(에러 복구 옵션 포함)

- [ ] 진입점 통합: 목록 화면/편집 화면/복구 실패 바텀시트에서 동일 삭제 플로우 호출
- [ ] 사용자 확인: 제목/페이지 수 요약 + 영구 삭제 경고/취소 옵션 제공
- [ ] 선행 정리: 자동 저장/썸네일 생성 등 백그라운드 작업 취소, 뷰/컨트롤러 언바인딩
- [ ] 데이터 삭제: 리포지토리 호출로 본문/페이지/메타/첨부/캐시 일관 삭제(스토리지/파일 포함, 필요 시 캐스케이드)
- [ ] 후속 처리: 네비게이션 복귀, 최근 열람 목록/상태 초기화, 토스트/스낵바 안내
- [ ] 실패 처리: 부분 실패 시 재시도/로그 수집/사용자 메시지(파일 잠금, 권한 문제 등)

13. 페이지 미리보기(썸네일) 생성/캐시

- [ ] 렌더링 파이프라인
  - [ ] 오프스크린 렌더링으로 배경 + 손글씨를 축소 합성하여 썸네일 비트맵 생성(종횡비 유지)
  - [ ] 목표 해상도/품질 정책 정의(예: 짧은 변 ~200–300px, 압축 품질 중간)
  - [ ] 메인 스레드 프리즈 방지: 백그라운드 처리/동시 작업 수 제한/디바운스
- [ ] 캐싱/무효화
  - [ ] 메모리 + 디스크 캐시 계층화(키: noteId/pageIndex/리비전)
  - [ ] 변경 트리거(선/색/굵기/배경 변경, 페이지 리네임/리사이즈) 시 지연 무효화 → 재생성 스케줄링
  - [ ] 초기 로드 시 가시 범위 우선 생성, 스크롤/가시성 기반 사전 생성
- [ ] 사용처/UX
  - [ ] 페이지 컨트롤러/재정렬 UI에 썸네일 사용, 로딩 중 플레이스홀더/스켈레톤 제공
  - [ ] 저장/공유/내보내기 등 다른 기능에서도 동일 썸네일 재사용

14. PDF 내보내기

- [ ] 요구사항/옵션 정의
  - [ ] 페이지 크기/방향/여백 정책(캔버스 규격과 1:1 또는 맞춤 스케일)
  - [ ] 배경 포함 여부, 손글씨 품질(벡터/래스터) 선택, 메타데이터(제목/작성일) 포함
  - [ ] 내보내기 범위(전체/선택 페이지), 파일명 규칙, 저장 위치/공유 옵션
- [ ] 구현 전략
  - [ ] 각 페이지를 순회 렌더링하여 PDF 페이지로 추가(메모리 폭주 방지: 스트리밍/청크 처리)
  - [ ] 진행률 표시/취소 가능 UI, 실패 시 재시도/부분 저장 처리
  - [ ] 결과 파일 검증(열림 확인), 권한/저장소 경로 예외 처리, 완료 후 공유 시트 연동
- [ ] 성능/품질
  - [ ] 긴 문서 처리 시간 최적화(병렬/시리얼 균형), 이미지 압축/해상도 튜닝
  - [ ] 시각 품질 리그레션 체크(썸네일과 PDF 렌더 간 시각 일치성)

### 후속 개선 아이디어

- [ ] `currentNoteProvider(noteId)` 등 파생 상태(제목, 페이지 수 등) 노출
- [ ] `simulatePressure`를 노트별로 DB에 영속화(사용자 경험 유지)
