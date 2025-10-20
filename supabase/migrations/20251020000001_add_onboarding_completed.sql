-- Migration: Add onboarding_completed flag to profiles table
-- Created: 2025-10-20
-- Purpose: Track whether a user has completed the onboarding flow
--         This prevents existing users from seeing onboarding again after login

-- Add onboarding_completed column to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE NOT NULL;

-- Create index for faster lookups when checking onboarding status
-- Using 'id' instead of 'user_id' (correct column name in profiles table)
CREATE INDEX IF NOT EXISTS idx_profiles_onboarding_completed
ON profiles(id, onboarding_completed);

-- Update existing profiles to mark them as having completed onboarding
-- (Assumes existing profiles were created through old flow)
UPDATE profiles
SET onboarding_completed = TRUE
WHERE onboarding_completed = FALSE;

-- Add comment to document the column
COMMENT ON COLUMN profiles.onboarding_completed IS 'Indicates whether the user has completed the initial onboarding flow. Set to TRUE after completing all onboarding steps.';
