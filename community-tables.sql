-- Community Tables for Kohza Platform
-- This file contains the database schema for the community feature

-- Community Threads
CREATE TABLE IF NOT EXISTS threads (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    course_id UUID REFERENCES courses(id) ON DELETE CASCADE NOT NULL,
    author_id UUID REFERENCES profiles(id) NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Thread Replies
CREATE TABLE IF NOT EXISTS replies (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    thread_id UUID REFERENCES threads(id) ON DELETE CASCADE NOT NULL,
    author_id UUID REFERENCES profiles(id) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on community tables
ALTER TABLE threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE replies ENABLE ROW LEVEL SECURITY;

-- Community threads policies
DO $$ BEGIN
    CREATE POLICY "Users can view threads in their courses" ON threads
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM enrollments 
                WHERE enrollments.course_id = threads.course_id 
                AND enrollments.student_id = auth.uid()
            ) OR 
            EXISTS (
                SELECT 1 FROM courses 
                WHERE courses.id = threads.course_id 
                AND courses.coach_id = auth.uid()
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can create threads in their courses" ON threads
        FOR INSERT WITH CHECK (
            author_id = auth.uid() AND (
                EXISTS (
                    SELECT 1 FROM enrollments 
                    WHERE enrollments.course_id = threads.course_id 
                    AND enrollments.student_id = auth.uid()
                ) OR 
                EXISTS (
                    SELECT 1 FROM courses 
                    WHERE courses.id = threads.course_id 
                    AND courses.coach_id = auth.uid()
                )
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update their own threads" ON threads
        FOR UPDATE USING (author_id = auth.uid());
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can delete their own threads" ON threads
        FOR DELETE USING (author_id = auth.uid());
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Replies policies
DO $$ BEGIN
    CREATE POLICY "Users can view replies in course threads" ON replies
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM threads 
                JOIN enrollments ON enrollments.course_id = threads.course_id
                WHERE threads.id = replies.thread_id 
                AND enrollments.student_id = auth.uid()
            ) OR 
            EXISTS (
                SELECT 1 FROM threads 
                JOIN courses ON courses.id = threads.course_id
                WHERE threads.id = replies.thread_id 
                AND courses.coach_id = auth.uid()
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can create replies in course threads" ON replies
        FOR INSERT WITH CHECK (
            author_id = auth.uid() AND (
                EXISTS (
                    SELECT 1 FROM threads 
                    JOIN enrollments ON enrollments.course_id = threads.course_id
                    WHERE threads.id = replies.thread_id 
                    AND enrollments.student_id = auth.uid()
                ) OR 
                EXISTS (
                    SELECT 1 FROM threads 
                    JOIN courses ON courses.id = threads.course_id
                    WHERE threads.id = replies.thread_id 
                    AND courses.coach_id = auth.uid()
                )
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can update their own replies" ON replies
        FOR UPDATE USING (author_id = auth.uid());
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE POLICY "Users can delete their own replies" ON replies
        FOR DELETE USING (author_id = auth.uid());
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_threads_course_id ON threads(course_id);
CREATE INDEX IF NOT EXISTS idx_threads_author_id ON threads(author_id);
CREATE INDEX IF NOT EXISTS idx_replies_thread_id ON replies(thread_id);
CREATE INDEX IF NOT EXISTS idx_replies_author_id ON replies(author_id);