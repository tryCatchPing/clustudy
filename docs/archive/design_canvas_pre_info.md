# 📱 Flutter Note App 코드베이스 분석 문서

## 🏗️ 전체 아키텍처 개요

### 기술 스택

- Flutter + Riverpod 기반 상태 관리
- GoRouter 기반 라우팅
- Scribble 패키지 기반 캔버스 그리기
- Isar 데이터베이스 (로컬 저장)

### 폴더 구조

lib/
├── design_system/ # 디자인 시스템 (더미 UI)
│ ├── components/ # Atoms, Molecules, Organisms
│ ├── screens/ # 디자인용 더미 스크린
│ └── tokens/ # 색상, 간격, 타이포그래피
├── features/ # 실제 기능 구현
│ ├── canvas/ # 노트 편집/캔버스 관련
│ ├── notes/ # 노트 목록/관리 관련
│ └── vaults/ # Vault/폴더 시스템
└── shared/ # 공통 유틸리티
├── routing/ # 라우팅 설정
└── services/ # 공통 서비스

---

## 🎯 캔버스/편집 시스템 구조 (features/canvas)

### 📝 주요 위젯 계층구조

NoteEditorScreen (note_editor_screen.dart:242)
├── AppBar
│ ├── Title (noteTitle + 현재페이지/총페이지)
│ └── actions: [NoteEditorActionsBar] (actions_bar.dart:73)
├── endDrawer: BacklinksPanel (backlinks_panel.dart:32)
└── body: NoteEditorCanvas (note_editor_canvas.dart:44)
├── PageView.builder
│ └── NotePageViewItem (note_page_view_item.dart:145)
│ ├── CanvasBackgroundWidget
│ ├── SavedLinksLayer
│ ├── Scribble (drawing layer)
│ └── LinkerGestureLayer
└── NoteEditorToolbar (toolbar.dart:46)
├── NoteEditorDrawingToolbar
└── NoteEditorPageNavigation

### 🎮 Provider 구조 (note_editor_provider.dart)

#### 세션 관리

// 전역 노트 세션 상태
noteSessionProvider // 현재 활성 noteId 관리
noteRouteIdProvider // 라우트별 ID 관리
resumePageIndexMapProvider // 페이지 복원용 맵
lastKnownPageIndexProvider // 마지막 알려진 페이지

#### 페이지 관리

currentPageIndexProvider(noteId) // 현재 페이지 인덱스
notePagesCountProvider(noteId) // 총 페이지 수
pageControllerProvider(noteId, routeId) // PageView 컨트롤러

#### 스크리블 상태

canvasPageNotifierProvider(pageId) // 페이지별 CustomScribbleNotifier
currentNotifierProvider(noteId) // 현재 페이지 notifier
pageNotifierProvider(noteId, index) // 특정 인덱스 페이지 notifier

### ⚡ 최적화 패턴

#### ✅ ValueListenableBuilder (권장 유지)

// actions_bar.dart - Undo/Redo 버튼
ValueListenableBuilder(
valueListenable: notifier, // CustomScribbleNotifier 직접 감지
builder: (context, value, child) => IconButton(
onPressed: notifier.canUndo ? notifier.undo : null,
),
child: const Icon(Icons.undo), // 아이콘 캐싱으로 재빌드 방지
)

#### 🎯 리빌드 최적화 포인트

1. NotePageViewItem: ValueListenableBuilder로 스크리블 상태만 반응
2. Toolbar 컴포넌트: 각각 독립적으로 분리되어 선택적 리빌드
3. AppBar: 페이지 번호 변경시에만 재빌드

---

## 📋 노트 목록 시스템 구조 (features/notes)

### 🗂️ 현재 구조 (복잡한 Vault/Folder 시스템)

// note_list_screen.dart - 현재 구현
NoteListScreen
├── TopToolbar (동적 제목, 뒤로가기)
├── body: ListView
│ ├── NoteListActionBar (경로 표시)
│ ├── VaultListPanel (Vault 없을 때)
│ └── NoteListFolderSection (폴더/노트 표시)
└── bottomNavigationBar: NoteListPrimaryActions

### 📊 데이터 모델

// note_model.dart
class NoteModel {
final String noteId;
final String title;
final List<NotePageModel> pages;
final NoteSourceType sourceType; // blank, pdfBased
final DateTime createdAt, updatedAt;
}

### 🔌 Provider 구조

// derived_note_providers.dart
notesProvider // 전체 노트 목록 스트림
noteProvider(noteId) // 특정 노트 스트림
noteOnceProvider(noteId) // 단건 조회용

---

## 🎨 디자인 시스템 구조

### 🏷️ 디자인 토큰

// tokens/
AppColors // 색상 팔레트
AppSpacing // 간격 시스템
AppTypography // 폰트 스타일
AppShadows // 그림자 효과
AppIcons // SVG 아이콘 경로

### 🧩 컴포넌트 계층

design_system/components/
├── atoms/ # 최소 단위 (버튼, 텍스트필드)
├── molecules/ # 조합 컴포넌트 (카드, 픽커)
└── organisms/ # 복합 컴포넌트 (툴바, 그리드)

### 🎯 타겟 디자인 (design_system/screens/notes/note_screen.dart)

DesignNoteScreen { - 배경: Colors.grey[100] - AppBar: 보라색 배경 + 중앙 제목 - body: - 상단 컨테이너 (흰색, 둥근모서리, 그림자) - "노트 관리" 헤더 + "새 노트 만들기" 버튼 - 노트 카드 리스트 (제목, 설명, 날짜, 액션버튼) - 하단 "PDF 가져오기" 섹션
}

---

## 🛤️ 라우팅 구조

### 📍 주요 라우트

// app_routes.dart
static const String noteList = '/notes'; // 노트 목록
static const String noteEdit = '/notes/:noteId/edit'; // 노트 편집
static const String noteSearch = '/notes/search'; // 노트 검색

### 🔄 네비게이션 플로우

HomeScreen → [/notes] → NoteListScreen
↓ 노트 선택
[/notes/:noteId/edit] → NoteEditorScreen

---

# 🎯 다음 작업: 디자인 적용 가이드

## 📋 작업 목표

design_system/screens/notes/note_screen.dart의 UI를
features/notes/pages/note_list_screen.dart에 동일하게 구현

## 🔄 현재 vs 목표 비교

### 현재 (복잡한 구조)

NoteListScreen { - TopToolbar (동적) - VaultListPanel / NoteListFolderSection - 복잡한 Vault/Folder 네비게이션 - 하단 FloatingActionButton들
}

### 목표 (단순한 구조)

NoteListScreen { - AppBar (고정 디자인) - 단일 컨테이너 - 헤더 ("노트 관리" + 새 노트 버튼) - 노트 카드 리스트 - PDF 가져오기 섹션
}

## 🛠️ 구현 전략

1. 기존 복잡한 로직 단순화

- Vault/Folder 시스템 → 단순 노트 리스트
- 동적 툴바 → 고정 AppBar
- 복잡한 상태 관리 → 단순 노트 목록만

2. Provider 최적화

// 필요한 Provider만 사용
ref.watch(notesProvider) // 전체 노트 목록
ref.read(noteListControllerProvider) // 액션 처리

3. 위젯 분리 전략

\_NoteManagementContainer { - \_HeaderSection (제목 + 새 노트 버튼) - \_NoteCardsList (노트 카드 리스트)
}
\_ImportPdfSection { - PDF 가져오기 UI
}

4. 리빌드 최적화

- 노트 목록: notesProvider 변경시만
- 개별 카드: 해당 노트 데이터 변경시만
- 액션 버튼: 로딩 상태 변경시만

## ⚠️ 주의사항

1. 기존 Provider 구조 유지: notesProvider, noteListControllerProvider 활용
2. 라우팅 동작 유지: 노트 선택시 /notes/:noteId/edit 이동
3. 에러 처리 유지: AppSnackBar, AppErrorSpec 사용
4. 디자인 토큰 활용: AppColors, AppSpacing 등 적극 사용

## 📝 체크리스트

- 디자인 시스템의 더미 UI 분석
- 기존 복잡한 Vault/Folder 로직 제거
- 단순한 노트 카드 리스트 구현
- "새 노트 만들기" 액션 연결
- "PDF 가져오기" 기능 연결
- 노트 편집 네비게이션 연결
- 로딩/에러 상태 처리
- 리빌드 최적화 검증

---

# 📚 핵심 파일 참조

## 🎯 디자인 참고

- lib/design_system/screens/notes/note_screen.dart (타겟 UI)

## 🔧 구현 대상

- lib/features/notes/pages/note_list_screen.dart (수정 필요)

## 🧩 활용 컴포넌트

- lib/design\*system/components/\*\*/\_.dart (재사용 가능)
- lib/design\*system/tokens/\*\*/\_.dart (디자인 토큰)

## 📊 데이터 레이어

- lib/features/notes/data/derived_note_providers.dart
- lib/features/notes/providers/note_list_controller.dart
- lib/features/notes/models/note_model.dart

---

# 🎨 DesignNoteScreen 상세 분석

## 📱 전체 UI 구조 분석

### 레이아웃 계층구조

```
DesignNoteScreen (note_screen.dart:7)
├── Scaffold
│   ├── backgroundColor: Colors.grey[100] (line:14)
│   ├── AppBar
│   │   ├── backgroundColor: Color(0xFF6750A4) (line:23)
│   │   ├── title: "노트 목록" (line:16)
│   │   └── centerTitle: true (line:25)
│   └── Body
│       └── SafeArea + Padding(24) + SingleChildScrollView (line:27-30)
│           ├── MainContainer (line:33)
│           └── _ImportSection (line:102)
```

### 🧩 주요 컴포넌트 상세 분석

#### 1. MainContainer 스타일 (Lines 33-45)

```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: Offset(0, 5)
    )]
  )
)
```

#### 2. Header Section (Lines 49-86)

- **레이아웃**: Row(spaceBetween)
- **왼쪽**: Column(제목 + 설명)
  - "노트 관리" (fontSize: 24, fontWeight: bold)
  - "최근 생성한 노트와 PDF를 빠르게 확인하세요" (color: grey)
- **오른쪽**: FilledButton("새 노트 만들기")
  - backgroundColor: Color(0xFF6750A4)
  - borderRadius: 12
  - padding: horizontal(20), vertical(14)

#### 3. \_NoteCard 컴포넌트 (Lines 118-189)

```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.withOpacity(0.15))
  ),
  child: Row(
    children: [
      Expanded(Column(title + description)),
      Column(updatedAt + actions)
    ]
  )
)
```

#### 4. \_ImportSection 컴포넌트 (Lines 191-235)

```dart
Container(
  padding: EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.withOpacity(0.2))
  ),
  child: Row(
    children: [
      Icon(Icons.picture_as_pdf, color: 0xFF6750A4),
      Expanded(Column(title + description)),
      FilledButton.tonal("파일 선택")
    ]
  )
)
```

## 🔧 모듈화 및 적용 계획

### ✅ 즉시 사용 가능한 컴포넌트

#### 1. AppBar 스타일

- **위치**: DesignNoteScreen Lines 15-26
- **적용방법**: 스타일 그대로 복사
- **특징**: 보라색 배경, 흰색 텍스트, 중앙 정렬

#### 2. \_ImportSection 위젯

- **위치**: Lines 191-235
- **적용방법**: 위젯 전체 복사 후 콜백 연결
- **수정사항**: `onTap` 파라미터를 실제 PDF import 기능과 연결

### 🔄 부분 수정 필요한 컴포넌트

#### 3. \_NoteCard 위젯

- **위치**: Lines 118-189
- **수정사항**:

  ```dart
  // Before
  final _DemoNote note;

  // After
  final NoteModel note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  ```

- **데이터 바인딩**:
  - `note.title` → `noteModel.title`
  - `note.description` → `noteModel.description` 또는 생성 로직
  - `note.updatedAt` → `noteModel.updatedAt.formatDate()`

#### 4. Header Section

- **위치**: Lines 49-86
- **수정사항**: 하드코딩된 텍스트를 파라미터화
- **콜백 연결**: "새 노트 만들기" 버튼을 실제 생성 기능과 연결

### 🏗️ 공통 컴포넌트화 후보

#### 5. MainContainer 래퍼

- **분리 위치**: `design_system/components/molecules/main_container.dart`
- **재사용성**: 다른 화면에서도 활용 가능
- **스타일**: 흰색 배경 + 그림자 + 둥근 모서리(20) + 패딩(24)

## 📋 Features 적용 단계별 계획

### 🎯 1단계: 스타일 및 레이아웃 적용

1. **AppBar**: 색상과 스타일 직접 적용
2. **배경색**: `Colors.grey[100]` 적용
3. **패딩**: 24px 적용
4. **스크롤**: SingleChildScrollView 적용

### 🔗 2단계: 데이터 연결

1. **Provider 연결**:
   ```dart
   final notesAsync = ref.watch(notesProvider);
   final controller = ref.read(noteListControllerProvider);
   ```
2. **NoteCard 데이터 바인딩**: \_DemoNote → NoteModel
3. **액션 연결**: 더미 액션 → 실제 기능

### 🎨 3단계: 컴포넌트 최적화

1. **MainContainer 분리** (선택사항)
2. **NoteCard 독립 위젯화**
3. **ImportSection 독립 위젯화**
4. **리빌드 최적화**: ValueListenableBuilder, Consumer 활용

## 🎨 디자인 토큰 매핑

### 색상 시스템

- **Primary**: `Color(0xFF6750A4)` → AppColors 추가 또는 기존 활용
- **Background**: `Colors.grey[100]` → AppColors.backgroundGrey
- **Surface**: `Colors.white` → AppColors.surface
- **Border**: `Colors.grey.withOpacity(0.15)` → AppColors.borderLight

### 간격 시스템

- **Container Padding**: 24px → AppSpacing.large
- **Card Padding**: 20px → AppSpacing.medium
- **Small Spacing**: 8px, 12px → AppSpacing.small, AppSpacing.medium

### 테두리 반지름

- **Main Container**: 20px → AppSpacing.radiusLarge
- **Card**: 16px → AppSpacing.radiusMedium
- **Button**: 12px → AppSpacing.radiusSmall

## ⚠️ 구현 시 주의사항

1. **기존 Provider 구조 유지**: `notesProvider`, `noteListControllerProvider` 활용
2. **라우팅 연결**: 노트 카드 탭 시 `/notes/:noteId/edit` 이동
3. **에러 처리**: `AppSnackBar`, `AppErrorSpec` 사용
4. **성능 최적화**: 불필요한 리빌드 방지
5. **접근성**: 기존 앱의 접근성 가이드라인 준수

## 📝 구현 우선순위

1. **High**: AppBar, MainContainer, Header Section
2. **Medium**: NoteCard 데이터 바인딩, ImportSection
3. **Low**: 공통 컴포넌트 분리, 세부 애니메이션
