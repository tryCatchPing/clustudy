# 📚 디자이너를 위한 Flutter 학습 경로

## 개요

이 학습 경로는 **디자인 배경을 가진 학습자**가 **4주 동안 Flutter UI 개발 능력**을 기를 수 있도록 설계되었습니다. 이론보다는 **실습 중심**으로 구성되어 있으며, **프로젝트에 바로 적용**할 수 있는 실무 기술에 집중합니다.

## 🎯 학습 목표

- Figma 디자인을 Flutter 코드로 변환할 수 있다
- AI 도구를 활용하여 효율적으로 UI 코드를 생성할 수 있다  
- 재사용 가능한 컴포넌트를 만들 수 있다
- 디자인 시스템을 Flutter 코드로 구현할 수 있다
- 개발자와 효과적으로 협업할 수 있다

## 📅 4주 학습 계획

### 🗓️ Week 1: Flutter 기초 + 레이아웃

#### Day 1-2: 개발 환경 설정 + Hello World
**학습 내용:**
- Flutter 개발 환경 설정 (VS Code, FVM)
- 첫 번째 앱 실행해보기
- Hot Reload 이해하기

**실습 과제:**
```dart
// lib/design_system/designer_workspace/learning/week1_day1.dart
import 'package:flutter/material.dart';

class HelloWorldApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('내 첫 번째 앱')),
        body: Center(
          child: Text('Hello, Flutter!', 
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
```

#### Day 3-4: 기본 위젯 마스터하기
**학습 위젯:**
- `Container`, `Text`, `Image`
- `Column`, `Row`, `Stack`  
- `Padding`, `Margin`, `SizedBox`

**실습 과제:** 명함 디자인 구현
```dart
// lib/design_system/designer_workspace/learning/week1_day3.dart
class BusinessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 180,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('홍길동', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
          ),
          SizedBox(height: 8),
          Text('UX/UI Designer', 
            style: TextStyle(fontSize: 16, color: Colors.grey[600])
          ),
          Spacer(),
          Row(
            children: [
              Icon(Icons.email, size: 16),
              SizedBox(width: 4),
              Text('hong@company.com'),
            ],
          ),
        ],
      ),
    );
  }
}
```

#### Day 5-7: 리스트 + 스크롤뷰
**학습 내용:**
- `ListView`, `ListView.builder`
- `SingleChildScrollView`
- 무한 스크롤 개념

**실습 과제:** 연락처 목록 앱
```dart
// lib/design_system/designer_workspace/learning/week1_day5.dart
class ContactList extends StatelessWidget {
  final List<Contact> contacts = [
    Contact(name: '김철수', phone: '010-1234-5678'),
    Contact(name: '이영희', phone: '010-9876-5432'),
    // ... 더 많은 연락처
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(contact.name[0]),
          ),
          title: Text(contact.name),
          subtitle: Text(contact.phone),
          trailing: Icon(Icons.call),
        );
      },
    );
  }
}

class Contact {
  final String name;
  final String phone;
  Contact({required this.name, required this.phone});
}
```

**주말 과제:** 개인 포트폴리오 소개 페이지 만들기

---

### 🗓️ Week 2: 스타일링 + 디자인 시스템

#### Day 8-9: 고급 스타일링
**학습 내용:**
- `BoxDecoration` (그라데이션, 테두리, 그림자)
- `TextStyle` 세부 속성
- `ClipRRect`, `ClipPath`

**실습 과제:** 모던한 카드 디자인
```dart
// lib/design_system/designer_workspace/learning/week2_day8.dart
class ModernCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366f1).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 배경 패턴
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            // 콘텐츠
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Premium Plan', 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('₩29,000/월', 
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Day 10-11: 디자인 토큰 시스템
**학습 내용:**
- 색상 시스템 구축
- 타이포그래피 시스템
- 간격 시스템

**실습 과제:** 프로젝트 디자인 토큰 구현
```dart
// lib/design_system/shared/tokens/app_colors.dart
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366f1);
  static const Color primaryDark = Color(0xFF4f46e5);
  static const Color primaryLight = Color(0xFF818cf8);
  
  // Surface Colors  
  static const Color surface = Color(0xFFffffff);
  static const Color surfaceDark = Color(0xFF1f2937);
  
  // Text Colors
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceSecondary = Color(0xFF6b7280);
  
  // Status Colors
  static const Color success = Color(0xFF10b981);
  static const Color error = Color(0xFFef4444);
  static const Color warning = Color(0xFFf59e0b);
}
```

#### Day 12-14: 버튼 + 입력 컴포넌트
**학습 내용:**
- 다양한 버튼 스타일
- `TextFormField` 커스터마이징
- `Checkbox`, `Switch`, `Slider`

**실습 과제:** 로그인 폼 UI 구현

**주말 과제:** 현재 프로젝트의 기본 컴포넌트 라이브러리 구축

---

### 🗓️ Week 3: 컴포넌트화 + AI 도구

#### Day 15-16: 재사용 가능한 위젯 만들기
**학습 내용:**
- `StatelessWidget` vs `StatefulWidget`
- Props 시스템 (생성자 매개변수)
- Optional vs Required 매개변수

**실습 과제:** 범용 버튼 컴포넌트
```dart
// lib/design_system/shared/components/app_button.dart
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isDisabled || isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _getBackgroundColor(),
        foregroundColor: _getForegroundColor(), 
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading 
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.surface;
    }
  }
  
  // ... 다른 메서드들
}

enum AppButtonVariant { primary, secondary }
enum AppButtonSize { small, medium, large }
```

#### Day 17-18: AI 도구 마스터하기
**학습 내용:**
- Figma MCP 사용법
- AI 생성 코드 품질 평가
- 수동 정제 기법

**실습 과제:**
1. Figma 컴포넌트 → AI 코드 생성
2. 생성된 코드를 디자인 토큰 기반으로 리팩토링  
3. 재사용 가능한 컴포넌트로 변환

#### Day 19-21: 복합 컴포넌트 구축
**학습 내용:**
- 여러 위젯을 조합한 복합 컴포넌트
- 컴포넌트 간 데이터 전달
- 이벤트 버블링

**실습 과제:** 노트 카드 컴포넌트
```dart
// lib/design_system/shared/components/note_card.dart
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.title,
    required this.lastModified,
    this.preview,
    this.thumbnailUrl,
    this.onTap,
    this.onFavorite,
    this.onDelete,
    this.isFavorited = false,
  });

  final String title;
  final DateTime lastModified;
  final String? preview;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final bool isFavorited;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              // 썸네일
              if (thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              SizedBox(width: AppSpacing.medium),
              
              // 콘텐츠
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.headline2),
                    if (preview != null) ...[
                      SizedBox(height: AppSpacing.small),
                      Text(
                        preview!,
                        style: AppTypography.body2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: AppSpacing.small),
                    Text(
                      _formatDate(lastModified),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              
              // 액션 버튼들
              Column(
                children: [
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? AppColors.error : null,
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // 날짜 포맷팅 로직
    return '${date.month}/${date.day}';
  }
}
```

**주말 과제:** 현재 프로젝트의 주요 화면 중 1개를 컴포넌트 기반으로 재구축

---

### 🗓️ Week 4: 실전 프로젝트 적용

#### Day 22-24: 홈 화면 구현
**목표:** 프로젝트의 홈 화면을 완전히 Flutter로 구현

**작업 단계:**
1. Figma 디자인 분석
2. AI 도구로 초기 코드 생성  
3. 디자인 토큰 적용
4. 컴포넌트화
5. 개발자 핸드오프

**결과물:**
- `lib/design_system/designer_workspace/handoff/home_screen_ui.dart`
- 사용된 컴포넌트들
- 핸드오프 문서

#### Day 25-26: 노트 목록 화면 구현
**목표:** 노트 목록 화면 구현 + 검색 기능 UI

**작업 단계:**
- 동일한 패턴으로 진행
- 검색 바 컴포넌트 개발
- 필터 UI 구현

#### Day 27-28: 마무리 + 문서화
**목표:**
- 모든 컴포넌트 정리 및 문서화
- 디자인 시스템 가이드 작성
- 학습 회고 및 다음 단계 계획

**최종 결과물:**
- 완성된 컴포넌트 라이브러리
- 디자인 시스템 문서
- 개발자 인수인계 완료

## 📖 주간별 참고 자료

### Week 1: 기초 학습 자료
- **Flutter 공식 문서**: [flutter.dev](https://flutter.dev)
- **Flutter Layout Cheat Sheet**: 레이아웃 패턴 참고
- **Material Design Guidelines**: 구글 디자인 시스템

### Week 2: 스타일링 자료  
- **Color Tool**: 색상 조합 도구
- **Typography Scale**: 타이포그래피 가이드
- **Elevation Guidelines**: 그림자 시스템

### Week 3: 컴포넌트 자료
- **Flutter Widget Catalog**: 위젯 레퍼런스
- **Component Gallery**: 컴포넌트 예시들
- **Figma to Flutter**: 변환 가이드

### Week 4: 실전 자료
- **코드 리뷰 체크리스트**
- **성능 최적화 가이드**
- **협업 도구 사용법**

## 🎯 단계별 학습 검증

### Week 1 체크리스트
- [ ] Flutter 앱을 실행할 수 있다
- [ ] 기본 위젯들을 조합하여 화면을 만들 수 있다
- [ ] Column, Row를 사용한 레이아웃을 구성할 수 있다
- [ ] ListView로 스크롤 가능한 목록을 만들 수 있다

### Week 2 체크리스트  
- [ ] 그라데이션, 그림자 등 고급 스타일을 적용할 수 있다
- [ ] 디자인 토큰을 정의하고 사용할 수 있다
- [ ] 폰트, 색상 시스템을 구축할 수 있다
- [ ] 일관된 스타일의 UI를 만들 수 있다

### Week 3 체크리스트
- [ ] 재사용 가능한 컴포넌트를 만들 수 있다
- [ ] Props를 통해 컴포넌트를 커스터마이징할 수 있다
- [ ] AI 도구를 활용하여 코드를 생성하고 정제할 수 있다
- [ ] 복합 컴포넌트를 설계하고 구현할 수 있다

### Week 4 체크리스트
- [ ] Figma 디자인을 Flutter 코드로 완전히 변환할 수 있다
- [ ] 개발자에게 인수인계할 수 있는 품질의 코드를 작성할 수 있다  
- [ ] 컴포넌트 라이브러리를 구축하고 문서화할 수 있다
- [ ] 효과적인 디자이너-개발자 협업을 수행할 수 있다

## 🚀 학습 완료 후 로드맵

### 단기 목표 (1-2개월)
- **고급 인터랙션**: 애니메이션, 제스처, 전환 효과
- **반응형 디자인**: 다양한 화면 크기 대응
- **접근성**: 스크린 리더, 키보드 네비게이션

### 중기 목표 (3-6개월)  
- **고급 위젯**: CustomPainter, CustomScrollView
- **성능 최적화**: 메모리 관리, 렌더링 최적화
- **플랫폼별 UI**: Material vs Cupertino

### 장기 목표 (6개월 이상)
- **풀스택 이해**: 상태 관리, API 연동 기초
- **디자인 시스템 리드**: 팀 차원의 디자인 시스템 구축
- **크로스 플랫폼 전문성**: 웹, 데스크톱 앱 개발

---

💡 **학습 팁**: 매일 조금씩이라도 코드를 작성해보세요. 이론보다는 실습이 훨씬 중요합니다!