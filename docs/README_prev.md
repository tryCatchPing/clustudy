# Clustudy

**손글씨 노트 앱** - 4인 팀으로 진행되는 Flutter 프로젝트입니다.

## 개요

### 핵심 기능

- **Canvas 기반 손글씨 입력**
- **PDF 위에 손글씨 작성**
- **노트 간 링크 생성**
- **그래프 뷰** 노트 관계 시각화
- **로컬 데이터베이스** (isar)
- **자동 저장**

### 팀 구성 및 역할 분담

| 팀 구분      | 담당자 | 주요 역할                                           |
| ------------ | ------ | --------------------------------------------------- |
| **디자인팀** | 김유라 | **기획 + UI/UX + 디자인 + QA**                      |
| **디자인팀** | 김효민 | 기획 + 디자인                                       |
| **개발팀**   | 김지담 | **Link + DB**                                       |
| **개발팀**   | 장태웅 | **기획 + PM + Canvas + Link + DB + Analytics + QA** |

## 프로젝트 시작하기

### 필수 요구사항

**중요: 버전 호환성**

- **Flutter SDK 3.32.5** (최신 안정 버전, Dart SDK 3.8.1+ 요구)
- **FVM 사용 필수** (팀원 간 버전 통일)
- **VSCode** + Flutter/Dart Extensions
- **Git**
- **Android Studio**

### 호환성 확인 및 해결

**현재 Flutter 버전 확인:**

```bash
flutter --version
# 또는
fvm list
```

**버전이 낮은 경우 해결 방법:**

최신 Flutter 설치 (권장)

```bash
# Flutter 업그레이드
flutter upgrade

# 또는 FVM으로 특정 버전 설치
dart pub global activate fvm
fvm install 3.32.5
fvm use 3.32.5
```

### 빠른 시작

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

### 환경 설정

1. **FVM 설치 및 Flutter 버전 관리**

   ```bash
   # FVM 설치
   dart pub global activate fvm

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

#### 0. "Flutter SDK Version is not installed" 오류 (신규 추가)

```bash
# 문제: fvm install stable로 설치했지만 실제 버전이 없음
# 해결: 구체적인 버전 번호로 재설치
fvm install 3.32.5  # 실제 버전 다운로드
fvm use 3.32.5      # 프로젝트에서 사용 설정

# 확인
fvm list  # Local 컬럼에 ● 표시가 있어야 함
```

#### 1. "Dart SDK version is not compatible" 오류

```bash
# 문제: Dart SDK 버전이 맞지 않음
# 해결: FVM으로 올바른 Flutter 버전 사용
fvm use 3.32.5
fvm flutter pub get
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

## 개발 워크플로우

### Git 브랜치 전략 (Modified Feature Branch)

```
main (프로덕션 배포) ← 최종 안정 버전
 ↑
dev (개발 통합) ← 모든 PR의 타겟
 ↑
├── feature/canvas-dev-a        # 개발자 A: Canvas 관련
├── feature/database-dev-b      # 개발자 B: DB/Storage 관련
├── feature/pdf-dev-b          # 개발자 B: PDF 관련
├── design/ui-design-a        # 디자이너 A: UI 컴포넌트
└── design/graph-design-b     # 디자이너 B: 그래프 UI
```

#### **브랜치 명명 규칙**

```bash
feature/[기능명]-[담당자]
feature/canvas-dev-a
feature/database-dev-b
feature/lasso-ui-design-a
```

### 상세 작업 플로우 (충돌 최소화 목표)

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
# 작업 시작 전
git checkout dev
git pull origin dev
git checkout feature/canvas-dev-a
git rebase dev  # 또는 git merge dev (팀 정책에 따라)

# 충돌 발생 시
git status  # 충돌 파일 확인
# 충돌 해결 후
git add .
git rebase --continue

# 작업 완료 후
git add .
git commit -m "feat(canvas): implement basic drawing"
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

#### **Rebase 정책 사용**

for clean history.

**Rebase 실패 시 Merge 사용:**

팀장에게 문의 필수

```bash
# rebase가 너무 복잡한 충돌을 만들 때
git rebase --abort
git merge dev
```

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

팀장에게 문의 필수

### 커밋 메시지 규칙

```
type(scope): subject

예시:
feat(canvas): add basic drawing functionality
fix(database): resolve migration issue
ui(lasso): implement selection feedback
```

**Type 분류:**

- `feat`: 새 기능 구현
- `fix`: 버그 수정
- `ui`: UI/UX 개선
- `db`: 데이터베이스 관련
- `perf`: 성능 개선
- `test`: 테스트 코드
- `docs`: 문서 업데이트
- (추후 추가될 수 있음)

## 팀 협업 가이드

### 정기 미팅 일정

| 미팅               | 시간                         | 참석자       | 목적                          |
| ------------------ | ---------------------------- | ------------ | ----------------------------- |
| **Daily Check-in** | 매일 오후 11시 (5분)         | 전체         | 진행 상황 공유                |
| **Design Review**  | 매주 월요일 오전 10시 (20분) | 디자인, 팀장 | 디자인 피드백                 |
| **Code Review**    | 매주 금요일 6시 (45분)       | 개발팀       | 코드 검토 및 블로킹 이슈 확인 |
| **Sprint Demo**    | 매주 월요일 오전 11시 (30분) | 전체         | 주간 성과 데모                |

## 라이선스

이 프로젝트는 MIT License를 따릅니다. 자세한 내용은 루트의 `LICENSE` 파일을 참고하세요.

## 외부 리소스

- Pretendard Variable — SIL Open Font License 1.1 (https://github.com/orioncactus/pretendard)
- Play — SIL Open Font License 1.1 (https://fonts.google.com/specimen/Play)
- 앱 아이콘 및 SVG 아이콘 — Clustudy 팀 자체 제작
