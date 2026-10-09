# HomeSchooling — mobile app

Android-first Flutter app for homeschooling families. Parents plan and review; children play. This README
covers everything to get from a clean Windows machine to a running app and a signed release build. For Play
Console listing/release-track steps, see the separate deployment guide (PDF) — this document stops at
"upload the .aab".

## 1. Install Flutter, Android Studio and JDK 17 (Windows)

1. **JDK 17** — install a JDK 17 distribution (e.g. [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17)).
   During setup, tick "Set JAVA_HOME variable". Verify: open a new PowerShell window and run `java -version`
   (should print `17.x`).
2. **Android Studio** — install from [developer.android.com/studio](https://developer.android.com/studio).
   On first launch, run through the setup wizard so it installs the Android SDK, SDK Platform-Tools and an
   emulator image. Note the SDK location it prints (usually `C:\Users\<you>\AppData\Local\Android\Sdk`).
3. **Flutter SDK** — download the Windows zip from [flutter.dev](https://flutter.dev), extract it somewhere
   without spaces in the path (e.g. `C:\src\flutter`), and add `C:\src\flutter\bin` to your `Path` (Windows
   Settings → "Edit environment variables for your account").
4. Open a **new** PowerShell window and run:
   ```powershell
   flutter doctor
   ```
   Resolve anything it flags (accept Android licenses with `flutter doctor --android-licenses`, install the
   Android Studio plugin steps it suggests, etc.) until every check is green (or at least Android toolchain +
   Android Studio are green — VS Code/Chrome checks are optional).
5. Create an emulator: Android Studio → **Device Manager** → **Create device** → pick a Pixel profile and a
   recent API level (34+) → Finish. Start it once so its first boot completes.
6. Install **PowerShell 7** (`pwsh`), which the scripts under `tools/` are written for (not Windows
   PowerShell 5.1): `winget install --id Microsoft.PowerShell -e`, or download from
   [github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases).

## 2. Clone and bootstrap

```powershell
git clone <this repo's URL> homeschooling-app
cd homeschooling-app
flutter pub get
pwsh tools/bootstrap.ps1
```

`bootstrap.ps1` is **idempotent** — safe to re-run any time (e.g. after pulling a change that touches
`android/`). The first time, with no `android/` folder present, it runs `flutter create` for you and then
patches the result to add:

- the `dev` / `nonprod` / `prod` build flavors (each a distinct `applicationId` suffix and app name)
- `minSdk 26`, `compileSdk`/`targetSdk 36`
- a release `signingConfig` that reads `android/key.properties` (see §5 — falls back to the debug key until
  that file exists, so `flutter run --release` still works without it)
- release minification (R8) and resource shrinking
- `android:allowBackup="false"`
- a `dev`-flavor-only network security config allowing cleartext HTTP to `10.0.2.2` (the emulator's alias for
  your machine), so local development never needs HTTPS

**Before your first Play Store upload**, re-run bootstrap with your real organisation id:

```powershell
pwsh tools/bootstrap.ps1 -Org com.yourcompany
```

> `applicationId` (derived from `-Org`) is **permanent** once an app is uploaded to the Play Store — it can
> never be changed for that listing afterwards. The default, `in.homeschoolapp`, is a clearly-fake
> placeholder. Do not ship it.

## 3. Run the app

```powershell
pwsh tools/run.ps1                 # dev flavor, against http://10.0.2.2:8000 (the emulator's alias for your machine)
pwsh tools/run.ps1 -Flavor nonprod # against the nonprod backend in env/nonprod.json
```

The backend itself (`backend-api`) is a separate repo — run it locally, e.g. `uvicorn ... --port 8000`.

**On the emulator**, `10.0.2.2` already reaches your machine's `localhost:8000` — nothing else to do.

**On a physical device** over USB, forward the port instead:

```powershell
adb reverse tcp:8000 tcp:8000
```

then run with `-Flavor dev` as above; `10.0.2.2` won't resolve on a real device, so `env/dev.json`'s
`API_BASE_URL` would need to become `http://127.0.0.1:8000` for that session (only relevant for physical
device testing against a local backend — `adb reverse` makes `127.0.0.1:8000` on the device reach `8000` on
your machine).

## 4. Environment files and flavors

| File | Flavor | Notes |
|---|---|---|
| `env/dev.json` | `dev` | Points at the emulator alias. Committed as-is; no secrets here or in any env file — they're baked into the app binary via `--dart-define-from-file`. |
| `env/nonprod.json` | `nonprod` | `API_BASE_URL` starts as a Terraform-output placeholder. `tools/check-env.ps1 -Flavor nonprod` refuses to let a build proceed until it's replaced with the real URL (`terraform output api_url` in the infra repo). |
| `env/prod.json` | `prod` | Same placeholder pattern as nonprod. |

`lib/core/config.dart` (`AppConfig`) reads these via `String.fromEnvironment`, so every `flutter run`/`build`
call must pass `--dart-define-from-file=env/<flavor>.json` — `tools/run.ps1`/`tools/build.ps1` do this for
you.

## 5. Creating a signing key

Once, on your machine (or a shared secure location — **never commit the resulting file**):

```powershell
keytool -genkey -v -keystore homeschooling-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias homeschooling
```

Then create `android/key.properties` (already in `.gitignore`):

```properties
storeFile=C:\\path\\to\\homeschooling-release.jks
storePassword=...
keyAlias=homeschooling
keyPassword=...
```

`tools/build.ps1` (and `bootstrap.ps1`'s Gradle patch) picks this up automatically for release builds. For CI
release builds, the keystore is stored **base64-encoded in a GitHub secret** (`RELEASE_KEYSTORE_BASE64`, see
`.github/workflows/release.yml`) and decoded to a temp file for the duration of the job only — it is never
committed.

## 6. Building

```powershell
pwsh tools/build.ps1 -Flavor dev -Target apk           # debug apk, dev flavor
pwsh tools/build.ps1 -Flavor prod -Target appbundle     # release appbundle, prod flavor (needs key.properties)
```

`tools/build.ps1` runs `tools/check-env.ps1` first, so it refuses nonprod/prod builds against a
still-placeholder `API_BASE_URL`.

Outputs land under the usual Flutter paths: `build/app/outputs/flutter-apk/` for APKs,
`build/app/outputs/bundle/<flavor>Release/` for app bundles.

For Play Console upload steps (internal testing track, closed testing, production rollout, content rating,
data safety form, etc.), see the separate **deployment guide** PDF — this README only covers getting to a
built `.aab`.

## 7. Testing

```powershell
flutter analyze
flutter test
pwsh tools/test-bootstrap.ps1     # verifies tools/bootstrap.ps1's Gradle/manifest patches, see its header comment
python3 tools/verify_api_paths.py --openapi ../api-contracts/openapi/openapi.json
```

`test/` layout:
- unit tests for the Riverpod notifiers in `lib/state/` (mocktail against the `lib/data/*_repository.dart`
  interfaces — see `test/support/mock_repositories.dart`)
- `test/pending_queue_test.dart` — offline queue retry/backoff behaviour
- `test/dates_test.dart` — calendar helpers (weeks start Monday)
- `test/answer_payload_test.dart` — one real step-JSON example per type from `backend-api/seed/launch-bundle.json`
  (copied into `test/fixtures/steps_sample.json`), parsed and checked against the answer shapes in
  `api-contracts/docs/client-guide.md`
- `test/router_guard_test.dart` — the child-mode/auth/update-gate route guard, as a pure function
  (`lib/state/router_guard.dart`), so it's tested without a widget pump
- `test/image_manifest_test.dart`, `test/image_store_test.dart`, `test/widgets/step_picture_test.dart` — activity pictures:
  the `images` manifest and per-step/option `image` references, the hash-checked on-device cache (fake HTTP, temp
  folder), and the step views showing pictures with the text as fallback
- `test/widgets/` — a couple of widget tests (the PIN pad, one player step view)

## 8. Architecture map

```
lib/
  core/        HTTP client, token refresh, PIN elevation, offline submit queue, validators, dates, the activity picture
               cache (image_store.dart) — no Flutter imports
  models/      Immutable data classes + fromJson, one file per API resource
  data/        One repository per API area (auth, family, children, catalogue, curriculum, planning,
               progress, pin, config, sessions) — thin wrappers over core/api_client.dart
  state/       Riverpod (3.x, Notifier/AsyncNotifier — not the legacy StateProvider/StateNotifierProvider)
               providers wiring repositories to the UI: one small notifier per concern
  strings.dart All user-facing copy (English only for MVP)
  theme.dart   Material 3 light/dark theme (+ a child-mode accent)
  app.dart     go_router routes, redirect guard, MaterialApp.router
  main.dart    Bootstraps AppEnvironment (secure storage, token manager, repositories), then runs the app
  features/
    auth/        signup/login
    guardian/    DPDP guardian-verification wizard (phone -> OTP -> declaration)
    pin/         set/verify/reset PIN, lockout countdown
    profiles/    who's-learning switcher, add/edit child
    child_home/  child's today-plan screen (locked to this screen while in child mode)
    player/      one widget per activity step type, under player/step_views/
    parent/      dashboard, planner, catalogue, progress/mastery, reviews, settings
    common/      loading/error/empty states, PIN pad, chip picker
tools/         bootstrap/build/run/check-env PowerShell scripts + the Android template overlay they use
```

Auth/session state: `lib/state/environment.dart` builds one `AppEnvironment` (repositories + `TokenManager` +
the offline `PendingQueue`) at startup and hands it down via a single Riverpod `Provider` override, so tests
can swap in mocks without touching plugins.

## 9. Hardening backlog (not done for MVP)

- **Certificate pinning** for the API base URL (currently plain TLS trust chain validation only).
- **Root/jailbreak and debugger detection** before allowing child-mode PIN exit.
- **Biometric unlock** as an alternative to the PIN for leaving child mode.
- **Real audio/photo capture** for `audio_record`/`photo_evidence` steps (MVP is "do it with a grown-up,
  tap Done" — no in-app recording or upload yet, so `media/presign` and `media/complete` are unused so far).
- **Crash reporting / structured client logging** (no Sentry/Crashlytics wired up yet).
- **Accessibility pass**: screen-reader labels and dynamic type scaling have not been audited.
- **Deep linking** (e.g. opening a specific activity from a notification) is not implemented; `lib/app.dart`'s
  router assumes it always starts at `/splash`.
- **Localisation**: `lib/strings.dart` is English-only; no `intl`/ARB pipeline yet.
- The DPDP guardian-declaration text in `lib/strings.dart` (`Str.guardianDeclarationDraft`) is a **draft**
  pending legal review — do not ship without sign-off.
