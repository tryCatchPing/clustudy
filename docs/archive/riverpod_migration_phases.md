# Riverpod Migration - Detailed Phases

## Phase 1: 기반 구축 ✅ (완료)

### 목표
Riverpod의 기본 환경 설정 및 프로젝트 구조 준비

### 완료된 작업
- [x] pubspec.yaml에 Riverpod 패키지 추가
- [x] main.dart에 ProviderScope 설정
- [x] providers 폴더 구조 생성
- [x] 기본 Provider 파일 템플릿 작성
- [x] build_runner 버전 충돌 해결 (수동 Provider 방식 채택)

### 산출물
- `lib/features/canvas/providers/note_editor_provider.dart`
- Riverpod 패키지 설정 완료
- 컴파일 에러 없는 기본 환경

---

## Phase 2: 단순 상태 Provider 전환 ✅ (완료)

### 목표
가장 단순한 2개 상태를 Provider로 전환하여 Riverpod 동작 검증

### 완료된 작업
- [x] `currentPageIndex` (int) Provider 변환
- [x] `simulatePressure` (bool) Provider 변환
- [x] StateNotifierProvider로 타입 안전성 확보
- [x] NoteEditorScreen → ConsumerStatefulWidget 변환
- [x] AppBar 제목에서 Provider 값 읽기 적용
- [x] 기본적인 상태 업데이트 메커니즘 구현

### 기술적 상세
```dart
// Provider 정의
final currentPageIndexProvider = StateNotifierProvider<CurrentPageIndexNotifier, int>
final simulatePressureProvider = StateNotifierProvider<SimulatePressureNotifier, bool>

// 사용법
final currentIndex = ref.watch(currentPageIndexProvider);
ref.read(currentPageIndexProvider.notifier).setPage(newIndex);
```

### 검증 사항
- Provider 값 읽기 정상 동작
- Provider 값 변경 정상 동작
- UI 반영 정상 동작

---

## Phase 3: 위젯별 Consumer 전환 🔄 (진행중)

### 목표
하위 위젯들을 ConsumerWidget으로 전환하여 포워딩 제거 시작

### 진행된 작업
- [x] NoteEditorCanvas → ConsumerWidget 전환
- [x] 포워딩 파라미터 일부 제거
- [x] Provider에서 직접 상태 읽기 구현
- [x] CustomScribbleNotifier에 WidgetRef 전달 메커니즘 구현

### 현재 상태
```dart
class NoteEditorCanvas extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPageIndex = ref.watch(currentPageIndexProvider);
    final simulatePressure = ref.watch(simulatePressureProvider);
    // 포워딩 파라미터 대신 Provider에서 직접 읽기
  }
}
```

### 다음 단계 작업 예정
- [ ] NoteEditorToolbar → ConsumerWidget 전환
- [ ] NoteEditorPageNavigation → ConsumerWidget 전환
- [ ] 각 하위 컴포넌트들의 포워딩 파라미터 제거
- [ ] Provider 직접 접근으로 인한 파라미터 수 감소 측정

---

## Phase 4: CustomScribbleNotifier Provider 통합 ✅ (완료)

### 목표
복잡한 그리기 상태를 Provider 시스템에 완전 통합

### 완료된 작업
- [x] **Family Provider 구현**: StateNotifierProvider.family 패턴 적용
- [x] **CustomScribbleNotifiersProvider 생성**:
```dart
final customScribbleNotifiersProvider = StateNotifierProvider.family<
  CustomScribbleNotifiersNotifier, 
  Map<int, CustomScribbleNotifier>, 
  NoteModel
>((ref, note) => CustomScribbleNotifiersNotifier(ref, note));
```

- [x] **CurrentNotifierProvider 생성**:
```dart
final currentNotifierProvider = Provider.family<CustomScribbleNotifier, NoteModel>((ref, note) {
  final currentIndex = ref.watch(currentPageIndexProvider);
  final notifiers = ref.watch(customScribbleNotifiersProvider(note));
  return notifiers[currentIndex]!;
});
```

- [x] **NoteEditorScreen 대대적 단순화**:
  - `late CustomScribbleNotifier notifier` → **완전 제거** ✅
  - `Map<int, CustomScribbleNotifier> _scribbleNotifiers` → **완전 제거** ✅
  - `void _initializeNotifiers()` → **완전 제거** ✅
  - 복잡한 setState 로직 → **단순 Provider 호출로 교체** ✅

### 기술적 성과
- **자동 초기화**: Provider 생성시 모든 notifier 자동 생성
- **타입 안전성**: NoteModel 파라미터로 특정 노트에 대한 notifier 보장
- **생명주기 관리**: Provider가 자동으로 dispose 및 캐싱 처리
- **페이지 전환 최적화**: currentNotifierProvider가 페이지 변경 자동 감지

---

## Phase 5: Controller Provider화 📋 (계획)

### 목표
Flutter Controller들을 Provider로 관리하여 생명주기와 의존성 중앙 집중화

### 계획된 작업
- [ ] TransformationControllerProvider 생성
```dart
@riverpod
TransformationController transformationController(TransformationControllerRef ref) {
  final controller = TransformationController();
  ref.onDispose(() => controller.dispose());
  return controller;
}
```

- [ ] PageControllerProvider 생성
- [ ] Controller 포워딩 제거 (5개 위젯에서 제거)
- [ ] Controller 생명주기 Provider에서 관리

### 예상 효과
- Controller 관련 포워딩 파라미터 완전 제거
- 메모리 누수 방지 자동화
- Controller 재사용성 증대

---

## Phase 6: 완전한 전환 및 최적화 📋 (최종 목표)

### 목표
모든 상태 관리를 Riverpod로 통일하고 불필요한 코드 제거

### 계획된 작업
- [ ] 모든 setState() 호출 제거
- [ ] StatefulWidget → ConsumerWidget 완전 전환
- [ ] 콜백 함수들 단순화
```dart
// 기존 복잡한 콜백
void _onPageChanged(int index) {
  ref.read(currentPageIndexProvider.notifier).setPage(index);
  setState(() => notifier = _scribbleNotifiers[index]!);
}

// 단순화된 콜백  
PageView(
  onPageChanged: (index) => ref.read(currentPageIndexProvider.notifier).setPage(index)
)
```

- [ ] 불필요한 로컬 변수들 제거
- [ ] 최종 성능 및 기능 테스트

### 최종 검증 사항
- [ ] 모든 기존 기능 정상 동작
- [ ] 성능 저하 없음
- [ ] 포워딩 파라미터 90% 이상 감소
- [ ] setState 호출 0개
- [ ] 코드 가독성 및 유지보수성 향상

---

## Phase 5: PageController Provider화 ✅ (완료)

### 목표
PageController 생명주기 문제 해결 및 Provider 동기화 구현

### 문제 상황
- 노트 페이지 이동 후 뒤로가기한 다음 다시 노트로 돌아가면 페이지 변경 버튼이 작동하지 않음
- PageController의 생명주기와 Provider 상태가 불일치
- 툴바의 페이지 네비게이션 컨트롤이 Provider 상태를 반영하지 못함

### 완료된 작업
- [x] **PageController Provider 생성**:
```dart
final pageControllerProvider = Provider.family<PageController, NoteModel>((ref, note) {
  final controller = PageController(initialPage: 0);
  
  // Provider가 dispose될 때 controller도 정리
  ref.onDispose(() => controller.dispose());
  
  // currentPageIndex가 변경되면 PageController도 동기화
  ref.listen<int>(currentPageIndexProvider, (previous, next) {
    if (controller.hasClients && previous != next) {
      controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  });
  
  return controller;
});
```

- [x] **NoteEditorPageNavigation → ConsumerWidget 전환**:
  - StatelessWidget → ConsumerWidget으로 변경
  - 모든 메서드에서 Provider 직접 접근으로 변경
  - 파라미터 포워딩 완전 제거: `currentPageIndex`, `totalPages`, `pageController`, `onPageChanged` 제거

- [x] **NoteEditorToolbar → ConsumerWidget 전환**:
  - StatelessWidget → ConsumerWidget으로 변경
  - NoteModel 파라미터 추가로 NoteEditorPageNavigation에 노트 정보 전달
  - 페이지 관련 파라미터 포워딩 제거

- [x] **NoteEditorCanvas 및 NoteEditorScreen 파라미터 정리**:
  - NoteModel 파라미터 추가로 Provider 체인 완성
  - PageController 생성 및 dispose 로직 Provider로 이관

### 기술적 성과
- **자동 생명주기 관리**: PageController dispose가 Provider에서 자동 처리
- **상태 동기화 해결**: Provider 상태 변경시 PageController가 자동으로 애니메이션 실행
- **파라미터 포워딩 대폭 감소**: 페이지 네비게이션 관련 4개 파라미터 제거
- **화면 재진입 문제 해결**: Provider 캐싱으로 상태 일관성 유지

---

## 현재 진행 상황 요약

### ✅ 완료된 Phase
- **Phase 1**: 기반 구축 (환경 설정)
- **Phase 2**: 단순 상태 전환 (currentPageIndex, simulatePressure)
- **Phase 3**: 위젯별 Consumer 전환 (NoteEditorCanvas, NoteEditorPageNavigation, NoteEditorToolbar)
- **Phase 4**: CustomScribbleNotifier Provider 통합
- **Phase 5**: PageController Provider화

### 📋 남은 작업
- **Phase 6**: TransformationController Provider화
- **Phase 7**: 추가 위젯들의 ConsumerWidget 전환

### 성과 지표 (현재)
- Riverpod 기본 환경: ✅ 100% 완료
- 기본 상태 Provider 전환: ✅ 100% 완료  
- CustomScribbleNotifier Provider 통합: ✅ 100% 완료
- PageController Provider화: ✅ 100% 완료
- 위젯 Consumer 전환: ✅ 약 80% 완료
- 파라미터 포워딩 제거: ✅ 약 85% 완료
- **전체 마이그레이션: ✅ 약 85% 완료**