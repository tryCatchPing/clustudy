# pdf 내보내기를 처음부터 구현하자

노트 페이지 - 페이지 관리
페이지 관리 화면에서 'PDF 내보내기' 버튼을 통해 현재 필기중인 노트를 내보내자.

- scribble 의 renderSketchOffscreen 함수 사용
- 현재 노트 pages 의 모든 page 별 notifier 에 대해 renderSketchOffscreen 사용
- 현재 노트 pages 의 모든 paeg 별 배경
  - 빈 배경인 경우 (pdf 아님) renderSketchOffscreen 파라미터로 현재 배경 색 전달 후 완성
  - pdf 배경인 경우 'pdf 노트' 생성 시 이미 저장(렌더링?)된 이미지 배경 가져오기
- 배경과 render함수로 받아온 이미지(?) 합성
  - 빈 배경인 경우 앞서 배경 색 포함해 렌더했다면 완성된 상태이므로 무시해도 되겠다
  - pdf 배경인 경우 합성 진행
- 모든 합성된 pages를 합쳐 하나의 pdf 로 합치기
- 공유 / 저장 옵션 제공

- 래스터 pdf 가 제작되므로.. 렌더링 품질을 선택할 수 있는게 좋겠으나 일단 기술 복잡도를 줄이기 위해 높은 화질로 내보내자 일단. 따로 옵션 제공 안함
- 노트 제목은 현재 노트 제목으로
- 링크가 존재하는 경우 링크는 제외하고 내보내기 (추후 뭐 링크 직사각형까지 렌더링 할 수 있겠으나 지금은 아님)
- 최대한 MVP 중 하나인 PDF 내보내기를 가능하게 만드는게 목표이므로 최대한 단순하게 가자

- pdf 내보내기 모달창 만들기. 디자인 컴포넌트 무조건 참고해서 제작
- 서비스도 제작해야겠네

## 추가

- `page_controller_screen.dart` 파일의 상단 툴바에 버튼
- 버튼 누르면 내보내기 모달 창 나온다
- 기존 파이프라인 재사용안하고 폐기
- 새로운 render 함수 (내가 추가했어 패키지에) 사용해서 내보내기 구현
- 노트 생성 시 pdf 배경 이미지는 모두 저장되어있어. 이건 네가 찾아봐 나도 기억이 안나.
- pdf_export_offscreen_scribble.dart 파일에서는 render 함수가 없을 때를 이야기하는거라 렌더링 및 저장 방식은 모두 무시해야해
- 모달 창에서 pdf 저장 / 공유 를 누른 경우 전체 화면 뒤로가기 금지 (1차 목표는 취소 불가) + 스크린 lock(?) 진행
- 모달 창에서 일단은 진행률 보여주지 말자. 구현 쉬우면 하는데 아니면 그냥 하지 말고
- 모든 페이지 내보내기만 일단 구현 (전 범위)
- 모든 단계 로그 추가 필요
- 안드로이드 내보내기만 고려
- 로컬 저장만 일단 고려
- 실패 시 그냥 진행중 작업 삭제하고 하단 error spec 으로 실패 원인 띄우기 (자동 재시도 없음)
- 유닛 테스트 작성이 가능할까.. 그냥 내가 실 기기로 테스트 하는게 나을듯 (로그 적어주면 그거 보고 판단)
- pdfexportservice 는 무시하는게 좋음. 새로 아얘 새로 기획하는거.
- renderSketchOffscreen 함수 뭐 리턴하는지 확인하고 진행해라. 해당 패키지에서 정상 동작하는거 화인했다.

## MVP 구현 방침 (Android only)

### UX 흐름

- 진입점: `page_controller_screen.dart` 상단 툴바 `PDF 내보내기` 버튼.
- 버튼 → 모달(`DesignSystem` BottomSheet) 노출 → `내보내기` 선택 시 즉시 모달 내 버튼 비활성 + 전역 `WillPopScope`/`ModalBarrier`로 뒤로가기 차단.
- 진행률/취소 UI 없음. 성공 시 스낵바 + 저장 경로 텍스트, 실패 시 모달 내 error spec 그대로 출력.

### 서비스 구조

- `PdfExportMvpService` (신규) 하나로 단순 구성.
  1. `NoteModel`에서 페이지 ID·캔버스 크기·배경 타입 수집. Riverpod에서는 `notePageNotifiersProvider`(`lib/features/canvas/providers/note_editor_provider.dart`)로 각 페이지의 `CustomScribbleNotifier` 맵을 받아 서비스에 주입.
  2. 페이지별 `renderSketchOffscreen` 호출. 이 함수는 `Future<Uint8List>`(PNG) 반환 확인함. 호출 전 각 페이지 notifier에 `flushPendingStrokes()`만 호출하고, 프레임 지연 로직은 패키지에서 처리된다고 가정.
  3. 배경:
     - 비 PDF: `renderSketchOffscreen` 파라미터 `backgroundColor`에 현재 색상을 넣어 완성 PNG만 사용. 배경 경로 개념이 없으므로 null이면 즉시 실패 → 워크플로 중단.
     - PDF: 노트 생성 시 디스크에 저장된 JPG 경로를 `NotePageModel.backgroundImagePath`(실제 필드명 TBD)에서 얻고, `ui.decodeImageFromList`로 로드. 경로 없거나 파일 누락 시 즉시 실패.
  4. 합성: `ui.PictureRecorder` + `Canvas`로 배경 → 스케치 순서로 그려 `Uint8List` PNG 반환.
  5. PDF 작성: `package:pdf` 사용, 단일 프로필(A4) 고정. 픽셀(pt) 변환은 `pixels * 0.75`.
  6. 저장: Android `Downloads/Clustudy` 폴더를 기본 경로로 사용(없으면 생성). `getDownloadsDirectory()` 미지원 시 `path_provider_android`로 `Environment.DIRECTORY_DOWNLOADS`를 직접 호출.
  7. 결과 `ExportResult(path, pageCount, duration)` 리턴.
- 안드로이드 공유 무시. 저장만 하고 사용자에게 경로 텍스트와 `open file` 버튼 정도 제공.
- 렌더링은 완전 직렬(페이지 순차)로 고정. 성능 튜닝은 추후 과제로 미룬다.

### 데이터/파일 정책

- 저장 경로: `Downloads/Clustudy` 고정. 동일 파일명이 이미 있으면 `_1`, `_2` 꼬리표를 붙여 충돌 회피.
- PDF 배경 페이지에서 경로가 없거나 파일이 없으면 즉시 실패 처리 후 temp 파일 삭제.
- 공용 폴더를 쓰므로 Android 13 이하에서는 WRITE_EXTERNAL_STORAGE 권한 체크, 13+에서는 MediaStore ACTION_CREATE_DOCUMENT 없이 앱 고유 Downloads 하위 경로를 사용.

### 에러/로그 전략

- 각 페이지마다 `logger.i('[pdf-export]: page=$index render start')`, 성공/실패, 배경 로드 결과 기록.
- 실패 정책: 첫 에러 발생 시 즉시 중단 → 이미 생성한 temp 파일 삭제 → UI에 사유(code + 메시지) 노출.
- 로그 태그 공통: `pdf-export-mvp`. 에러는 `logger.e`.
- UI 에러 표시는 `AppErrorSpec`(`lib/shared/errors/app_error_spec.dart`) 규격으로 노출.

### 테스트/검증

- 자동 테스트는 `PdfExportMvpService`를 `renderSketchOffscreen`/배경 로더 mock으로 감싼 단위 테스트 1~2개만 작성(입력→PDF writer 호출 여부).
- 최종 품질은 실제 안드로이드 기기에서 로그 확인 + 출력 파일 육안 검수. QA 체크리스트: 단일/다중 페이지, PDF/빈 배경 각 1회.
