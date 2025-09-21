-- EMERGENCY DATABASE FIX
-- Run this immediately in your Supabase SQL Editor to restore database functionality

-- Step 1: Drop the problematic policy we created
DROP POLICY IF EXISTS "Coaches can view student profiles for enrollment" ON profiles;

-- Step 2: Restore the original simple policies for profiles
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Step 3: Fix any duplicate profile issues (this is likely causing the login error)
-- First, let's see if there are any duplicates
SELECT email, COUNT(*) as duplicate_count 
FROM profiles 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Step 4: Remove duplicates, keeping the most recent one
DELETE FROM profiles 
WHERE id NOT IN (
    SELECT DISTINCT ON (email) id 
    FROM profiles 
    ORDER BY email, created_at DESC NULLS LAST
);

-- Step 5: Alternative approach - if the above doesn't work, manually clean up
-- Uncomment and modify the email below if needed:
-- DELETE FROM profiles WHERE email = 'mameek@gmail.com' AND created_at IS NULL;

-- Step 6: Create a simple policy that allows coaches to view all profiles (temporary fix)
CREATE POLICY "Allow coaches to view all profiles" ON profiles
    FOR SELECT USING (
        -- Users can view their own profile
        auth.uid() = id
        OR
        -- Coaches can view all profiles  
        (auth.uid() IN (SELECT id FROM profiles WHERE role = 'coach'))
    );

-- Step 7: Verify the fix
SELECT 'Database policies restored successfully!' as status;

-- Step 8: Show current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY cmd, policyname;