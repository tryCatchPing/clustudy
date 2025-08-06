# 🎨 디자인 시스템

## 개요

이 디렉토리는 **재사용 가능한 UI 컴포넌트 라이브러리**입니다. `features/` 폴더의 각 화면에서 import하여 사용하는 **공통 UI 컴포넌트들**을 제공합니다. 디자이너가 AI 도구를 활용해 UI를 생성하고, 이를 정제하여 재사용 가능한 컴포넌트로 만드는 워크플로우를 지원합니다.

## 🏗️ 폴더 구조

```
lib/design_system/
├── 🤖 ai_generated/          # AI 도구 생성 결과물 보관
│   ├── figma_exports/        # Figma MCP 결과물
│   ├── raw_components/       # AI가 생성한 원본 컴포넌트
│   └── pages/                # AI가 생성한 페이지 코드
├── 🎨 tokens/                # 디자인 토큰
│   ├── app_colors.dart       # 색상 시스템
│   ├── app_typography.dart   # 타이포그래피 시스템
│   ├── app_spacing.dart      # 간격 시스템
│   └── app_shadows.dart      # 그림자 시스템
├── 🧩 components/            # 정제된 재사용 컴포넌트
│   ├── atoms/                # 기본 컴포넌트 (버튼, 입력 등)
│   ├── molecules/            # 복합 컴포넌트 (카드, 폼 등)
│   └── organisms/            # 복잡한 UI 섹션 (헤더, 툴바 등)
├── 🔧 utils/                 # 디자인 시스템 유틸리티
│   ├── theme.dart            # 앱 테마 구성
│   └── extensions.dart       # 유틸리티 확장
└── 📚 docs/                  # 협업 가이드 문서
    ├── DESIGNER_FLUTTER_GUIDE.md      # 디자이너용 Flutter 가이드
    ├── DEVELOPER_INTEGRATION_GUIDE.md # 개발자용 통합 가이드
    ├── COLLABORATION_WORKFLOW.md      # 협업 워크플로우
    └── FLUTTER_LEARNING_PATH.md       # 디자이너 학습 경로
```

## 📂 features와의 관계

```
lib/
├── features/              # 메인 앱 구조 (화면, 로직, 라우팅)
│   ├── canvas/
│   │   ├── pages/        # 화면
│   │   ├── controllers/  # 비즈니스 로직
│   │   ├── routing/      # 라우팅
│   │   └── widgets/      # ⬅️ 점진적으로 design_system 컴포넌트로 교체
│   ├── notes/
│   └── home/
├── design_system/         # UI 컴포넌트 라이브러리 (이 폴더)
│   └── components/       # ➡️ features에서 import하여 사용
└── shared/               # 서비스, 유틸리티
```

## 👥 역할 분담

### 🎨 디자이너 역할
- **Figma 디자인** → **Flutter UI 코드** 변환
- **AI 도구 활용**하여 효율적인 코드 생성 및 정제
- **디자인 토큰** 관리 (색상, 폰트, 간격 시스템)
- **재사용 가능한 컴포넌트** 구축
- **개발자와의 핸드오프** 진행

### 💻 개발자 역할  
- **상태 관리** (Provider 패턴)
- **라우팅** (GoRouter)
- **비즈니스 로직** 구현 (API 호출, 데이터 처리)
- **성능 최적화** 및 **메모리 관리**
- **테스트 코드** 작성

## 🛠️ 디자인 토큰

### 색상 시스템 (`tokens/app_colors.dart`)
```dart
import '../../design_system/tokens/app_colors.dart';

Container(
  color: AppColors.primary,
  child: Text('텍스트', style: TextStyle(color: AppColors.onPrimary)),
)
```

### 타이포그래피 (`tokens/app_typography.dart`)
```dart
import '../../design_system/tokens/app_typography.dart';

Text('제목', style: AppTypography.headline1),
Text('본문', style: AppTypography.body1),
```

### 간격 시스템 (`tokens/app_spacing.dart`)
```dart
import '../../design_system/tokens/app_spacing.dart';

Padding(
  padding: EdgeInsets.all(AppSpacing.medium), // 16px
  child: Column(
    children: [
      Text('첫 번째'),
      SizedBox(height: AppSpacing.small), // 8px
      Text('두 번째'),
    ],
  ),
)
```

### 그림자 시스템 (`tokens/app_shadows.dart`)
```dart
import '../../design_system/tokens/app_shadows.dart';

Container(
  decoration: BoxDecoration(
    boxShadow: AppShadows.medium,
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### 앱 테마 (`utils/theme.dart`)
```dart
import '../../design_system/utils/theme.dart';

MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: MyHomePage(),
)
```

## 🔄 작업 워크플로우

### 1️⃣ AI 코드 생성 및 보관
```
Figma 디자인 → AI 도구 (Figma MCP) → ai_generated/ 폴더에 저장
```

### 2️⃣ 컴포넌트 정제 및 분류
```
ai_generated/ → 수동 정제 → components/atoms|molecules|organisms/
```

### 3️⃣ features에서 사용
```
features/canvas/widgets/ → import design_system/components/ → 기존 커스텀 위젯 교체
```

### 실제 예시:

**AI 생성 후 정제:**
```dart
// ai_generated/raw_components/button_component.dart (AI 생성 원본)
Container(
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(color: Color(0xFF6366f1)),
  child: Text('버튼'),
)

// ⬇️ 정제 후 ⬇️

// components/atoms/app_button.dart (정제된 컴포넌트)
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';

class AppButton extends StatelessWidget {
  const AppButton({required this.text, this.onPressed});
  final String text;
  final VoidCallback? onPressed;
  
  Widget build(context) => ElevatedButton(
    onPressed: onPressed,
    child: Text(text),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: EdgeInsets.all(AppSpacing.medium),
    ),
  );
}
```

**features에서 사용:**
```dart
// features/canvas/widgets/toolbar/note_editor_toolbar.dart
import '../../../../design_system/components/atoms/app_button.dart';

class NoteEditorToolbar extends StatelessWidget {
  Widget build(context) => Row(
    children: [
      AppButton(
        text: '저장',
        onPressed: () => _saveNote(), // 비즈니스 로직
      ),
    ],
  );
}

## 📋 품질 체크리스트

### 디자이너 체크리스트
- [ ] 모든 색상이 `AppColors` 사용
- [ ] 모든 폰트가 `AppTypography` 사용
- [ ] 모든 간격이 `AppSpacing` 사용
- [ ] `const` 생성자 사용
- [ ] 이벤트 핸들러 `null`로 설정 (개발자가 로직 연결)
- [ ] 컴포넌트 props 명확히 정의
- [ ] 핸드오프 문서 작성 완료

### 개발자 체크리스트
- [ ] Provider 패턴 적용
- [ ] GoRouter 연결 완료
- [ ] 모든 이벤트 핸들러 구현
- [ ] 에러 처리 및 로딩 상태 구현
- [ ] 메모리 누수 방지 (Controller dispose)
- [ ] Widget 테스트 작성
- [ ] 성능 최적화 완료

## 🚀 시작하기

### 디자이너용
1. **Flutter 기초 학습**: `docs/FLUTTER_LEARNING_PATH.md` 참고
2. **개발 환경 설정**: VS Code, FVM 설치
3. **첫 컴포넌트 만들기**: `docs/DESIGNER_FLUTTER_GUIDE.md` 참고

### 개발자용
1. **협업 워크플로우 이해**: `docs/COLLABORATION_WORKFLOW.md` 참고
2. **통합 가이드 숙지**: `docs/DEVELOPER_INTEGRATION_GUIDE.md` 참고
3. **디자이너 핸드오프 받기**: `designer_workspace/handoff/` 확인

## 🧪 테스트 전략

### Widget Test 예시
```dart
testWidgets('NoteCard displays title and subtitle', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: NoteCard(
        title: '테스트 제목',
        subtitle: '테스트 부제목',
      ),
    ),
  );
  
  expect(find.text('테스트 제목'), findsOneWidget);
  expect(find.text('테스트 부제목'), findsOneWidget);
});
```

### 통합 테스트
```bash
# 전체 테스트 실행
fvm flutter test

# 특정 디렉토리 테스트
fvm flutter test test/design_system/
```

## 📖 참고 문서

### 핵심 가이드
- [디자이너를 위한 Flutter 가이드](docs/DESIGNER_FLUTTER_GUIDE.md)
- [개발자를 위한 통합 가이드](docs/DEVELOPER_INTEGRATION_GUIDE.md)
- [협업 워크플로우](docs/COLLABORATION_WORKFLOW.md)
- [Flutter 학습 경로](docs/FLUTTER_LEARNING_PATH.md)

### 외부 리소스
- [Flutter 공식 문서](https://flutter.dev/docs)
- [Material Design Guidelines](https://material.io/design)
- [Provider 패턴 가이드](https://pub.dev/packages/provider)
- [GoRouter 가이드](https://pub.dev/packages/go_router)

## 🤝 기여하기

### 디자이너 기여 방법
1. **AI 코드 생성**: Figma MCP 등을 활용해 `ai_generated/` 폴더에 원본 저장
2. **코드 정제**: 디자인 토큰 적용하여 `components/` 폴더에 정제된 컴포넌트 생성
3. **문서화**: 컴포넌트 사용법과 props 설명 추가
4. **개발자와 협업**: features에서 사용할 때 가이드 제공

### 개발자 기여 방법
1. **컴포넌트 활용**: `design_system/components/`에서 필요한 컴포넌트 import
2. **비즈니스 로직 연결**: `features/` 폴더에서 이벤트 핸들러와 상태 관리 구현
3. **성능 최적화**: 컴포넌트 사용 시 불필요한 rebuild 방지
4. **피드백 제공**: 컴포넌트 개선 사항이나 추가 요청사항 공유

## 🚨 주의사항

### 성능 고려사항
- **불필요한 rebuild 방지**: `Consumer` 대신 `Selector` 적극 활용
- **메모리 관리**: Controller, Stream 등은 반드시 dispose
- **이미지 최적화**: 적절한 크기로 리사이즈 후 사용

### 코드 스타일
- **const 생성자**: 가능한 모든 위젯에서 사용
- **final 변수**: 변경되지 않는 변수는 final 선언
- **네이밍 컨벤션**: camelCase 사용, 의미 있는 이름 선택

---

💡 **성공의 열쇠**: 서로의 전문성을 존중하면서도 적극적으로 소통하는 것입니다. 디자이너는 UI에, 개발자는 로직에 집중하되, 서로의 영역을 이해하려 노력해야 합니다!