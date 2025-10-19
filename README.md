# Rezzmo Backend - Supabase Configuration

**Version:** 1.0.0
**Last Updated:** October 19, 2025
**Milestone:** 2 - Backend Architecture & Authentication

---

## Overview

This directory contains all backend configurations, database migrations, seed data, and Edge Functions for the Rezzmo AI fitness platform. The backend is built on **Supabase**, providing:

- PostgreSQL database with Row Level Security (RLS)
- Authentication (Email/Password + Google OAuth)
- File storage (avatars, videos, voice messages, challenge images)
- Real-time subscriptions
- Edge Functions for custom backend logic

---

## Directory Structure

```
rezzmo-backend/
├── supabase/
│   ├── config.toml              # Supabase CLI configuration
│   ├── migrations/              # Database schema migrations
│   │   ├── 20251017000001_initial_schema.sql
│   │   ├── 20251017000002_rls_policies.sql
│   │   ├── 20251017000003_database_functions.sql
│   │   ├── 20251017000004_storage_buckets.sql
│   │   └── 20251019000001_create_test_admin.sql
│   ├── seed/                    # Seed data for development
│   │   └── seed.sql
│   ├── functions/               # Supabase Edge Functions (future)
│   └── .env.example             # Environment variables template
├── docs/                        # Documentation
│   ├── API.md                   # API documentation
│   ├── DATABASE_SCHEMA.md       # Database schema reference
│   └── SETUP.md                 # Local development setup
└── README.md                    # This file
```

---

## Quick Start

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) installed
- [Docker](https://www.docker.com/) installed (for local Supabase)
- Node.js 18+ (for Edge Functions)

### 1. Clone & Navigate

```bash
cd rezzmo-backend
```

### 2. Install Supabase CLI

```bash
npm install -g supabase
```

### 3. Start Local Supabase Instance

```bash
supabase start
```

This will spin up a local Supabase instance with PostgreSQL, Auth, Storage, and more.

### 4. Apply Migrations

```bash
supabase db reset
```

This applies all migrations in order and loads seed data.

### 5. View Local Dashboard

```bash
supabase status
```

Access the local Studio at `http://localhost:54323`

---

## Database Migrations

All database changes are managed through migration files in `supabase/migrations/`.

### Migration Files (In Order)

1. **20251017000001_initial_schema.sql** - Creates all 19+ tables
2. **20251017000002_rls_policies.sql** - Sets up Row Level Security policies
3. **20251017000003_database_functions.sql** - Database functions and triggers
4. **20251017000004_storage_buckets.sql** - Storage buckets and policies
5. **20251019000001_create_test_admin.sql** - Test admin user creation

### Running Migrations

**Local Development:**
```bash
supabase db reset  # Resets DB and applies all migrations
```

**Production (Remote):**
```bash
supabase db push  # Pushes migrations to remote Supabase project
```

### Creating New Migrations

```bash
supabase migration new <migration_name>
```

---

## Database Schema

The Rezzmo database includes 19+ tables organized into functional groups.

### Core Tables
- `profiles` - User profiles with onboarding data
- `user_progress` - Gamification data (XP, levels, streaks)
- `badges` - Achievement badges
- `user_badges` - User-earned badges

### Social Tables
- `social_circles` - Friend groups
- `circle_members` - Group memberships
- `posts` - Social feed posts
- `likes` - Post likes
- `comments` - Post comments

### Fitness Tables
- `exercises` - Exercise library
- `workouts` - Workout templates
- `workout_exercises` - Exercise-workout relationships
- `user_workouts` - Completed workouts
- `challenges` - Fitness challenges
- `challenge_participants` - Challenge enrollments

### Trainer Tables
- `trainer_profiles` - Trainer-specific data
- `trainer_bookings` - Booking sessions
- `trainer_availability` - Schedule availability

### Communication Tables
- `chat_rooms` - Chat rooms
- `chat_messages` - Messages

See `docs/DATABASE_SCHEMA.md` for detailed schema documentation.

---

## Storage Buckets

### Configured Buckets

| Bucket | Public? | Purpose | File Types | Size Limit |
|--------|---------|---------|------------|------------|
| `profile-avatars` | ✅ Yes | User profile pictures | Images | 5MB |
| `workout-videos` | ✅ Yes | Workout demonstration videos | Videos | 100MB |
| `voice-messages` | ❌ No | Voice messages in chat | Audio | 10MB |
| `challenge-images` | ✅ Yes | Challenge cover images | Images | 10MB |

### File Path Structure

All files follow the pattern: `{bucket-name}/{user_id}/{filename}`

Example: `profile-avatars/550e8400-e29b-41d4-a716-446655440000/avatar.jpg`

---

## Authentication

### Supported Providers

1. **Email/Password** - Default authentication
2. **Google OAuth** - Social login

### Admin Authentication

- **Admin accounts can ONLY be created manually** in Supabase Dashboard
- **No signup functionality** for admin role
- Admin role is checked via `profiles.role = 'admin'`
- Test admin credentials (development only):
  - Email: `admin@rezzmo.test`
  - Password: `TestAdmin123!`

### User Roles

- `user` - Regular app users (default)
- `trainer` - Fitness trainers
- `admin` - Platform administrators

---

## Row Level Security (RLS)

All tables have RLS enabled with policies ensuring:
- Users can only access their own data
- Trainers can access client data
- Admins have elevated access
- Public data is properly exposed

See `migrations/20251017000002_rls_policies.sql` for all RLS policies.

---

## Environment Variables

### Required Variables

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Google OAuth (optional)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

Copy `.env.example` to `.env` and fill in your credentials.

---

## Development Workflow

### 1. Local Development

```bash
# Start local Supabase
supabase start

# Reset database (applies migrations + seed data)
supabase db reset

# View logs
supabase logs
```

### 2. Database Changes

```bash
# Create new migration
supabase migration new add_new_feature

# Edit the migration file
# Apply locally
supabase db reset
```

### 3. Testing Changes

```bash
# Generate TypeScript types from database
supabase gen types typescript --local > types/supabase.ts
```

### 4. Deploy to Production

```bash
# Link to remote project
supabase link --project-ref your-project-ref

# Push migrations
supabase db push

# Verify deployment
supabase db diff
```

---

## Seed Data

The `seed/seed.sql` file contains:
- Sample badges (Bronze, Silver, Gold, Platinum)
- Exercise library (50+ exercises)
- Workout templates (Full Body, Upper Body, Lower Body, etc.)

Seed data is automatically loaded when running `supabase db reset`.

---

## Edge Functions (Future Milestones)

Edge Functions will be added in future milestones for:
- AI workout generation (Milestone 3)
- Payment processing webhooks (Milestone 6)
- Email notifications (Milestone 4)
- Complex business logic

---

## Useful Commands

```bash
# View Supabase status
supabase status

# Stop local Supabase
supabase stop

# Generate migration from database diff
supabase db diff -f migration_name

# View database schema
supabase db dump --data-only > dump.sql

# Backup database
supabase db dump > backup.sql
```

---

## Documentation

- **Supabase Dashboard Setup:** `../../AiNutritionFitnessApp-Doc/info/supabase-setup-guide.md`
- **Credentials:** `../../AiNutritionFitnessApp-Doc/info/credentials.md`

---

## Security Notes

1. **Never commit** `.env` files or credentials to Git
2. **Use RLS policies** for all tables - never disable RLS in production
3. **Rotate keys** periodically (every 90 days recommended)
4. **Service role key** should NEVER be exposed in client-side code
5. **Enable 2FA** on Supabase account for production projects

---

## Troubleshooting

### Migration Failed

```bash
# View migration status
supabase migration list

# Repair migration (if needed)
supabase migration repair <version> --status applied
```

### Connection Issues

```bash
# Check Supabase is running
supabase status

# Restart Supabase
supabase stop
supabase start
```

### Reset Everything

```bash
# Nuclear option - wipes all data
supabase stop
supabase start
supabase db reset
```

---

## Contributing

When adding new features:
1. Create a new migration file
2. Test locally with `supabase db reset`
3. Update documentation
4. Commit migration files to Git
5. Create PR for review

---

## Support

- **Supabase Documentation:** https://supabase.com/docs
- **Community:** https://discord.supabase.com
- **Issues:** Report in project repository

---

**Maintained by:** Cyberix Digital
**Project:** Rezzmo AI Fitness Platform
**License:** Proprietary
