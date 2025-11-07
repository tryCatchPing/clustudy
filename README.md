# Clustudy

## 정식 출시

<div align="center">
  <a href="https://play.google.com/store/apps/details?id=com.clustudy.clustudy&pcampaignid=web_share&referrer=utm_source%3Dgithub%26utm_medium%3Dreadme%26utm_campaign%3Dproduction">
    <img alt="Get it on Google Play" src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" height="80">
  </a>
</div>

## Project Overview

Clustudy는 손필기 노트에 링크를 추가해 지식 네트워크를 만들어 나가는 앱입니다.

- 배경: 분산된 필기 자료로 누적 학습이 어려운 문제를 해결, 지식 정리를 넘어 지식간의 관계를 탐색
- 목표: 지식 정리에 있어 맥락을 유지한 채 필기 및 복습을 반복, 과정속에서 새로운 지식간의 연결을 발견하고 정리

## Problem & Solution

- **문제 정의**: 폴더 기반 노트 저장 방식의 한계, 지식 연결 부족, 재탐색 비용 증가.
- **핵심 솔루션**: 손필기 주석에 링크/백링크를 제공하고 그래프 뷰로 관계를 시각화.
- **가치 제안**: 기존 패드 노트 사용자도 쉽게 링크 작성, 빠른 맥락 파악.

## Target Users

- 수능·고시 등 방대한 지식을 누적 학습해야 하는 학생.
- 기존 필기 노트 앱 사용자 중 지식 연결 니즈가 있는 학습자.
- 손글씨와 링크 혼합을 원하는 사용자.

## Key Features

| 기능             | 요약 설명                                         | 참고 화면/링크                  |
| ---------------- | ------------------------------------------------- | ------------------------------- |
| 손필기 Canvas    | `scribble` 포크 기반 필압 지원 캔버스.            | `docs/screenshots/canvas.png`   |
| PDF 주석         | PDF 위에 자유 필기, 페이지별 레이어.              | `docs/screenshots/pdf.png`      |
| 링크 & 백링크    | 노트 간 링크/백링크 생성.                         | `docs/screenshots/backlink.png` |
| 그래프 뷰        | 지식 네트워크 시각화.                             | `docs/screenshots/graph.png`    |
| 로컬 DB & 동기화 | `isar` 기반 자동 저장, 추후 클라우드 동기화 계획. | TBD                             |

## DEMO

- 시연 영상: `docs/demo/demo.mp4` (TBD)
- 주요 시나리오: 노트 작성 → 링크 연결 → 백링크 및 그래프 확인.

## Architecture & Tech Stack

- **Front-end**: Flutter 3.32.5 + Riverpod → 단일 코드베이스로 iOS/Android 태블릿을 아우르고, 상태를 예측 가능하게 유지.
- **Routing**: GoRouter → 필기, 그래프, 설정 등 다중 화면 전환을 선언형으로 구성.
- **손필기 엔진**: 포크한 `scribble` → 필압/포인터 정책 커스터마이즈로 패드 필기 UX 강화.
- **문서 처리**: `pdfx` + `pdf` → PDF 위 오버레이 필기와 향후 오프스크린 내보내기 파이프라인 구축에 활용.
- **저장소**: `isar` → 빠른 로컬 인덱싱과 오프라인 우선 전략, 이후 동기화 계층 확장 기반.
- **그래프 시각화**: `flutter_graph_view` → 노트 간 링크 네트워크를 즉시 시각화.
- **분석**: Firebase Analytics → 학습 플로우 행동 데이터를 수집해 UX 개선 근거 확보, 성과지표 측정.
- **레이어링**: Presentation → Services → Repository → Storage.
- **디자인 시스템**: `lib/design_system/**` 내 공통 컴포넌트와 토큰 사용.

## Repository Structure (요약)

```
lib/
 ├─ design_system/   # 토큰, 공통 위젯, 데모 라우트
 ├─ features/
 │   ├─ canvas/      # 손필기 도구, 레이아웃
 │   ├─ notes/       # 노트 CRUD, 백링크 로직
 │   ├─ vaults/      # 자료 보관 및 검색
 │   └─ home/        # 대시보드 및 그래프 뷰
 ├─ shared/          # 서비스, 저장소 인터페이스, 위젯 유틸
docs/                # 디자인·서비스·PDF 런북
test/                # lib 구조 반영 테스트
```

## Getting Started

1. **필수 요구사항**
   - Flutter SDK 3.32.5 (FVM 권장), Dart 3.8.1+
   - Android Studio/Xcode, VS Code 플러그인
2. **설치**
   ```bash
   git clone https://github.com/tryCatchPing/clustudy
   cd clustudy
   dart pub global activate fvm
   fvm install 3.32.5
   fvm use 3.32.5
   fvm flutter pub get
   ```
3. **Firebase 설정** (필수)
   ```bash
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure
   ```
   iOS/macOS 개발 시 추가:
   ```bash
   cd ios && pod install && cd ..
   cd macos && pod install && cd ..
   ```
4. **실행 & 테스트**
   ```bash
   fvm flutter run
   fvm flutter analyze
   fvm flutter test
   ```

## Development Workflow

- 브랜치 전략: `dev` ← feature branches (`feat/backlink`, `fix/pdf-export` 등).
- 커밋 규칙: Conventional Commits (`feat(canvas): ...`).
- 코드 생성: `fvm dart run build_runner build --delete-conflicting-outputs`.
- 린트/포맷: `fvm flutter analyze`, `fvm dart format .`.
- 참고 문서: 상세 디자인 교체 및 서비스→DB 이전 흐름은 `docs/design_cleanup_runbook.md`, `docs/service_to_db.md`에서 추적.

## Team & Contributions

| 역할            | 이름   | 주요 기여                                                                                                      |
| --------------- | ------ | -------------------------------------------------------------------------------------------------------------- |
| PM & 전체 개발  | 장태웅 | 기획 총괄, Canvas/백링크/그래프/PDF/파일시스템 기능 구현, Isar 모델 설계/구현, Analytics 파이프라인, 배포 준비 |
| 디자인 & 브랜드 | 김유라 | 사용자 여정 설계, 디자인 시스템 제작, 핵심 화면/아이콘 제작, 마케팅 에셋, QA 협업                              |
| 개발            | 김지담 | 링크/DB 구조 연구 및 초기 프로토타입                                                                           |
| UI              | 김효민 | 초기 기획/디자인 프로토타입                                                                                    |

## Timeline & Outcomes

- 2025.06~07: 문제 정의, 페르소나 연구, UX 프로토타입 제작.
- 2025.08~09: Flutter MVP 구현, 캔버스/노트 링크/그래프 기능 완성.
- 2025.10~11: 세부 기능 구현, 테스트 유저 온보딩, 마케팅 준비.
- 성과: 공모전 최종평가 진출, 출시 준비 진행 중.

## Learnings & Next Steps

- 학습: 오프스크린 PDF 렌더링 파이프라인 구축, 손필기 백링크 UX 실험.
- 다음 단계: 클라우드 동기화, 다중 기기 지원, PDF 내보내기 재작성, DB/Service 레이어 최적화.
- 문서화: 전체 아키텍처/폴더 구조/데이터 흐름 문서화를 진행 중.

## References & License

- 기획 문서 및 기술 계획: `docs/` 디렉토리 파일 확인.
- 라이선스: MIT License (`LICENSE` 파일 참조).
- 사용한 외부 리소스:
  - Pretendard Variable (SIL Open Font License 1.1) – https://github.com/orioncactus/pretendard
  - Play (SIL Open Font License 1.1) – https://fonts.google.com/specimen/Play
  - 앱 아이콘 및 SVG는 팀(김유라) 자체 제작.
