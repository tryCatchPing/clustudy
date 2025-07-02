# IT Contest Flutter Project

4인 팀으로 진행되는 Flutter 프로젝트입니다.

## 🚀 프로젝트 시작하기

### 필수 요구사항

- Flutter SDK (최신 stable 버전)
- Dart SDK
- VSCode + Flutter/Dart Extensions
- Git

### 환경 설정

1. **저장소 클론**

   ```bash
   git clone [repository-url]
   cd it-contest
   ```

2. **Flutter 의존성 설치**

   ```bash
   flutter pub get
   ```

3. **Flutter Doctor 실행으로 환경 확인**

   ```bash
   flutter doctor
   ```

4. **프로젝트 실행**
   ```bash
   flutter run
   ```

## 📋 개발 규칙 & 가이드

### Git 브랜치 전략

- `main`: 배포 가능한 안정적인 코드
- `develop`: 개발 중인 기능들이 통합되는 브랜치
- `feature/기능명`: 개별 기능 개발 브랜치
- `hotfix/이슈명`: 긴급 버그 수정 브랜치

### 커밋 메시지 규칙

```
type(scope): subject

body (optional)

footer (optional)
```

**Type:**

- `feat`: 새로운 기능
- `fix`: 버그 수정
- `docs`: 문서 수정
- `style`: 코드 스타일 변경 (포맷팅, 세미콜론 등)
- `refactor`: 코드 리팩토링
- `test`: 테스트 코드
- `chore`: 빌드 업무 수정, 패키지 매니저 수정

**예시:**

```
feat(auth): add login functionality
fix(api): resolve network timeout issue
docs(readme): update installation guide
```

### 코드 스타일

- **Dart 코드 포맷팅**: `dart format .` 또는 VSCode 자동 포맷팅 사용
- **Lint 규칙**: `flutter analyze` 통과 필수
- **Single Quotes**: 문자열은 작은따옴표 사용
- **Const 키워드**: 가능한 모든 곳에서 const 사용
- **80자 제한**: 한 줄은 80자를 넘지 않도록

### 폴더 구조

```
lib/
├── core/           # 공통 기능 (constants, utils, services)
├── data/           # 데이터 레이어 (repositories, models, datasources)
├── domain/         # 비즈니스 로직 (entities, use cases)
├── presentation/   # UI 레이어 (pages, widgets, providers)
│   ├── pages/
│   ├── widgets/
│   └── providers/
├── shared/         # 공유 컴포넌트
└── main.dart
```

## 🔧 개발 도구

### VSCode Extensions (권장)

- Flutter
- Dart
- GitLens
- Bracket Pair Colorizer
- Material Icon Theme

### 유용한 명령어

```bash
# 의존성 설치
flutter pub get

# 코드 분석
flutter analyze

# 테스트 실행
flutter test

# 빌드 (Android)
flutter build apk

# 빌드 (iOS)
flutter build ios

# 캐시 정리
flutter clean
```

## 🤝 협업 가이드

### Pull Request 규칙

1. **브랜치명**: `feature/기능명` 또는 `fix/이슈명`
2. **PR 제목**: 명확하고 간결하게
3. **설명**: 변경사항, 테스트 방법, 스크린샷 포함
4. **리뷰어**: 최소 1명 이상의 팀원 리뷰 필수
5. **머지**: Squash and merge 사용

### 코드 리뷰 가이드

- 코드 스타일과 컨벤션 준수 확인
- 성능과 메모리 누수 고려
- 테스트 코드 존재 여부 확인
- 명명 규칙 일관성 검토
- 주석과 문서화 적절성 판단

### 이슈 관리

- 기능 요청, 버그 리포트는 GitHub Issues 사용
- 라벨을 활용한 분류 (bug, enhancement, question)
- 담당자 지정 및 마일스톤 설정

## 📱 테스트

### 테스트 종류

- **Unit Tests**: 개별 함수/클래스 테스트
- **Widget Tests**: UI 컴포넌트 테스트
- **Integration Tests**: 전체 앱 플로우 테스트

### 테스트 실행

```bash
# 모든 테스트 실행
flutter test

# 커버리지 포함 테스트
flutter test --coverage
```

## 🔄 CI/CD

- GitHub Actions를 통한 자동 빌드 및 테스트
- main 브랜치 푸시 시 자동 배포

## 📞 연락처

팀원 연락처 및 역할:

- 팀장: [이름] - [연락처]
- 개발자 1: [이름] - [연락처]
- 개발자 2: [이름] - [연락처]
- 개발자 3: [이름] - [연락처]

## 📋 TODO

- [ ] 초기 프로젝트 설정
- [ ] 기본 UI 컴포넌트 개발
- [ ] API 연동
- [ ] 테스트 코드 작성
- [ ] 배포 설정
