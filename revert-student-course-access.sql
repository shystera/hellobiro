-- Revert RLS policies added by fix-student-course-access.sql
-- This will remove the policies that are causing login issues

-- Remove the student course access policies
DROP POLICY IF EXISTS "Students can view courses they're enrolled in" ON courses;
DROP POLICY IF EXISTS "Students can view modules of enrolled courses" ON modules;
DROP POLICY IF EXISTS "Students can view lessons of enrolled courses" ON lessons;

-- Remove the coach profile access policies
DROP POLICY IF EXISTS "Coaches can view all profiles" ON profiles;

-- Remove the coach enrollment management policies
DROP POLICY IF EXISTS "Coaches can view enrollments for their courses" ON enrollments;
DROP POLICY IF EXISTS "Coaches can enroll students in their courses" ON enrollments;
DROP POLICY IF EXISTS "Coaches can update enrollments for their courses" ON enrollments;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';