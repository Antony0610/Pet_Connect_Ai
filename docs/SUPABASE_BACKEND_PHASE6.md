# Phase 6: Administrator Portal Backend & Governance — Implementation Documentation

## Overview
Phase 6 implements the backend and Clean Architecture integration for the Administrator Portal. It establishes audit logging, global platform configurations, and security-governed user directory views for system administrators.

**Supabase Project Reference:** `cghgslyikjqghrzhrqxz`  
**Supabase Project Name:** PetConnect AI  
**Deployment Date:** August 12, 2026  

---

## 1. Database Schema & Supabase Objects

### Tables Created

#### 1. `public.audit_logs`
Immutable audit log record storing system-wide admin and security events.

```sql
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  severity TEXT NOT NULL DEFAULT 'INFO',
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT chk_audit_severity CHECK (severity IN ('INFO', 'WARNING', 'CRITICAL'))
);
```

#### 2. `public.platform_settings`
Global key-value settings managed by system administrators.

```sql
CREATE TABLE IF NOT EXISTS public.platform_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value JSONB NOT NULL DEFAULT '{}'::jsonb,
  description TEXT,
  updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

---

### Views Created

#### 1. `public.vw_admin_user_directory`
Roster projection of `public.profiles` for administrator user governance.

> [!IMPORTANT]
> Created with `WITH (security_invoker = true)` to strictly enforce row-level security policies of underlying tables.

```sql
CREATE OR REPLACE VIEW public.vw_admin_user_directory
WITH (security_invoker = true) AS
SELECT
  p.id,
  p.full_name,
  p.email,
  p.role,
  p.avatar_url,
  p.created_at,
  p.updated_at
FROM public.profiles p
ORDER BY p.created_at DESC;
```

---

## 2. Row Level Security (RLS) Policies

Row-level security is enabled on all Phase 6 tables with role checking against `public.profiles.role = 'administrator'`:

1. **`audit_logs`**:
   - `SELECT`: Only users with `role = 'administrator'` in `public.profiles`.
   - `INSERT`: Administrators and system functions (actor_id = auth.uid()).
   - `UPDATE` / `DELETE`: Forbidden (immutable audit log requirement).

2. **`platform_settings`**:
   - `SELECT`: Only administrators (`profiles.role = 'administrator'`).
   - `INSERT`: Only administrators.
   - `UPDATE`: Only administrators.

---

## 3. Clean Architecture Integration

### Domain Layer
- **Entities**: `AuditLogEntry`, `PlatformSetting`, `AdminUserEntry`
- **Repository Interface**: `AdminRepository`
- **Use Cases**: `GetAuditLogs`, `CreateAuditLog`, `GetPlatformSettings`, `UpdatePlatformSetting`, `GetAdminUserDirectory`

### Data Layer
- **Models**: `AuditLogModel`, `PlatformSettingModel`, `AdminUserEntryModel`
- **Data Source**: `AdminRemoteDataSourceImpl` (Supabase PostgREST)
- **Repository**: `AdminRepositoryImpl` with `FailureMapper` integration

### Presentation Layer
- **Providers**: `adminAuditLogsProvider`, `adminPlatformSettingsProvider`, `adminUserDirectoryProvider`
- **Screens Connected**:
  - `AdminAuditLogsScreen` → Live `audit_logs` data with severity badge formatting and filtering
  - `AdminUserManagementScreen` → Live `vw_admin_user_directory` roster with stats and role filters

---

## 4. Verification Results

- **Unit Tests**: 132/132 unit tests passing (`flutter test`).
- **Static Analysis**: `flutter analyze --no-fatal-infos` clean (0 errors, 0 warnings).
- **View Security**: Verified `vw_admin_user_directory` has `reloptions = ["security_invoker=true"]`.
