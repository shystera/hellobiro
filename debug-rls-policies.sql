-- Check current RLS policies to understand what's blocking course access
-- Run this to see what policies exist

-- Check policies on courses table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'courses';

-- Check policies on enrollments table  
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'enrollments';

-- Check policies on profiles table
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'profiles';

-- Test if the course exists and is accessible
SELECT id, title, status, coach_id 
FROM courses 
WHERE id = '3063d1aa-698d-42ef-ae5f-9a9a61d9ff7e';