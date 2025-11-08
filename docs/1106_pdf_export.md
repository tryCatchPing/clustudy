# pdf 내보내기를 처음부터 구현하자

노트 페이지 - 페이지 관리
페이지 관리 화면에서 'PDF 내보내기' 버튼을 통해 현재 필기중인 노트를 내보내자.

- scribble 의 `ScribbleNotifier.renderCurrentSketchOffscreen()` 사용
- 현재 노트 pages 의 모든 page 별 notifier 에 대해 `renderCurrentSketchOffscreen` 실행
- 현재 노트 pages 의 모든 paeg 별 배경
  - 빈 배경인 경우 (pdf 아님) `renderCurrentSketchOffscreen` 파라미터 `backgroundColor`에 현재 색상을 넣어 PNG 획득
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
- 새로운 render 함수(`renderCurrentSketchOffscreen`) 사용해서 내보내기 구현. 현재 `.dart_tool/package_config.json`이 `/Users/taeung/.pub-cache/git/scribble-89708a97c7f223d00646f055255740e2d7232138` 커밋을 바라보고 있어 동일 API가 이미 포함되어 있다(다른 환경이라면 git ref/path를 맞춘 뒤 `fvm flutter pub get`).
- 노트 생성 시 pdf 배경 이미지는 모두 저장되어있어. 이건 네가 찾아봐 나도 기억이 안나.
- pdf_export_offscreen_scribble.dart 파일에서는 render 함수가 없을 때를 이야기하는거라 렌더링 및 저장 방식은 모두 무시해야해
- 모달 창에서 pdf 저장 / 공유 를 누른 경우 전체 화면 뒤로가기 금지 (1차 목표는 취소 불가) + 스크린 lock(?) 진행
- 모달 창에서 일단은 진행률 보여주지 말자. 구현 쉬우면 하는데 아니면 그냥 하지 말고
- 모든 페이지 내보내기만 일단 구현 (전 범위)
- 모든 단계 로그 추가 필요
- 안드로이드 내보내기만 고려
- 로컬 저장은 지원하지 않고, 내보내기 버튼은 곧바로 공유 시트를 띄운다.
- 실패 시 그냥 진행중 작업 삭제하고 하단 error spec 으로 실패 원인 띄우기 (자동 재시도 없음)
- 유닛 테스트 작성이 가능할까.. 그냥 내가 실 기기로 테스트 하는게 나을듯 (로그 적어주면 그거 보고 판단)
- pdfexportservice 는 무시하는게 좋음. 새로 아얘 새로 기획하는거.
- `renderCurrentSketchOffscreen()`이 `Future<ByteData>`를 바로 리턴하므로 ByteData→PNG 변환 경로만 구현하면 된다.

## 구현 전 확인

- `.dart_tool/package_config.json` 상 `scribble` root: `file:///Users/taeung/.pub-cache/git/scribble-89708a97c7f223d00646f055255740e2d7232138/`. 이 커밋의 `lib/src/view/notifier/scribble_notifier.dart:201`에 `Future<ByteData> renderCurrentSketchOffscreen({ ... })`가 구현되어 있다.
- 이 함수는 현재 스케치를 스냅샷 떠서 `renderSketchOffscreen`으로 넘기는 래퍼라 위젯이 마운트되어 있지 않아도 PNG(ByteData)를 얻을 수 있다.
- 호출 전에는 현재 활성 스트로크가 있으면 Scribble 측에서 자동으로 커밋되도록 한 프레임 대기하거나, UI 상에서 입력을 멈춘 상태에서 실행해야 한다. `size/pixelRatio/backgroundColor/simulatePressure` 값은 노트 페이지 스펙과 일치시킨다.

## MVP 구현 방침 (Android only)

### UX 흐름

- 진입점: `page_controller_screen.dart` 상단 툴바 `PDF 내보내기` 버튼.
- 버튼 → 모달(`DesignSystem` BottomSheet) 노출 → `내보내기` 선택 시 즉시 모달 내 버튼 비활성 + 전역 `WillPopScope`/`ModalBarrier`로 뒤로가기 차단.
- 진행률/취소 UI 없음. 성공 시 스낵바 + 저장 경로 텍스트, 실패 시 모달 내 error spec 그대로 출력.

### 서비스 구조

- `PdfExportMvpService` (신규) 하나로 단순 구성.
    1. `NoteModel`에서 페이지 ID·캔버스 크기·배경 타입 수집. Riverpod에서는 `notePageNotifiersProvider`(`lib/features/canvas/providers/note_editor_provider.dart`)로 각 페이지의 `CustomScribbleNotifier` 맵을 받아 서비스에 주입.
  2. 페이지별 `renderCurrentSketchOffscreen` 호출: `size = Size(pageWidth, pageHeight)`, `pixelRatio = 4.0`, `simulatePressure`는 현재 설정, `backgroundColor`는 배경 종류에 따라 주입. 반환된 `ByteData`는 즉시 `Uint8List`로 변환.
  3. 배경:
     - 비 PDF: 배경 색을 `renderCurrentSketchOffscreen` 파라미터로 넣으면 결과 PNG에 이미 색이 깔리므로 추가 합성 없이 바로 사용.
     - PDF: 노트 생성 시 디스크에 저장된 JPG 경로를 `NotePageModel.backgroundImagePath`(실제 필드명 TBD)에서 얻고, `ui.decodeImageFromList`로 로드. 경로 없거나 파일 누락 시 즉시 실패.
  4. 합성: PDF 배경이 있을 때만 `ui.PictureRecorder`로 배경 JPG + 스케치 PNG를 합성, 없으면 2단계 결과 PNG 사용.
  5. PDF 작성: `package:pdf` 사용, 단일 프로필(A4) 고정. 픽셀(pt) 변환은 `pixels * 0.75`.
  6. 저장: `getTemporaryDirectory()/pdf_exports/<noteTitle>_yyyyMMdd_HHmmss.pdf`에 임시 파일 작성.
  7. 공유: `Share.shareXFiles`로 외부 공유 시트 호출. 공유 완료/취소 후 임시 파일 삭제.
  8. 결과 `ExportResult(path, pageCount, duration)` 리턴(경로는 내부 임시 경로).
- 공유만 허용(내장 저장소 저장 제외). 공유 시트에서 사용자가 원하는 앱·폴더로 옮긴다.
- 렌더링은 완전 직렬(페이지 순차)로 고정. 성능 튜닝은 추후 과제로 미룬다.

### 데이터/파일 정책

- 파일은 `getTemporaryDirectory()/pdf_exports` 등 앱 임시 디렉터리에만 저장한다. 공유 Future 완료 직후(성공/취소 불문) 즉시 삭제한다.
- PDF 배경 페이지에서 경로가 없거나 파일이 없으면 즉시 실패 처리 후 temp 파일 삭제.
- 외부 저장소 권한/MediaStore 접근은 사용하지 않는다.

### 에러/로그 전략

- 각 페이지마다 `logger.i('[pdf-export]: page=$index render start')`, 성공/실패, 배경 로드 결과 기록.
- 실패 정책: 첫 에러 발생 시 즉시 중단 → 이미 생성한 temp 파일 삭제 → UI에 사유(code + 메시지) 노출.
- 공유 Future 결과(성공/취소/실패)도 로그로 남긴다.
- 로그 태그 공통: `pdf-export-mvp`. 에러는 `logger.e`.
- UI 에러 표시는 `AppErrorSpec`(`lib/shared/errors/app_error_spec.dart`) 규격으로 노출.

### 테스트/검증

- 자동 테스트는 `PdfExportMvpService`를 `renderCurrentSketchOffscreen`/배경 로더 mock으로 감싼 단위 테스트 1~2개만 작성(입력→PDF writer 호출 여부).
- 최종 품질은 실제 안드로이드 기기에서 로그 확인 + 출력 파일 육안 검수. QA 체크리스트: 단일/다중 페이지, PDF/빈 배경 각 1회.
