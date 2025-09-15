-- Fix Database Schema for Kohza Platform
-- Run this in your Supabase SQL editor to ensure all required columns exist

-- Add published column to courses table if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='courses' AND column_name='published') THEN
        ALTER TABLE courses ADD COLUMN published BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added published column to courses table';
    ELSE
        RAISE NOTICE 'Published column already exists in courses table';
    END IF;
END $$;

-- Update existing records to have proper default values
UPDATE courses SET published = false WHERE published IS NULL;

-- Ensure profiles table has all required columns
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='role') THEN
        ALTER TABLE profiles ADD COLUMN role TEXT CHECK (role IN ('student', 'coach', 'admin')) DEFAULT 'student';
        RAISE NOTICE 'Added role column to profiles table';
    ELSE
        RAISE NOTICE 'Role column already exists in profiles table';
    END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_courses_published ON courses(published);
CREATE INDEX IF NOT EXISTS idx_courses_coach_id ON courses(coach_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- Verify the schema
SELECT 
    'courses' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'courses' 
    AND column_name IN ('id', 'title', 'coach_id', 'published')
ORDER BY column_name;

SELECT 
    'profiles' as table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles' 
    AND column_name IN ('id', 'email', 'full_name', 'role')
ORDER BY column_name;

-- Show sample data to verify
SELECT 'Sample courses:' as info;
SELECT id, title, coach_id, published FROM courses LIMIT 5;

SELECT 'Sample profiles:' as info;
SELECT id, email, full_name, role FROM profiles LIMIT 5;