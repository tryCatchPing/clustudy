# Repository Guidelines

## Project Structure & Modules
- `lib/features/`: Feature-centric code.
  - `canvas/` (providers, notifiers, widgets)
  - `notes/` (data, models, pages)
  - `page_controller/` (page management)
- `lib/shared/`: `services/`, `repositories/` (interfaces), reusable `widgets/`.
- `test/`: Mirrors `lib/` with `*_test.dart`.
- `docs/`: Project docs and workflows.
- Platform: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`.
- Config: `pubspec.yaml` (deps), `analysis_options.yaml` (lints), `.fvmrc` (Flutter 3.32.5 via FVM).

## Architecture Overview
- Clean layering: Presentation (ConsumerWidget + Riverpod) → Services/Notifiers → Data (Repository pattern).
- State: Riverpod providers (family where needed), no logic in `createState`.
- Data: Access via repository interfaces only; current memory impl, Isar planned.
- PDF/Canvas: `pdfx` + custom `scribble` fork (Apple Pencil, fixed `scaleFactor` = 1.0).

## Build, Test, and Dev Commands
- Install deps: `fvm flutter pub get`
- Run app: `fvm flutter run`
- Analyze code: `fvm flutter analyze`
- Format code: `fvm dart format .`
- Run tests: `fvm flutter test` (optionally `--coverage`)
- Codegen (Riverpod, build_runner):
  - One-off: `fvm dart run build_runner build --delete-conflicting-outputs`
  - Watch: `fvm dart run build_runner watch --delete-conflicting-outputs`
 - iOS deps (macOS): `cd ios && pod install && cd ..`

## Coding Style & Naming
- Follow `analysis_options.yaml` (Flutter lints + stricter rules).
- Indentation: 2 spaces; line length ~80.
- Quotes: single quotes; prefer `const`/`final`; avoid `print`.
- Documentation: add `///` for public members.
- Imports: keep ordered (`directives_ordering`); let analyzer guide specifics.
- Naming: files `snake_case.dart`; classes/types `UpperCamelCase`; variables/methods `lowerCamelCase`.

## Testing Guidelines
- Framework: `flutter_test`.
- Location: mirror `lib/` structure under `test/` with matching `*_test.dart` names.
- Scope: unit-test providers/services; widget tests for UI; add a test with each new feature/bugfix.
- Run locally: `fvm flutter test` (ensure `fvm flutter analyze` is clean).

## Commit & Pull Request Guidelines
- Commit style: Conventional Commits.
  - Examples: `feat(pdf): export annotations to PDF`, `fix(session): keepAlive during route swap`, `chore(docs): update README`.
- Branching: feature branches from `dev`; open PRs into `dev`.
- PR checklist:
  - Clear title + scope; link issue/task ID.
  - Describe changes, rationale, and risks; include screenshots for UI.
  - Verify locally: `pub get`, `analyze`, `test`, and app runs.

## Security & Configuration Tips
- Use FVM: ensure `3.32.5` is active (`fvm list`, `.fvmrc`). VS Code: set `"dart.flutterSdkPath": ".fvm/flutter_sdk"`.
- Do not commit secrets or local build artifacts. Generated files are fine when needed; prefer codegen commands above.
