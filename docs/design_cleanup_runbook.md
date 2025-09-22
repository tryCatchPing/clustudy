# Design Branch Cleanup Runbook

이 문서는 `design/clean-dev-xodnd` 브랜치에서 Yura의 디자인 작업을 재적용하면서 기능 코드(`lib/features/**`, `lib/shared/**`, `lib/routing/**`, 등)를 현재 브랜치 상태와 동일하게 유지하기 위한 절차를 기록합니다. 큰 흐름은 다음 두 단계로 나뉩니다.

- **Phase 1 (완료)**: `90cadcd`부터 `de8cbbd`까지 정리 완료. 디자인 자산만 `lib/design_system/**`로 추출했고 기능 계층은 `origin/dev`와 동일하게 맞춰둠.
- **Phase 2 (진행 중)**: `de8cbbd` 이후 Yura가 추가한 커밋들(`c676136`~`880c7d5`)을 재생산. 기능 코드는 현재 브랜치(`design/clean-dev-xodnd`) 상태로 고정하고, 디자인 관련 파일만 누적.

---

## 1. 현재 브랜치 상태

- 작업 브랜치: `design/clean-dev-xodnd`
- 기능/서비스 기준선: Phase 2 시작 시점의 `design/clean-dev-xodnd` (추후 `tmp/design-clean-base` 브랜치로 보관)
- 디자인 변경 원본: `origin/design/landing_page-yura`
- 목표
  - 디자인 시스템 자산(`lib/design_system/**`, `assets/fonts/**`, `assets/icons/**`)만 누적
  - 기능 계층(`lib/features/**`, `lib/shared/**`, `lib/routing/**`, `lib/main.dart`, `test/**`)은 기준선과 동일하게 유지
  - 디자인 관련 생성 시트/화면을 `lib/design_system/screens/**`로 이동하고, 더미 데이터/콜백으로 대체
  - 기존 커밋 작성자/타임스탬프 보존 + `Co-authored-by: yul-04 <yurakim0829@gmail.com>` 추가, 커밋 메시지는 `feat(design): ...` 형식으로 통일

---

## 2. Pre-flight Checklist

1. **작업 트리 정리**

   ```bash
   git status
   ```

   로컬 변경이 있다면 스태시하거나 별도 브랜치에 백업.

2. **원격 최신 상태 동기화**

   ```bash
   git fetch origin
   ```

3. **기준선 스냅샷 저장** (Phase 2 작업용)

   ```bash
   git checkout design/clean-dev-xodnd
   git branch --force tmp/design-clean-base
   ```

   이후 `git restore --source tmp/design-clean-base ...` 명령으로 기능 파일을 항상 이전 상태로 되돌릴 수 있음.

4. **Yura 최신 브랜치 로컬 추적**
   ```bash
   git checkout -B tmp/yura-refresh origin/design/landing_page-yura
   ```
   Phase 2 커밋을 모두 포함한 임시 작업 브랜치.

---

## 3. 인터랙티브 리베이스 준비

### 3.1 Phase 2용 GIT_SEQUENCE_EDITOR 스크립트

```bash
cat <<'PY' > docs/edit_rebase_todo_phase2.py
#!/usr/bin/env python3
import sys
from pathlib import Path

REWRITE = {
    'c6761363b6d7ce7c377d6a2fce69698626c7d15c': 'edit',
    '3e2f420fda37c3365130f0a872f5f58f7e56a3cb': 'edit',
    '0269af5d2aee8f0ade7372d9654f293f729fab48': 'edit',
    '127e5f431b5187d0245cc823aac9d2ff1df3fdd7': 'edit',
    '6a170bb807b3d36b1d19c63b7bb47fb3c9aaf9d4': 'edit',
    'e9f20c5f5bf8b1dc13181c14356bcbc85e885e3e': 'edit',
    '7c0dec4ede2336ab755d3efac1cd252db100302a': 'edit',
    'c973119ccf51cbf4942fe04806f1b0df9b6671e0': 'edit',
    '2c20d5c7ee057f0a70890fade77c1f6fd20b997c': 'edit',
    '8d3fd616970e581cb3a66af2a1f5d883d40aeddf': 'edit',
    '880c7d5dea0840b621cbea08bdf5d06fbfa59a8b': 'edit',
}

path = Path(sys.argv[1])
text = path.read_text()
lines = []
for line in text.splitlines():
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        lines.append(line)
        continue
    parts = stripped.split()
    if len(parts) < 2:
        lines.append(line)
        continue
    sha = parts[1]
    new_action = REWRITE.get(sha)
    if new_action:
        parts[0] = new_action
        line = ' '.join(parts)
    lines.append(line)
path.write_text('\n'.join(lines) + '\n')
PY
chmod +x docs/edit_rebase_todo_phase2.py
```

### 3.2 Phase 2 커밋만 리플레이

`tmp/yura-refresh`에서 다음 명령 실행:

```bash
GIT_SEQUENCE_EDITOR="python3 docs/edit_rebase_todo_phase2.py" \
  git rebase -i --onto design/clean-dev-xodnd \
    de8cbbde79d9147f61afdad1d11a898120560271 \
    tmp/yura-refresh
```

- 리베이스는 `de8cbbd` 이후 커밋(`c676136`~`880c7d5`)만 대상으로 함
- `edit`으로 표시된 커밋에서 멈출 때마다 Mixed Commit Extraction Loop 수행
- 순수 디자인 커밋이 있다면(Phase 2에는 드묾) 충돌 해결 후 바로 `git rebase --continue`

리베이스가 끝나면 `tmp/yura-refresh`가 정리된 디자인 커밋만 갖게 되므로 이후 `design/clean-dev-xodnd`에 fast-forward로 반영.

---

## 4. Mixed Commit Extraction Loop (Phase 2)

`edit` 지점마다 다음 절차 반복:

1. **초기화**

   ```bash
   git reset --hard HEAD
   ```

2. **디자인 관련 변경만 체크아웃**

   ```bash
   git checkout <SHA> -- assets lib/design_system
   # 필요 시 features 내부의 UI 파일도 임시로 체크아웃 후 design 폴더로 복사
   ```

3. **기능 UI를 디자인 시스템으로 이동/복사**

   - `lib/features/**/pages/*.dart`, `widgets/*.dart` 중 UI 위젯은
     `lib/design_system/screens/<domain>/` 경로로 복사
   - 기존에 동일 파일이 있다면 수동 병합 (스타일 변경 반영)
   - Provider, Router, 서비스 의존성은 삭제하고 더미 데이터/콜백으로 치환

4. **기능 계층을 기준선으로 롤백**

   ```bash
   git restore --source tmp/design-clean-base --staged --worktree \
     lib/features \
     lib/routing \
     lib/shared \
     lib/main.dart \
     test
   ```

   수정 범위에 따라 추가 경로(`lib/utils/**` 등)를 포함

5. **디자인 자산만 스테이징**

   ```bash
   git add assets lib/design_system
   git add -p pubspec.yaml  # 아이콘/폰트 등록 변경만 포함
   ```

6. **커밋 재작성 (작성자/타임스탬프 유지)**

   ```bash
   AUTHOR=$(git show --no-patch --format='%an <%ae>' <SHA>)
   DATE=$(git show --no-patch --format='%ad' <SHA>)
   git commit \
     --author="$AUTHOR" \
     --date="$DATE" \
     -m 'feat(design): <concise summary>' \
     -m 'Co-authored-by: yul-04 <yurakim0829@gmail.com>'
   ```

   `<concise summary>`에는 해당 커밋의 디자인 변경 요약 입력.

7. **리베이스 계속**
   ```bash
   git rebase --continue
   ```

---

## 5. Phase 2 커밋별 메모

| SHA (원본) | 커밋 메시지             | 메모                                                                                            |
| ---------- | ----------------------- | ----------------------------------------------------------------------------------------------- |
| `c676136`  | 폴더 관리 시트 생성     | 새 시트들을 `lib/design_system/screens/folder/widgets/`로 이동. 기능 시트는 기준선으로 복원.    |
| `3e2f420`  | 폴더 관리 시트 수정     | 디자인 시트에만 스타일 반영, 기능 위젯은 롤백.                                                  |
| `0269af5`  | 폴더 관리 카드 2차 수정 | `lib/design_system/components/molecules/folder_card.dart` 등 디자인 파일로 통합.                |
| `127e5f4`  | 전체 화면 툴바 해결     | 디자인 툴바(Top/Bottom) 관련 변경만 유지. 기능 툴바는 기준선.                                   |
| `6a170bb`  | 노트 툴바 수정          | 디자인 노트 툴바/세컨더리 툴바에 반영, 기능 쪽은 되돌림.                                        |
| `e9f20c5`  | 노트 화면 완성          | 디자인 노트 데모 화면 강화. 기능 노트 화면은 복원.                                              |
| `7c0dec4`  | 링크 생성용 시트        | 시트/다이얼로그를 `design_system` 쪽으로 복제, 기능 링크 시트는 제거.                           |
| `c973119`  | 기존 링크용 시트        | 위와 동일 전략.                                                                                 |
| `2c20d5c`  | 노트 페이지 관리 생성   | 관리 UI는 디자인 데모로 옮기고 기능 라우팅/서비스는 롤백.                                       |
| `8d3fd61`  | 검색 화면 완성          | `lib/design_system/screens/search/` 생성 후 더미 데이터 연결. 기능 검색 페이지는 baseline 유지. |
| `880c7d5`  | 링크 리스트 생성        | 링크 리스트/아이콘만 디자인 시스템에 남김. 기능 내부 변화는 모두 복원.                          |

> 모든 커밋에서 새로 추가된 아이콘(`assets/icons/**`)은 디자인 시스템에서만 사용하도록 확인. 기능에서 참조하지 않는지 double check.

---

## 6. 리베이스 이후 마무리

1. **정리된 브랜치 합치기**

   ```bash
   git checkout design/clean-dev-xodnd
   git merge --ff-only tmp/yura-refresh
   ```

2. **Diff 범위 재확인**

   ```bash
   git diff --name-only tmp/design-clean-base..HEAD
   ```

   결과가 `assets/**`, `lib/design_system/**`, `docs/**` 정도에 한정되는지 확인. 다른 경로가 나오면 기준선으로 복원.

3. **필요 시 추가 검증**

   ```bash
   fvm flutter analyze
   fvm flutter test
   ```

4. **푸시 및 정리**
   ```bash
   git push --force-with-lease origin design/clean-dev-xodnd
   # 작업 끝난 뒤 정리
   git branch -D tmp/yura-refresh
   git branch -D tmp/design-clean-base   # 필요 시 유지
   rm -f docs/edit_rebase_todo_phase2.py
   ```

---

## 7. Open Questions / TODOs

- 디자인 화면으로 옮기는 과정에서 필요한 더미 데이터/콜백 패턴 표준화 필요
- `lib/design_system/routing/design_system_routes.dart`에 새 데모 화면을 어떻게 노출할지 결정
- `pubspec.yaml` 디자인 자산 섹션을 주기적으로 점검 (사용되지 않는 아이콘 제거 등)
- Phase 2 완료 후에는 향후 Phase 3(추가 커밋) 대비해서 동일 절차 반복 가능하도록 본 문서를 최신화할 것
- 기준선 브랜치(`tmp/design-clean-base`)는 Phase 2 종료 후에도 다음 작업 전까지 업데이트해 두기

---

이 문서를 따라가면 이후 세션에서도 동일한 컨텍스트를 재현해 Phase 2 커밋을 안전하게 정리할 수 있습니다.
