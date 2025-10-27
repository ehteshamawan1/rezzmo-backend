// Mission Generation Edge Function
// Milestone 3: Gamification Feature
// Automatically generates daily/weekly/monthly missions for all users
// Schedule: Daily at 12:00 AM (0 0 * * *)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1';

// Database Schema Reference:
/*
-- missions table:
CREATE TABLE missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type TEXT NOT NULL, -- 'daily', 'weekly', 'monthly'
  category TEXT NOT NULL, -- 'workout', 'streak', 'social', 'challenge', 'nutrition'
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  target_value INTEGER NOT NULL, -- e.g., 3 workouts, 7 days streak
  xp_reward INTEGER NOT NULL,
  criteria_json JSONB, -- Additional criteria/conditions
  start_date TIMESTAMP,
  end_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- user_missions table:
CREATE TABLE user_missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  mission_id UUID REFERENCES missions(id) ON DELETE CASCADE,
  progress INTEGER DEFAULT 0, -- Current progress value
  status TEXT DEFAULT 'active', -- 'active', 'completed', 'expired'
  completed_at TIMESTAMP,
  assigned_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, mission_id)
);
*/

interface Mission {
  type: 'daily' | 'weekly' | 'monthly';
  category: 'workout' | 'streak' | 'social' | 'challenge' | 'nutrition';
  title: string;
  description: string;
  target_value: number;
  xp_reward: number;
  criteria_json?: any;
  start_date: string;
  end_date: string;
}

serve(async (req) => {
  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    console.log(`[Mission Generation] Starting at ${now.toISOString()}`);

    // ===== STEP 1: Generate Daily Missions =====
    const dailyMissions = await generateDailyMissions(today);
    console.log(`[Daily Missions] Generated ${dailyMissions.length} missions`);

    // ===== STEP 2: Generate Weekly Missions (Monday only) =====
    let weeklyMissions: Mission[] = [];
    if (now.getDay() === 1) {
      // Monday
      weeklyMissions = await generateWeeklyMissions(today);
      console.log(`[Weekly Missions] Generated ${weeklyMissions.length} missions`);
    }

    // ===== STEP 3: Generate Monthly Missions (1st of month only) =====
    let monthlyMissions: Mission[] = [];
    if (now.getDate() === 1) {
      // First day of month
      monthlyMissions = await generateMonthlyMissions(today);
      console.log(`[Monthly Missions] Generated ${monthlyMissions.length} missions`);
    }

    // ===== STEP 4: Insert Missions into Database =====
    const allMissions = [...dailyMissions, ...weeklyMissions, ...monthlyMissions];

    if (allMissions.length > 0) {
      const { data: insertedMissions, error: insertError } = await supabase
        .from('missions')
        .insert(allMissions)
        .select();

      if (insertError) throw insertError;

      console.log(`[Database] Inserted ${insertedMissions.length} missions`);

      // ===== STEP 5: Assign Missions to All Active Users =====
      const { data: users, error: usersError } = await supabase
        .from('profiles')
        .select('id')
        .eq('status', 'active'); // Only active users

      if (usersError) throw usersError;

      const userMissionAssignments = users.flatMap((user) =>
        insertedMissions.map((mission) => ({
          user_id: user.id,
          mission_id: mission.id,
          progress: 0,
          status: 'active',
          assigned_at: now.toISOString(),
        }))
      );

      if (userMissionAssignments.length > 0) {
        const { error: assignError } = await supabase
          .from('user_missions')
          .insert(userMissionAssignments);

        if (assignError) throw assignError;

        console.log(
          `[Assignment] Assigned ${userMissionAssignments.length} missions to ${users.length} users`
        );
      }

      // ===== STEP 6: Expire Old Missions =====
      await expireOldMissions(supabase, now);
    }

    // ===== STEP 7: Return Summary =====
    return new Response(
      JSON.stringify({
        success: true,
        timestamp: now.toISOString(),
        summary: {
          daily: dailyMissions.length,
          weekly: weeklyMissions.length,
          monthly: monthlyMissions.length,
          total: allMissions.length,
          users: (await supabase.from('profiles').select('id').eq('status', 'active')).data
            ?.length,
        },
      }),
      {
        headers: { 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('[Mission Generation Error]', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    );
  }
});

// ===== DAILY MISSION GENERATOR =====
async function generateDailyMissions(startDate: Date): Promise<Mission[]> {
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + 1); // Expires tomorrow

  const missions: Mission[] = [
    {
      type: 'daily',
      category: 'workout',
      title: 'Complete Your First Workout',
      description: 'Start your day strong! Complete at least 1 workout today.',
      target_value: 1,
      xp_reward: 50,
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'daily',
      category: 'workout',
      title: 'Burn 200 Calories',
      description: 'Burn at least 200 calories through exercise today.',
      target_value: 200,
      xp_reward: 75,
      criteria_json: { metric: 'calories' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'daily',
      category: 'workout',
      title: 'Exercise for 20 Minutes',
      description: 'Commit to at least 20 minutes of exercise today.',
      target_value: 20,
      xp_reward: 60,
      criteria_json: { metric: 'duration_minutes' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'daily',
      category: 'streak',
      title: 'Maintain Your Streak',
      description: 'Don\'t break your streak! Complete a workout today.',
      target_value: 1,
      xp_reward: 100,
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'daily',
      category: 'social',
      title: 'Boost 3 Friends',
      description: 'Send encouragement to 3 friends today.',
      target_value: 3,
      xp_reward: 40,
      criteria_json: { action: 'boost' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
  ];

  // Randomly select 3 daily missions (variety)
  return shuffleArray(missions).slice(0, 3);
}

// ===== WEEKLY MISSION GENERATOR =====
async function generateWeeklyMissions(startDate: Date): Promise<Mission[]> {
  const endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + 7); // Expires next Monday

  const missions: Mission[] = [
    {
      type: 'weekly',
      category: 'workout',
      title: 'Complete 5 Workouts This Week',
      description: 'Workout at least 5 days this week to stay consistent.',
      target_value: 5,
      xp_reward: 250,
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'weekly',
      category: 'workout',
      title: 'Try 3 Different Workout Types',
      description: 'Explore variety! Complete workouts from 3 different categories.',
      target_value: 3,
      xp_reward: 200,
      criteria_json: { metric: 'workout_variety' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'weekly',
      category: 'workout',
      title: 'Exercise for 150 Minutes',
      description: 'Reach the WHO recommendation of 150 minutes of exercise.',
      target_value: 150,
      xp_reward: 300,
      criteria_json: { metric: 'total_duration_minutes' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'weekly',
      category: 'social',
      title: 'Join a Circle Challenge',
      description: 'Participate in at least 1 circle challenge this week.',
      target_value: 1,
      xp_reward: 150,
      criteria_json: { action: 'join_circle_challenge' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'weekly',
      category: 'challenge',
      title: 'Complete 2 Challenges',
      description: 'Join and complete 2 community challenges this week.',
      target_value: 2,
      xp_reward: 200,
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
  ];

  // Return 3 weekly missions
  return shuffleArray(missions).slice(0, 3);
}

// ===== MONTHLY MISSION GENERATOR =====
async function generateMonthlyMissions(startDate: Date): Promise<Mission[]> {
  const endDate = new Date(startDate);
  endDate.setMonth(endDate.getMonth() + 1); // Expires next month

  const missions: Mission[] = [
    {
      type: 'monthly',
      category: 'workout',
      title: 'Complete 20 Workouts This Month',
      description: 'Stay active all month long! Complete 20 workouts.',
      target_value: 20,
      xp_reward: 1000,
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'monthly',
      category: 'streak',
      title: 'Achieve a 30-Day Streak',
      description: 'The ultimate consistency challenge! Work out every day this month.',
      target_value: 30,
      xp_reward: 1500,
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'monthly',
      category: 'workout',
      title: 'Burn 5,000 Calories',
      description: 'Torch 5,000 calories through exercise this month.',
      target_value: 5000,
      xp_reward: 1200,
      criteria_json: { metric: 'total_calories' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'monthly',
      category: 'social',
      title: 'Create a Training Circle',
      description: 'Build community! Create and invite 5+ members to a training circle.',
      target_value: 5,
      xp_reward: 800,
      criteria_json: { action: 'create_circle_with_members' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
    {
      type: 'monthly',
      category: 'challenge',
      title: 'Win 3 Challenges',
      description: 'Compete and win! Finish in the top 3 of any 3 challenges.',
      target_value: 3,
      xp_reward: 1000,
      criteria_json: { metric: 'challenge_top_3' },
      start_date: startDate.toISOString(),
      end_date: endDate.toISOString(),
    },
  ];

  // Return 2 monthly missions
  return shuffleArray(missions).slice(0, 2);
}

// ===== EXPIRE OLD MISSIONS =====
async function expireOldMissions(supabase: any, now: Date): Promise<void> {
  const { data, error } = await supabase
    .from('user_missions')
    .update({ status: 'expired' })
    .eq('status', 'active')
    .lt('end_date', now.toISOString())
    .select();

  if (error) {
    console.error('[Expire Missions Error]', error);
  } else {
    console.log(`[Expiration] Expired ${data?.length || 0} old missions`);
  }
}

// ===== UTILITY: Shuffle Array =====
function shuffleArray<T>(array: T[]): T[] {
  const shuffled = [...array];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}
