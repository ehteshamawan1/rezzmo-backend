-- =====================================================
-- Rezzmo Seed Data
-- Created: October 17, 2025
-- Description: Initial data for badges, exercises, and workouts
-- =====================================================

-- =====================================================
-- BADGES
-- =====================================================

INSERT INTO badges (name, description, icon_url, category, criteria_json, rarity, xp_reward) VALUES
-- Workout Count Badges
('Getting Started', 'Complete your first 10 workouts', 'https://api.dicebear.com/7.x/shapes/svg?seed=getting-started', 'workout', '{"type": "workout_count", "target": 10}'::jsonb, 'common', 100),
('Fitness Enthusiast', 'Complete 50 workouts', 'https://api.dicebear.com/7.x/shapes/svg?seed=enthusiast', 'workout', '{"type": "workout_count", "target": 50}'::jsonb, 'rare', 250),
('Workout Warrior', 'Complete 100 workouts', 'https://api.dicebear.com/7.x/shapes/svg?seed=warrior', 'workout', '{"type": "workout_count", "target": 100}'::jsonb, 'epic', 500),
('Fitness Legend', 'Complete 500 workouts', 'https://api.dicebear.com/7.x/shapes/svg?seed=legend', 'workout', '{"type": "workout_count", "target": 500}'::jsonb, 'legendary', 2000),

-- Streak Badges
('Week Warrior', 'Maintain a 7-day workout streak', 'https://api.dicebear.com/7.x/shapes/svg?seed=week-warrior', 'streak', '{"type": "streak", "target": 7}'::jsonb, 'common', 150),
('Month Master', 'Maintain a 30-day workout streak', 'https://api.dicebear.com/7.x/shapes/svg?seed=month-master', 'streak', '{"type": "streak", "target": 30}'::jsonb, 'rare', 500),
('Century Champion', 'Maintain a 100-day workout streak', 'https://api.dicebear.com/7.x/shapes/svg?seed=century', 'streak', '{"type": "streak", "target": 100}'::jsonb, 'epic', 1500),
('Year Legend', 'Maintain a 365-day workout streak', 'https://api.dicebear.com/7.x/shapes/svg?seed=year-legend', 'streak', '{"type": "streak", "target": 365}'::jsonb, 'legendary', 5000),

-- Social Badges
('Social Butterfly', 'Join your first circle', 'https://api.dicebear.com/7.x/shapes/svg?seed=social', 'social', '{"type": "circle_join", "target": 1}'::jsonb, 'common', 50),
('Circle Creator', 'Create your own fitness circle', 'https://api.dicebear.com/7.x/shapes/svg?seed=creator', 'social', '{"type": "circle_create", "target": 1}'::jsonb, 'common', 100),
('Community Leader', 'Have 10 members in your circle', 'https://api.dicebear.com/7.x/shapes/svg?seed=leader', 'social', '{"type": "circle_members", "target": 10}'::jsonb, 'rare', 300),

-- Challenge Badges
('Challenge Accepted', 'Complete your first challenge', 'https://api.dicebear.com/7.x/shapes/svg?seed=challenge-1', 'challenge', '{"type": "challenge_complete", "target": 1}'::jsonb, 'common', 100),
('Challenge Master', 'Complete 10 challenges', 'https://api.dicebear.com/7.x/shapes/svg?seed=challenge-10', 'challenge', '{"type": "challenge_complete", "target": 10}'::jsonb, 'epic', 750),
('Location Explorer', 'Complete a location-based challenge', 'https://api.dicebear.com/7.x/shapes/svg?seed=explorer', 'challenge', '{"type": "location_challenge", "target": 1}'::jsonb, 'rare', 200),

-- Special Badges
('Early Adopter', 'Joined Rezzmo in the first month', 'https://api.dicebear.com/7.x/shapes/svg?seed=early', 'special', '{"type": "join_date", "before": "2025-11-01"}'::jsonb, 'legendary', 1000),
('Perfect Week', 'Complete workouts every day for a week', 'https://api.dicebear.com/7.x/shapes/svg?seed=perfect', 'special', '{"type": "perfect_week"}'::jsonb, 'epic', 500),
('Midnight Warrior', 'Complete a workout between midnight and 5 AM', 'https://api.dicebear.com/7.x/shapes/svg?seed=midnight', 'special', '{"type": "time_range", "start": "00:00", "end": "05:00"}'::jsonb, 'rare', 200);

-- =====================================================
-- EXERCISES
-- =====================================================

INSERT INTO exercises (name, description, muscle_group, equipment, instructions, difficulty) VALUES
-- Bodyweight Exercises
('Push-ups', 'Classic upper body exercise targeting chest, shoulders, and triceps', 'Chest', 'None', ARRAY['Start in plank position with hands shoulder-width apart', 'Lower body until chest nearly touches floor', 'Push back up to starting position', 'Keep core engaged throughout'], 'Beginner'),
('Squats', 'Fundamental lower body exercise for legs and glutes', 'Legs', 'None', ARRAY['Stand with feet shoulder-width apart', 'Lower body as if sitting back into a chair', 'Keep knees behind toes', 'Push through heels to return to standing'], 'Beginner'),
('Plank', 'Core stability exercise', 'Core', 'None', ARRAY['Start in forearm plank position', 'Keep body in straight line from head to heels', 'Engage core and hold position', 'Avoid sagging hips or raising them too high'], 'Beginner'),
('Lunges', 'Single-leg exercise for lower body strength and balance', 'Legs', 'None', ARRAY['Step forward with one leg', 'Lower hips until both knees bent at 90 degrees', 'Push back to starting position', 'Alternate legs'], 'Beginner'),
('Mountain Climbers', 'Dynamic cardio and core exercise', 'Full Body', 'None', ARRAY['Start in plank position', 'Bring one knee toward chest', 'Quickly switch legs', 'Maintain fast pace while keeping core stable'], 'Intermediate'),
('Burpees', 'Full-body explosive exercise', 'Full Body', 'None', ARRAY['Start standing', 'Drop to squat and place hands on ground', 'Jump feet back to plank', 'Do a push-up', 'Jump feet to hands', 'Jump up explosively'], 'Advanced'),

-- Dumbbell Exercises
('Dumbbell Rows', 'Back strengthening exercise', 'Back', 'Dumbbells', ARRAY['Hinge at hips with dumbbell in one hand', 'Pull dumbbell to hip level', 'Lower with control', 'Complete reps then switch sides'], 'Intermediate'),
('Dumbbell Shoulder Press', 'Shoulder and tricep builder', 'Shoulders', 'Dumbbells', ARRAY['Hold dumbbells at shoulder height', 'Press weights overhead', 'Lower with control', 'Keep core engaged'], 'Intermediate'),
('Dumbbell Bicep Curls', 'Arm isolation exercise', 'Arms', 'Dumbbells', ARRAY['Hold dumbbells at sides with palms forward', 'Curl weights toward shoulders', 'Lower with control', 'Avoid swinging'], 'Beginner'),
('Goblet Squats', 'Weighted squat variation', 'Legs', 'Dumbbells', ARRAY['Hold dumbbell at chest level', 'Perform squat movement', 'Keep chest up and core engaged', 'Drive through heels to stand'], 'Intermediate'),

-- Pull-up Bar Exercises
('Pull-ups', 'Upper body pulling exercise', 'Back', 'Pull-up Bar', ARRAY['Hang from bar with hands wider than shoulders', 'Pull body up until chin over bar', 'Lower with control', 'Avoid swinging'], 'Advanced'),
('Hanging Leg Raises', 'Advanced core exercise', 'Core', 'Pull-up Bar', ARRAY['Hang from pull-up bar', 'Raise legs to 90 degrees', 'Lower with control', 'Keep movements controlled'], 'Advanced'),

-- Cardio Exercises
('Jumping Jacks', 'Classic cardio warm-up', 'Cardio', 'None', ARRAY['Start with feet together, arms at sides', 'Jump feet apart while raising arms overhead', 'Jump back to starting position', 'Maintain steady rhythm'], 'Beginner'),
('High Knees', 'Cardio exercise for leg strength', 'Cardio', 'None', ARRAY['Run in place', 'Drive knees up toward chest', 'Pump arms vigorously', 'Maintain fast pace'], 'Beginner'),
('Jump Rope', 'Cardio and coordination exercise', 'Cardio', 'Resistance Bands', ARRAY['Hold rope handles at hip level', 'Swing rope overhead and jump as it passes under feet', 'Land softly on balls of feet', 'Maintain rhythm'], 'Intermediate');

-- =====================================================
-- SAMPLE WORKOUTS
-- =====================================================

-- Get exercise IDs for workout creation
DO $$
DECLARE
    v_workout_id UUID;
    v_pushup_id UUID;
    v_squat_id UUID;
    v_plank_id UUID;
    v_lunge_id UUID;
    v_mountain_id UUID;
    v_burpee_id UUID;
    v_jumpingjack_id UUID;
    v_highknees_id UUID;
    v_row_id UUID;
    v_press_id UUID;
BEGIN
    -- Get exercise IDs
    SELECT id INTO v_pushup_id FROM exercises WHERE name = 'Push-ups';
    SELECT id INTO v_squat_id FROM exercises WHERE name = 'Squats';
    SELECT id INTO v_plank_id FROM exercises WHERE name = 'Plank';
    SELECT id INTO v_lunge_id FROM exercises WHERE name = 'Lunges';
    SELECT id INTO v_mountain_id FROM exercises WHERE name = 'Mountain Climbers';
    SELECT id INTO v_burpee_id FROM exercises WHERE name = 'Burpees';
    SELECT id INTO v_jumpingjack_id FROM exercises WHERE name = 'Jumping Jacks';
    SELECT id INTO v_highknees_id FROM exercises WHERE name = 'High Knees';
    SELECT id INTO v_row_id FROM exercises WHERE name = 'Dumbbell Rows';
    SELECT id INTO v_press_id FROM exercises WHERE name = 'Dumbbell Shoulder Press';

    -- Beginner Full Body Workout
    INSERT INTO workouts (title, description, category, difficulty, duration_minutes, estimated_calories, equipment_needed, target_muscles, is_published)
    VALUES (
        'Beginner Full Body Blast',
        'Perfect for those just starting their fitness journey. This workout targets all major muscle groups with simple, effective exercises.',
        'Strength',
        'Beginner',
        20,
        200,
        ARRAY['None'],
        ARRAY['Chest', 'Legs', 'Core'],
        true
    ) RETURNING id INTO v_workout_id;

    INSERT INTO workout_exercises (workout_id, exercise_id, exercise_order, sets, reps, rest_seconds) VALUES
    (v_workout_id, v_jumpingjack_id, 1, 1, 30, 30),
    (v_workout_id, v_pushup_id, 2, 3, 10, 60),
    (v_workout_id, v_squat_id, 3, 3, 15, 60),
    (v_workout_id, v_plank_id, 4, 3, NULL, 60), -- duration_seconds to be added
    (v_workout_id, v_lunge_id, 5, 3, 10, 60);

    UPDATE workout_exercises SET duration_seconds = 30 WHERE workout_id = v_workout_id AND exercise_id = v_plank_id;

    -- HIIT Cardio Blast
    INSERT INTO workouts (title, description, category, difficulty, duration_minutes, estimated_calories, equipment_needed, target_muscles, is_published)
    VALUES (
        'HIIT Cardio Blast',
        'High-intensity interval training to burn calories and boost metabolism. Get ready to sweat!',
        'HIIT',
        'Intermediate',
        15,
        250,
        ARRAY['None'],
        ARRAY['Full Body', 'Cardio'],
        true
    ) RETURNING id INTO v_workout_id;

    INSERT INTO workout_exercises (workout_id, exercise_id, exercise_order, sets, duration_seconds, rest_seconds) VALUES
    (v_workout_id, v_jumpingjack_id, 1, 1, 60, 30),
    (v_workout_id, v_highknees_id, 2, 3, 30, 30),
    (v_workout_id, v_mountain_id, 3, 3, 30, 30),
    (v_workout_id, v_burpee_id, 4, 3, 20, 40),
    (v_workout_id, v_mountain_id, 5, 3, 30, 30);

    -- Upper Body Strength
    INSERT INTO workouts (title, description, category, difficulty, duration_minutes, estimated_calories, equipment_needed, target_muscles, is_published)
    VALUES (
        'Upper Body Strength Builder',
        'Build strength in your chest, back, shoulders, and arms with this focused workout.',
        'Strength',
        'Intermediate',
        30,
        280,
        ARRAY['Dumbbells'],
        ARRAY['Chest', 'Back', 'Shoulders', 'Arms'],
        true
    ) RETURNING id INTO v_workout_id;

    INSERT INTO workout_exercises (workout_id, exercise_id, exercise_order, sets, reps, rest_seconds) VALUES
    (v_workout_id, v_jumpingjack_id, 1, 1, 30, 30),
    (v_workout_id, v_pushup_id, 2, 4, 15, 90),
    (v_workout_id, v_row_id, 3, 4, 12, 90),
    (v_workout_id, v_press_id, 4, 4, 10, 90),
    (v_workout_id, v_pushup_id, 5, 3, 12, 60);

    -- Lower Body Power
    INSERT INTO workouts (title, description, category, difficulty, duration_minutes, estimated_calories, equipment_needed, target_muscles, is_published)
    VALUES (
        'Lower Body Power',
        'Build strong, powerful legs with this challenging lower body workout.',
        'Strength',
        'Intermediate',
        25,
        260,
        ARRAY['None'],
        ARRAY['Legs'],
        true
    ) RETURNING id INTO v_workout_id;

    INSERT INTO workout_exercises (workout_id, exercise_id, exercise_order, sets, reps, rest_seconds) VALUES
    (v_workout_id, v_highknees_id, 1, 1, 30, 30),
    (v_workout_id, v_squat_id, 2, 4, 20, 90),
    (v_workout_id, v_lunge_id, 3, 4, 15, 90),
    (v_workout_id, v_squat_id, 4, 3, 15, 60);

    -- Core Crusher
    INSERT INTO workouts (title, description, category, difficulty, duration_minutes, estimated_calories, equipment_needed, target_muscles, is_published)
    VALUES (
        'Core Crusher',
        'Strengthen and sculpt your core with this targeted ab workout.',
        'Strength',
        'Intermediate',
        15,
        150,
        ARRAY['None'],
        ARRAY['Core'],
        true
    ) RETURNING id INTO v_workout_id;

    INSERT INTO workout_exercises (workout_id, exercise_id, exercise_order, sets, duration_seconds, rest_seconds) VALUES
    (v_workout_id, v_plank_id, 1, 3, 45, 30),
    (v_workout_id, v_mountain_id, 2, 3, 30, 30),
    (v_workout_id, v_plank_id, 3, 3, 60, 45),
    (v_workout_id, v_mountain_id, 4, 3, 30, 30);

END $$;

-- =====================================================
-- DAILY MISSIONS
-- =====================================================

INSERT INTO missions (type, title, description, xp_reward, criteria_json, start_date, end_date, is_active) VALUES
('daily', 'Morning Warrior', 'Complete a workout before 10 AM', 100, '{"type": "time_based", "before": "10:00"}'::jsonb, NOW(), NOW() + INTERVAL '1 day', true),
('daily', 'Quick Session', 'Complete a 15-minute workout', 75, '{"type": "duration", "minutes": 15}'::jsonb, NOW(), NOW() + INTERVAL '1 day', true),
('daily', 'Cardio Blast', 'Complete a cardio workout', 80, '{"type": "category", "value": "Cardio"}'::jsonb, NOW(), NOW() + INTERVAL '1 day', true),

('weekly', 'Consistency King', 'Complete 5 workouts this week', 500, '{"type": "workout_count", "target": 5, "period": "week"}'::jsonb, NOW(), NOW() + INTERVAL '7 days', true),
('weekly', 'Full Body Focus', 'Complete 3 strength workouts this week', 400, '{"type": "category_count", "category": "Strength", "target": 3, "period": "week"}'::jsonb, NOW(), NOW() + INTERVAL '7 days', true);

-- =====================================================
-- SAMPLE ADMIN USER
-- =====================================================
-- Note: This would be created after a real user signs up through the auth flow
-- For now, we're just documenting the expected structure

-- Sample comment showing how to manually create an admin (for development only):
-- UPDATE profiles SET role = 'admin', user_type = 'Trainer' WHERE email = 'admin@rezzmo.com';

COMMENT ON TABLE profiles IS 'User profiles extending Supabase auth.users. To create admin: UPDATE profiles SET role = ''admin'' WHERE email = ''your-email@example.com''';
