# AI Generated Components

이 폴더는 AI 도구(Claude, Figma Dev Mode 등)로 생성된 원본 코드를 보관합니다.

## 폴더 구조

### `figma_exports/`
- Figma에서 직접 내보낸 코드
- 디자인 토큰, SVG, 이미지 등

### `raw_components/`
- AI가 생성한 Flutter 컴포넌트들
- **주의**: 직접 사용하지 말고 참조용으로만 사용

### `pages/`
- AI가 생성한 페이지 레이아웃
- 실제 앱에서 사용할 페이지의 초기 버전

## 사용 규칙

1. **이 폴더의 코드는 직접 사용하지 마세요**
2. 참조용으로만 사용하고, 실제 컴포넌트는 `../components/`에서 정제해서 만드세요
3. AI 생성 코드는 다음 단계를 거쳐야 합니다:
   - `ai_generated/` → 검토 → `components/` → 실제 사용

## 현재 상태

### Figma Toolbar Design (2025-08-06)
- ✅ 색상 토큰 추출 완료 (`../tokens/app_colors.dart`에 추가)
- ✅ 컴포넌트 생성 완료 (`raw_components/`에 보관)
- ⏳ 정제된 컴포넌트는 아직 미생성 (향후 `../components/`에서 작업)

### 생성된 컴포넌트들
- `figma_toolbar_design.dart`: 원본 Figma 변환 코드
- `toolbar_button.dart`: 기본 툴바 버튼
- `color_circle.dart`: 색상 선택 원형 버튼  
- `toolbar_section.dart`: 세로 툴바 섹션
- `color_palette.dart`: 펜 색상 팔레트
- `tool_selector.dart`: 펜 타입/굵기 선택기
- `action_controls.dart`: 실행취소/재실행 컨트롤
- `navigation_section.dart`: 노트 네비게이션 및 메뉴
- `canvas_toolbar.dart`: 완전한 캔버스 툴바 조합