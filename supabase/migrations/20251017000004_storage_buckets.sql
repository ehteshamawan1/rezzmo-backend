-- =====================================================
-- Rezzmo Storage Buckets Configuration
-- Created: October 17, 2025
-- Description: Storage buckets and policies for media files
-- =====================================================

-- =====================================================
-- CREATE STORAGE BUCKETS
-- =====================================================

-- Profile Avatars Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-avatars',
    'profile-avatars',
    true, -- Public bucket for easy avatar display
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
);

-- Workout Videos Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'workout-videos',
    'workout-videos',
    true, -- Public for streaming
    104857600, -- 100MB limit
    ARRAY['video/mp4', 'video/webm', 'video/quicktime']
);

-- Voice Messages Bucket (Private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'voice-messages',
    'voice-messages',
    false, -- Private - only accessible to sender/recipient
    10485760, -- 10MB limit
    ARRAY['audio/mpeg', 'audio/mp4', 'audio/webm', 'audio/wav', 'audio/ogg']
);

-- Challenge Images Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'challenge-images',
    'challenge-images',
    true, -- Public for challenge display
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- =====================================================
-- STORAGE POLICIES - PROFILE AVATARS
-- =====================================================

-- Anyone can view avatars (public bucket)
CREATE POLICY "Public avatar access"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-avatars');

-- Users can upload their own avatar
CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'profile-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own avatar
CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'profile-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own avatar
CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'profile-avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- STORAGE POLICIES - WORKOUT VIDEOS
-- =====================================================

-- Anyone can view workout videos (public bucket)
CREATE POLICY "Public workout video access"
ON storage.objects FOR SELECT
USING (bucket_id = 'workout-videos');

-- Trainers and admins can upload workout videos
CREATE POLICY "Trainers can upload workout videos"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'workout-videos'
    AND (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND (user_type = 'Trainer' OR role = 'admin')
        )
    )
);

-- Creators can update their own videos
CREATE POLICY "Creators can update their workout videos"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'workout-videos'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Creators can delete their own videos
CREATE POLICY "Creators can delete their workout videos"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'workout-videos'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Admins can delete any workout video
CREATE POLICY "Admins can delete any workout video"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'workout-videos'
    AND EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =====================================================
-- STORAGE POLICIES - VOICE MESSAGES
-- =====================================================

-- Users can view voice messages they sent
CREATE POLICY "Users can view sent voice messages"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'voice-messages'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can view voice messages sent to them
CREATE POLICY "Users can view received voice messages"
ON storage.objects FOR SELECT
USING (
    bucket_id = 'voice-messages'
    AND EXISTS (
        SELECT 1 FROM voice_messages
        WHERE audio_url LIKE '%' || (storage.objects.name) || '%'
        AND recipient_id = auth.uid()
    )
);

-- Users can upload voice messages
CREATE POLICY "Users can upload voice messages"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'voice-messages'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own voice messages
CREATE POLICY "Users can delete their voice messages"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'voice-messages'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- STORAGE POLICIES - CHALLENGE IMAGES
-- =====================================================

-- Anyone can view challenge images (public bucket)
CREATE POLICY "Public challenge image access"
ON storage.objects FOR SELECT
USING (bucket_id = 'challenge-images');

-- Users can upload challenge images for challenges they created
CREATE POLICY "Users can upload challenge images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'challenge-images'
    AND (
        EXISTS (
            SELECT 1 FROM challenges
            WHERE id::text = (storage.foldername(name))[1]
            AND created_by = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    )
);

-- Challenge creators can update their images
CREATE POLICY "Challenge creators can update images"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'challenge-images'
    AND EXISTS (
        SELECT 1 FROM challenges
        WHERE id::text = (storage.foldername(name))[1]
        AND created_by = auth.uid()
    )
);

-- Challenge creators can delete their images
CREATE POLICY "Challenge creators can delete images"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'challenge-images'
    AND EXISTS (
        SELECT 1 FROM challenges
        WHERE id::text = (storage.foldername(name))[1]
        AND created_by = auth.uid()
    )
);

-- Admins can delete any challenge image
CREATE POLICY "Admins can delete any challenge image"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'challenge-images'
    AND EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- =====================================================
-- HELPER FUNCTIONS FOR STORAGE
-- =====================================================

-- Function to get public URL for avatar
CREATE OR REPLACE FUNCTION get_avatar_url(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_avatar_url TEXT;
    v_supabase_url TEXT := 'https://bmyiivszfcjklzpqkhvj.supabase.co';
BEGIN
    SELECT avatar_url INTO v_avatar_url
    FROM profiles
    WHERE id = user_id;

    -- If avatar_url is already a full URL, return it
    IF v_avatar_url LIKE 'http%' THEN
        RETURN v_avatar_url;
    END IF;

    -- If it's a storage path, construct the public URL
    IF v_avatar_url IS NOT NULL AND v_avatar_url != '' THEN
        RETURN v_supabase_url || '/storage/v1/object/public/profile-avatars/' || v_avatar_url;
    END IF;

    -- Return default avatar
    RETURN 'https://api.dicebear.com/7.x/avataaars/svg?seed=' || user_id::text;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup orphaned storage files
-- This can be run periodically to remove files that are no longer referenced
CREATE OR REPLACE FUNCTION cleanup_orphaned_storage()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- Note: This is a placeholder function
    -- Actual implementation would require checking for orphaned files
    -- and removing them from storage

    -- For now, we'll just return 0
    -- In production, this would be handled by an Edge Function or scheduled task

    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STORAGE USAGE TRACKING (Optional)
-- =====================================================

-- Table to track storage usage per user
CREATE TABLE storage_usage (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    total_bytes BIGINT DEFAULT 0,
    avatar_bytes BIGINT DEFAULT 0,
    video_bytes BIGINT DEFAULT 0,
    voice_bytes BIGINT DEFAULT 0,
    last_calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to calculate user storage usage
CREATE OR REPLACE FUNCTION calculate_user_storage(p_user_id UUID)
RETURNS BIGINT AS $$
DECLARE
    v_total_bytes BIGINT := 0;
BEGIN
    -- Sum up all files owned by user across all buckets
    SELECT COALESCE(SUM(size), 0) INTO v_total_bytes
    FROM storage.objects
    WHERE (storage.foldername(name))[1] = p_user_id::text;

    -- Update tracking table
    INSERT INTO storage_usage (user_id, total_bytes, last_calculated_at)
    VALUES (p_user_id, v_total_bytes, NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        total_bytes = EXCLUDED.total_bytes,
        last_calculated_at = NOW();

    RETURN v_total_bytes;
END;
$$ LANGUAGE plpgsql;

-- Enable RLS on storage_usage
ALTER TABLE storage_usage ENABLE ROW LEVEL SECURITY;

-- Users can view their own storage usage
CREATE POLICY "Users can view their own storage usage"
ON storage_usage FOR SELECT
USING (auth.uid() = user_id);

-- Admins can view all storage usage
CREATE POLICY "Admins can view all storage usage"
ON storage_usage FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);
