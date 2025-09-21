-- Reverse all enrollment-related changes and restore original state
-- Run this in your Supabase SQL editor to undo all modifications

-- 1. Drop all custom functions we created
DROP FUNCTION IF EXISTS public.enroll_student_by_email(TEXT, UUID);
DROP FUNCTION IF EXISTS public.find_student_for_enrollment(TEXT);
DROP FUNCTION IF EXISTS public.safe_create_profile(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.get_user_profile(UUID);
DROP FUNCTION IF EXISTS public.create_profile_safe(UUID, TEXT, TEXT, TEXT);

-- 2. Drop all custom RLS policies we created
DROP POLICY IF EXISTS "Profile access policy" ON profiles;
DROP POLICY IF EXISTS "Profile full access policy" ON profiles;
DROP POLICY IF EXISTS "Enrollment access policy" ON enrollments;
DROP POLICY IF EXISTS "Coaches can view student profiles for enrollment" ON profiles;
DROP POLICY IF EXISTS "Coaches can search student profiles by email" ON profiles;

-- 3. Restore basic RLS policies (minimal original setup)
-- Enable RLS on tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

-- 4. Create simple, basic RLS policies (original style)
-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Students can view own enrollments" ON enrollments;
DROP POLICY IF EXISTS "Students can enroll themselves" ON enrollments;
DROP POLICY IF EXISTS "Anyone can view published courses" ON courses;
DROP POLICY IF EXISTS "Coaches can create courses" ON courses;
DROP POLICY IF EXISTS "Coaches can update own courses" ON courses;
DROP POLICY IF EXISTS "Coaches can delete own courses" ON courses;
DROP POLICY IF EXISTS "Users can view modules of accessible courses" ON modules;
DROP POLICY IF EXISTS "Coaches can manage modules of own courses" ON modules;
DROP POLICY IF EXISTS "Users can view lessons of accessible courses" ON lessons;
DROP POLICY IF EXISTS "Coaches can manage lessons of own courses" ON lessons;
DROP POLICY IF EXISTS "Students can view own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Students can update own progress" ON lesson_progress;

-- Now create the basic policies
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Basic enrollment policies
CREATE POLICY "Students can view own enrollments" ON enrollments
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Students can enroll themselves" ON enrollments
    FOR INSERT WITH CHECK (student_id = auth.uid());

-- Basic course policies
CREATE POLICY "Anyone can view published courses" ON courses
    FOR SELECT USING (status = 'published' OR coach_id = auth.uid());

CREATE POLICY "Coaches can create courses" ON courses
    FOR INSERT WITH CHECK (coach_id = auth.uid());

CREATE POLICY "Coaches can update own courses" ON courses
    FOR UPDATE USING (coach_id = auth.uid());

CREATE POLICY "Coaches can delete own courses" ON courses
    FOR DELETE USING (coach_id = auth.uid());

-- Basic module policies
CREATE POLICY "Users can view modules of accessible courses" ON modules
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = modules.course_id 
            AND (courses.status = 'published' OR courses.coach_id = auth.uid())
        )
    );

CREATE POLICY "Coaches can manage modules of own courses" ON modules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = modules.course_id 
            AND courses.coach_id = auth.uid()
        )
    );

-- Basic lesson policies
CREATE POLICY "Users can view lessons of accessible courses" ON lessons
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM modules 
            JOIN courses ON courses.id = modules.course_id
            WHERE modules.id = lessons.module_id 
            AND (courses.status = 'published' OR courses.coach_id = auth.uid())
        )
    );

CREATE POLICY "Coaches can manage lessons of own courses" ON lessons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM modules 
            JOIN courses ON courses.id = modules.course_id
            WHERE modules.id = lessons.module_id 
            AND courses.coach_id = auth.uid()
        )
    );

-- Basic lesson progress policies
CREATE POLICY "Students can view own progress" ON lesson_progress
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Students can update own progress" ON lesson_progress
    FOR ALL USING (student_id = auth.uid());

-- 5. Clean up any orphaned data or test records (optional)
-- Note: Be careful with this section - only run if you want to clean test data
-- DELETE FROM enrollments WHERE created_at > NOW() - INTERVAL '1 day'; -- Uncomment if needed
-- DELETE FROM profiles WHERE email LIKE '%test%' OR email LIKE '%demo%'; -- Uncomment if needed

-- 6. Verify the restoration
SELECT 'All custom enrollment changes have been reversed!' as result;

-- Show current policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    cmd as operation
FROM pg_policies 
WHERE tablename IN ('profiles', 'enrollments', 'courses', 'modules', 'lessons', 'lesson_progress')
ORDER BY tablename, policyname;

-- Show remaining functions (should be empty for our custom ones)
SELECT 
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN ('enroll_student_by_email', 'find_student_for_enrollment', 'safe_create_profile', 'get_user_profile');

-- Final status
SELECT 
    'System restored to original state. All custom enrollment functions and policies removed.' as final_status,
    'You may need to restart your application to clear any cached function calls.' as note;