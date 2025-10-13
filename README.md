# Rezzmo Backend

## AI-Powered Fitness Platform Backend

Backend services for the Rezzmo fitness and social training platform, built with Supabase.

## Features

- **Authentication**: Email/password, Google, Facebook, Apple Sign-In via Supabase Auth
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Real-time**: Live updates for social features and challenges
- **Storage**: Secure file storage for user photos, videos, and documents
- **Edge Functions**: Serverless functions for AI integration, notifications, and business logic
- **APIs**: RESTful and GraphQL endpoints via PostgREST and GraphQL

## Tech Stack

- **Backend-as-a-Service**: Supabase
- **Database**: PostgreSQL 15+
- **Real-time Engine**: Supabase Realtime
- **Storage**: Supabase Storage (S3-compatible)
- **Edge Functions**: Deno runtime
- **AI Integration**: OpenAI API / Claude API (via Edge Functions)

## Setup

### Prerequisites

- Supabase account (https://supabase.com)
- Supabase CLI
- Node.js 18+ (for local development)
- Deno (for Edge Functions)

### Installation

1. Install Supabase CLI:
\`\`\`bash
npm install -g supabase
\`\`\`

2. Initialize local Supabase:
\`\`\`bash
supabase init
supabase start
\`\`\`

3. Link to remote project:
\`\`\`bash
supabase link --project-ref your-project-ref
\`\`\`

## Database Schema

### Core Tables

- **users**: User profiles and preferences
- **workouts**: Workout plans and templates
- **exercises**: Exercise library
- **meals**: Meal plans and recipes
- **nutrition**: Nutritional data
- **challenges**: Community challenges
- **circles**: Social training groups
- **achievements**: Gamification and badges
- **trainers**: Trainer profiles and availability
- **bookings**: Trainer session bookings

### Security

All tables implement Row Level Security (RLS) policies to ensure data privacy and security.

## Edge Functions

- **ai-workout-generator**: Generate personalized workout plans
- **ai-meal-planner**: Create custom meal plans
- **notification-handler**: Send push notifications
- **payment-webhook**: Handle Stripe payment events
- **trainer-matching**: Match users with suitable trainers

## API Documentation

API documentation is auto-generated via Supabase and available at:
- REST API: `https://your-project.supabase.co/rest/v1/`
- GraphQL: `https://your-project.supabase.co/graphql/v1`

## Deployment

Supabase handles deployment automatically. For Edge Functions:

\`\`\`bash
supabase functions deploy function-name
\`\`\`

## Environment Variables

Required environment variables:
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Public anon key
- `SUPABASE_SERVICE_KEY`: Service role key (server-side only)
- `OPENAI_API_KEY`: For AI features
- `STRIPE_SECRET_KEY`: For payments

## Contributing

This is a private project. Contact the development team for access.

## License

Proprietary - All rights reserved by Cyberix Digital

---

**Developed by Cyberix Digital**
