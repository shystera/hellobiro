-- Revert RLS Policies to Original State
-- This will restore the original RLS policies and remove the fixes
-- Run this in your Supabase SQL editor

-- Drop all the policies I added
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Coaches can search profiles by email" ON profiles;
DROP POLICY IF EXISTS "Users can view published courses or coaches can view their own" ON courses;
DROP POLICY IF EXISTS "Coaches can create courses" ON courses;
DROP POLICY IF EXISTS "Coaches can update their own courses" ON courses;
DROP POLICY IF EXISTS "Coaches can delete their own courses" ON courses;
DROP POLICY IF EXISTS "Students can view their own enrollments" ON enrollments;
DROP POLICY IF EXISTS "Students can enroll themselves" ON enrollments;
DROP POLICY IF EXISTS "Coaches can view enrollments for their courses" ON enrollments;
DROP POLICY IF EXISTS "Coaches can enroll students in their courses" ON enrollments;

-- Restore the original policies from the schema
-- Profiles policies (original - SELECT and UPDATE only, no INSERT)
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Courses policies (original)
CREATE POLICY "Anyone can view published courses" ON courses
    FOR SELECT USING (status = 'published');

CREATE POLICY "Coaches can manage their own courses" ON courses
    FOR ALL USING (auth.uid() = coach_id);

-- Enrollments policies (original - basic student access only)
CREATE POLICY "Students can view their own enrollments" ON enrollments
    FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "Students can enroll in courses" ON enrollments
    FOR INSERT WITH CHECK (auth.uid() = student_id);

-- Success message
SELECT 'RLS policies reverted to original state. The login issues will return.' as result;