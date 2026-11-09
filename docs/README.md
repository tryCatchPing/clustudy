# docs

Clustudy 구현 과정에서 남긴 설계·문제 해결·작업 기록입니다.
현재 코드 이해에 필요한 문서만 주제별 폴더에 두고, 나머지는 `archive/`에 보관했습니다.

| 폴더 | 내용 |
| --- | --- |
| [`architecture/`](architecture) | 지금 코드가 어떻게 동작하는지: 설계, 데이터 모델, 정책 |
| [`troubleshooting/`](troubleshooting) | 실제로 겪은 버그와 원인 분석, 해결 과정 |
| [`isar-migration/`](isar-migration) | 메모리 저장소 → Isar DB 전환 작업 기록 (task 순서대로) |
| [`plans/`](plans) | 설계만 하고 아직 구현하지 않은 향후 과제 |
| [`guides/`](guides) | 운영, 개발 환경, 실기기 테스트 가이드 |
| [`screenshots/`](screenshots) | 스토어 스크린샷, 그래픽 이미지 |
| [`archive/`](archive) | 끝난 작업 계획, 중간 분석, 오래된 상태 문서, AI 세션 로그 |

## architecture — 설계와 정책

**링크 시스템**

- [linking-system-architecture.md](architecture/linking-system-architecture.md): 링크/백링크/그래프 전체 설계 (모델, 저장소, Provider, UI 흐름)
- [linking-system-erd.md](architecture/linking-system-erd.md): Note / NotePage / Link ERD (Mermaid)
- [linking-system-graph-examples.md](architecture/linking-system-graph-examples.md): Outgoing·Backlink·코시테이션 관계 예시 그래프
- [link-delete-edit-and-cascades.md](architecture/link-delete-edit-and-cascades.md): 링크 삭제/수정, 페이지·노트 삭제 시 링크 캐스케이드

**Vault / 폴더 / 노트**

- [vault-folder-note-structure.md](architecture/vault-folder-note-structure.md): vault → folder → note → page 구조와 불변식
- [vault-notes-service.md](architecture/vault-notes-service.md): VaultNotesService (트리·콘텐츠·링크 오케스트레이션) 설계
- [naming-search-move-policy.md](architecture/naming-search-move-policy.md): 이름 정규화, 검색, 이동 정책
- [note-move-auto-rename.md](architecture/note-move-auto-rename.md): 노트 이동과 이름 충돌 자동 접미사 구현
- [error-and-ux-policy.md](architecture/error-and-ux-policy.md): 에러 분류와 AppErrorMapper / AppSnackBar 규격

**PDF**

- [pdf-processor.md](architecture/pdf-processor.md): PDF 처리 서비스 구조 정리 과정
- [pdf-recovery-service.md](architecture/pdf-recovery-service.md): PDF 손상 감지와 복구 시스템
- [pdf-export.md](architecture/pdf-export.md): PDF 내보내기 MVP (오프스크린 렌더링, PDF 배경 합성, 공유)

**캔버스 입력**

- 최종 입력 정책(포인터 수에 따른 필기, 확대, 페이지 넘김)은 [troubleshooting/pointer-gesture-issues.md](troubleshooting/pointer-gesture-issues.md)의 "최종 포인터 정책" 절에 있습니다.

## troubleshooting — 문제 해결 기록

- [isar-nested-transaction.md](troubleshooting/isar-nested-transaction.md): 중첩 `writeTxn`으로 인한 Isar 트랜잭션 실패 → `DbWriteSession` 도입
- [note-list-invisible-layout.md](troubleshooting/note-list-invisible-layout.md): vault 선택 후 노트 목록이 안 보이던 문제 (스트림 초기값 + 레이아웃 0 높이)
- [pointer-gesture-issues.md](troubleshooting/pointer-gesture-issues.md): Scribble 포크와 제스처 아레나 충돌, 페이지 넘김 충돌, 포인터 추적 provider 도입과 최종 포인터 정책
- [undo-redo-history-loss.md](troubleshooting/undo-redo-history-loss.md): 도구 변경·페이지 추가 시 undo/redo 기록 유실
- [note-session-race-condition.md](troubleshooting/note-session-race-condition.md): "No note session" 에러와 수동 캐시 → Riverpod 생명주기 전환
- [editor-navigation-and-autosave.md](troubleshooting/editor-navigation-and-autosave.md): 백링크 패널 이후 GlobalKey 충돌, 자동저장 크래시, 페이지 이동 저장 누락
- [per-route-resume-navigation.md](troubleshooting/per-route-resume-navigation.md): 라우트별 마지막 페이지 복원
- [linking-and-session-retrospective.md](troubleshooting/linking-and-session-retrospective.md): 링크 기능 + 세션 구현 회고

## isar-migration — Isar DB 전환 기록

| 문서 | 내용 |
| --- | --- |
| [00-adoption-guide.md](isar-migration/00-adoption-guide.md) | 도입 시 유의점, 트랜잭션·스키마 베스트 프랙티스 |
| [01-task1-2-setup-and-entities.md](isar-migration/01-task1-2-setup-and-entities.md) | 의존성, DB 서비스, 엔티티 정의 |
| [02-task1-2-foundations.md](isar-migration/02-task1-2-foundations.md) | 메타데이터 엔티티, 관계(backlink) 배선 |
| [03-task3-mappers.md](isar-migration/03-task3-mappers.md) | 엔티티 ↔ 도메인 모델 매퍼 |
| [04-task4-txn-runner.md](isar-migration/04-task4-txn-runner.md) | `IsarDbTxnRunner` |
| [05-task5-vault-tree-repository.md](isar-migration/05-task5-vault-tree-repository.md) | Vault 트리 저장소 |
| [06-task6-link-repository.md](isar-migration/06-task6-link-repository.md) | 링크 저장소 |
| [08-task8-provider-wiring.md](isar-migration/08-task8-provider-wiring.md) | Provider 교체, 앱 시작 시 DB 초기화 |
| [09-task9-tests.md](isar-migration/09-task9-tests.md) | `TestIsarContext` 기반 테스트 전략 |

## plans — 미구현 과제

- [service-to-db.md](plans/service-to-db.md): VaultNotesService의 이름 충돌·트리 탐색 로직을 저장소 계층으로 이전

## guides

- [install-attribution.md](guides/install-attribution.md): Play 스토어 UTM 링크 생성과 Firebase 설치 경로 추적
- [galaxy-tab-device-test.md](guides/galaxy-tab-device-test.md): 새 PC에서 개발 환경 구성, 갤럭시 탭 연결, PDF 내보내기(#59) 실기기 테스트

## archive

이미 끝났거나 다른 문서로 대체된 기록입니다. 지금 코드와 다를 수 있습니다.

- 끝난 작업 계획/상태: `todo.md`, `current_status_summary.md`, `vault-delete-plan.md`, `vault-notes-service-implementation.md`, `riverpod_migration_plan.md`, `riverpod_migration_phases.md`, `2025-09-13-initial-release-iteration.md`
- 디자인 시스템 적용 작업: `design_flow.md`, `design_cleanup_runbook.md`, `design_canvas_pre_info.md`, `design_canvas_implementation_plan.md`
- 최종 문서로 대체된 중간 기록: `1104_pointerPolicy.md`, `1104_pointerPolicy_problem.md`, `1104_pointerPolicy_scribble_fix_plan.md`, `prev-page-save.md`, `session_problem_solved.md`, `pdf_file_system_history.md`
- 이전 PDF 내보내기: `pdf-export-fix-scale-save.md`(v1.0.4까지의 구현), `pdf_export_offscreen_scribble.md`(MVP 이전 재설계안)
- 이전 README: `README_prev.md`
- `ai-sessions/`: Claude Code / Cursor 대화 로그와 예전 CLAUDE.md 백업
- `AGENTS.md`: 개발 기간에 AI 코딩 도구에 제공하던 저장소 가이드
- `kiro/`: Kiro로 작성한 스펙(isar-db-migration, page-controller)과 steering 문서
