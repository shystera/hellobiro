-- Add missing columns to existing tables for Kohza platform

-- Add published column to courses table (boolean for draft/published functionality)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='courses' AND column_name='published') THEN
        ALTER TABLE courses ADD COLUMN published BOOLEAN DEFAULT false;
    END IF;
END $$;



-- Update existing records to have proper default values
UPDATE courses SET published = false WHERE published IS NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_courses_published ON courses(published);
CREATE INDEX IF NOT EXISTS idx_courses_coach_id ON courses(coach_id);
CREATE INDEX IF NOT EXISTS idx_modules_course_id ON modules(course_id);
CREATE INDEX IF NOT EXISTS idx_lessons_module_id ON lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student_course ON enrollments(student_id, course_id);