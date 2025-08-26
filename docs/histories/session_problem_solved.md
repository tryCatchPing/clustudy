문제 해결 과정 요약

1. 최초 문제 발생: StateError: Bad state

- 현상: 노트 편집 화면으로 이동할 때 Bad state: No note session for pageId라는 오류와 함께 앱이 중단되었습니다.
- 원인: 노트 편집 화면의 특정 위젯(NoteEditorPointerMode)이 canvasPageNotifier라는 Provider를 사용하는데, 이 Provider는 현재 활성화된 노트
  세션(noteSessionProvider)에 의존합니다. 하지만 화면이 빌드되는 시점에 이 세션 값이 null이어서 오류가 발생했습니다.

2. 1차 진단 및 해결 시도: 경로 감지 리스너의 경쟁 상태 (Race Condition)

- 기술적 분석: 처음에는 세션 관리가 go_router의 경로 변경을 감지하는 리스너(addListener)를 통해 자동으로 이루어지고 있었습니다. 이 리스너는 경로가
  변경되면 noteSessionProvider의 상태를 업데이트하는 방식이었습니다. 하지만 이 업데이트 로직에 Future()를 사용한 미세한 지연이 있었고, 이 지연 시간보다
  위젯 트리가 먼저 빌드되면서 세션이 설정되지 않은 상태로 접근하는 경쟁 상태(Race Condition)가 문제의 원인이라고 추측했습니다.
- 시도: 세션이 준비될 때까지 로딩 화면을 보여주도록 NoteEditorScreen을 수정했습니다.
- 결과: 무한 로딩에 빠졌습니다. 이는 경쟁 상태가 문제가 아니라, 세션 자체가 아예 설정되지 않고 있음을 의미했습니다.

3. 2차 진단 및 해결 시도: 부정확한 경로 정보 및 Provider 수정 시점 오류

- 기술적 분석: 로그를 재분석한 결과, go_router의 리스너가 경로 변경을 감지하기는 하지만, 라우터의 내부 상태가 완전히 업데이트되기 전에 호출되어
  부정확한(stale) 이전 경로 정보를 전달하는 것을 확인했습니다. 이로 인해 세션 설정 로직이 아예 트리거되지 않았습니다.
- 시도 1: 잘못된 리스너 로직을 제거하고, GoRoute의 builder 콜백 안에서 직접 세션을 설정하도록 변경했습니다.
- 결과: Tried to modify a provider while the widget tree was building 오류가 발생했습니다. 이는 Flutter/Riverpod의 핵심 규칙으로, 위젯의 `build` 메서드
  내에서는 Provider의 상태를 변경할 수 없다는 것을 의미합니다.
- 시도 2: Provider 상태 변경은 build 메서드가 아닌, 버튼 클릭과 같은 사용자 이벤트 콜백에서 수행하는 것이 올바른 아키텍처입니다. 따라서 노트 목록
  화면(note_list_screen.dart)에서 노트 아이템을 탭하는 onTap 콜백으로 세션 설정 로직(enterNote)을 이동시켰습니다. 즉, 화면을 이동하기 직전에 세션을 먼저
  설정하도록 변경했습니다.
- 결과: 아키텍처상 올바른 수정이었음에도 불구하고, 다시 최초의 Bad state: No note session 오류가 발생했습니다.

4. 최종 원인 규명 및 해결: Provider의 autoDispose 동작

- 기술적 분석: 로그를 통해 onTap에서 세션이 분명히 설정되었음에도, 다음 화면에서는 그 값이 null이 되는 미스터리한 현상을 확인했습니다. 이는 Riverpod
  Provider의 `autoDispose` 기본 동작 때문이었습니다.
  - noteSessionProvider는 앱의 전역적인 상태임에도 불구하고, 화면이 전환되는 짧은 순간 동안 이 Provider를 watch(구독)하는 위젯이 하나도 없었습니다.
    (onTap에서는 ref.read를 사용했으므로 구독이 발생하지 않음)
  - Riverpod는 기본적으로 구독자가 없는 Provider를 메모리 절약을 위해 자동으로 파기(autoDispose)합니다.
  - 따라서 onTap에서 설정된 세션 상태는 화면 전환 중에 파기되었고, 노트 편집 화면에서는 초기값인 null로 새로 생성된 Provider에 접근하게 되어 오류가
    발생한 것입니다.
- 최종 해결: note_editor_provider.dart 파일에서 noteSessionProvider의 어노테이션을 @riverpod에서 `@Riverpod(keepAlive: true)`로 수정했습니다. 이 설정은
  Provider의 구독 여부와 관계없이 앱이 실행되는 동안 상태를 계속 유지하도록 하여, 화면 전환 중에도 세션 정보가 파기되지 않도록 보장합니다.

이 수정을 통해 마침내 문제가 해결되었습니다.
