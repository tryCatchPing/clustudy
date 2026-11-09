# 갤럭시 탭 실기기 테스트 가이드 (PDF 내보내기, #59)

아무것도 설치되지 않은 PC에서 개발 환경을 만들고, 갤럭시 탭을 USB로 연결해 [#59](https://github.com/tryCatchPing/clustudy/pull/59)(내보낸 PDF에서 필기가 좌상단에 작게 몰리던 문제 수정)를 실기기에서 확인하는 절차입니다.

- 기준 OS는 **Windows 10/11**입니다. macOS는 [macOS에서 할 때 다른 점](#macos에서-할-때-다른-점)을 참고하세요.
- 기준 커밋: `main`의 `831287c` 이후
- 명령은 PowerShell 기준입니다.

## 목차

1. [받아야 할 것 한눈에 보기](#1-받아야-할-것-한눈에-보기)
2. [PC 준비](#2-pc-준비)
3. [프로젝트 받기와 Flutter 설치](#3-프로젝트-받기와-flutter-설치)
4. [Firebase 설정 파일 넣기](#4-firebase-설정-파일-넣기)
5. [의존성 설치, 코드 생성, PC에서 먼저 검사](#5-의존성-설치-코드-생성-pc에서-먼저-검사)
6. [갤럭시 탭 준비와 연결](#6-갤럭시-탭-준비와-연결)
7. [앱 설치와 실행](#7-앱-설치와-실행)
8. [로그 보기](#8-로그-보기)
9. [#59 테스트 시나리오](#9-59-테스트-시나리오)
10. [자주 막히는 문제](#10-자주-막히는-문제)

---

## 1. 받아야 할 것 한눈에 보기

### 설치 프로그램

| # | 항목 | 버전 | 받는 곳 | 비고 |
| --- | --- | --- | --- | --- |
| 1 | Git for Windows | 최신 | https://git-scm.com/download/win | FVM이 Flutter를 받을 때도 사용 |
| 2 | Android Studio | 최신 안정판 | https://developer.android.com/studio | Android SDK, adb 설치용. 코드 편집은 VS Code를 써도 됨 |
| 3 | JDK 17 (Eclipse Temurin) | 17 | https://adoptium.net/temurin/releases/?version=17 | CI와 같은 버전(`JAVA_VERSION: 17`). Android Studio 내장 JDK가 너무 새로우면 Gradle 8.12가 실패할 수 있어 따로 둠 |
| 4 | Chocolatey | 최신 | https://chocolatey.org/install | FVM 설치용. FVM zip을 직접 받으면 불필요 |
| 5 | FVM | 최신 | `choco install fvm` 또는 https://github.com/btwld/fvm/releases/latest 의 `windows-x64` zip | 프로젝트 Flutter 버전 고정용 |
| 6 | Flutter | **3.32.5** | FVM이 `.fvmrc`를 보고 설치 | 직접 받지 않음 |
| 7 | Samsung Android USB Driver | 최신 | https://developer.samsung.com/android-usb-driver | **Windows만** 필요. 없으면 `adb devices`에 탭이 안 보일 수 있음 |
| 8 | VS Code + Flutter 확장 (선택) | 최신 | https://code.visualstudio.com | 저장소의 `.vscode/settings.json`이 `.fvm/versions/3.32.5`를 SDK로 지정 |
| 9 | Node.js LTS + Firebase CLI (조건부) | LTS | https://nodejs.org | Firebase 설정 파일을 **새로 생성할 때만** 필요 ([4절](#4-firebase-설정-파일-넣기)) |

### Android Studio SDK Manager에서 설치할 것

Android Studio → `More Actions`(또는 `Tools`) → `SDK Manager`. `SDK Tools` 탭에서는 오른쪽 아래 **Show Package Details**를 체크해야 버전을 고를 수 있습니다.

| 탭 | 항목 | 버전 | 근거 |
| --- | --- | --- | --- |
| SDK Platforms | Android 15 (API 35) SDK Platform | 35 | Flutter 3.32.5 기본 `compileSdk`가 35, `isar_flutter_libs`도 35로 강제 (`android/build.gradle.kts`) |
| SDK Tools | Android SDK Build-Tools | 최신 35.x | |
| SDK Tools | Android SDK Command-line Tools (latest) | latest | `flutter doctor --android-licenses`에 필요 |
| SDK Tools | Android SDK Platform-Tools | latest | `adb` |
| SDK Tools | NDK (Side by side) | **29.0.14206865** | `android/app/build.gradle.kts`의 `ndkVersion`. 빌드 중 자동으로 받기도 하지만 미리 설치해 두는 편이 빠르고 확실함 |

Gradle 8.12, AGP 8.7.3, Kotlin 2.1.0은 첫 빌드 때 자동으로 받습니다.

### 저장소에 없어서 따로 구해야 하는 파일

| 파일 | 필요 여부 | 없으면 | 구하는 법 |
| --- | --- | --- | --- |
| `lib/firebase_options.dart` | **필수** | `main.dart`가 import하므로 컴파일 실패 | [4절](#4-firebase-설정-파일-넣기) |
| `android/app/google-services.json` | **필수** | `com.google.gms.google-services` Gradle 플러그인이 빌드 실패 | [4절](#4-firebase-설정-파일-넣기) |
| `ios/Runner/GoogleService-Info.plist` | 불필요 | Android 테스트에는 영향 없음 | |
| `android/key.properties`, `*.jks` | 불필요 | release 빌드도 debug 키로 서명됨 (`android/app/build.gradle.kts`) | 스토어 업로드할 때만 필요 |
| `android/local.properties` | 자동 생성 | | `flutter pub get` 때 생성 |
| `*.g.dart` | 자동 생성 | 분석·빌드 에러 | `build_runner` ([5절](#5-의존성-설치-코드-생성-pc에서-먼저-검사)) |
| `libisar.so` / `isar.dll` | 불필요 | Isar 저장소 테스트만 실패 | PC에서 Isar 저장소 테스트를 돌릴 때만 필요 (README 참고) |

### 테스트 준비물

- **데이터 전송이 되는** USB-C 케이블 (충전 전용 케이블이면 탭이 인식되지 않음)
- 테스트용 PDF 파일
  - 1~3페이지짜리 PDF (글자와 그림이 있는 것, 위치 확인용)
  - 30페이지 이상 PDF (속도·메모리 확인용)
- PC 사양: RAM 16GB 이상 권장 (`android/gradle.properties`가 Gradle에 `-Xmx8G`를 줌), 디스크 여유 30GB 이상 (Android Studio + SDK + NDK + Flutter + Gradle 캐시)

---

## 2. PC 준비

### 2-1. Windows 개발자 모드 켜기

Flutter 플러그인과 FVM이 심볼릭 링크를 만들기 때문에 필요합니다. 끄면 `Building with plugins requires symlink support` 에러가 납니다.

```powershell
start ms-settings:developers
```

`설정 → 시스템 → 개발자용 → 개발자 모드`를 켭니다.

### 2-2. Git 설치

기본 옵션으로 설치한 뒤:

```powershell
git config --global core.longpaths true
```

줄바꿈은 저장소의 `.gitattributes`가 정하므로 `core.autocrlf`는 따로 바꾸지 않아도 됩니다.

### 2-3. Android Studio 설치

1. 설치 후 첫 실행 마법사에서 `Standard`로 진행 (SDK, Platform-Tools 기본 설치)
2. SDK Manager에서 [위 표](#android-studio-sdk-manager에서-설치할-것)의 항목 설치
3. SDK 경로는 기본값 `C:\Users\<사용자>\AppData\Local\Android\Sdk`

### 2-4. JDK 17 설치

Temurin 17 `.msi` 설치 중 `Set JAVA_HOME variable`을 켭니다. Flutter에 연결하는 것은 Flutter 설치 후 [3절](#3-프로젝트-받기와-flutter-설치)에서 합니다.

### 2-5. FVM 설치

관리자 PowerShell에서 (Chocolatey가 없으면 https://chocolatey.org/install 의 한 줄 명령으로 먼저 설치):

```powershell
choco install fvm
```

Chocolatey를 쓰기 싫으면 https://github.com/btwld/fvm/releases/latest 에서 `windows-x64` zip을 받아 풀고, 그 폴더를 PATH에 추가합니다.

새 PowerShell 창을 열어 확인:

```powershell
fvm --version
```

### 2-6. Samsung USB 드라이버 설치

https://developer.samsung.com/android-usb-driver 에서 받아 설치합니다. 탭을 연결하기 전에 설치해 두세요.

### 2-7. 경로 주의

- 프로젝트는 **영문, 공백 없는 경로**에 둡니다. 예: `C:\dev\clustudy`. Android Gradle 플러그인은 Windows에서 한글 경로를 거부합니다.
- Windows 사용자 이름이 한글이라 pub 캐시나 Gradle 캐시 경로 때문에 빌드가 실패하면, 시스템 환경 변수에 `PUB_CACHE=C:\dev\pub-cache`, `GRADLE_USER_HOME=C:\dev\gradle-home`을 추가하고 새 터미널에서 다시 시도합니다.

---

## 3. 프로젝트 받기와 Flutter 설치

```powershell
mkdir C:\dev
cd C:\dev
git clone https://github.com/tryCatchPing/clustudy
cd clustudy

fvm install 3.32.5      # .fvmrc 버전. 처음엔 수 분 걸림
fvm use 3.32.5          # .fvm/ 링크 생성 (VS Code 설정이 이 경로를 씀)
fvm flutter --version   # Flutter 3.32.5, Dart 3.8.x 인지 확인
```

`fvm use`가 `.fvmrc`나 `.vscode/settings.json`을 고쳤다면 내용 차이가 없는지 `git diff`로 보고 되돌립니다.

```powershell
git status
git checkout -- .fvmrc .vscode/settings.json   # 바뀐 경우에만
```

JDK 17을 Flutter에 연결하고 Android 라이선스에 동의합니다.

```powershell
# 경로는 실제 설치된 폴더명으로 (예: jdk-17.0.13.11-hotspot)
fvm flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"

fvm flutter doctor --android-licenses   # 모두 y
fvm flutter doctor -v
```

`flutter doctor`에서 확인할 것:

| 항목 | 기대 결과 |
| --- | --- |
| Flutter | `Channel stable, 3.32.5` |
| Android toolchain | ✓, `Java version OpenJDK ... 17` |
| Android Studio | ✓ |
| Visual Studio, Chrome | ✗여도 괜찮음 (Windows 데스크톱, 웹 빌드용) |

(선택) 다른 도구가 `flutter`, `dart` 명령을 직접 찾을 수 있게 전역 버전도 지정해 둘 수 있습니다. [4절](#4-firebase-설정-파일-넣기) 방법 B를 쓸 때 필요합니다.

```powershell
fvm global 3.32.5   # 출력되는 ...\fvm\default\bin 경로를 PATH에 추가
```

---

## 4. Firebase 설정 파일 넣기

두 파일은 `.gitignore`에 있어 clone으로 받아지지 않습니다. GitHub Actions secret에도 들어 있지만 secret은 다시 읽을 수 없으므로 아래 둘 중 하나로 구합니다. **둘 다 커밋하거나 공개된 곳에 올리지 마세요.**

### 방법 A (권장): 기존 개발 PC에서 복사

기존 PC의 저장소에서 아래 두 파일을 그대로 가져와 같은 위치에 둡니다.

```
lib/firebase_options.dart
android/app/google-services.json
```

### 방법 B: Firebase 콘솔과 FlutterFire CLI로 새로 생성

Firebase 프로젝트 `clustudy-2baa4`에 접근 권한이 있는 계정이 필요합니다.

1. **google-services.json**
   Firebase 콘솔 → `clustudy-2baa4` → ⚙ `프로젝트 설정` → `일반` → `내 앱`에서 Android 앱(`com.clustudy.clustudy`) 선택 → `google-services.json` 다운로드 → `android/app/`에 저장
2. **firebase_options.dart**

   ```powershell
   # Node.js LTS 설치 후
   npm install -g firebase-tools
   firebase login

   fvm dart pub global activate flutterfire_cli
   # %LOCALAPPDATA%\Pub\Cache\bin 을 PATH에 추가 (PUB_CACHE를 바꿨다면 그 아래 bin)

   flutterfire configure --project=clustudy-2baa4
   ```

   플랫폼 선택에서는 지금 `firebase.json`과 같게 android, ios, macos, web, windows를 고릅니다. `lib/firebase_options.dart`가 생성되고 `google-services.json`도 다시 받아집니다.
3. `flutterfire configure`가 추적 중인 파일을 고칠 수 있습니다. 확인 후 의도하지 않은 변경은 되돌립니다.

   ```powershell
   git status
   git diff firebase.json android/
   git checkout -- firebase.json android/   # 필요한 경우에만. 무시된 google-services.json은 지워지지 않음
   ```

### 확인

```powershell
Test-Path lib\firebase_options.dart                                       # True
Select-String -Path android\app\google-services.json -Pattern com.clustudy.clustudy   # 한 줄 이상 나와야 함
```

패키지 이름이 `com.clustudy.clustudy`가 아니면 빌드가 실패합니다(CI도 같은 검사를 함).

> 이 설정은 실제 운영 Firebase 프로젝트를 가리킵니다. 테스트 중 실행, 크래시도 Analytics와 Crashlytics에 기록됩니다.

---

## 5. 의존성 설치, 코드 생성, PC에서 먼저 검사

```powershell
fvm flutter pub get --enforce-lockfile
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter analyze --no-fatal-infos
```

- `--enforce-lockfile`은 `pubspec.lock`과 다르게 풀리면 바꾸지 않고 실패합니다. CI와 같은 방식입니다.
- 필기 엔진 `scribble`은 포크(`ehdnd/scribble`)의 커밋 `2d3e0c8`로 고정되어 있습니다. #59의 핵심 수정(`renderSketchOffscreen`이 `pixelRatio`만큼 캔버스를 확대)이 이 커밋에 들어 있습니다. 아래로 확인할 수 있습니다.

  ```powershell
  Select-String -Path pubspec.lock -Pattern 2d3e0c818ea5c750dc4e7cbaccd116b15162d53f
  ```

- `analyze` 결과에 error, warning이 없어야 합니다.

PDF 내보내기 단위 테스트를 PC에서 먼저 돌려 봅니다. Isar 네이티브 라이브러리 없이 돌아갑니다.

```powershell
fvm flutter test test/shared/services/pdf_export_mvp_service_test.dart
```

4개 모두 통과해야 합니다.

- `exports single blank page into target directory`
- `merges every page into one PDF with each page at canvas size`
- `throws when pdf background path missing`
- `offscreen render scales strokes and background with pixelRatio` (#59 회귀 테스트. 수정 전 scribble이면 실패)

여기까지 통과하면 PC 쪽 준비는 끝입니다.

---

## 6. 갤럭시 탭 준비와 연결

### 6-1. 개발자 옵션 켜기

`설정 → 태블릿 정보 → 소프트웨어 정보 → 빌드번호`를 7번 누릅니다. PIN을 입력하면 `설정` 맨 아래에 `개발자 옵션`이 생깁니다.

### 6-2. 자동 차단 끄기 (One UI 6 이상)

`설정 → 보안 및 개인정보 보호 → 자동 차단`을 끕니다. 켜져 있으면 USB 명령이 막혀 `USB 디버깅`이 회색으로 비활성화되거나 저절로 꺼집니다. 테스트가 끝나면 다시 켜는 것을 권장합니다.

### 6-3. USB 디버깅 켜기

`설정 → 개발자 옵션 → USB 디버깅`을 켭니다. 자동 차단을 끈 뒤 USB 디버깅이 꺼져 있을 수 있으니 다시 확인하세요.

선택: 같은 화면의 `화면 켜짐 상태 유지`를 켜면 충전 중 화면이 꺼지지 않아 편합니다.

### 6-4. 스토어 버전 Clustudy 확인 (중요)

탭에 Google Play에서 받은 Clustudy가 설치되어 있으면, **서명 키가 달라서 개발 빌드로 덮어쓸 수 없습니다.** `flutter run`은 설치에 실패하면 기존 앱을 **자동으로 삭제한 뒤** 다시 설치하므로, 스토어 버전의 노트 데이터가 모두 사라집니다.

- 지켜야 할 노트가 있으면 먼저 PDF로 내보내 두거나 테스트 전용 기기를 쓰세요.
- 직접 지우려면: `adb uninstall com.clustudy.clustudy`
- 테스트가 끝난 뒤 스토어 버전을 다시 쓰려면 개발 빌드를 지우고 Play에서 다시 설치해야 합니다.

### 6-5. USB 연결과 승인

1. 케이블로 PC와 연결합니다.
2. 탭에 `USB 디버깅을 허용하시겠습니까?`가 뜨면 `이 컴퓨터에서 항상 허용`을 체크하고 `허용`을 누릅니다.
3. 창이 안 뜨면: 알림창에서 USB 모드를 `파일 전송`으로 바꾸거나, `개발자 옵션 → USB 디버깅 권한 승인 취소` 후 케이블을 다시 꽂습니다.

### 6-6. 연결 확인

`adb`는 `%LOCALAPPDATA%\Android\Sdk\platform-tools`에 있습니다. PATH에 없다면 현재 창에만 추가합니다.

```powershell
$env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"

adb devices
# List of devices attached
# R54XXXXXXXX     device          ← "device"면 정상, "unauthorized"면 탭에서 승인 필요

fvm flutter devices
# SM X... (mobile) • R54XXXXXXXX • android-arm64 • Android 14 (API 34)
```

### 6-7. 테스트용 PDF 옮기기

파일 탐색기에서 탭의 `Download` 폴더로 끌어 놓거나:

```powershell
adb push .\sample-3p.pdf /sdcard/Download/
adb push .\sample-30p.pdf /sdcard/Download/
```

### (선택) 무선 디버깅

펜으로 테스트할 때 케이블이 거슬리면 무선으로 연결할 수 있습니다. PC와 탭이 같은 Wi-Fi에 있어야 합니다.

1. `개발자 옵션 → 무선 디버깅` 켜기 → `페어링 코드로 기기 페어링`
2. `adb pair <IP>:<페어링 포트>` 후 6자리 코드 입력
3. 무선 디버깅 첫 화면에 보이는 `IP 주소 및 포트`로 `adb connect <IP>:<포트>` (페어링 포트와 다름)

---

## 7. 앱 설치와 실행

첫 빌드는 Gradle, NDK 등을 받느라 10~20분 이상 걸릴 수 있습니다.

| 목적 | 명령 | 비고 |
| --- | --- | --- |
| 기능 확인, 로그 보기 | `fvm flutter run -d <기기ID>` | debug 모드. 렌더링이 느리므로 **속도는 여기서 판단하지 않음** |
| 속도, 메모리 확인 | `fvm flutter run --profile -d <기기ID>` | 성능 측정용 모드. 로그도 나옴 |
| PC 없이 계속 쓸 APK | `fvm flutter build apk --release` 후 `adb install -r build\app\outputs\flutter-apk\app-release.apk` | debug 키로 서명됨 |

`<기기ID>`는 `fvm flutter devices`에 나온 ID(예: `R54XXXXXXXX`)입니다. 기기가 하나만 연결되어 있으면 `-d`를 생략해도 됩니다.

`flutter run` 중 터미널에서 `r`은 hot reload, `R`은 hot restart, `q`는 종료입니다.

---

## 8. 로그 보기

내보내기 서비스(`lib/shared/services/pdf_export_mvp_service.dart`)는 `[pdf-export-mvp]` 태그로 로그를 남깁니다.

```
[pdf-export-mvp] start note=<noteId> pages=<N>
[pdf-export-mvp] page 1/N id=<pageId>
...
[pdf-export-mvp] success path=.../pdf_exports/<제목>_yyyyMMdd_HHmmss.pdf duration=<ms>ms
[pdf-export-mvp] deleted temp file ...      ← 공유 시트가 닫힌 뒤
```

`flutter run` 중이면 그 터미널에 바로 나옵니다. 따로 보려면:

```powershell
adb logcat -c                                        # 이전 로그 지우기
adb logcat -s flutter | Select-String pdf-export     # 내보내기 로그만
```

`fvm flutter logs`로도 볼 수 있습니다. 실패하면 시트 아래에 빨간 에러 문구가 나오고, 같은 내용과 스택은 터미널에 나옵니다.

---

## 9. #59 테스트 시나리오

### 무엇이 바뀌었나

- **수정 전**: 내보낸 PDF에서 페이지 크기는 맞는데 필기(빈 페이지는 흰 배경까지)가 페이지 **왼쪽 위 1/4 영역에 작게** 몰려 나옴
- **수정 후**: 필기와 배경이 페이지 전체에 화면과 같은 위치로 나와야 함
- PDF 배경 페이지는 배경 JPEG 원본 위에 투명 필기 PNG를 겹쳐 넣음
- 렌더링 배율 4x → 2x. 시트의 화질 문구가 `고화질 (2x)`로 바뀜

### 내보내는 법

노트 열기 → 상단 툴바 `페이지 관리` 아이콘 → `페이지 관리` 화면 오른쪽 위 내보내기 아이콘(`PDF 내보내기`) → 시트에서 `PDF 공유하기` → 공유 시트

- 앱은 임시 폴더에만 PDF를 만들고 **공유 시트가 닫히면 지웁니다.** 결과를 보려면 공유 시트에서 Google Drive, Quick Share(PC로 전송), 메일, 메신저 등 파일을 받을 수 있는 곳으로 보내세요.
- 위치 오차는 PC의 PDF 뷰어에서 크게 확대해 보는 것이 정확합니다.

### 체크리스트

| # | 시나리오 | 준비 | 확인할 것 |
| --- | --- | --- | --- |
| 1 | 빈 노트 1페이지 | 네 모서리와 가운데에 X 표시, 짧은 글씨 | 표시가 PDF의 네 모서리와 가운데에 화면과 같은 위치로 나오는지. 흰 배경이 페이지 전체를 덮는지. **좌상단 1/4에 몰리면 실패** |
| 2 | 빈 노트 여러 페이지 | 3페이지 이상, 페이지마다 번호 쓰기, 페이지 관리에서 순서 바꾸기 | PDF 페이지 수와 순서가 앱과 같은지 |
| 3 | 필기 없는 페이지가 섞인 노트 | 1, 3페이지만 필기 | 2페이지가 흰 빈 페이지로 들어가는지 |
| 4 | PDF 노트 (1~3p) | 노트 목록에서 `PDF 불러오기` → `Download`의 `sample-3p.pdf`. 모서리와 원본 글자 위에 표시 | 배경이 원본 화질로 페이지 전체를 채우는지. 필기가 배경 글자와 같은 자리에 겹치는지 |
| 5 | PDF 배경 위 하이라이터 | 4번 노트에서 하이라이터로 배경 글자 위를 칠함 | 배경 글자가 비쳐 보이는지. 화면보다 지나치게 진하거나 흐리지 않은지 (#59에서 실기기 확인 필요로 남긴 항목) |
| 6 | 페이지 많은 PDF 노트 | `sample-30p.pdf`로 노트 생성, 몇 페이지에 필기. **`--profile` 모드**로 실행 | 로그 `duration`, 앱이 멈추거나 꺼지지 않는지, PDF 파일 크기 (#59에서 실기기 확인 필요로 남긴 항목) |
| 7 | 필압 시뮬레이션 켜기/끄기 | 설정을 바꾸고 같은 노트를 각각 내보내기 | 획 굵기가 화면에서 보던 것과 비슷한지 |
| 8 | 링크가 있는 페이지 | 필기 위에 링크 영역 만들기 | 링크 사각형은 PDF에 **나오지 않는 것이 정상** (MVP 범위) |
| 9 | 공유 취소 | 공유 시트를 뒤로가기로 닫기 | 앱이 정상인지, 다시 내보내기가 되는지, 로그에 `deleted temp file`이 찍히는지 |
| 10 | 내보내는 중 뒤로가기 | `PDF 공유하기` 직후 뒤로가기 | 진행 중에는 시트가 닫히지 않는지 |
| 11 | 특수문자 제목 | 노트 제목에 `/ : * ?` 포함 | 파일명이 `_`로 바뀌고 `_yyyyMMdd_HHmmss.pdf`가 붙는지 |
| 12 | 화질 문구 | 시트 열기 | `고화질 (2x)`로 표시되는지 |

### 결과 기록 양식

PR이나 이슈에 붙여 넣을 수 있게 아래 형식으로 남기면 비교하기 쉽습니다.

```markdown
- 기기: Galaxy Tab S? (SM-X???), One UI ?, Android ?
- 빌드: 831287c, --profile
| # | 결과 | 페이지 수 | duration(ms) | 파일 크기 | 메모 |
| --- | --- | --- | --- | --- | --- |
| 1 | 통과 | 1 | | | |
| 6 | | 30 | | | |
```

---

## 10. 자주 막히는 문제

| 증상 | 원인과 해결 |
| --- | --- |
| `adb devices`에 아무것도 없음 | 충전 전용 케이블, Samsung USB 드라이버 미설치, 자동 차단 켜짐, USB 디버깅 꺼짐 중 하나. 케이블과 포트를 바꾸고 [6절](#6-갤럭시-탭-준비와-연결)을 다시 확인 |
| `unauthorized` | 탭 화면의 승인 창에서 허용. 안 뜨면 `USB 디버깅 권한 승인 취소` 후 재연결 |
| USB 디버깅이 회색이거나 저절로 꺼짐 | 자동 차단 끄기 ([6-2](#6-2-자동-차단-끄기-one-ui-6-이상)) |
| `Building with plugins requires symlink support` | Windows 개발자 모드 켜기 ([2-1](#2-1-windows-개발자-모드-켜기)) |
| `Unsupported class file major version ...`, Gradle이 Java 버전 에러 | JDK가 너무 새로움. `fvm flutter config --jdk-dir`로 JDK 17 지정 |
| `License for package ... not accepted`, NDK `29.0.14206865`를 못 찾음 | `fvm flutter doctor --android-licenses`, SDK Manager에서 NDK 해당 버전 설치 |
| `flutter.sdk not set in local.properties` | 프로젝트 폴더에서 `fvm flutter pub get`을 한 번 실행 |
| `File google-services.json is missing` | [4절](#4-firebase-설정-파일-넣기) |
| `firebase_options.dart`를 찾을 수 없음, `Undefined name 'DefaultFirebaseOptions'` | `lib/firebase_options.dart` 없음. [4절](#4-firebase-설정-파일-넣기) |
| `Target of URI hasn't been generated`, `*.g.dart` 관련 에러 | `fvm dart run build_runner build --delete-conflicting-outputs` |
| `pub get` 또는 `build_runner`가 `perfect_freehand` 등 scribble 하위 의존성을 못 찾음 | pub 캐시의 git 사본이 오래됨. `Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Pub\Cache\git"` 후 `fvm flutter pub get --enforce-lockfile` (CI도 같은 처리를 함) |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | 스토어 버전이 설치되어 있음. [6-4](#6-4-스토어-버전-clustudy-확인-중요) 확인 후 `adb uninstall com.clustudy.clustudy` |
| 빌드 중 PC가 멈추거나 Gradle 메모리 부족 | `android/gradle.properties`의 `-Xmx8G`. RAM 8GB PC면 로컬에서만 `-Xmx4G`로 낮추고 커밋하지 않음 |
| 내보내기 시트에 `페이지 N의 필기 정보가 없습니다.` | 페이지 필기 상태를 못 찾은 경우. 노트를 다시 열고 재시도, 로그와 재현 순서를 기록 |
| 내보내기 시트에 `배경 파일을 찾을 수 없습니다` | PDF 노트의 배경 이미지가 지워진 경우. 노트를 열어 복구 옵션(다시 렌더링)을 실행한 뒤 재시도 |

---

## macOS에서 할 때 다른 점

| 항목 | macOS |
| --- | --- |
| Git | `xcode-select --install` |
| FVM | `brew tap btwld/fvm && brew install btwld/fvm/fvm` 또는 `curl -fsSL https://fvm.app/install.sh \| bash` |
| JDK 17 | `brew install --cask temurin@17`, 경로는 `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home` |
| Samsung USB 드라이버, 개발자 모드 | 필요 없음 |
| adb 경로 | `~/Library/Android/sdk/platform-tools` |
| pub 캐시 git 사본 | `~/.pub-cache/git` |
| 로그 필터 | `adb logcat -s flutter \| grep pdf-export` |
| 파일 확인 | `test -f lib/firebase_options.dart && grep -c com.clustudy.clustudy android/app/google-services.json` |
| 탭 파일 옮기기 | macOS는 파일 탐색기로 MTP가 안 되므로 `adb push` 사용 |
