# Session Problem Solving History

## Problem Summary

The Flutter/Riverpod note-taking application faced two critical issues:

1. **Race Conditions**: PDF export and page reordering operations caused notifier cache to disappear
2. **"Bad state: No canvas session for pageId"**: Error when first entering a note

## Root Cause Analysis

The core issue was timing problems between:

- Widget lifecycle (initState/dispose)
- Provider initialization
- Session management
- Manual cache management complexity

The user's explicit intent: "캐시 지울거야. 없앨거야. riverpod이 생명주기 관리하도록 위임할거라고"

## Solution Evolution

### Phase 1: Session-Based Architecture

**Objective**: Replace manual cache management with Riverpod-based session management

**Key Implementation**:

```dart
// CanvasSession provider for note-level session management
@riverpod
class CanvasSession extends _$CanvasSession {
  @override
  String? build() => null;

  void enterNote(String noteId) => state = noteId;
  void exitNote() => state = null;
}

// Session-based page notifier
@riverpod
CustomScribbleNotifier canvasPageNotifier(Ref ref, String pageId) {
  final activeNoteId = ref.watch(canvasSessionProvider);
  if (activeNoteId == null) {
    throw StateError('No canvas session for pageId: $pageId');
  }
  ref.keepAlive();
  // ... notifier creation logic
}
```

**Widget Integration**:

```dart
@override
void initState() {
  super.initState();
  ref.read(canvasSessionProvider.notifier).enterNote(widget.noteId);
}

@override
void dispose() {
  ref.read(canvasSessionProvider.notifier).exitNote();
  super.dispose();
}
```

### Phase 2: Timing Issues Discovery

**Problem 1**: Using `postFrameCallback` caused "No canvas session" errors

- Providers were called before session was established

**Problem 2**: Immediate `initState` execution caused Riverpod constraint violation

- "Tried to modify provider while widget tree was building"
- Riverpod prevents provider modification during widget lifecycle methods

### Phase 3: GoRouter-Based Automatic Solution

**Proposed Architecture**: Eliminate widget-level session management entirely

**Core Concept**: Use GoRouter route changes to automatically trigger session start/stop

**Flow Design**:

1. **Route Pattern**: `/notes/{noteId}/edit` automatically triggers session
2. **Session Start**: When navigating TO note edit screen
3. **Session End**: When navigating AWAY from note edit screen
4. **No Widget Code**: Zero session management code in widgets

**Provider Structure**:

```dart
// 1. Note session state
@riverpod
class NoteSession extends _$NoteSession {
  @override
  String? build() => null;
  // Session management methods
}

// 2. GoRouter instance access
@riverpod
GoRouter goRouter(Ref ref) => GoRouter.of(context);

// 3. Current route path watching
@riverpod
String? currentPath(Ref ref) {
  // Watch current route path
}

// 4. Session observer - the key component
@riverpod
class NoteSessionObserver extends _$NoteSessionObserver {
  @override
  void build() {
    final currentPath = ref.watch(currentPathProvider);
    _handleRouteChange(currentPath);
  }

  void _handleRouteChange(String? path) {
    if (path?.startsWith('/notes/') == true && path?.endsWith('/edit') == true) {
      // Extract noteId and start session
      final noteId = extractNoteIdFromPath(path!);
      ref.read(noteSessionProvider.notifier).enterNote(noteId);
    } else {
      // End any active session
      ref.read(noteSessionProvider.notifier).exitNote();
    }
  }
}
```

## Benefits Analysis

### Manual Session Management (Phase 1)

- ✅ Explicit control over session lifecycle
- ✅ Clear session boundaries
- ❌ Widget-level complexity
- ❌ Timing issues with Riverpod constraints
- ❌ Boilerplate code in every note screen

### Automatic GoRouter Management (Phase 3)

- ✅ Zero widget-level session code
- ✅ No timing issues
- ✅ Automatic session management
- ✅ Route-based session boundaries
- ✅ Centralized session logic
- ❌ Slightly more complex initial setup

## Technical Resolution

### Error Types Encountered

1. **Build Runner Generation Errors**

   - **Solution**: Run `fvm dart run build_runner build` after provider changes

2. **Import Missing Errors**

   - **Solution**: Add missing imports (e.g., `NoteModel`)

3. **Type Inference Errors**

   - **Solution**: Add explicit return types

4. **StateError "No canvas session"**

   - **Root Cause**: Timing between session establishment and provider access
   - **Solution**: GoRouter-based automatic management

5. **Riverpod Constraint Violation**
   - **Root Cause**: Provider modification during widget lifecycle
   - **Solution**: Move session management outside widget lifecycle

### Key Files Modified

- `/lib/features/canvas/providers/note_editor_provider.dart`

  - Added CanvasSession provider
  - Replaced CustomScribbleNotifiers class with individual providers
  - Implemented session-based notifier creation

- `/lib/features/canvas/pages/note_editor_screen.dart`
  - Added session lifecycle management (Phase 1)
  - To be removed in Phase 3 (GoRouter implementation)

## Implementation Status

### ✅ Completed

- Session-based provider architecture
- Manual session management implementation
- Error analysis and root cause identification

### 🔄 Pending

- GoRouter-based automatic session management
- Remove widget-level session code
- Testing of automatic session system

## Lessons Learned

1. **Riverpod Constraints**: Provider modification during widget lifecycle causes violations
2. **Timing Criticality**: Provider access timing must be carefully managed
3. **Architecture Evolution**: Sometimes the best solution requires rethinking the approach entirely
4. **Route-Based Management**: GoRouter can be leveraged for automatic lifecycle management

## Next Steps

1. Implement the 4-provider GoRouter system
2. Remove all widget-level session management
3. Test automatic session start/stop functionality
4. Validate race condition resolution

## User Intent Fulfillment

The progression from manual cache management → session-based providers → automatic GoRouter management directly addresses the user's core request to "eliminate cache management and delegate lifecycle to Riverpod" while solving the fundamental timing issues that prevented the simpler approaches from working.

---

## 진행에 앞서..

⏺ GoRouter 기반 세션 관리 플로우 분석

🔄 기존 수동 관리 vs 새로운 자동 관리

기존 방식 (Widget 수동 관리):

사용자 동작 Widget 반응 세션 상태
────────────────────────────────────────────────────────────
노트 목록 화면 - 세션 없음
"수학노트" 클릭 NoteEditorScreen.initState CanvasSession("math-id") 시작
→ enterNote() 호출
페이지 1,2,3 이동 - 세션 유지 (keepAlive)
PDF 모달 열기 - 세션 유지
뒤로가기 NoteEditorScreen.dispose CanvasSession.exitNote()
→ exitNote() 호출 → 모든 notifier dispose

새로운 방식 (GoRouter 자동 관리):

사용자 동작 Router 반응 세션 상태
────────────────────────────────────────────────────────────
노트 목록 화면 경로: /notes 세션 없음
"수학노트" 클릭 경로: /notes/math-id/edit Observer 감지
→ 패턴 매칭 성공 → CanvasSession("math-id") 자동 시작
페이지 1,2,3 이동 경로 변화 없음 세션 유지 (keepAlive)
PDF 모달 열기 경로 변화 없음 세션 유지
뒤로가기 경로: /notes Observer 감지
→ 패턴 매칭 실패 → CanvasSession.exitNote() 자동 종료

🏗️ 구조적 변화

기존 구조:

NoteEditorScreen (Widget)
├── initState() → CanvasSession 수동 시작
├── dispose() → CanvasSession 수동 종료
└── build() → canvasPageNotifier 사용

새로운 구조:

App Root
├── GoRouter → 경로 변경 감지
├── noteSessionObserver → 자동 세션 관리 ⭐ (새로 추가)
└── NoteEditorScreen (Widget) → 세션 코드 완전 제거 ⭐
└── build() → canvasPageNotifier 사용 (동일)

📋 세션 열기/닫기 조건

세션 열기 조건:

- 패턴: /notes/{noteId}/edit 매칭시
- 추출: noteId 파라미터
- 액션: CanvasSession.enterNote(noteId)

세션 닫기 조건:

- 패턴: /notes/{noteId}/edit 매칭 실패시
- 예시: /notes, /settings, / 등
- 액션: CanvasSession.exitNote()

세션 유지 조건:

- 같은 noteId: /notes/abc/edit → /notes/abc/pages (보통은 없지만)
- 모달/팝업: URL 변화 없음
- 페이지 내 이동: PageView 등은 URL 영향 없음

🔧 변경 범위

✅ 추가될 것들:

// 4개 새 Provider

1. noteSessionProvider // 기존 canvasSessionProvider 개명
2. goRouterProvider // GoRouter 인스턴스 제공
3. currentPathProvider // 경로 변경 Stream
4. noteSessionObserverProvider // 핵심 Observer 로직

🗑️ 제거될 것들:

// NoteEditorScreen에서

- initState() 세션 시작 코드
- dispose() 세션 종료 코드
- addPostFrameCallback 관련 코드

🔄 변경될 것들:

// 단순 이름 변경
canvasSessionProvider → noteSessionProvider
canvasPageNotifier → 내부적으로 noteSessionProvider 참조

🎯 실제 사용자 시나리오

시나리오 1: 정상적인 노트 편집

1. 앱 시작 → `/` → 세션 없음
2. 노트 목록 → `/notes` → 세션 없음
3. 수학노트 선택 → `/notes/abc-123/edit` → Observer: CanvasSession("abc-123") 시작
4. 페이지 그리기 → canvasPageNotifier("page-1") 정상 동작 (세션 있음)
5. 다른 페이지 이동 → URL 동일, 세션 유지, 히스토리 보존
6. 뒤로가기 → `/notes` → Observer: CanvasSession 종료, 모든 히스토리 dispose

시나리오 2: PDF 내보내기

1. 노트 편집 중 → `/notes/abc-123/edit` → 세션 활성
2. PDF 내보내기 모달 → URL 변화 없음 → 세션 유지 ⭐
3. PDF 생성 진행 → canvasPageNotifier 안전하게 접근 가능
4. 모달 닫기 → URL 여전히 동일 → 세션 계속 유지

💡 핵심 장점

1. 완전한 분리: Widget은 세션 관리 전혀 몰라도 됨
2. 자동화: 경로만 바뀌면 알아서 세션 관리
3. 안전성: Race condition 완전 해결 (Widget lifecycle과 무관)
4. 중앙화: 한 곳에서 모든 세션 로직 관리
5. 확장성: 다른 세션들도 동일 패턴으로 쉽게 추가

결론: 구조가 훨씬 간단해지고 안전해진다! Widget 코드는 깔끔해지고, 세션 관리는 중앙화되어 유지보수성이 크게 향상된다.
