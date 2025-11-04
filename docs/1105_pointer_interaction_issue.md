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

## 4. 문제 재현 요약 (Stylus Only 모드)

1. 링커 툴 선택 후 링크 영역을 펜/손가락으로 탭해도 반응 없음.
2. 링커 툴에서 펜으로 사각형을 한 번 그린 뒤, 손가락으로 뷰어를 이동하거나 핀치해도 반응 없음.

→ stylusOnly 정책에서 링커 제스처와 InteractiveViewer가 동시에 비활성화되는 것이 핵심 증상.

## 5. 근본 원인 분석

### 5.1 포인터 필터 흐름

| 계층               | 위치                                                           | stylusOnly에서의 동작                                                                                                                     |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Scribble           | `note_page_view_item.dart:210-221`<br>`CustomScribbleNotifier` | 링커 모드 진입 시 `IgnorePointer`로 완전 차단.                                                                                            |
| LinkerGestureLayer | `linker_gesture_layer.dart:87-205`                             | `_allowTouchTap`과 `_allowTouchDrag`가 둘 다 `false` → 손가락 탭/드래그 모두 reject. `_activeKind`가 stylus여도 tap 콜백을 호출하지 않음. |
| InteractiveViewer  | `note_page_view_item.dart:159-175`                             | `isLinkerMode`면 `panEnabled=false` → 손가락 이동/핀치가 전부 막힘.                                                                       |

### 5.2 정리

- “Stylus 전용이라도 탭은 허용한다”는 설계 의도와 달리 `_allowTouchTap`이 `LinkerPointerMode.all`일 때만 `true`라 손가락 탭이 막혀 Step 3가 발생함.
- `_handlePointerUp`이 `_activeKind`를 확인하지 않아 펜 탭이 콜백으로 전달되지 않음(링크 탭 미동작).
- InteractiveViewer가 완전히 비활성화되어 Step 4의 “손가락 이동 불가” 증상이 유지됨. stylusOnly에서도 손가락 제스처가 전부 버려지고 있음.

## 6. 수정 계획

1. **링커 탭 복구**

   - `_allowTouchTap`을 stylusOnly에서도 `true`로 유지하거나, 최소한 `_activeKind`가 stylus일 때는 강제로 탭 콜백을 호출하도록 `_handlePointerUp`을 수정한다.
   - `_supportsPointer`도 stylus 탭을 reject하지 않도록 정리한다.

2. **링커 모드 패닝 허용**

   - `InteractiveViewer.panEnabled` 계산식을 조정해 `isLinkerMode && pointerPolicy == penOnly`일 때는 `true`로 유지한다. 손가락 입력은 InteractiveViewer가 처리하고, 펜 드래그는 Linker가 담당한다.

3. **스타일러스/손가락 공존 확인**

   - 멀티 포인터가 들어오면 기존처럼 `_resetGesture()`로 Linker 추적을 중단해 두 손가락 핀치가 InteractiveViewer로 흘러가도록 유지한다(`linker_gesture_layer.dart:168-207`).

4. **Scribble 레이어 유지**
   - Scribble을 끄는 로직은 그대로 두되(링커 모드에서는 필기 차단 필요), 상위 제스처가 손가락 입력을 소비하지 않도록 조건을 조정한다.

## 7. 구현 시나리오 초안

1. `LinkerGestureLayer`에서 `_allowTouchTap` 계산을 고쳐 stylusOnly에서도 탭을 허용하고, `_handlePointerUp`에 `_activeKind` 분기를 추가한다.
2. `note_page_view_item.dart`에서 `panEnabled`를 `isLinkerMode && pointerPolicy == ScribblePointerMode.penOnly`인 경우에도 `true`로 설정한다.
3. 에뮬레이터/기기에서 아래 플로우를 검증한다.
   - 펜 탭 → 링크 액션 패널 표시
   - 손가락 탭 → 동일하게 패널 표시
   - 펜 드래그 → 링크 사각형 생성
   - 손가락 드래그/핀치 → 뷰어 이동/확대 축소
4. 필요 시 추가 회귀 테스트(`pointerPolicy == all`)도 실행해 싱글 터치 패닝 방식이 변하지 않았는지 확인한다.

## 8. Stylus-only에서 링크 생성 시 InteractiveViewer 패닝 문제

### 증상

- 스타일러스 모드 + 링커 모드에서 사각형을 그리면, 링크 직사각형과 함께 InteractiveViewer도 움직여 화면이 쓸려 나감.

### 근본 원인

- `panEnabled`를 stylus-only 모드에서도 켜둔 상태라, Flutter 제스처 아레나에서 InteractiveViewer의 `ScaleGestureRecognizer`가 스타일러스 드래그를 계속 팬(Pan)으로 인식함.
- `LinkerGestureLayer`는 Listener 기반이라 포인터 이벤트를 모두 받고 드래그를 추적하지만, 동시에 InteractiveViewer도 제스처를 `accept`해 두 위젯이 같은 드래그 스트림을 공유하게 됨.
- 결과적으로 스타일러스 드래그가 링커 사각형 + 뷰어 패닝을 동시에 유발.

### 해결

1. `LinkerGestureLayer`에 `onStylusInteractionChanged` 콜백을 추가해 스타일러스 드래그가 시작/종료될 때 상위 레이어에 알림.
   - 포인터 다운/업/취소 시 `_notifyStylusInteraction`으로 상태 전환 (`lib/features/canvas/widgets/linker_gesture_layer.dart`).
2. `NotePageViewItem`에서 `_stylusLinkerActive` 상태를 추가해 콜백 값을 추적하고, 스타일러스가 활성일 동안에는 `panEnabled`를 일시적으로 꺼 InteractiveViewer가 드래그를 수락하지 않도록 함.
3. 스타일러스가 올라가면 즉시 `panEnabled`가 다시 켜져 손가락 패닝/핀치를 계속 허용.
