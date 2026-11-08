# Task 8 – Provider & Startup Wiring Notes

## Why This Exists

Task 8 from the Isar migration plan focuses on replacing all in-memory
providers with Isar-backed implementations and ensuring the database is ready
before the widget tree boots. This document captures the reasoning behind each
change so future refactors (or rewrites) have the necessary context.

## Summary of Work

- Swapped the default repository providers to instantiate Isar-based classes.
- Ensured provider disposals continue to run so repositories can release
  resources on teardown.
- Updated the app entry point to initialize the Isar database before running
  the `ProviderScope`, surfacing initialization failures via
  `FlutterError.reportError` for visibility.
- Attempted formatting via `fvm dart format` and `dart format`; sandbox
  restrictions prevented the commands from writing the engine stamp. Formatting
  should be run locally outside the sandbox.

## Provider Changes

### Vault Tree

- `lib/features/vaults/data/vault_tree_repository_provider.dart`
  - Imports `IsarVaultTreeRepository` instead of the memory variant.
  - Provider comment updated to state the Isar default.
  - Provider now instantiates `IsarVaultTreeRepository()` and disposes it on
    scope teardown. The Isar implementation keeps a cached database instance,
    so disposal remains important for tests and overrides.

### Notes

- `lib/features/notes/data/notes_repository_provider.dart`
  - Imports `IsarNotesRepository` and updates docs to reflect the new default.
  - Provider returns `IsarNotesRepository()` with the same disposal behaviour.
  - Notes repository consumers (page controllers, note editor, etc.) now talk
    to persistent storage via the mapper layer instead of the RAM-backed list.

### Links

- `lib/features/canvas/providers/link_providers.dart`
  - Switches dependency to `IsarLinkRepository`.
  - The Riverpod generator continues to emit `linkRepositoryProvider`, so all
    downstream selectors (`linksByPage`, `backlinksToNote`, etc.) now stream
    from Isar.
  - Maintains the existing on-dispose contract; when tests override the
    provider they can still supply memory or fake implementations as needed.

## App Startup Initialization

- `lib/main.dart`
  - `main()` is now `async` and calls `WidgetsFlutterBinding.ensureInitialized()`
    before touching platform channels.
  - Guards `IsarDatabaseService.getInstance()` with a `try/catch` block so
    initialization failures surface via `FlutterError.reportError`. The error is
    rethrown to avoid starting the UI in a partially-initialized state.
  - Once the database is ready, the app continues to launch the existing
    `ProviderScope` + `MyApp` tree unchanged.

## Follow-Up / Verification Steps

1. Run `fvm dart format lib/main.dart lib/features/**/data/*provider*.dart
lib/features/canvas/providers/link_providers.dart` to satisfy formatting
   rules (blocked in the sandbox).
2. Execute `fvm flutter analyze` to confirm lint compliance.
3. Execute `fvm flutter test` to make sure runtime behaviour matches the memory
   implementation expectations.
4. (Optional) Instrument manual smoke testing to verify the database directory
   is created and populated on app launch.

## Notes for Future Refactors

- The providers still create repositories eagerly. If lifecycle issues arise,
  consider using scoped overrides with lazily created repositories per
  navigation stack.
- `main.dart` currently initializes Isar synchronously on the UI isolate. If
  startup hitches become noticeable, explore spinning the initialization into a
  separate isolate while showing a splash screen.
- Test suites may need overrides for these providers to keep using the memory
  repositories; Riverpod overrides at the test harness level continue to work.
