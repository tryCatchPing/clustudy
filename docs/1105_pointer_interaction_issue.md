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

## 9. 페이지 이탈 시 MouseTracker Assertion 문제

### 증상

- 스타일러스 호버 상태(커서 점이 보이는 상태)에서 노트 편집 화면을 떠나면 다음 예외가 연속 발생:
  ```
  'package:flutter/src/rendering/mouse_tracker.dart': Failed assertion: line 203 pos 12: '!_debugDuringDeviceUpdate': is not true.
  A CustomScribbleNotifier was used after being disposed.
  ```

### 근본 원인

- 화면이 Pop되면서 `CustomScribbleNotifier`가 `dispose()`된 뒤에도 시스템이 마지막 스타일러스 포인터에 대한 `PointerExitEvent`를 전달.
- Scribble 패키지 기본 구현은 exit 시 `notifyListeners()`를 호출하지만, 이미 dispose된 노티파이어에서 이를 실행해 Flutter의 `ChangeNotifier` 보호 로직이 assertion을 발생시킴.
- MouseTracker는 여전히 디바이스 업데이트 중이어서 `_debugDuringDeviceUpdate` 플래그가 켜진 상태로 재귀 호출이 일어나 추가 assertion이 이어짐.

### 해결

1. `CustomScribbleNotifier`에 `_isDisposed` 플래그를 도입하고 `dispose()`에서 true로 설정.
2. `onPointerDown`, `onPointerUpdate`, `onPointerExit` 등 포인터 핸들러가 `_isDisposed`를 먼저 확인해 dispose 이후 이벤트를 무시하도록 변경.
3. `onPointerExit`를 override해 dispose된 상태에서는 상위 구현을 호출하지 않도록 함으로써 MouseTracker 업데이트 루프에서 더 이상 dispose된 노티파이어를 참조하지 않게 함.

## 10. 기존 정책 한계와 회귀

- 싱글 포인터 제어는 `ScribbleState.activePointerIds`에 의존했는데, penOnly 모드에서는 Scribble이 **손가락 이벤트를 아예 추적하지 않아** 손가락 1개 여부를 알 수 없었다.
- PageView는 여전히 상위에서 가로 드래그를 수락해, `pointerPolicy == all` 상태에서도 **한 손가락 좌우 드래그가 페이지 이동과 필기를 동시에 일으키는 회귀**가 재발했다.
- Linker가 Listener 기반으로 모든 포인터를 잡는 특성 때문에, `PageView`와 `InteractiveViewer`가 제스처 아레나에서 계속 경쟁하면서 “필기 ↔ 페이지 스와이프”가 상황에 따라 달라지는 비일관성이 남았다.

## 11. Pointer Snapshot Provider 도입

- **파일:** `lib/features/canvas/providers/pointer_snapshot_provider.dart`
- **구성 요소**
  - `PointerSnapshotNotifier`: noteId별로 포인터 다운/업/취소 이벤트를 관리하고, 손가락/스타일러스/마우스/트랙패드 개수를 모두 카운트.
  - `PointerSnapshot`: 현재 입력 상태를 불변 스냅샷으로 노출(`totalPointers`, `stylusPointers`, `hasMultiplePointers` 등).
  - `pageScrollLockProvider`: Linker 활성 여부 + `totalPointers == 1` 조건으로 PageView 잠금 여부를 계산.
- **주요 특징**
  - `NotePageViewItem` 루트에 Listener를 추가해 모든 포인터 이벤트를 트래커에 보고 → Scribble 모드·포인터 종류와 상관없이 동일한 데이터를 확보.
  - Linker가 stylus 드래그를 시작/종료할 때 `setLinkerStylusActive`를 호출해, 드래그 중에는 포인터 수와 무관하게 PageView를 강제 잠금.

## 12. PageView/InteractiveViewer 연동 방식 변경

- `NoteEditorCanvas`
  - `pageScrollLockProvider`를 구독해 잠금 시 `NeverScrollableScrollPhysics`를, 해제 시 커스텀 `SnappyPageScrollPhysics`를 적용해 관성도 짧게 유지.
  - 싱글 포인터가 눌린 동안에는 PageView가 제스처 아레나에 참여하지 않으므로, 필기·링커 입력과 충돌하지 않는다.
- `NotePageViewItem`
  - 포인터 스냅샷을 사용해 `InteractiveViewer.panEnabled`와 `LinkerGestureLayer` 조건을 동일한 규칙으로 계산.
  - penOnly 모드에서도 손가락/스타일러스 카운트를 정확하게 구분할 수 있어, 손가락 1개 팬과 펜 필기/링커 드래그가 안정적으로 공존.
  - `LinkerGestureLayer`의 스타일러스 상태를 전파해 stylus-only 드래그 중에는 항상 PageView와 InteractiveViewer 팬이 비활성화된다.

## 13. 최종 포인터 정책 (2025-11-05)

| 포인터 수              | 입력 종류                | 허용 동작                                                                                                                                           |
| ---------------------- | ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0                      | -                        | 페이지 잠금 해제 상태 유지                                                                                                                          |
| 1                      | 손가락/스타일러스/마우스 | **항상 현재 페이지 조작 전용**<br>- Scribble 필기, 링커 드래그/탭<br>- penOnly 모드에선 손가락 싱글 팬만 허용<br>- PageView 스와이프/관성 전부 차단 |
| ≥2                     | 조합 무관                | PageView와 InteractiveViewer가 제스처를 나눠 사용<br>- 두 손가락 수평 스와이프 → 페이지 이동<br>- 핀치/회전 → InteractiveViewer가 우선              |
| stylus 드래그 (Linker) | -                        | `linkerStylusActive`가 true인 동안엔 포인터 수와 상관없이 PageView 완전 잠금                                                                        |

**결과**

- 한 손가락 좌/우 드래그는 더 이상 페이지 이동을 트리거하지 않고, Scribble/Linker/InteractiveViewer 중 해당 모드의 “현재 페이지 조작”에만 사용된다.
- 두 손가락 이상일 때만 PageView가 아레나에 참여하므로, “페이지 넘김 의도”가 명확해지고 우발적인 전환이 사라졌다.
- 포인터 정책 변화가 `pointer_snapshot_provider.dart` 한 곳에서 계산되기 때문에, 향후 모드가 추가되어도 동일 규칙을 손쉽게 확장할 수 있다.
