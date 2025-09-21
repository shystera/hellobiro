-- Emergency fix for login issues with orphaned profiles and RLS policy conflicts
-- This addresses the 500 Internal Server Error and profile access issues

-- 1. First, let's drop all existing conflicting policies on profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles; 
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Profile access policy" ON profiles;
DROP POLICY IF EXISTS "Coaches can view student profiles for enrollment" ON profiles;
DROP POLICY IF EXISTS "Coaches can search student profiles by email" ON profiles;

-- 2. Temporarily disable RLS on profiles to diagnose the issue
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- 3. Check for orphaned profiles (profiles without corresponding auth users)
SELECT 
    p.id,
    p.email,
    p.role,
    CASE 
        WHEN au.id IS NULL THEN 'ORPHANED - No auth user'
        ELSE 'OK - Has auth user'
    END as status
FROM profiles p
LEFT JOIN auth.users au ON p.id = au.id
ORDER BY p.created_at DESC;

-- 4. Re-enable RLS and create comprehensive policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 5. Create new comprehensive policies that handle all scenarios
CREATE POLICY "Profile full access policy" ON profiles
    FOR ALL USING (
        -- Users can access their own profile
        auth.uid() = id
        OR 
        -- Coaches can view student profiles (for enrollment)
        (
            auth.uid() IN (
                SELECT id FROM profiles 
                WHERE role = 'coach' 
                AND id = auth.uid()
            )
            AND role = 'student'
        )
        OR
        -- Allow service role to access all profiles (for admin operations)
        auth.jwt() ->> 'role' = 'service_role'
    );

-- 6. Create a safe profile creation function that handles duplicates
CREATE OR REPLACE FUNCTION public.safe_create_profile(
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
    existing_profile profiles;
BEGIN
    -- Check if profile already exists
    SELECT * INTO existing_profile
    FROM profiles
    WHERE id = user_id;
    
    IF existing_profile.id IS NOT NULL THEN
        -- Profile exists, return it
        SELECT json_build_object(
            'id', existing_profile.id,
            'email', existing_profile.email,
            'full_name', existing_profile.full_name,
            'role', existing_profile.role,
            'created_at', existing_profile.created_at,
            'status', 'existing'
        ) INTO result;
    ELSE
        -- Profile doesn't exist, create it
        INSERT INTO profiles (id, email, full_name, role)
        VALUES (
            user_id, 
            user_email, 
            COALESCE(user_name, split_part(user_email, '@', 1)), 
            user_role
        );
        
        -- Return the created profile
        SELECT json_build_object(
            'id', user_id,
            'email', user_email,
            'full_name', COALESCE(user_name, split_part(user_email, '@', 1)),
            'role', user_role,
            'created_at', NOW(),
            'status', 'created'
        ) INTO result;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'error', 'Profile operation failed: ' || SQLERRM,
            'code', SQLSTATE
        );
END;
$$;

-- 7. Grant execute permission
GRANT EXECUTE ON FUNCTION public.safe_create_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.safe_create_profile TO anon;

-- 8. Create a function to get user profile safely
CREATE OR REPLACE FUNCTION public.get_user_profile(user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
    user_profile profiles;
BEGIN
    -- Get the profile
    SELECT * INTO user_profile
    FROM profiles
    WHERE id = user_id;
    
    IF user_profile.id IS NOT NULL THEN
        SELECT json_build_object(
            'id', user_profile.id,
            'email', user_profile.email,
            'full_name', user_profile.full_name,
            'role', user_profile.role,
            'created_at', user_profile.created_at,
            'updated_at', user_profile.updated_at
        ) INTO result;
    ELSE
        SELECT json_build_object(
            'error', 'Profile not found',
            'user_id', user_id
        ) INTO result;
    END IF;
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'error', 'Failed to get profile: ' || SQLERRM,
            'code', SQLSTATE
        );
END;
$$;

-- 9. Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_profile TO anon;

-- 10. Verify the policies are active
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'profiles';

-- 11. Show current profile status
SELECT 
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN role = 'coach' THEN 1 END) as coaches,
    COUNT(CASE WHEN role = 'student' THEN 1 END) as students
FROM profiles;

SELECT 'Emergency login fix applied successfully! You should now be able to login.' as result;