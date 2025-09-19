-- Fix Orphaned Users Script
-- Run this in your Supabase SQL editor to detect and handle orphaned users

-- 1. DETECTION: Find orphaned auth users (auth exists but no profile)
-- This finds auth users that don't have corresponding profiles
SELECT 
    u.id as auth_user_id,
    u.email as auth_email,
    u.created_at as auth_created_at,
    'ORPHANED AUTH USER' as status
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC;

-- 2. DETECTION: Find orphaned profiles (profile exists but no auth user)
-- This finds profiles that don't have corresponding auth users
SELECT 
    p.id as profile_id,
    p.email as profile_email,
    p.created_at as profile_created_at,
    p.role,
    'ORPHANED PROFILE' as status
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id
WHERE u.id IS NULL
ORDER BY p.created_at DESC;

-- 3. DETECTION: Combined report of all orphaned records
SELECT 
    'Orphaned Auth Users (auth exists, no profile)' as issue_type,
    COUNT(*) as count
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL

UNION ALL

SELECT 
    'Orphaned Profiles (profile exists, no auth)' as issue_type,
    COUNT(*) as count
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id
WHERE u.id IS NULL;

-- 4. REMEDIATION: Create missing profiles for orphaned auth users
-- CAUTION: Review the results above before running this!
-- This will create profiles for auth users that don't have them

/*
INSERT INTO public.profiles (id, email, full_name, role)
SELECT 
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)) as full_name,
    COALESCE((u.raw_user_meta_data->>'role')::text, 'student') as role
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
  AND u.email IS NOT NULL;
*/

-- 5. REMEDIATION: Clean up orphaned profiles (profiles without auth users)
-- CAUTION: This will permanently delete profile data!
-- Only run this if you're sure these profiles should be removed

/*
DELETE FROM public.profiles 
WHERE id IN (
    SELECT p.id
    FROM public.profiles p
    LEFT JOIN auth.users u ON p.id = u.id
    WHERE u.id IS NULL
);
*/

-- 6. PREVENTION: Ensure RLS policies allow profile creation
-- Check current policies on profiles table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 7. PREVENTION: Create or update policies to prevent orphaned accounts
-- Run this to ensure proper policies exist

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

-- Create comprehensive policies
DO $$ BEGIN
    -- Allow users to create their own profile
    CREATE POLICY "Users can create their own profile" ON profiles
        FOR INSERT WITH CHECK (auth.uid() = id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    -- Allow users to view their own profile
    CREATE POLICY "Users can view their own profile" ON profiles
        FOR SELECT USING (auth.uid() = id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    -- Allow users to update their own profile
    CREATE POLICY "Users can update their own profile" ON profiles
        FOR UPDATE USING (auth.uid() = id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    -- Allow coaches to search students by email for enrollment
    CREATE POLICY "Coaches can search student profiles by email" ON profiles
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM profiles coach_profile 
                WHERE coach_profile.id = auth.uid() 
                AND coach_profile.role = 'coach'
            )
            AND role = 'student'
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 8. Create a function to safely create user profiles
CREATE OR REPLACE FUNCTION public.create_profile_safe(
    user_id UUID,
    user_email TEXT,
    user_name TEXT DEFAULT NULL,
    user_role TEXT DEFAULT 'student'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    auth_user_exists BOOLEAN;
BEGIN
    -- Check if auth user exists
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = user_id) INTO auth_user_exists;
    
    IF NOT auth_user_exists THEN
        RETURN json_build_object('error', 'Auth user does not exist');
    END IF;
    
    -- Insert or update the profile
    INSERT INTO profiles (id, email, full_name, role)
    VALUES (user_id, user_email, COALESCE(user_name, split_part(user_email, '@', 1)), user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Return the created/updated profile
    SELECT json_build_object(
        'id', id,
        'email', email,
        'full_name', full_name,
        'role', role,
        'created_at', created_at,
        'updated_at', updated_at
    ) INTO result
    FROM profiles
    WHERE id = user_id;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', SQLERRM);
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.create_profile_safe TO authenticated;

SELECT 'Orphaned user detection and remediation script completed!' as result;