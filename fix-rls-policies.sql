-- Fix RLS Policies for Supabase
-- Run this in your Supabase SQL editor to allow profile creation

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Courses policies
CREATE POLICY "Anyone can view published courses" ON courses
    FOR SELECT USING (status = 'published' OR coach_id = auth.uid());

CREATE POLICY "Coaches can create courses" ON courses
    FOR INSERT WITH CHECK (coach_id = auth.uid());

CREATE POLICY "Coaches can update own courses" ON courses
    FOR UPDATE USING (coach_id = auth.uid());

CREATE POLICY "Coaches can delete own courses" ON courses
    FOR DELETE USING (coach_id = auth.uid());

-- Modules policies
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

-- Lessons policies
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

-- Enrollments policies
CREATE POLICY "Students can view own enrollments" ON enrollments
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Students can enroll themselves" ON enrollments
    FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Coaches can view enrollments for their courses" ON enrollments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM courses 
            WHERE courses.id = enrollments.course_id 
            AND courses.coach_id = auth.uid()
        )
    );

-- Lesson progress policies
CREATE POLICY "Students can view own progress" ON lesson_progress
    FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Students can update own progress" ON lesson_progress
    FOR ALL USING (student_id = auth.uid());

CREATE POLICY "Coaches can view progress for their courses" ON lesson_progress
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM lessons 
            JOIN modules ON modules.id = lessons.module_id
            JOIN courses ON courses.id = modules.course_id
            WHERE lessons.id = lesson_progress.lesson_id 
            AND courses.coach_id = auth.uid()
        )
    );

-- Success message
SELECT 'RLS policies created successfully!' as result;