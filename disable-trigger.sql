-- Disable the problematic trigger completely
-- Run this in Supabase SQL Editor

-- Drop the trigger that's causing the 500 error
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- We'll handle profile creation manually in the client code instead