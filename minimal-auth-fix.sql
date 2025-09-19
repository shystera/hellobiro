-- Minimal Authentication Fix
-- This addresses only the core login issue without additional features
-- Run this in your Supabase SQL editor

-- Drop existing profile policies to recreate them cleanly
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Add the minimal policies needed for authentication to work
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Success message
SELECT 'Minimal authentication fix applied. Login should work now.' as result;