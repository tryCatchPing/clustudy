# 1104 pointerPolicy 개선 작업 가이드

> 목표: `ScribblePointerMode.all`일 때는 **싱글 터치 = 필기**, **멀티 터치 = 패닝/줌**이 자연스럽게 공존하도록 하고, `penOnly` 모드는 기존 동작을 유지합니다.

## 1. 원인 요약 (재확인)

- `scribble` 포크(`lib/src/view/scribble.dart`)가 항상 `GestureCatcher`로 `RawGestureDetector`를 등록합니다.
- `GestureCatcher`는 전달받은 `pointerKindsToCatch` 전체를 즉시 `GestureDisposition.accepted`로 만들어 InteractiveViewer 제스처 아레나를 이깁니다.
- `ScribblePointerMode.all`일 때 터치가 포함된 세트를 그대로 전달해서, 2번째 손가락이 들어와도 InteractiveViewer는 이벤트를 못 받습니다.

## 2. Scribble 위젯 수정 지침

### 2.1 수정 대상

- 경로: `~/.pub-cache/git/scribble-<hash>/lib/src/view/scribble.dart`
- `build` 메서드 내부에서 `GestureCatcher`를 감싸는 부분

### 2.2 적용 아이디어

1. `state.allowedPointersMode`에 따라 `GestureCatcher` 적용 여부를 분기합니다.
   ```dart
   final shouldCatch = switch (state.allowedPointersMode) {
     ScribblePointerMode.penOnly ||
     ScribblePointerMode.mouseOnly ||
     ScribblePointerMode.mouseAndPen => true,
     ScribblePointerMode.all => false,
   };
   ```
2. `shouldCatch == false`이면 기존 `GestureCatcher` 래핑을 건너뛰고 `MouseRegion` → `Listener`만 렌더링합니다.
   - 이렇게 하면 터치 포인터가 제스처 아레나로 흘러 InteractiveViewer가 두 번째 손가락을 받을 수 있습니다.
3. `shouldCatch == true`인 경우(= 터치가 금지된 모드)는 현재 구조를 유지하면 됩니다.
4. `state.supportedPointerKinds`에는 아무 변화가 없어도 됩니다. `CustomScribbleNotifier`가 이미 포인터 종류를 다시 필터링합니다.

### 2.3 구현 힌트

- 가독성을 위해 `Widget _buildActiveChild(...)` 같은 private 메서드로 child 빌드를 분리해도 좋습니다.
- 조건 분기 이후에는 다음 형태를 유지하면 됩니다.
  ```dart
  if (!state.active) return child;
  if (!shouldCatch) {
    return MouseRegion(... Listener(child));
  }
  return GestureCatcher(... MouseRegion(... Listener(child)));
  ```
- `_GestureCatcherRecognizer` 자체를 수정할 필요는 없습니다.

## 3. 앱 코드 후속 정리

### 3.1 InteractiveViewer 설정 (`lib/features/canvas/widgets/note_page_view_item.dart`)

- `panEnabled`를 무조건 `!isLinkerMode`로 고정하면, `all` 모드에서도 한 손가락 드래그가 패닝으로 연결되는 순간 필기와 충돌합니다.
- 전역 포인터 정책을 읽어서 아래처럼 조건을 나눕니다.
  ```dart
  final pointerPolicy = ref.watch(pointerPolicyProvider);
  final canPanWithSingleFinger = pointerPolicy == ScribblePointerMode.penOnly;
  panEnabled: !isLinkerMode && canPanWithSingleFinger,
  ```
- 두 손가락 이상은 `GestureDetector`의 scale 제스처가 처리하므로 `scaleEnabled: true`는 그대로 유지합니다.

### 3.2 멀티 포인터 안전장치 (선택)

- `CustomScribbleNotifier`는 이미 `value.active`로 2개 이상 포인터가 들어오면 `pointerPosition`을 null로 돌립니다. 그래도 확실히 하고 싶다면, `onPointerDown`에서 `activePointerIds.length >= 1`일 때 항상 `activeLine`을 `null`로 정리해도 됩니다.

## 4. 테스트 & 검증

1. `fvm flutter analyze`가 통과해야 합니다.
2. 물리 디바이스나 시뮬레이터에서 아래 시나리오를 확인합니다.
   - `ScribblePointerMode.all`: 한 손가락 필기, 두 손가락 패닝, 두 손가락 핀치 줌 모두 정상.
   - `ScribblePointerMode.penOnly`: 손가락 단독은 패닝만, 펜 입력은 필기.
3. 링커 모드에서도 기존 동작(손가락 탭 허용, 두 손가락 줌 가능)이 유지되는지 확인합니다.

## 5. 작업 순서 제안

1. `scribble` 포크 브랜치를 체크아웃하고 위의 2단계 수정 적용.
2. 앱 레이어(`note_page_view_item.dart`)에서 `panEnabled` 조건 수정.
3. 필요 시 `docs/1104_pointerPolicy.md`에 구현 완료 메모 추가.
4. `fvm flutter analyze`, `fvm flutter test` 후 동작 검증.

이 문서를 기반으로 수정 요청을 전달하면 됩니다. Codex 인스턴스에는 **패키지 포크 수정**과 **앱 레이어 조정** 두 파트를 명시적으로 할당하세요.
