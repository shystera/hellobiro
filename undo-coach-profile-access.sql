-- UNDO coach profile access changes
-- Run this in your Supabase SQL editor to reverse the previous changes

-- Drop the policy we created
DROP POLICY IF EXISTS "Coaches can view student profiles for enrollment" ON profiles;

-- Restore the original simple policy
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

-- Verify the original policy is restored
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'profiles' AND cmd = 'SELECT';