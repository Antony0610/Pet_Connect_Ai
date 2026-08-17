# Phase 11 — Analytics & Reports Architecture

## 1. Overview & Architectural Scope

Phase 11 introduces aggregate analytics and platform-wide ecosystem reporting for PetConnect AI without exposing personally identifiable information (PII) or compromising cross-tenant data boundaries.

### Core Philosophy
- **No PII in Analytics**: Individual user emails, phone numbers, addresses, and pet medical notes are strictly excluded from analytics data sources.
- **Strict Role & Tenant Isolation**: Materialized views bypass standard PostgreSQL row-level security (RLS). To prevent cross-tenant data leakage, a **Security-Invoker Wrapper View Architecture** is enforced at the database level.
- **Honest Data States**: Zero fake/mock values are rendered on frontend portals. Screens reflect genuine backend aggregate counts, loading indicators, empty states, or error retry states.

---

## 2. Database Objects & Security Layer

### A. Materialized Views

1. **`public.mv_clinic_analytics`**
   - **Granularity**: Monthly aggregate per clinic (`clinic_id`, `report_month`).
   - **Unique Index**: `uidx_mv_clinic_analytics_clinic_month` ON `(clinic_id, report_month)` (enables `REFRESH CONCURRENTLY`).
   - **Metrics Aggregated**:
     - `total_appointments`
     - `completed_appointments`
     - `cancelled_appointments`
     - `avg_duration_minutes`
     - `total_consultations`
     - `total_prescriptions`
     - `total_vaccinations` (correlated via pet appointment activity in the same calendar month)
     - `unique_patients`
     - `refreshed_at`

2. **`public.mv_platform_reports`**
   - **Granularity**: Monthly platform-wide aggregate (`report_month`).
   - **Unique Index**: `uidx_mv_platform_reports_month` ON `(report_month)`.
   - **Metrics Aggregated**:
     - `total_users`, `total_pet_owners`, `total_veterinarians`, `total_rescuers`, `total_administrators`
     - `total_appointments`, `completed_appointments`
     - `total_ai_conversations`, `total_ai_scans`
     - `total_rescue_missions`, `total_lost_pet_alerts`
     - `refreshed_at`

### B. Security-Invoker Wrapper Views

Because PostgreSQL (including 17.6) does not support RLS directly on materialized views, security-invoker views wrap the underlying materialized tables:

1. **`public.vw_clinic_analytics` (`WITH (security_invoker = true)`)**
   - Restricts rows to clinics where `auth.uid()` matches `vet_clinics.owner_id` or `clinic_staff.user_id`.
   - Denies access to non-veterinarian roles and anonymous callers.

2. **`public.vw_platform_reports` (`WITH (security_invoker = true)`)**
   - Restricts access exclusively to users with `role = 'administrator'` in `public.profiles`.
   - Denies access to veterinarians, pet owners, rescuers, and anonymous callers.

### C. Maintenance & Refresh RPC

**`public.refresh_analytics_views()`**
- **Security**: `SECURITY DEFINER`, with explicit `SET search_path = public`.
- **Authorization**: Validates that `auth.uid()` belongs to an active `administrator`. Throws `42501 (Permission Denied)` for all other roles or anonymous requests.
- **Execution**: Refreshes `mv_clinic_analytics` and `mv_platform_reports` using `CONCURRENTLY`.

---

## 3. Clean Architecture Integration

### Domain Layer
- **`ClinicAnalyticsSummary`**: Immutable entity representing one calendar-month clinic aggregate row.
- **`PlatformReportSummary`**: Immutable entity representing platform-wide ecosystem metrics.

### Data Layer
- **`ClinicAnalyticsSummaryModel`**: JSON deserialization and serialization for clinic analytics.
- **`PlatformReportSummaryModel`**: JSON deserialization and serialization for platform reports.
- **`VetRemoteDataSource.getClinicAnalytics(clinicId)`**: Queries `vw_clinic_analytics` ordered by `report_month DESC`.
- **`AdminRemoteDataSource.getPlatformReports()`**: Queries `vw_platform_reports` via `maybeSingle()`.

### Repositories
- **`VetRepository.getClinicAnalytics(clinicId)`** / `VetRepositoryImpl`: Maps data source responses to `Either<Failure, List<ClinicAnalyticsSummary>>`.
- **`AdminRepository.getPlatformReports()`** / `AdminRepositoryImpl`: Maps data source responses to `Either<Failure, PlatformReportSummary?>`.

### Riverpod Providers
- **`vetClinicAnalyticsProvider(clinicId)`**: `FutureProvider.family` managing clinic analytics state.
- **`adminPlatformReportsProvider`**: `FutureProvider` managing platform reports state.

---

## 4. Frontend Portals

1. **Veterinarian Clinic Analytics Screen (`/vet/analytics`)**
   - Replaced static layout with Riverpod-driven `ConsumerStatefulWidget`.
   - Dynamically resolves the veterinarian's clinic via `vetClinicsProvider`.
   - Timeframe Selector: Supports `This Month`, `3 Months`, `6 Months`, and `YTD` aggregation over monthly backend rows.
   - Live KPI cards: Unique patients, completion rates, average consultation duration, prescription volume, appointment bar trends, and clinical breakdown.

2. **Administrator Platform Reports Screen (`/admin/reports`)**
   - Replaced hardcoded figures (`24.5k`, `1.2M`) with live database counts from `adminPlatformReportsProvider`.
   - Ecosystem KPI grid: Users (pet owners, vets, rescuers, admins), Activity (AI scans, consultations, rescue missions).
   - On-demand refresh button triggers provider invalidation.

---

## 5. Verification & Security Test Suite

### Database Level Verification (8/8 Verified in PostgreSQL)
1. Pet owner querying `vw_clinic_analytics` &rarr; **BLOCKED** (0 rows returned).
2. Veterinarian querying another clinic's analytics &rarr; **BLOCKED** (0 rows returned).
3. Veterinarian querying `vw_platform_reports` &rarr; **BLOCKED** (0 rows returned).
4. Administrator querying `vw_platform_reports` &rarr; **ALLOWED** (aggregate data returned).
5. Anonymous caller querying `vw_clinic_analytics` &rarr; **BLOCKED** (0 rows returned).
6. Anonymous caller querying `vw_platform_reports` &rarr; **BLOCKED** (0 rows returned).
7. Non-admin invoking `refresh_analytics_views()` &rarr; **BLOCKED** (Exception: `Permission denied: only administrators may refresh analytics views`).
8. Administrator invoking `refresh_analytics_views()` &rarr; **ALLOWED** (Matviews refreshed concurrently).

### Automated Unit Test Suite
- `ClinicAnalyticsSummaryModel` JSON serialization & round-trip tests.
- `PlatformReportSummaryModel` JSON serialization & round-trip tests.
- `VetRepository` clinic analytics success & failure handling.
- `AdminRepository` platform reports success, null-state & failure handling.
- `vetClinicAnalyticsProvider` and `adminPlatformReportsProvider` state management tests.

---

## 6. System Classification

| Feature Area | Classification | Notes |
|---|---|---|
| Materialized Views & Refresh RPC | **LIVE BACKEND** | Deployed & verified in Supabase PostgreSQL |
| Security-Invoker Wrapper Views | **LIVE BACKEND** | Enforced at database level |
| Clinic Analytics Entity & DTO | **SOFTWARE IMPLEMENTED** | Full Clean Architecture integration |
| Platform Reports Entity & DTO | **SOFTWARE IMPLEMENTED** | Full Clean Architecture integration |
| Vet Clinic Analytics Screen | **SOFTWARE IMPLEMENTED** | Connected to live backend provider |
| Admin Platform Reports Screen | **SOFTWARE IMPLEMENTED** | Connected to live backend provider |
| Physical Scanner / Collar GPS | **HARDWARE DEPENDENT** | Hardware telemetry feeds smart collar tables |
