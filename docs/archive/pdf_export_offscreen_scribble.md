# PDF 내보내기(Offscreen Scribble Render) 설계서

작성일: 2025-09-01
작성자: 팀 tryCatchPing
상태: 제안(Implementable)

## 1. 배경 & 문제 요약
- 현재 PDF 내보내기는 `ScribbleNotifier.renderImage()`를 사용함. 이 메서드는 내부적으로 `repaintBoundaryKey.currentContext?.findRenderObject()`를 통해 `RenderRepaintBoundary`를 찾아 `toImage()`를 호출.
- PageView 구조상 “현재 보이는 페이지”만 RenderObject가 존재/페인트됨. 비가시(오프스크린) 페이지는 `renderImage()` 호출 시 `no valid RenderObject` 예외 발생.
- PDF 배경이 있는 경우에도 합성 자체는 정상이나, iPad 공유 시 `sharePositionOrigin` 미지정으로 팝오버 앵커 오류가 발생.

결론: 모든 페이지에 대해 RenderObject를 확보한 뒤 `renderImage()`를 호출할 수 있는 “숨김(Offscreen/Overlay) 렌더링” 경로가 필요.

## 2. 목표(Goals) / 비목표(Non‑Goals)
- 목표
  - 화면과 “완전히 동일한” 스케치 모양(필압/시뮬레이션/하이라이터 포함)으로 모든 페이지를 이미지화하여 PDF로 내보내기.
  - 내보내기 중 UI는 고정(사용자 인터랙션 차단), 진행률 표시.
  - 단일 고품질 프로파일만 지원(옵션 없음). 픽셀 비율 `exportScale = 4.0` 고정.
  - iPad 공유 오류 제거(팝오버 앵커 지정).
- 비목표
  - 벡터 PDF(Perfect Freehand Path 직결) 구현은 이번 범위에 포함하지 않음.
  - 성능 최적화/메모리 튜닝은 2차 과제로 후속.

## 3. 요구사항(Functional)
- F1. 페이지별로 배경(PDF에서 프리렌더된 JPG) + 스케치 이미지를 합성하여 최종 PNG 생성.
- F2. 스케치 이미지는 `Scribble` 위젯의 엔진을 그대로 사용한 `renderImage(pixelRatio: 4.0)` 결과여야 함(동일도 보장).
- F3. 화면이 변하거나 깜빡이지 않아야 함(Overlay에 숨김으로 마운트, Opacity 0.0).
- F4. 진행률(페이지 n/m) 갱신, 오류 발생 시 해당 페이지만 폴백(배경만 또는 에러 플레이스홀더) 처리.
- F5. iPad 공유 시 `sharePositionOrigin` 지정.

## 4. 제약사항 & 주요 결정
- C1. `Offstage(offstage: true)`나 `Visibility(visible: false)`는 페인트를 생략할 수 있어 안전하지 않음. RenderObject가 있어도 최신 페인트가 없으면 `toImage()` 품질/성공 보장이 안 됨.
  - 결정: `Opacity(opacity: 0.0)` + `IgnorePointer`를 사용해 레이아웃/페인트는 수행하되 사용자에게 보이지 않게 유지.
- C2. `renderImage()`는 RepaintBoundary가 “페인트 완료” 상태여야 동작.
  - 결정: Overlay 삽입 후 `WidgetsBinding.instance.endOfFrame`를 1~2회 기다린 뒤 호출. 실패 시 1회 재시도.
- C3. 단일 프로파일, 고정 스케일.
  - 결정: `exportScale = 4.0`.

## 5. 설계 개요(Architecture)
- 상위 오케스트레이터: `PdfExportService`(기존)에서 “페이지 이미지 생성 단계”만 교체/위임.
- 숨김 렌더러: `OffscreenScribbleRenderer`(신규) – Overlay에 임시로 Scribble을 마운트해 `renderImage()`를 안정적으로 호출하는 유틸.
- 합성기: `PageImageComposer`(기존) 활용 또는 `PageRasterComposer`(신규)로 배경+스케치 PNG 합성.

### 5.1 컴포넌트 책임
- PdfExportService
  - 페이지 필터링, 진행률/로그, PDF 페이지 생성/저장/공유(앵커 포함).
  - 각 페이지에 대해 `OffscreenScribbleRenderer.renderScribblePng(...)` → `Composer.compose(...)` → `pdf.addPage(...)`.
- OffscreenScribbleRenderer(신규)
  - Overlay에 숨김 Scribble 위젯을 삽입 → 프레임 대기 → `notifier.renderImage()` 호출 → PNG(ByteData) 반환 → Overlay 제거.
- Composer(기존/신규)
  - 배경 JPG 디코드(target 크기) + 스케치 PNG를 `dart:ui` Canvas에서 합성 → 최종 PNG 반환. PNG 유효성 검사 수행.

## 6. 상세 동작 흐름(Per Page)
1) 입력 준비
- `NotePageModel page`(drawingAreaWidth/Height, 배경 프리렌더 경로 등)
- 스케치 소스
  - 안전안을 위해 “렌더 전 저장” 수행: `pageNotifiers.values.forEach((n) => n.saveSketch())`(선택). 또는 `NotePageModel`의 최신 `jsonData`를 신뢰.
- 시뮬레이트 필압 여부: Provider에서 노트별 설정 읽기.

2) 숨김 Scribble 마운트
- OverlayEntry 생성:
  - `IgnorePointer(
       child: Opacity(
         opacity: 0.0,
         child: Center(
           child: SizedBox(
             width: page.drawingAreaWidth,
             height: page.drawingAreaHeight,
             child: Scribble(
               notifier: <렌더용 Notifier>,
               simulatePressure: <provider 값>,
             ),
           ),
         ),
       ),
     )`
- 두 가지 방식 중 선택:
  - A) 렌더 전용 임시 Notifier(권장): `CustomScribbleNotifier`를 새로 만들고 `setSketch(page.toSketch())`로 상태 주입. 화면의 Notifier와 키 충돌이 없음.
  - B) 화면의 라이브 Notifier 재사용: Overlay Scribble이 “키를 덮어써서” renderImage 대상으로 됨. 제거 시 on-screen Scribble의 키 복구 타이밍 이슈가 있어 A 권장.

3) 프레임 대기 & 확인
- `await endOfFrame` 1~2회.
- 안전 확인:
  - `notifier.renderImage()` 호출 try/catch. 실패 시 한 프레임 추가 대기 후 1회 재시도.

4) 스케치 PNG 획득
- `ByteData png = await notifier.renderImage(pixelRatio: 4.0, format: PNG)`
- 바이트 배열로 변환 후 `instantiateImageCodec(bytes)`로 유효성 검사.

5) 배경 합성
- `instantiateImageCodec(page.preRenderedImagePath, targetWidth: targetW, targetHeight: targetH)`로 디코드.
- `PictureRecorder` + `Canvas(targetW, targetH)`
  - 흰색 배경 → 배경 JPG drawImageRect → 스케치 PNG drawImageRect.
- 최종 PNG(ByteData) 생성 및 유효성 재검사.

6) Overlay 제거
- OverlayEntry.remove() → `await endOfFrame`.

7) PDF 페이지 추가
- `PdfPageFormat(pageWidth*0.75, pageHeight*0.75)`
- `pw.Image(pw.MemoryImage(finalPng), fit: pw.BoxFit.fill)`

8) 진행률/로그 갱신

## 7. API/인터페이스(제안)

```dart
/// 숨김 Scribble 렌더링 유틸
class OffscreenScribbleRenderer {
  /// overlayContext: 보통 모달의 BuildContext(Overlay가 존재해야 함)
  /// width/height: page.drawingAreaWidth/Height
  static Future<Uint8List> renderScribblePng({
    required BuildContext overlayContext,
    required ScribbleNotifier notifier,
    required double width,
    required double height,
    double pixelRatio = 4.0,
    required bool simulatePressure,
    int frameWaitCount = 2, // 안정성 위해 기본 2프레임 대기
  });
}

/// 배경 + 스케치 합성기
class PageRasterComposer {
  static Future<Uint8List> compose({
    required Uint8List? backgroundJpgBytes, // 없으면 흰 배경
    required Uint8List? sketchPngBytes,     // 없으면 배경만
    required int targetWidth,
    required int targetHeight,
  });
}

/// PDF 내보내기(상위) – 기존 PdfExportService에 통합
Future<Uint8List> exportNoteToPdf(
  NoteModel note,
  Map<String, ScribbleNotifier> pageNotifiers, {
  required BuildContext overlayContext,  // iPad 공유 앵커도 여기서 구함
});
```

주의: 렌더 전용 Notifier 방식(A)을 택할 경우 `pageNotifiers` 대신 `NotePageModel`만 전달해도 됨. 다만 현재 구조를 최소 변경하려면 `pageNotifiers`는 유지하되, 렌더러 내부에서 “임시 Notifier 생성” 옵션을 제공.

## 8. iPad 공유(팝오버 앵커)
- 원인: iPad는 `sharePositionOrigin`가 필수. 미지정 시 `PlatformException(... must be non-zero ...)`.
- 해결: 모달의 버튼 `BuildContext` 기준으로 `RenderBox box = context.findRenderObject() as RenderBox` → `Rect origin = box.localToGlobal(Offset.zero) & box.size` 계산 → `Share.shareXFiles(..., sharePositionOrigin: origin)`.
- 실패 시 안전 기본값: 화면 중앙의 작은 rect.

## 9. 로깅 & 오류 처리
- 페이지 시작/종료 로그, 배경 파일 존재/사이즈, 디코드 성공(w×h), `renderImage` 성공/실패, 재시도 여부, 최종 PNG 유효성 체크 결과, PDF 페이지 포맷(pt), 최종 PDF 크기.
- 실패 정책:
  - `renderImage` 1회 재시도 후 실패 → 배경만 사용(경고).
  - 배경 디코드 실패 → 흰 배경 + 스케치만.
  - 합성 PNG 유효성 실패 → 오류 플레이스홀더(크기 동일)로 대체.

## 10. 성능/메모리 고려(이번 범위의 가이드)
- 순차 처리(페이지 단위), 각 단계 후 `image.dispose()` 호출.
- 배경 JPG 디코드 시 `targetWidth/Height` 지정으로 메모리 사용 억제.
- 5페이지마다 GC 힌트 로그만 남김(실제 GC는 VM에 위임).

## 11. 리스크 & 대응
- R1. 라이브 Notifier 재사용 시 키 덮어쓰기로 on-screen Scribble이 일시적으로 키를 잃을 수 있음.
  - 대응: A안(렌더 전용 Notifier) 채택 권장.
- R2. 프레임 타이밍으로 첫 시도 실패 가능.
  - 대응: 1프레임 추가 대기 후 재시도.
- R3. iPad 공유 팝오버 앵커 누락.
  - 대응: 반드시 origin Rect 계산 후 전달.

## 12. 단계적 롤아웃 계획
- Phase 1: 렌더 전용 Notifier + Overlay 숨김 렌더러 구현, 배경 합성/유효성 검증, iPad 공유 앵커.
- Phase 2: 코드 정리, 로깅 개선, 에러 UI/취소.
- Phase 3(선택): 성능/메모리 최적화, 품질 옵션 추가.

## 13. 테스트 계획
- 단일/다중 페이지(배경 유/무) 케이스로 내보내기.
- 가시/비가시 페이지 모두 동일 성공 확인(더 이상 RenderObject 오류 없음).
- 스케치 동일도: 가시 페이지에서 `renderImage(4.0)` 결과와 offscreen 결과 픽셀 비교(~안티앨리어싱 1px 이내).
- iPad 공유: 실제 장비/시뮬레이터에서 팝오버 정상 동작.
- 에지: 배경 파일 없음/손상, 0/NaN 크기 가드, 재시도 로직.

## 14. 구현 노트(요약)
- 숨김은 `Opacity(0.0)` 사용, `Offstage(true)`는 지양.
- `endOfFrame`를 최소 1~2회 대기 후 `renderImage()` 호출.
- 렌더 전용 Notifier를 권장(키 충돌 회피).
- `exportScale = 4.0` 고정.
- PDF 페이지 크기: `px * 0.75` pt.
- iPad 공유 시 `sharePositionOrigin` 필수.

---
본 문서는 “Scribble 엔진을 그대로 활용한 오프스크린 렌더링”으로 화면과 동일한 품질을 보장하면서, PageView 오프스크린 문제를 해결하기 위한 구현 가이드를 제공합니다. 위 설계대로 구현 후, PDF가 열리지 않는 문제는 공유 앵커 지정으로 제거되며, 비가시 페이지 렌더 실패도 사라집니다.
