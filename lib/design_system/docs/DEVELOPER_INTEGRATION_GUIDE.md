# 🛠️ 개발자를 위한 UI 통합 가이드

## 개요

이 가이드는 **디자이너가 작성한 UI 코드에 비즈니스 로직을 연결**하는 방법을 다룹니다. 디자이너는 순수 UI를 담당하고, 개발자는 상태 관리, 라우팅, 데이터 처리를 담당하는 **역할 분담형 협업** 구조입니다.

## 🎯 개발자의 역할

### ✅ 개발자가 담당하는 것
- **상태 관리**: Provider를 통한 앱 전역 상태 관리
- **라우팅**: GoRouter를 활용한 페이지 네비게이션
- **비즈니스 로직**: API 호출, 데이터 변환, 유효성 검사
- **이벤트 처리**: 버튼 클릭, 텍스트 입력, 제스처 등
- **성능 최적화**: 메모리 관리, 빌드 최적화
- **테스트**: Unit Test, Widget Test, Integration Test

### ❌ 개발자가 하지 않는 것
- **UI 디자인**: 색상, 폰트, 레이아웃 등 시각적 요소 수정
- **스타일링**: CSS 속성에 해당하는 Flutter 스타일
- **컴포넌트 구조**: 위젯 트리 구조 변경

## 📁 작업 폴더 구조

```
lib/design_system/developer_workspace/
├── logic_layer/          # 비즈니스 로직
│   ├── services/         # API, 데이터 서비스
│   └── utils/            # 유틸리티 함수
├── state_management/     # 상태 관리
│   ├── providers/        # Provider 클래스들
│   └── notifiers/        # ChangeNotifier 클래스들
└── integration/          # UI + 로직 통합
    ├── screens/          # 완성된 화면
    └── components/       # 완성된 컴포넌트
```

## 🔄 UI 통합 워크플로우

### 1단계: 디자이너 UI 코드 분석

디자이너로부터 받은 UI 코드를 분석합니다:

```dart
// 디자이너가 작성한 UI (handoff 폴더)
class HomeScreenUI extends StatelessWidget {
  const HomeScreenUI({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('노트 목록')),
      body: Column(
        children: [
          SearchBarWidget(
            onChanged: null, // 🔴 로직 연결 필요
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // 🔴 실제 데이터로 교체 필요
              itemBuilder: (context, index) => NoteCard(
                title: '샘플 제목 $index',
                subtitle: '샘플 내용',
                onTap: null, // 🔴 로직 연결 필요
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null, // 🔴 로직 연결 필요
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### 2단계: 상태 관리 설계

Provider를 사용하여 상태 관리 구조를 설계합니다:

```dart
// state_management/providers/notes_provider.dart
import 'package:flutter/material.dart';
import '../../../shared/models/note_model.dart';
import '../../../shared/services/note_service.dart';

class NotesProvider extends ChangeNotifier {
  final NoteService _noteService = NoteService.instance;
  
  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  List<NoteModel> get notes => _searchQuery.isEmpty 
      ? _notes 
      : _notes.where((note) => 
          note.title.toLowerCase().contains(_searchQuery.toLowerCase())
        ).toList();
  
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  
  // 노트 목록 로드
  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _notes = await _noteService.getAllNotes();
    } catch (e) {
      // 에러 처리
      debugPrint('노트 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 검색어 업데이트
  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // 새 노트 생성
  Future<void> createNote() async {
    try {
      final newNote = await _noteService.createBlankNote();
      _notes.insert(0, newNote);
      notifyListeners();
    } catch (e) {
      debugPrint('노트 생성 실패: $e');
    }
  }
}
```

### 3단계: UI + 로직 통합

디자이너 UI에 상태 관리와 이벤트 처리를 연결합니다:

```dart
// integration/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../designer_workspace/handoff/home_screen_ui.dart';
import '../../state_management/providers/notes_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 로드 시 노트 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        return Scaffold(
          appBar: AppBar(title: Text('노트 목록')),
          body: Column(
            children: [
              SearchBarWidget(
                onChanged: (query) {
                  // 🔵 검색 로직 연결
                  notesProvider.updateSearchQuery(query);
                },
              ),
              Expanded(
                child: notesProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: notesProvider.notes.length,
                        itemBuilder: (context, index) {
                          final note = notesProvider.notes[index];
                          return NoteCard(
                            title: note.title,
                            subtitle: note.createdAt.toString(),
                            onTap: () {
                              // 🔵 노트 편집 페이지로 이동
                              context.go('/notes/${note.id}/edit');
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              // 🔵 새 노트 생성 로직 연결
              await notesProvider.createNote();
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
```

### 4단계: 라우팅 연결

GoRouter를 사용하여 페이지 네비게이션을 설정합니다:

```dart
// integration/routing/app_router.dart
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../../../features/canvas/pages/note_editor_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/notes/:noteId/edit',
      builder: (context, state) {
        final noteId = state.pathParameters['noteId']!;
        return NoteEditorScreen(noteId: noteId);
      },
    ),
  ],
);
```

## 🔧 주요 통합 패턴

### Provider 패턴 적용

```dart
// main.dart에서 Provider 등록
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => CanvasProvider()),
        // 다른 Provider들...
      ],
      child: MyApp(),
    ),
  );
}

// UI에서 Provider 사용
Widget build(BuildContext context) {
  return Consumer<NotesProvider>(
    builder: (context, provider, child) {
      return SomeWidget(
        data: provider.someData,
        onSomething: provider.someMethod,
      );
    },
  );
}
```

### 이벤트 핸들러 연결

```dart
// 디자이너 코드: onPressed: null
// 개발자 통합: onPressed: () { /* 로직 */ }

ElevatedButton(
  onPressed: () async {
    // 비동기 작업 처리
    await context.read<SomeProvider>().doSomething();
    
    // 네비게이션
    if (mounted) {
      context.go('/next-page');
    }
  },
  child: Text('버튼'),
)
```

### 폼 데이터 처리

```dart
class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      context.read<NotesProvider>().createNoteWithTitle(title);
      context.go('/');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: '제목'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text('저장'),
          ),
        ],
      ),
    );
  }
}
```

## 🧪 테스트 전략

### Widget Test 예시

```dart
// test/integration/home_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:it_contest/design_system/integration/screens/home_screen.dart';
import 'package:it_contest/design_system/state_management/providers/notes_provider.dart';

void main() {
  testWidgets('홈 화면에서 노트 목록 표시', (WidgetTester tester) async {
    final notesProvider = NotesProvider();
    
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notesProvider,
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    
    // 로딩 인디케이터 확인
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // 노트 로드 대기
    await tester.pumpAndSettle();
    
    // 노트 카드 확인
    expect(find.byType(NoteCard), findsWidgets);
  });
}
```

## 🚨 주의사항

### 성능 최적화

```dart
// ❌ 잘못된 방법: 불필요한 rebuild 발생
Consumer<NotesProvider>(
  builder: (context, provider, child) {
    return ExpensiveWidget(data: provider.allData);
  },
)

// ✅ 올바른 방법: 필요한 데이터만 선택
Selector<NotesProvider, List<NoteModel>>(
  selector: (context, provider) => provider.filteredNotes,
  builder: (context, notes, child) {
    return ListView.builder(...);
  },
)
```

### 메모리 관리

```dart
class _SomeScreenState extends State<SomeScreen> {
  late ScrollController _scrollController;
  late TextEditingController _textController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
  }
  
  @override
  void dispose() {
    // 🔴 필수: 컨트롤러 해제
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(...);
  }
}
```

## ✅ 통합 완료 체크리스트

### 기능적 요구사항
- [ ] 모든 이벤트 핸들러 연결 완료
- [ ] 상태 관리 정상 작동
- [ ] 라우팅 연결 완료
- [ ] API/서비스 연동 완료

### 성능 요구사항
- [ ] 불필요한 rebuild 최소화
- [ ] 메모리 누수 없음
- [ ] 로딩 상태 처리 완료
- [ ] 에러 처리 구현

### 코드 품질
- [ ] Provider 패턴 준수
- [ ] GoRouter 사용
- [ ] 테스트 코드 작성
- [ ] 주석 및 문서화 완료

---

💡 **팁**: 디자이너와의 소통을 위해 변경사항이 있을 때는 항상 이유를 설명하고, UI에 영향을 주는 수정은 사전에 논의하세요!