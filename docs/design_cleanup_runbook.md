# Design Branch Cleanup Runbook

This runbook captures the exact plan for cleaning up the branch `design/clean-dev-xodnd` so that it only contains design-system assets and demo screens while restoring all feature/business logic back to `origin/dev`.

The process relies on an interactive rebase onto `origin/dev`, replaying Yura's design commits and, for mixed commits, extracting only the design UI into `lib/design_system` (plus assets) while keeping the app's real feature code untouched. This document keeps the context so a future "full-auto" session can resume and finish the job.

---

## 1. Current Context

- Branch to clean: `design/clean-dev-xodnd`
- Base branch: `origin/dev` (commit `38f056b` at the time of writing)
- Goal:
  - Preserve design artifacts (tokens, atoms, molecules, organisms, sample screens, icons, fonts).
  - Move any UI work that landed under `lib/features/**` into `lib/design_system/**`.
  - Restore feature/business logic files (`lib/features`, `lib/routing`, `lib/shared`, etc.) to match `origin/dev` exactly.
  - Keep asset registrations in `pubspec.yaml` that the design system needs (fonts, icons).
  - Preserve original authorship/timestamps of Yura's commits while crediting her via `Co-authored-by: yul-04 <yurakim0829@gmail.com>` and standardized `feat(design): ...` subjects.

---

## 2. Pre-flight Checklist

1. **Clean tree**

   ```bash
   git status
   ```

   Ensure only helper files like `docs/how_to_rebase_yura.md` remain. Either stash or delete helpers during the rebase.

2. **Remove helper artifacts** (optional but recommended)

   ```bash
   rm -f edit_rebase_todo.py
   rm -f docs/how_to_rebase_yura.md  # or stash it if still needed
   ```

3. **Update remote refs**
   ```bash
   git fetch origin
   ```

---

## 3. Interactive Rebase Setup

### 3.1 Mark commits that need manual surgery

Only Yura's commits that touched feature logic should be marked as `edit`. Prepare the helper once:

```bash
cat <<'PY' > edit_rebase_todo.py
#!/usr/bin/env python3
import sys
from pathlib import Path

REWRITE = {
    '359402f2db466980178a5487ec3955cca2e1f56b': 'edit',
    'e90ad47adae4401d5228233f43a0c4d6d0610deb': 'edit',
    '2bf274cde1f78c98ef7f4ba792dc0ca2de9c2c39': 'edit',
    '711d7259d33a9d864354b098fcb65b8bec8fc074': 'edit',
    '225f5c5d9a900fe50d5638197e85ddb6966a12f7': 'edit',
    '10df4c17772a9f66f51e4cda4dd1f463f2f16b36': 'edit',
    'b5ecb740b52294e06f834e109f07c6e25b748960': 'edit',
    'f86f79d4ea39c54d3ce4469ce156c8c62638ced8': 'edit',
    'b9fb12fc0e6068f621add866464485742f366cb4': 'edit',
    'b5c704b39af11fcacd20a7112cdf4db62a80b211': 'edit',
    '4179da2934051028648a00ad1b59ec20ffa4eeba': 'edit',
    '41eb910cfb0e63362c913e0b8143a1e83b1df8a0': 'edit',
    'c108d9d298d8437ae6505724e4d9b57ab67a6c94': 'edit',
    'de8cbbde79d9147f61afdad1d11a898120560271': 'edit',
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
    sha = parts[1]
    new_action = REWRITE.get(sha)
    if new_action:
        parts[0] = new_action
        line = ' '.join(parts)
    lines.append(line)
path.write_text('\n'.join(lines) + '\n')
PY
chmod +x edit_rebase_todo.py
```

Run the rebase with the helper as `GIT_SEQUENCE_EDITOR`:

```bash
GIT_SEQUENCE_EDITOR="python3 edit_rebase_todo.py" git rebase -i origin/dev
```

### 3.2 Commit classification

- **Pure design commits (auto)**: `90cadcd` through `c2ad63f` are limited to design assets/tokens. Resolve conflicts, stage design files, `git rebase --continue`.
- **Mixed commits (manual)**: the SHA list in `REWRITE` above requires extraction of design code and restoration of features.

---

## 4. Conflict Policy for Design-only Commits

1. **`lib/design_system/tokens/app_colors.dart` conflict** (commit `90cadcd`)

   - design_system 폴더의 수정사항은 모두 yura 의 최신 변경 사항을 가져옵니다

2. **`pubspec.yaml` conflicts**

   - Ensure the following remain:
     - Font registration for `assets/fonts/PretendardVariable.ttf` (added in `90cadcd`).
     - Icon assets under `flutter/assets` introduced by later design commits (`assets/icons/*.svg`).
   - Stage only the relevant chunks via `git add -p pubspec.yaml` if necessary.

3. For other design-only commits, simply stage modified design files and run `git rebase --continue`.

---

## 5. Mixed Commit Extraction Loop

For each commit marked `edit`, follow this pattern (replace `<SHA>` and paths as needed):

1. **Reset to a clean state for that commit**

   ```bash
   git reset --hard HEAD
   ```

2. **Check out the commit's changes only for design-relevant directories**

   ```bash
   git checkout <SHA> -- assets lib/design_system
   ```

   Add additional paths only if the design system needs them (e.g., demo routing files under `lib/design_system/routing`).

3. **Copy UI screens/widgets out of features before restoring**

   - For each features file that contains visual work (pages, widgets), copy it into the design system. Examples:

     ```bash
     mkdir -p lib/design_system/screens/home
     cp lib/features/home/pages/home_screen.dart lib/design_system/screens/home/home_screen.dart

     mkdir -p lib/design_system/screens/folder
     cp lib/features/folder/pages/folder_screen.dart lib/design_system/screens/folder/folder_screen.dart

     mkdir -p lib/design_system/screens/vault
     cp lib/features/vaults/pages/vault_screen.dart lib/design_system/screens/vault/vault_screen.dart

     mkdir -p lib/design_system/screens/notes
     cp lib/features/notes/pages/note_screen.dart lib/design_system/screens/notes/note_screen.dart

     mkdir -p lib/design_system/screens/home/widgets
     cp lib/features/home/widgets/home_creation_sheet.dart lib/design_system/screens/home/widgets/home_creation_sheet.dart
     cp lib/features/folder/widgets/folder_creation_sheet.dart lib/design_system/screens/folder/widgets/folder_creation_sheet.dart
     cp lib/features/vaults/widgets/vault_creation_sheet.dart lib/design_system/screens/vault/widgets/vault_creation_sheet.dart
     cp lib/features/notes/widgets/note_creation_sheet.dart lib/design_system/screens/notes/widgets/note_creation_sheet.dart
     ```

   - If earlier commits already created a design version of a file, open both and merge by hand so history remains consistent.
   - Strip app logic (providers, navigation, async calls) from the design copies; replace them with deterministic sample data.

4. **Restore feature/business code back to `origin/dev`**

   ```bash
   git restore --source origin/dev --staged --worktree \
     lib/features \
     lib/routing \
     lib/shared \
     lib/main.dart \
     test
   ```

   Add/remove paths here according to each commit's scope (some commits touch additional files such as `lib/utils/pickers/pick_pdf.dart`).

5. **Stage design assets only**

   ```bash
   git add assets lib/design_system
   git add -p pubspec.yaml  # keep only icon/font entries needed by design
   ```

6. **Re-create the commit with co-author metadata and standardized message**

   ```bash
   AUTHOR=$(git show --no-patch --format='%an <%ae>' <SHA>)
   DATE=$(git show --no-patch --format='%ad' <SHA>)
   git commit \
     --author="$AUTHOR" \
     --date="$DATE" \
     -m 'feat(design): <concise summary>' \
     -m 'Co-authored-by: yul-04 <yurakim0829@gmail.com>'
   ```

   Replace `<concise summary>` with the specific design change (e.g. `refine home showcase`). Include additional body text if the original commit message had details.

7. **Continue the rebase**
   ```bash
   git rebase --continue
   ```

Repeat the loop for each SHA in the `REWRITE` map.

---

## 6. Commit-specific Notes

### 359402f `home 1차 완성`

- Keep removal of `lib/design_system/ai_generated/**` and the new design routing files.
- Extract all UI from `lib/features/**` into the corresponding folders under `lib/design_system/screens/**`.
- Restore `lib/features`, `lib/routing`, `lib/shared`, `lib/main.dart`, `pubspec.yaml` (except for icon/font asset lines).

### e90ad47 `router 해결, vault 폴더 화면 생성`

- Adds vault/folder demo screens and routing glue.
- Copy visual widgets (`vault_screen`, `folder_screen`, `vault_creation_sheet`, etc.) into `lib/design_system/screens/**`.
- Keep design-system routing updates (`lib/design_system/routing/design_system_routes.dart`).
- Restore all feature logic and providers to `origin/dev`.

### 2bf274c `폴더, 노트 생성을 위한 스크린 생성`

- Same pattern: move new creation sheets into `lib/design_system/screens/**/widgets`.
- Restore feature stores/routes/services.

### 711d725 `home, vault, folder 2차 수정`

- Merge incremental design tweaks into the design copies created earlier.
- Before restoring features, diff against the previous design versions to bring over style changes.

### 225f5c5 `toptoolbar 수정`

- Purely design system except for canvas references. Only `lib/design_system/components` should stay; ensure canvas feature files revert to `dev`.

### 10df4c1 `appcard 수정`

- Keep design-system molecule updates, new icons, and screens.
- Restore `lib/features/*` pages to `dev`.

### b5ecb74 `생성 sheet 생성 버튼 수정`

- Only design components should remain. Restore widgets under `lib/features/**` after copying to design folder if needed.

### f86f79d `homescreen 수정`

- Continue merging updates into `lib/design_system/screens/home/home_screen.dart`.
- Restore feature home screen to `dev` version afterward.

### b9fb12f `이전 버튼 경로 수정`

- Similar: merge icon path tweaks into design copy, then restore features.

### b5c704b `생성 sheet 생성 버튼 수정`

- Update design creation sheets; restore feature sheets to `dev`.

### 4179da2 `creationsheet 아이콘 버튼 수정`

- Keep design component changes; restore feature usages.

### 41eb910c `folder_grid + stores`

- UI parts (folder grid) stay in `lib/design_system/components/organisms`.
- Feature store/state/data files must revert.

### c108d9d `folder_screen, note_store`

- Move final visual tweaks into design screens; restore feature stores and pages.

### de8cbbd `foldercard 아이콘 수정`

- Purely design updates except maybe icons. Ensure only `lib/design_system/...` and `assets/icons/*.svg` stay staged.

---

## 7. After the Rebase

1. **Verify diff scope**

   ```bash
   git diff --name-only origin/dev..HEAD
   ```

   Expect to see only `assets/fonts`, `assets/icons`, `lib/design_system/**`, and possibly documentation.

2. **Run sanity checks** (optional but encouraged)

   ```bash
   fvm flutter analyze
   fvm flutter test
   ```

3. **Force-push the cleaned branch**

   ```bash
   git push --force-with-lease origin design/clean-dev-xodnd
   ```

4. **Cleanup**
   ```bash
   rm -f edit_rebase_todo.py
   ```

---

## 8. Open Questions / TODOs

- When copying feature UI into `lib/design_system/screens/**`, replace provider/data calls with static mock data so that design previews compile without app state.
- Decide how to expose the new design screens (e.g., via `lib/design_system/routing/design_system_routes.dart`).
- Revisit `pubspec.yaml` after rebase to ensure no unused asset entries remain.

This document should give the next session full context to resume the cleanup without re-discovering the workflow.
