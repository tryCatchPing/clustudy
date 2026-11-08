# Linking Relationship Graphs (Mermaid)

링크의 방향성(Outgoing/Backlink)과 코시테이션(공통 타깃 기반 연관)을 간단한 그래프로 예시합니다.

## 1) 기본 링크 방향 (노트 레벨)
```mermaid
flowchart LR
  B([Note B]) -->|links to| A([Note A])
  C([Note C]) -->|links to| A
```

## 2) 페이지 레벨 링크 + 노트 페이지 소속
```mermaid
flowchart LR
  subgraph B_note[Note B]
    Bp1([B:page#1])
  end
  subgraph C_note[Note C]
    Cp2([C:page#2])
  end
  subgraph A_note[Note A]
    Ap1([A:page#1])
  end

  Bp1 -->|link| A_note
  Cp2 -->|link| A_note
```

## 3) 코시테이션(공통 타깃 기반 연관)
```mermaid
flowchart LR
  B([Note B]) --> A([Note A])
  C([Note C]) --> A
  B ---- C
  %% 점선(B—C)은 "A를 공통으로 참조"한다는 유도 관계(가중치=공통 타깃 수)
  classDef inferred stroke-dasharray: 3 3;
  class B,C inferred;
```

## 4) 아웃고잉 vs 백링크 하이라이트
```mermaid
flowchart LR
  A([Note A])
  B([Note B])
  C([Note C])
  B -- Outgoing --> A
  C -. Backlink .-> A
  %% 동일 관계를 관점만 바꿔서 표현: B에서 보면 Outgoing, A에서 보면 Backlink
```

설명
- 그래프 레벨은 노트/페이지 중 선택 가능합니다(옵션 토글).
- 코시테이션은 동일 타깃을 가리키는 노트들 사이의 유도 관계입니다(분석/추천/그래프 가중치에 활용).
- 실제 구현에서는 Providers로 링크/백링크/코시테이션을 파생 계산하여 그래프 데이터로 변환합니다.

