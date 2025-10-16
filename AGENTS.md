# 저장소 가이드라인

## 리포 개요

- 핵심 기능 (`canvas/`, `notes/`, `vaults/`, `home/`)은 기능 개발이 완료되었으며, 현재는 마감 품질과 UX 개선에 집중하고 있습니다.
- UI는 `lib/design_system/**` 에셋을 활용해 새로운 디자인 시스템으로 교체 중이며, 남은 교체 작업은 `docs/design_cleanup_runbook.md`와 `docs/design_flow.md`를 기준으로 진행합니다.
- 서비스 계층에서 데이터베이스 계층으로의 이관과 PDF 내보내기 재구축 계획은 각각 `docs/service_to_db.md`와 `docs/pdf_export_offscreen_scribble.md`에 정리되어 있습니다.

## 프로젝트 구조 및 모듈

- `lib/design_system/`: 토큰, 컴포넌트, 데모 화면, 라우팅 엔트리, 스토리/데모 스캐폴드.
- `lib/features/`: 실서비스 기능 코드(`canvas/`, `notes/`, `vaults/`, `home/`)가 데이터, 모델, 페이지, 프로바이더, 라우팅, 위젯 단위로 분리되어 있습니다.
- `lib/shared/`: 공통 서비스, 저장소(인터페이스 + 메모리 구현), 다이얼로그, 매퍼, 엔티티, 위젯, 상수를 포함합니다.
- `test/`: `lib/` 구조를 그대로 반영한 `*_test.dart` 파일이 위치합니다.
- `docs/`: 정리된 런북과 심화 문서(클린업 워크플로, 서비스→DB 계획, PDF 내보내기, 상태 요약 등).
- 플랫폼: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`.
- 설정: `pubspec.yaml`, `analysis_options.yaml`, `.fvmrc`(FVM Flutter 3.32.5).

## 아키텍처 개요

- 클린 레이어링: Presentation (ConsumerWidget + Riverpod providers) -> Services/Notifiers -> Data (Repository pattern).
- 상태: Riverpod providers(필요 시 family)를 사용하며, `createState` 내부에 비즈니스 로직을 넣지 않습니다.
- 데이터: 모든 접근은 저장소 인터페이스를 통해서만 수행합니다. 현재는 메모리 구현을 사용하며, `service_to_db` 계획에 따라 Isar 구현을 확장합니다.
- PDF/Canvas: Apple Pencil을 지원하는 `scribble` 포크와 `pdfx`를 사용하고, `scaleFactor`는 1.0으로 고정되어 있습니다. 오프스크린 기반 내보내기 파이프라인을 재구축 중입니다.
- 디자인 시스템: `lib/design_system/**`에 참조 구현, 토큰, 데모 라우트가 모여 있으며, 실제 기능 플로우는 `lib/features/**`에서 유지됩니다.

## 현재 집중 영역 및 백로그

- Isar API가 준비되는 대로 고유 이름 할당, 캐스케이드 헬퍼, 대량 작업 등을 포함해 서비스 계층의 vault/note 흐름을 DB 계층으로 이전합니다.
- 오프스크린 렌더러 계획을 기반으로 PDF 내보내기를 처음부터 재구축하고, 로깅 및 iPad 공유 이슈를 해결합니다.
- 라쏘/획 선택, 스트로크 그룹화 등 캔버스 도구를 확장합니다.
- `docs/design_cleanup_runbook.md` 지침에 맞춰 디자인 시스템 레이아웃으로 UI를 계속 교체하고, 관련 변경은 작은 커밋으로 분리합니다.

## 빌드, 테스트, 개발 명령어

- 의존성 설치: `fvm flutter pub get`
- 앱 실행: `fvm flutter run`
- 정적 분석: `fvm flutter analyze`
- 포맷팅: `fvm dart format .`
- 테스트 실행: `fvm flutter test` (필요 시 `--coverage`)
- 코드 생성(Riverpod, build_runner):
  - 일회성: `fvm dart run build_runner build --delete-conflicting-outputs`
  - 감시 모드: `fvm dart run build_runner watch --delete-conflicting-outputs`
- iOS 의존성(macOS): `cd ios && pod install && cd ..`

## 코딩 스타일 및 네이밍

- `analysis_options.yaml`에서 정의한 Flutter lint + 프로젝트 규칙을 따릅니다.
- 들여쓰기 2칸, 권장 줄 길이 ~80자.
- 작은따옴표를 사용하고, 기본적으로 `const`/`final`을 선호하며, 프로덕션 코드에서 `print`는 피합니다.
- 공개 멤버와 주요 enum에는 `///` 문서 주석을 추가합니다.
- 임포트는 `directives_ordering` 규칙에 맞춰 정렬하며, 분석기가 제안하는 정리를 따릅니다.
- 파일은 `snake_case.dart`, 클래스/타입은 UpperCamelCase, 변수/메서드는 lowerCamelCase로 이름을 짓습니다.

## 테스트 가이드라인

- 테스트 프레임워크: `flutter_test`.
- 위치: `lib/` 구조를 반영해 `test/`에 동일한 경로, 동일한 이름의 `*_test.dart`를 둡니다.
- 범위: 프로바이더/서비스 단위 테스트와 UI 플로우에 대한 위젯 테스트를 추가하고, 모든 기능/버그 수정에는 최소 한 개의 테스트를 동반합니다.
- 실행: `fvm flutter analyze`와 `fvm flutter test`를 통과한 뒤 변경을 푸시합니다.

## 커밋 및 PR 가이드라인

- 커밋 스타일: Conventional Commits (예: `feat(pdf): export annotations`, `fix(canvas): maintain selection`, `chore(docs): update README`).
- 브랜치 전략: `dev`에서 기능 브랜치를 분기하고, PR은 `dev`로 보냅니다.
- PR 체크리스트:
  - 명확한 제목과 범위를 작성하고, 이슈/태스크 ID가 있다면 연결합니다.
  - 변경 내용, 배경, 리스크를 설명하고, UI 변경 시 스크린샷을 첨부합니다.
  - `pub get`, `analyze`, `test` 실행과 기본 앱 빌드/실행을 확인합니다.

## 보안 및 구성 팁

- FVM 사용: `3.32.5`가 활성화되어 있는지 확인합니다(`fvm list`, `.fvmrc`). VS Code에서는 `"dart.flutterSdkPath": ".fvm/flutter_sdk"`로 설정합니다.
- 비밀 값이나 로컬 빌드 산출물을 커밋하지 않습니다. 필요한 경우 생성 파일은 허용하되, 가능한 한 위의 코드 생성 명령을 활용합니다.

## 작업 요청 프로세스

### 기능 구현 요청 대응

- 사용자 요구를 정리해 목표를 명확히 하고, 해당 목표를 달성하기 위해 필요한 하위 기능과 데이터를 도출합니다.
- 이미 구현된 모듈·서비스·상태 중 재사용 가능한 요소를 식별하고, 추가 설계나 정책 결정이 필요한 지점을 정리합니다.
- 예상되는 코드 수정 범위와 영향을 받는 파일, 새로 드러나는 입출력 흐름을 글로 정리해 사용자에게 공유합니다(코드 스니펫은 포함하지 않음).
- 기능이 전체 맥락에서 어떻게 동작할지 플로우를 설명하고, 구현 단계·검증 계획과 함께 사용자 컨펌을 받은 뒤 작업을 시작합니다.

### 오류 수정 요청 대응

- 제공된 로그·맥락으로 문제가 발생했을 환경과 조건을 가정하고, 동일 조건에서 재현을 시도합니다.
- 재현에 실패하면 환경 차이·누락된 정보 등 추정 원인을 정리해 추가 자료를 요청합니다.
- 재현/분석 결과로 파악한 근본 원인과 해결 방안을 텍스트로 설명하고(필요 시 명세나 정책 변경 제안 포함) 사용자 컨펌을 받습니다.
- 합의 후 수정을 진행하며, 기본적으로 `fvm flutter analyze`를 실행하고 추가 테스트 필요 여부는 사용자에게 확인합니다.

### 예외 및 긴급 상황

- 원인이 명확하거나 동일 문제가 반복 확인된 경우, 위 과정의 핵심 요약을 공유한 뒤 바로 수정에 착수할 수 있습니다.
- 시간 압박이 있는 경우에도 목표·영향·검증 계획을 짧게 문서화해 공유한 뒤 작업을 시작합니다.

### 대규모 코드 수정이나 기능 변경 수정 이후

- 위 상황에서는 `AGENTS.md` 파일을 수정해야합니다.
