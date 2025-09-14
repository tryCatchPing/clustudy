### 에러/메시지 규격과 UX 보강 정책 (초기 릴리스)

본 문서는 에러 표출을 일원화하고, 사용자 경험(UX)을 일관되게 개선하기 위한 정책과 구현 계획을 정의합니다. 구현 세부는 후속 작업에서 이 가이드를 기준으로 적용합니다.

---

### 목표

- **일관성**: 동일한 유형의 오류에 동일한 톤/색상/형식으로 안내.
- **가독성**: 사용자가 즉시 다음 액션을 이해할 수 있는 간결한 메시지.
- **확장성**: i18n, 추후 Sentry/Crashlytics, 커스텀 예외 타입으로 확장 용이.

---

### 설계 개요

- **AppErrorMapper**: 예외(Object) → 표준 메시지 스펙(AppSnackSpec)으로 매핑.
- **AppSnackBar**: AppSnackSpec → 스낵바/토스트 UI 렌더링(색상/아이콘/지속시간 일관).
- **원칙**: 서비스/레포는 의미 있는 예외만 던짐, UI는 try/catch에서 매퍼로 통일.

---

### 에러 분류 체계

- **Validation(입력/정책 위반)**
  - 예: 이름 길이 초과/공백, 금지 이동(사이클), 타깃 폴더 미존재.
  - 대표 타입: `FormatException`, `ArgumentError`, 일반 `Exception`(메시지 기반).
- **Conflict(충돌/중복)**
  - 예: Vault/폴더/노트 이름 중복, 동일 스코프 내 충돌.
  - 대표 메시지: "already exists" 포함.
- **NotFound(대상 없음)**
  - 예: 노트/폴더/볼트 미존재.
  - 대표 메시지: "not found" 포함.
- **System/Unknown(시스템/알 수 없음)**
  - 예: 파일/스토리지/네트워크/미정의 오류.
  - 개발 모드에서만 상세 제공(원문/스택)

---

### 매핑 규칙(AppErrorMapper → AppSnackSpec)

- 공통 필드

  - `severity`: success | info | warn | error
  - `message`: 사용자 노출 문구(로컬라이즈 대상)
  - `action`: { label, onPressed? } (선택)
  - `duration`: short(2s) | normal(4s) | long(8s) | persistent

- 권장 매핑

  - Validation → warn, normal, 구체 사유 노출(예: "자기/하위 폴더로 이동할 수 없습니다")
  - Conflict → error, normal, "이미 존재하는 이름입니다. 다른 이름을 입력해 주세요"
  - NotFound → warn, normal, "대상을 찾을 수 없습니다. 새로고침 후 다시 시도해 주세요"
  - Unknown → error, persistent, "알 수 없는 오류가 발생했어요. 잠시 후 다시 시도해 주세요"
    - dev 모드: 원문 메시지/힌트 추가 병행

- 색상/아이콘(권장)
  - success=green(✓), info=blue(ℹ), warn=amber(!), error=red(⨯)

---

### 메시지 톤/스타일

- 짧고 직관적으로(최대 1~2문장), 존댓말 유지.
- 사용자가 할 수 있는 **다음 행동**을 우선 명시.
- 내부 용어 대신 사용자가 이해할 용어 사용(예: "폴더", "노트").

---

### i18n 전략(Phase 2)

- 메시지 키 기반으로 전환: `S.of(context).error_duplicate_name` 등.
- 초기(Phase 1)는 한국어 하드코드 → 점진적 대체.

---

### UI 컴포넌트 규격(요약)

- AppSnackBar
  - 입력: AppSnackSpec
  - 기능: 색상/아이콘/지속시간/액션 일관 처리, 중복 스낵바 코알레싱(선택)

예시(의도 설명용):

```dart
try {
  await service.moveNoteWithAutoRename(id, newParentFolderId: picked);
  AppSnackBar.show(context, AppSnackSpec.success('노트를 이동했습니다.'));
} catch (e, st) {
  final spec = AppErrorMapper.toSpec(e, st: st);
  AppSnackBar.show(context, spec);
}
```

---

### UX 보강 지침(에러/메시지 연계)

- **즉시 검증(Inline Validation)**

  - 이름 입력 다이얼로그: 길이 초과/공백/금지문자 시 버튼 비활성 + helperText로 사유 표기.
  - 유효 시에만 확인 버튼 활성화.

- **변경 없음 안내**

  - 동일 위치 선택/무효 작업 시 info 스낵바(짧게): "변경된 내용이 없습니다".

- **자동 접미사 안내(선택)**

  - 충돌 자동 해결 시, 간단 토스트: "자동으로 (2)가 붙었습니다"(설정으로 끌 수 있음).

- **이동 후 흐름**

  - 기본: 현재 뷰 유지 + 성공 스낵바.
  - 옵션 토글: 타깃 폴더로 자동 전환.

- **브레드크럼**

  - 현재 경로를 상단에 표시(루트/상위 이동 맥락 강화).

- **빈 상태/로딩/에러 뷰 표준화**

  - 빈 상태: 권장 행동(폴더 추가/노트 생성) CTA 제공.
  - 로딩: 일관된 인디케이터.
  - 에러: AppErrorMapper 기반 표출.

- **접근성/포커스**
  - 다이얼로그 오픈 시 인풋에 포커스.
  - 에러 발생 시 스크린리더 읽기/포커스 이동 고려.

---

### 구현 계획(Phase 단계)

- Phase 1 (빠른 적용)

  - AppErrorMapper 기본 구현(문자열 heuristic 기반 분류)
  - AppSnackBar 컴포넌트 도입(색/아이콘/지속시간 표준)
  - 주요 화면의 try/catch 교체(노트/폴더 생성·이동·이름 변경·삭제)
  - 이름 입력 다이얼로그에 즉시 검증 적용

- Phase 2 (국문화·정교화)

  - 메시지 키/intl 적용
  - 충돌 자동 접미사 안내 토글(설정) 추가
  - Unknown/System의 Sentry/Crashlytics 연동

- Phase 3 (타입 기반·확장)
  - 커스텀 예외 타입 도입: `ValidationException`, `ConflictException`, `NotFoundException`
  - AppErrorMapper를 타입 기반 매핑으로 전환(heuristic 제거)

---

### 체크리스트(적용 시)

- 에러 메시지 하드코딩 제거 → AppErrorMapper + AppSnackBar 사용
- 성공 스낵바 문구/지속시간 표준 반영
- 이름 입력 다이얼로그 즉시 검증 동작 확인(버튼 활성/비활성)
- 동일 위치 이동 시 "변경 없음" 안내 확인
- 빈 상태/로딩/에러 뷰 일관성 검토

---

### FAQ / 결정 포인트

- 즉시 검증 vs 후단 검증?
  - 권장: 즉시 검증(UX 개선), 서비스 예외는 최종 보루.
- 자동 접미사 안내 노출?
  - 기본은 조용히 처리, 설정 옵션으로 안내 토스트 on/off.
- Unknown/System을 사용자에게 얼마나 노출?
  - 사용자: 일반 문구, 개발 모드: 상세(원문/스택).
