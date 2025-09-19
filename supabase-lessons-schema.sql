-- Lessons table for storing video lessons with Mux integration
CREATE TABLE IF NOT EXISTS lessons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    mux_asset_id TEXT, -- Mux asset ID
    mux_playback_id TEXT, -- Mux playback ID for video player
    mux_upload_id TEXT, -- Mux upload ID for tracking
    upload_status TEXT DEFAULT 'pending' CHECK (upload_status IN ('pending', 'uploading', 'processing', 'ready', 'error')),
    duration INTEGER, -- Video duration in seconds
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Modules table (if not exists)
CREATE TABLE IF NOT EXISTS modules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Courses table (if not exists)
CREATE TABLE IF NOT EXISTS courses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    instructor_id UUID NOT NULL REFERENCES profiles(id),
    price DECIMAL(10,2),
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- RLS Policies for lessons
CREATE POLICY "Users can view lessons of courses they have access to" ON lessons
    FOR SELECT USING (
        module_id IN (
            SELECT m.id FROM modules m
            JOIN courses c ON m.course_id = c.id
            WHERE c.instructor_id = auth.uid()
            OR c.id IN (
                SELECT course_id FROM enrollments 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Instructors can manage their course lessons" ON lessons
    FOR ALL USING (
        module_id IN (
            SELECT m.id FROM modules m
            JOIN courses c ON m.course_id = c.id
            WHERE c.instructor_id = auth.uid()
        )
    );

-- RLS Policies for modules
CREATE POLICY "Users can view modules of courses they have access to" ON modules
    FOR SELECT USING (
        course_id IN (
            SELECT id FROM courses
            WHERE instructor_id = auth.uid()
            OR id IN (
                SELECT course_id FROM enrollments 
                WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Instructors can manage their course modules" ON modules
    FOR ALL USING (
        course_id IN (
            SELECT id FROM courses
            WHERE instructor_id = auth.uid()
        )
    );

-- RLS Policies for courses
CREATE POLICY "Anyone can view published courses" ON courses
    FOR SELECT USING (status = 'published' OR instructor_id = auth.uid());

CREATE POLICY "Instructors can manage their own courses" ON courses
    FOR ALL USING (instructor_id = auth.uid());

-- Enrollments table (if not exists)
CREATE TABLE IF NOT EXISTS enrollments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id),
    course_id UUID NOT NULL REFERENCES courses(id),
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, course_id)
);

ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own enrollments" ON enrollments
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can enroll themselves" ON enrollments
    FOR INSERT WITH CHECK (user_id = auth.uid());