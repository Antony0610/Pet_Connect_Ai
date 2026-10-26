# Deployment & Operations Plan

This document details the production build, deployment, and operational procedures for **PetConnect AI**, covering the native Android mobile application, the React 19 web portal on Vercel, and the Supabase backend with serverless Edge Functions.

---

## 1. Environments & Infrastructure Topology

The system operates across three standard environments:

| Environment | Purpose | Supabase Project | Web Portal (Vercel) | Mobile Application ID |
| :--- | :--- | :--- | :--- | :--- |
| **`dev`** | Local feature work | `petconnect-dev` | `petconnect-dev.vercel.app` | `com.petconnect.ai.petconnect_ai.dev` |
| **`staging`** | Internal QA & Test Tracks | `petconnect-staging` | `petconnect-staging.vercel.app` | `com.petconnect.ai.petconnect_ai.staging` |
| **`prod`** | Public Production | `petconnect-prod` (`cghgslyikjqghrzhrqxz`) | `petconnect-ai.vercel.app` | `com.petconnect.ai.petconnect_ai` |

---

## 2. Secrets Management & Environment Isolation

PetConnect AI enforces zero hardcoded secrets:

1. **Client Mobile `.env`**:
   - Kept in `petconnect_ai/.env` (strictly ignored by `.gitignore`).
   - Contains only client-safe keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AI_EDGE_FUNCTION_URL`.
   - Never commit `.env` or production keystores to version control.
2. **Serverless AI Secrets**:
   - `GEMINI_API_KEY` is never exposed to client applications.
   - Configured in Supabase via Edge Secrets:
     ```bash
     supabase secrets set GEMINI_API_KEY="your-gemini-api-key"
     supabase secrets set SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
     ```
3. **Web Portal Environment Variables**:
   - Configured in Vercel project settings:
     - `VITE_SUPABASE_URL`
     - `VITE_SUPABASE_ANON_KEY`

---

## 3. Android Mobile Build & Release

The Android build toolchain is fully configured and production-verified:
- **AGP**: `8.9.1`
- **Gradle**: `8.12.1`
- **Kotlin**: `2.2.20`
- **Target SDK**: `34` (Android 14) / **Min SDK**: `21` (Android 5.0)
- **Java Compatibility**: `JavaVersion.VERSION_17` with core library desugaring enabled (`desugar_jdk_libs:2.1.5`).

### 3.1 Local Release Verification
```bash
# 1. Run static analysis
flutter analyze

# 2. Run unit tests
flutter test test/unit

# 3. Build standalone production APK
flutter build apk --release

# 4. Build Google Play Store App Bundle (AAB)
flutter build appbundle --release
```

Compiled artifacts:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### 3.2 Distribution & Security Policy
- In accordance with security best practices, raw compiled binary APKs (`.apk`, `.aab`) are excluded from Git history to prevent binary bloat and asset extraction.
- Official release builds are tagged (e.g. `v1.0.3`) and published directly to **GitHub Releases**.

---

## 4. Web Portal Deployment (Vercel)

The React 19 web companion (`web_portal/`) is hosted on Vercel:

### 4.1 CLI Deployment
```bash
cd web_portal

# Deploy preview build
npx vercel

# Deploy production release
npx vercel --prod
```

### 4.2 GitHub Automated CI/CD
1. Link GitHub repository to Vercel.
2. Set **Root Directory** to `web_portal`.
3. Set **Framework Preset** to `Vite`.
4. Ensure `vercel.json` contains universal SPA rewrites so direct routes (`/emergency/:id`, `/verify/:id`) resolve properly:
   ```json
   {
     "rewrites": [
       { "source": "/(.*)", "destination": "/index.html" }
     ]
   }
   ```

---

## 5. Supabase Backend & Edge Functions Deployment

### 5.1 Database Migrations
Migrations are managed via the Supabase CLI:
```bash
# Link local CLI to live Supabase project
supabase link --project-ref cghgslyikjqghrzhrqxz

# Apply new migrations and RLS policies
supabase db push
```

### 5.2 Deploying Edge Functions
All three AI microservices run on the Deno runtime:
```bash
# Deploy universal assistant
supabase functions deploy ai-assistant --no-verify-jwt

# Deploy multimodal symptom scanner
supabase functions deploy ai-symptom-scan --no-verify-jwt

# Deploy clinical report generator
supabase functions deploy ai-report-generator --no-verify-jwt
```
*(Note: Edge functions internally validate callers and origin headers via CORS whitelisting).*

---

## 6. Pre-Flight Release Checklist

- [ ] `flutter analyze` returns 0 warnings and 0 errors.
- [ ] All unit and widget tests pass (`flutter test`).
- [ ] `.env` is absent from git tracking (`git status` is clean).
- [ ] Vercel web portal builds without TypeScript or bundling warnings (`npm run build`).
- [ ] Edge Functions respond to health requests and have `GEMINI_API_KEY` set.
- [ ] RLS policies are active on `pets`, `profiles`, `health_records`, and `collar_telemetry`.
- [ ] Single Prototype Tag `TAG-PROTOTYPE-001` resolves properly on both Web Portal and Mobile Scanner.
