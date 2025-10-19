# Streak Calculation Function - TODO

**Status:** ⏸️ Deferred to Milestone 3 (Gamification System)
**Priority:** High

---

## Implementation Checklist

### Prerequisites
- [ ] Push notification service configured (OneSignal or FCM)
- [ ] Push notification API keys obtained
- [ ] User timezone data available in profiles table
- [ ] Streak milestone badges created in database

### Function Implementation
- [ ] Create `index.ts` with Deno runtime
- [ ] Set up cron trigger for daily execution
- [ ] Query all users from profiles table
- [ ] Implement timezone-aware date calculations

### Business Logic
- [ ] For each user:
  - [ ] Get user's local timezone
  - [ ] Check if workout completed in last 24 hours
  - [ ] If yes: increment current_streak, update last_workout_date
  - [ ] If no: reset current_streak to 0
  - [ ] Update longest_streak if current > longest
- [ ] Check for streak milestone achievements:
  - [ ] 7-day streak → "7-Day Warrior" badge
  - [ ] 14-day streak → "2-Week Champion" badge
  - [ ] 30-day streak → "Monthly Master" badge
  - [ ] 60-day streak → "Streak Legend" badge
  - [ ] 100-day streak → "Century Streaker" badge
- [ ] Award badges when milestones are reached

### Notifications
- [ ] Send streak reminder notification:
  - [ ] Trigger 2 hours before midnight (user timezone)
  - [ ] Only send if no workout completed today
  - [ ] Message: "Don't break your {X}-day streak! Complete a quick workout."
- [ ] Send streak milestone notifications:
  - [ ] Congratulate user on reaching milestone
  - [ ] Show badge earned

### Performance Optimization
- [ ] Batch database updates for better performance
- [ ] Use database indexes on last_workout_date
- [ ] Implement cursor-based pagination for large user bases
- [ ] Cache timezone data to reduce lookups

### Error Handling
- [ ] Handle timezone conversion errors
- [ ] Skip users with invalid data
- [ ] Log all errors without failing entire batch
- [ ] Implement retry logic for failed notifications

### Testing
- [ ] Write unit tests for streak calculation logic
- [ ] Test with users in different timezones
- [ ] Test edge cases (midnight boundary, leap seconds, DST)
- [ ] Test notification delivery
- [ ] Simulate cron execution locally

### Deployment
- [ ] Set environment variables in Supabase dashboard
- [ ] Deploy function: `supabase functions deploy streak-calculation`
- [ ] Configure cron trigger:
  ```sql
  SELECT cron.schedule(
    'calculate-daily-streaks',
    '0 1 * * *', -- Run at 1 AM UTC daily
    $$SELECT net.http_post(
      url:='https://your-project.supabase.co/functions/v1/streak-calculation',
      headers:='{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
    )$$
  );
  ```
- [ ] Monitor function execution logs
- [ ] Verify streak calculations in production

---

## Code Template

```typescript
// index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // TODO: Fetch all users with their timezone data
    const { data: users } = await supabase
      .from('profiles')
      .select('id, timezone, current_streak, longest_streak, last_workout_date')

    let streaksUpdated = 0
    let badgesAwarded = 0

    // TODO: Process each user
    for (const user of users || []) {
      // TODO: Check if workout completed today (timezone-aware)
      // TODO: Update streak counters
      // TODO: Award milestone badges
      // TODO: Send notifications
    }

    return new Response(
      JSON.stringify({
        success: true,
        streaksUpdated,
        badgesAwarded
      }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

---

## Cron Schedule Reference

```
# Run daily at 1 AM UTC (covers all timezones)
0 1 * * *

# Run every 12 hours (backup schedule)
0 */12 * * *
```

---

**Implementation Target:** Milestone 3
**Estimated Effort:** 8 hours
**Dependencies:** Push notification service integration
