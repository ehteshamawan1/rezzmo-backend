# Rezzmo Backend API Documentation

## Overview
This document provides comprehensive documentation for the Rezzmo Backend API.

**Base URL:** `https://your-project.supabase.co`
**API Version:** v1
**Authentication:** Bearer Token (JWT)

---

## Authentication

All API requests require authentication using a JWT token obtained from Supabase Auth.

### Headers
```
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json
```

---

## Endpoints

### Users & Profiles
- `GET /api/v1/users/:id` - Get user profile
- `PUT /api/v1/users/:id` - Update user profile
- `DELETE /api/v1/users/:id` - Delete user account

### Workouts
- `GET /api/v1/workouts` - List all workouts
- `GET /api/v1/workouts/:id` - Get workout details
- `POST /api/v1/workouts` - Create new workout
- `PUT /api/v1/workouts/:id` - Update workout
- `DELETE /api/v1/workouts/:id` - Delete workout

### Challenges
- `GET /api/v1/challenges` - List challenges
- `POST /api/v1/challenges` - Create challenge
- `GET /api/v1/challenges/:id` - Get challenge details
- `POST /api/v1/challenges/:id/join` - Join challenge

### Social Features
- `POST /api/v1/circles` - Create social circle
- `GET /api/v1/circles/:id` - Get circle details
- `POST /api/v1/circles/:id/members` - Add member to circle

---

## Supabase Edge Functions

### User Registration Webhook
**Function:** `user-registration`
**Trigger:** On user signup
**Purpose:** Create user profile and initialize data

### Streak Calculation
**Function:** `calculate-streaks`
**Schedule:** Daily at midnight
**Purpose:** Update user workout streaks

### Payment Webhook
**Function:** `payment-webhook`
**Trigger:** Stripe/PayPal webhook
**Purpose:** Process payments and update subscriptions

---

## Database Schema

See `supabase/migrations/` for complete database schema.

---

## Error Handling

All errors follow this format:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  }
}
```

---

## Rate Limiting

- General API: 100 requests per minute
- Nominatim API: 1 request per second
- Auth endpoints: 5 requests per minute

---

*Last updated: October 13, 2025*
