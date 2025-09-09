네, 노트 편집 화면을 나갔다가 다시 돌아올 때 마지막 페이지를 기억하는 기능이 어떤 원리로 동작하는지 전체적으로 정리한 문서입니다. 각 컴포넌트가 어떻게 상호작용하는지 이해하는 데 큰 도움이 될 겁니다.

---

### ## 큰 그림 (Big Picture) 🗺️

- **라우팅**: `GoRouter`는 노트 편집 화면을 `MaterialPage(maintainState: false)`로 생성합니다. 즉, 화면 스택에는 **항상 단 하나의 편집기만 존재**하며, 화면을 벗어나면 해당 편집기 인스턴스는 메모리에서 **파기(dispose)**됩니다. 다시 돌아오면 완전히 새로운 인스턴스가 생성됩니다.
- **상태 계층**:
  - **노트 데이터**: `noteProvider(noteId)`가 노트의 실제 데이터를 담당합니다.
  - **현재 페이지 상태**: `currentPageIndexProvider(noteId)`는 현재 편집기 화면에 **보이는 페이지 번호**를 가리킵니다. (화면이 재생성될 때마다 0으로 초기화됩니다.)
  - **이어보기 상태**: `resumePageIndexProvider(noteId)`는 사용자가 마지막으로 봤던 페이지 번호입니다. 화면이 파기되어도 **상태가 유지(`keepAlive`)**됩니다.
  - **컨트롤러**: `pageControllerProvider(noteId)`는 `PageView` 위젯을 `currentPageIndexProvider`와 동기화합니다.
  - **세션**: `noteSessionProvider`는 모든 캔버스 관련 프로바이더들이 현재 어떤 노트 위에서 작업 중인지 알려줍니다.

---

### ## 왜 `maintainState=false`를 사용하나요?

편집기 화면이 중복으로 생성되거나 `GlobalKey`가 충돌하는 문제를 피하기 위해서입니다. 하지만 이 방식의 중요한 특징은, 화면을 벗어나면 이전 편집기가 완전히 파괴된다는 것입니다. 따라서 다시 돌아오면 항상 0페이지에서 시작하게 되므로, 우리가 직접 마지막 페이지를 복원해 줘야 합니다.

---

### ## '마지막 페이지'는 언제, 어디에 저장되고 복원되나요? 💾

#### **저장 위치**

- `resumePageIndexProvider(noteId)`에 저장됩니다. 이 프로바이더는 화면과 생명주기를 달리하여 값을 계속 유지합니다.

#### **저장 시점**

1.  **다른 노트로 이동할 때 (사용자 탭)**: 역링크나 캔버스 내 링크를 탭하면, 화면을 이동하기 직전에 현재 노트의 페이지 번호와 스케치를 저장합니다.
2.  **뒤로 가기로 나갈 때 (`pop`)**: `didPop` 콜백에서 `addPostFrameCallback`을 사용해 프레임 빌드가 끝난 후, 현재 페이지 번호를 저장합니다. (빌드 중 프로바이더 수정을 피하기 위함)

#### **복원 시점**

- 편집기 화면에 다시 진입하면 (`maintainState=false` 때문에 새 인스턴스가 생성됨), 첫 프레임이 그려진 직후 `_scheduleRestoreResumeIndexIfAny()` 함수가 실행됩니다.
- 이 함수는 `resumePageIndexProvider`에 저장된 값이 있는지 확인하고, 값이 있다면:
  1.  페이지 범위를 벗어나지 않도록 값을 보정합니다.
  2.  그 값으로 **`currentPageIndexProvider`를 업데이트**합니다.
  3.  역할을 다한 `resumePageIndexProvider`의 값은 다시 비웁니다.

---

### ## 페이지 인덱스는 어떻게 사용되나요? 📖

`currentPageIndexProvider`가 업데이트되면, `pageControllerProvider`가 이 변경을 감지하고 `PageView`를 해당 페이지로 점프(`jumpToPage`)시킵니다. 반대로 사용자가 페이지를 스와이프하면 `onPageChanged` 콜백이 `currentPageIndexProvider`를 새로운 페이지 번호로 업데이트하여 상태를 동기화합니다.

---

### ## 전체 흐름 예시 (A-a → B-b → A-a) 🚶

1.  사용자가 노트 **A**의 **a** 페이지에 있습니다.
    - `currentPageIndexProvider(A)`는 `a`입니다.
2.  노트 **B**로 가는 링크를 탭합니다.
    - 노트 **A**의 스케치를 저장합니다.
    - `resumePageIndexProvider(A)`에 `a`를 **저장**합니다.
    - 노트 **B**로 화면을 전환합니다.
3.  노트 **B**의 편집기가 새로 생성됩니다. (노트 A의 편집기는 파기됨)
4.  노트 **B**에서 뒤로 가기를 누릅니다.
    - 노트 **B**의 스케치를 저장합니다.
    - `resumePageIndexProvider(B)`에 현재 페이지 `b`를 **저장**합니다. (나중에 B로 돌아올 때를 대비)
5.  노트 **A**의 편집기가 다시 새로 생성됩니다.
    - 첫 프레임이 그려진 후, `resumePageIndexProvider(A)`에 저장된 `a`를 읽어와 `currentPageIndexProvider(A)`를 `a`로 **복원**합니다.
    - `PageController`가 이 변경을 보고 `a` 페이지로 점프합니다.

---

### ## 핵심 개념 요약 🔑

- **`maintainState=false`**: 화면 밖의 Route는 메모리에서 파기되므로, 화면보다 더 오래 유지되어야 하는 상태는 반드시 별도의 공간(프로바이더 등)에 저장해야 합니다.
- **프로바이더 쓰기 안전성**: 위젯 트리가 빌드되는 중(특히 Route 생명주기 콜백)에는 프로바이더의 상태를 변경하면 안 됩니다. 사용자 이벤트 핸들러나 `post-frame` 콜백을 사용해야 합니다.
- **책임 분리**:
  - `resumePageIndexProvider`: 화면을 넘나드는 **장기 기억** (어디로 돌아갈지)
  - `currentPageIndexProvider`: 편집기 내의 **실시간 상태** (지금 어느 페이지인지)
  - `pageControllerProvider`: 실시간 상태를 실제 **UI 액션**으로 변환
