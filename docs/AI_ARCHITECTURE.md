# AI Architecture

## Overview

PetConnect AI uses Google Gemini API combined with Retrieval-Augmented Generation (RAG) to provide intelligent, context-aware assistance for pet care. All AI inference runs server-side through Supabase Edge Functions to maintain security and protect API credentials.

## Core Pipeline

```
User Query
    ↓
Extract Intent & Context
    ↓
Generate Embedding (local)
    ↓
pgvector Similarity Search (Supabase)
    ↓
Retrieve Relevant Context (pet health records, knowledge base)
    ↓
Augment Prompt with Retrieved Data
    ↓
Edge Function → Gemini API Request
    ↓
Stream Response to Client
    ↓
Display in UI (gradient-border AI cards)
```

## Embeddings Strategy

### Embedding Sources
PetConnect generates and stores embeddings for:
- **Pet Health Records**: Vaccination history, medical diagnoses, treatment plans, vet notes
- **Knowledge Base**: Curated pet care articles, breed information, common health conditions
- **Community Content**: High-quality Q&A threads, expert advice, rescue protocols
- **User Context**: Pet profiles, preferences, historical interactions

### Storage Schema
```sql
CREATE TABLE embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  embedding VECTOR(768),  -- Gemini embedding dimension
  source_type TEXT NOT NULL,  -- 'health_record', 'knowledge_base', 'community'
  source_id UUID NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX ON embeddings USING ivfflat (embedding vector_cosine_ops);
```

### Embedding Generation
Embeddings are generated server-side when:
- New health records are created or updated
- Knowledge base articles are published
- Community content is marked as high-quality

Edge Function handles batch embedding generation:
```typescript
// Supabase Edge Function: generate-embeddings
const response = await fetch('https://generativelanguage.googleapis.com/v1/models/embedding-001:embedContent', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'x-goog-api-key': Deno.env.get('GEMINI_API_KEY')
  },
  body: JSON.stringify({ content: { parts: [{ text: content }] } })
});
```

## Retrieval Process

When a user submits a query:

1. **Query Embedding**: Convert user query to embedding vector
2. **Similarity Search**: Use pgvector to find top-k relevant contexts
```sql
SELECT content, metadata, 1 - (embedding <=> query_embedding) AS similarity
FROM embeddings
WHERE source_type = ANY($1)
ORDER BY embedding <=> query_embedding
LIMIT 5;
```
3. **Context Ranking**: Score results by relevance, recency, and source authority
4. **Prompt Augmentation**: Insert retrieved context into Gemini prompt

## Server-Side Inference

**CRITICAL**: Gemini API keys are NEVER exposed to the Flutter app. All AI requests flow through Supabase Edge Functions.

### Edge Function Architecture
```
petconnect_ai/
└── supabase/
    └── functions/
        ├── ai-chat/
        │   └── index.ts          # General AI assistant
        ├── ai-health-analysis/
        │   └── index.ts          # Analyze symptoms/photos
        ├── ai-health-report/
        │   └── index.ts          # Generate health reports
        ├── ai-emergency/
        │   └── index.ts          # Emergency triage
        └── ai-recommendations/
            └── index.ts          # Personalized insights
```

### Example Edge Function
```typescript
// supabase/functions/ai-chat/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const { query, petId, conversationHistory } = await req.json();
  
  // 1. Retrieve context via RAG
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  const queryEmbedding = await generateEmbedding(query);
  const { data: contexts } = await supabase.rpc('match_embeddings', {
    query_embedding: queryEmbedding,
    match_count: 5,
    filter: { pet_id: petId }
  });
  
  // 2. Build augmented prompt
  const prompt = buildPrompt(query, contexts, conversationHistory);
  
  // 3. Call Gemini with streaming
  const geminiResponse = await fetch(
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:streamGenerateContent',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': Deno.env.get('GEMINI_API_KEY')!
      },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        safetySettings: SAFETY_CONFIG,
        generationConfig: { temperature: 0.7, maxOutputTokens: 1024 }
      })
    }
  );
  
  // 4. Stream response back to client
  return new Response(geminiResponse.body, {
    headers: { 'Content-Type': 'text/event-stream' }
  });
});
```

## App-Side Service Interface

The Flutter app communicates only with Edge Functions, never directly with Gemini.

### ai_service.dart Interface Sketch
```dart
abstract class AIService {
  /// Stream AI assistant responses
  Stream<String> chatStream({
    required String petId,
    required String message,
    List<ChatMessage>? history,
  });
  
  /// Analyze health symptoms/photos
  Future<HealthAnalysisResult> analyzeHealth({
    required String petId,
    required String symptoms,
    List<String>? photoUrls,
  });
  
  /// Generate comprehensive health report
  Future<HealthReport> generateHealthReport({
    required String petId,
    required DateTimeRange period,
  });
  
  /// Get personalized recommendations
  Future<List<Recommendation>> getRecommendations({
    required String petId,
    required RecommendationType type,
  });
  
  /// Emergency triage assistant
  Future<EmergencyGuidance> getEmergencyGuidance({
    required String petId,
    required String situation,
  });
}

class SupabaseAIService implements AIService {
  final SupabaseClient _client;
  
  @override
  Stream<String> chatStream({
    required String petId,
    required String message,
    List<ChatMessage>? history,
  }) async* {
    final response = await _client.functions.invoke(
      'ai-chat',
      body: {
        'query': message,
        'petId': petId,
        'conversationHistory': history?.map((m) => m.toJson()).toList(),
      },
    );
    
    // Parse SSE stream
    yield* response.data.transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: '))
        .map((line) => line.substring(6))
        .map((json) => jsonDecode(json)['text'] as String);
  }
  
  // ... other implementations
}
```

## Streaming Responses

AI features use Server-Sent Events (SSE) for real-time streaming:
- Edge Function receives Gemini streaming response
- Parses chunks and forwards as SSE to client
- Flutter app displays tokens incrementally for responsive UX
- Gradient-border cards visually distinguish AI content

## Safety & Guardrails

### Content Safety
```typescript
const SAFETY_CONFIG = [
  { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
  { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
  { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
  { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
];
```

### Medical Disclaimer
All AI health features include prominent disclaimers:
> "AI-generated insights are for informational purposes only and do not replace professional veterinary advice. Always consult a licensed veterinarian for medical decisions."

### Rate Limiting
Implemented at Edge Function level using Supabase RLS:
- 100 requests/hour per user for chat
- 20 requests/hour for health analysis
- 5 requests/day for full health reports

## Cost Controls

### Token Management
- **Max Input Tokens**: 2048 per request
- **Max Output Tokens**: 1024 per response
- Conversation history truncated to last 10 messages
- Long documents summarized before embedding

### Caching Strategy
```sql
CREATE TABLE ai_cache (
  query_hash TEXT PRIMARY KEY,
  response JSONB NOT NULL,
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  hit_count INT DEFAULT 1
);

CREATE INDEX ON ai_cache (cached_at) WHERE hit_count > 3;
```
Cache common queries (e.g., "How often should I feed my puppy?") to reduce API calls.

### Budget Monitoring
Track usage in Supabase:
```sql
CREATE TABLE ai_usage_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  function_name TEXT NOT NULL,
  input_tokens INT,
  output_tokens INT,
  cost_usd DECIMAL(10, 6),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## AI Feature Mapping

| UI Feature | Edge Function | Purpose |
|------------|---------------|---------|
| AI Assistant Chat | `ai-chat` | General Q&A, advice |
| AI Health Analysis | `ai-health-analysis` | Symptom analysis, photo recognition |
| AI Health Reports | `ai-health-report` | Comprehensive health summaries |
| AI Insights/Recommendations | `ai-recommendations` | Personalized tips |
| AI Emergency Assistant | `ai-emergency` | Triage & first aid |
| AI Health Trends | `ai-chat` | Analyze historical health data |
| AI Hub | Portal UI | Aggregates all AI features |

## Privacy & Data Security

### Data Handling
- **PII Redaction**: Strip owner PII before sending to Gemini
- **Pet Data Anonymization**: Use internal IDs, not names, in logs
- **Retention Policy**: AI conversation logs deleted after 90 days
- **User Control**: Users can opt out of AI features entirely

### RLS Policies
```sql
-- Only pet owner can access AI features for their pets
CREATE POLICY "ai_feature_access" ON ai_usage_log
  FOR ALL USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM pets
      WHERE pets.id = (ai_usage_log.metadata->>'petId')::UUID
      AND pets.owner_id = auth.uid()
    )
  );
```

### Compliance
- **GDPR**: Right to deletion includes all AI-generated content
- **Data Localization**: Edge Functions deployed in user's region when possible
- **Audit Trail**: All AI interactions logged for abuse detection

## Future Enhancements

- **Multi-modal Input**: Voice queries, video analysis
- **Veterinarian AI Tools**: Draft medical notes, suggest diagnoses
- **Predictive Health Alerts**: Proactive notifications based on trends
- **Fine-tuned Models**: Custom Gemini fine-tuning on PetConnect data
- **Federated Learning**: Privacy-preserving model improvements
