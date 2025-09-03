# Linking System ERD (Mermaid)

이 문서는 링크 시스템의 엔티티/관계(ERD)를 Mermaid로 시각화합니다. GitHub/VS Code 미리보기에서 바로 볼 수 있습니다.

```mermaid
%% Domain-level ERD (Note / NotePage / Link)
erDiagram
    NOTE ||--o{ NOTEPAGE : contains
    NOTEPAGE ||--o{ LINK : has_outgoing

    %% Optional target relations (one of)
    NOTE ||--o{ LINK : is_target_of
    NOTEPAGE ||--o{ LINK : is_target_of

    NOTE {
      string noteId PK
      string title
      enum   sourceType
      string sourcePdfPath
      int    totalPdfPages
      datetime createdAt
      datetime updatedAt
    }

    NOTEPAGE {
      string pageId PK
      string noteId FK
      int    pageNumber
      enum   backgroundType
      string backgroundPdfPath
      int    backgroundPdfPageNumber
      double backgroundWidth
      double backgroundHeight
      string preRenderedImagePath
      bool   showBackgroundImage
      string sketchJson
    }

    LINK {
      string id PK
      string sourceNoteId
      string sourcePageId
      enum   targetType  %% note | page | url
      string targetNoteId
      string targetPageId
      string url
      double bboxLeft
      double bboxTop
      double bboxWidth
      double bboxHeight
      string label
      string anchorText
      datetime createdAt
      datetime updatedAt
    }
```

설명

- NOTE 1 — N NOTEPAGE
- NOTEPAGE 1 — N LINK (Outgoing)
- LINK의 Target은 NOTE 또는 NOTEPAGE 또는 URL 중 하나(타입으로 분기)
- 페이지/노트 모델에는 링크를 임베드하지 않고, 식별자/인덱스로 조회합니다.

추가 참고: Isar 도입 시에는 LINK 컬렉션에 `sourcePageId`, `targetNoteId`, `targetPageId` 인덱스를 생성하고, 선택적으로 IsarLink/Backlink를 사용해 연쇄 삭제를 쉽게 구현할 수 있습니다.
