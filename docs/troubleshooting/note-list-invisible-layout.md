## Note list invisible after vault selection — root cause and fix

### Symptoms

- After selecting a vault, the middle content (folder/note grid) did not render. Only the top app bar and the bottom dock were visible.
- Creating a note previously triggered: “Floating SnackBar presented off screen.”
- Initially, almost no logs beyond “🗄️ Vault selected: <id>”.

### Investigation timeline

1. Instrumented providers and repository streams.

- Added logs in `vaultItemsProvider` and `IsarVaultTreeRepository.watchFolderChildren` to trace emissions.
- Found that the repo emitted only after both folder and placements watchers produced a first value (gate: `foldersReady && placementsReady`).

2. Fixed stream’s initial emission contract.

- Seeded both sides as ready with empty lists and emitted immediately, then emitted on subsequent updates.
- Result: provider started receiving data; `NoteListFolderSection.data(total=…)` logs appeared.

3. UI still not visible → turned to layout/measurement.

- Added `LayoutBuilder` diagnostics. Observed `NoteListScreen.body constraints ... h=0.0` and parent size of section `…x0.0`.
- Conclusion: The body was measured with zero height; bottom dock and wrappers were causing the main content to collapse.

### Root causes

- Stream-level: The combined stream violated our “initial empty emit” contract, leaving the UI in loading states in some timing windows.
- Layout-level: The body collapsed to zero height due to the combination of `SingleChildScrollView + Column` and a bottom dock that occupied/expanded space in a way that left the body with no measurable height (Center/Align wrappers contributing). The SnackBar floating error also disturbed layout earlier.

### Concrete fixes applied

1. Streams (initial value contract)

- File: `lib/features/vaults/data/isar_vault_tree_repository.dart`
  - Emit initial empty combined list immediately; then emit on either side update.
  - Added debug logs to verify emissions.

2. SnackBar safety

- File: `lib/shared/widgets/app_snackbar.dart`
  - `behavior: SnackBarBehavior.floating` → `SnackBarBehavior.fixed` to avoid off-screen exceptions.

3. Main content layout

- File: `lib/features/notes/pages/note_list_screen.dart`
  - `SingleChildScrollView + Column` → `ListView` with padding (prevents zero-height body).
  - `Scaffold(resizeToAvoidBottomInset: false)` to reduce unexpected body resizing.
  - Temporary `LayoutBuilder` logs to confirm non-zero constraints (can be removed later).

4. Bottom dock sizing/positioning

- File: `lib/features/notes/widgets/note_list_primary_actions.dart`

  - Removed `Center` wrapper so the dock does not aggressively claim space.
  - Added size log (temporary) to validate height.

- File: `lib/design_system/components/organisms/bottom_actions_dock_fixed.dart`

  - Removed internal `Align` that could conflict with the parent.
  - The component now renders a fixed-size container only; parent controls width via `ConstrainedBox`.
  - Kept explicit `height`; computed intrinsic width from item count and spacing, optionally limited by `maxWidth`.

- File: `lib/features/notes/pages/note_list_screen.dart` (bottom bar wrapper)
  - Wrapped the dock with `SafeArea + Padding + SizedBox(height: 60) + Center + ConstrainedBox(maxWidth: 520)` to:
    - Anchor it at the bottom,
    - Keep three-button width,
    - Prevent it from stretching horizontally.

### Verification

- Repo logs show init and updates (folders/placements) and combined emits (total > 0).
- Provider logs show data received with correct totals.
- `NoteListFolderSection` logs show `data: total=n` and split counts.
- Layout logs show body constraints with non-zero height; the dock renders at 60px height; the grid is visible.

### Why this was tricky

- Two independent issues compounded:
  1. Stream initial emit gate → UI stuck “loading” in certain timings.
  2. Layout collapse caused by scroll/column + bottom dock wrappers → even with data, nothing visible.
- Only after we instrumented both the data path and the layout constraints did the picture become clear.

### Preventative guidelines

- Streams

  - Always seed with an initial empty value when combining multiple streams.
  - Prefer a combineLatest-style merge with explicit seed values instead of manual “ready” gates.

- Layout
  - Prefer `ListView`/Slivers for scrollable pages over `SingleChildScrollView + Column` to avoid unbounded/zero height issues.
  - In bottomNavigationBar, keep a fixed height and constrain width at the parent (Center + ConstrainedBox), not inside the reusable component.
  - Keep SnackBars `fixed` when using full-width bottom bars/docks.

### Files touched (high-level)

- Stream/Repo: `lib/features/vaults/data/isar_vault_tree_repository.dart`
- Providers: `lib/features/vaults/data/derived_vault_providers.dart` (diagnostic logs)
- UI
  - `lib/features/notes/pages/note_list_screen.dart`
  - `lib/features/notes/widgets/note_list_primary_actions.dart`
  - `lib/design_system/components/organisms/bottom_actions_dock_fixed.dart`
  - `lib/shared/widgets/app_snackbar.dart`

### Follow-ups

- Remove temporary debug prints once stabilized.
- Add a regression widget test: ensure a non-zero body height after vault selection, and presence of N cards given a seeded repo.
