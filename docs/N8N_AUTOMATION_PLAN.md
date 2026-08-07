# n8n Automation Plan

## Overview

PetConnect uses n8n as its workflow automation engine for backend orchestration. n8n handles asynchronous, event-driven, and scheduled tasks that don't belong in request-time logic, keeping the app responsive and the architecture cleanly separated.

## Separation of Concerns

Understanding what belongs where is critical to a maintainable system:

| Concern | Handled By | Rationale |
|---------|-----------|-----------|
| Request-time logic | Supabase Edge Functions | Low latency, synchronous responses (AI chat, collar ingest) |
| Orchestration & automation | n8n workflows | Multi-step, retryable, scheduled, fan-out tasks |
| Data persistence | Postgres | Source of truth |
| Real-time delivery | Supabase Realtime | Live updates to app |
| Push delivery | FCM (via n8n) | Cross-platform notifications |

**Rule of thumb**: If it must happen instantly in response to a user action, use an Edge Function. If it's scheduled, involves multiple systems, needs retries, or fans out to many recipients, use n8n.

## What n8n Orchestrates

### 1. Notification Fan-Out
Distribute a single event to many recipients across channels (push, email, in-app):
- Rescue mission alerts to all nearby volunteers
- Community post replies to thread participants
- Emergency broadcasts to a geographic radius

### 2. Scheduled Reminders
Time-based triggers for recurring care tasks:
- **Vaccination reminders**: X days before due date
- **Appointment reminders**: 24h and 1h before vet visits
- **Medication reminders**: Daily/weekly dosing schedules
- **Wellness checkups**: Periodic reminders based on pet age

### 3. Rescue Mission Dispatch
- New rescue mission created by Volunteer & Rescue portal
- n8n queries volunteers within geographic radius
- Fan-out dispatch with mission details and accept/decline actions

### 4. Lost-Pet Alerts
- Lost Mode activation triggers community alert workflow
- Geo-radius query for nearby users
- Escalating alerts (widen radius over time if not found)

### 5. Community Digests
- Weekly/daily digest of community activity
- Personalized based on user's pets and interests
- Batch-generated and delivered via email/push

### 6. Data Sync & ETL
- Aggregate collar telemetry into daily activity summaries
- Sync external vet clinic data (if integrated)
- Generate analytics rollups for Administrator portal

### 7. AI Report Generation Triggers
- Schedule monthly health report generation
- Trigger Edge Function (`ai-health-report`) for each active pet
- Deliver completed reports via notification

## Supabase Integration

n8n integrates with Supabase through multiple mechanisms:

### Integration Diagram
```
┌─────────────────────────────────────────────────┐
│                   Supabase                        │
│  ┌──────────┐   ┌──────────┐   ┌──────────────┐ │
│  │ Postgres │   │   Edge   │   │   Realtime   │ │
│  │ Triggers │   │Functions │   │              │ │
│  └────┬─────┘   └────┬─────┘   └──────────────┘ │
└───────┼──────────────┼───────────────────────────┘
        │              │
        │ (webhook)    │ (invoke)
        ↓              ↕
┌───────────────────────────────────────────────────┐
│                       n8n                          │
│  ┌─────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ Webhook │  │  Cron    │  │  HTTP Request    │  │
│  │ Trigger │  │ Schedule │  │  (Supabase REST) │  │
│  └─────────┘  └──────────┘  └──────────────────┘  │
│         │           │                │             │
│         └───────────┴────────────────┘             │
│                     ↓                              │
│         ┌──────────────────────┐                   │
│         │   Workflow Logic      │                   │
│         │  (filter, transform,  │                   │
│         │   branch, loop)       │                   │
│         └──────────┬───────────┘                   │
│                    ↓                               │
│         ┌──────────────────────┐                   │
│         │   FCM / Email / SMS   │                   │
│         └──────────────────────┘                   │
└────────────────────────────────────────────────────┘
```

### Postgres Triggers → n8n Webhooks
Database events trigger n8n workflows via webhooks:

```sql
-- Example: Notify n8n when lost mode is activated
CREATE OR REPLACE FUNCTION notify_lost_pet()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://n8n.petconnect.app/webhook/lost-pet-alert',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'X-Webhook-Secret', current_setting('app.n8n_webhook_secret')
    ),
    body := jsonb_build_object(
      'petId', NEW.pet_id,
      'location', NEW.last_known_location,
      'activatedAt', NEW.activated_at
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_lost_pet_broadcast
  AFTER INSERT ON lost_pet_broadcasts
  FOR EACH ROW EXECUTE FUNCTION notify_lost_pet();
```

### Supabase REST API
n8n reads/writes data via Supabase's auto-generated REST API:
```
GET  https://<project>.supabase.co/rest/v1/pets?vaccination_due=lt.<date>
POST https://<project>.supabase.co/rest/v1/notifications
```
n8n uses the service role key (stored in n8n credentials) for backend access.

### Edge Function Invocation
n8n calls Edge Functions for request-time logic (e.g., AI report generation):
```
POST https://<project>.supabase.co/functions/v1/ai-health-report
Body: { "petId": "...", "period": {...} }
```

## FCM Integration

Push notifications delivered via Firebase Cloud Messaging:

### FCM Node Configuration
```
HTTP Request Node → FCM v1 API
URL: https://fcm.googleapis.com/v1/projects/<project>/messages:send
Auth: OAuth2 (Service Account)
Body:
{
  "message": {
    "token": "{{ $json.fcmToken }}",
    "notification": {
      "title": "{{ $json.title }}",
      "body": "{{ $json.body }}"
    },
    "data": {
      "type": "{{ $json.type }}",
      "deepLink": "{{ $json.deepLink }}"
    }
  }
}
```

### Token Management
- FCM tokens stored in `user_devices` table
- n8n queries active tokens for target users
- Handles token refresh and cleanup of stale tokens

## Example Workflows

### Workflow 1: Vaccination Reminder

**Trigger**: Cron schedule (daily at 8:00 AM)

**Steps**:
1. **Cron Node**: Fires daily at 08:00
2. **Supabase Query Node**: Fetch pets with vaccinations due in 7 days
   ```
   GET /rest/v1/vaccinations?due_date=eq.<today+7>&status=eq.pending
   ```
3. **Loop Node**: Iterate over each pet
4. **Supabase Query Node**: Get owner's FCM tokens
   ```
   GET /rest/v1/user_devices?user_id=eq.<owner_id>
   ```
5. **Function Node**: Build notification payload
   ```javascript
   return {
     title: `Vaccination Reminder`,
     body: `${pet.name}'s ${vaccine.name} is due in 7 days`,
     type: 'vaccination_reminder',
     deepLink: `petconnect://pets/${pet.id}/health`
   };
   ```
6. **FCM Node**: Send push notification
7. **Supabase Insert Node**: Log notification to `notifications` table
8. **Error Handler**: Retry failed sends up to 3 times

### Workflow 2: Lost-Mode Alert

**Trigger**: Webhook (from Postgres trigger on `lost_pet_broadcasts` insert)

**Steps**:
1. **Webhook Node**: Receives `{ petId, location, activatedAt }`
2. **Validation Node**: Verify webhook secret
3. **Supabase Query Node**: Get pet details and owner info
4. **PostGIS Query Node**: Find users within 10km radius
   ```sql
   SELECT DISTINCT u.id, u.fcm_token
   FROM users u
   WHERE ST_DWithin(
     u.last_location::geography,
     ST_MakePoint($lng, $lat)::geography,
     10000  -- 10km in meters
   )
   AND u.id != $owner_id
   AND u.lost_pet_alerts_enabled = true;
   ```
5. **Split In Batches Node**: Process users in batches of 100
6. **FCM Node**: Send alert with pet photo and last-known location
   ```
   "🔍 Lost pet alert: Help find Max (Golden Retriever) near Central Park.
    Tap to view details and report sightings."
   ```
7. **Wait Node**: Wait 2 hours
8. **Supabase Query Node**: Check if pet found
9. **IF Node**: If still lost, widen radius to 25km and repeat
10. **Insert Node**: Log all dispatched alerts for analytics

### Workflow 3: Rescue Mission Dispatch

**Trigger**: Webhook (from Volunteer & Rescue portal creating a mission)

**Steps**:
1. **Webhook Node**: Receives `{ missionId, location, urgency, animalType }`
2. **Supabase Query Node**: Get full mission details
3. **PostGIS Query Node**: Find volunteers within radius (based on urgency)
   ```sql
   SELECT v.id, v.fcm_token, v.name,
     ST_Distance(v.location::geography, mission_point::geography) AS distance
   FROM volunteers v
   WHERE v.available = true
   AND v.animal_types @> ARRAY[$animalType]
   AND ST_DWithin(v.location::geography, mission_point::geography, $radius)
   ORDER BY distance ASC
   LIMIT 20;
   ```
4. **Function Node**: Rank volunteers by proximity + rating + availability
5. **Loop Node**: Dispatch to top volunteers
6. **FCM Node**: Send mission alert with accept/decline actions
   ```
   "🚨 Rescue mission: Injured cat reported 2.3km away.
    Can you help? [Accept] [Decline]"
   ```
7. **Wait Node**: Wait for responses (30 min timeout)
8. **IF Node**: If no acceptance, expand to next tier of volunteers
9. **Supabase Update Node**: Update mission status and assigned volunteer
10. **Notification Node**: Confirm assignment to reporter and volunteer

## Hosting & Security

### Hosting Options
- **Self-Hosted**: Docker container on dedicated VPS (recommended for data control)
- **n8n Cloud**: Managed hosting (faster setup, less operational overhead)
- **Kubernetes**: For high-availability, auto-scaling deployments

### Recommended Setup
```yaml
# docker-compose.yml (self-hosted)
services:
  n8n:
    image: n8nio/n8n:latest
    environment:
      - N8N_HOST=n8n.petconnect.app
      - N8N_PROTOCOL=https
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=${DB_HOST}
      - WEBHOOK_URL=https://n8n.petconnect.app/
      - N8N_BASIC_AUTH_ACTIVE=true
    volumes:
      - n8n_data:/home/node/.n8n
    ports:
      - "5678:5678"
```

### Security Considerations
- **Webhook Authentication**: All incoming webhooks validated with shared secret (`X-Webhook-Secret` header)
- **Credential Storage**: Supabase service key, FCM key stored in n8n's encrypted credential vault, never in workflow JSON
- **Network Isolation**: n8n deployed in private network; only webhook endpoints exposed via reverse proxy
- **HTTPS Only**: All traffic over TLS; enforce with reverse proxy (nginx/Caddy)
- **Rate Limiting**: Protect webhook endpoints from abuse at proxy layer
- **Least Privilege**: Use scoped Supabase keys where possible; audit service role usage
- **Audit Logging**: n8n execution logs retained for debugging and compliance
- **Secret Rotation**: Rotate webhook secrets and API keys quarterly

### Reliability
- **Retry Logic**: Configure automatic retries on failure-prone nodes (FCM, HTTP)
- **Error Workflows**: Dedicated error-handling workflow logs failures and alerts admins
- **Idempotency**: Use unique keys to prevent duplicate notifications
- **Dead Letter Queue**: Failed executions logged for manual review
- **Monitoring**: Track workflow execution metrics; alert on elevated failure rates

## Workflow Catalog Summary

| Workflow | Trigger | Frequency | Priority |
|----------|---------|-----------|----------|
| Vaccination Reminder | Cron | Daily 08:00 | Medium |
| Appointment Reminder | Cron | Every 15 min | High |
| Medication Reminder | Cron | Configurable | High |
| Lost-Pet Alert | Webhook | Event-driven | Critical |
| Rescue Dispatch | Webhook | Event-driven | Critical |
| Geofence Breach | Webhook | Event-driven | High |
| Low Battery Alert | Webhook | Event-driven | Low |
| Community Digest | Cron | Weekly | Low |
| Health Report Gen | Cron | Monthly | Medium |
| Telemetry Rollup (ETL) | Cron | Daily 02:00 | Low |

## Future Enhancements

- **Smart Scheduling**: ML-optimized notification timing per user
- **Multi-Language**: Localized notification templates
- **A/B Testing**: Experiment with notification copy and timing
- **Escalation Chains**: Auto-escalate unacknowledged critical alerts
- **Integration Hub**: Connect external vet systems, pet insurance, pharmacies
