# User Registration Webhook - TODO

**Status:** ⏸️ Deferred to Milestone 3
**Priority:** Medium

---

## Implementation Checklist

### Prerequisites
- [ ] Email service provider selected (SendGrid, Mailgun, or Supabase Email)
- [ ] Email templates designed (welcome email, email verification)
- [ ] Email service API key obtained from client

### Function Implementation
- [ ] Create `index.ts` with Deno runtime
- [ ] Set up function handler for POST requests
- [ ] Validate incoming webhook payload
- [ ] Extract user data from Supabase Auth event

### Business Logic
- [ ] Send welcome email to new user
- [ ] Initialize user gamification data:
  - [ ] Set XP = 0
  - [ ] Set level = 1
  - [ ] Set current_streak = 0
  - [ ] Set longest_streak = 0
- [ ] Award "First Steps" badge
- [ ] Create default user settings/preferences

### Error Handling
- [ ] Handle email sending failures gracefully
- [ ] Log all errors to Supabase logs
- [ ] Implement retry logic for failed operations
- [ ] Return appropriate HTTP status codes

### Testing
- [ ] Write unit tests
- [ ] Test locally with `supabase functions serve`
- [ ] Test with production-like data
- [ ] Verify email delivery in test environment

### Deployment
- [ ] Set environment variables in Supabase dashboard
- [ ] Deploy function: `supabase functions deploy user-registration-webhook`
- [ ] Configure webhook trigger in Supabase Auth settings
- [ ] Test in production with test account

---

## Code Template

```typescript
// index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    // TODO: Implement user registration logic
    const { user } = await req.json()

    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // TODO: Send welcome email

    // TODO: Initialize gamification data

    // TODO: Award first badge

    return new Response(JSON.stringify({ success: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
```

---

**Implementation Target:** Milestone 3
**Estimated Effort:** 4 hours
