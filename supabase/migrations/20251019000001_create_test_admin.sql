-- =====================================================
-- Create Test Admin User for Rezzmo Admin Panel
-- Created: October 19, 2025
-- WARNING: This is for DEVELOPMENT/TESTING only!
-- Will be replaced with actual admin credentials in Milestone 8
-- =====================================================

-- =====================================================
-- INSTRUCTIONS FOR CREATING TEST ADMIN USER
-- =====================================================
--
-- IMPORTANT: This SQL file cannot directly create auth users via SQL.
-- You must create the user manually through Supabase Dashboard:
--
-- 1. Go to Supabase Dashboard → Authentication → Users
-- 2. Click "Add user" → "Create new user"
-- 3. Enter:
--    Email: admin@rezzmo.test
--    Password: TestAdmin123!
-- 4. Click "Create user"
-- 5. Copy the User ID (UUID) that was generated
-- 6. Come back to SQL Editor and run the commands below
--
-- =====================================================

-- =====================================================
-- STEP 1: UPDATE THE USER ID BELOW
-- =====================================================
-- Replace 'YOUR-USER-UUID-HERE' with the actual UUID from step 5 above
--
-- Example:
-- DO $$
-- DECLARE
--   admin_user_id uuid := '550e8400-e29b-41d4-a716-446655440000'; -- Your actual UUID
-- BEGIN

DO $$
DECLARE
  admin_user_id uuid := 'YOUR-USER-UUID-HERE'; -- <<<< REPLACE THIS WITH ACTUAL UUID
BEGIN
  -- =====================================================
  -- STEP 2: UPDATE PROFILE WITH ADMIN ROLE
  -- =====================================================

  -- Update the auto-created profile with admin role and details
  UPDATE public.profiles
  SET
    role = 'admin',
    display_name = 'Rezzmo Admin (Test)',
    bio = 'Test administrator account - will be replaced in Milestone 8',
    updated_at = NOW()
  WHERE id = admin_user_id;

  -- Verify the update
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Admin profile not found. Make sure the user was created first and UUID is correct.';
  END IF;

  -- =====================================================
  -- STEP 3: CREATE USER PROGRESS RECORD
  -- =====================================================

  -- Create progress record for admin (not really needed but for consistency)
  INSERT INTO public.user_progress (user_id, level, xp, created_at, updated_at)
  VALUES (admin_user_id, 1, 0, NOW(), NOW())
  ON CONFLICT (user_id) DO NOTHING;

  RAISE NOTICE 'Test admin user configured successfully!';
  RAISE NOTICE 'Email: admin@rezzmo.test';
  RAISE NOTICE 'Password: TestAdmin123!';
  RAISE NOTICE 'Role: admin';
  RAISE NOTICE 'This is a TEST account only - will be replaced in Milestone 8 with actual credentials and 2FA.';
END $$;

-- =====================================================
-- VERIFICATION QUERY
-- =====================================================
-- Run this to verify the admin user was created correctly:

SELECT
  p.id,
  p.email,
  p.display_name,
  p.role,
  p.created_at
FROM public.profiles p
WHERE p.email = 'admin@rezzmo.test';

-- Expected result:
-- - One row with role = 'admin'
-- - display_name = 'Rezzmo Admin (Test)'

-- =====================================================
-- IMPORTANT SECURITY NOTES
-- =====================================================
--
-- 1. This is a DEVELOPMENT/TESTING account only
-- 2. NEVER use this in production
-- 3. In Milestone 8, you will:
--    - Delete this test admin account
--    - Create actual admin account with your real email
--    - Enable 2FA (Two-Factor Authentication)
-- 4. Admin signup is DISABLED - admins can only be created manually
-- 5. Keep these test credentials secure during development
--
-- =====================================================

-- =====================================================
-- CLEANUP (Use this to remove test admin when done)
-- =====================================================
-- Uncomment and run these commands when you're ready to remove the test admin:
--
-- DELETE FROM public.user_progress WHERE user_id IN (
--   SELECT id FROM public.profiles WHERE email = 'admin@rezzmo.test'
-- );
--
-- DELETE FROM public.profiles WHERE email = 'admin@rezzmo.test';
--
-- -- Then go to Authentication → Users and manually delete admin@rezzmo.test
--
