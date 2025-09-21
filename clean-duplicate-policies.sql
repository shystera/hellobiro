-- Clean up all duplicate and conflicting RLS policies
-- This will remove all existing policies and create a minimal, working set

-- 1. Drop ALL existing policies on all tables
-- Profiles policies
DROP POLICY IF EXISTS "Allow profile creation" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile." ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile." ON profiles;
DROP POLICY IF EXISTS "allow_own_profile_insert" ON profiles;
DROP POLICY IF EXISTS "allow_own_profile_select" ON profiles;
DROP POLICY IF EXISTS "allow_own_profile_update" ON profiles;

-- Courses policies
DROP POLICY IF EXISTS "Anyone can view published courses" ON courses;
DROP POLICY IF EXISTS "Coaches can create courses" ON courses;
DROP POLICY IF EXISTS "Coaches can delete own courses" ON courses;
DROP POLICY IF EXISTS "Coaches can manage their own courses" ON courses;
DROP POLICY IF EXISTS "Coaches can update own courses" ON courses;
DROP POLICY IF EXISTS "Students can view enrolled courses" ON courses;

-- Enrollments policies
DROP POLICY IF EXISTS "Students can enroll in courses" ON enrollments;
DROP POLICY IF EXISTS "Students can enroll themselves" ON enrollments;
DROP POLICY IF EXISTS "Students can view own enrollments" ON enrollments;
DROP POLICY IF EXISTS "Students can view their own enrollments" ON enrollments;

-- Modules policies
DROP POLICY IF EXISTS "Anyone can view modules of published courses" ON modules;
DROP POLICY IF EXISTS "Coaches can manage modules of own courses" ON modules;
DROP POLICY IF EXISTS "Coaches can manage modules of their courses" ON modules;
DROP POLICY IF EXISTS "Students can view enrolled course modules" ON modules;
DROP POLICY IF EXISTS "Users can view modules of accessible courses" ON modules;

-- Lessons policies
DROP POLICY IF EXISTS "Anyone can view lessons of published courses" ON lessons;
DROP POLICY IF EXISTS "Coaches can manage lessons of own courses" ON lessons;
DROP POLICY IF EXISTS "Coaches can manage lessons of their courses" ON lessons;
DROP POLICY IF EXISTS "Students can view enrolled course lessons" ON lessons;
DROP POLICY IF EXISTS "Users can view lessons of accessible courses" ON lessons;

-- Lesson progress policies
DROP POLICY IF EXISTS "Coaches can view progress for their courses" ON lesson_progress;
DROP POLICY IF EXISTS "Students can update own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Students can update their own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Students can view own progress" ON lesson_progress;
DROP POLICY IF EXISTS "Students can view their own progress" ON lesson_progress;

-- Lesson notes policies
DROP POLICY IF EXISTS "Students can manage their own notes" ON lesson_notes;

-- 2. Create clean, minimal policies that work

-- Basic profile policies
CREATE POLICY "profile_select_own" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profile_insert_own" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profile_update_own" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Basic course policies
CREATE POLICY "course_select_published_or_own" ON courses
    FOR SELECT USING (status = 'published' OR coach_id = auth.uid());

CREATE POLICY "course_insert_coach" ON courses
    FOR INSERT WITH CHECK (coach_id = auth.uid());

CREATE POLICY "course_update_own" ON courses
    FOR UPDATE USING (coach_id = auth.uid());

CREATE POLICY "course_delete_own" ON courses
    FOR DELETE USING (coach_id = auth.uid());

-- Basic enrollment policies
CREATE POLICY "enrollment_select_own" ON enrollments
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "enrollment_insert_own" ON enrollments
    FOR INSERT WITH CHECK (student_id = auth.uid());

-- Basic module policies
CREATE POLICY "module_select_accessible" ON modules
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = modules.course_id 
            AND (courses.status = 'published' OR courses.coach_id = auth.uid())
        )
    );

CREATE POLICY "module_manage_own_courses" ON modules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = modules.course_id 
            AND courses.coach_id = auth.uid()
        )
    );

-- Basic lesson policies
CREATE POLICY "lesson_select_accessible" ON lessons
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM modules 
            JOIN courses ON courses.id = modules.course_id
            WHERE modules.id = lessons.module_id 
            AND (courses.status = 'published' OR courses.coach_id = auth.uid())
        )
    );

CREATE POLICY "lesson_manage_own_courses" ON lessons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM modules 
            JOIN courses ON courses.id = modules.course_id
            WHERE modules.id = lessons.module_id 
            AND courses.coach_id = auth.uid()
        )
    );

-- Basic lesson progress policies
CREATE POLICY "progress_select_own" ON lesson_progress
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "progress_manage_own" ON lesson_progress
    FOR ALL USING (student_id = auth.uid());

-- Lesson notes policy (if table exists)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'lesson_notes') THEN
        EXECUTE 'CREATE POLICY "notes_manage_own" ON lesson_notes FOR ALL USING (student_id = auth.uid())';
    END IF;
END $$;

-- 3. Verify the cleanup
SELECT 'Policy cleanup completed successfully!' as result;

-- Show the clean policy list
SELECT 
    tablename, 
    policyname, 
    cmd as operation,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read'
        WHEN cmd = 'INSERT' THEN 'Create'
        WHEN cmd = 'UPDATE' THEN 'Update'
        WHEN cmd = 'DELETE' THEN 'Delete'
        WHEN cmd = 'ALL' THEN 'All Operations'
    END as description
FROM pg_policies 
WHERE tablename IN ('profiles', 'enrollments', 'courses', 'modules', 'lessons', 'lesson_progress', 'lesson_notes')
ORDER BY tablename, cmd;

-- Final status
SELECT 
    'All duplicate policies removed and clean minimal policies created.' as status,
    'System should now work without policy conflicts.' as note;