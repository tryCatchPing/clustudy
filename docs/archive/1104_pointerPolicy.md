# pointer 정책 확정

1104_pointerPolicy_problem.md 문서와 관련해 정책을 정리합니다

## 목표: 사용자 기대 동작

### all pointer 모드

#### 일반 모드

- 손 입력

  - 한 손가락: 그리기 (현 구현 상태에서 테스트 시 의도대로 정상 동작 O)
  - 두 손가락: 캔버스 이동 (의도대로 동작 X)
  - 두 손가락: 핀치 줌 / 아웃 (X)
  - 세 손가락: 캔버스 이동 (O)

- 스타일러스 입력
  - 그리기 (O)

#### 링커 모드 (링커 툴 선택)

- 손 입력

  - 한 손가락 탭: 링크 터치/액션 (O)
  - 한 손가락 드래그: 링크 그리기 (O)
  - 두 손가락 이동/줌: 일반모드와 동일 (줌만 O, 이동 X)

- 스타일러스 입력
  - 드래그: 링크 그리기 (O)
  - 탭: 링크 터치 (O)

### stylus only 모드

#### 일반 모드

- 손 입력

  - 한 손가락: 이동 (O)
  - 두 손가락: 이동 (O)
  - 두 손가락: 핀치 줌 / 아웃 (O)
  - 세 손가락: 캔버스 이동 (O)

- 스타일러스 입력
  - 그리기 (O)

#### 링커 모드

- 손 입력

  - 한 손가락: 터치 시 링크 이동 또는 동작 안함 (링크 이동 O)
  - 두 손가락: 이동 (줌만 O, 이동 X)
  - 두 손가락: 핀치 줌 / 아웃 (O)
  - 세 손가락: 캔버스 이동 (O)

- 스타일러스 입력
  - 링크 그리기 (O)
  - 링크 터치 시 동작 (O)

---

## 현재 문제 분석

### 근본 원인

#### 1. Scribble 패키지의 Listener 구조

```
포인터 이벤트 흐름:
  터치 이벤트
       ↓
  Hit Test
       ↓
  Scribble Widget
    └─ Listener (raw 포인터 이벤트 캡처)
       └─ notifier.onPointerDown()
          └─ supportedPointerKinds 체크 (내부 필터링)
```

**문제점:**

- Listener는 제스처 아레나에 참여하지 않음
- raw 포인터를 직접 받아서 내부에서만 필터링
- InteractiveViewer와 제스처 경쟁 불가능

#### 2. All 모드에서 멀티터치 충돌

```
두 손가락 터치:
  첫 번째 손가락 → Scribble Listener → 그리기 시작
  두 번째 손가락 → Scribble Listener → 또 다른 그리기 시작
  InteractiveViewer → 제스처 아레나에서 패배 → 줌/패닝 불가
```

**결과:**

- 두 손가락 이동 불가 ❌
- 핀치 줌 불가 ❌

#### 3. 링커 모드에서 패닝 차단

```dart
// note_page_view_item.dart:163
panEnabled: !isLinkerMode,  // 링커 모드 = false
```

**의도:** 한 손가락 드래그를 LinkerGestureLayer가 받도록 패닝 차단

**부작용:**

- 두 손가락 이동도 차단됨
- 줌만 가능 (scaleEnabled: true)

### 위젯 레이어 분석

```
NotePageViewItem
└─ InteractiveViewer
   ├─ panEnabled: !isLinkerMode (문제)
   ├─ scaleEnabled: true
   └─ Stack
      ├─ CanvasBackgroundWidget
      ├─ SavedLinksLayer
      ├─ IgnorePointer(ignoring: toolMode.isLinker)
      │  └─ Scribble (Listener 사용, 문제 원인)
      └─ LinkerGestureLayer (GestureDetector 사용)
```

**충돌 포인트:**

1. Scribble Listener ↔ InteractiveViewer GestureDetector
2. LinkerGestureLayer ↔ InteractiveViewer (panEnabled 정적 제어)
