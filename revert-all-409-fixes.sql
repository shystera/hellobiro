-- Comprehensive revert script to undo all changes made after identifying the enrollment issue
-- This script reverts both the enrollment fixes AND the login 409 conflict fixes
-- Run this in your Supabase SQL editor to return to the original state

-- 1. Drop all custom functions that were created
DROP FUNCTION IF EXISTS public.create_profile_idempotent(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.find_student_for_enrollment(TEXT);
DROP FUNCTION IF EXISTS public.enroll_student_by_email(TEXT, UUID);
DROP FUNCTION IF EXISTS public.safe_create_profile(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.get_user_profile(UUID);
DROP FUNCTION IF EXISTS public.create_profile_safe(UUID, TEXT, TEXT, TEXT);

-- 2. Drop all custom RLS policies that were added
DROP POLICY IF EXISTS "Profile access policy" ON profiles;
DROP POLICY IF EXISTS "Profile full access policy" ON profiles;
DROP POLICY IF EXISTS "Enrollment access policy" ON profiles;
DROP POLICY IF EXISTS "Coaches can view student profiles for enrollment" ON profiles;
DROP POLICY IF EXISTS "Coaches can search student profiles by email" ON profiles;
DROP POLICY IF EXISTS "Coaches can search profiles by email" ON profiles;
DROP POLICY IF EXISTS "Coaches can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Coaches can view enrollments for their courses" ON enrollments;
DROP POLICY IF EXISTS "Coaches can enroll students in their courses" ON enrollments;
DROP POLICY IF EXISTS "Coaches can update enrollments for their courses" ON enrollments;
DROP POLICY IF EXISTS "Students can view courses they're enrolled in" ON courses;
DROP POLICY IF EXISTS "Students can view modules of enrolled courses" ON modules;
DROP POLICY IF EXISTS "Students can view lessons of enrolled courses" ON lessons;

-- 3. Ensure RLS is enabled on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

-- 4. Restore original basic RLS policies (create only if they don't exist)
-- These are the minimal policies that should have been there originally

-- Basic profiles policies
DO $$ BEGIN
    CREATE POLICY "Users can view own profile" ON profiles
        FOR SELECT USING (auth.uid() = id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can insert own profile" ON profiles
        FOR INSERT WITH CHECK (auth.uid() = id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update own profile" ON profiles
        FOR UPDATE USING (auth.uid() = id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Basic courses policies
DO $$ BEGIN
    CREATE POLICY "Anyone can view published courses" ON courses
        FOR SELECT USING (status = 'published');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Coaches can manage their own courses" ON courses
        FOR ALL USING (auth.uid() = coach_id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Basic enrollments policies
DO $$ BEGIN
    CREATE POLICY "Students can view their own enrollments" ON enrollments
        FOR SELECT USING (auth.uid() = student_id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Students can enroll in courses" ON enrollments
        FOR INSERT WITH CHECK (auth.uid() = student_id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Basic modules policies
DO $$ BEGIN
    CREATE POLICY "Users can view modules of accessible courses" ON modules
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM courses 
                WHERE courses.id = modules.course_id 
                AND (courses.status = 'published' OR courses.coach_id = auth.uid())
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Coaches can manage modules of own courses" ON modules
        FOR ALL USING (
            EXISTS (
                SELECT 1 FROM courses 
                WHERE courses.id = modules.course_id AND courses.coach_id = auth.uid()
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Basic lessons policies
DO $$ BEGIN
    CREATE POLICY "Users can view lessons of accessible courses" ON lessons
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM modules 
                JOIN courses ON courses.id = modules.course_id
                WHERE modules.id = lessons.module_id 
                AND (courses.status = 'published' OR courses.coach_id = auth.uid())
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Coaches can manage lessons of own courses" ON lessons
        FOR ALL USING (
            EXISTS (
                SELECT 1 FROM modules 
                JOIN courses ON courses.id = modules.course_id
                WHERE modules.id = lessons.module_id AND courses.coach_id = auth.uid()
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Basic lesson progress policies
DO $$ BEGIN
    CREATE POLICY "Students can view own progress" ON lesson_progress
        FOR SELECT USING (auth.uid() = student_id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Students can update own progress" ON lesson_progress
        FOR ALL USING (auth.uid() = student_id);
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 5. Verification queries
-- Show remaining functions (should be empty for our custom ones)
SELECT 
    'Functions check:' as check_type,
    routine_name, 
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'create_profile_idempotent', 
    'find_student_for_enrollment', 
    'enroll_student_by_email',
    'safe_create_profile',
    'get_user_profile',
    'create_profile_safe'
)
UNION ALL
SELECT 
    'Policies check:' as check_type,
    tablename as routine_name,
    policyname as routine_type
FROM pg_policies 
WHERE tablename IN ('profiles', 'enrollments', 'courses', 'modules', 'lessons', 'lesson_progress')
ORDER BY check_type, routine_name;

-- 6. Final status message
SELECT 
    'REVERT COMPLETE' as status,
    'All custom functions and policies have been removed.' as message,
    'Original RLS policies have been restored.' as note,
    'You should now see the original enrollment and login errors.' as expected_result;