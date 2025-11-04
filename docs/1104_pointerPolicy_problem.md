📊 pointerPolicy가 제어하는 입력 흐름 전체 분석

1. pointerPolicy의 정의와 전파

전역 설정 (DB 저장)
↓
pointerPolicyProvider (ScribblePointerMode)
↓
├─→ CustomScribbleNotifier.setAllowedPointersMode() [Line 257-258, 274-279]
│ (각 페이지의 notifier에 전파)
│
└─→ LinkerGestureLayer.pointerMode [note_page_view_item.dart:220-223]
(ScribblePointerMode → LinkerPointerMode 변환)

2. 현재 입력 필터링이 적용되는 정확한 위치 2곳

🎯 위치 1: CustomScribbleNotifier 내부 (custom_scribble_notifier.dart)

// Line 83-87
@override
void onPointerDown(PointerDownEvent event) {
if (toolMode.isLinker) return; // 링커 모드 차단
if (!value.supportedPointerKinds.contains(event.kind)) { // ← 여기서 필터링!
return;
}
// ... 필기 처리
}

// Line 127-131
@override
void onPointerUpdate(PointerMoveEvent event) {
if (toolMode.isLinker) return; // 링커 모드 차단
if (!value.supportedPointerKinds.contains(event.kind)) { // ← 여기서 필터링!
return;
}
// ... 필기 처리
}

작동 방식:

- value.supportedPointerKinds는 ScribbleState 내부에 저장된 allowedPointersMode에서
  파생됨
- notifier.setAllowedPointersMode(pointerPolicy)로 설정됨
  (note_editor_provider.dart:258)
- 문제점: Scribble 패키지 내부의 Listener가 raw 포인터 이벤트를 먼저 받아서 이
  메서드를 호출함

🎯 위치 2: LinkerGestureLayer (linker_gesture_layer.dart)

// Line 131-152
// 드래그 허용 포인터
final dragDevices = <ui.PointerDeviceKind>{
ui.PointerDeviceKind.stylus,
ui.PointerDeviceKind.invertedStylus,
};
if (widget.pointerMode == LinkerPointerMode.all) {
dragDevices
..add(ui.PointerDeviceKind.touch)
..add(ui.PointerDeviceKind.mouse)
..add(ui.PointerDeviceKind.trackpad);
}

// 탭 허용 포인터 (두 모드 모두 손가락 탭으로 링크 확인 허용)
final tapDevices = <ui.PointerDeviceKind>{
ui.PointerDeviceKind.stylus,
ui.PointerDeviceKind.invertedStylus,
ui.PointerDeviceKind.touch, // ← 항상 포함!
};
if (widget.pointerMode == LinkerPointerMode.all) {
tapDevices
..add(ui.PointerDeviceKind.mouse)
..add(ui.PointerDeviceKind.trackpad);
}

작동 방식:

- GestureDetector(supportedDevices: dragDevices, ...): 드래그 제스처 필터링
- GestureDetector(supportedDevices: tapDevices, ...): 탭 제스처 필터링
- 중요: 탭은 stylusOnly 모드에서도 touch를 항상 허용함 (의도적 설계)

3. 🚨 입력 충돌이 발생할 수 있는 지점

A. 일반 필기 모드 (toolMode != linker)

위젯 스택 (위→아래):
┌────────────────────────────────────┐
│ InteractiveViewer │ ← panEnabled: true (패닝 허용)
│ └─ Stack │
│ ├─ CanvasBackgroundWidget │
│ ├─ SavedLinksLayer │
│ ├─ Scribble │ ← 입력 처리
│ │ (IgnorePointer: false) │ ← 포인터 이벤트 받음
│ │ (drawPen: true) │
│ │ → CustomScribbleNotifier │
│ │ → onPointerDown() │
│ │ → supportedPointerKinds │ ← 🔥 필터링 지점 1
│ │ 체크 │
│ └─ LinkerGestureLayer │
│ (toolMode != linker) │ ← Container() 반환 (비활성)
└────────────────────────────────────┘

충돌 가능 시나리오:

1. InteractiveViewer가 터치 이벤트를 패닝으로 처리
2. Scribble도 동시에 터치 이벤트를 받아서 필기 시작
3. → 패닝과 필기가 동시에 발생할 수 있음

현재 보호 장치:

- CustomScribbleNotifier가 supportedPointerKinds로 필터링
- stylusOnly 모드면 touch 이벤트를 무시함

B. 링커 모드 (toolMode == linker)

위젯 스택 (위→아래):
┌────────────────────────────────────┐
│ InteractiveViewer │ ← panEnabled: FALSE (패닝 차단)
│ └─ Stack │
│ ├─ CanvasBackgroundWidget │
│ ├─ SavedLinksLayer │
│ ├─ Scribble │ ← 입력 차단됨
│ │ (IgnorePointer: true) ❌ │ ← 모든 포인터 무시
│ │ (drawPen: false) │
│ └─ LinkerGestureLayer │ ← 입력 처리
│ ├─ Listener (raw debug) │
│ ├─ GestureDetector (tap) │
│ │ supportedDevices: │ ← 🔥 필터링 지점 2
│ │ [stylus, touch, ...] │
│ └─ GestureDetector (drag) │
│ supportedDevices: │ ← 🔥 필터링 지점 3
│ [stylus, (touch?)] │
└────────────────────────────────────┘

충돌 가능 시나리오:

1. pointerMode == stylusOnly인데
2. 손가락으로 드래그하면?
3. → dragDevices에 touch가 없으므로 드래그 무시 ✅
4. BUT: 손가락 탭은 항상 허용됨! (Line 143-147)

5. 🔍 실제 문제가 발생하는 정확한 원인

문제 1: Scribble 패키지의 내부 Listener

Scribble 위젯은 아마도 다음과 같은 구조를 가지고 있을 것:
class Scribble extends StatelessWidget {
@override
Widget build(BuildContext context) {
return Listener( // ← raw 포인터 이벤트를 먼저 캡처
onPointerDown: (event) {
notifier.onPointerDown(event);
},
onPointerMove: (event) {
notifier.onPointerUpdate(event);
},
child: CustomPaint(...),
);
}
}

문제:

- Listener는 hit-test를 통과한 모든 포인터 이벤트를 받음
- IgnorePointer(ignoring: false)일 때, Listener는 모든 이벤트를 notifier에 전달
- notifier 내부에서 supportedPointerKinds 체크를 하지만, 이미 위젯 트리에서
  이벤트가 전파됨

문제 2: GestureDetector와 Listener의 충돌

포인터 이벤트 흐름:
터치 이벤트
↓
Hit Test
↓
┌─────────────────┐
│ LinkerGestureLayer │ ← 링커 모드: GestureDetector가 supportedDevices로 필터링
│ (Container) │ ← 일반 모드: 아무것도 안 함
└─────────────────┘
↓
┌─────────────────┐
│ Scribble │ ← Listener가 raw 이벤트 받음
│ → Listener │ ← 내부에서 supportedPointerKinds 체크
└─────────────────┘

충돌 시나리오:

1. stylusOnly 모드 + 일반 필기 모드


    - 손가락 터치 → Scribble의 Listener → notifier.onPointerDown()
    - → supportedPointerKinds.contains(touch) = false
    - → return으로 무시 ✅ (문제 없음)

2. stylusOnly 모드 + 링커 모드


    - 손가락 드래그 → LinkerGestureLayer의 GestureDetector
    - → dragDevices.contains(touch) = false
    - → 드래그 무시 ✅
    - 손가락 탭 → LinkerGestureLayer의 GestureDetector
    - → tapDevices.contains(touch) = true ✅
    - → 탭 허용 (의도된 동작: 링크 찾기는 손가락 가능)

3. all 모드 + 일반 필기 모드


    - InteractiveViewer가 panEnabled: true
    - Scribble도 입력 받음
    - → 패닝과 필기가 동시에 시작될 수 있음 🚨

문제 3: InteractiveViewer의 제스처 우선순위

// note_page_view_item.dart:163
panEnabled: !isLinkerMode,

- 일반 모드: panEnabled=true → 터치 드래그가 패닝으로 처리될 수 있음
- 링커 모드: panEnabled=false → 패닝 차단, LinkerGestureLayer가 선점

충돌:

- InteractiveViewer와 Scribble이 동시에 터치 이벤트에 반응할 수 있음
- Flutter의 제스처 arbitration(중재)에 의존하고 있음
- → 예측 불가능한 동작 발생 가능

5. 📋 정리: 현재 pointerPolicy가 제어하는 것 vs 제어하지 못하는 것

✅ 제어되는 것:

1. CustomScribbleNotifier 내부 필기 처리 (onPointerDown/Update)
2. LinkerGestureLayer의 드래그 제스처 (supportedDevices)
3. LinkerGestureLayer의 탭 제스처 (supportedDevices)

❌ 제어되지 않는 것:

1. InteractiveViewer의 패닝 제스처
2. 위젯 간 제스처 충돌 (InteractiveViewer ↔ Scribble)
3. hit-test 단계의 이벤트 전파
4. 링커 모드에서 탭은 항상 touch 허용 (의도적이지만 일관성 부족)

5. 🎯 구체적인 문제 증상

사용자가 경험하는 문제는 아마도:

1. stylusOnly 모드에서 손가락으로 패닝하려고 했는데 필기가 시작됨


    - InteractiveViewer보다 Scribble이 이벤트를 먼저 받음

2. all 모드에서 드래그가 패닝과 필기를 동시에 트리거함


    - 제스처 중재 실패

3. 링커 모드에서 손가락 탭이 작동함 (stylusOnly인데도)


    - tapDevices에 touch가 항상 포함됨 (line 146)
