-- Fix coach access to student profiles for enrollment
-- Run this in your Supabase SQL editor

-- Add policy to allow coaches to view student profiles for enrollment purposes
CREATE POLICY "Coaches can view student profiles for enrollment" ON profiles
    FOR SELECT USING (
        -- Allow coaches to view student profiles
        (auth.uid() IN (
            SELECT id FROM profiles 
            WHERE role = 'coach' 
            AND id = auth.uid()
        ) AND role = 'student')
        OR 
        -- Users can still view their own profile
        (auth.uid() = id)
    );

-- Drop the restrictive policy if it exists
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;

-- Verify the new policy
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'profiles' AND cmd = 'SELECT';