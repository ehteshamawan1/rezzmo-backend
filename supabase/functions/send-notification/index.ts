// Rezzmo - FCM Push Notification Edge Function
// Sends Firebase Cloud Messaging notifications to users
// Last Updated: October 26, 2025

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// FCM API Key from credentials.md
const FCM_API_KEY = 'AIzaSyDY_9uRKOFG_JafuuIaS0oHcriB5C-1lTA'
const FCM_ENDPOINT = 'https://fcm.googleapis.com/fcm/send'

interface NotificationRequest {
  user_id?: string
  user_ids?: string[]
  type: 'streak_reminder' | 'mission_completed' | 'badge_unlocked' | 'challenge_invite' | 'social_interaction'
  title: string
  body: string
  data?: Record<string, any>
  image_url?: string
  action_url?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request body
    const notificationRequest: NotificationRequest = await req.json()

    // Validate request
    if (!notificationRequest.user_id && !notificationRequest.user_ids) {
      throw new Error('Either user_id or user_ids must be provided')
    }

    if (!notificationRequest.title || !notificationRequest.body) {
      throw new Error('Title and body are required')
    }

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

    // Get user FCM tokens
    const userIds = notificationRequest.user_ids || [notificationRequest.user_id!]
    const { data: devices, error: devicesError } = await supabaseClient
      .from('user_devices')
      .select('fcm_token, user_id, device_type, is_active')
      .in('user_id', userIds)
      .eq('is_active', true)

    if (devicesError) {
      throw new Error(`Failed to fetch user devices: ${devicesError.message}`)
    }

    if (!devices || devices.length === 0) {
      console.log('ℹ️  No active devices found for users:', userIds)
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No active devices to send notification',
          sent_count: 0,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    }

    console.log(`📱 Sending notification to ${devices.length} devices...`)

    // Prepare FCM payload
    const fcmPayload = {
      notification: {
        title: notificationRequest.title,
        body: notificationRequest.body,
        ...(notificationRequest.image_url && { image: notificationRequest.image_url }),
        sound: 'default',
        badge: '1',
      },
      data: {
        type: notificationRequest.type,
        ...(notificationRequest.data || {}),
        ...(notificationRequest.action_url && { action_url: notificationRequest.action_url }),
        timestamp: new Date().toISOString(),
      },
      priority: 'high',
      content_available: true,
    }

    // Send notifications in batches
    const results = await Promise.allSettled(
      devices.map((device) => sendFCMNotification(device.fcm_token, fcmPayload))
    )

    // Count successes and failures
    let sentCount = 0
    let failedCount = 0
    const invalidTokens: string[] = []

    results.forEach((result, index) => {
      if (result.status === 'fulfilled' && result.value.success) {
        sentCount++
      } else {
        failedCount++
        if (result.status === 'rejected' || result.value.invalidToken) {
          invalidTokens.push(devices[index].fcm_token)
        }
      }
    })

    // Remove invalid tokens from database
    if (invalidTokens.length > 0) {
      await supabaseClient
        .from('user_devices')
        .update({ is_active: false })
        .in('fcm_token', invalidTokens)

      console.log(`🗑️  Removed ${invalidTokens.length} invalid tokens`)
    }

    // Log notification to database
    await supabaseClient.from('notifications').insert(
      userIds.map((userId) => ({
        user_id: userId,
        type: notificationRequest.type,
        title: notificationRequest.title,
        body: notificationRequest.body,
        data: notificationRequest.data || {},
        sent_at: new Date().toISOString(),
        is_read: false,
      }))
    )

    console.log(`✅ Notification sent successfully:`)
    console.log(`   - Sent: ${sentCount}`)
    console.log(`   - Failed: ${failedCount}`)
    console.log(`   - Invalid tokens removed: ${invalidTokens.length}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Notification sent',
        stats: {
          total_devices: devices.length,
          sent_count: sentCount,
          failed_count: failedCount,
          invalid_tokens_removed: invalidTokens.length,
        },
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('❌ Error sending notification:', error)

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
 * Send FCM notification to a single device
 */
async function sendFCMNotification(
  fcmToken: string,
  payload: any
): Promise<{ success: boolean; invalidToken?: boolean }> {
  try {
    const response = await fetch(FCM_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `key=${FCM_API_KEY}`,
      },
      body: JSON.stringify({
        to: fcmToken,
        ...payload,
      }),
    })

    const result = await response.json()

    if (!response.ok) {
      console.error('FCM Error:', result)

      // Check if token is invalid
      if (result.error === 'InvalidRegistration' || result.error === 'NotRegistered') {
        return { success: false, invalidToken: true }
      }

      return { success: false }
    }

    if (result.failure === 1) {
      // Check for invalid token in results
      if (
        result.results?.[0]?.error === 'InvalidRegistration' ||
        result.results?.[0]?.error === 'NotRegistered'
      ) {
        return { success: false, invalidToken: true }
      }
      return { success: false }
    }

    return { success: true }
  } catch (error) {
    console.error('Error sending FCM notification:', error)
    return { success: false }
  }
}

// Database schema for user_devices table:
/*
CREATE TABLE user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  device_type TEXT, -- 'ios' or 'android'
  device_name TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  UNIQUE(fcm_token)
);

CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX idx_user_devices_active ON user_devices(is_active) WHERE is_active = true;
*/

// Database schema for notifications table:
/*
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()),
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read) WHERE is_read = false;
CREATE INDEX idx_notifications_type ON notifications(type);
*/
