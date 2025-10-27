// Rezzmo - Streak Calculation Edge Function
// Runs daily via cron job to update user streaks
// Last Updated: October 26, 2025

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface UserStreak {
  id: string
  email: string
  current_streak: number
  longest_streak: number
  last_workout_date: string | null
  timezone: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    )

    console.log('🔄 Starting streak calculation...')

    // Get all users with their streak data
    const { data: users, error: usersError } = await supabaseClient
      .from('profiles')
      .select('id, email, current_streak, longest_streak, last_workout_date, timezone')
      .returns<UserStreak[]>()

    if (usersError) {
      throw new Error(`Failed to fetch users: ${usersError.message}`)
    }

    if (!users || users.length === 0) {
      console.log('ℹ️  No users found')
      return new Response(
        JSON.stringify({ message: 'No users to process', updated_count: 0 }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    console.log(`📊 Processing ${users.length} users...`)

    const updates: Array<{ user_id: string; new_streak: number; streak_broken: boolean }> = []
    let streaksBroken = 0
    let streaksIncremented = 0
    let streaksMaintained = 0

    for (const user of users) {
      const today = new Date()
      const userTimezone = user.timezone || 'UTC'

      // Get user's local midnight
      const localMidnight = getLocalMidnight(today, userTimezone)

      // Calculate days since last workout
      let daysSinceLastWorkout = Infinity

      if (user.last_workout_date) {
        const lastWorkoutDate = new Date(user.last_workout_date)
        const diffTime = localMidnight.getTime() - lastWorkoutDate.getTime()
        daysSinceLastWorkout = Math.floor(diffTime / (1000 * 60 * 60 * 24))
      }

      let newStreak = user.current_streak || 0
      let streakBroken = false

      if (daysSinceLastWorkout === 0) {
        // Worked out today - maintain streak
        streaksMaintained++
      } else if (daysSinceLastWorkout === 1) {
        // Worked out yesterday - increment streak
        newStreak = (user.current_streak || 0) + 1
        streaksIncremented++
      } else if (daysSinceLastWorkout > 1) {
        // Missed more than 1 day - break streak
        newStreak = 0
        streakBroken = true
        streaksBroken++
      }

      // Update longest streak if current is higher
      const longestStreak = Math.max(user.longest_streak || 0, newStreak)

      // Update database
      const { error: updateError } = await supabaseClient
        .from('profiles')
        .update({
          current_streak: newStreak,
          longest_streak: longestStreak,
          updated_at: new Date().toISOString(),
        })
        .eq('id', user.id)

      if (updateError) {
        console.error(`❌ Failed to update user ${user.id}: ${updateError.message}`)
      } else {
        updates.push({
          user_id: user.id,
          new_streak: newStreak,
          streak_broken: streakBroken,
        })

        // Send notification if streak is at risk (no workout today and had streak > 0)
        if (streakBroken && user.current_streak > 0) {
          await sendStreakReminderNotification(supabaseClient, user)
        }
      }
    }

    console.log(`✅ Streak calculation complete:`)
    console.log(`   - Streaks maintained: ${streaksMaintained}`)
    console.log(`   - Streaks incremented: ${streaksIncremented}`)
    console.log(`   - Streaks broken: ${streaksBroken}`)
    console.log(`   - Total updated: ${updates.length}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Streak calculation completed',
        stats: {
          total_users: users.length,
          streaks_maintained: streaksMaintained,
          streaks_incremented: streaksIncremented,
          streaks_broken: streaksBroken,
          total_updated: updates.length,
        },
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Error in streak calculation:', error)

    return new Response(
      JSON.stringify({
        error: error.message || 'Unknown error',
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    )
  }
})

/**
 * Get local midnight for a given timezone
 */
function getLocalMidnight(date: Date, timezone: string): Date {
  try {
    const dateString = date.toLocaleDateString('en-US', { timeZone: timezone })
    const localMidnight = new Date(`${dateString} 00:00:00`)
    return localMidnight
  } catch {
    // Fallback to UTC if timezone is invalid
    const utcMidnight = new Date(date.toISOString().split('T')[0] + 'T00:00:00Z')
    return utcMidnight
  }
}

/**
 * Send streak reminder notification via FCM
 */
async function sendStreakReminderNotification(
  supabaseClient: any,
  user: UserStreak
): Promise<void> {
  try {
    // Call FCM notification function
    await supabaseClient.functions.invoke('send-notification', {
      body: {
        user_id: user.id,
        type: 'streak_reminder',
        title: `Don't lose your ${user.current_streak}-day streak!`,
        body: 'Complete a quick workout to keep your streak alive.',
        data: {
          type: 'streak_reminder',
          current_streak: user.current_streak,
        },
      },
    })

    console.log(`📬 Sent streak reminder to user ${user.id}`)
  } catch (error) {
    console.error(`❌ Failed to send notification to user ${user.id}:`, error)
  }
}

// Cron job schedule: Run daily at 11:00 PM (user's local time)
// Configure in Supabase Dashboard: Cron Jobs
// Schedule: 0 23 * * * (11 PM every day)
