-- =====================================================
-- Rezzmo Database Functions
-- Created: October 17, 2025
-- Description: Game mechanics and utility functions
-- =====================================================

-- =====================================================
-- XP & LEVELING SYSTEM
-- =====================================================

-- Calculate level from total XP
CREATE OR REPLACE FUNCTION calculate_level_from_xp(total_xp INTEGER)
RETURNS INTEGER AS $$
DECLARE
    level INTEGER;
BEGIN
    -- Level formula: Each level requires 100 * level XP
    -- Level 1: 0-99 XP
    -- Level 2: 100-299 XP (100 + 200)
    -- Level 3: 300-599 XP (100 + 200 + 300)
    -- Formula: total_xp = 100 * (level * (level + 1) / 2)

    level := FLOOR((-1 + SQRT(1 + 8 * total_xp / 100.0)) / 2) + 1;

    RETURN GREATEST(level, 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Calculate XP needed for next level
CREATE OR REPLACE FUNCTION xp_needed_for_next_level(current_level INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN 100 * (current_level + 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Award XP to user and handle level-ups
CREATE OR REPLACE FUNCTION award_xp(
    p_user_id UUID,
    p_xp_amount INTEGER,
    p_source TEXT DEFAULT 'workout'
)
RETURNS TABLE(
    new_level INTEGER,
    new_total_xp INTEGER,
    leveled_up BOOLEAN,
    xp_to_next_level INTEGER
) AS $$
DECLARE
    v_old_level INTEGER;
    v_new_level INTEGER;
    v_new_total_xp INTEGER;
    v_leveled_up BOOLEAN;
    v_xp_to_next INTEGER;
BEGIN
    -- Get current progress
    SELECT level, total_xp INTO v_old_level, v_new_total_xp
    FROM user_progress
    WHERE user_id = p_user_id;

    -- If user progress doesn't exist, create it
    IF v_old_level IS NULL THEN
        INSERT INTO user_progress (user_id, level, current_xp, total_xp)
        VALUES (p_user_id, 1, 0, 0);
        v_old_level := 1;
        v_new_total_xp := 0;
    END IF;

    -- Add XP
    v_new_total_xp := v_new_total_xp + p_xp_amount;
    v_new_level := calculate_level_from_xp(v_new_total_xp);
    v_leveled_up := v_new_level > v_old_level;

    -- Calculate current XP within level
    DECLARE
        v_xp_for_current_level INTEGER;
        v_current_xp INTEGER;
    BEGIN
        v_xp_for_current_level := 100 * (v_new_level * (v_new_level - 1) / 2);
        v_current_xp := v_new_total_xp - v_xp_for_current_level;
        v_xp_to_next := xp_needed_for_next_level(v_new_level) - v_current_xp;

        -- Update user progress
        UPDATE user_progress
        SET
            level = v_new_level,
            current_xp = v_current_xp,
            total_xp = v_new_total_xp,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END;

    -- If leveled up, create notification
    IF v_leveled_up THEN
        INSERT INTO notifications (user_id, type, title, message)
        VALUES (
            p_user_id,
            'achievement',
            'Level Up!',
            'Congratulations! You reached level ' || v_new_level || '!'
        );
    END IF;

    -- Return results
    RETURN QUERY SELECT v_new_level, v_new_total_xp, v_leveled_up, v_xp_to_next;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STREAK SYSTEM
-- =====================================================

-- Update user streak based on workout completion
CREATE OR REPLACE FUNCTION update_streak(p_user_id UUID)
RETURNS TABLE(
    current_streak INTEGER,
    longest_streak INTEGER,
    streak_maintained BOOLEAN
) AS $$
DECLARE
    v_last_workout_date DATE;
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_today DATE := CURRENT_DATE;
    v_streak_maintained BOOLEAN;
BEGIN
    -- Get current streak data
    SELECT last_workout_date, user_progress.current_streak, user_progress.longest_streak
    INTO v_last_workout_date, v_current_streak, v_longest_streak
    FROM user_progress
    WHERE user_id = p_user_id;

    -- Initialize if null
    IF v_current_streak IS NULL THEN
        v_current_streak := 0;
        v_longest_streak := 0;
    END IF;

    -- Calculate new streak
    IF v_last_workout_date IS NULL THEN
        -- First workout ever
        v_current_streak := 1;
        v_streak_maintained := TRUE;
    ELSIF v_last_workout_date = v_today THEN
        -- Already worked out today, maintain streak
        v_streak_maintained := TRUE;
    ELSIF v_last_workout_date = v_today - INTERVAL '1 day' THEN
        -- Worked out yesterday, increment streak
        v_current_streak := v_current_streak + 1;
        v_streak_maintained := TRUE;
    ELSE
        -- Streak broken, reset
        v_current_streak := 1;
        v_streak_maintained := FALSE;
    END IF;

    -- Update longest streak if current is higher
    IF v_current_streak > v_longest_streak THEN
        v_longest_streak := v_current_streak;

        -- Award streak milestone badges
        PERFORM check_and_award_streak_badges(p_user_id, v_current_streak);
    END IF;

    -- Update user progress
    UPDATE user_progress
    SET
        current_streak = v_current_streak,
        longest_streak = v_longest_streak,
        last_workout_date = v_today,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Create notification for streak milestones
    IF v_current_streak IN (7, 30, 100, 365) THEN
        INSERT INTO notifications (user_id, type, title, message)
        VALUES (
            p_user_id,
            'achievement',
            'Streak Milestone!',
            'Amazing! You maintained a ' || v_current_streak || '-day workout streak!'
        );
    END IF;

    RETURN QUERY SELECT v_current_streak, v_longest_streak, v_streak_maintained;
END;
$$ LANGUAGE plpgsql;

-- Check streak status (for daily reminders)
CREATE OR REPLACE FUNCTION check_streak_status(p_user_id UUID)
RETURNS TABLE(
    is_active BOOLEAN,
    days_count INTEGER,
    at_risk BOOLEAN
) AS $$
DECLARE
    v_last_workout_date DATE;
    v_current_streak INTEGER;
    v_today DATE := CURRENT_DATE;
    v_is_active BOOLEAN;
    v_at_risk BOOLEAN;
BEGIN
    SELECT last_workout_date, current_streak
    INTO v_last_workout_date, v_current_streak
    FROM user_progress
    WHERE user_id = p_user_id;

    -- Check if streak is active
    v_is_active := (v_last_workout_date = v_today OR v_last_workout_date = v_today - INTERVAL '1 day');

    -- Check if streak is at risk (didn't workout today)
    v_at_risk := (v_last_workout_date = v_today - INTERVAL '1 day' AND v_current_streak > 0);

    RETURN QUERY SELECT v_is_active, COALESCE(v_current_streak, 0), v_at_risk;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- BADGE SYSTEM
-- =====================================================

-- Award badge to user (if not already earned)
CREATE OR REPLACE FUNCTION award_badge(
    p_user_id UUID,
    p_badge_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_already_earned BOOLEAN;
    v_xp_reward INTEGER;
    v_badge_name TEXT;
BEGIN
    -- Check if already earned
    SELECT EXISTS (
        SELECT 1 FROM user_badges
        WHERE user_id = p_user_id AND badge_id = p_badge_id
    ) INTO v_already_earned;

    IF v_already_earned THEN
        RETURN FALSE;
    END IF;

    -- Get badge details
    SELECT xp_reward, name INTO v_xp_reward, v_badge_name
    FROM badges
    WHERE id = p_badge_id;

    -- Award badge
    INSERT INTO user_badges (user_id, badge_id)
    VALUES (p_user_id, p_badge_id);

    -- Award XP
    IF v_xp_reward > 0 THEN
        PERFORM award_xp(p_user_id, v_xp_reward, 'badge');
    END IF;

    -- Create notification
    INSERT INTO notifications (user_id, type, title, message, related_entity_type, related_entity_id)
    VALUES (
        p_user_id,
        'achievement',
        'New Badge Earned!',
        'You earned the "' || v_badge_name || '" badge!',
        'badge',
        p_badge_id
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Check and award streak badges
CREATE OR REPLACE FUNCTION check_and_award_streak_badges(
    p_user_id UUID,
    p_streak_count INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_badge_id UUID;
BEGIN
    -- 7-day streak badge
    IF p_streak_count >= 7 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Week Warrior' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;

    -- 30-day streak badge
    IF p_streak_count >= 30 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Month Master' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;

    -- 100-day streak badge
    IF p_streak_count >= 100 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Century Champion' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;

    -- 365-day streak badge
    IF p_streak_count >= 365 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Year Legend' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Check and award workout count badges
CREATE OR REPLACE FUNCTION check_and_award_workout_badges(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_workout_count INTEGER;
    v_badge_id UUID;
BEGIN
    -- Get total workout count
    SELECT total_workouts_completed INTO v_workout_count
    FROM user_progress
    WHERE user_id = p_user_id;

    -- 10 workouts badge
    IF v_workout_count >= 10 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Getting Started' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;

    -- 50 workouts badge
    IF v_workout_count >= 50 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Fitness Enthusiast' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;

    -- 100 workouts badge
    IF v_workout_count >= 100 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Workout Warrior' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;

    -- 500 workouts badge
    IF v_workout_count >= 500 THEN
        SELECT id INTO v_badge_id FROM badges WHERE name = 'Fitness Legend' LIMIT 1;
        IF v_badge_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_id);
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- WORKOUT COMPLETION
-- =====================================================

-- Complete workout session and award rewards
CREATE OR REPLACE FUNCTION complete_workout_session(
    p_session_id UUID,
    p_exercises_completed INTEGER,
    p_calories_burned INTEGER
)
RETURNS TABLE(
    xp_earned INTEGER,
    level_up BOOLEAN,
    streak_info JSONB
) AS $$
DECLARE
    v_user_id UUID;
    v_workout_id UUID;
    v_duration_minutes INTEGER;
    v_xp_earned INTEGER;
    v_level_result RECORD;
    v_streak_result RECORD;
    v_streak_info JSONB;
    v_leveled_up BOOLEAN;
BEGIN
    -- Get session details
    SELECT user_id, workout_id,
           EXTRACT(EPOCH FROM (NOW() - started_at)) / 60
    INTO v_user_id, v_workout_id, v_duration_minutes
    FROM workout_sessions
    WHERE id = p_session_id;

    -- Calculate XP (base 50 + 10 per 10 minutes)
    v_xp_earned := 50 + (v_duration_minutes / 10) * 10;

    -- Bonus XP for completing all exercises
    IF p_exercises_completed >= (SELECT COUNT(*) FROM workout_exercises WHERE workout_id = v_workout_id) THEN
        v_xp_earned := v_xp_earned + 20;
    END IF;

    -- Update workout session
    UPDATE workout_sessions
    SET
        completed_at = NOW(),
        duration_minutes = v_duration_minutes,
        exercises_completed = p_exercises_completed,
        calories_burned = p_calories_burned,
        xp_earned = v_xp_earned,
        status = 'completed'
    WHERE id = p_session_id;

    -- Update user progress
    UPDATE user_progress
    SET
        total_workouts_completed = total_workouts_completed + 1,
        total_workout_minutes = total_workout_minutes + v_duration_minutes,
        total_calories_burned = total_calories_burned + p_calories_burned
    WHERE user_id = v_user_id;

    -- Award XP
    SELECT * INTO v_level_result
    FROM award_xp(v_user_id, v_xp_earned, 'workout');

    v_leveled_up := v_level_result.leveled_up;

    -- Update streak
    SELECT * INTO v_streak_result
    FROM update_streak(v_user_id);

    v_streak_info := jsonb_build_object(
        'current_streak', v_streak_result.current_streak,
        'longest_streak', v_streak_result.longest_streak,
        'streak_maintained', v_streak_result.streak_maintained
    );

    -- Check and award badges
    PERFORM check_and_award_workout_badges(v_user_id);

    -- Update workout completion count
    UPDATE workouts
    SET total_completions = total_completions + 1
    WHERE id = v_workout_id;

    -- Return results
    RETURN QUERY SELECT v_xp_earned, v_leveled_up, v_streak_info;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CHALLENGE SYSTEM
-- =====================================================

-- Update challenge participant progress
CREATE OR REPLACE FUNCTION update_challenge_progress(
    p_challenge_id UUID,
    p_user_id UUID,
    p_progress_increment INTEGER
)
RETURNS TABLE(
    new_progress INTEGER,
    challenge_completed BOOLEAN,
    reward_info JSONB
) AS $$
DECLARE
    v_new_progress INTEGER;
    v_goal_target INTEGER;
    v_completed BOOLEAN;
    v_xp_reward INTEGER;
    v_badge_reward_id UUID;
    v_reward_info JSONB;
BEGIN
    -- Get challenge details
    SELECT goal_target, xp_reward, badge_reward_id
    INTO v_goal_target, v_xp_reward, v_badge_reward_id
    FROM challenges
    WHERE id = p_challenge_id;

    -- Update progress
    UPDATE challenge_participants
    SET current_progress = current_progress + p_progress_increment
    WHERE challenge_id = p_challenge_id AND user_id = p_user_id
    RETURNING current_progress INTO v_new_progress;

    -- Check if completed
    v_completed := v_new_progress >= v_goal_target;

    IF v_completed THEN
        -- Mark as completed
        UPDATE challenge_participants
        SET
            completed = TRUE,
            completed_at = NOW()
        WHERE challenge_id = p_challenge_id AND user_id = p_user_id;

        -- Update challenge stats
        UPDATE challenges
        SET completion_count = completion_count + 1
        WHERE id = p_challenge_id;

        -- Award XP
        IF v_xp_reward > 0 THEN
            PERFORM award_xp(p_user_id, v_xp_reward, 'challenge');
        END IF;

        -- Award badge
        IF v_badge_reward_id IS NOT NULL THEN
            PERFORM award_badge(p_user_id, v_badge_reward_id);
        END IF;

        v_reward_info := jsonb_build_object(
            'xp_earned', v_xp_reward,
            'badge_earned', v_badge_reward_id IS NOT NULL
        );

        -- Create notification
        INSERT INTO notifications (user_id, type, title, message, related_entity_type, related_entity_id)
        VALUES (
            p_user_id,
            'achievement',
            'Challenge Completed!',
            'Congratulations! You completed a challenge!',
            'challenge',
            p_challenge_id
        );
    ELSE
        v_reward_info := jsonb_build_object('xp_earned', 0, 'badge_earned', false);
    END IF;

    RETURN QUERY SELECT v_new_progress, v_completed, v_reward_info;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- LEADERBOARD FUNCTIONS
-- =====================================================

-- Get global leaderboard (by total XP)
CREATE OR REPLACE FUNCTION get_global_leaderboard(p_limit INTEGER DEFAULT 100)
RETURNS TABLE(
    rank BIGINT,
    user_id UUID,
    display_name TEXT,
    avatar_url TEXT,
    level INTEGER,
    total_xp INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY up.total_xp DESC) as rank,
        p.id as user_id,
        COALESCE(p.display_name, p.full_name) as display_name,
        p.avatar_url,
        up.level,
        up.total_xp
    FROM user_progress up
    JOIN profiles p ON p.id = up.user_id
    ORDER BY up.total_xp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Get circle leaderboard
CREATE OR REPLACE FUNCTION get_circle_leaderboard(p_circle_id UUID, p_limit INTEGER DEFAULT 100)
RETURNS TABLE(
    rank BIGINT,
    user_id UUID,
    display_name TEXT,
    avatar_url TEXT,
    level INTEGER,
    total_xp INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY up.total_xp DESC) as rank,
        p.id as user_id,
        COALESCE(p.display_name, p.full_name) as display_name,
        p.avatar_url,
        up.level,
        up.total_xp
    FROM user_progress up
    JOIN profiles p ON p.id = up.user_id
    JOIN circle_members cm ON cm.user_id = p.id
    WHERE cm.circle_id = p_circle_id
    ORDER BY up.total_xp DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Get challenge leaderboard
CREATE OR REPLACE FUNCTION get_challenge_leaderboard(p_challenge_id UUID)
RETURNS TABLE(
    rank BIGINT,
    user_id UUID,
    display_name TEXT,
    avatar_url TEXT,
    progress INTEGER,
    completed BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER (ORDER BY cp.current_progress DESC) as rank,
        p.id as user_id,
        COALESCE(p.display_name, p.full_name) as display_name,
        p.avatar_url,
        cp.current_progress as progress,
        cp.completed
    FROM challenge_participants cp
    JOIN profiles p ON p.id = cp.user_id
    WHERE cp.challenge_id = p_challenge_id
    ORDER BY cp.current_progress DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- UTILITY FUNCTIONS
-- =====================================================

-- Get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'level', up.level,
        'current_xp', up.current_xp,
        'total_xp', up.total_xp,
        'xp_to_next_level', xp_needed_for_next_level(up.level) - up.current_xp,
        'current_streak', up.current_streak,
        'longest_streak', up.longest_streak,
        'total_workouts', up.total_workouts_completed,
        'total_minutes', up.total_workout_minutes,
        'total_calories', up.total_calories_burned,
        'badges_earned', (SELECT COUNT(*) FROM user_badges WHERE user_id = p_user_id),
        'challenges_completed', (SELECT COUNT(*) FROM challenge_participants WHERE user_id = p_user_id AND completed = true)
    ) INTO v_stats
    FROM user_progress up
    WHERE up.user_id = p_user_id;

    RETURN COALESCE(v_stats, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;
