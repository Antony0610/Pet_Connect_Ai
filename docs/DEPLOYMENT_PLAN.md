# Deployment Plan

Build and release plan for **PetConnect AI** (Flutter + Supabase). Covers flavors, per-store release steps, Supabase environments and migrations, secrets, CI/CD, versioning, FCM, Google Maps key restriction, code signing, and staged rollout.

> **Note on native folders:** the repository is currently Dart-only (`pubspec.yaml`, `lib/`, `docs/`). The `android/` and `ios/` folders are **generated later** with:
> ```bash
> flutter create --platforms=android,ios .
> ```
> Run this from the project root before the first native build. All native config below (signing, Gradle flavors, plist entries) applies after that step.

---

## 1. Flavors and environments

Three flavors map to three Supabase projects and three Firebase apps:

| Flavor | Purpose | Supabase project | Firebase project | Bundle/App ID |
|--------|---------|------------------|------------------|---------------|
| `dev` | local + feature work | `petconnect-dev` | `petconnect-dev` | `ai.petconnect.dev` |
| `staging` | QA / TestFlight / internal track | `petconnect-staging` | `petconnect-staging` | `ai.petconnect.staging` |
| `prod` | public release | `petconnect-prod` | `petconnect` | `ai.petconnect` |

### Config strategy

Environment values come from `flutter_dotenv` (`.env` files) for non-secret runtime config, and from `--dart-define` for values injected by CI. `.env` is bundled as an asset (see `pubspec.yaml`), so **only non-secret** values belong there — the Supabase anon key and URL are safe to ship (they are public by design and protected by RLS); private keys are not.

`.env.dev` / `.env.staging` / `.env.prod`:

```dotenv
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
GOOGLE_MAPS_API_KEY=AIza...
GEMINI_API_KEY=          # injected at runtime via dart-define, not stored here for prod
ENV=dev
```

Select the file at build time and load it in `main`:

```dart
Future<void> main() async {
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  await dotenv.load(fileName: '.env.$env');
  runApp(const ProviderScope(child: App()));
}
```

Build invocations:

```bash
# dev
flutter run --dart-define=ENV=dev

# staging build
flutter build apk --dart-define=ENV=staging --flavor staging

# prod release
flutter build appbundle --dart-define=ENV=prod --flavor prod
```

Secrets that must not ship in the bundle (e.g. `GEMINI_API_KEY` used only server-side) live in **Supabase Edge Function secrets** or CI, never in `.env` committed to git.

---

## 2. Secrets management

- **Never commit** any `.env*` file. Add to `.gitignore`:
  ```gitignore
  .env
  .env.*
  *.keystore
  *.jks
  ios/Runner/GoogleService-Info.plist
  android/app/google-services.json
  **/key.properties
  ```
- Commit a `.env.example` with keys but no values.
- CI reads secrets from **GitHub Actions encrypted secrets** and writes them into `.env.<flavor>` at build time.
- AI inference keys (Gemini) belong in **Edge Function secrets** (`supabase secrets set GEMINI_API_KEY=...`) so the key never reaches the client. The Flutter app calls the Edge Function, not Gemini directly, for privileged operations.
- Android signing keys and Apple certificates live in CI secrets / a secure keystore, not the repo.

---

## 3. Supabase environments and migration workflow

Three isolated Supabase projects (dev/staging/prod). Schema is managed with the **Supabase CLI** and version-controlled SQL migrations under `supabase/migrations/`.

```bash
# one-time
supabase init
supabase link --project-ref <dev-ref>

# author a change locally
supabase db diff -f add_geofences   # generates a timestamped migration

# apply to an environment
supabase link --project-ref <staging-ref>
supabase db push
```

Workflow:

1. Develop against a **local** Supabase (`supabase start`) or the dev project.
2. Generate migrations with `supabase db diff`; review the SQL by hand.
3. Promote by running `supabase db push` against staging, then prod, in order.
4. RLS policies, enums, extensions (`vector`, `postgis`), and RPCs are all part of migrations — never applied manually in the dashboard for prod.
5. Edge Functions deploy per environment: `supabase functions deploy <name> --project-ref <ref>`.
6. Seed data (reference tables, demo accounts) via `supabase db seed` for dev/staging only.

Migrations are **forward-only**; roll back by writing a new compensating migration.

---

## 4. CI/CD outline (GitHub Actions)

Pipeline stages: **analyze → test → build**. Release builds run only on tags.

```yaml
name: ci
on:
  push:
    branches: [main, develop]
  pull_request:
  workflow_dispatch:

jobs:
  analyze-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: dart format --set-exit-if-changed .
      - run: flutter test --coverage

  build-android:
    needs: analyze-test
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - name: Write env + secrets
        run: |
          echo "${{ secrets.ENV_PROD }}" > .env.prod
          echo "${{ secrets.ANDROID_KEYSTORE_B64 }}" | base64 -d > android/app/upload.jks
      - run: flutter build appbundle --dart-define=ENV=prod --flavor prod
      - uses: actions/upload-artifact@v4
        with: { name: appbundle, path: build/app/outputs/bundle/prodRelease/*.aab }

  build-ios:
    needs: analyze-test
    if: startsWith(github.ref, 'refs/tags/')
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ipa --dart-define=ENV=prod --flavor prod --export-options-plist=ios/ExportOptions.plist
```

Notes:
- `build_runner` runs before analyze so generated `freezed`/`json_serializable`/`riverpod` files exist.
- Store uploads (Play/App Store) can be added with `fastlane` or the respective upload actions, gated behind manual approval.

---

## 5. Versioning strategy

- `pubspec.yaml` `version: <semver>+<build>` (currently `1.0.0+1`).
- **Semantic versioning** for the marketing version: `MAJOR.MINOR.PATCH`.
- Build number auto-incremented in CI (e.g. `--build-number=${{ github.run_number }}`), keeping it monotonic — required by both stores.
- Git tags drive releases: `v1.2.0` triggers the release build.
- Override at build time without editing pubspec:
  ```bash
  flutter build appbundle --build-name=1.2.0 --build-number=45 --flavor prod
  ```

---

## 6. Android (Play Store) release

After `flutter create` has generated `android/`:

1. **Flavors** in `android/app/build.gradle`:
   ```groovy
   flavorDimensions "env"
   productFlavors {
     dev     { dimension "env"; applicationId "ai.petconnect.dev";     resValue "string", "app_name", "PetConnect Dev" }
     staging { dimension "env"; applicationId "ai.petconnect.staging"; resValue "string", "app_name", "PetConnect QA" }
     prod    { dimension "env"; applicationId "ai.petconnect";          resValue "string", "app_name", "PetConnect AI" }
   }
   ```
2. **Signing** — create an upload keystore, reference via `key.properties` (git-ignored):
   ```properties
   storeFile=upload.jks
   storePassword=***
   keyAlias=upload
   keyPassword=***
   ```
   Wire `signingConfigs.release` to read `key.properties`; enable Play App Signing (Google holds the app signing key, you hold the upload key).
3. Add `google-services.json` per flavor under `android/app/src/<flavor>/`.
4. Build: `flutter build appbundle --dart-define=ENV=prod --flavor prod`.
5. Upload the `.aab` to the Play Console → **Internal testing** → Closed → Production, promoting through tracks.

---

## 7. iOS (App Store) release

After `flutter create` has generated `ios/`:

1. **Schemes/configs** — add `Debug/Release/Profile` × flavor build configurations in Xcode, or use `--flavor` with a matching scheme.
2. Set bundle IDs per flavor in the target (`ai.petconnect`, `.staging`, `.dev`).
3. Add `GoogleService-Info.plist` per flavor (via build phase copy or per-config folders).
4. **Signing** — managed by Xcode automatic signing for dev; for CI use manual signing with distribution certificate + provisioning profile stored in CI (e.g. via `match`/App Store Connect API key).
5. Build: `flutter build ipa --dart-define=ENV=prod --flavor prod --export-options-plist=ios/ExportOptions.plist`.
6. Upload with `xcrun altool` / Transporter / `fastlane pilot` to **TestFlight**, then submit for App Store review.

---

## 8. Firebase / FCM setup per environment

- One Firebase project per environment (dev/staging/prod) to keep push tokens and analytics isolated.
- Register the flavor's bundle/app ID in each Firebase project and download the config:
  - Android: `google-services.json` → `android/app/src/<flavor>/`
  - iOS: `GoogleService-Info.plist` → per-config
- `firebase_core` initializes from the platform config file automatically; ensure the correct file ships per flavor.
- APNs: upload the Apple **APNs auth key** to the Firebase project for iOS push.
- FCM tokens are stored server-side (linked to `profiles`) so Edge Functions / n8n can target notifications; token refresh updates the stored value.

---

## 9. Google Maps API key restriction per platform

`google_maps_flutter` needs a key per platform. Use **separate keys** for Android and iOS, restricted in Google Cloud Console:

| Platform | Key restriction | API enabled |
|----------|-----------------|-------------|
| Android | Application restriction: package name + SHA-1 fingerprint (per flavor) | Maps SDK for Android |
| iOS | Application restriction: iOS bundle ID (per flavor) | Maps SDK for iOS |

- Android key goes in `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`) — inject the flavor-specific value via manifest placeholder from `.env`/dart-define rather than hardcoding.
- iOS key set in `AppDelegate` via `GMSServices.provideAPIKey(...)`, read from the loaded env.
- Enable **API restriction** (limit each key to only the Maps SDK it needs) to reduce blast radius if leaked.
- Never reuse the browser/unrestricted key; rotate keys if exposed.

---

## 10. Code signing notes

| Platform | Dev | CI / Release |
|----------|-----|--------------|
| Android | debug keystore (auto) | upload keystore from CI secret (`ANDROID_KEYSTORE_B64`), Play App Signing enabled |
| iOS | Xcode automatic signing | manual signing; distribution cert + provisioning profile via App Store Connect API key in CI |

- Keep the upload keystore and its passwords out of git; loss of the **upload** key is recoverable with Play support, loss of the app signing key is not (mitigated by Play App Signing).
- For iOS, store the App Store Connect API key (`.p8`), key ID, and issuer ID as CI secrets.

---

## 11. Staged rollout and monitoring

**Rollout**
- Android: use **staged rollout** in Play Console — start at 5–10%, watch crash-free rate, ramp to 100%.
- iOS: use **phased release** (7-day automatic ramp) in App Store Connect.
- Promote through tracks: internal → closed (staging testers) → open beta → production.

**Monitoring**
- Firebase Crashlytics for crash reporting (per environment project).
- Supabase logs / dashboard for query errors, Edge Function logs, RLS denials.
- App-side structured logging via `logger` (see `API_CONVENTIONS.md`), with a remote sink for prod.
- Alerting: n8n workflow watches error thresholds (crash spike, Edge Function failures) and posts to the team channel.
- Roll back a bad release by halting the staged rollout and shipping a hotfix build with an incremented build number; roll back schema with a compensating migration.

---

## Release checklist

- [ ] `flutter create --platforms=android,ios .` has been run (native folders exist)
- [ ] Correct `.env.<flavor>` written by CI; no secrets committed
- [ ] `build_runner` codegen succeeds; `flutter analyze` and `flutter test` green
- [ ] Version + build number bumped (tag pushed)
- [ ] Supabase migrations applied to target environment in order
- [ ] Edge Function secrets set for the environment
- [ ] Firebase config file present for the flavor; APNs key uploaded (iOS)
- [ ] Google Maps keys restricted per platform/flavor
- [ ] Signing configured (keystore / provisioning profile from CI)
- [ ] Staged/phased rollout enabled; Crashlytics + Supabase monitoring live
