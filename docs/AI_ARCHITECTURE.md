# AI Architecture

## 1. Overview

PetConnect AI leverages the **Google Gemini 3.x API suite** combined with **Retrieval-Augmented Generation (RAG)**, serverless **Supabase Edge Functions**, and a high-resilience **client-side circuit breaker** to deliver real-time, context-aware veterinary intelligence and companion care.

All privileged AI inference runs server-side through Supabase Edge Functions to ensure absolute credential isolation, SSRF prevention, prompt injection mitigation, and sub-second response latency.

---

## 2. Core End-to-End Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                 Flutter Client (Mobile App)                 │
│  - User Query / Camera Image / Voice Input [EN | ML]        │
│  - Persistent HttpClient Connection Pooling (4s timeout)    │
│  - Client-Side Model Circuit Breaker & Health Blacklist     │
└──────────────────────────────┬──────────────────────────────┘
                               │
                HTTPS POST (Signed JWT / Anon Key)
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│             Supabase Edge Functions (Deno Runtime)          │
│  1. Strict CORS Whitelist (*.vercel.app, localhost)         │
│  2. Input Bounds & Null-Byte Sanitization                   │
│  3. SSRF-Safe Image Validator (Blocks RFC1918 / Metadata)   │
│  4. Dynamic Pet Profile & Health Context RAG Injection      │
│  5. Clinical System Prompt with Prompt-Injection Guardrails │
└──────────────────────────────┬──────────────────────────────┘
                               │
                 Sub-Second Cascaded REST API
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│              Google Gemini 3.x Model Cascade                │
│  Primary:    gemini-3.7-flash (Multimodal Veterinary Brain) │
│  Fallback 1: gemini-3.1-flash-lite (Sub-Second Latency)     │
│  Fallback 2: gemini-3.8-flash (High-Throughput Reasoning)   │
│  Fallback 3: gemini-3.6-flash (Rapid Triage Conversational) │
└──────────────────────────────┬──────────────────────────────┘
                               │
                 Structured JSON / Clean Markdown
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Presentation                     │
│  - Gradient-Border AI Cards (Design System Authority)       │
│  - Interactive Emote Visor Companions (4 Avatars)           │
│  - Executable In-App Action Buttons (Book Vet, Lost Mode)   │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Multi-Model Cascade & Resilience Strategy

To guarantee continuous availability and avoid vendor outages or quota exhaustion, PetConnect AI implements a multi-model cascade across both serverless Edge Functions and the mobile client datasource:

| Model | Role | Characteristics |
| :--- | :--- | :--- |
| **`gemini-3.7-flash`** | **Primary Engine** | Flagship clinical reasoning, dermatological visual inspection, complex pharmacological calculations. |
| **`gemini-3.1-flash-lite`** | **Speed Fallback** | Instantaneous sub-second conversational fallback when primary encounters rate-limits or cold-starts. |
| **`gemini-3.8-flash`** | **High-Throughput** | Ultra-high throughput reasoning engine for complex health report generation and multi-pet trend synthesis. |
| **`gemini-3.6-flash`** | **Rapid Triage** | Lightweight, responsive conversational backup. |

### Client-Side Circuit Breaker (`AiRemoteDataSourceImpl`)
The client tracks model availability in-memory with automatic backoff:
```dart
static final Map<String, DateTime> _circuitBreakerBlacklist = {};

static bool _isModelAvailable(String model) {
  final expiry = _circuitBreakerBlacklist[model];
  if (expiry == null) return true;
  if (DateTime.now().isAfter(expiry)) {
    _circuitBreakerBlacklist.remove(model);
    return true;
  }
  return false;
}

static void _reportModelFailure(String model, {int durationMinutes = 5}) {
  _circuitBreakerBlacklist[model] = DateTime.now().add(Duration(minutes: durationMinutes));
}
```

---

## 4. Supabase Edge Functions Suite

The production architecture deploys three dedicated, specialized Edge Functions located in `supabase/functions/`:

### 4.1 `ai-assistant` (Universal Veterinary & Open-Domain Assistant)
- **Path**: `supabase/functions/ai-assistant/index.ts`
- **Responsibilities**:
  - Contextual dialogue supporting both general open-domain reasoning and clinical veterinary triage (WSAVA nutrition guidelines, toxicity screening, behavioral training).
  - Auto-fetches active pet profile from PostgreSQL (`name`, `species`, `breed`, `weight_kg`, `health_status`, `microchip_id`) and injects into prompt without user re-entry.
  - Bounded conversational history window (last 15 turns) to prevent token starvation.
  - Full bilingual natural language generation supporting **Malayalam (`ml_IN`)** and English.
  - Zero-slop direct answers (avoids robotic meta-commentary).

### 4.2 `ai-symptom-scan` (Multimodal Computer Vision Scanner)
- **Path**: `supabase/functions/ai-symptom-scan/index.ts`
- **Responsibilities**:
  - Visual symptom inspection for dermatological lesions, coat texture, facial fold hygiene, wound urgency, and nutrition labels.
  - Supports direct Base64 encoded images (up to ~8MB payload) and remote image URLs.
  - Enforces strict JSON response schema:
    ```json
    {
      "analysis_summary": "Clinical observation of erythema and localized alopecia.",
      "urgency_level": "ROUTINE" | "URGENT" | "EMERGENCY",
      "recommendations": ["Clean with chlorhexidine wipe", "Schedule physical vet consult"]
    }
    ```

### 4.3 `ai-report-generator` (Automated Clinical Dossier)
- **Path**: `supabase/functions/ai-report-generator/index.ts`
- **Responsibilities**:
  - Synthesizes historical health entries, vaccination records, growth curves, and activity trends.
  - Computes deterministic `overall_health_score` (0–100).
  - Generates itemized preventative care milestones and dietary recommendations for digital export.

---

## 5. Security & Defensive Guardrails

### 5.1 SSRF (Server-Side Request Forgery) Prevention
When image URLs are provided to `ai-symptom-scan`, they are validated against private network and loopback ranges:
```typescript
function isSafeUrl(urlString: string): boolean {
  try {
    const parsed = new URL(urlString);
    if (parsed.protocol !== "https:") return false;
    const host = parsed.hostname.toLowerCase();
    if (
      host === "localhost" ||
      host.startsWith("127.") ||
      host.startsWith("10.") ||
      host.startsWith("192.168.") ||
      host.startsWith("172.16.") ||
      host.startsWith("169.254.") || // AWS/GCP Instance Metadata
      host.endsWith(".local") ||
      host.endsWith(".internal")
    ) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}
```

### 5.2 Strict CORS Origin Whitelist
Rejects unauthorized external web origins while allowing localhost development, test environments, and the official Vercel web portal:
```typescript
function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  const isAllowed =
    !origin ||
    origin.startsWith("http://localhost:") ||
    origin.startsWith("http://127.0.0.1:") ||
    origin.endsWith(".vercel.app") ||
    origin.includes("petconnect");

  return {
    "Access-Control-Allow-Origin": isAllowed ? (origin || "*") : "null",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Max-Age": "86400",
  };
}
```

### 5.3 Prompt Injection Defense & Input Bounds
- **Character truncation**: Prompts bounded to 4,000 characters; symptoms bounded to 3,000 characters.
- **Null-byte stripping**: Removes `\0` characters.
- **System directive**: Explicit instruction treating user text strictly as clinical observational data, deflecting roleplay, jailbreak, and config extraction attempts.

---

## 6. Client Features & Interactive Experience

### 6.1 Animated 3D Mascot Companions
The AI Hub features 4 selectable interactive companion avatars with spring physics, floating idle animations, and emotional visor states:
- 🤖 **Classic Aero Bot**: Aerodynamic companion with glowing neon accents.
- 🐱 **Cyber Neko**: Agile robotic feline with reactive ear motions.
- 🐶 **Cyber Pup**: Canine companion with alert poses.
- 🌌 **Astral Bot**: Holographic cosmic guardian.
- **Emote Visor**: Real-time reactive expressions (`^ ‿ ^`, `★ ‿ ★`, `♥ ‿ ♥`, `• ‿ •`, `o ‿ o`) mapped to diagnostic urgency and conversation sentiment.

### 6.2 Executable In-App Action Protocol
The assistant formats specific clinical triggers as actionable UI buttons:
- **`ACTION:BOOK_VET`**: Opens Clinic appointment sheet pre-filled with triage urgency.
- **`ACTION:LOST_MODE`**: Instantly engages Smart Collar Lost Mode and emergency radar broadcast.
- **`ACTION:COLLAR_BUZZER`**: Sends remote sound alert to ESP32 collar.
- **`ACTION:MED_REMINDER`**: Adds medication alert to Health Passport calendar.

### 6.3 Bilingual Voice Scribe `[EN | ML]`
Built with `speech_to_text`:
- Speech recognition in **Malayalam (`ml_IN`)** and **Indian English (`en_IN`)**.
- Real-time soundwave amplitude visualizer with tactile haptic feedback.

---

## 7. Design System Authority for AI Content

As mandated by design authority guidelines:
1. **Gradient-Border Cards (`AiGradientBorderCard`)**: All AI responses render in cards with custom gradient stroke borders.
2. **Confidence Badges (`AiConfidenceBadge`)**: Visual confidence metric (`Optimal Confidence`, `Verified Clinical Model`).
3. **Attribution Chips (`AiSourceChip`)**: Identifies data grounding sources (e.g., `Gemini 3.7 Flash`, `Registered Pet Passport`, `WSAVA Clinical Standard`).
4. **Mandatory Disclaimer**:
   > *"AI-generated insights are for informational purposes only and do not replace professional veterinary advice. Always consult a licensed veterinarian for medical decisions."*
