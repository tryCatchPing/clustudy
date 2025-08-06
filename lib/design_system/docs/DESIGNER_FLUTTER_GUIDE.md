# 🎨 디자이너를 위한 Flutter 개발 가이드

## 개요

이 가이드는 **디자이너가 직접 Flutter UI 코드를 작성**하여 개발자와 협업하는 방법을 다룹니다. 디자이너는 순수한 UI 코드를 작성하고, 개발자가 비즈니스 로직을 연결하는 **역할 분담형 협업**을 목표로 합니다.

## 🎯 디자이너의 역할

### ✅ 디자이너가 담당하는 것
- **UI 코드 작성**: Figma 디자인 → Flutter 위젯 코드 변환
- **스타일링**: 색상, 폰트, 간격, 그림자 등 시각적 요소
- **레이아웃**: Column, Row, Stack 등을 활용한 화면 구성
- **컴포넌트화**: 재사용 가능한 UI 컴포넌트 제작
- **디자인 토큰 관리**: 일관된 디자인 시스템 유지

### ❌ 디자이너가 하지 않는 것
- **비즈니스 로직**: 데이터 처리, API 호출, 상태 관리
- **라우팅**: 페이지 간 이동 로직
- **성능 최적화**: 메모리 관리, 빌드 최적화
- **테스트 코드**: Unit Test, Widget Test 작성

## 🚀 시작하기

### 1. 개발 환경 설정

```bash
# Flutter SDK 확인
fvm flutter doctor

# 프로젝트 의존성 설치
fvm flutter pub get

# 개발 서버 실행
fvm flutter run
```

### 2. 작업 폴더 구조 이해

```
lib/design_system/designer_workspace/
├── ui_only/           # 순수 UI 코드 (로직 없음)
├── learning/          # 학습용 예제 코드
└── handoff/           # 개발자에게 전달할 완성 UI
```

## 📚 Flutter 기본 위젯 가이드

### 기본 레이아웃 위젯

#### Container - 박스 모델
```dart
Container(
  width: 200,
  height: 100,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Text('Hello World'),
)
```

#### Column - 세로 배치
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text('첫 번째'),
    SizedBox(height: 8),
    Text('두 번째'),
  ],
)
```

#### Row - 가로 배치
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Icon(Icons.star),
    Text('별점'),
    Text('5.0'),
  ],
)
```

### 텍스트 스타일링

```dart
Text(
  '제목 텍스트',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    letterSpacing: -0.5,
  ),
)
```

### 버튼 컴포넌트

```dart
ElevatedButton(
  onPressed: null, // 디자이너는 null로 설정 (개발자가 로직 연결)
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text('버튼 텍스트'),
)
```

## 🎨 디자인 토큰 사용법

### 색상 사용하기
```dart
import '../../shared/tokens/app_colors.dart';

Container(
  color: AppColors.primary,        // 주 색상
  child: Text(
    '텍스트',
    style: TextStyle(color: AppColors.onPrimary),
  ),
)
```

### 타이포그래피 사용하기
```dart
import '../../shared/tokens/app_typography.dart';

Text(
  '제목',
  style: AppTypography.headline1,
),
Text(
  '본문',
  style: AppTypography.body1,
),
```

### 간격 사용하기
```dart
import '../../shared/tokens/app_spacing.dart';

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

## 🤖 AI 도구 활용 워크플로우

### 1단계: Figma MCP로 초기 코드 생성
1. Figma에서 변환할 컴포넌트/페이지 선택
2. AI 도구를 사용해 Flutter 코드 생성
3. 생성된 코드를 `ui_only/` 폴더에 저장

### 2단계: 수동 정제 작업
1. **디자인 토큰 적용**: 하드코딩된 색상/폰트 → 토큰 사용
2. **컴포넌트화**: 반복되는 UI 요소 → 재사용 가능한 위젯
3. **네이밍 개선**: 의미 있는 변수명/클래스명 사용
4. **코드 정리**: 불필요한 코드 제거, 주석 추가

### 3단계: 품질 체크리스트
```dart
// ✅ Good
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.title,
    required this.subtitle,
  });
  
  final String title;
  final String subtitle;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.headline2),
          SizedBox(height: AppSpacing.small),
          Text(subtitle, style: AppTypography.body2),
        ],
      ),
    );
  }
}
```

## ✅ 개발자 전달 체크리스트

### 코드 품질
- [ ] `const` 생성자 사용
- [ ] `final` 변수 선언
- [ ] 싱글 쿼트(`'`) 문자열 사용
- [ ] 의미 있는 클래스/변수명 사용

### 디자인 토큰 적용
- [ ] 색상: `AppColors` 사용
- [ ] 폰트: `AppTypography` 사용  
- [ ] 간격: `AppSpacing` 사용
- [ ] 그림자: `AppShadows` 사용

### 컴포넌트 구조
- [ ] 재사용 가능한 위젯으로 분리
- [ ] Props를 통한 커스터마이징 가능
- [ ] 적절한 주석 추가

### 이벤트 핸들러
- [ ] `onPressed: null` (개발자가 로직 연결)
- [ ] `onTap: null`
- [ ] `onChanged: null`

## 📞 개발자와 소통하기

### 전달 시 포함할 정보
1. **완성된 UI 코드** (`handoff/` 폴더)
2. **사용된 컴포넌트 목록**
3. **특별한 인터랙션 요구사항**
4. **디자인 의도 설명**

### 커뮤니케이션 템플릿
```markdown
## [페이지명] UI 코드 전달

### 📁 파일 위치
- `lib/design_system/designer_workspace/handoff/home_screen_ui.dart`

### 🧩 사용된 컴포넌트
- NoteCard (노트 카드 컴포넌트)
- SearchBar (검색 바)
- FloatingActionButton (플로팅 버튼)

### ⚡ 필요한 로직 연결
- 검색 기능: SearchBar의 onChanged
- 노트 생성: FloatingActionButton의 onPressed
- 노트 클릭: NoteCard의 onTap

### 💡 디자인 의도
- 카드 간격을 넓게 하여 터치하기 쉽게 설계
- 검색바는 항상 상단 고정
- 스크롤 시 플로팅 버튼 숨김 효과 원함
```

## 🎓 다음 단계

1. **기본 위젯 마스터** → 복잡한 레이아웃 도전
2. **커스텀 위젯 제작** → 애니메이션 학습
3. **디자인 시스템 완성** → 고급 인터랙션 구현

---

💡 **팁**: 막히는 부분이 있으면 언제든 개발자에게 질문하세요! 함께 배워나가는 것이 목표입니다.