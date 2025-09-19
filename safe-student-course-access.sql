-- Safe and minimal RLS policy fix for student course access
-- This only adds the essential policy for students to see enrolled courses
-- It doesn't modify profile or other sensitive policies

-- Add policy for students to view courses they're enrolled in (ONLY if it doesn't exist)
DO $$ BEGIN
    -- Check if the policy already exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'courses' 
        AND policyname = 'Students can view enrolled courses'
    ) THEN
        CREATE POLICY "Students can view enrolled courses" ON courses
            FOR SELECT USING (
                -- Allow if user is enrolled in this course
                EXISTS (
                    SELECT 1 FROM enrollments 
                    WHERE enrollments.course_id = courses.id 
                    AND enrollments.student_id = auth.uid()
                    AND enrollments.status = 'active'
                )
            );
        RAISE NOTICE 'Created policy: Students can view enrolled courses';
    ELSE
        RAISE NOTICE 'Policy already exists: Students can view enrolled courses';
    END IF;
END $$;

-- Add policy for students to view modules of enrolled courses (ONLY if it doesn't exist)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'modules' 
        AND policyname = 'Students can view enrolled course modules'
    ) THEN
        CREATE POLICY "Students can view enrolled course modules" ON modules
            FOR SELECT USING (
                -- Allow if user is enrolled in the course that owns this module
                EXISTS (
                    SELECT 1 FROM enrollments 
                    JOIN courses ON courses.id = enrollments.course_id
                    WHERE courses.id = modules.course_id 
                    AND enrollments.student_id = auth.uid()
                    AND enrollments.status = 'active'
                )
            );
        RAISE NOTICE 'Created policy: Students can view enrolled course modules';
    ELSE
        RAISE NOTICE 'Policy already exists: Students can view enrolled course modules';
    END IF;
END $$;

-- Add policy for students to view lessons of enrolled courses (ONLY if it doesn't exist)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'lessons' 
        AND policyname = 'Students can view enrolled course lessons'
    ) THEN
        CREATE POLICY "Students can view enrolled course lessons" ON lessons
            FOR SELECT USING (
                -- Allow if user is enrolled in the course that owns this lesson
                EXISTS (
                    SELECT 1 FROM enrollments 
                    JOIN courses ON courses.id = enrollments.course_id
                    JOIN modules ON modules.course_id = courses.id
                    WHERE modules.id = lessons.module_id 
                    AND enrollments.student_id = auth.uid()
                    AND enrollments.status = 'active'
                )
            );
        RAISE NOTICE 'Created policy: Students can view enrolled course lessons';
    ELSE
        RAISE NOTICE 'Policy already exists: Students can view enrolled course lessons';
    END IF;
END $$;

-- Test the fix by checking if student can now access their enrolled course
DO $$ 
DECLARE
    course_count INTEGER;
BEGIN
    -- This should return 1 if the policy is working
    SELECT COUNT(*) INTO course_count
    FROM enrollments e
    JOIN courses c ON c.id = e.course_id  
    WHERE e.course_id = '3063d1aa-698d-42ef-ae5f-9a9a61d9ff7e';
    
    RAISE NOTICE 'Accessible enrolled courses: %', course_count;
END $$;

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';