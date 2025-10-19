-- =====================================================
-- Rezzmo RLS Policies - Security Layer
-- Created: October 17, 2025
-- Description: Row Level Security policies for all tables
-- =====================================================

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE circle_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE trainer_gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_messages ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is trainer
CREATE OR REPLACE FUNCTION is_trainer()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND user_type = 'Trainer'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is circle member
CREATE OR REPLACE FUNCTION is_circle_member(circle_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM circle_members
        WHERE circle_members.circle_id = $1 AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is circle admin
CREATE OR REPLACE FUNCTION is_circle_admin(circle_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM circle_members
        WHERE circle_members.circle_id = $1
        AND user_id = auth.uid()
        AND role IN ('creator', 'admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PROFILES POLICIES
-- =====================================================

-- Users can view all profiles (for social features)
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

-- Users can insert their own profile during registration
CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Admins can update any profile
CREATE POLICY "Admins can update any profile"
    ON profiles FOR UPDATE
    USING (is_admin());

-- Users cannot delete their own profile (must be done via admin)
CREATE POLICY "Only admins can delete profiles"
    ON profiles FOR DELETE
    USING (is_admin());

-- =====================================================
-- USER PROGRESS POLICIES
-- =====================================================

-- Users can view their own progress
CREATE POLICY "Users can view their own progress"
    ON user_progress FOR SELECT
    USING (auth.uid() = user_id);

-- Circle members can view each other's progress
CREATE POLICY "Circle members can view each other's progress"
    ON user_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members cm1
            JOIN circle_members cm2 ON cm1.circle_id = cm2.circle_id
            WHERE cm1.user_id = auth.uid() AND cm2.user_id = user_progress.user_id
        )
    );

-- Users can insert their own progress
CREATE POLICY "Users can insert their own progress"
    ON user_progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress
CREATE POLICY "Users can update their own progress"
    ON user_progress FOR UPDATE
    USING (auth.uid() = user_id);

-- =====================================================
-- BADGES POLICIES
-- =====================================================

-- Anyone can view badges (they're public)
CREATE POLICY "Badges are viewable by everyone"
    ON badges FOR SELECT
    USING (true);

-- Only admins can create/update/delete badges
CREATE POLICY "Only admins can manage badges"
    ON badges FOR ALL
    USING (is_admin());

-- =====================================================
-- USER BADGES POLICIES
-- =====================================================

-- Users can view their own badges
CREATE POLICY "Users can view their own badges"
    ON user_badges FOR SELECT
    USING (auth.uid() = user_id);

-- Other users can view user badges (for profiles)
CREATE POLICY "User badges are publicly viewable"
    ON user_badges FOR SELECT
    USING (true);

-- System can insert badges (via database functions)
CREATE POLICY "System can insert user badges"
    ON user_badges FOR INSERT
    WITH CHECK (true); -- Will be controlled by database functions

-- =====================================================
-- MISSIONS POLICIES
-- =====================================================

-- Active missions are viewable by everyone
CREATE POLICY "Active missions are viewable by everyone"
    ON missions FOR SELECT
    USING (is_active = true);

-- Admins can manage all missions
CREATE POLICY "Admins can manage missions"
    ON missions FOR ALL
    USING (is_admin());

-- =====================================================
-- USER MISSIONS POLICIES
-- =====================================================

-- Users can view their own missions
CREATE POLICY "Users can view their own missions"
    ON user_missions FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own missions (when accepting a mission)
CREATE POLICY "Users can insert their own missions"
    ON user_missions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own missions (progress)
CREATE POLICY "Users can update their own missions"
    ON user_missions FOR UPDATE
    USING (auth.uid() = user_id);

-- =====================================================
-- WORKOUTS POLICIES
-- =====================================================

-- Published workouts are viewable by everyone
CREATE POLICY "Published workouts are viewable by everyone"
    ON workouts FOR SELECT
    USING (is_published = true);

-- Creators can view their own unpublished workouts
CREATE POLICY "Creators can view their own workouts"
    ON workouts FOR SELECT
    USING (auth.uid() = created_by);

-- Trainers can create workouts
CREATE POLICY "Trainers can create workouts"
    ON workouts FOR INSERT
    WITH CHECK (is_trainer() OR is_admin());

-- Creators can update their own workouts
CREATE POLICY "Creators can update their own workouts"
    ON workouts FOR UPDATE
    USING (auth.uid() = created_by);

-- Admins can manage all workouts
CREATE POLICY "Admins can manage all workouts"
    ON workouts FOR ALL
    USING (is_admin());

-- =====================================================
-- EXERCISES POLICIES
-- =====================================================

-- Exercises are viewable by everyone
CREATE POLICY "Exercises are viewable by everyone"
    ON exercises FOR SELECT
    USING (true);

-- Only admins can manage exercises
CREATE POLICY "Only admins can manage exercises"
    ON exercises FOR ALL
    USING (is_admin());

-- =====================================================
-- WORKOUT EXERCISES POLICIES
-- =====================================================

-- Workout exercises follow workout visibility
CREATE POLICY "Workout exercises are viewable with workouts"
    ON workout_exercises FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND (workouts.is_published = true OR workouts.created_by = auth.uid())
        )
    );

-- Workout creators can manage workout exercises
CREATE POLICY "Workout creators can manage workout exercises"
    ON workout_exercises FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM workouts
            WHERE workouts.id = workout_exercises.workout_id
            AND workouts.created_by = auth.uid()
        )
    );

-- =====================================================
-- WORKOUT SESSIONS POLICIES
-- =====================================================

-- Users can view their own workout sessions
CREATE POLICY "Users can view their own workout sessions"
    ON workout_sessions FOR SELECT
    USING (auth.uid() = user_id);

-- Circle members can view each other's sessions (for social features)
CREATE POLICY "Circle members can view each other's sessions"
    ON workout_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM circle_members cm1
            JOIN circle_members cm2 ON cm1.circle_id = cm2.circle_id
            WHERE cm1.user_id = auth.uid() AND cm2.user_id = workout_sessions.user_id
        )
    );

-- Users can insert their own sessions
CREATE POLICY "Users can insert their own sessions"
    ON workout_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own sessions
CREATE POLICY "Users can update their own sessions"
    ON workout_sessions FOR UPDATE
    USING (auth.uid() = user_id);

-- =====================================================
-- SOCIAL CIRCLES POLICIES
-- =====================================================

-- Public circles are viewable by everyone
CREATE POLICY "Public circles are viewable by everyone"
    ON social_circles FOR SELECT
    USING (privacy = 'public');

-- Circle members can view their circles
CREATE POLICY "Circle members can view their circles"
    ON social_circles FOR SELECT
    USING (is_circle_member(id));

-- Users can create circles
CREATE POLICY "Users can create circles"
    ON social_circles FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

-- Circle creators and admins can update circles
CREATE POLICY "Circle admins can update circles"
    ON social_circles FOR UPDATE
    USING (is_circle_admin(id));

-- Circle creators can delete circles
CREATE POLICY "Circle creators can delete circles"
    ON social_circles FOR DELETE
    USING (auth.uid() = creator_id);

-- =====================================================
-- CIRCLE MEMBERS POLICIES
-- =====================================================

-- Circle members can view other members in their circles
CREATE POLICY "Circle members can view other members"
    ON circle_members FOR SELECT
    USING (is_circle_member(circle_id));

-- Circle admins can add members
CREATE POLICY "Circle admins can add members"
    ON circle_members FOR INSERT
    WITH CHECK (is_circle_admin(circle_id));

-- Circle admins can remove members
CREATE POLICY "Circle admins can remove members"
    ON circle_members FOR DELETE
    USING (is_circle_admin(circle_id));

-- Members can remove themselves
CREATE POLICY "Members can leave circles"
    ON circle_members FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- CIRCLE INVITATIONS POLICIES
-- =====================================================

-- Users can view invitations sent to them
CREATE POLICY "Users can view their invitations"
    ON circle_invitations FOR SELECT
    USING (auth.uid() = invitee_id);

-- Circle admins can view invitations for their circles
CREATE POLICY "Circle admins can view circle invitations"
    ON circle_invitations FOR SELECT
    USING (is_circle_admin(circle_id));

-- Circle admins can send invitations
CREATE POLICY "Circle admins can send invitations"
    ON circle_invitations FOR INSERT
    WITH CHECK (is_circle_admin(circle_id) AND auth.uid() = inviter_id);

-- Invitees can update invitation status (accept/decline)
CREATE POLICY "Invitees can respond to invitations"
    ON circle_invitations FOR UPDATE
    USING (auth.uid() = invitee_id);

-- =====================================================
-- CHALLENGES POLICIES
-- =====================================================

-- Active challenges are viewable by everyone
CREATE POLICY "Active challenges are viewable by everyone"
    ON challenges FOR SELECT
    USING (is_active = true);

-- Users/admins can create challenges
CREATE POLICY "Users can create challenges"
    ON challenges FOR INSERT
    WITH CHECK (auth.uid() = created_by);

-- Challenge creators can update their challenges
CREATE POLICY "Challenge creators can update their challenges"
    ON challenges FOR UPDATE
    USING (auth.uid() = created_by);

-- Admins can manage all challenges
CREATE POLICY "Admins can manage all challenges"
    ON challenges FOR ALL
    USING (is_admin());

-- =====================================================
-- CHALLENGE PARTICIPANTS POLICIES
-- =====================================================

-- Users can view participants in challenges they joined
CREATE POLICY "Users can view challenge participants"
    ON challenge_participants FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM challenge_participants cp
            WHERE cp.challenge_id = challenge_participants.challenge_id
            AND cp.user_id = auth.uid()
        )
    );

-- Users can join challenges
CREATE POLICY "Users can join challenges"
    ON challenge_participants FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress
CREATE POLICY "Users can update their challenge progress"
    ON challenge_participants FOR UPDATE
    USING (auth.uid() = user_id);

-- =====================================================
-- TRAINER GIGS POLICIES
-- =====================================================

-- Available gigs are viewable by everyone
CREATE POLICY "Available gigs are viewable by everyone"
    ON trainer_gigs FOR SELECT
    USING (is_available = true);

-- Trainers can view their own gigs (even if not available)
CREATE POLICY "Trainers can view their own gigs"
    ON trainer_gigs FOR SELECT
    USING (auth.uid() = trainer_id);

-- Trainers can create gigs
CREATE POLICY "Trainers can create gigs"
    ON trainer_gigs FOR INSERT
    WITH CHECK (is_trainer() AND auth.uid() = trainer_id);

-- Trainers can update their own gigs
CREATE POLICY "Trainers can update their own gigs"
    ON trainer_gigs FOR UPDATE
    USING (auth.uid() = trainer_id);

-- Trainers can delete their own gigs
CREATE POLICY "Trainers can delete their own gigs"
    ON trainer_gigs FOR DELETE
    USING (auth.uid() = trainer_id);

-- =====================================================
-- BOOKINGS POLICIES
-- =====================================================

-- Users can view their own bookings (as client)
CREATE POLICY "Users can view their bookings"
    ON bookings FOR SELECT
    USING (auth.uid() = user_id);

-- Trainers can view their bookings (as trainer)
CREATE POLICY "Trainers can view their bookings"
    ON bookings FOR SELECT
    USING (auth.uid() = trainer_id);

-- Users can create bookings
CREATE POLICY "Users can create bookings"
    ON bookings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users and trainers can update bookings
CREATE POLICY "Users and trainers can update bookings"
    ON bookings FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() = trainer_id);

-- Admins can view and manage all bookings
CREATE POLICY "Admins can manage all bookings"
    ON bookings FOR ALL
    USING (is_admin());

-- =====================================================
-- PAYMENTS POLICIES
-- =====================================================

-- Users can view their own payments
CREATE POLICY "Users can view their own payments"
    ON payments FOR SELECT
    USING (auth.uid() = user_id);

-- System can insert payments (via Edge Functions)
CREATE POLICY "System can insert payments"
    ON payments FOR INSERT
    WITH CHECK (true); -- Controlled by Edge Functions with service role

-- Admins can view all payments
CREATE POLICY "Admins can view all payments"
    ON payments FOR SELECT
    USING (is_admin());

-- =====================================================
-- SUBSCRIPTIONS POLICIES
-- =====================================================

-- Users can view their own subscription
CREATE POLICY "Users can view their own subscription"
    ON subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- System can manage subscriptions (via Edge Functions)
CREATE POLICY "System can manage subscriptions"
    ON subscriptions FOR ALL
    WITH CHECK (true); -- Controlled by Edge Functions with service role

-- Admins can view all subscriptions
CREATE POLICY "Admins can view all subscriptions"
    ON subscriptions FOR SELECT
    USING (is_admin());

-- =====================================================
-- NOTIFICATIONS POLICIES
-- =====================================================

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

-- System can create notifications
CREATE POLICY "System can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (true); -- Controlled by Edge Functions

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
    ON notifications FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- VOICE MESSAGES POLICIES
-- =====================================================

-- Users can view messages they sent
CREATE POLICY "Users can view sent voice messages"
    ON voice_messages FOR SELECT
    USING (auth.uid() = sender_id);

-- Users can view messages sent to them
CREATE POLICY "Users can view received voice messages"
    ON voice_messages FOR SELECT
    USING (auth.uid() = recipient_id);

-- Users can send voice messages
CREATE POLICY "Users can send voice messages"
    ON voice_messages FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

-- Recipients can update message status (mark as read)
CREATE POLICY "Recipients can update message status"
    ON voice_messages FOR UPDATE
    USING (auth.uid() = recipient_id);

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant authenticated users access to tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- Grant anonymous users read-only access to public data
GRANT SELECT ON profiles, workouts, exercises, challenges, trainer_gigs, badges TO anon;
