# 1105 싱글 터치/링커 제스처 이슈 정리

## 1. 최근 진행 사항

### 1.1 Scribble 포크 수정

- 경로: `lib/src/view/scribble.dart`
- `ScribblePointerMode.all`일 때 `GestureCatcher`를 건너뛰도록 바꿔, 두 번째 손가락부터는 Flutter 제스처 아레나가 정상적으로 열리도록 조정.
- 기존 `Listener` 기반 필기 로직은 그대로 두고, 마우스 커서 처리 등은 유지.

### 1.2 앱 레이어 수정

- 경로: `lib/features/canvas/widgets/note_page_view_item.dart`
- `ValueListenableBuilder<ScribbleState>`로 현재 포인터 수를 관찰.
- `panEnabled` 계산식:
  ```
  final multiplePointersActive = scribbleState.activePointerIds.length >= 2;
  final allowSingleFingerPan = pointerPolicy == ScribblePointerMode.penOnly;
  final panEnabled =
      !isLinkerMode && (allowSingleFingerPan || multiplePointersActive);
  ```
- 결과: `pointerPolicy == all` 상태에서 한 손가락은 Scribble만 반응하고, 두 손가락 이상이 되면 InteractiveViewer가 패닝/핀치를 담당.

## 2. 현재 동작 요약

| 모드    | 포인터 수 | 실제 동작                                                                      |
| ------- | --------- | ------------------------------------------------------------------------------ |
| all     | 1         | Scribble 필기만 동작, InteractiveViewer 패닝 차단                              |
| all     | ≥2        | InteractiveViewer 패닝/핀치 정상 작동, Scribble는 포인터가 2개 이상이라 비활성 |
| penOnly | 1         | InteractiveViewer 싱글 터치 패닝 허용 (기존 동작 유지)                         |
| penOnly | ≥2        | InteractiveViewer 멀티 터치 패닝/핀치                                          |

싱글 터치 패닝 충돌은 이 방식으로 해결됐다.

## 3. Flutter 제스처 모델 이해 요약

1. **Listener는 제스처 아레나 밖**
   `Listener`는 히트 테스트만 통과하면 포인터 이벤트를 무조건 전달받는다. 아레나 경쟁이 없으므로 Scribble은 항상 이벤트를 수신한다.
2. **InteractiveViewer는 제스처 아레나 안**
   내부 `ScaleGestureRecognizer`가 1포인터 드래그를 팬으로 인식하고 `accept`하면 같은 스트림의 이벤트를 계속 소비한다.
3. **충돌 구조**
   두 위젯이 동시에 이벤트를 받는 구조였기 때문에, `panEnabled`를 싱글 포인터 구간에서만 꺼주어 충돌을 풀었다.

## 4. 링커 모드에서 남은 문제

### 4.1 증상

1. `pointerPolicy == all` + 링커 모드
   - 두 손가락/세 손가락 제스처가 모두 `LinkerGestureLayer`로 흘러가 링크 드래그가 시작됨.
   - InteractiveViewer에 포인터가 도달하지 않아 패닝/핀치 불가.
2. `pointerPolicy == penOnly`(stylus 모드) + 링커 모드
   - 손가락 제스처가 InteractiveViewer에 닿지 않음.
   - 뷰어 패닝이 불가능해짐.

### 4.2 원인

- 링커 모드에서는 `IgnorePointer`로 Scribble 레이어를 막고, Stack 최상단에 `LinkerGestureLayer`가 위치.
- `LinkerGestureLayer`는 다음 구조를 갖는다:
  ```dart
  GestureDetector( // 탭 감지, supportedDevices: tapDevices
    child: GestureDetector( // 드래그 감지, supportedDevices: dragDevices
      child: CustomPaint(...),
    ),
  );
  ```
- tap detector는 모든 모드에서 `PointerDeviceKind.touch`를 포함하고 `HitTestBehavior.opaque`라 포인터를 먼저 선점.
- all 모드의 drag detector는 touch까지 포함하므로 멀티 터치도 Linker 측이 `accept`한다.
- stylus 모드에서는 drag detector가 터치를 제외하지만, 바깥 tap detector가 이미 touch 포인터를 잡는 바람에 InteractiveViewer로 내려가지 않는다.

### 4.3 해결 방향 후보

1. **멀티 포인터 전달**
   - `LinkerGestureLayer`에서 포인터 수를 추적하고, 두 번째 손가락이 들어오면 `GestureRecognizer.rejectGesture`로 자신의 제스처를 중단하여 InteractiveViewer가 이어받게 한다.
2. **Stylus 모드 탭 필터링**
   - stylusOnly일 때 tap detector의 `supportedDevices`에서 `touch`를 제거하거나, `IgnorePointer`로 터치를 투과시켜 InteractiveViewer가 패닝하도록 한다.
3. **모드별 전용 제스처 레이어**
   - 링커 모드에서 InteractiveViewer 패닝을 사용하지 않고 별도 이동/확대 제스처를 제공하는 등 UX를 재설계.

## 5. 원하는 동작을 위한 구조 개선 초안

### 5.1 원인 재정리

- Linker 레이어가 `GestureDetector` 두 개(탭/드래그)를 중첩해 사용하면서 `HitTestBehavior.opaque`로 화면 전체를 차지.
- 탭 detector는 터치를 항상 허용하고, 드래그 detector는 all 모드에서 touch까지 수용해 첫 번째 손가락에서 바로 제스처를 `accept`.
- StylusOnly 모드에서도 탭 detector가 touch를 잡아두기 때문에 손가락 입력이 InteractiveViewer까지 내려가지 못한다.

### 5.2 근본적인 개편 방안

1. **Pointer Listener 기반으로 재작성**

   - `GestureDetector` 대신 `Listener` + 간단한 상태 머신으로 링크 드래그/탭을 직접 처리.
   - Listener는 제스처 아레나에 참여하지 않으므로 InteractiveViewer와 충돌하지 않음.
   - 구현 포인트:
     - `PointerDownEvent`에서 허용 포인터(kind, 정책)를 판별해 하나의 포인터만 추적.
     - 이동 거리로 드래그와 탭을 구분해 `onRectCompleted` / `onTapAt` 호출.
     - 포인터가 2개 이상이 되면 즉시 현재 추적을 취소하고 나머지는 무시 → InteractiveViewer가 자연스럽게 멀티 터치를 처리.
     - StylusOnly 모드에서는 touch 포인터를 바로 무시해 손가락 패닝이 그대로 하위 레이어로 전달되도록 한다.

2. **커스텀 GestureRecognizer 사용**

   - `RawGestureDetector` + `PanGestureRecognizer`/`TapGestureRecognizer` 확장 클래스를 도입.
   - `addPointer` 단계에서 포인터 수·종류를 검사해 조건에 맞지 않으면 `resolve(GestureDisposition.rejected)` 호출.
   - 두 번째 손가락이 들어오면 `rejectGesture`로 Linker 제스처를 중단시키고 InteractiveViewer가 아레나를 이어받게 한다.
   - StylusOnly 모드에서는 touch를 바로 reject하도록 tap recognizer를 조정해 패닝 흐름을 보장.

3. **위젯 스택 재구성**
   - Linker 전용 오버레이를 InteractiveViewer 밖으로 빼고 `HitTestBehavior.translucent`로 필요한 포인터만 소비하는 방식도 가능.
   - 이 경우 Linker 좌표계를 `TransformationController`와 동기화해야 하므로, Listener 기반 방식이 상대적으로 구현이 단순.

> 위 개선안 중 Listener 기반 single-pointer 처리 방식이 구현 난이도가 가장 낮고, InteractiveViewer와의 충돌을 명확하게 제거할 수 있는 접근으로 판단된다.

## 6. 2025-11-05 구현 메모

- `LinkerGestureLayer`를 Listener 기반 단일 포인터 추적 구조로 재작성해 적용 완료.
- 포인터가 둘 이상 내려오면 즉시 내부 상태를 초기화하여 InteractiveViewer가 멀티 터치를 처리하도록 함.
- StylusOnly 모드에서는 스타일러스만 드래그 허용, 손가락 입력은 패스스루되어 InteractiveViewer 패닝/핀치로 사용 가능하도록 조정.
- 기존 콜백(`onRectCompleted`, `onTapAt`)과 오버레이 페인터는 그대로 재사용해 외부 API 변경 없이 동작.
