-- =====================================================
-- Rezzmo Database Schema - Initial Migration
-- Created: October 17, 2025
-- Description: Complete database schema for Rezzmo fitness app
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For location-based features

-- =====================================================
-- USERS & PROFILES
-- =====================================================

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT DEFAULT '',
    bio TEXT DEFAULT '',

    -- User Classification
    user_type TEXT NOT NULL CHECK (user_type IN ('Regular User', 'Trainer')),
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'trainer', 'admin')),

    -- Auth Provider
    auth_provider TEXT NOT NULL CHECK (auth_provider IN ('email', 'google')),

    -- Onboarding Data
    onboarding_completed BOOLEAN DEFAULT FALSE,
    goal TEXT CHECK (goal IN ('Lose Weight', 'Build Muscle', 'Stay Active', 'Improve Endurance', 'General Fitness')),
    fitness_level TEXT CHECK (fitness_level IN ('Beginner', 'Intermediate', 'Advanced')),
    gender TEXT CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    height_cm INTEGER CHECK (height_cm > 0 AND height_cm < 300),
    current_weight_kg DECIMAL(5,2) CHECK (current_weight_kg > 0 AND current_weight_kg < 500),
    target_weight_kg DECIMAL(5,2) CHECK (target_weight_kg > 0 AND target_weight_kg < 500),
    diet_preference TEXT CHECK (diet_preference IN ('No Preference', 'Vegetarian', 'Vegan', 'Keto', 'Paleo', 'Mediterranean')),
    exercise_preferences TEXT[], -- Array of preferred exercise types

    -- Location (for challenges and trainer discovery)
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    location_name TEXT,

    -- Trainer-specific fields
    trainer_bio TEXT,
    trainer_specializations TEXT[],
    trainer_certifications TEXT[],
    trainer_hourly_rate DECIMAL(10,2),
    trainer_rating DECIMAL(3,2) DEFAULT 0.0 CHECK (trainer_rating >= 0 AND trainer_rating <= 5),
    trainer_total_reviews INTEGER DEFAULT 0,
    trainer_verified BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- USER PROGRESS & GAMIFICATION
-- =====================================================

-- User Progress (XP, levels, streaks)
CREATE TABLE user_progress (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,

    -- Leveling System
    level INTEGER DEFAULT 1 CHECK (level > 0),
    current_xp INTEGER DEFAULT 0 CHECK (current_xp >= 0),
    total_xp INTEGER DEFAULT 0 CHECK (total_xp >= 0),

    -- Streaks
    current_streak INTEGER DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak INTEGER DEFAULT 0 CHECK (longest_streak >= 0),
    last_workout_date DATE,

    -- Statistics
    total_workouts_completed INTEGER DEFAULT 0,
    total_workout_minutes INTEGER DEFAULT 0,
    total_calories_burned INTEGER DEFAULT 0,

    -- Weekly Goals
    weekly_workout_goal INTEGER DEFAULT 3,
    weekly_workouts_completed INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Badges (Achievement definitions)
CREATE TABLE badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon_url TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('workout', 'streak', 'social', 'challenge', 'special')),

    -- Criteria (JSON object defining how to earn the badge)
    criteria_json JSONB NOT NULL,

    -- Rarity
    rarity TEXT NOT NULL DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),

    -- XP reward for earning badge
    xp_reward INTEGER DEFAULT 0 CHECK (xp_reward >= 0),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Badges (Earned badges)
CREATE TABLE user_badges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, badge_id)
);

-- Missions (Daily/Weekly challenges)
CREATE TABLE missions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL CHECK (type IN ('daily', 'weekly', 'special')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    xp_reward INTEGER NOT NULL CHECK (xp_reward > 0),

    -- Criteria (JSON object defining mission completion)
    criteria_json JSONB NOT NULL,

    -- Validity period
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Missions (Mission progress tracking)
CREATE TABLE user_missions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,

    -- Progress
    progress INTEGER DEFAULT 0,
    target INTEGER NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    -- Reward claimed
    reward_claimed BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, mission_id)
);

-- =====================================================
-- WORKOUTS & EXERCISES
-- =====================================================

-- Workouts (Predefined workout routines)
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('Strength', 'Cardio', 'Flexibility', 'HIIT', 'Yoga', 'Sports', 'Dance', 'Recovery')),
    difficulty TEXT NOT NULL CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),

    -- Duration in minutes
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),

    -- Estimated calories burned
    estimated_calories INTEGER DEFAULT 0,

    -- Media
    thumbnail_url TEXT,
    video_url TEXT,

    -- Creator (trainer or admin)
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    is_premium BOOLEAN DEFAULT FALSE,

    -- Equipment needed
    equipment_needed TEXT[],

    -- Target muscle groups
    target_muscles TEXT[],

    -- Ratings
    average_rating DECIMAL(3,2) DEFAULT 0.0 CHECK (average_rating >= 0 AND average_rating <= 5),
    total_ratings INTEGER DEFAULT 0,
    total_completions INTEGER DEFAULT 0,

    -- Status
    is_published BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Exercises (Individual exercise definitions)
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    muscle_group TEXT NOT NULL CHECK (muscle_group IN ('Chest', 'Back', 'Shoulders', 'Arms', 'Core', 'Legs', 'Full Body', 'Cardio')),
    equipment TEXT CHECK (equipment IN ('None', 'Dumbbells', 'Barbell', 'Resistance Bands', 'Pull-up Bar', 'Kettlebell', 'Medicine Ball', 'Bench', 'Machine')),

    -- Demonstration media
    demo_image_url TEXT,
    demo_video_url TEXT,

    -- Instructions
    instructions TEXT[],

    -- Difficulty
    difficulty TEXT NOT NULL CHECK (difficulty IN ('Beginner', 'Intermediate', 'Advanced')),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workout Exercises (Many-to-many relationship)
CREATE TABLE workout_exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,

    -- Exercise order in workout
    exercise_order INTEGER NOT NULL,

    -- Sets, reps, duration
    sets INTEGER,
    reps INTEGER,
    duration_seconds INTEGER,
    rest_seconds INTEGER DEFAULT 60,

    -- Notes for this exercise in this workout
    notes TEXT,

    UNIQUE(workout_id, exercise_order)
);

-- Workout Sessions (User workout history)
CREATE TABLE workout_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,

    -- Session details
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    duration_minutes INTEGER,

    -- Performance
    exercises_completed INTEGER DEFAULT 0,
    total_exercises INTEGER,
    calories_burned INTEGER DEFAULT 0,

    -- User rating and feedback
    user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
    user_feedback TEXT,

    -- XP earned from this session
    xp_earned INTEGER DEFAULT 0,

    -- Status
    status TEXT DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- SOCIAL FEATURES
-- =====================================================

-- Social Circles (Groups of friends)
CREATE TABLE social_circles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Privacy settings
    privacy TEXT NOT NULL DEFAULT 'private' CHECK (privacy IN ('public', 'private', 'invite_only')),

    -- Circle avatar
    avatar_url TEXT,

    -- Statistics
    member_count INTEGER DEFAULT 1,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Circle Members
CREATE TABLE circle_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id UUID NOT NULL REFERENCES social_circles(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Role in circle
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('creator', 'admin', 'member')),

    joined_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(circle_id, user_id)
);

-- Circle Invitations
CREATE TABLE circle_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    circle_id UUID NOT NULL REFERENCES social_circles(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    responded_at TIMESTAMPTZ,

    UNIQUE(circle_id, invitee_id)
);

-- =====================================================
-- CHALLENGES
-- =====================================================

-- Challenges (Location-based or global challenges)
CREATE TABLE challenges (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,

    -- Challenge type
    type TEXT NOT NULL CHECK (type IN ('location_based', 'global', 'circle')),

    -- Location (for location-based challenges)
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    location_name TEXT,
    location_radius_km DECIMAL(6,2), -- Radius in km

    -- Circle (for circle-only challenges)
    circle_id UUID REFERENCES social_circles(id) ON DELETE CASCADE,

    -- Time period
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,

    -- Challenge criteria
    goal_type TEXT NOT NULL CHECK (goal_type IN ('workouts_count', 'total_minutes', 'calories_burned', 'specific_workout')),
    goal_target INTEGER NOT NULL,

    -- Rewards
    xp_reward INTEGER DEFAULT 0,
    badge_reward_id UUID REFERENCES badges(id) ON DELETE SET NULL,

    -- Sponsor (optional brand partnership)
    sponsor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    sponsor_logo_url TEXT,
    sponsor_prize_description TEXT,

    -- Media
    image_url TEXT,

    -- Statistics
    participant_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Challenge Participants
CREATE TABLE challenge_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Progress tracking
    current_progress INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    -- Ranking (for leaderboard)
    rank INTEGER,

    joined_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(challenge_id, user_id)
);

-- =====================================================
-- TRAINER MARKETPLACE
-- =====================================================

-- Trainer Gigs (Services offered by trainers)
CREATE TABLE trainer_gigs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Personal Training', 'Group Class', 'Online Coaching', 'Nutrition Consulting', 'Custom Workout Plan')),

    -- Pricing
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    currency TEXT DEFAULT 'USD',

    -- Duration
    duration_minutes INTEGER,

    -- Location
    location_type TEXT NOT NULL CHECK (location_type IN ('in_person', 'online', 'hybrid')),
    location_address TEXT,

    -- Media
    thumbnail_url TEXT,
    images TEXT[],

    -- Availability
    is_available BOOLEAN DEFAULT TRUE,

    -- Statistics
    total_bookings INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bookings
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gig_id UUID NOT NULL REFERENCES trainer_gigs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Booking details
    scheduled_date TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL,

    -- Pricing
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    platform_commission DECIMAL(10,2) NOT NULL, -- Rezzmo's 20% commission
    trainer_payout DECIMAL(10,2) NOT NULL,

    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'refunded')),

    -- Payment
    payment_id UUID,

    -- Session notes
    trainer_notes TEXT,
    user_notes TEXT,

    -- Rating (after completion)
    user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
    user_review TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- PAYMENTS & SUBSCRIPTIONS
-- =====================================================

-- Payments (Transaction history)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Payment details
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',

    -- Payment type
    type TEXT NOT NULL CHECK (type IN ('subscription', 'booking', 'one_time')),

    -- Status
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'succeeded', 'failed', 'refunded')),

    -- Related entities
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    subscription_id UUID,

    -- Stripe integration
    stripe_payment_intent_id TEXT,
    stripe_charge_id TEXT,

    -- Metadata
    description TEXT,
    metadata JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscriptions (Premium membership)
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Plan details
    plan TEXT NOT NULL CHECK (plan IN ('free', 'premium_monthly', 'premium_yearly')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'past_due', 'expired')),

    -- Pricing
    amount DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',

    -- Stripe integration
    stripe_subscription_id TEXT UNIQUE,
    stripe_customer_id TEXT,

    -- Billing period
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,

    -- Cancellation
    cancel_at_period_end BOOLEAN DEFAULT FALSE,
    cancelled_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id)
);

-- =====================================================
-- NOTIFICATIONS & MESSAGING
-- =====================================================

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Notification content
    type TEXT NOT NULL CHECK (type IN ('workout', 'challenge', 'social', 'booking', 'achievement', 'system')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,

    -- Related entity
    related_entity_type TEXT,
    related_entity_id UUID,

    -- Action link
    action_url TEXT,

    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Voice Messages (for trainer communication)
CREATE TABLE voice_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,

    -- Audio file
    audio_url TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL,

    -- Optional booking context
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,

    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Profiles indexes
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_user_type ON profiles(user_type);
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_location ON profiles USING GIST(
    ST_SetSRID(ST_MakePoint(location_lng, location_lat), 4326)
) WHERE location_lat IS NOT NULL AND location_lng IS NOT NULL;

-- User Progress indexes
CREATE INDEX idx_user_progress_level ON user_progress(level DESC);
CREATE INDEX idx_user_progress_total_xp ON user_progress(total_xp DESC);

-- Workout Sessions indexes
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_workout_id ON workout_sessions(workout_id);
CREATE INDEX idx_workout_sessions_created_at ON workout_sessions(created_at DESC);

-- Workouts indexes
CREATE INDEX idx_workouts_category ON workouts(category);
CREATE INDEX idx_workouts_difficulty ON workouts(difficulty);
CREATE INDEX idx_workouts_created_by ON workouts(created_by);

-- Challenges indexes
CREATE INDEX idx_challenges_type ON challenges(type);
CREATE INDEX idx_challenges_start_date ON challenges(start_date);
CREATE INDEX idx_challenges_end_date ON challenges(end_date);
CREATE INDEX idx_challenges_location ON challenges USING GIST(
    ST_SetSRID(ST_MakePoint(location_lng, location_lat), 4326)
) WHERE location_lat IS NOT NULL AND location_lng IS NOT NULL;

-- Bookings indexes
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_trainer_id ON bookings(trainer_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_scheduled_date ON bookings(scheduled_date);

-- Payments indexes
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_created_at ON payments(created_at DESC);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Update updated_at timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_progress_updated_at BEFORE UPDATE ON user_progress
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON workouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_social_circles_updated_at BEFORE UPDATE ON social_circles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_challenges_updated_at BEFORE UPDATE ON challenges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trainer_gigs_updated_at BEFORE UPDATE ON trainer_gigs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_missions_updated_at BEFORE UPDATE ON user_missions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
