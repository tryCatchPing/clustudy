# IT Contest Flutter Project

**손글씨 노트 앱** - 4인 팀으로 진행되는 Flutter 프로젝트입니다.

## 🎯 프로젝트 개요

### 핵심 기능

- **Canvas 기반 손글씨 입력** (Apple Pencil 지원)
- **PDF 위에 손글씨 작성**
- **노트 간 링크 생성** (Lasso 선택 → 링크)
- **그래프 뷰** 노트 관계 시각화
- **로컬 데이터베이스** (Drift vs Hive)
- **자동 저장**
- **다양한 내보내기** (PDF, ZIP)

### 팀 구성 및 역할 분담

| 팀 구분      | 담당자 | 주요 역할                      | 담당 Task 영역                          |
| ------------ | ------ | ------------------------------ | --------------------------------------- |
| **디자인팀** | 김유라 | **UI/UX 리드 + 프론트엔드**    | Canvas UI, 사용자 경험, 컴포넌트        |
| **디자인팀** | 김효민 | **시각 디자인 + QA**           | 디자인 시스템, 아이콘, 테스트           |
| **개발팀**   | 김지담 | **Canvas & UI 스페셜리스트**   | Task 2, 3, 9 (Canvas, Undo/Redo, Lasso) |
| **개발팀**   | 장태웅 | **Data & Export 스페셜리스트** | Task 4, 5, 6, 7, 8 (DB, 저장, PDF)      |

> **🔄 협업 방식**: 디자인 완료 후 디자인팀이 개발 지원으로 전환하여 최종 2개월간 4명 모두 개발에 집중

### 프로젝트 타임라인 (8주)

#### **Phase 1: 디자인 + 기초 개발 (1-2주)**

- **디자인팀**: UI/UX 디자인 완성 + Flutter 학습
- **개발팀**: 프로젝트 설정 + 기본 아키텍처

#### **Phase 2: 핵심 기능 개발 (3-5주)**

- **전체팀**: Canvas, 데이터베이스, PDF 뷰어 구현
- **의존성 순서**: Task 1 → Task 4 → Task 2 → Task 7

#### **Phase 3: 고급 기능 + 완성 (6-8주)**

- **전체팀**: 링크, 그래프, 내보내기, 최적화
- **완성 순서**: Task 9 → Task 10 → Task 12 → Task 6,8

## 🚀 프로젝트 시작하기

### 필수 요구사항

⚠️ **중요: 버전 호환성**

- **Flutter SDK 3.32.5** (최신 안정 버전, Dart SDK 3.8.1+ 요구)
- **FVM 사용 필수** (팀원 간 버전 통일)
- **VSCode** + Flutter/Dart Extensions
- **Git**
- **Apple Developer Account** (iOS 테스트용)

> **주의**: 현재 프로젝트는 **Dart SDK 3.8.1+**를 요구합니다.
> 구버전 Flutter를 사용하시는 분들은 반드시 아래 환경 설정을 따라주세요.

### 호환성 확인 및 해결

**현재 Flutter 버전 확인:**

```bash
flutter --version
# 또는
fvm list
```

**버전이 낮은 경우 해결 방법:**

1. **최신 Flutter 설치 (권장)**

   ```bash
   # Flutter 업그레이드
   flutter upgrade

   # 또는 FVM으로 특정 버전 설치
   dart pub global activate fvm
   fvm install 3.32.5
   fvm use 3.32.5
   ```

2. **또는 프로젝트 Dart 버전 다운그레이드** (임시방편, 권장하지 않음)
   ```yaml
   # pubspec.yaml에서 수정
   environment:
     sdk: ^3.5.0 # 본인 Flutter 버전에 맞게 조정
   ```

### 🚀 빠른 시작 (요약)

**신규 팀원 체크리스트:**

```bash
# 1️⃣ 프로젝트 클론
git clone [repository-url]
cd it-contest

# 2️⃣ FVM 설치 및 Flutter 설정
dart pub global activate fvm
fvm install 3.32.5    # ⚠️ 정확한 버전 번호 필수!
fvm use 3.32.5

# 3️⃣ 설치 확인
fvm list              # Local에 ● 표시 확인
fvm flutter doctor    # 모든 ✓ 확인

# 4️⃣ 프로젝트 실행
fvm flutter pub get
fvm flutter run
```

✅ **성공 조건**: `fvm list`에서 Local 컬럼에 ● 표시 + `fvm flutter doctor`에서 모든 ✓

### 환경 설정

1. **FVM 설치 및 Flutter 버전 관리**

   ```bash
   # FVM 설치
   dart pub global activate fvm

   # ⚠️ 중요: 특정 버전 번호로 설치해야 함
   # ❌ 이렇게 하면 안됨: fvm install stable (채널만 추가됨)
   # ✅ 이렇게 해야 함: 정확한 버전 번호 사용
   fvm install 3.32.5
   fvm use 3.32.5

   # 설치 확인 (.fvmrc 파일이 있으므로 자동으로 올바른 버전 사용됨)
   fvm list  # Local에 ● 표시 확인
   ```

2. **저장소 클론 및 의존성 설치**

   ```bash
   git clone [repository-url]
   cd it-contest
   fvm flutter pub get
   ```

3. **환경 확인 및 실행**

   ```bash
   # 환경 확인 (모든 항목에 ✓ 표시 나와야 함)
   fvm flutter doctor

   # 프로젝트 실행
   fvm flutter run
   ```

   **예상 출력 예시:**

   ```bash
   # fvm list 성공 시
   ┌─────────┬─────────┬─────────────────┬──────────────┬──────────────┬────────┬───────┐
   │ Version │ Channel │ Flutter Version │ Dart Version │ Release Date │ Global │ Local │
   ├─────────┼─────────┼─────────────────┼──────────────┼──────────────┼────────┼───────┤
   │ 3.32.5  │ stable  │ 3.32.5          │ 3.8.1        │ Jun 25, 2025 │        │ ●     │
   └─────────┴─────────┴─────────────────┴──────────────┴──────────────┴────────┴───────┘

   # fvm flutter doctor 성공 시
   [✓] Flutter (Channel stable, 3.32.5, on macOS 15.5 24F74 darwin-arm64, locale ko-KR)
   [✓] Android toolchain - develop for Android devices
   [✓] Xcode - develop for iOS and macOS (Xcode 16.4)
   [✓] VS Code (version 1.100.3)
   • No issues found!
   ```

### ⚠️ 자주 발생하는 호환성 문제 해결

#### 1. "Dart SDK version is not compatible" 오류

```bash
# 문제: Dart SDK 버전이 맞지 않음
# 해결: FVM으로 올바른 Flutter 버전 사용
fvm use 3.32.5
fvm flutter pub get
```

#### 0. "Flutter SDK Version is not installed" 오류 (신규 추가)

```bash
# 문제: fvm install stable로 설치했지만 실제 버전이 없음
# 해결: 구체적인 버전 번호로 재설치
fvm install 3.32.5  # 실제 버전 다운로드
fvm use 3.32.5      # 프로젝트에서 사용 설정

# 확인
fvm list  # Local 컬럼에 ● 표시가 있어야 함
```

#### 2. "flutter command not found" 오류

```bash
# 문제: FVM Flutter가 PATH에 없음
# 해결: FVM 명령어 사용
fvm flutter doctor
fvm flutter run

# 또는 alias 설정 (선택사항)
alias flutter="fvm flutter"
alias dart="fvm dart"
```

#### 3. VS Code에서 Flutter SDK를 찾지 못하는 경우

```json
// .vscode/settings.json에서 확인
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk"
}
```

#### 4. 의존성 설치 문제

```bash
# FVM으로 의존성 재설치
fvm flutter clean
fvm flutter pub get

# iOS 의존성 (macOS에서만)
cd ios && pod install && cd ..
```

### 🚨 팀원들을 위한 체크리스트

**새로운 팀원이 프로젝트를 시작할 때:**

- [ ] FVM 설치됨
- [ ] Flutter 3.32.5 설치됨
- [ ] `fvm flutter doctor` 통과
- [ ] VS Code Flutter extension 설치됨
- [ ] `.fvmrc` 파일 존재 확인
- [ ] `fvm flutter run` 성공

**문제 발생 시 확인사항:**

- [ ] `fvm list`에서 Local 컬럼에 ● 표시 확인
- [ ] `flutter --version` vs `fvm flutter --version` 비교
- [ ] `pubspec.yaml`의 SDK 버전 확인
- [ ] `.fvm/flutter_sdk` 폴더 존재 확인
- [ ] `fvm flutter doctor` 실행하여 모든 ✓ 확인

**FVM 관련 주의사항:**

- ⚠️ `fvm install stable`은 채널만 추가, 실제 설치 안됨
- ✅ `fvm install 3.32.5`로 구체적 버전 번호 사용 필수
- 📁 `.fvmrc` 파일이 있으면 자동으로 해당 버전 사용됨
- 💡 VS Code 재시작 필요할 수 있음 (터미널 메시지 확인)

## 📋 개발 워크플로우

### Git 브랜치 전략 (Modified Feature Branch)

```
main (프로덕션 배포) ← 최종 안정 버전
 ↑
dev (개발 통합) ← 매주 금요일 통합, 모든 PR의 타겟
 ↑
├── feature/canvas-dev-a        # 개발자 A: Canvas 관련
├── feature/database-dev-b      # 개발자 B: DB/Storage 관련
├── feature/pdf-dev-b          # 개발자 B: PDF 관련
├── feature/ui-design-a        # 디자이너 A: UI 컴포넌트
└── feature/graph-design-b     # 디자이너 B: 그래프 UI
```

#### **브랜치 명명 규칙**

```bash
feature/[기능명]-[담당자]
feature/canvas-dev-a          # Canvas 기능 - 개발자 A
feature/database-dev-b        # Database 기능 - 개발자 B
feature/lasso-ui-design-a     # Lasso UI - 디자이너 A
```

### 🔄 상세 작업 플로우 (충돌 최소화)

#### **1️⃣ 새로운 기능 브랜치 시작**

```bash
# 항상 최신 dev에서 시작
git checkout dev
git pull origin dev

# 새 브랜치 생성
git checkout -b feature/canvas-dev-a

# 첫 푸시 (upstream 설정)
git push -u origin feature/canvas-dev-a
```

#### **2️⃣ 일일 작업 사이클**

```bash
# 🌅 작업 시작 전 (매일 아침 권장)
git checkout dev
git pull origin dev
git checkout feature/canvas-dev-a
git rebase dev  # 또는 git merge dev (팀 정책에 따라)

# 충돌 발생 시
git status  # 충돌 파일 확인
# 충돌 해결 후
git add .
git rebase --continue

# 🌆 작업 완료 후 (매일 저녁)
git add .
git commit -m "[TASK-2] feat(canvas): implement basic drawing"
git push origin feature/canvas-dev-a
```

#### **3️⃣ Pull Request 전 준비 (중요! 충돌 방지)**

```bash
# PR 올리기 직전에 반드시 수행
git checkout dev
git pull origin dev
git checkout feature/canvas-dev-a

# 최신 dev와 동기화 (rebase 권장)
git rebase dev

# 충돌 발생 시 해결
# ... 충돌 해결 ...
git add .
git rebase --continue

# 강제 푸시 (rebase 후 필요)
git push --force-with-lease origin feature/canvas-dev-a

# 이제 GitHub에서 PR 생성
```

#### **4️⃣ 코드 리뷰 수정사항 반영**

```bash
# 리뷰 피드백 반영
git add .
git commit -m "[TASK-2] fix(canvas): address code review feedback"

# 다시 dev와 동기화 (다른 팀원 작업이 머지되었을 수 있음)
git checkout dev
git pull origin dev
git checkout feature/canvas-dev-a
git rebase dev

# 푸시
git push --force-with-lease origin feature/canvas-dev-a
```

#### **5️⃣ PR 머지 후 정리**

```bash
# PR이 머지된 후
git checkout dev
git pull origin dev

# 로컬 브랜치 삭제
git branch -d feature/canvas-dev-a

# 원격 브랜치 삭제 (GitHub에서 자동 삭제 설정 권장)
git push origin --delete feature/canvas-dev-a
```

### ⚡ 충돌 최소화 전략

#### **📅 작업 스케줄링**

1. **소규모 PR**: 하나의 기능당 최대 500줄 이하
2. **빠른 머지**: PR 생성 후 24시간 내 리뷰 완료 목표
3. **파일 분할**: 같은 파일을 여러 명이 수정하지 않도록 사전 조율

#### **🗂️ 파일별 담당자 분리**

```
lib/
├── canvas/          # 개발자 A 전담
├── database/        # 개발자 B 전담
├── pdf/            # 개발자 B 전담
├── ui/
│   ├── components/  # 디자이너 A 전담
│   └── theme/       # 디자이너 B 전담
└── shared/         # 공통 - 사전 협의 필요
```

#### **📱 동시 작업 시 충돌 방지 규칙**

1. **pubspec.yaml 수정**: 슬랙에서 미리 공지 후 작업
2. **shared 폴더**: PR 전에 팀원들과 사전 논의
3. **main.dart, app.dart**: 최소한의 수정, 사전 협의 필수

#### **🔧 Rebase vs Merge 정책**

**팀 정책: Rebase 우선 (Clean History)**

```bash
# ✅ 권장: Rebase (깔끔한 히스토리)
git rebase dev

# ⚠️ 주의: Merge (히스토리 복잡해짐, 필요시에만)
git merge dev
```

**Rebase 실패 시 Merge 사용:**

```bash
# rebase가 너무 복잡한 충돌을 만들 때
git rebase --abort
git merge dev
```

#### **🚨 긴급 상황 대응**

**충돌이 복잡할 때:**

```bash
# 1. 백업 브랜치 생성
git checkout -b feature/canvas-dev-a-backup

# 2. 원본 브랜치에서 fresh start
git checkout feature/canvas-dev-a
git reset --hard origin/dev
git cherry-pick [필요한-커밋들]

# 3. 단계별로 충돌 해결
```

**실수로 잘못 머지했을 때:**

```bash
# dev 브랜치에서 되돌리기 (머지 직후에만)
git checkout dev
git reset --hard HEAD~1
git push --force-with-lease origin dev
```

### 📊 주간 통합 프로세스

#### **🗓️ 매주 금요일 통합 일정**

1. **오후 5시**: 모든 PR 리뷰 완료
2. **오후 6시**: dev → main 머지 준비
3. **오후 7시**: 통합 테스트 및 main 머지
4. **오후 8시**: 다음 주 스프린트 계획

#### **📋 통합 체크리스트**

```bash
# dev 브랜치 최종 검증
git checkout dev
git pull origin dev
fvm flutter test        # 모든 테스트 통과
fvm flutter analyze     # 정적 분석 통과
fvm flutter run         # 앱 정상 실행

# main으로 머지
git checkout main
git pull origin main
git merge dev           # Fast-forward 머지 권장
git push origin main

# 태그 생성 (선택)
git tag -a week-2 -m "Week 2 sprint completion"
git push origin week-2
```

### 🎯 팀 협업 모범 사례

#### **💬 커뮤니케이션**

- **슬랙 알림**: 큰 변경사항 PR 전에 미리 공지
- **코드 리뷰**: 비판이 아닌 학습과 개선의 기회
- **Daily Standup**: 어제 한 일, 오늘 할 일, 블로커 공유

#### **🔍 코드 리뷰 가이드라인**

- **24시간 규칙**: PR 생성 후 24시간 내 1차 리뷰
- **Approve 조건**: 최소 1명 승인 + 충돌 해결 완료
- **리뷰 우선순위**: 작은 PR > 큰 PR, 긴급도 순

#### **📈 성과 지표**

- **머지 성공률**: 95% 이상 (충돌 없는 머지)
- **리뷰 시간**: 평균 4시간 이내
- **PR 크기**: 평균 200줄 이하

### Task 기반 개발 순서 (의존성 고려)

#### **🏗️ Week 1-2: 기초 구축**

```bash
└── Task 1: Flutter 프로젝트 설정 (전체 협업)
    ├── 1.1 FVM + Flutter 3.22 설정 ✅
    ├── 1.2 Material 3 프로젝트 생성
    ├── 1.3 의존성 라이브러리 추가
    └── 1.4 기본 앱 구조 구축

└── Task 4: Drift ORM 데이터베이스 (개발자 B)
    ├── 4.1 스키마 설계 (Note, Stroke, Link)
    ├── 4.2 DAO 구현
    └── 4.3 데이터베이스 초기화
```

#### **🎨 Week 3-4: 핵심 기능**

```bash
└── Task 2: Canvas & Stroke (개발자 A + 디자이너 A)
    ├── 2.1 Drawing Canvas 설정
    ├── 2.2 Scribble 통합
    ├── 2.3 제스처 감지
    └── 2.4 도구 컨트롤 (펜, 지우개, 색상)

└── Task 7: PDF 뷰어 (개발자 B)
    └── flutter_pdfx 통합 + Canvas 레이어
```

#### **⚡ Week 5-6: 고급 기능**

```bash
└── Task 3: Undo/Redo (개발자 A)
└── Task 5: Auto-Save (개발자 B)
└── Task 9: Lasso 선택 (개발자 A + 디자이너 B)
```

#### **🔗 Week 7-8: 완성**

```bash
└── Task 10: 링크 생성 (개발자 A)
└── Task 12: 그래프 뷰 (디자이너 B + 개발자 B)
└── Task 6,8: 내보내기 (개발자 B)
└── Task 17: 성능 최적화 (전체)
```

### 커밋 메시지 규칙

```
[TASK-번호] type(scope): subject

예시:
[TASK-2] feat(canvas): add basic drawing functionality
[TASK-4] fix(database): resolve migration issue
[TASK-9] ui(lasso): implement selection feedback
```

**Type 분류:**

- `feat`: 새 기능 구현
- `fix`: 버그 수정
- `ui`: UI/UX 개선
- `db`: 데이터베이스 관련
- `perf`: 성능 개선
- `test`: 테스트 코드
- `docs`: 문서 업데이트

## 🎨 디자인 → 개발 핸드오프

### 디자인 자산 관리

```
design-assets/
├── figma-exports/           # Figma에서 내보낸 에셋
│   ├── icons/              # SVG 아이콘들
│   ├── components/         # UI 컴포넌트 spec
│   └── screens/           # 화면별 디자인
├── flutter-integration/    # Flutter 코드로 변환된 디자인
│   ├── theme/             # Material 3 테마
│   ├── widgets/           # 커스텀 위젯
│   └── constants/         # 디자인 토큰
└── prototypes/            # 인터랙션 프로토타입
```

### 디자인 시스템 컴포넌트

```dart
// 예시: 디자인 토큰 정의
class AppColors {
  static const primary = Color(0xFF6750A4);
  static const secondary = Color(0xFF625B71);
  static const canvas = Color(0xFFFFFBFE);
  static const stroke = Color(0xFF1C1B1F);
}

class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 32, fontWeight: FontWeight.bold
  );
  static const body = TextStyle(
    fontSize: 16, fontWeight: FontWeight.normal
  );
}
```

## 🔧 개발 환경 & 도구

### AI/LLM 기본 비활성 정책

- 이 저장소는 기본 개발/테스트/CI 플로우에서 **LLM/AI를 사용하지 않습니다**.
- IDE 플러그인이나 외부 파이프라인으로 인해 모델 연결 오류가 발생할 수 있으니, 기본은 비활성하고 필요 시 **개인 로컬에서만 opt-in** 하세요.
- 가이드:
  - 문서: [모델 공급자 오류 트러블슈팅](docs/troubleshooting/model-provider-error/README.md)
  - 문서: [IDE AI/LLM 플러그인 사용 지침](docs/troubleshooting/ide-ai.md)

### 필수 VSCode Extensions

- Flutter
- Dart
- GitLens
- Flutter Tree
- Pubspec Assist
- **Thunder Client** (API 테스트용)

### 주요 의존성 라이브러리

```yaml
dependencies:
  # UI & Canvas
  flutter_svg: ^2.0.9

  # Database
  drift: ^2.14.1
  sqlite3_flutter_libs: ^0.5.18

  # PDF
  flutter_pdfx: ^2.0.1
  dart_pdf: ^3.10.7

  # Graph
  graphview: ^1.2.0

  # Export
  archive: ^3.4.9

  # State Management
  provider: ^6.1.1
```

## 🤝 팀 협업 가이드

### 📅 정기 미팅 일정

| 미팅               | 시간                   | 참석자 | 목적           |
| ------------------ | ---------------------- | ------ | -------------- |
| **Daily Check-in** | 매일 오후 6시 (10분)   | 전체   | 진행 상황 공유 |
| **Design Review**  | 매주 수요일 7시 (30분) | 전체   | 디자인 피드백  |
| **Code Review**    | 매주 금요일 6시 (45분) | 개발팀 | 코드 품질 검토 |
| **Sprint Demo**    | 매주 금요일 7시 (30분) | 전체   | 주간 성과 데모 |

### 🔍 Pull Request 프로세스

#### PR 템플릿

```markdown
## [TASK-번호] 기능 요약

### 🔨 구현 내용

- [ ] 주요 구현 사항 1
- [ ] 주요 구현 사항 2

### 📱 테스트 방법

1. 앱 실행 후 [특정 화면] 이동
2. [특정 동작] 수행
3. [예상 결과] 확인

### 📸 스크린샷 (UI 변경시)

| Before    | After        |
| --------- | ------------ |
| 이전 화면 | 변경 후 화면 |

### ✅ 체크리스트

- [ ] 코드 리뷰 완료
- [ ] 충돌 해결 완료
- [ ] 로컬 테스트 완료
- [ ] 관련 Task 업데이트
```

#### 리뷰어 지정 규칙

- **Canvas 관련**: 개발자 A + 디자이너 A
- **Database 관련**: 개발자 B + 개발자 A
- **UI 컴포넌트**: 디자이너 A + 디자이너 B
- **통합 기능**: 전체 팀원

## 📱 테스트 전략

### 테스트 우선순위

1. **Canvas 기능** (핵심): 그리기, 지우기, 색상 변경
2. **데이터 저장**: 자동 저장, 불러오기, 데이터 무결성
3. **PDF 통합**: PDF 위에 그리기, 내보내기
4. **성능**: 1000개 stroke에서도 55FPS 유지

### 디바이스 테스트 매트릭스

| 플랫폼  | 디바이스            | 담당자     | 우선순위 |
| ------- | ------------------- | ---------- | -------- |
| iOS     | iPhone (최신)       | 개발자 A   | 🔥 높음  |
| iOS     | iPad + Apple Pencil | 디자이너 A | 🔥 높음  |
| Android | Pixel/Galaxy        | 개발자 B   | 🟡 중간  |
| Web     | Chrome/Safari       | 디자이너 B | 🟢 낮음  |

## 🎯 마일스톤 & 성공 기준

### Week 1-2: 기반 구축 ✅

- [ ] **Task 1**: Flutter 프로젝트 설정 완료
- [ ] **Task 4**: 기본 데이터베이스 스키마 구현
- [ ] **디자인**: 핵심 UI 디자인 80% 완성
- [ ] **팀**: Git 워크플로우 정착

### Week 3-4: 핵심 기능 🎨

- [ ] **Task 2**: Canvas 기본 그리기 기능
- [ ] **Task 7**: PDF 뷰어 통합
- [ ] **성능**: 기본 그리기 30FPS 이상
- [ ] **UI**: 메인 화면 UI 구현

### Week 5-6: 고급 기능 ⚡

- [ ] **Task 3**: Undo/Redo (500 액션)
- [ ] **Task 5**: 5초 자동 저장
- [ ] **Task 9**: Lasso 선택 도구
- [ ] **통합**: 기능 간 연동 테스트

### Week 7-8: 완성 🚀

- [ ] **Task 10**: 링크 생성 기능
- [ ] **Task 12**: 그래프 뷰 시각화
- [ ] **Task 6,8**: PDF/ZIP 내보내기
- [ ] **Task 17**: 성능 최적화 (55FPS, 5MB 이내)
- [ ] **배포**: TestFlight 업로드 준비

### 최종 성공 기준 🏆

#### 기능적 목표

- ✅ **Canvas**: 부드러운 그리기 (55FPS 이상)
- ✅ **PDF**: PDF 위 그리기 + 내보내기
- ✅ **링크**: 노트 간 연결 + 그래프 뷰
- ✅ **성능**: 1000 stroke → 5MB 이내 ZIP

#### 팀 목표

- 🤝 **협업**: 효과적인 디자인-개발 핸드오프
- 📚 **학습**: 각자 Flutter 새 기술 1개+ 습득
- 🔄 **품질**: 코드 리뷰 문화 정착
- 🎯 **완주**: 8주 내 배포 가능한 앱 완성

---

## 📞 팀 연락처

| 이름   | 역할       | 연락처   | 주 활동시간  | 특기              |
| ------ | ---------- | -------- | ------------ | ----------------- |
| [팀장] | 디자이너 A | [연락처] | 평일 10-19시 | UI/UX, 프로토타입 |
| [팀원] | 디자이너 B | [연락처] | 평일 14-21시 | 시각디자인, QA    |
| [팀원] | 개발자 A   | [연락처] | 평일 9-18시  | Canvas, 그래픽스  |
| [팀원] | 개발자 B   | [연락처] | 평일 19-24시 | Database, API     |

---

> **💡 성공의 핵심**: 디자인과 개발의 긴밀한 협업, 명확한 Task 의존성 관리, 그리고 지속적인 소통을 통해 **세상에 없던 손글씨 노트 앱**을 만들어봅시다! 🚀
