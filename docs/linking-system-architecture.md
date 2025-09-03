# Linking System Architecture Guide

본 문서는 노트/페이지 간 링크 시스템의 최종 설계안을 정리합니다. 메모리 구현으로 시작해 Isar 기반 영속 저장으로 자연스럽게 확장되며, UI는 Provider 스트림을 통해 변경에 반응하도록 설계합니다. Obsidian 스타일의 백링크/그래프 뷰까지 확장 가능한 구조를 목표로 합니다.

## 1) 목표와 범위

- 목표: 링크 생성·저장·조회·네비게이션과 백링크/연관 노트/그래프 뷰를 지원하는 일관된 데이터 흐름 제공
- 범위: 데이터 모델, 저장소(Repository), Provider, UI 플로우, 일관성 규칙, 성능/확장성
- 비범위: 실제 그래프 레이아웃/렌더링 구현(추후 단계), 외부 동기화/협업

## 2) 상위 구조(레이어)

- UI(Widgets)
  - 캔버스 페이지, 사이드바(Outgoing/Backlinks), 그래프 뷰
- Providers(Riverpod)
  - 관찰(Streams) 중심. 페이지/노트별 링크 목록과 파생 데이터(히트 테스트, 코시테이션, 그래프)
- Services(선택)
  - 생성/수정/삭제 Orchestration, 유효성 검사, 트랜잭션 단위 조정
- Repositories(Interfaces)
  - LinkRepository: 저장소 추상화. 인메모리 → Isar 교체 가능
- Data stores
  - Memory 구현(개발/프로토타입)
  - Isar 구현(영속 저장, 인덱스/트랜잭션)

원칙: Watch-first(스트림 기반), 도메인/엔티티 분리, 페이지 로컬 좌표, 느슨한 결합

## 3) 데이터 모델

### 3.1 LinkModel (도메인)

- 식별자
  - `id: String` (UUID v4)
  - `sourceNoteId: String`
  - `sourcePageId: String`
- 대상
  - `targetNoteId?: String`
  - `targetPageId?: String`
  - `url?: String`
- 표현/앵커
  - `bbox: { left: double, top: double, width: double, height: double }` (페이지 로컬 좌표)
  - `label?: String` (표시명 오버라이드; 없으면 대상 제목으로 계산)
  - `anchorText?: String` (선택 영역 키워드/문맥; 선택사항)
- 메타
  - `createdAt: DateTime`, `updatedAt: DateTime`

설명: 하나의 LinkModel로 “링크를 건 페이지(Source)”와 “링크 대상(Target)”이 명확히 연결됩니다. 동일 대상(예: A)을 가리키는 여러 링크(B→A, C→A)는 공통 타깃을 통해 B–C 연관(코시테이션)을 계산할 수 있습니다.

### 3.2 NoteModel / NotePageModel (도메인)

- 기존 구조 유지(노트/페이지의 스케치/배경 중심)
- 링크 리스트는 임베드하지 않음(별도 컬렉션로 분리). 필요 시 `pageId`/`noteId` 키로 LinkRepository에서 조회

### 3.3 좌표계

- `bbox`는 페이지 로컬 좌표로 저장합니다.
- `scaleFactor`는 1.0 고정(현재 scribble 커스텀 설정과 일치). InteractiveViewer의 확대/축소는 시각적 처리만 담당합니다.

## 4) 저장소(Repository)

### 4.1 LinkRepository (인터페이스)

```dart
abstract class LinkRepository {
  Stream<List<LinkModel>> watchByPage(String pageId);      // Outgoing
  Stream<List<LinkModel>> watchBacklinksToPage(String pageId);
  Stream<List<LinkModel>> watchBacklinksToNote(String noteId);

  Future<void> create(LinkModel link);
  Future<void> update(LinkModel link);
  Future<void> delete(String linkId);
}
```

일관성: create/update 시 source/target 유효성은 서비스 계층에서 Note/NotePage를 조회해 검증합니다.

### 4.2 Memory 구현 (개발 초기)

- 내부 구조: `Map<String /*pageId*/, List<LinkModel>>` (source 인덱스)
- 역인덱스: `Map<String /*noteId*/, Set<String /*linkId*/>>` / `Map<String /*pageId*/, Set<linkId>>` (target 인덱스)
- 스트림: pageId/target 단위의 `StreamController`를 보유해 변화만 브로드캐스트

### 4.3 Isar 구현 (영속)

- `LinkEntity @collection`
  - 필드: 도메인과 동일 + Isar 내부 Id(optional)
  - 인덱스: `sourcePageId`, `targetNoteId`, `targetPageId` (조회/백링크/코시테이션 성능)
  - 선택: `IsarLink<NoteEntity>`/`IsarLink<NotePageEntity>`로 참조 + `@Backlink`(삭제 연쇄/무결성 강화)
- 스트림: `query.watch()`/`watchLazy()`를 Provider에 연결
- 트랜잭션: 링크 일괄 생성/삭제, 노트/페이지 삭제에 따른 연쇄 정리

## 5) Providers(Riverpod)

- `linksByPageProvider(pageId): StreamProvider<List<LinkModel>>` — Outgoing
- `backlinksToPageProvider(pageId): StreamProvider<List<LinkModel>>`
- `backlinksToNoteProvider(noteId): StreamProvider<List<LinkModel>>`
- `linkRectsByPageProvider(pageId): Provider<List<Rect>>` — 페인팅용 변환
- `linkAtPointProvider((pageId, Offset)): Provider<LinkModel?>` — 히트 테스트
- Orchestration
  - `LinkCreationController`: 생성/검증/저장
  - `LinkEditingController`: 수정/삭제

UI는 Provider만 watch하며, repo 직접 get 호출은 지양합니다(불필요한 IO/리빌드 방지).

## 6) UI 플로우

### 6.1 생성(Create)

1. 도구 전환: `ToolMode.linker`
2. 드래그: `LinkerGestureLayer`가 임시 `Rect`를 그리며 최소 크기 검사
3. 완료: “링크 생성” 다이얼로그 표시 — 대상(note/page/url), label/anchorText 입력
4. 저장: `LinkCreationController.create()` → `LinkRepository.create()`
5. 반영: `linksByPageProvider` 스트림 갱신 → 페인터에서 즉시 렌더

### 6.2 렌더(Render)

- 저장된 링크: `linkRectsByPageProvider(pageId)`로 항상 그리기
- 드래그 중 임시 rect: 위젯 로컬 상태에서만 표시

### 6.3 탭/네비게이션(Navigate)

- 탭 좌표 → `linkAtPointProvider`로 링크 resolve
- 대상 분기: note(첫 페이지), page(지정 페이지), url(브라우저/웹뷰)

### 6.4 편집/삭제(Edit/Delete)

- 링크 탭 → 옵션 시트 → update/delete → 스트림 갱신

### 6.5 사이드바/그래프

- 사이드바
  - Outgoing: `linksByPageProvider(pageId)`
  - Backlinks: `backlinksToNoteProvider(noteId)`(노트/페이지 단위 그룹핑, 카운트 표시)
  - Related(코시테이션): 동일 타깃을 가진 소스 노트 집합 가중치 정렬
- 그래프(Obsidian 스타일)
  - 노드: 노트(기본) 또는 페이지(옵션)
  - 엣지: 링크(B→A). 추가로 코시테이션 유도 엣지(B—C, weight=공통 타깃 수)

## 7) 관계/쿼리 정의

- Outgoing(페이지 기준): `sourcePageId = pageId`
- Backlinks(노트 기준): `targetNoteId = noteId`
- Backlinks(페이지 기준): `targetPageId = pageId`
- Co-citation(관련 노트): 동일 `targetNoteId`/`targetPageId`를 가리키는 소스 노트 집합을 그룹핑, 가중치=공통 타깃 링크 수

## 8) 일관성/삭제 정책

- 노트 삭제: `sourceNoteId==noteId` 또는 `targetNoteId==noteId` 링크 삭제
- 페이지 삭제: `sourcePageId==pageId` 또는 `targetPageId==pageId` 링크 삭제
- 트랜잭션(필수): Isar에서 일괄 처리. 메모리 구현도 배치 처리 제공
- 제목 변경: `label`이 null이면 실시간 조인으로 표시명 계산, `label`이 있으면 사용자 오버라이드 유지

## 9) 성능 고려

- 인덱스: `sourcePageId`, `targetNoteId`, `targetPageId`
- 스트림: watch 기반으로 변경 시에만 재빌드
- 페인팅: 저장된 링크 + 임시 rect 1회 렌더; 레이어 중복 최소화
- 히트 테스트: `Rect.contains`(필요 시 R-Tree/그리드로 확장)

## 10) 구현 계획(Phase)

### Phase 1 — 스키마/메모리/기본 UI

- LinkModel 정의
- LinkRepository 인터페이스 정의
- MemoryLinkRepository 구현(인덱스/스트림 포함)
- Providers 구현(links/backlinks/rects/atPoint)
- “링크 생성” 다이얼로그(기본형) + 생성/표시/탭 네비게이션 연동

### Phase 2 — 사이드바/코시테이션/미세 UX

- Backlinks 패널, Related(코시테이션) 섹션 구성
- 히트 테스트 개선(우선순위, 최소 크기/패딩)
- 링크 편집/삭제

### Phase 3 — Isar 도입

- Isar 패키지/세팅 + `LinkEntity @collection`
- 인덱스 생성 + 트랜잭션 기반 일괄 처리
- `IsarLinkRepository` 구현 및 Provider 전환

### Phase 4 — 그래프 뷰(Obsidian 스타일)

- 그래프 Provider(노드/엣지 가공) + 레이아웃/렌더링 위젯
- 필터/하이라이트/네비게이션 연동

## 11) 도입 이유

- 느슨한 결합: 링크를 별도 컬렉션으로 분리해 Note/Page 도메인을 단순 유지
- 스트림 우선: UI는 데이터 변경에만 반응 → 퍼포먼스/일관성 향상
- 확장 용이: URL/페이지/노트 대상 추가와 그래프 분석까지 데이터 모델 변경 최소화
- 트랜잭션 보장: Isar에서 일괄 처리로 정합성 강화

## 12) 사용 목적/시나리오

- 페이지의 특정 영역을 다른 노트/페이지/URL과 연결(앵커+네비게이션)
- 사이드바에서 Outgoing/Backlinks/Related 확인
- 그래프 뷰에서 문서 간 관계 탐색(학습/아이디어 맵)

## 13) 확장 가능성

- 타깃 타입 확장: 파일/태스크/태그/쿼리 링크 등
- 링크 스타일: 타입별 색상/아이콘/툴팁
- 권한/공유: 공유 노트에서 공개/비공개 링크
- 버전/감사 로그: 링크 변경 이력 추적
- 검색/추천: 링크 기반 추천/랭킹

## 14) 테스트 전략

- Memory 구현 단위 테스트: 생성/업데이트/삭제, 인덱스/스트림 동작, 백링크/코시테이션 계산
- Provider 테스트: links/backlinks/related/graph 파생 정확성
- UI 위젯 테스트: 생성 다이얼로그 → repo 호출 → 렌더 반영
- Isar 통합 테스트: 인덱스/트랜잭션/삭제 연쇄

## 15) 파일 레이아웃(제안)

- `lib/features/canvas/models/link_model.dart`
- `lib/shared/repositories/link_repository.dart`
- `lib/features/canvas/data/memory_link_repository.dart`
- `lib/features/canvas/providers/link_providers.dart`
- `lib/features/canvas/widgets/dialogs/link_creation_dialog.dart`
- (Isar)
  - `lib/features/canvas/data/isar/link_entity.dart`
  - `lib/features/canvas/data/isar/isar_link_repository.dart`

## 16) 오픈 이슈(결정 필요)

- label/anchorText 기본값/표시 정책(동기 vs 스냅샷)
- URL 타깃은 인앱 웹뷰 vs 외부 브라우저
- 그래프 단위(노트 vs 페이지) 기본값과 토글 UX
- 링크 보호/권한(읽기 전용 노트에서의 처리)

---

이 문서는 링크 시스템의 일관된 가이드라인을 제공합니다. Phase 1부터 차근차근 적용하고, UX/데이터 형태가 안정되면 Isar로 전환해 영속성과 성능을 확보합니다.
