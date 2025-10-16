# 🎨 NoteEditorScreen 디자인 적용 선행작업 및 구현 계획서

## 📋 문서 개요

본 문서는 `lib/design_system/screens/notes/note_screen.dart`의 디자인 언어를 `lib/features/canvas/pages/note_editor_screen.dart`에 적용하기 위한 **종합 분석 및 선행작업 계획서**입니다.

**작성일**: 2025-10-02
**목표**: 기능 완전 보존 + 디자인 일관성 확보 + 전체화면 토글 기능 추가

---

## 🎯 1. 프로젝트 목표 및 배경

### 1.1 핵심 목표

1. **기능 완전 보존**: NoteEditorScreen의 모든 기존 기능을 100% 유지
2. **디자인 일관성**: 디자인 시스템의 스타일 언어를 편집 화면에 적용
3. **신규 기능 추가**: 전체화면 토글 모드 구현
4. **성능 유지**: 기존의 리빌드 최적화 패턴 유지

### 1.2 배경 및 맥락

현재 상황:

- **DesignNoteScreen** (design_system): 노트 목록 화면의 디자인 레퍼런스
- **NoteEditorScreen** (features/canvas): 실제 노트 편집 기능 구현

문제점:

- 두 화면이 서로 다른 디자인 언어 사용 (색상, 간격, 스타일 불일치)
- NoteEditorScreen은 복잡한 상태 관리와 라이프사이클을 가짐
- 디자인 시스템의 스타일을 단순히 복사-붙여넣기 방식으로는 적용 불가능

---

## 🔍 2. 현재 아키텍처 심층 분석

### 2.1 NoteEditorScreen 구조 분석

#### 2.1.1 파일 구조

```
lib/features/canvas/pages/note_editor_screen.dart (255 lines)
├── NoteEditorScreen (ConsumerStatefulWidget)
├── _NoteEditorScreenState (with RouteAware)
│   ├── RouteAware 라이프사이클 메서드 (didPush, didPop, didPopNext, didPushNext)
│   ├── 페이지 인덱스 복원 로직
│   └── 세션 관리 로직
└── build 메서드
    ├── AppBar (제목 + 페이지 번호 + NoteEditorActionsBar)
    ├── endDrawer: BacklinksPanel
    └── body: NoteEditorCanvas
```

#### 2.1.2 핵심 기능 목록

1. **RouteAware 라이프사이클 관리** (lines 87-198)

   - `didPush`: 화면 진입 시 세션 시작 + 페이지 인덱스 복원
   - `didPopNext`: 하위 화면에서 돌아올 때 세션 재진입
   - `didPushNext`: 상위 화면으로 이동 시 현재 페이지 스케치 저장
   - `didPop`: 화면 이탈 시 세션 종료 + lastKnown 인덱스 저장

2. **세션 관리** (Provider 기반)

   - `noteSessionProvider`: 전역 활성 노트 ID
   - `noteRouteIdProvider`: 라우트별 고유 ID
   - `resumePageIndexMapProvider`: 라우트별 페이지 인덱스 복원 맵
   - `lastKnownPageIndexProvider`: 마지막 알려진 페이지 인덱스

3. **페이지 인덱스 복원 로직** (lines 44-85)

   - 우선순위 1: per-route resume (특정 라우트 인스턴스 복원)
   - 우선순위 2: lastKnown (노트 재진입 시 마지막 페이지)
   - 우선순위 3: currentPageIndex (기본값 0)

4. **에러 처리 및 가드**
   - 노트가 null이거나 페이지가 0개일 때 빈 화면 처리 (lines 236-240)
   - RouteAware가 없을 때의 build-guard 로직 (lines 206-223)

#### 2.1.3 Provider 의존성 그래프

```
NoteEditorScreen
├── noteProvider(noteId) → 노트 데이터 (AsyncValue<NoteModel?>)
├── notePagesCountProvider(noteId) → 페이지 수
├── currentPageIndexProvider(noteId) → 현재 페이지 인덱스
├── noteSessionProvider → 전역 활성 노트 ID
├── noteRouteIdProvider(noteId) → 라우트 ID
├── resumePageIndexMapProvider(noteId) → 복원 맵
└── lastKnownPageIndexProvider(noteId) → 마지막 페이지

NoteEditorCanvas
├── pageControllerProvider(noteId, routeId) → PageController
├── notePagesCountProvider(noteId) → 페이지 수
└── [각 페이지별]
    └── pageNotifierProvider(noteId, pageIndex) → CustomScribbleNotifier

NoteEditorActionsBar
├── notePagesCountProvider(noteId)
├── currentNotifierProvider(noteId) → 현재 페이지의 CSN
└── [Undo/Redo] ValueListenableBuilder<ScribbleState>

NoteEditorToolbar
├── notePagesCountProvider(noteId)
├── NoteEditorDrawingToolbar(noteId)
│   └── toolSettingsNotifierProvider(noteId)
└── NoteEditorPageNavigation(noteId)
    ├── currentPageIndexProvider(noteId)
    └── notePagesCountProvider(noteId)
```

### 2.2 NoteEditorCanvas 구조 분석

#### 2.2.1 위젯 계층 구조

```
NoteEditorCanvas (note_editor_canvas.dart:24)
├── Padding(horizontal: 16)
└── Column
    ├── Expanded (캔버스 영역)
    │   └── PageView.builder
    │       └── NotePageViewItem (각 페이지)
    │           └── Padding(8)
    │               └── Card(elevation: 8)
    │                   └── ClipRRect(borderRadius: 6)
    │                       └── InteractiveViewer
    │                           └── SizedBox (canvasScale 적용)
    │                               └── Center
    │                                   └── SizedBox (실제 drawing 영역)
    │                                       └── ValueListenableBuilder
    │                                           └── Stack
    │                                               ├── CanvasBackgroundWidget
    │                                               ├── SavedLinksLayer
    │                                               ├── Scribble (필기 레이어)
    │                                               └── LinkerGestureLayer
    └── NoteEditorToolbar (하단 툴바)
        ├── NoteEditorDrawingToolbar
        └── Wrap
            ├── NoteEditorPageNavigation
            ├── NoteEditorPressureToggle
            ├── NoteEditorViewportInfo
            └── NoteEditorPointerMode
```

#### 2.2.2 핵심 기능 분석

**PageView 페이지 전환 처리** (lines 58-96):

- `onPageChanged` 콜백에서 이전 페이지 스케치 자동 저장
- `pageJumpTargetProvider`를 통한 programmatic jump 감지
- 사용자 스와이프와 코드 점프를 구분하여 처리

**InteractiveViewer 줌/패닝**:

- `minScale: 0.3`, `maxScale: 3.0`
- 링커 모드에서는 `panEnabled: false` (제스처 충돌 방지)
- TransformationController를 통한 스케일 동기화

**최적화 패턴**:

- ValueListenableBuilder로 ScribbleState 변경만 감지
- Provider 의존성 최소화 (구조 변경만 watch)
- 페이지별 독립 CustomScribbleNotifier

### 2.3 Provider 아키텍처 분석

#### 2.3.1 세션 관리 Provider (note_editor_provider.dart:33-106)

```dart
@Riverpod(keepAlive: true)
class NoteSession extends _$NoteSession {
  @override
  String? build() => null;

  void enterNote(String noteId) { /* ... */ }
  void exitNote() { /* ... */ }
}
```

**설계 의도**:

- 전역 싱글톤으로 현재 활성 노트를 추적
- RouteAware 라이프사이클과 연동하여 자동 세션 관리
- `canvasPageNotifier`가 활성 세션을 확인하여 안전성 보장

#### 2.3.2 CustomScribbleNotifier 생성 Provider (lines 139-263)

```dart
@Riverpod(keepAlive: true)
CustomScribbleNotifier canvasPageNotifier(Ref ref, String pageId) {
  final activeNoteId = ref.watch(noteSessionProvider);
  if (activeNoteId == null) {
    return CustomScribbleNotifier(/* no-op notifier */);
  }

  // ... 페이지 데이터 로드, 도구 설정 적용, 리스너 등록

  ref.onDispose(() { notifier.dispose(); });
  return notifier;
}
```

**핵심 특징**:

- `keepAlive: true`로 세션 내 영구 보존
- 노트 데이터 변경(JSON 저장)에는 반응하지 않음 (구조 변경만)
- 도구 설정 변경, 필압 설정, 포인터 정책 변경 시 자동 동기화
- 세션 종료 시 자동 dispose

#### 2.3.3 PageController 동기화 Provider (lines 388-489)

**복잡도 높은 로직**:

1. 초기 인덱스 결정: resume → lastKnown → currentPageIndex
2. `currentPageIndexProvider` 변경 감지 → `jumpToPage`
3. PageView가 아직 attached되지 않았을 때 pending jump 처리
4. `pageJumpTargetProvider`로 spurious callback 필터링

**주의점**:

- PageView의 `onPageChanged`와 `controller.jumpToPage`의 상호작용
- Race condition 방지를 위한 복잡한 플래그 관리

---

## 🎨 3. 디자인 시스템 분석

### 3.1 DesignNoteScreen 스타일 추출

#### 3.1.1 색상 시스템

```dart
// note_screen.dart에서 사용된 색상
const Color primaryPurple = Color(0xFF6750A4);  // AppBar, 버튼
const Color backgroundGrey = Colors.grey[100];  // 배경
const Color surfaceWhite = Colors.white;        // 카드, 컨테이너
const Color borderGrey = Colors.grey.withOpacity(0.15);  // 카드 테두리
const Color shadowBlack = Colors.black.withOpacity(0.1); // 그림자

// 기존 AppColors.dart와의 충돌
AppColors.primary = Color(0xFF182955);  // 기존 primary (다름!)
AppColors.background = Color(0xFFFEFCF3); // 기존 background (다름!)
```

**문제**: 디자인 시스템의 note_screen.dart는 하드코딩된 색상을 사용하며, 기존 AppColors와 다름

**해결 방안**:

1. **Option A**: AppColors에 새로운 색상 추가 (`AppColors.editorPrimary`, `AppColors.editorBackground`)
2. **Option B**: note_screen의 색상을 AppColors에 맞게 수정
3. **Option C**: 테마별 색상 시스템 구축 (`ThemeColors.editor`, `ThemeColors.list`)

#### 3.1.2 간격 및 레이아웃

```dart
// note_screen.dart의 간격
Padding: EdgeInsets.all(24)  // 메인 컨테이너
Container.padding: EdgeInsets.all(24)  // 카드 내부
Card.padding: EdgeInsets.all(20)  // 노트 카드

// AppSpacing.dart 매핑
AppSpacing.large = 24.0  ✓
AppSpacing.medium = 16.0
```

#### 3.1.3 그림자 및 테두리

```dart
// note_screen의 BoxShadow
BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 10,
  offset: Offset(0, 5)
)

// BorderRadius
BorderRadius.circular(20)  // 메인 컨테이너
BorderRadius.circular(16)  // 카드
BorderRadius.circular(12)  // 버튼
```

### 3.2 NoteEditorScreen 현재 스타일

#### 3.2.1 AppBar

```dart
AppBar(
  title: Text('$noteTitle - Page ${currentIndex + 1}/$notePagesCount'),
  actions: [NoteEditorActionsBar(noteId: widget.noteId)],
)
```

- 기본 Material 테마 색상 (primary)
- 제목: 노트명 + 페이지 번호
- 액션: Undo, Redo, Clear, 페이지 설정, Links

#### 3.2.2 Body

```dart
Scaffold(
  backgroundColor: Theme.of(context).colorScheme.surface,
  body: NoteEditorCanvas(noteId: widget.noteId, routeId: widget.routeId),
)
```

- 배경: `colorScheme.surface` (테마 의존)
- 캔버스: Card with elevation 8

#### 3.2.3 Toolbar

```dart
NoteEditorToolbar(
  noteId: noteId,
  canvasWidth: _canvasWidth,
  canvasHeight: _canvasHeight,
)
```

- 하단 고정 툴바
- 그리기 도구 + 페이지 네비게이션 + 뷰포트 정보

---

## 🚨 4. 기술적 도전 과제

### 4.1 복잡한 상태 관리

**문제점**:

- 10개 이상의 Provider가 상호 의존
- RouteAware 라이프사이클과 Provider 상태 동기화 필요
- 페이지 전환, 줌, 그리기가 동시에 발생할 수 있음

**리스크**:

- 디자인 변경 시 Provider rebuild 트리거 가능
- 성능 저하 (불필요한 리빌드)
- 상태 불일치 (세션과 UI 불일치)

### 4.2 RouteAware 라이프사이클

**문제점**:

- didPush, didPop, didPopNext, didPushNext의 복잡한 플로우
- 각 메서드가 세션, 인덱스, 스케치 저장을 관리
- WidgetsBinding.instance.addPostFrameCallback의 중첩된 사용

**리스크**:

- 디자인 변경 시 build 타이밍 변경 가능
- RouteAware 콜백이 예상치 못한 순서로 호출될 수 있음

### 4.3 ValueListenableBuilder 최적화

**현재 패턴**:

```dart
ValueListenableBuilder(
  valueListenable: notifier,
  builder: (context, value, child) => IconButton(...),
  child: const Icon(Icons.undo),  // 아이콘 캐싱
)
```

**주의점**:

- 디자인 변경 시 child 캐싱 패턴 유지 필수
- builder 내부 로직 최소화

### 4.4 InteractiveViewer와 제스처 충돌

**문제점**:

- InteractiveViewer (줌/패닝)
- Scribble (그리기)
- LinkerGestureLayer (링크 드래그)
- 세 가지 제스처가 동시에 처리됨

**현재 해결책**:

- 링커 모드에서 `panEnabled: false`
- `IgnorePointer`로 Scribble 비활성화
- `Positioned.fill`로 레이어 순서 관리

**리스크**:

- 디자인 변경 시 Stack 순서나 크기 변경 가능
- 제스처 영역 변경 시 충돌 재발 가능

### 4.5 전체화면 토글 기능 추가

**요구사항** (추정):

- AppBar와 Toolbar 숨기기/보이기
- 캔버스 영역 확장
- 상태 유지 (전체화면 → 일반 → 전체화면 시 상태 보존)

**기술적 과제**:

1. AppBar 숨기기: `PreferredSize(preferredSize: Size.zero, child: Container())`
2. Toolbar 숨기기: AnimatedContainer 또는 조건부 렌더링
3. 전체화면 상태 관리: 새로운 Provider 또는 State
4. 제스처: 스와이프로 토글? 버튼 클릭?

---

## 🛠️ 5. 선행 작업 상세 계획

### 5.1 단계별 선행 작업 로드맵

#### **STEP 0: 안전 백업 및 브랜치 생성** ✅

```bash
git checkout -b feature/canvas-design-system
git commit -m "chore: backup before canvas design refactoring"
```

#### **STEP 1: 기능 명세 및 테스트 작성** (우선순위: 최상)

**목표**: 현재 기능을 명확히 정의하고 회귀 테스트 방지

**작업 내용**:

1. **기능 명세서 작성** (`docs/note_editor_features_spec.md`)

   - [ ] RouteAware 라이프사이클 플로우 다이어그램
   - [ ] Provider 의존성 그래프 (Mermaid 다이어그램)
   - [ ] 주요 사용자 시나리오 (페이지 전환, 그리기, 링크 생성, 노트 이동)
   - [ ] 예상되는 엣지 케이스 (빠른 페이지 전환, 노트 삭제 중 편집 등)

2. **통합 테스트 작성** (`test/features/canvas/note_editor_integration_test.dart`)

   ```dart
   testWidgets('노트 편집 화면 진입 → 페이지 전환 → 그리기 → 뒤로가기', (tester) async {
     // Given: 노트가 존재하고
     // When: 편집 화면 진입
     // Then: 세션이 활성화되고 마지막 페이지가 복원됨

     // When: 페이지 전환
     // Then: 이전 페이지 스케치가 저장되고 currentPageIndex가 변경됨

     // When: 뒤로가기
     // Then: 세션이 종료되고 lastKnown 인덱스가 저장됨
   });
   ```

3. **Widget 테스트 작성**
   - NoteEditorScreen 렌더링 테스트
   - AppBar 제목 및 페이지 번호 표시 테스트
   - NoteEditorActionsBar 버튼 동작 테스트

**예상 소요 시간**: 1-2일

---

#### **STEP 2: 디자인 토큰 정의 및 통합** (우선순위: 최상)

**목표**: 일관된 디자인 언어 구축

**작업 내용**:

1. **색상 시스템 정의**

   **Option A 채택**: 기존 AppColors 확장

   ```dart
   // lib/design_system/tokens/app_colors.dart

   class AppColors {
     // ... 기존 색상 유지

     // 📝 Editor Theme Colors
     static const Color editorPrimary = Color(0xFF6750A4);      // 보라색
     static const Color editorBackground = Color(0xFFF5F5F5);   // 연한 회색
     static const Color editorSurface = Colors.white;
     static const Color editorBorder = Color(0x26000000);       // 15% opacity
     static const Color editorShadow = Color(0x1A000000);       // 10% opacity

     // Canvas Colors
     static const Color canvasBackground = Colors.white;
     static const Color canvasBorder = Color(0xFFE0E0E0);
   }
   ```

2. **그림자 시스템 정의**

   ```dart
   // lib/design_system/tokens/app_shadows.dart

   class AppShadows {
     static List<BoxShadow> elevation8 = [
       BoxShadow(
         color: AppColors.editorShadow,
         blurRadius: 10,
         offset: Offset(0, 5),
       ),
     ];

     static List<BoxShadow> editorCard = elevation8;
   }
   ```

3. **테두리 반지름 시스템**

   ```dart
   // lib/design_system/tokens/app_spacing.dart 확장

   class AppRadius {
     static const double small = 6.0;   // ClipRRect (캔버스)
     static const double medium = 12.0; // 버튼
     static const double large = 16.0;  // 카드
     static const double xl = 20.0;     // 메인 컨테이너
   }
   ```

4. **타이포그래피 매핑**
   - AppBar 제목 스타일
   - 페이지 번호 스타일
   - 툴바 라벨 스타일

**예상 소요 시간**: 0.5일

---

#### **STEP 3: UI 컴포넌트 분리 및 리팩토링** (우선순위: 상)

**목표**: 복잡한 로직과 UI 분리, 재사용 가능한 컴포넌트 추출

**작업 내용**:

1. **NoteEditorAppBar 분리**

   **기존**:

   ```dart
   AppBar(
     title: Text('$noteTitle - Page ${currentIndex + 1}/$notePagesCount'),
     actions: [NoteEditorActionsBar(noteId: widget.noteId)],
   )
   ```

   **신규**: `lib/features/canvas/widgets/note_editor_app_bar.dart`

   ```dart
   class NoteEditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
     final String noteId;
     final bool isFullscreen;  // 전체화면 모드 지원

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       if (isFullscreen) {
         return PreferredSize(
           preferredSize: Size.zero,
           child: Container(),
         );
       }

       final noteTitle = ref.watch(noteProvider(noteId)).value?.title ?? noteId;
       final pageInfo = _buildPageInfo(ref);

       return AppBar(
         backgroundColor: AppColors.editorPrimary,
         foregroundColor: Colors.white,
         centerTitle: false,
         title: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(noteTitle, style: AppTypography.titleMedium),
             Text(pageInfo, style: AppTypography.bodySmall.copyWith(opacity: 0.8)),
           ],
         ),
         actions: [NoteEditorActionsBar(noteId: noteId)],
       );
     }

     String _buildPageInfo(WidgetRef ref) {
       final currentIndex = ref.watch(currentPageIndexProvider(noteId));
       final totalPages = ref.watch(notePagesCountProvider(noteId));
       return 'Page ${currentIndex + 1}/$totalPages';
     }

     @override
     Size get preferredSize => isFullscreen ? Size.zero : Size.fromHeight(kToolbarHeight);
   }
   ```

2. **FullscreenController Provider 생성**

   **파일**: `lib/features/canvas/providers/fullscreen_controller.dart`

   ```dart
   @riverpod
   class FullscreenController extends _$FullscreenController {
     @override
     bool build(String noteId) => false;

     void toggle() => state = !state;
     void enter() => state = true;
     void exit() => state = false;
   }
   ```

3. **NoteEditorToolbar 조건부 렌더링 수정**

   ```dart
   // note_editor_canvas.dart

   @override
   Widget build(BuildContext context, WidgetRef ref) {
     final isFullscreen = ref.watch(fullscreenControllerProvider(noteId));

     return Column(
       children: [
         Expanded(child: _buildPageView()),
         if (!isFullscreen)
           NoteEditorToolbar(noteId: noteId, ...),
       ],
     );
   }
   ```

4. **전체화면 토글 버튼 추가**
   - 위치: NoteEditorActionsBar 또는 Floating overlay
   - 아이콘: `Icons.fullscreen` / `Icons.fullscreen_exit`

**예상 소요 시간**: 1일

---

#### **STEP 4: 스타일 적용을 위한 래퍼 컴포넌트 생성** (우선순위: 중)

**목표**: 기존 위젯 구조는 유지하되 스타일만 변경

**작업 내용**:

1. **EditorScaffold 래퍼**

   ```dart
   // lib/features/canvas/widgets/editor_scaffold.dart

   class EditorScaffold extends ConsumerWidget {
     final String noteId;
     final Widget body;
     final Widget? endDrawer;

     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final isFullscreen = ref.watch(fullscreenControllerProvider(noteId));

       return Scaffold(
         backgroundColor: AppColors.editorBackground,
         appBar: isFullscreen
           ? null
           : NoteEditorAppBar(noteId: noteId, isFullscreen: false),
         endDrawer: endDrawer,
         body: body,
       );
     }
   }
   ```

2. **CanvasCard 래퍼**

   ```dart
   // lib/features/canvas/widgets/canvas_card.dart

   class CanvasCard extends StatelessWidget {
     final Widget child;

     @override
     Widget build(BuildContext context) {
       return Padding(
         padding: EdgeInsets.all(AppSpacing.small),
         child: Card(
           elevation: 8,
           shadowColor: AppColors.editorShadow,
           surfaceTintColor: AppColors.editorSurface,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(AppRadius.small),
           ),
           child: ClipRRect(
             borderRadius: BorderRadius.circular(AppRadius.small),
             child: child,
           ),
         ),
       );
     }
   }
   ```

3. **ToolbarContainer 래퍼**

   ```dart
   // lib/features/canvas/widgets/toolbar_container.dart

   class ToolbarContainer extends StatelessWidget {
     final Widget child;

     @override
     Widget build(BuildContext context) {
       return Container(
         decoration: BoxDecoration(
           color: Colors.white,
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.05),
               blurRadius: 8,
               offset: Offset(0, -2),
             ),
           ],
         ),
         child: Padding(
           padding: EdgeInsets.fromLTRB(
             AppSpacing.medium,
             AppSpacing.small,
             AppSpacing.medium,
             AppSpacing.medium,
           ),
           child: child,
         ),
       );
     }
   }
   ```

**예상 소요 시간**: 0.5일

---

#### **STEP 5: 점진적 디자인 적용 (Bottom-Up)** (우선순위: 중)

**목표**: 리스크를 최소화하며 단계별로 디자인 적용

**작업 순서**:

1. **Phase 1: 색상 적용**

   - [ ] AppBar 배경색: `AppColors.editorPrimary`
   - [ ] Scaffold 배경색: `AppColors.editorBackground`
   - [ ] 툴바 배경색: `Colors.white`
   - [ ] 테스트: 색상 변경이 Provider rebuild를 트리거하지 않는지 확인

2. **Phase 2: 간격 및 패딩 조정**

   - [ ] 캔버스 Card padding: `AppSpacing.small`
   - [ ] 툴바 padding: `AppPadding` 사용
   - [ ] 테스트: 레이아웃 변경이 제스처 영역에 영향을 주지 않는지 확인

3. **Phase 3: 그림자 및 테두리**

   - [ ] Card elevation: `AppShadows.editorCard`
   - [ ] ClipRRect borderRadius: `AppRadius.small`
   - [ ] 테스트: 시각적 변화만 있고 기능은 동일한지 확인

4. **Phase 4: 타이포그래피**
   - [ ] AppBar 제목 스타일
   - [ ] 페이지 번호 스타일
   - [ ] 툴바 라벨 스타일

**각 Phase마다 체크포인트**:

- [ ] Widget 테스트 통과
- [ ] 통합 테스트 통과
- [ ] 성능 프로파일링 (불필요한 rebuild 없는지)
- [ ] Git commit

**예상 소요 시간**: 1-2일

---

#### **STEP 6: 전체화면 모드 구현** (우선순위: 중)

**목표**: 전체화면 토글 기능 완성

**작업 내용**:

1. **전체화면 상태 관리**

   - [x] `FullscreenController` Provider (STEP 3에서 완료)

2. **UI 조건부 렌더링**

   ```dart
   // note_editor_screen.dart

   @override
   Widget build(BuildContext context) {
     final isFullscreen = ref.watch(fullscreenControllerProvider(noteId));

     return EditorScaffold(
       noteId: noteId,
       endDrawer: isFullscreen ? null : BacklinksPanel(noteId: noteId),
       body: Stack(
         children: [
           NoteEditorCanvas(noteId: noteId, routeId: routeId),
           if (isFullscreen)
             _buildFullscreenOverlay(),  // 전체화면 토글 버튼
         ],
       ),
     );
   }

   Widget _buildFullscreenOverlay() {
     return Positioned(
       top: 16,
       right: 16,
       child: FloatingActionButton.small(
         onPressed: () {
           ref.read(fullscreenControllerProvider(noteId).notifier).exit();
         },
         backgroundColor: Colors.black54,
         child: Icon(Icons.fullscreen_exit, color: Colors.white),
       ),
     );
   }
   ```

3. **제스처 지원 (옵션)**

   - 더블 탭으로 전체화면 토글
   - 스와이프 다운으로 전체화면 해제

4. **애니메이션 추가 (옵션)**
   - AppBar fade-out/in
   - Toolbar slide-out/in

**예상 소요 시간**: 1일

---

#### **STEP 7: 성능 최적화 및 검증** (우선순위: 중)

**목표**: 디자인 변경이 성능에 영향을 주지 않는지 확인

**작업 내용**:

1. **Flutter DevTools 프로파일링**

   - [ ] Rebuild 카운트 측정 (디자인 전후 비교)
   - [ ] 메모리 사용량 확인
   - [ ] 프레임 드롭 확인 (60fps 유지)

2. **최적화 체크리스트**

   - [ ] `const` 위젯 최대한 활용
   - [ ] `child` 파라미터 캐싱 유지
   - [ ] Provider `select` 사용 확인
   - [ ] ValueListenableBuilder 패턴 유지

3. **성능 테스트 시나리오**
   - 빠른 페이지 전환 (10페이지 연속 스와이프)
   - 그리기 중 줌 인/아웃
   - 전체화면 토글 반복

**예상 소요 시간**: 0.5일

---

#### **STEP 8: 문서화 및 코드 리뷰 준비** (우선순위: 하)

**작업 내용**:

1. [ ] 변경 사항 요약 문서 작성
2. [ ] 마이그레이션 가이드 (다른 개발자용)
3. [ ] 스크린샷 및 비교 이미지
4. [ ] PR 템플릿 작성

**예상 소요 시간**: 0.5일

---

### 5.2 총 예상 소요 시간

| 단계   | 작업 내용           | 소요 시간 | 누적 시간 |
| ------ | ------------------- | --------- | --------- |
| STEP 0 | 백업 및 브랜치 생성 | 0.1일     | 0.1일     |
| STEP 1 | 기능 명세 및 테스트 | 1-2일     | 2.1일     |
| STEP 2 | 디자인 토큰 정의    | 0.5일     | 2.6일     |
| STEP 3 | UI 컴포넌트 분리    | 1일       | 3.6일     |
| STEP 4 | 래퍼 컴포넌트 생성  | 0.5일     | 4.1일     |
| STEP 5 | 점진적 디자인 적용  | 1-2일     | 6.1일     |
| STEP 6 | 전체화면 모드 구현  | 1일       | 7.1일     |
| STEP 7 | 성능 최적화 및 검증 | 0.5일     | 7.6일     |
| STEP 8 | 문서화              | 0.5일     | 8.1일     |

**총 예상 소요 시간**: **약 8-10일** (1인 기준)

---

## 🗺️ 6. 디자인 적용 전략

### 6.1 적용 원칙

1. **기능 우선**: 디자인 < 기능 동작
2. **점진적 변경**: 한 번에 하나씩, 테스트 후 다음 단계
3. **롤백 가능**: 각 Phase마다 Git commit
4. **성능 모니터링**: 변경 후 항상 프로파일링

### 6.2 Before/After 비교

#### 6.2.1 AppBar

**Before**:

```dart
AppBar(
  title: Text('$noteTitle - Page ${currentIndex + 1}/$notePagesCount'),
  // 기본 Material primary color
)
```

**After**:

```dart
NoteEditorAppBar(
  noteId: noteId,
  isFullscreen: false,
  // backgroundColor: AppColors.editorPrimary (보라색)
  // 제목과 페이지 번호 분리
)
```

#### 6.2.2 Scaffold

**Before**:

```dart
Scaffold(
  backgroundColor: Theme.of(context).colorScheme.surface,
  body: NoteEditorCanvas(...),
)
```

**After**:

```dart
EditorScaffold(
  noteId: noteId,
  // backgroundColor: AppColors.editorBackground (연한 회색)
  body: NoteEditorCanvas(...),
)
```

#### 6.2.3 Canvas Card

**Before**:

```dart
Card(
  elevation: 8,
  shadowColor: Colors.black26,
  surfaceTintColor: Colors.white,
  child: ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: InteractiveViewer(...),
  ),
)
```

**After**:

```dart
CanvasCard(
  child: InteractiveViewer(...),
  // 내부적으로 AppColors, AppRadius, AppShadows 사용
)
```

---

## ⚠️ 7. 리스크 관리

### 7.1 High Risk

| 리스크                       | 발생 확률 | 영향도 | 완화 전략                                             |
| ---------------------------- | --------- | ------ | ----------------------------------------------------- |
| RouteAware 라이프사이클 깨짐 | 중        | 높음   | STEP 1에서 통합 테스트 작성, 각 Phase 후 테스트 실행  |
| Provider rebuild 증가        | 중        | 높음   | STEP 7에서 프로파일링, `select` 및 `child` 캐싱 확인  |
| 제스처 충돌                  | 낮        | 중간   | STEP 5 Phase 2에서 레이아웃 변경 시 주의, 수동 테스트 |
| 세션 상태 불일치             | 낮        | 높음   | 세션 관리 로직은 절대 변경하지 않음, UI만 변경        |

### 7.2 Medium Risk

| 리스크             | 발생 확률 | 영향도 | 완화 전략                            |
| ------------------ | --------- | ------ | ------------------------------------ |
| 전체화면 모드 버그 | 중        | 중간   | STEP 6에서 독립적으로 구현 후 테스트 |
| 디자인 토큰 불일치 | 낮        | 낮     | STEP 2에서 명확히 정의, 코드 리뷰    |
| 성능 저하          | 낮        | 중간   | STEP 7에서 검증, 필요시 최적화       |

### 7.3 롤백 계획

각 STEP마다 Git commit을 남기므로:

```bash
# Phase 3까지 완료했으나 문제 발생
git log --oneline  # commit 목록 확인
git revert <commit-hash>  # 또는 git reset --hard <commit-hash>
```

---

## ✅ 8. 실행 체크리스트

### 8.1 선행 작업 체크리스트

- [ ] **STEP 0**: 브랜치 생성 및 백업
- [ ] **STEP 1-1**: 기능 명세서 작성 완료
- [ ] **STEP 1-2**: 통합 테스트 작성 완료
- [ ] **STEP 1-3**: Widget 테스트 작성 완료
- [ ] **STEP 2-1**: AppColors에 editor 색상 추가
- [ ] **STEP 2-2**: AppShadows 정의
- [ ] **STEP 2-3**: AppRadius 정의
- [ ] **STEP 3-1**: NoteEditorAppBar 분리
- [ ] **STEP 3-2**: FullscreenController Provider 생성
- [ ] **STEP 3-3**: NoteEditorToolbar 조건부 렌더링
- [ ] **STEP 3-4**: 전체화면 토글 버튼 추가
- [ ] **STEP 4-1**: EditorScaffold 래퍼 생성
- [ ] **STEP 4-2**: CanvasCard 래퍼 생성
- [ ] **STEP 4-3**: ToolbarContainer 래퍼 생성

### 8.2 디자인 적용 체크리스트

- [ ] **Phase 1**: 색상 적용 + 테스트
- [ ] **Phase 2**: 간격 조정 + 테스트
- [ ] **Phase 3**: 그림자/테두리 + 테스트
- [ ] **Phase 4**: 타이포그래피 + 테스트
- [ ] **전체화면 모드**: 구현 완료 + 테스트
- [ ] **성능 검증**: 프로파일링 완료
- [ ] **문서화**: 변경 사항 문서 작성
- [ ] **코드 리뷰**: PR 생성 및 리뷰 요청

---

## 📊 9. 성공 지표

### 9.1 기능 보존 지표

- [ ] 모든 통합 테스트 통과 (100%)
- [ ] 모든 Widget 테스트 통과 (100%)
- [ ] RouteAware 라이프사이클 정상 동작
- [ ] 페이지 전환, 그리기, 링크 생성 모두 정상 동작

### 9.2 디자인 일관성 지표

- [ ] AppColors 사용률 100% (하드코딩된 색상 0개)
- [ ] AppSpacing 사용률 100% (매직 넘버 0개)
- [ ] 디자인 시스템과 시각적 일관성 확보

### 9.3 성능 지표

- [ ] Rebuild 횟수 증가율 < 5%
- [ ] 메모리 사용량 증가 < 10%
- [ ] 60fps 유지 (Frame drop < 1%)

### 9.4 신규 기능 지표

- [ ] 전체화면 모드 동작 확인
- [ ] 전체화면 전환 애니메이션 부드러움
- [ ] 전체화면 상태 유지 (페이지 전환 후에도)

---

## 🎓 10. 핵심 인사이트 및 주의사항

### 10.1 절대 변경하면 안 되는 것

1. **Provider 구조**

   - `noteSessionProvider`, `canvasPageNotifier` 등의 로직
   - Provider 간 의존성 그래프

2. **RouteAware 라이프사이클**

   - `didPush`, `didPop`, `didPopNext`, `didPushNext`의 로직
   - 단, UI 관련 코드는 변경 가능

3. **ValueListenableBuilder 패턴**

   - `child` 캐싱 패턴 유지 필수
   - builder 내부 로직 최소화

4. **InteractiveViewer와 제스처**
   - Stack 레이어 순서
   - `panEnabled`, `scaleEnabled` 플래그
   - LinkerGestureLayer의 우선순위

### 10.2 변경 가능한 것

1. **시각적 스타일**

   - 색상, 간격, 그림자, 테두리
   - 타이포그래피

2. **UI 구조 (조심스럽게)**

   - Scaffold, AppBar, Card 등의 래퍼
   - 조건부 렌더링 (전체화면 모드)

3. **애니메이션 (추가만)**
   - 전체화면 전환 애니메이션
   - 툴바 슬라이드 애니메이션

### 10.3 디버깅 팁

**Provider 상태 확인**:

```dart
// 개발 중 임시로 추가
ref.listen<String?>(noteSessionProvider, (prev, next) {
  debugPrint('🔄 [Session] $prev → $next');
});

ref.listen<int>(currentPageIndexProvider(noteId), (prev, next) {
  debugPrint('📄 [PageIndex] $prev → $next');
});
```

**Rebuild 추적**:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  debugPrint('🔨 [Rebuild] NoteEditorScreen');
  // ...
}
```

**제스처 충돌 확인**:

```dart
GestureDetector(
  onTap: () => debugPrint('👆 Tap detected'),
  behavior: HitTestBehavior.translucent,
  // ...
)
```

---

## 📚 11. 참고 자료

### 11.1 핵심 파일 위치

**디자인 레퍼런스**:

- `lib/design_system/screens/notes/note_screen.dart`

**구현 대상**:

- `lib/features/canvas/pages/note_editor_screen.dart`
- `lib/features/canvas/widgets/note_editor_canvas.dart`
- `lib/features/canvas/widgets/toolbar/`

**Provider**:

- `lib/features/canvas/providers/note_editor_provider.dart`

**디자인 토큰**:

- `lib/design_system/tokens/app_colors.dart`
- `lib/design_system/tokens/app_spacing.dart`
- `lib/design_system/tokens/app_shadows.dart`

### 11.2 관련 문서

- `docs/design_canvas_pre_info.md` (기존 분석 문서)
- `docs/note_editor_features_spec.md` (STEP 1에서 작성 예정)

---

## 🏁 12. 결론

### 12.1 요약

NoteEditorScreen에 디자인을 적용하는 것은 **단순한 스타일 변경이 아닌, 복잡한 상태 관리와 라이프사이클을 고려한 신중한 리팩토링**입니다.

**핵심 전략**:

1. **안전성 우선**: 테스트 작성 → 점진적 변경 → 검증 → 다음 단계
2. **기능 보존**: RouteAware, Provider, ValueListenableBuilder 패턴 유지
3. **디자인 토큰 활용**: 일관된 디자인 언어 구축
4. **성능 모니터링**: 변경 후 항상 프로파일링

**성공 기준**:

- 모든 기존 기능 정상 동작
- 디자인 시스템과 시각적 일관성 확보
- 전체화면 모드 추가 완료
- 성능 저하 없음

### 12.2 Next Steps

1. **즉시 시작 가능**: STEP 0 (브랜치 생성)
2. **우선 순위 최상**: STEP 1 (테스트 작성) → STEP 2 (디자인 토큰)
3. **병렬 작업 가능**: STEP 3 (컴포넌트 분리)와 STEP 4 (래퍼 생성)

### 12.3 예상 결과물

- 깔끔하고 일관된 UI
- 안정적인 기능 동작
- 전체화면 모드로 몰입도 향상
- 유지보수 가능한 코드

---

**문서 작성자**: Claude Code
**최종 업데이트**: 2025-10-02
**버전**: 1.0
