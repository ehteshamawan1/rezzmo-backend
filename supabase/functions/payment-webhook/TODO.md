# Payment Webhook Handler - TODO

**Status:** ⏸️ Deferred to Milestone 6 (Trainer Marketplace & Payments)
**Priority:** High (Security Critical)

---

## Implementation Checklist

### Prerequisites
- [ ] Stripe account set up by client
- [ ] Stripe API keys obtained (test + production)
- [ ] Stripe webhook secret obtained
- [ ] Platform commission percentage decided (default: 15%)
- [ ] Email service configured for payment confirmations

### Function Implementation
- [ ] Create `index.ts` with Deno runtime
- [ ] Import Stripe SDK for Deno
- [ ] Set up function handler for POST requests
- [ ] Implement webhook signature verification (CRITICAL)

### Webhook Events to Handle
- [ ] `payment_intent.succeeded`:
  - [ ] Update booking status to 'confirmed'
  - [ ] Calculate platform commission (15%)
  - [ ] Update trainer earnings
  - [ ] Send confirmation emails
- [ ] `payment_intent.failed`:
  - [ ] Update booking status to 'failed'
  - [ ] Send failure notification to user
  - [ ] Log failure reason for support
- [ ] `charge.refunded`:
  - [ ] Update booking status to 'refunded'
  - [ ] Adjust trainer earnings
  - [ ] Send refund confirmation emails

### Business Logic
- [ ] Calculate amounts:
  ```
  Total Amount = Booking Price
  Platform Commission = Total * 0.15
  Trainer Earnings = Total - Commission
  ```
- [ ] Update database tables:
  - [ ] `bookings` - payment status, stripe_payment_id
  - [ ] `payments` - transaction record
  - [ ] `trainer_profiles` - total_earnings
- [ ] Create transaction record in payments table
- [ ] Handle idempotency (prevent duplicate processing)

### Security (CRITICAL)
- [ ] **Verify Stripe webhook signature** - MUST BE FIRST STEP
  ```typescript
  const signature = req.headers.get('stripe-signature')
  const event = stripe.webhooks.constructEvent(
    payload,
    signature,
    webhookSecret
  )
  ```
- [ ] Validate event data before processing
- [ ] Use service role key for database operations
- [ ] Never expose sensitive data in responses
- [ ] Log all payment events for audit trail

### Email Notifications
- [ ] Payment success email to user:
  - [ ] Booking confirmation
  - [ ] Receipt with breakdown
  - [ ] Trainer contact info
- [ ] Payment success email to trainer:
  - [ ] New booking notification
  - [ ] Earnings breakdown
  - [ ] Client contact info
- [ ] Refund confirmation emails (if applicable)

### Error Handling
- [ ] Invalid signature → 400 Bad Request
- [ ] Unknown event type → Log and return 200 (Stripe best practice)
- [ ] Database errors → Retry logic with exponential backoff
- [ ] Email failures → Log but don't fail webhook
- [ ] Return 200 OK even if processing fails (prevent Stripe retries)

### Testing
- [ ] Use Stripe CLI for local webhook testing:
  ```bash
  stripe listen --forward-to localhost:54321/functions/v1/payment-webhook
  stripe trigger payment_intent.succeeded
  ```
- [ ] Test all webhook event types
- [ ] Test signature verification
- [ ] Test with invalid signatures (should reject)
- [ ] Verify idempotency (same event sent twice)
- [ ] Test database transaction rollback on errors

### Deployment
- [ ] Set environment variables in Supabase dashboard:
  ```
  STRIPE_SECRET_KEY=sk_live_...
  STRIPE_WEBHOOK_SECRET=whsec_...
  ```
- [ ] Deploy function: `supabase functions deploy payment-webhook`
- [ ] Get function URL from Supabase dashboard
- [ ] Configure webhook endpoint in Stripe dashboard:
  - URL: `https://your-project.supabase.co/functions/v1/payment-webhook`
  - Events: `payment_intent.*`, `charge.refunded`
- [ ] Test with Stripe test mode first
- [ ] Monitor webhook delivery in Stripe dashboard

---

## Code Template

```typescript
// index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'https://esm.sh/stripe@12.0.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') ?? '', {
  apiVersion: '2023-10-16',
})

serve(async (req) => {
  try {
    // CRITICAL: Verify webhook signature
    const signature = req.headers.get('stripe-signature')
    const body = await req.text()

    const event = stripe.webhooks.constructEvent(
      body,
      signature!,
      Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? ''
    )

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded':
        // TODO: Process successful payment
        break
      case 'payment_intent.failed':
        // TODO: Process failed payment
        break
      case 'charge.refunded':
        // TODO: Process refund
        break
      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    // IMPORTANT: Always return 200 to Stripe
    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Webhook error:', error.message)

    // Return 400 for signature verification failures
    if (error.message.includes('signature')) {
      return new Response(JSON.stringify({ error: 'Invalid signature' }), {
        status: 400,
      })
    }

    // Return 200 for other errors (Stripe will retry)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 200, // Prevent Stripe retries for processing errors
    })
  }
})
```

---

## Security Checklist

- [ ] Webhook signature verification implemented
- [ ] Service role key used for database access
- [ ] No sensitive data in error responses
- [ ] All events logged for audit trail
- [ ] HTTPS enforced (Supabase handles this)
- [ ] Rate limiting configured (Supabase handles this)
- [ ] Idempotency keys used for critical operations

---

## Platform Commission Calculation

```typescript
const PLATFORM_COMMISSION_RATE = 0.15; // 15%

function calculateEarnings(bookingAmount: number) {
  const commission = bookingAmount * PLATFORM_COMMISSION_RATE;
  const trainerEarnings = bookingAmount - commission;

  return {
    totalAmount: bookingAmount,
    platformCommission: commission,
    trainerEarnings: trainerEarnings,
  };
}
```

---

**Implementation Target:** Milestone 6
**Estimated Effort:** 6 hours
**Security Review Required:** YES
**Dependencies:** Stripe account setup, email service integration
