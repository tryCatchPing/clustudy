# Riverpod Migration Plan

## 프로젝트 개요
Flutter 노트 앱의 상태 관리를 **StatefulWidget + setState**에서 **Riverpod**로 마이그레이션

## 해결한 주요 문제점
- **파라미터 포워딩**: `notifier`가 9개 위젯, `pageController`가 5개 위젯을 거쳐 전달됨 → Provider로 직접 접근
- **상태 동기화**: Provider와 로컬 setState 혼재로 인한 불일치 → Provider 통합
- **생명주기 관리**: Controller 수동 dispose → Provider 자동 관리

## 마이그레이션된 상태들
1. **currentPageIndex** - 현재 페이지 인덱스 (StateNotifierProvider)
2. **simulatePressure** - 필압 시뮬레이션 설정 (StateNotifierProvider)  
3. **customScribbleNotifiers** - 페이지별 그리기 상태 (StateNotifierProvider.family)
4. **currentNotifier** - 현재 활성 그리기 상태 (Provider.family)
5. **pageController** - 페이지 네비게이션 (Provider.family)

## 마이그레이션 전략

### 원칙
1. **점진적 전환**: 한 번에 모든 것을 바꾸지 않음
2. **하향식 접근**: 단순한 상태부터 복잡한 상태 순으로
3. **포워딩 제거**: Provider 사용으로 직접 접근 방식 도입
4. **안전성 우선**: 각 단계마다 테스트 후 다음 단계 진행

### 접근 방법
1. **기존 코드 보존**: 주석 처리만 하고 삭제하지 않음
2. **혼용 방식**: Provider와 setState를 일시적으로 병행 사용
3. **타입 안정성**: StateNotifierProvider로 타입 안전성 확보
4. **성능 고려**: 필요한 부분만 재렌더링되도록 최적화

## 완료된 작업

### Phase 1: 기반 구축 ✅
- Riverpod 패키지 설치 및 ProviderScope 설정
- Provider 파일 구조 생성

### Phase 2: 기본 상태 전환 ✅
- `currentPageIndex`, `simulatePressure` StateNotifierProvider로 변환
- NoteEditorScreen → ConsumerStatefulWidget 변환

### Phase 3: 그리기 상태 통합 ✅
- `customScribbleNotifiers` StateNotifierProvider.family로 변환
- `currentNotifier` Provider.family로 자동 계산
- NoteModel 파라미터 지원으로 노트별 독립적 상태 관리

### Phase 4: PageController Provider화 ✅
- `pageController` Provider.family로 변환 및 자동 dispose
- Provider 상태 변경시 PageController 자동 동기화
- NoteEditorPageNavigation → ConsumerWidget 전환으로 파라미터 포워딩 제거

## 남은 작업
- TransformationController Provider화
- 추가 위젯들의 ConsumerWidget 전환

## 기술적 결정사항

### Provider 타입 선택
- **StateNotifierProvider.family**: 복잡한 상태 (CustomScribbleNotifier) ✅
- **Provider.family**: 계산된 상태 (currentNotifier) ✅
- **StateNotifierProvider**: 단순한 상태 (currentPageIndex, simulatePressure) ✅
- **Provider**: 단순한 객체 (Controllers, 예정)

### 파일 구조
```
lib/features/canvas/providers/
├── note_editor_provider.dart    # 페이지, 필압 등 기본 상태
├── canvas_providers.dart        # 캔버스 관련 Provider들
├── controller_providers.dart    # Controller들의 Provider
└── providers.dart               # Barrel export
```

### 네이밍 컨벤션
- Provider: `xxxProvider`
- StateNotifier: `XxxNotifier`
- 상태 읽기: `ref.watch(provider)`
- 상태 변경: `ref.read(provider.notifier).method()`

## 참고 자료
- [Riverpod 공식 문서](https://riverpod.dev/)
- [Flutter State Management 가이드](https://docs.flutter.dev/data-and-backend/state-mgmt)
- 프로젝트 CLAUDE.md의 Provider 마이그레이션 섹션