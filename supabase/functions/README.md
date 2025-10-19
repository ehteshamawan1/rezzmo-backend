# Rezzmo - Supabase Edge Functions

**Status:** Placeholder - Functions will be implemented in future milestones

---

## Overview

This directory contains Supabase Edge Functions for server-side logic that cannot be handled by database triggers or RLS policies alone.

Edge Functions are Deno-based serverless functions that run on Supabase infrastructure.

---

## Planned Edge Functions (Deferred to Future Milestones)

### 1. User Registration Webhook
**Status:** ⏸️ Deferred to Milestone 3
**File:** `user-registration-webhook/index.ts`

**Purpose:**
- Process new user registration events
- Send welcome email via email service
- Initialize user gamification data (XP, level, streak)
- Create default user settings

**Triggers:**
- Supabase Auth user signup event
- Called via webhook or database trigger

**Implementation Notes:**
- Use Supabase Email service or external provider (SendGrid, Mailgun)
- Set initial XP = 0, level = 1, streak = 0
- Award "First Steps" badge on registration

---

### 2. Streak Calculation Function
**Status:** ⏸️ Deferred to Milestone 3 (Gamification System)
**File:** `streak-calculation/index.ts`

**Purpose:**
- Calculate daily workout streaks for all users
- Check if user completed workout today
- Update streak counters (current streak, longest streak)
- Award streak milestone badges (7-day, 30-day, etc.)
- Send streak reminder notifications

**Triggers:**
- Scheduled cron job (runs daily at midnight in user timezone)
- Can also be triggered manually for testing

**Implementation Notes:**
- Query all users with active streaks
- Check if workout completed in last 24 hours (timezone-aware)
- If yes: increment streak, check for milestone badges
- If no: reset current streak to 0
- Send push notification 2 hours before midnight if no workout today
- Store streak history for analytics

**Dependencies:**
- Push notification service (OneSignal or FCM)
- User timezone data from profiles table

---

### 3. Payment Webhook Handler
**Status:** ⏸️ Deferred to Milestone 6 (Trainer Marketplace)
**File:** `payment-webhook/index.ts`

**Purpose:**
- Handle Stripe webhook events for payments
- Process trainer booking payments
- Calculate and distribute platform commission
- Update booking status
- Send payment confirmation emails

**Triggers:**
- Stripe webhook events:
  - `payment_intent.succeeded`
  - `payment_intent.failed`
  - `charge.refunded`

**Implementation Notes:**
- Verify Stripe webhook signature for security
- Update `bookings` table with payment status
- Calculate 15% platform commission
- Update trainer earnings in `trainer_profiles`
- Send confirmation email to user and trainer
- Handle refunds and disputes

**Security:**
- Validate Stripe webhook signature
- Use Stripe API key from environment variables
- Log all payment events for audit trail

---

## Future Edge Functions (Milestones 4+)

### 4. Challenge Notifications (Milestone 4)
- Send notifications when challenges start/end
- Notify participants of challenge updates
- Process challenge completion rewards

### 5. AI Workout Generator (Milestone 3)
- Generate personalized workout plans using AI
- Integration with AI model API
- Store generated workouts in database

### 6. Leaderboard Calculator (Milestone 4)
- Calculate global and circle leaderboards
- Update rankings based on XP, workouts, streaks
- Cache results for performance

### 7. Subscription Manager (Milestone 8)
- Handle Stripe subscription webhooks
- Update user subscription status
- Manage trial periods and cancellations

---

## Development Setup

### Prerequisites
- Supabase CLI installed
- Deno runtime (installed automatically by Supabase CLI)

### Local Development
```bash
# Navigate to backend directory
cd rezzmo-backend

# Start local Supabase instance
supabase start

# Serve Edge Function locally for testing
supabase functions serve <function-name>

# Example: Test streak calculation locally
supabase functions serve streak-calculation
```

### Deployment
```bash
# Deploy single function to remote Supabase
supabase functions deploy <function-name>

# Deploy all functions
supabase functions deploy
```

---

## Environment Variables

Edge Functions require these environment variables (set in Supabase dashboard):

```env
# Email Service
SENDGRID_API_KEY=your-sendgrid-api-key

# Push Notifications
ONESIGNAL_APP_ID=your-onesignal-app-id
ONESIGNAL_API_KEY=your-onesignal-api-key

# Payment Processing
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret

# AI Services (Milestone 3)
OPENAI_API_KEY=your-openai-api-key
```

---

## Testing

### Unit Tests
```bash
# Run tests for a specific function
deno test supabase/functions/<function-name>/index.test.ts
```

### Integration Tests
```bash
# Use curl to test locally running function
curl -i --location --request POST 'http://localhost:54321/functions/v1/<function-name>' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"test": "data"}'
```

---

## Security Best Practices

1. **Authentication:**
   - Validate JWT tokens from Supabase Auth
   - Check user permissions before processing requests

2. **Input Validation:**
   - Validate all input data
   - Sanitize user-provided content

3. **Secrets Management:**
   - Never hardcode API keys
   - Use Supabase secrets manager for sensitive data

4. **Rate Limiting:**
   - Implement rate limiting for public endpoints
   - Prevent abuse and DoS attacks

5. **Error Handling:**
   - Log errors without exposing sensitive information
   - Return generic error messages to clients

---

## Documentation

For more information on Supabase Edge Functions:
- [Official Documentation](https://supabase.com/docs/guides/functions)
- [Deno Documentation](https://deno.land/manual)

---

**Last Updated:** October 19, 2025
**Maintainer:** Cyberix Digital
**Project:** Rezzmo AI Fitness Platform
